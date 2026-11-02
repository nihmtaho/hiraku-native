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
  return /(^|\/)(AGENTS\.md|OPENCODE\.md|AGENT_WORKFLOW\.md|GIT_WORKFLOW\.md|DECISIONS\.md|RELEASE\.md|TEST_PLAN\.md|opencode\.jsonc?)$/i.test(path)
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

// Commands are split and canonicalized before any rule runs, so quotes, case, wrappers,
// global options and binary paths cannot change which verb a rule sees.
const assignment = /^[A-Za-z_][A-Za-z0-9_]*=/;
const wrappers = new Set(["env", "nohup", "exec", "command", "nice", "time", "timeout", "sudo", "builtin"]);
const wrapperValueOpts = { env: ["-u", "-C", "-S"], nice: ["-n"], timeout: ["-s", "-k"], sudo: ["-u", "-g", "-C"], exec: ["-a"] };
const shells = new Set(["sh", "bash", "zsh", "dash"]);
const gitValueOpts = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--attr-source", "--super-prefix", "--config-env"]);
const ghValueOpts = new Set(["-R", "--repo", "--hostname"]);
const agentClis = new Set(["claude", "opencode", "pi", "cmd", "commandcode"]);
const maxDepth = 8;

// Splits a command line into simple commands; quotes and escapes are resolved, unquoted operators end a command.
function splitCommands(text) {
  const commands = [];
  let words = [];
  let word = null;
  let quote = null;
  const endWord = () => { if (word !== null) { words.push(word); word = null; } };
  const endCommand = () => { endWord(); if (words.length) commands.push(words); words = []; };
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quote === "'") {
      if (c === "'") quote = null; else word += c;
    } else if (c === "\\" && i + 1 < text.length) {
      word = (word ?? "") + text[++i];
    } else if (quote === '"') {
      if (c === '"') quote = null; else word += c;
    } else if (c === "'" || c === '"') {
      quote = c;
      word ??= "";
    } else if (c === "\n" || ";&|()`".includes(c)) {
      endCommand();
    } else if (/\s/.test(c)) {
      endWord();
    } else {
      word = (word ?? "") + c;
    }
  }
  endCommand();
  return commands;
}

// Skips leading options; value options named in valueOpts take the next token when given without "=".
function skipOptions(rest, valueOpts) {
  let k = 0;
  while (k < rest.length && rest[k].startsWith("-")) k += valueOpts.has(rest[k]) ? 2 : 1;
  return k;
}

function skipWrapper(name, rest) {
  const values = new Set(wrapperValueOpts[name] ?? []);
  let k = 0;
  while (k < rest.length && (rest[k].startsWith("-") || (name === "env" && assignment.test(rest[k])))) {
    k += values.has(rest[k]) ? 2 : 1;
  }
  return name === "timeout" ? k + 1 : k;
}

function segmentsOf(text, depth = 0) {
  if (depth > maxDepth) throw new Error("Lệnh lồng quá sâu để kiểm tra.");
  const substitutions = [...text.matchAll(/\$\(([^()]*)\)|`([^`]*)`/g)].map((m) => m[1] ?? m[2]);
  return [
    ...substitutions.flatMap((s) => segmentsOf(s, depth + 1)),
    ...splitCommands(text).flatMap((words) => canonical(words, depth)),
  ];
}

// Returns canonical command strings: wrappers, assignments and shell -c / eval are resolved, argv0 is a lowercase basename.
function canonical(words, depth) {
  let i = 0;
  while (i < words.length && assignment.test(words[i])) i++;
  if (i >= words.length) return [];
  const name = words[i].split("/").pop().toLowerCase();
  const rest = words.slice(i + 1);
  if (wrappers.has(name)) return canonical(rest.slice(skipWrapper(name, rest)), depth);
  if (shells.has(name)) {
    const k = rest.findIndex((w) => /^-[a-zA-Z]*c[a-zA-Z]*$/.test(w));
    if (k >= 0 && rest[k + 1] !== undefined) return segmentsOf(rest[k + 1], depth + 1);
  }
  if (name === "eval") return segmentsOf(rest.join(" "), depth + 1);
  if (name === "git") return [["git", ...rest.slice(skipOptions(rest, gitValueOpts))].join(" ")];
  if (name === "gh") return [["gh", ...rest.slice(skipOptions(rest, ghValueOpts))].join(" ")];
  return [[name, ...rest].join(" ")];
}

const delivery = /^(?:git (?:merge|tag|filter-branch|reset --hard|rebase (?:-i|--interactive))|gh (?:pr (?:merge|review)|release|repo (?:delete|create|edit)|api)|xcrun (?:altool|notarytool)|fastlane|codesign|security (?:find|dump|export)[\w-]*)(?=$| )/;
// Rebase is the senior's conflict tool on its own task branch; other callers stay out.
const rebase = /^git rebase(?=$| )/;

// Raw merge, review and API stay closed for every agent; only delivery.mjs (see handoff) reaches them.
function assertDeliveryClosed(command, agent) {
  for (const cmd of segmentsOf(command)) {
    if (delivery.test(cmd)) throw new Error("Merge/tag/release/signing đang đóng; chỉ người vận hành thực hiện.");
    if (rebase.test(cmd) && agent !== senior) throw new Error("Rebase chỉ Senior làm trên nhánh task.");
  }
}

const taskBranch = "(?:feat|fix|refactor|docs|test|chore|hotfix)/[a-z0-9][a-z0-9._-]*";
const handoff = {
  [senior]: [
    /^git commit(?: (?!--amend\b|--no-verify\b|--no-v\S*|-[A-Za-z]*n[A-Za-z]*(?=\s|$))[^\s]+)*$/,
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

const handoffCommand = /^(?:git (?:commit|push)|gh pr|node \S*delivery\.mjs)(?=$| )/;

// PR titles and bodies must not credit AI; checks inline text and the --body-file content.
const aiCredit = /generated (?:by|with) (?:ai|an ai|claude|copilot|chatgpt|gpt|opencode|command ?code)|ai[- ]generated|co-authored-by:[^\n]*(?:ai|bot|claude|copilot|gpt|opencode|commandcode|anthropic|openai)|🤖/i;

function assertNoAiCredit(root, part) {
  if (!/^gh pr (?:create|edit)(?= |$)/.test(part)) return;
  if (aiCredit.test(part)) throw new Error("Không ghi 'Generated by AI'/đồng tác giả AI trong tiêu đề hoặc body PR.");
  const file = /--body-file[= ]+(\S+)/.exec(part);
  if (!file) return;
  const path = file[1];
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
  for (const cmd of segmentsOf(command)) {
    assertNoAiCredit(root, cmd);
    if (!handoffCommand.test(cmd)) continue;
    if (!(handoff[agent] ?? []).some((rule) => rule.test(cmd))) {
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

// Identity comes from the runtime; no shell may set it, and a senior may not start another agent CLI.
function assertIdentity(agent, command) {
  if (/HIRAKU_AGENT/.test(command.replace(/["'\\]/g, ""))) throw new Error("Không đặt HIRAKU_AGENT trong lệnh: danh tính do runtime cấp.");
  if (agent === senior && segmentsOf(command).some((cmd) => agentClis.has(cmd.split(" ")[0]))) {
    throw new Error("Senior không gọi CLI agent lồng nhau.");
  }
}

export function assertShell(root, agent, command, cwd = root) {
  if (!agents.has(agent)) throw new Error("Agent không được chạy shell.");
  assertCommandShape(root, command, cwd);
  assertIdentity(agent, command);
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
