import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { root } from "../sync.mjs";

const directory = join(root, ".pi/agents");

function frontmatter(file) {
  const head = /^---\n([\s\S]*?)\n---/.exec(readFileSync(join(directory, file), "utf8"))[1];
  return Object.fromEntries(head.split("\n").map((line) => line.split(/: (.*)/s).slice(0, 2)));
}

test("pi has the coordinator as primary and the senior as its only subagent", () => {
  assert.deepEqual(readdirSync(directory).sort(), ["hiraku-coordinator.md", "hiraku-senior.md"]);
  assert.equal(frontmatter("hiraku-coordinator.md").mode, "primary");
});

test("pi senior can edit and run shell", () => {
  const tools = frontmatter("hiraku-senior.md").tools.split(", ");
  assert.ok(tools.includes("edit") && tools.includes("bash"));
});

test("pi config reads only its own agents and the shared guard", () => {
  const loader = readFileSync(join(root, ".pi/extensions/subagent/agents.ts"), "utf8");
  const guard = readFileSync(join(root, ".pi/extensions/hiraku-guard.ts"), "utf8");
  assert.match(loader, /"\.pi", "agents"/);
  assert.match(guard, /\.agents\/hiraku\/guard\.mjs/);
  assert.match(guard, /\.pi\/agents\/hiraku-coordinator\.md/);
  assert.doesNotMatch(loader + guard, /\.opencode|\.commandcode/);
  assert.equal(existsSync(join(root, ".pi/settings.json")), false);
});
