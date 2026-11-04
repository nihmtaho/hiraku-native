# Command Code — cấu hình hiraku

Quy trình: `docs/process/AGENT_WORKFLOW.md`. Không còn subagent, hook hay mod.

| Thành phần | Đường dẫn | Ghi chú |
|---|---|---|
| Skills | `.agents/skills/` | Command Code tự discovery |
| Cấu hình | `settings.json` | `featureModels.planning` (model plan mode) và `attribution.commit` rỗng |

Kiểm tra: `node --test .agents/hiraku/tests/*.test.mjs`.
