// Gate for the flowkit kit: prints one violation per line, exit 1 if any.
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
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

function filesUnder(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return [];
  }
  const files = [];
  for (const entry of entries) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...filesUnder(path));
    else if (entry.isFile()) files.push(path);
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

// 1. missing skill — every expected name must exist and pass the frontmatter rule
const skillBodies = new Map();
const nameValues = [];
const extraDirs = listSkillDirs().filter((dir) => !expectedSkills.includes(dir));
for (const dir of [...expectedSkills, ...extraDirs]) {
  const body = readOrNull(join(skillsDir, dir, "SKILL.md"));
  const fm = body === null ? null : frontmatter(body);
  const valid =
    body !== null &&
    fm !== null &&
    /^name:/m.test(fm) &&
    /^description:/m.test(fm);
  if (!valid) {
    violations.push(`missing skill: ${dir}`);
    continue;
  }
  skillBodies.set(dir, body);
  const value = fm.match(/^name:[ \t]*(.*)$/m)?.[1]?.trim();
  if (value) nameValues.push({ dir, value });
}

// 2. forbidden token — one line per file and token regardless of hit count
for (const file of filesUnder(skillsDir)) {
  const text = readOrNull(file);
  if (text === null) continue;
  const rel = file.slice(kitRoot.length + 1);
  for (const { token, ci } of forbidden) {
    const hit = ci
      ? text.toLowerCase().includes(token.toLowerCase())
      : text.includes(token);
    if (hit) violations.push(`forbidden token: ${rel}:${token}`);
  }
}

// 3. duplicate name — same value claimed by two different skills
const seen = new Map();
for (const { dir, value } of nameValues) {
  if (seen.has(value) && seen.get(value) !== dir) {
    if (!violations.includes(`duplicate name: ${value}`)) {
      violations.push(`duplicate name: ${value}`);
    }
  } else {
    seen.set(value, dir);
  }
}

// 4. missing section
const example = readOrNull(join(kitRoot, "PROJECT.md.example")) ?? "";
for (const heading of sections) {
  if (!new RegExp(`^## ${heading}$`, "m").test(example)) {
    violations.push(`missing section: ${heading}`);
  }
}

// 5. missing profile ref — flow-* skills must point at PROJECT.md
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
