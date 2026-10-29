import { realpathSync } from "node:fs";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";

export const agents = new Set([
  "hiraku-lead", "hiraku-coder", "hiraku-reviewer", "hiraku-shipper",
]);

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
    || /(^|\/)(\.git|\.github|\.opencode|\.pi)(\/|$)/i.test(path)
    || /(^|\/)(?:gen|generated)(\/|$)/i.test(path)
    || /^Frameworks\//i.test(path)
    || /(^|\/)scripts\/(?:check-[^/]+|build-xcframework\.sh|import-rules\.txt)$/i.test(path);
}

export function assertPathAccess(root, agent, action, resource) {
  const path = projectPath(root, resource);
  if (secret(path)) throw new Error("Không cho agent truy cập credential hoặc signing secret.");
  if (action !== "edit") return;
  if (!agents.has(agent)) throw new Error("Agent không thuộc bộ hiraku.");
  const task = /^\.opencode\/tasks\/[a-z0-9]+(?:-[a-z0-9]+)*\.md$/.test(path);
  if (task && (agent === "hiraku-lead" || agent === "hiraku-shipper")) return;
  if (agent !== "hiraku-coder") throw new Error("Agent này không được sửa source.");
  if (protectedPath(path)) throw new Error("Policy, checker và generated không được sửa trực tiếp bởi agent.");
}

const inspection = new Set([
  "git status --short",
  "git diff --no-ext-diff --no-textconv",
  "git diff --no-ext-diff --no-textconv --stat",
  "git rev-parse HEAD",
  "node --test .opencode/tests/*.test.mjs",
]);

export function assertShell(root, agent, command, cwd = root) {
  if (!agents.has(agent)) throw new Error("Agent không được chạy shell.");
  const directory = projectPath(root, cwd);
  if (directory === "" && inspection.has(command)) return;
  const developer = agent === "hiraku-coder" || agent === "hiraku-reviewer";
  if (!developer) throw new Error("Agent chỉ được chạy lệnh kiểm tra được liệt kê.");
  if (directory === "core" && /^(?:go test(?: -race)?|go vet) \.\/(?:[A-Za-z0-9_/-]+|\.\.\.)$/.test(command)) {
    return;
  }
  if (directory !== "") throw new Error("Lệnh phải chạy tại root hoặc core theo OPENCODE.md.");
  if (/^swift test --package-path Packages\/(?:Features\/)?[A-Za-z][A-Za-z0-9]*$/.test(command)) {
    const path = command.slice("swift test --package-path ".length);
    projectPath(root, path);
    return;
  }
  if (command === "buf lint") return;
  if (/^buf breaking --against ['"]?\.git#(?:branch|ref)=[A-Za-z0-9_/-]+(?:,subdir=core)['"]?$/.test(command)) return;
  const scripts = new Set([
    "bash Scripts/check-imports.sh",
    "bash core/scripts/check-core.sh",
  ]);
  if (agent === "hiraku-coder") scripts.add("bash core/scripts/build-xcframework.sh");
  if (scripts.has(command)) {
    projectPath(root, command.slice("bash ".length));
    return;
  }
  if (agent === "hiraku-coder" && command === "buf generate") return;
  if (/^xcodebuild test -scheme Hiraku -destination '(?:platform=macOS|platform=iOS Simulator,id=[A-Fa-f0-9-]+)'$/.test(command)) return;
  throw new Error("Lệnh ngoài allowlist; không được dùng shell/interpreter để vượt quyền.");
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
      if (event.agent !== "hiraku-lead" || event.resources.some((id) =>
        !["hiraku-coder", "hiraku-reviewer", "hiraku-shipper"].includes(id))) {
        throw new Error("Chỉ Lead được gọi ba subagents hiraku.");
      }
    }
    if (event.action === "shell") {
      if (!event.resources.length) throw new Error("Thiếu lệnh để kiểm tra quyền.");
      for (const command of event.resources) {
        // Shell hook kiểm tra cwd thực; scanner không cung cấp cwd ở permission event.
        const cwd = /^(go test|go vet) /.test(command) ? resolve(root, "core") : root;
        assertShell(root, event.agent, command, cwd);
      }
      if (event.resources.includes("buf generate")) {
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
