import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  agents, assertEditBaseline, assertPathAccess, assertShell, assertShellBaseline,
} from "../../.agents/hiraku/guard.mjs";

const hookRoot = fileURLToPath(new URL("../../", import.meta.url));

// A linked worktree has its own root; the hook file may live in another checkout.
function repoRoot(cwd) {
  try {
    return execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd, encoding: "utf8" }).trim();
  } catch {
    return hookRoot;
  }
}

// Claude Code names its built-in agents differently from the shared guard.
const builtIn = { Explore: "explore", Plan: "plan", "general-purpose": "general" };

export function decide(payload) {
  const input = payload.tool_input ?? {};
  const cwd = payload.cwd || hookRoot;
  const root = repoRoot(cwd);
  const at = (path) => (isAbsolute(path) ? path : resolve(cwd, path));
  const agent = builtIn[payload.agent_type] ?? payload.agent_type;
  // Calls from an unknown caller only get the checks that are closed for every role.
  const known = agents.has(agent);
  switch (payload.tool_name) {
    case "Bash":
      return known ? assertShell(root, agent, input.command, cwd) : assertShellBaseline(root, input.command, cwd);
    case "Read":
      return assertPathAccess(root, known ? agent : "explore", "read", at(input.file_path));
    case "Write":
    case "Edit":
    case "NotebookEdit": {
      const path = at(input.file_path ?? input.notebook_path);
      return known ? assertPathAccess(root, agent, "edit", path) : assertEditBaseline(root, path);
    }
    default:
      return undefined;
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  let output = "";
  try {
    decide(JSON.parse(readFileSync(0, "utf8")));
  } catch (error) {
    output = JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: error.message,
      },
    });
  }
  process.stdout.write(output);
}
