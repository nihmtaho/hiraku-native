import { readFileSync } from "node:fs";
import { isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { assertEditBaseline, assertPathAccess, assertShellBaseline } from "../../.agents/hiraku/guard.mjs";

const root = fileURLToPath(new URL("../../", import.meta.url));

export function decide(payload) {
  const input = payload.tool_input ?? {};
  const cwd = payload.cwd || root;
  const at = (path) => (isAbsolute(path) ? path : resolve(cwd, path));
  switch (payload.tool_name) {
    case "shell_command":
      return assertShellBaseline(root, input.command, input.directory ? at(input.directory) : cwd);
    case "read_file":
      return assertPathAccess(root, "explore", "read", at(input.absolute_path));
    case "write_file":
    case "edit_file":
      return assertEditBaseline(root, at(input.file_path));
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
