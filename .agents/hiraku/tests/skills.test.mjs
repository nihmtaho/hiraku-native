import { test } from "node:test";
import assert from "node:assert/strict";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { main, mismatches } from "../../scripts/wp-status.mjs";
import { context } from "../../scripts/task-context.mjs";

const root = fileURLToPath(new URL("../../../", import.meta.url));
const kanban = "ROADMAP hiraku — Kanban.html";

function copy() {
  const dir = mkdtempSync(join(tmpdir(), "hiraku-wp-"));
  for (const file of ["ROADMAP.md", kanban]) copyFileSync(join(root, file), join(dir, file));
  return dir;
}

test("issue template task-slice exists and links back to task record and plan", () => {
  const body = readFileSync(join(root, ".github/ISSUE_TEMPLATE/task-slice.md"), "utf8");
  assert.match(body, /^---\nname: Task slice/m);
  assert.match(body, /Parent task record/);
  assert.match(body, /Execution plan/);
  assert.match(body, /Acceptance/);
});

test("repository ROADMAP §11 and Kanban agree", () => {
  assert.deepEqual(mismatches(readFileSync(join(root, "ROADMAP.md"), "utf8"), readFileSync(join(root, kanban), "utf8")), []);
});

test("wp-status updates both places and splits a grouped row", () => {
  const dir = copy();
  try {
    main(["S-2", "ip", "--note", "Running vectors", "--root", dir]);
    const roadmap = readFileSync(join(dir, "ROADMAP.md"), "utf8");
    assert.match(roadmap, /\| S-2 \| ip \| [^|\n]* \| Running vectors \|/);
    assert.doesNotMatch(roadmap, /^\| (?=[^|\n]*,)[^|\n]*\bS-2\b[^|\n]* \|/m);
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

test("task record template has execution plan and github issues", () => {
  const tpl = readFileSync(join(root, ".agents/templates/task.md"), "utf8");
  assert.match(tpl, /## Execution plan/);
  assert.match(tpl, /## GitHub issues/);
});

test("task-context surfaces a directly blocking open question", () => {
  const result = context(root, "WP-22");
  assert.equal(result.work.length, 1);
  assert.ok(result.questions.some((line) => line.startsWith("| Q-26 ") && line.endsWith("trực tiếp")));
});

test("task-context labels questions inherited through dependencies", () => {
  const dir = mkdtempSync(join(tmpdir(), "hiraku-ctx-"));
  try {
    writeFileSync(join(dir, "ROADMAP.md"),
      "| WP-98 | child | WP-97 |\n\n## 4. Gates\n\n## 11. Trạng thái\n");
    const decisions = "| Q-98 | question | Mở | PO | GATE-2 | WP-97 |\n";
    mkdirSync(join(dir, "docs/architecture"), { recursive: true });
    writeFileSync(join(dir, "docs/architecture/DECISIONS.md"), decisions);
    const result = context(dir, "WP-98");
    assert.deepEqual(result.dependencies, ["WP-97"]);
    assert.ok(result.questions.some((line) => line.startsWith("| Q-98 ") && line.endsWith("qua WP-97")));
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
