# Claude Code — cấu hình hiraku

Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ giữ phần riêng của Claude Code.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Agents | `.claude/agents/hiraku-{lead,coder,reviewer,shipper}.md` | Sinh từ vai trò chung bằng `node .agents/hiraku/sync.mjs`; sửa vai trò, không sửa file sinh |
| Lead | `settings.json` → `"agent": "hiraku-lead"` | Phiên chính chạy như Lead; giao việc cho coder, reviewer, shipper và built-in Explore/Plan/general-purpose |
| Quyền | `settings.json` → `permissions` | `allow: Bash`; `deny` cho delivery thô, secret, policy |
| Guard | `.claude/hooks/guard.mjs` (`PreToolUse`) | Dùng `agent_type` trong payload để kiểm theo vai bằng `.agents/hiraku/guard.mjs`; caller lạ chỉ chịu phần đóng với mọi vai |
| Model | `hiraku-shipper` frontmatter `model` | Sinh từ `.agents/hiraku/models.json` (tier `cheap` → `haiku`); vai khác theo model phiên |
| Skills | `.claude/skills` → `../.agents/skills` (symlink) | Một nguồn skills cho mọi công cụ |
| Ghi công | `settings.json` → `attribution` rỗng | Không đồng tác giả AI trong commit/PR theo `docs/process/GIT_WORKFLOW.md` §4 |

Merge và verdict đi qua `node .agents/hiraku/delivery.mjs` (ADR-33); `gh pr merge/review/api` thô bị chặn.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
```

Chạy `claude` tại root repo, trust workspace, `/agents` phải liệt kê bốn hiraku agents. Chưa kiểm phiên Claude Code thật với cấu hình này: hãy xác nhận `agent_type` có trong payload hook ở phiên của bạn (nếu thiếu, guard chỉ còn phần chung cho mọi vai). Config user (`~/.claude/settings.json`) cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
