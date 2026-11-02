# Pi — cấu hình hiraku

Pi 1.4. Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ giữ phần
riêng của Pi. Không cần cài package npm.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Agents | `.pi/agents/` | Sinh từ vai trò chung; frontmatter `name`, `description`, `tools`; điều phối có `mode: primary` |
| Điều phối + guard | `.pi/extensions/hiraku-guard.ts` | Phiên chính là điều phối (thêm prompt điều phối vào system prompt); chặn tool ngoài allowlist |
| Subagents | `.pi/extensions/subagent/` | Bản ví dụ `subagent` của Pi (MIT); đọc `.pi/agents/` trừ agent primary |
| Model | Sinh từ `.agents/hiraku/models.json` | Hiện không ghim model cho vai nào |
| Skills | `.agents/skills/` | Pi tự discovery `.agents/skills` |

Pi không có agent dựng sẵn; hai vai là toàn bộ bộ agent.

Chạy `pi` tại root và chấp nhận project trust (extension chỉ nạp khi đã trust).
Tiến trình subagent nhận `HIRAKU_AGENT=<agent>` và `--approve`, nên nạp cùng guard
với đúng vai. Shell không được đặt `HIRAKU_AGENT` hay gọi CLI agent lồng nhau
(guard chặn cho senior). Bash của Pi không có cwd: lệnh trong `core/` viết `cd core && …`.

Tool ngoài `read/grep/find/ls/bash/edit/write/subagent` bị chặn (kể cả MCP, web,
codemode). Chưa có marker vô hiệu review. Packages và extension global của người
dùng vẫn được nạp; kiểm tra chúng khi đánh giá quyền.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
HIRAKU_AGENT=hiraku-senior pi -p "merge 7"   # phải bị chặn: senior không gọi được delivery
```

Sau khi đổi version Pi, so `subagent/index.ts` với ví dụ mới của Pi và chạy lại.
