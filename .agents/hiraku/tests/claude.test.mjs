import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { root } from "../sync.mjs";
import { decide } from "../../../.claude/hooks/guard.mjs";

const settings = JSON.parse(readFileSync(join(root, ".claude/settings.json"), "utf8"));
const agentFile = (name) => readFileSync(join(root, `.claude/agents/${name}.md`), "utf8");

test("claude has the two hiraku agents and runs the main session as the coordinator", () => {
  assert.deepEqual(readdirSync(join(root, ".claude/agents")).sort(),
    ["hiraku-coordinator.md", "hiraku-senior.md"]);
  assert.equal(settings.agent, "hiraku-coordinator");
  assert.match(agentFile("hiraku-coordinator"), /Agent\(hiraku-senior\)/);
  assert.doesNotMatch(agentFile("hiraku-senior"), /Agent\(/);
});

test("neither role is pinned to a cheap model", () => {
  assert.doesNotMatch(agentFile("hiraku-coordinator"), /^model:/m);
  assert.doesNotMatch(agentFile("hiraku-senior"), /^model:/m);
});

test("settings close delivery and policy, keep shell open, drop AI attribution, wire the hook", () => {
  const { allow, deny } = settings.permissions;
  assert.ok(allow.includes("Bash"));
  for (const rule of ["Bash(git merge *)", "Bash(gh pr merge *)", "Bash(gh api *)", "Edit(/.agents/hiraku/**)", "Edit(/.claude/hooks/**)", "Edit(/.claude/agents/**)", "Edit(/.claude/settings.json)"]) {
    assert.ok(deny.includes(rule), rule);
  }
  assert.ok(!deny.some((rule) => /git (push|commit)|gh pr create|delivery\.mjs/.test(rule)));
  assert.deepEqual(settings.attribution, { commit: "", pr: "" });
  assert.match(settings.hooks.PreToolUse[0].hooks[0].command, /\.claude\/hooks\/guard\.mjs/);
});

const call = (agent_type, tool_name, tool_input) => () => decide({ agent_type, tool_name, tool_input, cwd: root });

test("hook applies the closed paths to every caller, known or not", () => {
  for (const agent of [undefined, "hiraku-senior", "general-purpose"]) {
    assert.throws(call(agent, "Bash", { command: "go test ./... && git tag v1" }), String(agent));
    assert.throws(call(agent, "Read", { file_path: join(root, "AuthKey.p8") }), String(agent));
    assert.throws(call(agent, "Edit", { file_path: ".claude/settings.json" }), String(agent));
  }
});

test("hook applies the role of the calling agent", () => {
  const sha = "a".repeat(40);
  assert.doesNotThrow(call("hiraku-senior", "Bash", { command: 'git commit -m "feat(core): x"' }));
  assert.doesNotThrow(call("hiraku-senior", "Edit", { file_path: "App/Main.swift" }));
  assert.throws(call("hiraku-coordinator", "Edit", { file_path: "App/Main.swift" }));
  assert.doesNotThrow(call("hiraku-coordinator", "Write", { file_path: ".agents/tasks/wp-01.md" }));
  assert.throws(call("hiraku-coordinator", "Bash", { command: 'git commit -m "x"' }));
  assert.doesNotThrow(call("hiraku-coordinator", "Bash", { command: `node .agents/hiraku/delivery.mjs review 7 PASS --sha ${sha}` }));
  assert.throws(call("hiraku-senior", "Bash", { command: `node .agents/hiraku/delivery.mjs review 7 PASS --sha ${sha}` }));
  assert.doesNotThrow(call("hiraku-coordinator", "Bash", { command: `node .agents/hiraku/delivery.mjs merge 7 --sha ${sha}` }));
  assert.throws(call("hiraku-senior", "Bash", { command: `node .agents/hiraku/delivery.mjs merge 7 --sha ${sha}` }));
  assert.throws(call("Explore", "Bash", { command: "git merge main" }));
  assert.doesNotThrow(call("Explore", "Bash", { command: "git status" }));
});
