import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const root = fileURLToPath(new URL("../../", import.meta.url));

const readOnlyPi = ["read", "grep", "find", "ls"];
const readOnlyCommandCode = ["read_file", "read_directory", "grep", "glob"];

// Each tool gets its own agent files; only the frontmatter differs, the role body is shared.
const targets = {
  opencode: {
    "hiraku-lead": { path: ".opencode/agents/hiraku-lead.md", role: "lead", meta: { mode: "primary" } },
    "hiraku-coder": { path: ".opencode/agents/hiraku-coder.md", role: "coder", meta: { mode: "subagent" } },
    "hiraku-reviewer": { path: ".opencode/agents/hiraku-reviewer.md", role: "reviewer", meta: { mode: "subagent" } },
    "hiraku-shipper": { path: ".opencode/agents/hiraku-shipper.md", role: "shipper", meta: { mode: "subagent" } },
  },
  pi: {
    "hiraku-lead": { path: ".pi/agents/hiraku-lead.md", role: "lead", meta: { name: "hiraku-lead", mode: "primary" } },
    "hiraku-coder": { path: ".pi/agents/hiraku-coder.md", role: "coder", meta: { name: "hiraku-coder", tools: [...readOnlyPi, "bash", "edit", "write"] } },
    "hiraku-reviewer": { path: ".pi/agents/hiraku-reviewer.md", role: "reviewer", meta: { name: "hiraku-reviewer", tools: [...readOnlyPi, "bash"] } },
    "hiraku-shipper": { path: ".pi/agents/hiraku-shipper.md", role: "shipper", meta: { name: "hiraku-shipper", tools: [...readOnlyPi, "bash", "edit", "write"] } },
    explore: { path: ".pi/agents/explore.md", role: "explore", meta: { name: "explore", tools: readOnlyPi } },
    general: { path: ".pi/agents/general.md", role: "general", meta: { name: "general", tools: [...readOnlyPi, "bash", "edit", "write"] } },
    plan: { path: ".pi/agents/plan.md", role: "plan", meta: { name: "plan", tools: readOnlyPi } },
  },
  commandcode: {
    // The main session is the Lead; a SessionStart hook injects this prompt, so it must not sit in agents/.
    "hiraku-lead": { path: ".commandcode/lead.md", role: "lead", meta: null },
    "hiraku-coder": {
      path: ".commandcode/agents/hiraku-coder.md", role: "coder",
      meta: { name: "hiraku-coder", tools: [...readOnlyCommandCode, "edit_file", "write_file", "shell_command", "kill_shell", "todo_write"] },
    },
    "hiraku-reviewer": {
      path: ".commandcode/agents/hiraku-reviewer.md", role: "reviewer",
      meta: { name: "hiraku-reviewer", tools: [...readOnlyCommandCode, "shell_command"], disallowedTools: ["edit_file", "write_file"] },
    },
    "hiraku-shipper": {
      path: ".commandcode/agents/hiraku-shipper.md", role: "shipper",
      meta: { name: "hiraku-shipper", tools: [...readOnlyCommandCode, "shell_command", "edit_file", "write_file"] },
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

// OpenCode built-in agents take their model from opencode.json.
export function renderOpenCodeConfig() {
  const config = JSON.parse(readFileSync(join(root, "opencode.json"), "utf8"));
  for (const role of ["explore", "plan"]) {
    const model = modelFor("opencode", role);
    if (model) config.agents[role].model = model;
    else delete config.agents[role].model;
  }
  return config;
}

function writeOpenCodeConfig() {
  const text = readFileSync(join(root, "opencode.json"), "utf8");
  const config = renderOpenCodeConfig();
  let next = text;
  for (const role of ["explore", "plan"]) {
    const pattern = new RegExp(`("${role}": \\{\\n)(?:      "model": "[^"]*",\\n)?`);
    next = next.replace(pattern, config.agents[role].model ? `$1      "model": "${config.agents[role].model}",\n` : "$1");
  }
  return next;
}

export function stale() {
  const result = [];
  if (writeOpenCodeConfig() !== readFileSync(join(root, "opencode.json"), "utf8")) result.push("opencode.json");
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
    writeFileSync(join(root, "opencode.json"), writeOpenCodeConfig());
  }
}
