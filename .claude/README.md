# Claude Code — cấu hình hiraku

Quy trình: `docs/process/AGENT_WORKFLOW.md`. Không còn agent tùy chỉnh hay hook guard.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Skills | `.claude/skills` → `../.agents/skills` (symlink) | Điều phối bằng `hiraku-coordinator`; coding, review, PR, ship |
| Built-in | Explore, Plan, subagent mặc định | Có sẵn; review độc lập chạy trong subagent mặc định (Agent tool không truyền `subagent_type`) |
| Quyền | `settings.json` → `permissions` | Hiện chỉ `allow: Bash`, không có deny |
| Ghi công | `settings.json` → `attribution` rỗng | Không đồng tác giả AI trong commit và PR |

Kiểm tra: `node --test .agents/hiraku/tests/*.test.mjs`. Config user (`~/.claude/settings.json`)
cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
