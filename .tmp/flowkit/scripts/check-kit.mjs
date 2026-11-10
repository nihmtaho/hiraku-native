// Gate for the flowkit kit: prints one violation per line, exit 1 if any.
import { readdirSync, readFileSync, realpathSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const kitRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const skillsDir = join(kitRoot, "skills");
const sections = [
  "Project",
  "Status tracking",
  "Git & PR",
  "Checks",
  "Docs map",
  "Architecture rules",
  "Quality rules",
  "PM hooks",
];
const forbidden = [
  { token: "hiraku", ci: true },
  { token: "ROADMAP", ci: false },
  { token: "DECISIONS", ci: false },
  { token: "WP-", ci: false },
  { token: "$ARGUMENTS", ci: false },
  { token: "CONNECTORS.md", ci: false },
  { token: "task-context", ci: false },
  { token: "wp-status", ci: false },
];
// The kit is these 20 skills; an absent one is a violation, not a pass.
const expectedSkills = [
  "flow-coordinator",
  "flow-task",
  "flow-implement",
  "flow-pr",
  "flow-review",
  "flow-ship",
  "flow-status",
  "flow-interface",
  "flow-feature",
  "flow-spike",
  "flow-debug",
  "product-review",
  "write-spec",
  "roadmap-update",
  "sprint-planning",
  "stakeholder-update",
  "synthesize-research",
  "competitive-brief",
  "metrics-review",
  "product-brainstorming",
];

const violations = [];

function readOrNull(path) {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return null;
  }
}

function listSkillDirs() {
  try {
    return readdirSync(skillsDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
  } catch {
    return [];
  }
}

function filesUnder(dir, seen = new Set()) {
  let real;
  try {
    real = realpathSync(dir);
  } catch {
    return [];
  }
  if (seen.has(real)) return [];
  seen.add(real);
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
  const files = [];
  for (const entry of entries) {
    const path = join(dir, entry.name);
    let stat;
    try {
      stat = statSync(path);
    } catch {
      continue;
    }
    if (stat.isDirectory()) files.push(...filesUnder(path, seen));
    else if (stat.isFile()) files.push(realpathSync(path));
  }
  return files;
}

function frontmatter(text) {
  const lines = text.split(/\r?\n/);
  const start = lines.findIndex((line) => line.trim() === "---");
  if (start === -1) return null;
  const end = lines.findIndex((line, i) => i > start && line.trim() === "---");
  if (end === -1) return null;
  return lines.slice(start + 1, end).join("\n");
}

function scalar(fm, key) {
  const lines = fm.split(/\r?\n/);
  const index = lines.findIndex((line) => line.startsWith(`${key}:`));
  if (index === -1) return "";
  const inline = lines[index].slice(key.length + 1).trim();
  if (inline && !/^[>|][+-]?$/.test(inline)) return inline;
  const block = [];
  for (let i = index + 1; i < lines.length; i++) {
    if (!/^\s+\S/.test(lines[i])) break;
    block.push(lines[i].trim());
  }
  return block.join(" ").trim();
}

// 1. missing skill — every expected name must exist and pass the frontmatter rule
const skillBodies = new Map();
const nameValues = [];
const extraDirs = listSkillDirs().filter((dir) => !expectedSkills.includes(dir));
for (const dir of [...expectedSkills, ...extraDirs]) {
  const body = readOrNull(join(skillsDir, dir, "SKILL.md"));
  const fm = body === null ? null : frontmatter(body);
  if (body === null || fm === null) {
    violations.push(`missing skill: ${dir}`);
    continue;
  }
  const name = scalar(fm, "name");
  const description = scalar(fm, "description");
  if (!name || !description) {
    violations.push(`invalid frontmatter: ${dir}`);
    continue;
  }
  if (name !== dir) violations.push(`name mismatch: ${dir}:${name}`);
  skillBodies.set(dir, body);
  nameValues.push({ dir, value: name });
}

// 2. forbidden token — one line per file and token regardless of hit count
const kitReal = realpathSync(kitRoot);
for (const file of filesUnder(skillsDir)) {
  const text = readOrNull(file);
  if (text === null) continue;
  const rel = relative(kitReal, file);
  for (const { token, ci } of forbidden) {
    const hit = ci
      ? text.toLowerCase().includes(token.toLowerCase())
      : text.includes(token);
    if (hit) violations.push(`forbidden token: ${rel}:${token}`);
  }
}

// 3. duplicate name — same value claimed by two different skills, case-insensitive
const seen = new Map();
for (const { dir, value } of nameValues) {
  const key = value.toLowerCase();
  if (seen.has(key) && seen.get(key) !== dir) {
    if (!violations.includes(`duplicate name: ${value}`)) {
      violations.push(`duplicate name: ${value}`);
    }
  } else {
    seen.set(key, dir);
  }
}

// 4. missing section
const example = readOrNull(join(kitRoot, "PROJECT.md.example")) ?? "";
for (const heading of sections) {
  if (!new RegExp(`^## ${heading}$`, "m").test(example)) {
    violations.push(`missing section: ${heading}`);
  }
}

// 5. missing anchor — the template must keep naming the artifacts the skills read
const anchors = ["states", "task record", "merge", "changelog", "scratch"];
const exampleLower = example.toLowerCase();
for (const word of anchors) {
  if (!exampleLower.includes(word)) violations.push(`missing anchor: ${word}`);
}

// 6. missing profile ref — flow-* skills must point at PROJECT.md
for (const [dir, body] of skillBodies) {
  if (dir.startsWith("flow-") && !body.includes("PROJECT.md")) {
    violations.push(`missing profile ref: ${dir}`);
  }
}

if (violations.length > 0) {
  console.log(violations.join("\n"));
  process.exit(1);
}
console.log("flowkit check: OK");
