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

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../../..");
const agentsDir = path.join(root, ".pi", "agents");

type Frontmatter = { name?: unknown; description?: unknown; tools?: unknown; mode?: unknown; model?: unknown };

// The primary agent (Lead) runs the interactive session, so only subagents are listed.
export function discoverAgents(_cwd: string, _scope: AgentScope): AgentDiscoveryResult {
	const agents = fs.readdirSync(agentsDir)
		.filter((file) => file.endsWith(".md"))
		.sort()
		.map((file) => {
			const filePath = path.join(agentsDir, file);
			const { frontmatter, body } = parseFrontmatter<Frontmatter>(fs.readFileSync(filePath, "utf-8"));
			return { frontmatter, body, filePath };
		})
		.filter(({ frontmatter }) => frontmatter.mode !== "primary")
		.map(({ frontmatter, body, filePath }) => ({
			name: String(frontmatter.name ?? path.basename(filePath, ".md")),
			description: String(frontmatter.description ?? ""),
			tools: String(frontmatter.tools ?? "").split(",").map((tool) => tool.trim()).filter(Boolean),
			model: frontmatter.model ? String(frontmatter.model) : undefined,
			systemPrompt: body,
			source: "project" as const,
			filePath,
		}));
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
