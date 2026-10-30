# Command Code — cấu hình hiraku

Command Code 1.88. Quy trình và bảng quyền: `docs/process/AGENT_WORKFLOW.md`. Thư mục này chỉ
giữ phần riêng của Command Code.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Subagents | `.commandcode/agents/` | Sinh từ vai trò chung; frontmatter `name`, `description`, `tools`, `disallowedTools` |
| Lead | `.commandcode/lead.md` + hook `SessionStart` | Phiên chính là Lead; prompt được tiêm khi bắt đầu phiên. Không đặt trong `agents/` để không thành subagent |
| Agents dựng sẵn | General, Explore, Plan | Có sẵn, chỉ đọc cấu hình; tên `explore`, `general`, `plan` bị giữ chỗ |
| Quyền | `.commandcode/settings.json` → `permissions` | `allow: Shell` (Lead/Coder chạy mọi lệnh); `deny` cho delivery, secret, policy |
| Guard chung | `.commandcode/hooks/guard.mjs` (`PreToolUse`) | Hook không biết agent nào gọi: chỉ kiểm phần đóng với mọi vai |
| Guard theo vai | `.commandcode/mods/hiraku-roles.ts` | Mod theo dõi `subagent_start/stop`; không có subagent chạy = Lead; kiểm shell/edit theo vai |
| Model | `hiraku-shipper` frontmatter `model`; plan mode qua `featureModels.planning` | Sinh/kiểm từ `.agents/hiraku/models.json`. Built-in Explore không cấu hình model riêng được: chạy theo model phiên |
| Skills | `.agents/skills/` | Command Code tự discovery `.agents/skills` |
| Commit | `settings.json` → `attribution.commit: ""` | Tắt trailer đồng tác giả bot theo `docs/process/GIT_WORKFLOW.md` |

Chạy `cmd` tại root và trust workspace: mod dự án chỉ nạp sau khi trust. Chế độ
`-p` (headless) không nạp mod dự án trừ khi chạy với `--yolo`; khi đó deny rules
và hook `PreToolUse` vẫn áp dụng nhưng kiểm theo vai do mod. Subagent tự duyệt
prompt thường, nhưng deny rules và kiểm an toàn vẫn chặn.

Giới hạn: khi nhiều subagent khác vai chạy song song, mod buộc mỗi lệnh đạt luật
của mọi vai đang chạy (bảo thủ). Lệnh của Lead gửi trong lúc subagent nền đang
chạy bị kiểm theo vai subagent đó. Prompt Lead nằm ở lượt đầu, có thể mất sau
compaction; luật vẫn nằm trong `AGENTS.md`.

## Kiểm tra

```sh
node .agents/hiraku/sync.mjs --check
node --test .agents/hiraku/tests/*.test.mjs
```

Trong phiên: `/agents` phải liệt kê ba hiraku subagents cùng General/Explore/Plan;
`/mods` phải có `hiraku-roles`. Config user (`~/.commandcode/settings.json`) và
mod user cũng có thể đổi quyền: kiểm cấu hình hợp nhất.
