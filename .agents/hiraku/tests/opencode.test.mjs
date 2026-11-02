import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const root = fileURLToPath(new URL("../../../", import.meta.url));
const config = JSON.parse(readFileSync(join(root, "opencode.json"), "utf8"));
const coordinator = "hiraku-coordinator";
const senior = "hiraku-senior";

function matches(pattern, value) {
  const expression = pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replaceAll("*", ".*").replaceAll("?", ".");
  return new RegExp(`^${expression}$`).test(value);
}

function permission(agent, action, resource) {
  const rules = [...config.permissions, ...(config.agents[agent]?.permissions ?? [])];
  return rules.filter((rule) => matches(rule.action, action) && matches(rule.resource, resource))
    .at(-1)?.effect ?? "ask";
}

test("opencode runs the coordinator by default; builtins that could bypass roles stay disabled", () => {
  assert.equal(config.default_agent, coordinator);
  assert.equal(config.share, "disabled");
  assert.equal(config.update, "notify");
  for (const id of ["build", "plan", "general", "explore"]) assert.equal(config.agents[id].disabled, true, id);
  for (const legacy of ["agent", "permission", "plugin"]) assert.equal(legacy in config, false);
  assert.equal("model" in config, false);
  assert.equal("providers" in config, false);
});

for (const id of [coordinator, senior]) {
  test(`${id} is discoverable with the intended mode and default-deny delivery`, () => {
    const body = readFileSync(join(root, `.opencode/agents/${id}.md`), "utf8");
    assert.match(body, /^---\ndescription: .+\nmode: (primary|subagent)\n---/);
    assert.match(body, new RegExp(`mode: ${id === coordinator ? "primary" : "subagent"}`));
    for (const command of ["git merge main", "gh pr merge 1", "gh release create v1", "xcrun altool"]) {
      assert.equal(permission(id, "shell", command), "deny");
    }
    assert.equal(permission(id, "external_directory", "/outside/*"), "deny");
    assert.equal(permission(id, "some_mcp_tool", "*"), "deny");
    assert.equal(permission(id, "execute", "*"), "allow");
  });
}

test("only the coordinator delegates, and only to the senior", () => {
  assert.equal(permission(coordinator, "subagent", senior), "allow");
  assert.equal(permission(coordinator, "subagent", "general"), "deny");
  assert.equal(permission(senior, "subagent", coordinator), "deny");
  assert.equal(permission(senior, "subagent", senior), "deny");
});

test("edit rights: coordinator edits only task records and scratch; senior edits source", () => {
  assert.equal(permission(coordinator, "edit", "App/Main.swift"), "deny");
  assert.equal(permission(coordinator, "edit", ".agents/tasks/wp-01.md"), "allow");
  assert.equal(permission(coordinator, "edit", ".agents/tmp/notes.md"), "allow");
  assert.equal(permission(senior, "edit", "App/Main.swift"), "allow");
});

test("both roles run arbitrary non-delivery shell; rebase is senior-only", () => {
  for (const id of [coordinator, senior]) {
    for (const command of ["go mod tidy", "brew list", "xcodebuild -list", "make spike"]) {
      assert.equal(permission(id, "shell", command), "allow", `${id}: ${command}`);
    }
    assert.equal(permission(id, "shell", "git merge develop"), "deny");
  }
  assert.equal(permission(senior, "shell", "git rebase develop"), "allow");
  assert.equal(permission(coordinator, "shell", "git rebase develop"), "deny");
});

test("only the senior commits, pushes and opens pull requests", () => {
  assert.equal(permission(coordinator, "shell", "git commit -m x"), "deny");
  assert.equal(permission(coordinator, "shell", "git push -u origin feat/x"), "deny");
  assert.equal(permission(coordinator, "shell", "gh pr create --base develop"), "deny");
  assert.equal(permission(senior, "shell", "git commit -m x"), "allow");
  assert.equal(permission(senior, "shell", "git push --force-with-lease origin feat/x"), "allow");
  assert.equal(permission(senior, "shell", "gh pr create --base develop"), "allow");
  assert.equal(permission(senior, "shell", "gh pr merge 1"), "deny");
});

test("opencode grants each skill only to the roles that use it", () => {
  const grants = {
    [coordinator]: ["hiraku-task", "hiraku-review", "hiraku-ship", "hiraku-wp-status"],
    [senior]: ["hiraku-coding", "hiraku-create-pr", "hiraku-contract", "hiraku-feature", "hiraku-spike-report",
      "hiraku-wp-status", "golang-testing", "swift-concurrency-6-2", "swift-protocol-di-testing",
      "liquid-glass-design", "accessibility"],
  };
  const all = [...new Set(Object.values(grants).flat())];
  for (const [role, skills] of Object.entries(grants)) {
    for (const skill of all) {
      assert.equal(permission(role, "skill", skill), skills.includes(skill) ? "allow" : "deny", `${role}/${skill}`);
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
