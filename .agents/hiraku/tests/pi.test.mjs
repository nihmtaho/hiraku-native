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

test("pi has its own lead, three hiraku subagents and explore/general/plan", () => {
  assert.deepEqual(readdirSync(directory).sort(), [
    "explore.md", "general.md", "hiraku-coder.md", "hiraku-lead.md",
    "hiraku-reviewer.md", "hiraku-shipper.md", "plan.md",
  ]);
  assert.equal(frontmatter("hiraku-lead.md").mode, "primary");
});

test("pi subagent tools keep roles separate", () => {
  const tools = (file) => frontmatter(file).tools.split(", ");
  for (const file of ["explore.md", "plan.md", "hiraku-reviewer.md"]) {
    assert.ok(!tools(file).includes("edit") && !tools(file).includes("write"), file);
  }
  for (const file of ["explore.md", "plan.md"]) assert.ok(!tools(file).includes("bash"), file);
  assert.ok(tools("hiraku-coder.md").includes("edit"));
});

test("pi config reads only its own agents and the shared guard", () => {
  const loader = readFileSync(join(root, ".pi/extensions/subagent/agents.ts"), "utf8");
  const guard = readFileSync(join(root, ".pi/extensions/hiraku-guard.ts"), "utf8");
  assert.match(loader, /"\.pi", "agents"/);
  assert.match(guard, /\.agents\/hiraku\/guard\.mjs/);
  assert.match(guard, /\.pi\/agents\/hiraku-lead\.md/);
  assert.doesNotMatch(loader + guard, /\.opencode|\.commandcode/);
  assert.equal(existsSync(join(root, ".pi/settings.json")), false);
});
