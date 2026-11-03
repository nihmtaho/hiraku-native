# OpenCode — cấu hình hiraku

Quy trình: `docs/process/AGENT_WORKFLOW.md`. Không còn agent, plugin guard hay bảng quyền riêng.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Skills | `.agents/skills/` | OpenCode tự discovery |
| Cấu hình | `opencode.json` | Chỉ giữ schema, `share` và `update`; agent và quyền đã bỏ |

Kiểm tra: `opencode debug config --standalone`. Config global (`~/.config/opencode/`) cũng có thể
đổi quyền: kiểm cấu hình hợp nhất.
