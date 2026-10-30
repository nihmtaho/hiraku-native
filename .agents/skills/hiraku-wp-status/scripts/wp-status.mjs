#!/usr/bin/env node
// Keeps ROADMAP.md §11 and the Kanban `raw` array in step, since a mismatch blocks review.
import { readFileSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const statuses = ["bl", "rd", "ip", "rv", "dn"];
const usage = `Usage:
  node wp-status.mjs <id> <bl|rd|ip|rv|dn> [--pr <ref>] [--note <text>] [--blk <Q-xx>|--clear-blk]
  node wp-status.mjs --check`;

export function paths(root) {
  return { roadmap: join(root, "ROADMAP.md"), kanban: join(root, "ROADMAP hiraku — Kanban.html") };
}

const str = String.raw`"(?:[^"\\]|\\.)*"`;
const escape = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const quote = (text) => JSON.stringify(text);

function kanbanLine(id) {
  return new RegExp(`^(\\s*\\[${escape(quote(id))},${str},${str},${str},")(bl|rd|ip|rv|dn)(".*)$`, "m");
}

export function kanbanStatuses(html) {
  const result = new Map();
  const pattern = new RegExp(`^\\s*\\[(${str}),${str},${str},${str},"(bl|rd|ip|rv|dn)"`, "gm");
  for (const match of html.matchAll(pattern)) result.set(JSON.parse(match[1]), match[2]);
  return result;
}

export function updateKanban(html, id, status, { note, blk, clearBlk } = {}) {
  const pattern = kanbanLine(id);
  const match = pattern.exec(html);
  if (!match) throw new Error(`Không tìm thấy thẻ "${id}" trong mảng raw của Kanban.`);
  let rest = match[3];
  if (note !== undefined) {
    rest = /note:"/.test(rest)
      ? rest.replace(new RegExp(`note:${str}`), `note:${quote(note)}`)
      : rest.replace(/\{ref:/, `{note:${quote(note)},ref:`);
  }
  if (clearBlk) rest = rest.replace(new RegExp(`,?blk:${str}`), "");
  if (blk) {
    rest = /blk:"/.test(rest)
      ? rest.replace(new RegExp(`blk:${str}`), `blk:${quote(blk)}`)
      : rest.replace(/\{ref:/, `{blk:${quote(blk)},ref:`);
  }
  for (const [key, value] of [["note", note], ["blk", blk]]) {
    if (value && !rest.includes(`${key}:${quote(value)}`)) {
      throw new Error(`Thẻ "${id}" không có đối tượng {ref:…} để ghi ${key}; sửa Kanban bằng tay.`);
    }
  }
  return html.replace(pattern, `${match[1]}${status}${rest}`);
}

function table(markdown) {
  const start = markdown.indexOf("## 11.");
  if (start < 0) throw new Error("ROADMAP.md thiếu mục §11.");
  const lines = markdown.slice(start).split("\n");
  const header = lines.findIndex((line) => line.startsWith("| Mã |"));
  let end = header + 2;
  while (end < lines.length && lines[end].startsWith("|")) end += 1;
  return { start, lines, first: header + 2, end };
}

const cells = (row) => row.split("|").slice(1, -1).map((cell) => cell.trim());
// Cells may wrap ids in backticks or give a range such as RV-01…RV-08.
function ids(cell) {
  return cell.split(",").map((id) => id.trim().replace(/`/g, "")).filter(Boolean).flatMap((id) => {
    const range = /^([A-Z]+-)(\d+)…\1(\d+)$/.exec(id);
    if (!range) return [id];
    const [, prefix, from, to] = range;
    return Array.from({ length: Number(to) - Number(from) + 1 }, (_, i) =>
      `${prefix}${String(Number(from) + i).padStart(from.length, "0")}`);
  });
}
const row = (values) => `| ${values.join(" | ")} |`;

export function roadmapStatuses(markdown) {
  const { lines, first, end } = table(markdown);
  const result = new Map();
  for (const line of lines.slice(first, end)) {
    const [names, status] = cells(line);
    for (const id of ids(names)) result.set(id, status);
  }
  return result;
}

// A grouped row is split when one member changes, so every id keeps an exact status.
export function updateRoadmap(markdown, id, status, { pr, note } = {}) {
  const { start, lines, first, end } = table(markdown);
  const body = lines.slice(first, end);
  const index = body.findIndex((line) => ids(cells(line)[0]).includes(id));
  if (index < 0) {
    body.push(row([id, status, pr ?? "—", note ?? ""]));
  } else {
    const [names, , oldPr, oldNote] = cells(body[index]);
    const members = ids(names);
    const updated = row([id, status, pr ?? oldPr, note ?? oldNote]);
    if (members.length === 1) {
      body[index] = updated;
    } else {
      body[index] = row([members.filter((name) => name !== id).join(", "), cells(body[index])[1], oldPr, oldNote]);
      body.splice(index + 1, 0, updated);
    }
  }
  const next = [...lines.slice(0, first), ...body, ...lines.slice(end)];
  return markdown.slice(0, start) + next.join("\n");
}

export function mismatches(markdown, html) {
  const roadmap = roadmapStatuses(markdown);
  const result = [];
  for (const [id, status] of kanbanStatuses(html)) {
    const expected = roadmap.get(id) ?? "bl";
    if (expected !== status) result.push(`${id}: Kanban=${status}, ROADMAP §11=${expected}`);
  }
  return result;
}

function parse(argv) {
  const options = {};
  const positional = [];
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--check") options.check = true;
    else if (arg === "--clear-blk") options.clearBlk = true;
    else if (["--pr", "--note", "--blk", "--root"].includes(arg)) options[arg.slice(2)] = argv[++i];
    else positional.push(arg);
  }
  return { options, positional };
}

export function main(argv, cwd = process.cwd()) {
  const { options, positional } = parse(argv);
  const root = resolve(cwd, options.root ?? ".");
  const { roadmap, kanban } = paths(root);
  const markdown = readFileSync(roadmap, "utf8");
  const html = readFileSync(kanban, "utf8");
  if (options.check) {
    const problems = mismatches(markdown, html);
    if (problems.length) throw new Error(`Lệch trạng thái:\n${problems.join("\n")}`);
    return "ROADMAP §11 và Kanban khớp.";
  }
  const [id, status] = positional;
  if (!id || !statuses.includes(status)) throw new Error(usage);
  const nextHtml = updateKanban(html, id, status, options);
  const nextMarkdown = updateRoadmap(markdown, id, status, options);
  writeFileSync(kanban, nextHtml);
  writeFileSync(roadmap, nextMarkdown);
  return `${id} → ${status} (ROADMAP §11 + Kanban). Nhớ thêm dòng CHANGELOG [Unreleased] nếu là PR.`;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    console.log(main(process.argv.slice(2)));
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}
