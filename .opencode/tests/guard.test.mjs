import { after, test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { assertPathAccess, assertShell, evaluatePermission } from "../lib/guard.mjs";
import plugin from "../plugins/hiraku-guard/index.js";

const fixture = mkdtempSync(join(tmpdir(), "hiraku-guard-"));
const root = join(fixture, "project");
const outside = join(fixture, "outside");
mkdirSync(root);
mkdirSync(outside);
mkdirSync(join(root, "core"));
symlinkSync(outside, join(root, "escape"));
mkdirSync(join(root, ".opencode"));
symlinkSync(join(root, ".opencode"), join(root, "policy-alias"));
after(() => rmSync(fixture, { recursive: true }));

test("coder can edit a new product file", () => {
  assert.doesNotThrow(() => assertPathAccess(root, "hiraku-coder", "edit", "core/domain/kana/kana.go"));
});

for (const agent of ["hiraku-lead", "hiraku-reviewer", "hiraku-shipper", "general"]) {
  test(`${agent} cannot edit product source`, () => {
    assert.throws(() => assertPathAccess(root, agent, "edit", "App/Main.swift"));
  });
}

for (const path of [
  "opencode.json", "AGENTS.md", "DECISIONS.md", "RELEASE.md",
  ".opencode/plugins/hiraku-guard/index.js", ".opencode/tests/guard.test.mjs",
  ".pi/settings.json", ".pi/extensions/hiraku-guard.ts",
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
    assert.doesNotThrow(() => assertPathAccess(root, agent, "edit", ".opencode/tasks/wp-01.md"));
  }
  assert.throws(() => assertPathAccess(root, "hiraku-coder", "edit", ".opencode/tasks/wp-01.md"));
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

test("only permitted root inspection commands run for lead", () => {
  assert.doesNotThrow(() => assertShell(root, "hiraku-lead", "git status --short"));
  assert.throws(() => assertShell(root, "hiraku-lead", "go test ./...", join(root, "core")));
});

test("core tests require the real core working directory", () => {
  assert.doesNotThrow(() => assertShell(root, "hiraku-reviewer", "go test -race ./...", join(root, "core")));
  assert.throws(() => assertShell(root, "hiraku-reviewer", "go test -race ./..."));
});

test("coder can generate but reviewer cannot", () => {
  assert.doesNotThrow(() => assertShell(root, "hiraku-coder", "buf generate"));
  assert.throws(() => assertShell(root, "hiraku-reviewer", "buf generate"));
});

for (const command of [
  "git push", "gh pr merge 1", "gh api repos/owner/repo/releases",
  "node -e 'process.exit()'", "python3 -c 'print(1)'",
  "git status --short && git push", "git status --short; git push",
  "git status --short\nnode script.js", "go test ./... -exec sh",
  "swift test --package-path ../../outside", "buf generate; git push",
]) {
  test(`reject shell bypass ${JSON.stringify(command)}`, () => {
    assert.throws(() => assertShell(root, "hiraku-coder", command));
  });
}

test("test package cannot resolve outside workspace through a symlink", () => {
  mkdirSync(join(root, "Packages"));
  symlinkSync(outside, join(root, "Packages/External"));
  assert.throws(() => assertShell(root, "hiraku-coder", "swift test --package-path Packages/External"));
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

test("subagents cannot delegate recursively", async () => {
  const event = {
    action: "subagent", agent: "hiraku-coder", sessionID: "test",
    resources: ["hiraku-reviewer"], effect: "allow",
  };
  await evaluatePermission(root, event, {});
  assert.equal(event.effect, "deny");
});

test("plugin registers v2 hooks and raw-shell guard rejects a compound command", async () => {
  const hooks = {};
  const stored = new Map();
  await plugin.setup({
    location: { directory: root }, app: { version: "2.2.0" },
    storage: { set: async (key, value) => stored.set(key, value) },
    permission: { hook: async (name, callback) => { hooks[`permission.${name}`] = callback; } },
    shell: { hook: async (name, callback) => { hooks[`shell.${name}`] = callback; } },
  });
  assert.deepEqual(stored.get("loaded"), { version: "2.2.0" });
  assert.throws(() => hooks["shell.create.before"]({ command: "git status --short && git push", cwd: root }));
  assert.doesNotThrow(() => hooks["shell.create.before"]({ command: "git status --short", cwd: root }));
});
