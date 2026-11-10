# Design: adopt Flowkit into .agents/skills

Ngày: 2026-11-11 · Trạng thái: chờ PO duyệt · Nhánh: `feat/portable-skills-kit` (PR #83)

## Intent

Kit đã được eval (101/101). PO chốt adopt toàn bộ: Flowkit trở thành bộ skill đang chạy của repo,
hiraku chỉ còn là một profile (`PROJECT.md`). Kit ở `.tmp/flowkit/` vẫn là bản phân phối cho dự án
khác; `.agents/skills/` nhận bản cài.

## Hiện trạng đã quét

- 10 skill `hiraku-*` đang chạy; 2 script nằm trong skill: `hiraku-wp-status/scripts/wp-status.mjs`,
  `hiraku-task/scripts/task-context.mjs`; `hiraku-spike-report/references/report-template.md`.
- Tham chiếu tên skill/đường dẫn script ở: `AGENTS.md`, `docs/process/{AGENT_WORKFLOW,GIT_WORKFLOW,RELEASE}.md`,
  `ROADMAP.md`, `CHANGELOG.md`, `.github/workflows/ci.yml`, `.agents/hiraku/tests/skills.test.mjs`,
  `.claude/README.md`, `docs/architecture/DECISIONS.md`.
- Lịch sử không đụng: `.agents/tasks/*`, `docs/plans/*` (cũ), `docs/archive/*`, các mục CHANGELOG/ADR cũ.

## Thay đổi

1. **Script tách khỏi skill** → `.agents/scripts/wp-status.mjs`, `.agents/scripts/task-context.mjs`.
   Cập nhật import trong `.agents/hiraku/tests/skills.test.mjs` và lệnh trong `ci.yml`, `PROJECT.md`.
2. **Cài 20 skill** từ `.tmp/flowkit/skills/` vào `.agents/skills/` (kèm `evals/`).
   `hiraku-spike-report/references/report-template.md` → `flow-spike/references/`.
   Xóa 10 thư mục `hiraku-*` (đã được `flow-*` thay thế 1:1).
   Thêm `LICENSE.pm-skills` (Apache-2.0) vào `.agents/skills/`.
3. **`PROJECT.md` ở root**, nội dung từ `profiles/hiraku-native.md`, sửa đường dẫn script mới và
   trỏ `PROJECT.md.example` của kit. Bỏ quy định root chỉ có file cũ: thêm `PROJECT.md` (trong AGENTS.md).
4. **`AGENTS.md`**: đổi tên skill `hiraku-*` → `flow-*`, thêm dòng trỏ `PROJECT.md`, ghi kit ở
   `.tmp/flowkit/`, giữ nguyên luật Go/Swift/ADR (không đổi hành vi sản phẩm).
5. **Policy docs**: đổi tên skill trong `AGENT_WORKFLOW.md`, `GIT_WORKFLOW.md`, `RELEASE.md`,
   `.claude/README.md`; `ROADMAP.md` chỉ đổi nếu có tên skill (kiểm khi làm).
   `DECISIONS.md`: thêm **một mục sửa đổi** dưới ADR-31 ghi việc adopt, không viết lại ADR cũ.
6. **CHANGELOG** `[Unreleased]` → Tài liệu: một dòng adopt (PR 83).
7. **ROADMAP §11/Kanban**: không có WP cho việc này → không thêm dòng giả; ghi trong PR body.

## Không làm

- Không sửa nội dung 20 skill (bản cài = bản đã eval).
- Không xóa `.tmp/flowkit/` (bản phân phối).
- Không đổi contract, Go/Swift, dữ liệu.
- Không promote PM license thành license repo.

## Rủi ro

- PR chạm `AGENTS.md`, `docs/process/`, `DECISIONS.md`, `.github/`, `.agents/` → người vận hành review
  trước merge (quy ước repo).
- Xóa `hiraku-*` đổi tên skill agent dùng; đã quét hết nơi tham chiếu, kiểm lại bằng grep sau khi làm.
- Script đổi chỗ: nếu còn chỗ nào gọi đường dẫn cũ, CI hoặc workflow gãy — verify bằng test + `--check` + grep.

## Acceptance

1. `.agents/skills/` có đúng 20 skill Flowkit + các skill git/domain sẵn có; không còn `hiraku-*`.
2. `node --test .agents/hiraku/tests/*.test.mjs` xanh; `node .agents/scripts/wp-status.mjs --check` khớp.
3. `node .tmp/flowkit/scripts/check-kit.mjs` vẫn `OK`.
4. Không còn tham chiếu `hiraku-<skill>` ngoài lịch sử (`docs/plans` cũ, `.agents/tasks`, CHANGELOG/ADR cũ).
5. `PROJECT.md` + `AGENTS.md` mô tả đúng bộ mới; CHANGELOG có dòng adopt.
6. Commit + push lên PR #83; PR body ghi cảnh báo policy.
