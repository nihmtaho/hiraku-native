# Design: Flowkit eval suite

Ngày: 2026-11-10 · Trạng thái: chờ PO duyệt · Nhánh: `feat/portable-skills-kit`

## Intent

Kit đã qua checker cấu trúc, nhưng theo `docs/process/AGENT_WORKFLOW.md` §5: lint đạt không
phải bằng chứng hành vi đúng. Trước khi promote kit, cần bộ eval hành vi theo đúng quy ước
repo (`<skill>/evals/evals.json`, chạy read-only theo prompt, so với assertions) và một lần
chạy thật để biết skill nào hành xử sai.

## Phạm vi (đã chốt)

- **12 skill kit tự viết** (`flow-coordinator`, `flow-task`, `flow-implement`, `flow-pr`,
  `flow-review`, `flow-ship`, `flow-status`, `flow-interface`, `flow-feature`, `flow-spike`,
  `flow-debug`, `product-review`): 2–3 eval mỗi skill (~28 prompt).
  - 5 bộ port/adapt từ eval hiraku có sẵn (`task`, `wp-status`, `contract`, `feature`,
    `spike-report`) — bỏ đặc thù hiraku, đổi sang fixture trung tính.
  - 7 bộ viết mới: coordinator, implement, review, ship, pr, debug, product-review.
- **8 skill PM**: 1 smoke eval mỗi skill (~8 prompt) để bắt lỗi do adaptation.
- Tổng: 20 file `evals.json`, ~36 prompt.

## Thiết kế

### Vị trí và schema

`.tmp/flowkit/skills/<name>/evals/evals.json`, đúng schema repo:

```json
{ "skill_name": "<name>",
  "evals": [ { "id": 1, "prompt": "...", "expected_output": "...",
               "files": [], "assertions": ["...", "..."] } ] }
```

Assertion viết dạng câu khẳng định kiểm được bằng đọc kết quả (như 5 bộ hiraku hiện có).

### Fixture trung tính

Mọi prompt dùng một dự án giả định mô tả ngay trong prompt (không tạo file): một repo có
`PROJECT.md` với status file, base branch `develop`, lệnh test, docs map. Không dùng
`hiraku`, `ROADMAP`, `DECISIONS`, `WP-`, `task-context`, `wp-status` — checker quét mọi file
dưới `skills/**`, kể cả `evals/`.

### Cách chạy (trong phiên này)

- Mỗi skill 1 subagent read-only: nạp `SKILL.md`, trả lời từng prompt như đang ở fixture,
  không sửa file, tự đối chiếu từng assertion và trả PASS/FAIL + bằng chứng.
- 12 skill kit chạy song song theo lô; 8 PM gộp 2 skill/subagent.
- Controller spot-check các FAIL và các PASS đáng ngờ.

### Đầu ra

- 20 file eval trong kit (commit lên nhánh).
- `.tmp/flowkit/evals/REPORT.md`: bảng per-skill (số assertion PASS/FAIL), danh sách FAIL
  kèm bằng chứng, và quyết định: sửa skill + chạy lại, hay ghi nhận là giới hạn đã biết.
- Gate `check-kit.mjs` vẫn `OK` (eval nằm trong `skills/**` nên phải sạch token).

### Sửa khi FAIL

FAIL thật (skill hướng dẫn sai, thiếu guardrail, mơ hồ) → sửa `SKILL.md`, chạy lại đúng eval
đó, commit. FAIL do prompt/assertion viết dở → sửa eval, ghi rõ trong report.

## Non-goals

- Không viết runner tự động gọi model (`opencode run`); chạy bằng subagent là đủ cho một lần
  kiểm trước promote, và repo chưa có runner như vậy.
- Không eval hành vi sâu cho PM (nội dung verbatim từ plugin).
- Không thay đổi 12 skill ngoài các FAIL thật.
- Không promote kit vào `.agents/skills/` trong task này.

## Acceptance

1. 20 `evals.json` hợp lệ, đúng schema, không chứa token bị cấm.
2. `node .tmp/flowkit/scripts/check-kit.mjs` → `flowkit check: OK`.
3. Report có verdict từng assertion, không có FAIL bị bỏ qua không giải thích.
4. Commit + push lên PR #83.
