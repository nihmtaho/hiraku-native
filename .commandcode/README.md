# Command Code — cấu hình hiraku

Command Code 1.88. Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ
giữ phần riêng của Command Code.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Subagents | `.commandcode/agents/` | Sinh từ vai trò chung; hiện chỉ `hiraku-senior` (frontmatter `name`, `description`, `tools`) |
| Điều phối | `.commandcode/coordinator.md` + hook `SessionStart` | Phiên chính là điều phối; prompt được tiêm khi bắt đầu phiên. Không đặt trong `agents/` để không thành subagent |
| Quyền | `.commandcode/settings.json` → `permissions` | `allow: Shell`; `deny` cho delivery, secret, policy |
| Guard chung | `.commandcode/hooks/guard.mjs` (`PreToolUse`) | Hook không biết agent nào gọi: chỉ kiểm phần đóng với mọi vai |
| Guard theo vai | `.commandcode/mods/hiraku-roles.ts` | Mod theo dõi `subagent_start/stop`; không có subagent chạy = điều phối; kiểm shell/edit theo vai |
| Model | Sinh/kiểm từ `.agents/hiraku/models.json`; plan mode qua `featureModels.planning` | Hiện không ghim model cho vai nào |
| Skills | `.agents/skills/` | Command Code tự discovery `.agents/skills` |
| Commit | `settings.json` → `attribution.commit: ""` | Tắt trailer đồng tác giả bot theo `docs/process/GIT_WORKFLOW.md` |

Chạy `cmd` tại root và trust workspace: mod dự án chỉ nạp sau khi trust. Chế độ
`-p` (headless) không nạp mod dự án trừ khi chạy với `--yolo`. Khi đó kiểm theo vai
không còn; **chưa xử lý**: cần chặn lệnh delivery và force-push ở lớp hook chung, hoặc
từ chối chạy headless cho vai có quyền delivery.

Giới hạn: khi nhiều subagent khác vai chạy song song, mod buộc mỗi lệnh đạt luật
của mọi vai đang chạy (bảo thủ). Prompt điều phối nằm ở lượt đầu, có thể mất sau
compaction; luật vẫn nằm trong `AGENTS.md`.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
```

Trong phiên: `/agents` phải liệt kê `hiraku-senior`; `/mods` phải có `hiraku-roles`.
Config user (`~/.commandcode/settings.json`) và mod user cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
