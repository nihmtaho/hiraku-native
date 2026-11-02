# Claude Code — cấu hình hiraku

Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ giữ phần riêng của Claude Code.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Agents | `.claude/agents/hiraku-{coordinator,senior}.md` | Sinh từ vai trò chung bằng `node .agents/hiraku/sync.mjs`; sửa vai trò, không sửa file sinh |
| Điều phối | `settings.json` → `"agent": "hiraku-coordinator"` | Phiên chính chạy như điều phối; giao việc cho `hiraku-senior` |
| Quyền | `settings.json` → `permissions` | `allow: Bash`; `deny` cho delivery thô, secret, policy |
| Guard | `.claude/hooks/guard.mjs` (`PreToolUse`) | Dùng `agent_type` trong payload để kiểm theo vai bằng `.agents/hiraku/guard.mjs` |
| Skills | `.claude/skills` → `../.agents/skills` (symlink) | Một nguồn skills cho mọi công cụ |
| Ghi công | `settings.json` → `attribution` rỗng | Không đồng tác giả AI trong commit/PR theo `docs/process/GIT_WORKFLOW.md` §4 |

Merge và verdict đi qua `node .agents/hiraku/delivery.mjs` (ADR-33); `gh pr merge/review/api` thô bị chặn.

Chưa xử lý, cần kiểm trên phiên thật: built-in `general-purpose`, `Explore`, `Plan` vẫn
khả dụng vì settings chưa chặn; payload hook có thể thiếu `agent_type`, khi đó hook
coi là caller lạ và chỉ áp phần đóng với mọi vai.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
```

Chạy `claude` tại root, trust workspace, `/agents` phải liệt kê hai hiraku agents.
Config user (`~/.claude/settings.json`) cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
