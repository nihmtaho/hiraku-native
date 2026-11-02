import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const root = fileURLToPath(new URL("../../", import.meta.url));

const readOnlyPi = ["read", "grep", "find", "ls"];
const readOnlyCommandCode = ["read_file", "read_directory", "grep", "glob"];
const readOnlyClaude = ["Read", "Grep", "Glob"];

// Two roles only; each tool gets its own agent files and only the frontmatter differs.
const targets = {
  opencode: {
    "hiraku-coordinator": { path: ".opencode/agents/hiraku-coordinator.md", role: "coordinator", meta: { mode: "primary" } },
    "hiraku-senior": { path: ".opencode/agents/hiraku-senior.md", role: "senior", meta: { mode: "subagent" } },
  },
  pi: {
    "hiraku-coordinator": { path: ".pi/agents/hiraku-coordinator.md", role: "coordinator", meta: { name: "hiraku-coordinator", mode: "primary", tools: [...readOnlyPi, "bash", "edit", "write"] } },
    "hiraku-senior": { path: ".pi/agents/hiraku-senior.md", role: "senior", meta: { name: "hiraku-senior", tools: [...readOnlyPi, "bash", "edit", "write"] } },
  },
  claude: {
    // `agent` in .claude/settings.json runs the main session as the coordinator.
    "hiraku-coordinator": {
      path: ".claude/agents/hiraku-coordinator.md", role: "coordinator",
      meta: { name: "hiraku-coordinator", tools: [...readOnlyClaude, "Edit", "Write", "Bash", "TodoWrite", "Agent(hiraku-senior)"] },
    },
    "hiraku-senior": {
      path: ".claude/agents/hiraku-senior.md", role: "senior",
      meta: { name: "hiraku-senior", tools: [...readOnlyClaude, "Edit", "Write", "Bash", "TodoWrite"] },
    },
  },
  commandcode: {
    // The main session is the coordinator; a SessionStart hook injects this prompt, so it must not sit in agents/.
    "hiraku-coordinator": { path: ".commandcode/coordinator.md", role: "coordinator", meta: null },
    "hiraku-senior": {
      path: ".commandcode/agents/hiraku-senior.md", role: "senior",
      meta: { name: "hiraku-senior", tools: [...readOnlyCommandCode, "edit_file", "write_file", "shell_command", "kill_shell", "todo_write"] },
    },
  },
};

export function parseRole(text) {
  const match = /^---\n([\s\S]*?)\n---\n\n?([\s\S]*)$/.exec(text);
  if (!match) throw new Error("Role file must start with frontmatter.");
  const description = /^description: (.+)$/m.exec(match[1])?.[1];
  if (!description) throw new Error("Role file needs a description.");
  return { description, body: match[2] };
}

function frontmatter(meta) {
  const lines = Object.entries(meta).filter(([, value]) => value !== undefined).map(([key, value]) =>
    `${key}: ${Array.isArray(value) ? value.join(", ") : value}`);
  return `---\n${lines.join("\n")}\n---\n\n`;
}

// Roles not listed in models.json inherit the operator's session model.
export function modelFor(tool, role) {
  const { tiers, roles } = JSON.parse(readFileSync(join(root, ".agents/hiraku/models.json"), "utf8"));
  const tier = roles[role];
  return tier ? tiers[tier][tool] : undefined;
}

export function render() {
  const files = new Map();
  for (const [tool, agents] of Object.entries(targets)) {
    for (const { path, role, meta: base } of Object.values(agents)) {
      const meta = base && { ...base, model: modelFor(tool, role) };
      const source = `.agents/hiraku/roles/${role}.md`;
      const { description, body } = parseRole(readFileSync(join(root, source), "utf8"));
      const notice = `<!-- Generated from ${source} by \`node .agents/hiraku/sync.mjs\`; edit the role, not this file. -->\n\n`;
      const head = meta ? frontmatter({ name: meta.name, description, ...meta }) : "";
      files.set(path, head + notice + body);
    }
  }
  return files;
}

export function stale() {
  const result = [];
  for (const [path, content] of render()) {
    let current = null;
    try { current = readFileSync(join(root, path), "utf8"); } catch { /* missing counts as stale */ }
    if (current !== content) result.push(path);
  }
  return result;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--check")) {
    const paths = stale();
    if (paths.length) {
      console.error(`Stale agent files: ${paths.join(", ")}. Run node .agents/hiraku/sync.mjs`);
      process.exit(1);
    }
  } else {
    for (const [path, content] of render()) {
      mkdirSync(dirname(join(root, path)), { recursive: true });
      writeFileSync(join(root, path), content);
    }
  }
}
