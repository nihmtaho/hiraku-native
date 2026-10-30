import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const root = fileURLToPath(new URL("../../../", import.meta.url));
const config = JSON.parse(readFileSync(join(root, "opencode.json"), "utf8"));

function matches(pattern, value) {
  const expression = pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replaceAll("*", ".*").replaceAll("?", ".");
  return new RegExp(`^${expression}$`).test(value);
}

function permission(agent, action, resource) {
  const rules = [...config.permissions, ...config.agents[agent].permissions];
  return rules.filter((rule) => matches(rule.action, action) && matches(rule.resource, resource))
    .at(-1)?.effect ?? "ask";
}

test("native v2 configuration keeps scoped builtins and models external", () => {
  assert.equal(config.default_agent, "hiraku-lead");
  assert.equal(config.share, "disabled");
  assert.equal(config.update, "notify");
  assert.equal(config.agents.build.disabled, true);
  for (const id of ["plan", "general", "explore"]) assert.notEqual(config.agents[id].disabled, true);
  for (const id of ["plan", "explore"]) {
    assert.equal(permission(id, "edit", "App/Main.swift"), "deny");
    assert.equal(permission(id, "shell", "rm -rf core"), "deny");
  }
  assert.equal(permission("general", "edit", "App/Main.swift"), "allow");
  for (const legacy of ["agent", "permission", "plugin"]) assert.equal(legacy in config, false);
  assert.equal("model" in config, false);
  assert.equal("providers" in config, false);
});

for (const id of ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper"]) {
  test(`${id} is discoverable with the intended role and default-deny delivery`, () => {
    const body = readFileSync(join(root, `.opencode/agents/${id}.md`), "utf8");
    assert.match(body, /^---\ndescription: .+\nmode: (primary|subagent)\n(model: \S+\n)?---/);
    assert.match(body, new RegExp(`mode: ${id === "hiraku-lead" ? "primary" : "subagent"}`));
    for (const command of ["git merge main", "gh pr merge 1", "gh release create v1", "xcrun altool"]) {
      assert.equal(permission(id, "shell", command), "deny");
    }
    assert.equal(permission(id, "external_directory", "/outside/*"), "deny");
    assert.equal(permission(id, "some_mcp_tool", "*"), "deny");
    assert.equal(permission(id, "execute", "*"), "allow");
  });
}

test("lead alone delegates and subagents cannot recurse", () => {
  for (const id of ["hiraku-coder", "hiraku-reviewer", "hiraku-shipper"]) {
    assert.equal(permission("hiraku-lead", "subagent", id), "allow");
    assert.equal(permission(id, "subagent", "hiraku-coder"), "deny");
  }
  for (const id of ["explore", "general"]) assert.equal(permission("hiraku-lead", "subagent", id), "allow");
  assert.equal(permission("hiraku-coder", "subagent", "explore"), "allow");
  assert.equal(permission("hiraku-coder", "subagent", "general"), "deny");
  assert.equal(permission("explore", "subagent", "general"), "deny");
  assert.equal(permission("hiraku-reviewer", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-lead", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-shipper", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-coder", "edit", "App/Main.swift"), "allow");
});

test("every hiraku role and general run any non-delivery shell; explore and plan only read", () => {
  for (const id of ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper", "general"]) {
    for (const command of ["go mod tidy", "brew list", "xcodebuild -list", "make spike"]) {
      assert.equal(permission(id, "shell", command), "allow");
    }
    assert.equal(permission(id, "shell", "git merge develop"), "deny");
  }
  for (const id of ["explore", "plan"]) {
    assert.equal(permission(id, "shell", "go test ./..."), "deny");
    assert.equal(permission(id, "shell", "git log --oneline"), "allow");
  }
});

test("only coder commits and pushes; only shipper opens pull requests", () => {
  for (const id of ["hiraku-lead", "general", "hiraku-reviewer", "hiraku-shipper"]) {
    assert.equal(permission(id, "shell", "git commit -m x"), "deny");
    assert.equal(permission(id, "shell", "git push -u origin feat/x"), "deny");
  }
  assert.equal(permission("hiraku-coder", "shell", "git commit -m x"), "allow");
  assert.equal(permission("hiraku-coder", "shell", "git push -u origin feat/x"), "allow");
  for (const id of ["hiraku-lead", "hiraku-coder", "general", "hiraku-reviewer"]) {
    assert.equal(permission(id, "shell", "gh pr create --base develop"), "deny");
  }
  assert.equal(permission("hiraku-shipper", "shell", "gh pr create --base develop"), "allow");
});

test("opencode grants each skill only to the roles that use it", () => {
  const grants = {
    "hiraku-contract": ["hiraku-coder", "hiraku-reviewer"],
    "hiraku-feature": ["hiraku-coder", "hiraku-reviewer"],
    "hiraku-spike-report": ["hiraku-coder", "hiraku-reviewer"],
    "hiraku-task": ["hiraku-lead", "hiraku-reviewer"],
    "hiraku-wp-status": ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper"],
    ...Object.fromEntries(["swift-concurrency-6-2", "swift-protocol-di-testing", "golang-testing",
      "liquid-glass-design", "accessibility"].map((id) => [id, ["hiraku-coder", "hiraku-reviewer"]])),
  };
  for (const [skill, roles] of Object.entries(grants)) {
    for (const role of ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper"]) {
      assert.equal(permission(role, "skill", skill), roles.includes(role) ? "allow" : "deny", `${role}/${skill}`);
    }
  }
});

test("opencode config has no project-local skills, tasks or guard copies", () => {
  for (const path of [".opencode/skills", ".opencode/tasks", ".opencode/lib", ".opencode/templates"]) {
    assert.equal(existsSync(join(root, path)), false, path);
  }
  const plugin = readFileSync(join(root, ".opencode/plugins/hiraku-guard/index.js"), "utf8");
  assert.match(plugin, /\.agents\/hiraku\/guard\.mjs/);
});

test("shared task, release and validation references exist", () => {
  for (const path of [
    "AGENTS.md", "docs/architecture/ARCHITECTURE.md", "docs/architecture/DECISIONS.md",
    "docs/process/RELEASE.md", "docs/process/TEST_PLAN.md", ".agents/templates/task.md", "docs/process/AGENT_WORKFLOW.md",
    ".opencode/plugins/hiraku-guard/index.js", ".agents/hiraku/guard.mjs",
  ]) assert.ok(existsSync(join(root, path)), path);
  const task = readFileSync(join(root, ".agents/templates/task.md"), "utf8");
  assert.match(task, /head SHA/);
  assert.match(task, /Independent review/);
  assert.match(task, /PO approval/);
});
