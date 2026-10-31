import { after, test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { assertEditBaseline, assertPathAccess, assertShell, assertShellBaseline, evaluatePermission } from "../guard.mjs";
import plugin from "../../../.opencode/plugins/hiraku-guard/index.js";

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

test("coder can edit a new product file", () => {
  assert.doesNotThrow(() => assertPathAccess(root, "hiraku-coder", "edit", "core/domain/kana/kana.go"));
});

for (const agent of ["hiraku-lead", "hiraku-reviewer", "hiraku-shipper", "explore", "plan"]) {
  test(`${agent} cannot edit product source`, () => {
    assert.throws(() => assertPathAccess(root, agent, "edit", "App/Main.swift"));
  });
}

for (const path of [
  "opencode.json", "AGENTS.md", "docs/architecture/DECISIONS.md", "docs/process/RELEASE.md",
  ".opencode/plugins/hiraku-guard/index.js", ".opencode/agents/hiraku-coder.md",
  ".agents/hiraku/guard.mjs", ".agents/hiraku/roles/coder.md", ".agents/skills/hiraku-contract/SKILL.md",
  ".commandcode/settings.json", ".commandcode/agents/hiraku-coder.md", ".pi/agents/hiraku-coder.md",
  ".pi/extensions/hiraku-guard.ts",
  ".github/workflows/ci.yml", "core/gen/hirakuv1/study.pb.go",
  "Packages/HirakuBridge/Generated/Study.swift", "Scripts/check-imports.sh",
  "core/scripts/check-core.sh", ".git/config", "policy-alias/agents/fake.md",
]) {
  test(`coder cannot edit protected path ${path}`, () => {
    assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", path));
  });
}

test("multi-role task ownership is limited to lead and shipper", () => {
  for (const agent of ["hiraku-lead", "hiraku-shipper"]) {
    assert.doesNotThrow(() => assertPathAccess(root, agent, "edit", ".agents/tasks/wp-01.md"));
  }
  assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", ".agents/tasks/wp-01.md"));
});

for (const path of ["../outside/file", "escape/new/file", "/etc/passwd"]) {
  test(`reject external access ${path}`, () => {
    assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", path));
  });
}

for (const path of [".env", ".env.local", "AuthKey.p8", "signing.p12", "private.key", "dev.pem"]) {
  test(`deny credential read ${path}`, () => {
    assert.throws(() => assertPathAccess(root, "hiraku-reviewer", "read", path));
  });
}

test("example environment file is readable", () => {
  assert.doesNotThrow(() => assertPathAccess(root, "hiraku-coder", "read", ".env.example"));
});

test("malformed path fails closed", () => {
  assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", ""));
});

test("general edits source but not policy", () => {
  assert.doesNotThrow(() => assertPathAccess(root, "general", "edit", "App/Main.swift"));
  assert.throws(() => assertPathAccess(root, "general", "edit", "opencode.json"));
});

test("every hiraku role and general run arbitrary non-delivery commands", () => {
  for (const agent of ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper", "general"]) {
    for (const command of [
      "buf generate", "go mod tidy", "go test ./... | tail -5", "brew install buf",
      "python3 scripts/x.py", "cd core && go test -race ./...", "git checkout -b feat/x",
      "cd /tmp/x && find core -type f -not -path '*/.spike/*' | sort && cat core/go.mod",
      "cd core && go vet ./...; echo EXIT:$?",
      "git add -A",
    ]) assert.doesNotThrow(() => assertShell(root, agent, command), `${agent}: ${command}`);
  }
  assert.doesNotThrow(() => assertShell(root, "hiraku-coder", "go mod init hiraku/core", join(root, "core")));
});

for (const command of [
  "git merge main", "git status --short && git tag v1", "go test ./...; git rebase develop",
  "echo x | gh pr merge 1", "gh api repos/owner/repo/releases", "(git merge main)",
  "xcrun altool --upload-app", "xcrun notarytool submit", "fastlane beta", "git reset --hard HEAD~1",
]) {
  test(`delivery stays closed for every agent ${JSON.stringify(command)}`, () => {
    for (const agent of ["hiraku-lead", "hiraku-coder", "general", "hiraku-reviewer"]) {
      assert.throws(() => assertShell(root, agent, command));
    }
  });
}

test("coder commits and pushes only task branches", () => {
  for (const command of [
    'git add -A && git commit -m "feat(core): add kana table"',
    "git push -u origin feat/wp-01-core", "git push origin fix/q-21-normalize",
  ]) assert.doesNotThrow(() => assertShell(root, "hiraku-coder", command), command);
  for (const command of [
    "git push origin develop", "git push origin main", "git push -f origin feat/x",
    "git push --force-with-lease origin feat/x", "git push origin feat/x:develop",
    "git commit --amend -m x", "git commit --no-verify -m x", "echo $(git push origin feat/x)",
    "gh pr create --base develop",
  ]) assert.throws(() => assertShell(root, "hiraku-coder", command), command);
  for (const agent of ["hiraku-lead", "general", "hiraku-reviewer", "hiraku-shipper"]) {
    assert.throws(() => assertShell(root, agent, "git commit -m x"));
    assert.throws(() => assertShell(root, agent, "git push -u origin feat/x"));
  }
});

test("shipper opens pull requests into develop only", () => {
  mkdirSync(join(root, ".agents/tasks"), { recursive: true });
  writeFileSync(join(root, ".agents/tasks/wp-04.md"), "PR body\n");
  for (const command of [
    'gh pr create --base develop --title "feat(core): kana" --body-file .agents/tasks/wp-04.md',
    "gh pr view 3", "gh pr checks 3",
  ]) assert.doesNotThrow(() => assertShell(root, "hiraku-shipper", command), command);
  for (const command of [
    "gh pr create --base main --title x", "gh pr create --title x",
    "gh pr create --base develop --base main", "gh pr merge 3 --squash",
  ]) assert.throws(() => assertShell(root, "hiraku-shipper", command), command);
  for (const agent of ["hiraku-lead", "hiraku-coder", "general"]) {
    assert.throws(() => assertShell(root, agent, "gh pr create --base develop --title x"));
  }
});

test("shell cwd must stay inside the workspace", () => {
  assert.throws(() => assertShell(root, "hiraku-coder", "ls", outside));
  assert.throws(() => assertShell(root, "hiraku-lead", "ls", join(root, "escape")));
});

test("explore and plan only inspect", () => {
  for (const agent of ["explore", "plan"]) {
    assert.doesNotThrow(() => assertShell(root, agent, "git diff --stat"));
    assert.throws(() => assertShell(root, agent, "go test ./..."));
  }
  assert.throws(() => assertShell(root, "unknown", "git status"));
});

test("patch touching product and protected file is denied as a whole", async () => {
  const event = {
    action: "edit", agent: "hiraku-coder", sessionID: "test",
    resources: ["App/Main.swift", ".opencode/package.json"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: () => assert.fail("denied edit must not be recorded as allowed") });
  assert.equal(event.effect, "deny");
});

test("an allowed mutation invalidates prior review conservatively", async () => {
  const writes = [];
  const event = {
    action: "edit", agent: "hiraku-coder", sessionID: "test",
    resources: ["App/Main.swift"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: async (...args) => writes.push(args) });
  assert.equal(event.effect, "allow");
  assert.deepEqual(writes, [["dirty/test", { agent: "hiraku-coder", reviewInvalidated: true }]]);
});

test("storage failure denies mutation instead of losing review invalidation", async () => {
  const event = {
    action: "edit", agent: "hiraku-coder", sessionID: "test",
    resources: ["App/Main.swift"], effect: "allow",
  };
  await evaluatePermission(root, event, { set: async () => { throw new Error("storage unavailable"); } });
  assert.equal(event.effect, "deny");
  assert.match(event.message, /storage unavailable/);
});

test("subagents cannot delegate recursively; lead may use explore and general", async () => {
  for (const [agent, target, effect] of [
    ["hiraku-coder", "hiraku-reviewer", "deny"], ["hiraku-coder", "explore", "allow"],
    ["explore", "general", "deny"], ["general", "hiraku-coder", "deny"],
    ["hiraku-lead", "general", "allow"], ["hiraku-lead", "explore", "allow"],
  ]) {
    const event = { action: "subagent", agent, sessionID: "t", resources: [target], effect: "allow" };
    await evaluatePermission(root, event, {});
    assert.equal(event.effect, effect, `${agent} -> ${target}`);
  }
});

test("shell permission records review invalidation for full-shell agents only", async () => {
  const writes = [];
  const storage = { set: async (...args) => writes.push(args) };
  const coder = { action: "shell", agent: "hiraku-coder", sessionID: "c", resources: ["go mod tidy"], effect: "allow" };
  await evaluatePermission(root, coder, storage);
  assert.equal(coder.effect, "allow");
  const reviewer = { action: "shell", agent: "hiraku-reviewer", sessionID: "r", resources: ["go test ./..."], effect: "allow" };
  await evaluatePermission(root, reviewer, storage);
  assert.equal(reviewer.effect, "allow");
  assert.deepEqual(writes.map(([key]) => key), ["dirty/c"]);
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
  assert.throws(() => shell({ agent: "hiraku-lead", command: "git status --short && git push origin feat/x", cwd: root }));
  assert.throws(() => shell({ command: "git merge main", cwd: root }));
  assert.doesNotThrow(() => shell({ command: "go mod tidy && go test ./...", cwd: join(root, "core") }));
  assert.doesNotThrow(() => shell({ agent: "hiraku-lead", command: "ls | wc -l", cwd: root }));
  assert.doesNotThrow(() => shell({ agent: "hiraku-reviewer", command: "ls | wc -l", cwd: root }));
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
    assert.doesNotThrow(() => assertPathAccess(root, "hiraku-coder", "edit", path), path);
    assert.doesNotThrow(() => assertEditBaseline(root, path), path);
  }
  for (const path of ["M0_SPIKE.md", "notes.txt", "test-output.log", "plan.md", "result.json"]) {
    assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", path), path);
    assert.throws(() => assertEditBaseline(root, path), path);
  }
});

test("PR title and body must not credit AI", () => {
  mkdirSync(join(root, ".agents/tmp"), { recursive: true });
  writeFileSync(join(root, ".agents/tmp/pr-ok.md"), "## Summary\nAdd kana table.\n");
  writeFileSync(join(root, ".agents/tmp/pr-ai.md"), "## Summary\nAdd kana table.\n\n🤖 Generated by AI\n");
  writeFileSync(join(root, ".agents/tmp/pr-co.md"), "Body\n\nCo-authored-by: Claude <noreply@anthropic.com>\n");
  const ship = (command) => () => assertShell(root, "hiraku-shipper", command);
  assert.doesNotThrow(ship('gh pr create --base develop --title "feat(core): kana" --body-file .agents/tmp/pr-ok.md'));
  assert.throws(ship('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/pr-ai.md'), /AI/);
  assert.throws(ship('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/pr-co.md'), /AI/);
  assert.throws(ship('gh pr create --base develop --title "feat: x" --body "Generated with Claude Code"'), /AI/);
  assert.throws(ship('gh pr create --base develop --title "feat: x" --body-file -'), /stdin/);
  assert.throws(ship('gh pr create --base develop --title "feat: x" --body-file .agents/tmp/missing.md'), /đọc/);
});

test("only Reviewer records a verdict and only Shipper merges, both through delivery.mjs", () => {
  const sha = "a".repeat(40);
  const review = `node .agents/hiraku/delivery.mjs review 7 PASS --sha ${sha}`;
  const merge = `node .agents/hiraku/delivery.mjs merge 7 --sha ${sha}`;
  assert.doesNotThrow(() => assertShell(root, "hiraku-reviewer", review));
  assert.doesNotThrow(() => assertShell(root, "hiraku-shipper", merge));
  for (const agent of ["hiraku-lead", "hiraku-coder", "general", "hiraku-shipper"]) {
    assert.throws(() => assertShell(root, agent, review), agent);
  }
  for (const agent of ["hiraku-lead", "hiraku-coder", "general", "hiraku-reviewer"]) {
    assert.throws(() => assertShell(root, agent, merge), agent);
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
    assert.throws(() => assertShell(root, "hiraku-shipper", command), command);
  }
});
