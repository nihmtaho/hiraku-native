import type { ModApi } from "@commandcode/harness";
import { isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { agents, assertPathAccess, assertShell } from "../../.agents/hiraku/guard.mjs";

const root = fileURLToPath(new URL("../../", import.meta.url));
const active = new Map<string, string>();

// Hooks do not say which agent is calling: no running subagent means the Lead (main session).
// Unknown subagent types fall back to the read-only explore role.
function callers(): string[] {
	if (active.size === 0) return ["hiraku-lead"];
	return [...new Set(active.values())].map((type) => (agents.has(type) ? type : "explore"));
}

function check(agent: string, toolName: string, input: Record<string, any>) {
	const at = (path: string) => (isAbsolute(path) ? path : resolve(root, path));
	if (toolName === "shell_command") {
		return assertShell(root, agent, String(input.command ?? ""), input.directory ? at(input.directory) : root);
	}
	if (toolName === "write_file" || toolName === "edit_file") {
		return assertPathAccess(root, agent, "edit", at(String(input.file_path ?? "")));
	}
}

export default function (cmd: ModApi) {
	cmd.on("subagent_start", (event: any) => active.set(event.toolCallId, String(event.subagentType).toLowerCase()));
	cmd.on("subagent_stop", (event: any) => active.delete(event.toolCallId));
	cmd.hooks({
		beforeToolCall: async ({ toolName, input }: { toolName: string; input: Record<string, any> }) => {
			try {
				// Parallel subagents of different roles: a call must pass every active role.
				for (const agent of callers()) check(agent, toolName, input);
			} catch (error) {
				return { block: true, additionalContext: (error as Error).message };
			}
			return undefined;
		},
	});
}
