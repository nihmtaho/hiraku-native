import { readFileSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";

export const agents = new Set([
  "hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper",
  "explore", "general", "plan",
]);

// Every hiraku role needs an unrestricted shell to inspect, test and verify autonomously;
// roles stay separate through edit rights, delegation and the commit/push/PR handoff rules.
export const fullShell = new Set(["hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper", "general"]);
const mutators = new Set(["hiraku-lead", "hiraku-coder", "general"]);
const sourceEditors = new Set(["hiraku-coder", "general"]);
export const delegates = {
  "hiraku-lead": ["hiraku-coder", "hiraku-reviewer", "hiraku-shipper", "explore", "general", "plan"],
  "hiraku-coder": ["explore"],
  "hiraku-reviewer": ["explore"],
  plan: ["explore"],
};

function canonicalPath(path) {
  try {
    return realpathSync(path);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
    const parent = dirname(path);
    if (parent === path) throw error;
    return resolve(canonicalPath(parent), relative(parent, path));
  }
}

export function projectPath(root, path) {
  if (typeof path !== "string" || path.trim() === "") {
    throw new Error("Thiếu đường dẫn để kiểm tra quyền.");
  }
  const result = relative(realpathSync(root), canonicalPath(resolve(root, path)));
  if (result === ".." || result.startsWith(`..${sep}`) || isAbsolute(result)) {
    throw new Error("Đường dẫn nằm ngoài workspace.");
  }
  return result.split(sep).join("/");
}

function secret(path) {
  return /(^|\/)(\.env(?:\..*)?|[^/]+\.(?:p8|p12|pem|key)|[^/]*\.keychain-db)$/i.test(path)
    && !/(^|\/)\.env\.example$/.test(path);
}

function protectedPath(path) {
  return /(^|\/)(AGENTS\.md|OPENCODE\.md|DECISIONS\.md|RELEASE\.md|TEST_PLAN\.md|opencode\.jsonc?)$/i.test(path)
    || /(^|\/)(\.git|\.github|\.agents|\.opencode|\.pi|\.commandcode)(\/|$)/i.test(path)
    || /(^|\/)(?:gen|generated)(\/|$)/i.test(path)
    || /^Frameworks\//i.test(path)
    || /(^|\/)scripts\/(?:check-[^/]+|build-xcframework\.sh|import-rules\.txt)$/i.test(path);
}

// Root keeps only the shared entry docs; reports, plans, logs and scratch go under docs/ or .agents/tmp/.
const rootFiles = new Set([
  "AGENTS.md", "CHANGELOG.md", "COPY.md", "ROADMAP.md", "ROADMAP hiraku — Kanban.html",
  "opencode.json", ".gitignore", "buf.yaml", "buf.gen.yaml", "buf.work.yaml", "go.work", "go.work.sum",
]);

function assertPlacement(path) {
  if (path.includes("/") || rootFiles.has(path)) return;
  if (/\.(?:md|markdown|txt|log|html?|csv|json|ya?ml|out|tmp)$/i.test(path)) {
    throw new Error("Không đặt tài liệu/kết quả ở root: tài liệu vào docs/, báo cáo vào docs/reports/, kế hoạch vào docs/plans/, file tạm vào .agents/tmp/.");
  }
}

export function assertPathAccess(root, agent, action, resource) {
  const path = projectPath(root, resource);
  if (secret(path)) throw new Error("Không cho agent truy cập credential hoặc signing secret.");
  if (action !== "edit") return;
  if (!agents.has(agent)) throw new Error("Agent không thuộc bộ hiraku.");
  if (path.startsWith(".agents/tmp/") && agent !== "hiraku-reviewer") return;
  const task = /^\.agents\/tasks\/[a-z0-9]+(?:-[a-z0-9]+)*\.md$/.test(path);
  if (task && (agent === "hiraku-lead" || agent === "hiraku-shipper")) return;
  if (!sourceEditors.has(agent)) throw new Error("Agent này không được sửa source.");
  if (protectedPath(path)) throw new Error("Policy, checker và generated không được sửa trực tiếp bởi agent.");
  assertPlacement(path);
}

// For hooks that cannot tell which agent is editing: closed paths for every agent; role limits live elsewhere.
export function assertEditBaseline(root, resource) {
  const path = projectPath(root, resource);
  if (secret(path)) throw new Error("Không cho agent truy cập credential hoặc signing secret.");
  if (/^\.agents\/tasks\/[a-z0-9]+(?:-[a-z0-9]+)*\.md$/.test(path)) return;
  if (path.startsWith(".agents/tmp/")) return;
  if (protectedPath(path)) throw new Error("Policy, checker và generated không được sửa trực tiếp bởi agent.");
  assertPlacement(path);
}

const inspection = new Set([
  "git status --short",
  "git diff --no-ext-diff --no-textconv",
  "git diff --no-ext-diff --no-textconv --stat",
  "git rev-parse HEAD",
  "node --test .agents/hiraku/tests/*.test.mjs",
]);

// Delivery stays closed until CI and required checks exist; applies to every agent and every chained command.
const delivery = /(^|[\s;&|(`])(?:git\s+(?:merge|tag|rebase|reset\s+--hard|filter-branch)|gh\s+(?:pr\s+(?:merge|review)|release|repo\s+(?:delete|create|edit)|api)|xcrun\s+(?:altool|notarytool)|fastlane|codesign|security\s+(?:find|dump|export))(?=$|[\s;&|)`])/;

const taskBranch = "(?:feat|fix|refactor|docs|test|chore|hotfix)/[a-z0-9][a-z0-9._-]*";
const handoff = {
  "hiraku-coder": [
    /^git commit(?: (?!--amend\b|--no-verify\b|-n\b)[^\s]+| "[^"]*"| '[^']*')*$/,
    new RegExp(`^git push(?: -u| --set-upstream)? origin (?:HEAD:)?${taskBranch}$`),
  ],
  "hiraku-shipper": [
    /^gh pr create (?=.*--base develop(?:\s|$))(?!.*--base (?!develop))(?:[^;&|`$<>]|"[^"`$]*"|'[^']*')*$/,
    /^gh pr (?:view|list|checks|status|diff)(?: [^\s;&|`$<>]+)*$/,
  ],
};

const handoffCommand = /^(?:git\s+(?:commit|push)|gh\s+pr)\b/;

// PR titles and bodies must not credit AI; checks inline text and the --body-file content.
const aiCredit = /generated (?:by|with) (?:ai|an ai|claude|copilot|chatgpt|gpt|opencode|command ?code)|ai[- ]generated|co-authored-by:[^\n]*(?:ai|bot|claude|copilot|gpt|opencode|commandcode|anthropic|openai)|🤖/i;

function assertNoAiCredit(root, part) {
  if (!/^gh\s+pr\s+(?:create|edit)\b/.test(part)) return;
  if (aiCredit.test(part)) throw new Error("Không ghi 'Generated by AI'/đồng tác giả AI trong tiêu đề hoặc body PR.");
  const file = /--body-file[= ]+(?:"([^"]+)"|'([^']+)'|(\S+))/.exec(part);
  if (!file) return;
  const path = file[1] ?? file[2] ?? file[3];
  if (path === "-") throw new Error("Body PR phải từ file trong workspace để kiểm tra, không đọc từ stdin.");
  let body;
  try {
    body = readFileSync(resolve(root, projectPath(root, path)), "utf8");
  } catch {
    throw new Error(`Không đọc được --body-file ${path} để kiểm tra.`);
  }
  if (aiCredit.test(body)) throw new Error("Body PR có dòng ghi công AI ('Generated by AI', Co-authored-by AI): xóa trước khi tạo PR.");
}

// Only Coder pushes task branches and only Shipper opens PRs; merge/tag/release stay closed.
function assertHandoff(root, agent, command) {
  for (const part of command.split(/&&|\|\||[;|\n]/).map((x) => x.trim())) {
    assertNoAiCredit(root, part);
    if (!handoffCommand.test(part)) {
      if (/(?:git\s+(?:commit|push)|gh\s+pr)\b/.test(part)) {
        throw new Error("Lệnh commit/push/PR phải đứng đầu một đoạn lệnh.");
      }
      continue;
    }
    if (!(handoff[agent] ?? []).some((rule) => rule.test(part))) {
      throw new Error("Commit/push chỉ cho Coder trên nhánh task; PR chỉ Shipper tạo vào develop.");
    }
  }
}

// Hooks that cannot tell which agent is calling check only what is closed for everyone.
export function assertShellBaseline(root, command, cwd = root) {
  if (typeof command !== "string" || command.trim() === "") throw new Error("Lệnh không hợp lệ.");
  projectPath(root, cwd);
  if (delivery.test(command)) {
    throw new Error("Merge/tag/release/signing đang đóng; chỉ người vận hành thực hiện.");
  }
}

export function assertShell(root, agent, command, cwd = root) {
  if (!agents.has(agent)) throw new Error("Agent không được chạy shell.");
  assertShellBaseline(root, command, cwd);
  assertHandoff(root, agent, command);
  if (fullShell.has(agent)) return;
  command = command.trim();
  if (/[\n\r]/.test(command)) throw new Error("Lệnh không hợp lệ.");
  const directory = projectPath(root, cwd);
  if (directory === "" && inspection.has(command)) return;
  if (/[;&|<>`$]/.test(command)) throw new Error("Agent này chỉ chạy lệnh đơn trong allowlist.");
  if (/^git (?:status|log|show|diff|rev-parse|branch|ls-files|blame)(?: [A-Za-z0-9_./:=@^~-]+)*$/.test(command)) return;
  throw new Error("Agent chỉ đọc: chỉ được chạy git đọc.");
}

// Permission events may omit cwd; restricted commands are valid at root or core, re-checked with real cwd later.
function assertShellAnywhere(root, agent, command, cwd) {
  if (cwd) return assertShell(root, agent, command, cwd);
  try {
    assertShell(root, agent, command, root);
  } catch (error) {
    if (fullShell.has(agent)) throw error;
    assertShell(root, agent, command, resolve(root, "core"));
  }
}

export async function evaluatePermission(root, event, storage) {
  try {
    if (event.action === "read" || event.action === "edit") {
      if (!event.resources.length) throw new Error("Thiếu đường dẫn để kiểm tra quyền.");
      for (const resource of event.resources) {
        assertPathAccess(root, event.agent, event.action, resource);
      }
      if (event.action === "edit") {
        await storage.set(`dirty/${event.sessionID}`, {
          agent: event.agent,
          reviewInvalidated: true,
        });
      }
    }
    if (event.action === "subagent") {
      const allowed = delegates[event.agent] ?? [];
      if (event.resources.some((id) => !allowed.includes(id))) {
        throw new Error("Agent này không được gọi subagent đó.");
      }
    }
    if (event.action === "shell") {
      if (!event.resources.length) throw new Error("Thiếu lệnh để kiểm tra quyền.");
      // The create.before shell hook re-checks every command raw with the real cwd;
      // permission events can arrive shell-wrapped (e.g. zsh -lc) and must not gate on them.
      if (mutators.has(event.agent)) {
        await storage.set(`dirty/${event.sessionID}`, {
          agent: event.agent,
          reviewInvalidated: true,
        });
      }
    }
  } catch (error) {
    event.effect = "deny";
    event.message = error.message;
  }
}
