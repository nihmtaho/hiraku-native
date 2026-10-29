import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { join } from "node:path";

const root = fileURLToPath(new URL("../../", import.meta.url));
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

test("native v2 configuration disables broad builtins and keeps models external", () => {
  assert.equal(config.default_agent, "hiraku-lead");
  assert.equal(config.share, "disabled");
  assert.equal(config.update, "notify");
  for (const id of ["build", "plan", "general", "explore"]) {
    assert.equal(config.agents[id].disabled, true);
  }
  for (const legacy of ["agent", "permission", "plugin"]) assert.equal(legacy in config, false);
  assert.equal("model" in config, false);
  assert.equal("providers" in config, false);
});

for (const id of ["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper"]) {
  test(`${id} is discoverable with the intended role and default-deny delivery`, () => {
    const body = readFileSync(join(root, `.opencode/agents/${id}.md`), "utf8");
    assert.match(body, /^---\ndescription: .+\nmode: (primary|subagent)\n---/);
    assert.match(body, new RegExp(`mode: ${id === "hiraku-lead" ? "primary" : "subagent"}`));
    for (const command of ["git push", "git commit -m done", "gh pr merge 1", "xcrun altool"]) {
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
  assert.equal(permission("hiraku-lead", "subagent", "general"), "deny");
  assert.equal(permission("hiraku-reviewer", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-lead", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-shipper", "edit", "App/Main.swift"), "deny");
  assert.equal(permission("hiraku-coder", "edit", "App/Main.swift"), "allow");
});

test("only two scoped skills exist and both have scenario evals", () => {
  const directory = join(root, ".opencode/skills");
  assert.deepEqual(readdirSync(directory).sort(), ["hiraku-contract", "hiraku-feature"]);
  for (const id of readdirSync(directory)) {
    const body = readFileSync(join(directory, id, "SKILL.md"), "utf8");
    assert.match(body, new RegExp(`^---\\nname: ${id}\\n`));
    assert.match(body, /description: .+/);
    assert.match(body, /Nếu đang review/);
    assert.match(body, /BLOCKED/);
    const evals = JSON.parse(readFileSync(join(directory, id, "evals/evals.json"), "utf8"));
    assert.equal(evals.skill_name, id);
    assert.equal(evals.evals.length, 2);
    for (const scenario of evals.evals) {
      assert.ok(scenario.prompt.length > 30);
      assert.ok(scenario.assertions.length >= 3);
    }
    for (const role of ["hiraku-coder", "hiraku-reviewer"]) {
      assert.equal(permission(role, "skill", id), "allow");
    }
    assert.equal(permission("hiraku-lead", "skill", id), "deny");
    assert.equal(permission("hiraku-shipper", "skill", id), "deny");
  }
});

test("shared task, release and validation references exist", () => {
  for (const path of [
    "AGENTS.md", "ARCHITECTURE.md", "DECISIONS.md", "OPENCODE.md",
    "RELEASE.md", "TEST_PLAN.md", ".opencode/templates/task.md",
    ".opencode/plugins/hiraku-guard/index.js", ".opencode/lib/guard.mjs",
  ]) assert.ok(existsSync(join(root, path)), path);
  const task = readFileSync(join(root, ".opencode/templates/task.md"), "utf8");
  assert.match(task, /head SHA/);
  assert.match(task, /Independent review/);
  assert.match(task, /PO approval/);
});
