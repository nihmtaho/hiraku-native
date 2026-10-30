#!/usr/bin/env node
// Prints only the ROADMAP/DECISIONS rows a task needs, so the Lead does not load whole documents.
import { readFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const tableRows = (text) => text.split("\n").filter((line) => line.startsWith("| ") && !line.startsWith("|---"));
const cells = (line) => line.split("|").slice(1, -1).map((cell) => cell.trim());
const mentions = (text, id) => new RegExp(`(^|[^\\w-])${id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}([^\\w-]|$)`).test(text);
const settled = (status) => /^Đã chốt(?! một phần)|^Đã thay thế|^Đóng/.test(status);

export function context(root, id) {
  const roadmap = readFileSync(join(root, "ROADMAP.md"), "utf8");
  const decisions = readFileSync(join(root, "docs/architecture/DECISIONS.md"), "utf8");
  const status = roadmap.slice(roadmap.indexOf("## 11."));
  const gates = roadmap.slice(roadmap.indexOf("## 4."), roadmap.indexOf("## 5."));

  const work = tableRows(roadmap).filter((line) => cells(line)[0] === id || cells(line)[0]?.startsWith(`${id} `));
  const dependencies = work.flatMap((line) => (cells(line)[2] ?? "").match(/\b(?:WP-\d+[a-z]?|S-\d+|Q-[\w]+|ADR-\d+)\b/g) ?? []);
  const keys = [id, ...dependencies];
  const tracked = tableRows(status).filter((line) => cells(line)[0].replace(/`/g, "").split(",").map((x) => x.trim()).includes(id));
  const questions = tableRows(decisions).flatMap((line) => {
    const [qid, , state, , , blocks] = cells(line);
    if (!/^Q-/.test(qid) || settled(state)) return [];
    const via = keys.find((key) => mentions(blocks ?? "", key) || key === qid);
    if (!via) return [];
    return [`${line} ${via === id ? "trực tiếp" : `qua ${via}`}`];
  });
  const gateRows = tableRows(gates).filter((line) => keys.some((key) => mentions(line, key)) ||
    questions.some((q) => mentions(line, q.split("|")[1].trim())));
  return { id, work, dependencies, tracked, questions, gateRows };
}

function print({ id, work, dependencies, tracked, questions, gateRows }) {
  const section = (title, lines) => `## ${title}\n${lines.length ? lines.join("\n") : "(không có)"}\n`;
  return [
    `# Ngữ cảnh task ${id}\n`,
    section("Dòng WP/spike (ROADMAP §3)", work),
    section("Phụ thuộc", dependencies.length ? [dependencies.join(", ")] : []),
    section("Trạng thái (ROADMAP §11; không có = bl)", tracked),
    section("Q chưa chốt liên quan (DECISIONS)", questions),
    section("Gate liên quan (ROADMAP §4)", gateRows),
  ].join("\n");
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [id, ...rest] = process.argv.slice(2);
  if (!id) {
    console.error("Usage: node task-context.mjs <WP-xx|S-x|Q-xx> [--root <dir>]");
    process.exit(1);
  }
  const at = rest.indexOf("--root");
  console.log(print(context(resolve(at >= 0 ? rest[at + 1] : "."), id)));
}
