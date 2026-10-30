# OpenCode — cấu hình hiraku

OpenCode 2.2. Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ giữ
phần riêng của OpenCode.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Agents | `.opencode/agents/` | Sinh từ vai trò chung; `hiraku-lead` primary, ba hiraku subagents |
| Agents dựng sẵn | `opencode.json` → `agents` | `explore`, `general`, `plan` bật có phạm vi; `build` tắt (trùng Coder) |
| Quyền | `opencode.json` | Cú pháp v2 (`permissions`, `agents`, action `shell`, `subagent`); default deny |
| Guard | `.opencode/plugins/hiraku-guard/index.js` | Hook `permission.evaluate` (có tên agent) và `shell.create.before` (raw command + cwd) |
| Model | frontmatter `model` (sinh từ `.agents/hiraku/models.json`); `explore`/`plan` trong `opencode.json` | Chỉ `explore`, `plan`, `hiraku-shipper` ghim model rẻ; còn lại dùng model phiên |
| Skills | `.agents/skills/` | OpenCode tự discovery `.agents/skills`; `opencode.json` chỉ cấp skill cho coder/reviewer |

Chạy `opencode` tại root; phiên mới mặc định `hiraku-lead`, phiên cũ phải chọn lại.
Không dùng `permission`, `agent`, `bash`, `task` hoặc hook v1.

Hook shell nhận tên agent thì kiểm đầy đủ theo vai; không có tên thì chỉ kiểm
phần đóng với mọi vai (delivery, cwd), phần theo vai do `permission.evaluate`
đã chặn trước. Edit hoặc shell của Lead/Coder/General ghi marker
`dirty/<sessionID>` vào storage plugin: nhắc vô hiệu review, không phải bằng chứng.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
opencode debug agents --standalone
opencode debug config --standalone
```

Agent list phải có `hiraku-lead` (primary), ba hiraku subagents, `explore`,
`general`, `plan`; không có `build`. Plugin `hiraku.guard` phải tải thành công.
Config global (`~/.config/opencode/`) cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
