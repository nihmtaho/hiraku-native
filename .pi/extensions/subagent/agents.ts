import * as fs from "node:fs";
import * as path from "node:path";
import { parseFrontmatter } from "@earendil-works/pi-coding-agent";

export type AgentScope = "user" | "project" | "both";

export interface AgentConfig {
	name: string;
	description: string;
	tools?: string[];
	model?: string;
	systemPrompt: string;
	source: "user" | "project";
	filePath: string;
}

export interface AgentDiscoveryResult {
	agents: AgentConfig[];
	projectAgentsDir: string | null;
}

// Prompts stay in .opencode/agents so OpenCode and Pi share one source; Pi only adds tool lists.
const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../../..");
const agentsDir = path.join(root, ".opencode", "agents");
const subagentTools: Record<string, string[]> = {
	"hiraku-coder": ["read", "grep", "find", "ls", "bash", "edit", "write"],
	"hiraku-reviewer": ["read", "grep", "find", "ls", "bash"],
	"hiraku-shipper": ["read", "grep", "find", "ls", "bash", "edit", "write"],
};

export function discoverAgents(_cwd: string, _scope: AgentScope): AgentDiscoveryResult {
	const agents = Object.entries(subagentTools).map(([name, tools]) => {
		const filePath = path.join(agentsDir, `${name}.md`);
		const { frontmatter, body } = parseFrontmatter<{ description?: unknown }>(fs.readFileSync(filePath, "utf-8"));
		return {
			name,
			description: String(frontmatter.description ?? ""),
			tools,
			systemPrompt: body,
			source: "project" as const,
			filePath,
		};
	});
	return { agents, projectAgentsDir: agentsDir };
}

export function formatAgentList(agents: AgentConfig[], maxItems: number): { text: string; remaining: number } {
	if (agents.length === 0) return { text: "none", remaining: 0 };
	const listed = agents.slice(0, maxItems);
	return {
		text: listed.map((a) => `${a.name} (${a.source}): ${a.description}`).join("; "),
		remaining: agents.length - listed.length,
	};
}
