import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { modelFor, root, stale } from "../sync.mjs";

test("generated agent files match the shared roles", () => {
  assert.deepEqual(stale(), []);
});

test("roles stay tool-neutral", () => {
  const directory = join(root, ".agents/hiraku/roles");
  for (const file of readdirSync(directory)) {
    const body = readFileSync(join(directory, file), "utf8");
    assert.doesNotMatch(body, /opencode|commandcode|\bpi\b|\.pi\//i, file);
    assert.match(body, /^---\ndescription: .+\n---\n/, file);
  }
});

test("hiraku skills are the agreed set and each has scenario evals", () => {
  const directory = join(root, ".agents/skills");
  const ids = readdirSync(directory).filter((id) => id.startsWith("hiraku-")).sort();
  assert.deepEqual(ids, ["hiraku-contract", "hiraku-feature", "hiraku-spike-report", "hiraku-task", "hiraku-wp-status"]);
  for (const id of ids) {
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
  }
});

test("every shared skill name is lowercase and matches its directory", () => {
  const directory = join(root, ".agents/skills");
  for (const id of readdirSync(directory).filter((name) => !name.startsWith("."))) {
    const name = /^---\n(?:[\s\S]*?\n)?name: (.+)$/m.exec(readFileSync(join(directory, id, "SKILL.md"), "utf8"))?.[1];
    assert.equal(name, id);
    assert.match(name, /^[a-z0-9]+(-[a-z0-9]+)*$/);
  }
});

test("cheap model is pinned only for explore, plan and shipper in every tool", () => {
  for (const tool of ["opencode", "pi", "commandcode"]) {
    for (const role of ["explore", "plan", "shipper"]) assert.ok(modelFor(tool, role), `${tool}/${role}`);
    for (const role of ["lead", "coder", "reviewer", "general"]) assert.equal(modelFor(tool, role), undefined);
  }
  const opencode = JSON.parse(readFileSync(join(root, "opencode.json"), "utf8"));
  assert.equal(opencode.agents.explore.model, modelFor("opencode", "explore"));
  assert.equal(opencode.agents.plan.model, modelFor("opencode", "plan"));
  assert.equal("model" in opencode, false);
  const commandcode = JSON.parse(readFileSync(join(root, ".commandcode/settings.json"), "utf8"));
  assert.equal(commandcode.featureModels.planning, modelFor("commandcode", "plan"));
  for (const path of [".opencode/agents/hiraku-coder.md", ".pi/agents/hiraku-reviewer.md", ".commandcode/agents/hiraku-coder.md"]) {
    assert.doesNotMatch(readFileSync(join(root, path), "utf8").split("---")[1], /\nmodel:/, path);
  }
});

test("AGENTS.md stays short because every agent loads it", () => {
  assert.ok(readFileSync(join(root, "AGENTS.md"), "utf8").length < 6500);
});

test("vendored skills keep license, pinned source and a hiraku override section", () => {
  for (const id of ["swift-concurrency-6-2", "swift-protocol-di-testing", "golang-testing",
    "liquid-glass-design", "accessibility"]) {
    const directory = join(root, ".agents/skills", id);
    assert.match(readFileSync(join(directory, "LICENSE"), "utf8"), /^MIT License/);
    assert.match(readFileSync(join(directory, "SOURCE.md"), "utf8"), /affaan-m\/ecc\/tree\/[0-9a-f]{40}\//);
    assert.match(readFileSync(join(directory, "SKILL.md"), "utf8"), /\n## Áp dụng cho hiraku\n[\s\S]*BLOCKED/);
  }
});
