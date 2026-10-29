import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { type ExtensionAPI, parseFrontmatter } from "@earendil-works/pi-coding-agent";
import { assertPathAccess, assertShell } from "../../.opencode/lib/guard.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
// The subagent extension sets HIRAKU_AGENT for child processes; the interactive session is the Lead.
const agent = process.env.HIRAKU_AGENT ?? "hiraku-lead";
const subagents = new Set(["hiraku-coder", "hiraku-reviewer", "hiraku-shipper"]);
const readTools = new Set(["read", "grep", "find", "ls"]);

function check(toolName: string, input: Record<string, any>) {
	if (readTools.has(toolName)) return assertPathAccess(root, agent, "read", input.path ?? ".");
	if (toolName === "edit" || toolName === "write") return assertPathAccess(root, agent, "edit", input.path);
	if (toolName === "bash") {
		// Pi's bash has no cwd field, so the documented `cd core && go test` form maps to OpenCode's cwd.
		const match = /^cd core && (.+)$/.exec(input.command);
		return assertShell(root, agent, match ? match[1] : input.command, match ? join(root, "core") : root);
	}
	if (toolName === "subagent") {
		if (agent !== "hiraku-lead") throw new Error("Chỉ Lead được gọi ba subagents hiraku.");
		if (input.cwd) throw new Error("Subagent phải chạy tại root dự án.");
		const names = [input.agent, ...(input.tasks ?? []), ...(input.chain ?? [])].map((t) => t?.agent ?? t).filter(Boolean);
		if (names.some((name) => !subagents.has(name))) throw new Error("Chỉ Lead được gọi ba subagents hiraku.");
		return;
	}
	throw new Error(`Tool ${toolName} không nằm trong allowlist của hiraku.`);
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		try {
			check(event.toolName, event.input as Record<string, any>);
		} catch (error) {
			return { block: true, reason: (error as Error).message };
		}
		return undefined;
	});

	if (agent !== "hiraku-lead") return;
	const lead = parseFrontmatter(readFileSync(join(root, ".opencode/agents/hiraku-lead.md"), "utf-8")).body;
	pi.on("before_agent_start", async (event) => ({ systemPrompt: `${event.systemPrompt}\n\n${lead}` }));
}
