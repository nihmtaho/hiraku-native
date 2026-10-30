# Tài liệu hiraku

Root chỉ giữ `AGENTS.md`, `CHANGELOG.md`, `COPY.md`, `ROADMAP.md` và
`ROADMAP hiraku — Kanban.html`. Mọi tài liệu khác nằm ở đây.

| Thư mục | Nội dung |
|---|---|
| `product/` | `spec.md`, `use-cases.md`, `DESIGN.md`, `WIREFRAME_PROMPT.md` |
| `architecture/` | `ARCHITECTURE.md`, `DECISIONS.md` (ADR, Q) |
| `process/` | `GIT_WORKFLOW.md`, `AGENT_WORKFLOW.md`, `RELEASE.md`, `TEST_PLAN.md` |
| `plans/` | Kế hoạch kỹ thuật, thiết kế giải pháp, đề xuất trước khi làm (`<chủ-đề>.md`) |
| `reports/` | Kết quả spike, đo hiệu năng, kiểm thử thủ công, audit (`<mốc>-<chủ-đề>.md`, ví dụ `M0_SPIKE.md`) |
| `mimikara-n3/` | Dữ liệu từ vựng nguồn |

Ngoài `docs/`:

- File tạm, log, scratch của AI: `.agents/tmp/` (gitignore, xóa được bất cứ lúc nào).
- Task record của agent: `.agents/tasks/`; mẫu `.agents/templates/task.md`.
- Artifact build/test (archive, xcresult, coverage): trong thư mục build của module
  (ví dụ `core/.spike/`) và gitignore; báo cáo tóm tắt kết quả đặt ở `reports/`.
