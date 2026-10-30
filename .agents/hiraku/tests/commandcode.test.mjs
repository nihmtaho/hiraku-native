import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { root } from "../sync.mjs";
import { decide } from "../../../.commandcode/hooks/guard.mjs";
import roles from "../../../.commandcode/mods/hiraku-roles.ts";

const settings = JSON.parse(readFileSync(join(root, ".commandcode/settings.json"), "utf8"));

test("commandcode has its own subagents; Lead is the main session, not a subagent", () => {
  assert.deepEqual(readdirSync(join(root, ".commandcode/agents")).sort(),
    ["hiraku-coder.md", "hiraku-reviewer.md", "hiraku-shipper.md"]);
  const reviewer = readFileSync(join(root, ".commandcode/agents/hiraku-reviewer.md"), "utf8");
  assert.match(reviewer, /^---\nname: hiraku-reviewer\n/);
  assert.match(reviewer, /disallowedTools: edit_file, write_file/);
  assert.doesNotMatch(readFileSync(join(root, ".commandcode/lead.md"), "utf8"), /^---/);
});

test("settings close delivery for everyone, keep shell open and wire both hooks", () => {
  const { allow, deny } = settings.permissions;
  assert.ok(allow.includes("Shell"));
  for (const rule of ["Shell(git merge *)", "Shell(gh pr merge *)", "Shell(gh release *)", "Shell(xcrun altool *)", "Edit(/.agents/hiraku/**)", "Edit(/.commandcode/**)"]) {
    assert.ok(deny.includes(rule), rule);
  }
  assert.ok(!deny.some((rule) => /git (push|commit)|gh pr create/.test(rule)));
  assert.equal(settings.attribution.commit, "");
  assert.match(settings.hooks.PreToolUse[0].hooks[0].command, /\.commandcode\/hooks\/guard\.mjs/);
  assert.equal("matcher" in settings.hooks.SessionStart[0], false);
});

test("PreToolUse hook denies delivery, secrets and policy edits for every caller", () => {
  const call = (tool_name, tool_input) => () => decide({ tool_name, tool_input, cwd: root });
  assert.throws(call("shell_command", { command: "go test ./... && git tag v1" }));
  assert.throws(call("shell_command", { command: "ls", directory: "/tmp" }));
  assert.throws(call("read_file", { absolute_path: join(root, "AuthKey.p8") }));
  assert.throws(call("edit_file", { file_path: "opencode.json" }));
  assert.doesNotThrow(call("shell_command", { command: "go mod tidy && go test ./...", directory: "core" }));
  assert.doesNotThrow(call("write_file", { file_path: ".agents/tasks/wp-01.md" }));
});

async function loadMod() {
  const handlers = {};
  let hooks;
  roles({ on: (name, fn) => { handlers[name] = fn; }, hooks: (h) => { hooks = h; } });
  const run = (toolName, input) => hooks.beforeToolCall({ toolName, input });
  return { handlers, run };
}

test("mod treats the main session as Lead", async () => {
  const { run } = await loadMod();
  assert.equal(await run("shell_command", { command: "brew list | head" }), undefined);
  assert.equal((await run("edit_file", { file_path: "App/Main.swift" }))?.block, true);
  assert.equal(await run("edit_file", { file_path: ".agents/tasks/wp-01.md" }), undefined);
  assert.equal((await run("shell_command", { command: "git commit -m x" }))?.block, true);
});

test("mod applies the active subagent role", async () => {
  const { handlers, run } = await loadMod();
  handlers.subagent_start({ toolCallId: "a", subagentType: "hiraku-coder" });
  assert.equal(await run("shell_command", { command: "git add -A && git commit -m \"feat(core): x\"" }), undefined);
  assert.equal(await run("shell_command", { command: "git push -u origin feat/wp-01-core" }), undefined);
  assert.equal((await run("shell_command", { command: "git push origin develop" }))?.block, true);
  assert.equal(await run("edit_file", { file_path: "App/Main.swift" }), undefined);
  handlers.subagent_stop({ toolCallId: "a" });

  handlers.subagent_start({ toolCallId: "b", subagentType: "hiraku-shipper" });
  assert.equal(await run("shell_command", { command: "gh pr create --base develop --title x" }), undefined);
  assert.equal((await run("shell_command", { command: "git push -u origin feat/x" }))?.block, true);
  handlers.subagent_stop({ toolCallId: "b" });

  handlers.subagent_start({ toolCallId: "c", subagentType: "Explore" });
  assert.equal((await run("shell_command", { command: "go test ./..." }))?.block, true);
  handlers.subagent_start({ toolCallId: "d", subagentType: "hiraku-coder" });
  assert.equal((await run("edit_file", { file_path: "App/Main.swift" }))?.block, true);
});
