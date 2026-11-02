import { readFileSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";

const coordinator = "hiraku-coordinator";
const senior = "hiraku-senior";

export const agents = new Set([coordinator, senior]);
const sourceEditors = new Set([senior]);
const taskEditors = new Set([coordinator, senior]);
export const delegates = { [coordinator]: [senior] };

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

export function protectedPath(path) {
  return /(^|\/)(AGENTS\.md|OPENCODE\.md|DECISIONS\.md|RELEASE\.md|TEST_PLAN\.md|opencode\.jsonc?)$/i.test(path)
    || /(^|\/)(\.git|\.github|\.agents|\.opencode|\.pi|\.commandcode|\.claude)(\/|$)/i.test(path)
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

const taskRecord = /^\.agents\/tasks\/[a-z0-9]+(?:-[a-z0-9]+)*\.md$/;

export function assertPathAccess(root, agent, action, resource) {
  const path = projectPath(root, resource);
  if (secret(path)) throw new Error("Không cho agent truy cập credential hoặc signing secret.");
  if (action !== "edit") return;
  if (!agents.has(agent)) throw new Error("Agent không thuộc bộ hiraku.");
  if (path.startsWith(".agents/tmp/")) return;
  if (taskRecord.test(path) && taskEditors.has(agent)) return;
  if (!sourceEditors.has(agent)) throw new Error("Agent này không được sửa source.");
  if (protectedPath(path)) throw new Error("Policy, checker và generated không được sửa trực tiếp bởi agent.");
  assertPlacement(path);
}

// For hooks that cannot tell which agent is editing: closed paths for every agent; role limits live elsewhere.
export function assertEditBaseline(root, resource) {
  const path = projectPath(root, resource);
  if (secret(path)) throw new Error("Không cho agent truy cập credential hoặc signing secret.");
  if (taskRecord.test(path)) return;
  if (path.startsWith(".agents/tmp/")) return;
  if (protectedPath(path)) throw new Error("Policy, checker và generated không được sửa trực tiếp bởi agent.");
  assertPlacement(path);
}

// Raw merge, review and API stay closed for every agent; only delivery.mjs (see handoff) reaches them.
const delivery = /(^|[\s;&|(`])(?:git\s+(?:merge|tag|filter-branch|reset\s+--hard|rebase\s+(?:-i|--interactive))|gh\s+(?:pr\s+(?:merge|review)|release|repo\s+(?:delete|create|edit)|api)|xcrun\s+(?:altool|notarytool)|fastlane|codesign|security\s+(?:find|dump|export))(?=$|[\s;&|)`])/;
// Rebase is the senior's conflict tool on its own task branch; other callers stay out.
const rebase = /(^|[\s;&|(`])git\s+rebase(?=$|[\s;&|)`])/;

function assertDeliveryClosed(command, agent) {
  if (delivery.test(command)) throw new Error("Merge/tag/release/signing đang đóng; chỉ người vận hành thực hiện.");
  if (rebase.test(command) && agent !== senior) throw new Error("Rebase chỉ Senior làm trên nhánh task.");
}

const taskBranch = "(?:feat|fix|refactor|docs|test|chore|hotfix)/[a-z0-9][a-z0-9._-]*";
const handoff = {
  [senior]: [
    /^git commit(?: (?!--amend\b|--no-verify\b|-n\b)[^\s]+| "[^"]*"| '[^']*')*$/,
    new RegExp(`^git push((?: -u| --set-upstream| --force-with-lease)*) origin (?:HEAD:)?${taskBranch}$`),
    /^gh pr create (?=.*--base develop(?:\s|$))(?!.*--base (?!develop))(?:[^;&|`$<>]|"[^"`$]*"|'[^']*')*$/,
    /^gh pr (?:view|list|checks|status|diff)(?: [^\s;&|`$<>]+)*$/,
  ],
  [coordinator]: [
    /^node \.agents\/hiraku\/delivery\.mjs review \d+ (?:PASS|FAIL) --sha [0-9a-f]{40}$/,
    /^node \.agents\/hiraku\/delivery\.mjs merge \d+ --sha [0-9a-f]{40}$/,
    /^gh pr (?:view|list|checks|status|diff)(?: [^\s;&|`$<>]+)*$/,
  ],
};

const handoffCommand = /^(?:git\s+(?:commit|push)|gh\s+pr|node\s+\S*delivery\.mjs)\b/;

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

// Senior pushes task branches and opens PRs; coordinator records the verdict and merges through delivery.mjs.
function assertHandoff(root, agent, command) {
  for (const part of command.split(/&&|\|\||[;|\n]/).map((x) => x.trim())) {
    assertNoAiCredit(root, part);
    if (!handoffCommand.test(part)) {
      if (/(?:git\s+(?:commit|push)|gh\s+pr|delivery\.mjs)\b/.test(part)) {
        throw new Error("Lệnh commit/push/PR/delivery phải đứng đầu một đoạn lệnh.");
      }
      continue;
    }
    if (!(handoff[agent] ?? []).some((rule) => rule.test(part))) {
      throw new Error("Lệnh này không thuộc vai của agent: commit/push/PR cho Senior; review/merge cho Điều phối qua delivery.mjs.");
    }
  }
}

function assertCommandShape(root, command, cwd) {
  if (typeof command !== "string" || command.trim() === "") throw new Error("Lệnh không hợp lệ.");
  projectPath(root, cwd);
}

// Hooks that cannot tell which agent is calling check only what is closed for everyone.
export function assertShellBaseline(root, command, cwd = root) {
  assertCommandShape(root, command, cwd);
  assertDeliveryClosed(command, null);
}

export function assertShell(root, agent, command, cwd = root) {
  if (!agents.has(agent)) throw new Error("Agent không được chạy shell.");
  assertCommandShape(root, command, cwd);
  assertDeliveryClosed(command, agent);
  assertHandoff(root, agent, command);
}

async function markDirty(storage, event) {
  await storage.set(`dirty/${event.sessionID}`, { agent: event.agent, reviewInvalidated: true });
}

export async function evaluatePermission(root, event, storage) {
  try {
    if (event.action === "read" || event.action === "edit") {
      if (!event.resources.length) throw new Error("Thiếu đường dẫn để kiểm tra quyền.");
      for (const resource of event.resources) {
        assertPathAccess(root, event.agent, event.action, resource);
      }
      if (event.action === "edit") await markDirty(storage, event);
    }
    if (event.action === "subagent") {
      const allowed = delegates[event.agent] ?? [];
      if (event.resources.some((id) => !allowed.includes(id))) {
        throw new Error("Agent này không được gọi subagent đó.");
      }
    }
    if (event.action === "shell") {
      if (!event.resources.length) throw new Error("Thiếu lệnh để kiểm tra quyền.");
      // Both roles run a full shell; any mutation may invalidate an earlier review.
      if (agents.has(event.agent)) await markDirty(storage, event);
    }
  } catch (error) {
    event.effect = "deny";
    event.message = error.message;
  }
}
