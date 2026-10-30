import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const lead = readFileSync(new URL("../lead.md", import.meta.url), "utf8");

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: lead },
  }));
}
