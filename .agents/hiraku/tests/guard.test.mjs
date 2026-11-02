import { after, test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { assertEditBaseline, assertPathAccess, assertShell, assertShellBaseline, evaluatePermission } from "../guard.mjs";
import plugin from "../../../.opencode/plugins/hiraku-guard/index.js";

const coordinator = "hiraku-coordinator";
const senior = "hiraku-senior";

const fixture = mkdtempSync(join(tmpdir(), "hiraku-guard-"));
const root = join(fixture, "project");
const outside = join(fixture, "outside");
mkdirSync(root);
mkdirSync(outside);
mkdirSync(join(root, "core"));
symlinkSync(outside, join(root, "escape"));
mkdirSync(join(root, ".agents"));
symlinkSync(join(root, ".agents"), join(root, "policy-alias"));
after(() => rmSync(fixture, { recursive: true }));

test("senior can edit a new product file", () => {
  assert.doesNotThrow(() => assertPathAccess(root, senior, "edit", "core/domain/kana/kana.go"));
});

test("coordinator cannot edit product source", () => {
  assert.throws(() => assertPathAccess(root, coordinator, "edit", "App/Main.swift"));
});

for (const agent of [coordinator, senior]) {
  for (const path of [
    "opencode.json", "AGENTS.md", "docs/architecture/DECISIONS.md", "docs/process/RELEASE.md",
    ".opencode/plugins/hiraku-guard/index.js", ".opencode/agents/hiraku-senior.md",
    ".agents/hiraku/guard.mjs", ".agents/hiraku/roles/senior.md", ".agents/skills/hiraku-contract/SKILL.md",
    ".commandcode/settings.json", ".commandcode/agents/hiraku-senior.md", ".pi/agents/hiraku-senior.md",
    ".pi/extensions/hiraku-guard.ts",
    ".github/workflows/ci.yml", "core/gen/hirakuv1/study.pb.go",
    "Packages/HirakuBridge/Generated/Study.swift", "Scripts/check-imports.sh",
    "core/scripts/check-core.sh", ".git/config", "policy-alias/agents/fake.md",
  ]) {
    test(`${agent} cannot edit protected path ${path}`, () => {
      assert.throws(() => assertPathAccess(root, agent, "edit", path));
    });
  }
}

test("both roles edit task records; unknown callers edit nothing", () => {
  for (const agent of [coordinator, senior]) {
    assert.doesNotThrow(() => assertPathAccess(root, agent, "edit", ".agents/tasks/wp-01.md"));
  }
  assert.throws(() => assertPathAccess(root, "unknown", "edit", ".agents/tasks/wp-01.md"));
});

for (const path of ["../outside/file", "escape/new/file", "/etc/passwd"]) {
  test(`reject external access ${path}`, () => {
    assert.throws(() => assertPathAccess(root, senior, "edit", path));
  });
}

for (const path of [".env", ".env.local", "AuthKey.p8", "signing.p12", "private.key", "dev.pem"]) {
  test(`deny credential read ${path}`, () => {
    assert.throws(() => assertPathAccess(root, coordinator, "read", path));
  });
}

test("example environment file is readable", () => {
  assert.doesNotThrow(() => assertPathAccess(root, senior, "read", ".env.example"));
});

test("malformed path fails closed", () => {
  assert.throws(() => assertPathAccess(root, senior, "edit", ""));
});

test("both roles run arbitrary non-delivery commands", () => {
  for (const agent of [coordinator, senior]) {
    for (const command of [
      "buf generate", "go mod tidy", "go test ./... | tail -5", "brew install buf",
      "python3 scripts/x.py", "cd core && go test -race ./...", "git checkout -b feat/x",
      "cd /tmp/x && find core -type f -not -path '*/.spike/*' | sort && cat core/go.mod",
      "cd core && go vet ./...; echo EXIT:$?",
      "git add -A",
    ]) assert.doesNotThrow(() => assertShell(root, agent, command), `${agent}: ${command}`);
  }
  assert.doesNotThrow(() => assertShell(root, senior, "go mod init hiraku/core", join(root, "core")));
});

for (const command of [
  "git merge main", "git status --short && git tag v1", "git rebase -i develop",
  "echo x | gh pr merge 1", "gh api repos/owner/repo/releases", "(git merge main)",
  "xcrun altool --upload-app", "xcrun notarytool submit", "fastlane beta", "git reset --hard HEAD~1",
]) {
  test(`delivery stays closed for both roles ${JSON.stringify(command)}`, () => {
    for (const agent of [coordinator, senior]) {
      assert.throws(() => assertShell(root, agent, command));
    }
  });
}

test("rebase belongs to senior on its own branch; coordinator and unknown callers stay out", () => {
  for (const command of ["git rebase develop", "git rebase --continue", "go test ./... && git rebase develop"]) {
    assert.doesNotThrow(() => assertShell(root, senior, command), command);
    assert.throws(() => assertShell(root, coordinator, command), command);
    assert.throws(() => assertShellBaseline(root, command), command);
  }
});

test("senior commits and pushes only task branches, including force-with-lease", () => {
  for (const command of [
    'git add -A && git commit -m "feat(core): add kana table"',
    "git push -u origin feat/wp-01-core", "git push origin fix/q-21-normalize",
    "git push --force-with-lease origin feat/wp-01-core",
  ]) assert.doesNotThrow(() => assertShell(root, senior, command), command);
  for (const command of [
    "git push origin develop", "git push origin main", "git push -f origin feat/x",
    "git push --force origin feat/x", "git push origin feat/x:develop",
    "git commit --amend -m x", "git commit --no-verify -m x", "echo $(git push origin feat/x)",
  ]) assert.throws(() => assertShell(root, senior, command), command);
  assert.throws(() => assertShell(root, coordinator, "git commit -m x"));
  assert.throws(() => assertShell(root, coordinator, "git push -u origin feat/x"));
});

test("senior opens pull requests into develop; coordinator only reads them", () => {
  mkdirSync(join(root, ".agents/tasks"), { recursive: true });
  writeFileSync(join(root, ".agents/tasks/wp-04.md"), "PR body\n");
  for (const command of [
    'gh pr create --base develop --title "feat(core): kana" --body-file .agents/tasks/wp-04.md',
    "gh pr view 3", "gh pr checks 3",
  ]) assert.doesNotThrow(() => assertShell(root, senior, command), command);
  for (const command of [
    "gh pr create --base main --title x", "gh pr create --title x",
    "gh pr create --base develop --base main", "gh pr merge 3 --squash",
  ]) assert.throws(() => assertShell(root, senior, command), command);
  assert.throws(() => assertShell(root, coordinator, "gh pr create --base develop --title x"));
  assert.doesNotThrow(() => assertShell(root, coordinator, "gh pr view 3"));
});

test("shell cwd must stay inside the workspace", () => {
  assert.throws(() => assertShell(root, senior, "ls", outside));
  assert.throws(() => assertShell(root, coordinator, "ls", join(root, "escape")));
});

test("unknown callers get no role shell and no edits", () => {
  assert.throws(() => assertShell(root, "unknown", "git status"));
  assert.throws(() => assertShell(root, "explore", "go test ./..."));
  assert.doesNotThrow(() => assertShellBaseline(root, "go test ./..."));
});

test("patch touching product and protected file is denied as a whole", async () => {
  const event = {
    action: "edit", agent: senior, sessionID: "test",
    resources: ["App/Main.swift", ".opencode/package.json"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: () => assert.fail("denied edit must not be recorded as allowed") });
  assert.equal(event.effect, "deny");
});

test("an allowed mutation invalidates prior review conservatively", async () => {
  const writes = [];
  const event = {
    action: "edit", agent: senior, sessionID: "test",
    resources: ["App/Main.swift"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: async (...args) => writes.push(args) });
  assert.equal(event.effect, "allow");
  assert.deepEqual(writes, [["dirty/test", { agent: senior, reviewInvalidated: true }]]);
});

test("storage failure denies mutation instead of losing review invalidation", async () => {
  const event = {
    action: "edit", agent: senior, sessionID: "test",
    resources: ["App/Main.swift"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: async () => { throw new Error("storage unavailable"); } });
  assert.equal(event.effect, "deny");
  assert.match(event.message, /storage unavailable/);
});

test("only the coordinator delegates, and only to the senior", async () => {
  for (const [agent, target, effect] of [
    [coordinator, senior, "allow"], [coordinator, "general", "deny"],
    [senior, coordinator, "deny"], [senior, senior, "deny"],
  ]) {
    const event = { action: "subagent", agent, sessionID: "t", resources: [target], effect: "allow" };
    await evaluatePermission(root, event, {});
    assert.equal(event.effect, effect, `${agent} -> ${target}`);
  }
});

test("shell permission records review invalidation for both roles", async () => {
  const writes = [];
  const storage = { set: async (...args) => writes.push(args) };
  for (const [agent, sessionID] of [[coordinator, "c"], [senior, "s"]]) {
    const event = { action: "shell", agent, sessionID, resources: ["go test ./..."], effect: "allow" };
    await evaluatePermission(root, event, storage);
    assert.equal(event.effect, "allow");
  }
  assert.deepEqual(writes.map(([key]) => key), ["dirty/c", "dirty/s"]);
});

test("plugin re-checks raw shell per agent and closes delivery when agent is unknown", async () => {
  const hooks = {};
  const stored = new Map();
  await plugin.setup({
    location: { directory: root }, app: { version: "2.2.0" },
    storage: { set: async (key, value) => stored.set(key, value) },
    permission: { hook: async (name, callback) => { hooks[`permission.${name}`] = callback; } },
    shell: { hook: async (name, callback) => { hooks[`shell.${name}`] = callback; } },
  });
  const shell = hooks["shell.create.before"];
  assert.deepEqual(stored.get("loaded"), { version: "2.2.0" });
  assert.throws(() => shell({ command: "git status --short && gh pr merge 1", cwd: root }));
  assert.throws(() => shell({ agent: coordinator, command: "git status --short && git push origin feat/x", cwd: root }));
  assert.throws(() => shell({ agent: senior, command: "git status --short && gh pr merge 1", cwd: root }));
  assert.throws(() => shell({ command: "git merge main", cwd: root }));
  assert.doesNotThrow(() => shell({ command: "go mod tidy && go test ./...", cwd: join(root, "core") }));
  assert.doesNotThrow(() => shell({ agent: coordinator, command: "ls | wc -l", cwd: root }));
  assert.doesNotThrow(() => shell({ agent: senior, command: "ls | wc -l", cwd: root }));
  assert.throws(() => shell({ agent: "explore", command: "ls | wc -l", cwd: root }));
});

test("edit baseline allows source and task records but closes policy for unknown callers", () => {
  assert.doesNotThrow(() => assertEditBaseline(root, "App/Main.swift"));
  assert.doesNotThrow(() => assertEditBaseline(root, ".agents/tasks/wp-01.md"));
  for (const path of [".agents/hiraku/guard.mjs", ".commandcode/settings.json", "AGENTS.md", ".env"]) {
    assert.throws(() => assertEditBaseline(root, path), path);
  }
});

test("shell baseline closes delivery but leaves role checks to role-aware hooks", () => {
  assert.doesNotThrow(() => assertShellBaseline(root, "git push -u origin feat/x"));
  assert.throws(() => assertShellBaseline(root, "make && gh pr merge 1"));
  assert.throws(() => assertShellBaseline(root, "ls", outside));
});

test("root keeps only shared entry docs; loose docs, reports and logs are rejected", () => {
  for (const path of ["CHANGELOG.md", "COPY.md", "ROADMAP.md", "Package.swift", "docs/plans/wp-01.md", ".agents/tmp/run.log"]) {
    assert.doesNotThrow(() => assertPathAccess(root, senior, "edit", path), path);
    assert.doesNotThrow(() => assertEditBaseline(root, path), path);
  }
  for (const path of ["M0_SPIKE.md", "notes.txt", "test-output.log", "plan.md", "result.json"]) {
    assert.throws(() => assertPathAccess(root, senior, "edit", path), path);
    assert.throws(() => assertEditBaseline(root, path), path);
  }
});

test("PR title and body must not credit AI", () => {
  mkdirSync(join(root, ".agents/tmp"), { recursive: true });
  writeFileSync(join(root, ".agents/tmp/pr-ok.md"), "## Summary\nAdd kana table.\n");
  writeFileSync(join(root, ".agents/tmp/pr-ai.md"), "## Summary\nAdd kana table.\n\n🤖 Generated by AI\n");
  writeFileSync(join(root, ".agents/tmp/pr-co.md"), "Body\n\nCo-authored-by: Claude <noreply@anthropic.com>\n");
  const open = (command) => () => assertShell(root, senior, command);
  assert.doesNotThrow(open('gh pr create --base develop --title "feat(core): kana" --body-file .agents/tmp/pr-ok.md'));
  assert.throws(open('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/pr-ai.md'), /AI/);
  assert.throws(open('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/pr-co.md'), /AI/);
  assert.throws(open('gh pr create --base develop --title "feat: x" --body "Generated with Claude Code"'), /AI/);
  assert.throws(open('gh pr create --base develop --title "feat: x" --body-file -'), /stdin/);
  assert.throws(open('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/missing.md'), /đọc/);
});

test("only the coordinator records a verdict and merges, both through delivery.mjs", () => {
  const sha = "a".repeat(40);
  const review = `node .agents/hiraku/delivery.mjs review 7 PASS --sha ${sha}`;
  const merge = `node .agents/hiraku/delivery.mjs merge 7 --sha ${sha}`;
  assert.doesNotThrow(() => assertShell(root, coordinator, review));
  assert.doesNotThrow(() => assertShell(root, coordinator, merge));
  for (const command of [review, merge]) {
    assert.throws(() => assertShell(root, senior, command), command);
    assert.throws(() => assertShell(root, "unknown", command), command);
  }
});

test("delivery.mjs rejects other paths, short SHAs and chained use", () => {
  const sha = "a".repeat(40);
  for (const command of [
    `node ./.agents/hiraku/delivery.mjs merge 7 --sha ${sha}`,
    `node /tmp/delivery.mjs merge 7 --sha ${sha}`,
    "node .agents/hiraku/delivery.mjs merge 7 --sha abc123",
    `node .agents/hiraku/delivery.mjs merge 7 --sha ${sha} --extra`,
    `echo x && node .agents/hiraku/delivery.mjs merge 7 --sha ${sha}; gh pr merge 7`,
  ]) {
    assert.throws(() => assertShell(root, coordinator, command), command);
  }
});

test("git and gh global options cannot hide delivery or bare force-push", () => {
  for (const command of ["git -C . push --force origin develop", "git --no-pager push -f origin feat/x"]) {
    assert.throws(() => assertShell(root, senior, command), command);
  }
  for (const command of ["git -C . merge develop", "git --no-pager merge develop", "gh -R owner/repo pr merge 23"]) {
    for (const agent of [coordinator, senior]) assert.throws(() => assertShell(root, agent, command), `${agent}: ${command}`);
  }
  assert.doesNotThrow(() => assertShell(root, senior, "git -c core.x=1 push origin feat/x"));
});

test("a squashed -n flag does not skip hooks", () => {
  assert.throws(() => assertShell(root, senior, "git commit -nm x"));
  assert.doesNotThrow(() => assertShell(root, senior, 'git commit -m "feat(core): x"'));
});

test("senior cannot set the runtime identity or start another agent CLI", () => {
  for (const command of ["HIRAKU_AGENT=hiraku-coordinator pi -p merge", "env HIRAKU_AGENT=x node a.mjs", "cd core && claude -p hi"]) {
    assert.throws(() => assertShell(root, senior, command), command);
  }
  assert.throws(() => assertShell(root, coordinator, "HIRAKU_AGENT=hiraku-senior pi -p x"));
  assert.doesNotThrow(() => assertShell(root, senior, "grep claude AGENTS.md"));
});

test("workflow policy docs are protected for every role", () => {
  for (const agent of [coordinator, senior]) {
    for (const path of ["docs/process/AGENT_WORKFLOW.md", "docs/process/GIT_WORKFLOW.md"]) {
      assert.throws(() => assertPathAccess(root, agent, "edit", path), `${agent}: ${path}`);
    }
  }
});

test("git options and binary paths cannot hide merge or bare force-push", () => {
  for (const command of [
    "git --no-advice merge develop", "git --bare merge develop", "git -Cdir push --force origin develop",
    "/usr/bin/git merge develop", "git --git-dir .git merge develop", "git --no-advice push --force origin develop",
  ]) {
    for (const agent of [coordinator, senior]) {
      if (/merge/.test(command) && agent === senior) continue;
      assert.throws(() => assertShell(root, agent, command), `${agent}: ${command}`);
    }
  }
  assert.doesNotThrow(() => assertShell(root, senior, "git --no-advice push --force-with-lease origin feat/x"));
});

test("quoted or path-qualified identity escalation is denied for senior", () => {
  for (const command of [
    'H"IRAKU"_AGENT=hiraku-coordinator pi -p merge', 'HIRAKU_AG""ENT=x pi -p merge',
    "/usr/local/bin/pi -p merge", "/usr/bin/env FOO=1 claude -p hi", "FOO=1 opencode run x",
  ]) {
    assert.throws(() => assertShell(root, senior, command), command);
  }
  assert.throws(() => assertShell(root, coordinator, 'H"IRAKU"_AGENT=hiraku-senior pi -p x'));
  assert.doesNotThrow(() => assertShell(root, senior, "grep claude AGENTS.md"));
});
