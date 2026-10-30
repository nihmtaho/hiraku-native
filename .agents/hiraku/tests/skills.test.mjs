import { test } from "node:test";
import assert from "node:assert/strict";
import { copyFileSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { root } from "../sync.mjs";
import { main, mismatches } from "../../skills/hiraku-wp-status/scripts/wp-status.mjs";
import { context } from "../../skills/hiraku-task/scripts/task-context.mjs";

const kanban = "ROADMAP hiraku — Kanban.html";

function copy() {
  const dir = mkdtempSync(join(tmpdir(), "hiraku-wp-"));
  for (const file of ["ROADMAP.md", kanban]) copyFileSync(join(root, file), join(dir, file));
  return dir;
}

test("repository ROADMAP §11 and Kanban agree", () => {
  assert.deepEqual(mismatches(readFileSync(join(root, "ROADMAP.md"), "utf8"), readFileSync(join(root, kanban), "utf8")), []);
});

test("wp-status updates both places and splits a grouped row", () => {
  const dir = copy();
  try {
    main(["S-2", "ip", "--note", "Running vectors", "--root", dir]);
    const roadmap = readFileSync(join(dir, "ROADMAP.md"), "utf8");
    assert.match(roadmap, /\| S-2 \| ip \| — \| Running vectors \|/);
    assert.match(roadmap, /\| S-3, S-4, S-5, S-6, ADR-15 \| rd \|/);
    assert.match(readFileSync(join(dir, kanban), "utf8"), /\["S-2",.*"sp","ip",.*note:"Running vectors"/);
    assert.equal(main(["--check", "--root", dir]), "ROADMAP §11 và Kanban khớp.");
  } finally {
    rmSync(dir, { recursive: true });
  }
});

test("wp-status rejects unknown ids and statuses without writing", () => {
  const dir = copy();
  try {
    const before = readFileSync(join(dir, "ROADMAP.md"), "utf8");
    assert.throws(() => main(["WP-99", "ip", "--root", dir]), /Không tìm thấy/);
    assert.throws(() => main(["S-2", "done", "--root", dir]), /Usage/);
    assert.equal(readFileSync(join(dir, "ROADMAP.md"), "utf8"), before);
  } finally {
    rmSync(dir, { recursive: true });
  }
});

test("task-context surfaces a directly blocking open question", () => {
  const result = context(root, "WP-04");
  assert.equal(result.work.length, 1);
  assert.ok(result.questions.some((line) => line.startsWith("| Q-21 ") && line.endsWith("trực tiếp")));
});

test("task-context labels questions inherited through dependencies", () => {
  const result = context(root, "WP-03");
  assert.deepEqual(result.dependencies, ["WP-02a", "S-2"]);
  assert.ok(result.questions.some((line) => line.startsWith("| Q-19 ") && line.endsWith("qua WP-02a")));
});
