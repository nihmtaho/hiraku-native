# Design: Flowkit — portable skills kit (profile-driven)

Ngày: 2026-11-09 · Trạng thái: draft chờ PO duyệt · Nhánh: `feat/portable-skills-kit`

## 1. Intent và why

Bộ `.agents/skills/` hiện tại chạy thật tốt nhưng gắn cứng vào hiraku-native: tên skill
`hiraku-*`, nội dung tiếng Việt, và các bước tham chiếu WP/ROADMAP/DECISIONS/AGENTS.md của
repo này. Người dùng muốn:

1. Áp dụng phương pháp quản lý sản phẩm từ bộ plugin đã lưu trữ
   (`docs/archive/Product Management-1.2.0-v1/`) vào quy trình hiện tại.
2. Bộ skill + harness dùng được ở **bất kỳ dự án nào**, không chỉ hiraku-native.
3. Cải thiện bốn điểm: quản lý vòng đời & chất lượng dự án, coding (hiệu quả, không
   over-engineering, comment đúng chỗ), debugging, review (code/product/design).

**Deliverable:** một bản kit hoàn chỉnh trong `.tmp/flowkit/` trên nhánh này, để PO
đánh giá trước khi thay thế gì trong `.agents/skills/` (việc thay thế là task riêng, sau này).

## 2. Goals / Non-goals / Anti-goals

### Goals
- Kit copy-vào-dùng được: copy `skills/` → `.agents/skills/`, viết `PROJECT.md` từ mẫu,
  chạy được ở repo trung tính.
- Port **1:1** toàn bộ 10 skill quy trình `hiraku-*` thành skill generic (giữ workflow,
  guardrail, verdict-by-SHA đã chứng minh).
- Tích hợp 8 skill PM (gần như nguyên bản, tiếng Anh).
- Thêm skill debugging mới và skill review sản phẩm/design mới.
- Nhúng luật chất lượng coding (đơn giản, không over-engineering, comment giải thích
  *vì sao*) vào skill coding/review.
- Kèm: README cài đặt, `PROJECT.md.example`, profile mẫu hiraku, template AGENTS portable.
- Skill gốc trong `.agents/skills/` **không bị đụng tới**.

### Non-goals
- Không thay thế skill hiraku đang chạy (promotion là task riêng sau khi PO duyệt kit).
- Không đóng gói Claude plugin (marketplace/`claude plugin install`) — tránh maintain 2 format.
- Không port script hiraku (`task-context.mjs`, `wp-status.mjs`) — chúng là đặc thù repo;
  profile nêu nơi cắm lệnh status của từng dự án.
- Không dịch skill PM sang tiếng Việt; không setup MCP connector.
- Không đụng `docs/archive/` (giữ làm nguồn tham khảo).

### Anti-goals (thất bại nếu xảy ra)
- Kit vẫn chứa tham chiếu `hiraku`/`ROADMAP`/`DECISIONS` bên ngoài thư mục `profiles/`.
- Skill generic mất guardrail đang chạy (review đúng SHA, verdict PASS/FAIL/BLOCKED,
  không merge khi test chưa chạy, không force push trần…).
- Kit phình to vì thêm abstraction "để sau" (config format YAML, plugin system, registry).

## 3. Ranh giới & format

- Format skill: như repo hiện tại — thư mục skill + `SKILL.md`, frontmatter
  `name`, `description`, `compatibility` (bỏ `argument-hint` của Claude command).
- Ngôn ngữ kit: **tiếng Anh** (đã chốt). Profile mẫu hiraku được phép trích tiếng Việt.
- Nguồn: skill hiraku hiện tại + bộ PM archive. Port = generalize tham chiếu repo thành
  tham chiếu `PROJECT.md`, không viết lại workflow.

## 4. Approaches (đã chọn)

| Approach | Mô tả | Kết luận |
|---|---|---|
| **A. Profile-driven 1:1 port** | Giữ nguyên 10 workflow skill, thay chi tiết hiraku bằng cách đọc `PROJECT.md` ở root dự án; +8 PM skill; +2 skill mới; README + profile mẫu. | **CHỌN** — ít rủi ro, giữ guardrail, portable thật sự. |
| B. Tích hợp gọn | Gộp 10 → 4 skill lớn (plan/implement/review/ship). | Bỏ — viết lại lớn, mất guardrail chi tiết, rủi ro cao. |
| C. A + Claude plugin format | Như A nhưng đóng gói thêm `commands/` + metadata. | Bỏ bây giờ — 2 format phải maintain song song; cần lại thì làm sau. |

## 5. Thiết kế

### 5.1 Layout kit

```
.tmp/flowkit/
├── README.md                 # cài đặt: copy, viết PROJECT.md, bảng mapping hiraku→flow,
│                             #   ghi chú ngoại lệ .tmp/ và Apache-2.0 LICENSE của skill PM
├── LICENSE.pm-skills         # LICENSE Apache-2.0 kèm theo 8 skill PM port
├── PROJECT.md.example        # mẫu profile (xem 5.2)
├── AGENTS.template.md        # harness portable, generalize từ AGENTS.md hiraku
├── profiles/
│   └── hiraku-native.md      # profile đã điền cho hiraku (ví dụ thực tế)
├── scripts/
│   └── check-kit.mjs         # self-check (xem 5.6)
└── skills/
    ├── flow-coordinator/     # ← hiraku-coordinator
    ├── flow-task/            # ← hiraku-task
    ├── flow-implement/       # ← hiraku-coding  (+ luật chất lượng coding)
    ├── flow-pr/              # ← hiraku-create-pr
    ├── flow-review/          # ← hiraku-review   (+ checklist chất lượng)
    ├── flow-ship/            # ← hiraku-ship
    ├── flow-status/          # ← hiraku-wp-status (protocol chung, script theo profile)
    ├── flow-interface/       # ← hiraku-contract (đổi API/schema/breaking change)
    ├── flow-feature/         # ← hiraku-feature  (thêm feature dọc vào app có cấu trúc)
    ├── flow-spike/           # ← hiraku-spike-report (thí nghiệm time-boxed, có bằng chứng)
    ├── flow-debug/           # MỚI — debugging
    ├── product-review/       # MỚI — review spec/design/product
    ├── write-spec/           # PM
    ├── roadmap-update/       # PM
    ├── sprint-planning/      # PM
    ├── stakeholder-update/   # PM
    ├── synthesize-research/  # PM
    ├── competitive-brief/    # PM
    ├── metrics-review/       # PM
    └── product-brainstorming/# PM
```

Prefix `flow-` để không trùng id với skill superpowers/PM đang có; 10 skill hiraku giữ
mapping 1:1, PM giữ tên gốc.

### 5.2 Cơ chế profile — `PROJECT.md`

Mỗi skill quy trình mở đầu bằng: *"Read `PROJECT.md` at repo root first. If missing, stop
and ask the user to create it from `PROJECT.md.example`."* Sections:

1. **Project** — tên, stack, cấu trúc thư mục chính.
2. **Status tracking** — file + lệnh trạng thái (hiraku: ROADMAP §11, Kanban,
   `wp-status.mjs --check`). `flow-status` chạy lệnh profile nêu; không có thì skill bỏ bước.
3. **Git & PR** — base branch, quy ước commit, template PR path, policy files cần người
   vận hành review.
4. **Checks** — lệnh test/lint bắt buộc kèm kỷ luật exit code (`Not run` khi chưa chạy).
5. **Docs map** — plans/reports/decisions/spec ở đâu.
6. **Architecture rules** — file luật (hiraku: `ARCHITECTURE.md`, `DECISIONS.md`).
7. **Quality rules** — style, ngôn ngữ comment, ranh giới module (hiraku: Go/Swift boundary,
   C1–C8).
8. **PM hooks** — task lớn/ mơ hồ thì dùng `write-spec` trước; milestone thì
   `stakeholder-update`; planning thì `roadmap-update`/`sprint-planning`.

Luật chất lượng **universal** nằm trong skill (không lặp trong profile); profile chỉ thêm
đặc thù dự án.

### 5.3 Port 10 skill quy trình

- Giữ nguyên thứ tự bước, verdict model, guardrail (một senior một lúc, review trong
  subagent mới, PASS đúng SHA, `--force-with-lease` chỉ trên nhánh task, không AI trailer…).
- Thay: đường dẫn `.agents/skills/hiraku-*` → tên skill `flow-*`; WP/Q/ADR → mục trong
  profile; lệnh cụ thể → "the Check commands in `PROJECT.md`".
- `flow-interface` / `flow-feature` / `flow-spike`: generalize mạnh nhất —
  interface = mọi thay đổi breaking cần migration + golden test; feature = thêm vertical
  slice theo module map trong profile; spike = experiment với ladder xác minh
  (build-only → chạy được → môi trường thật) và bốn kết luận Đạt/Không đạt/Chưa chạy/Bị chặn.
- Bỏ tham chiếu script hiraku; profile nêu lệnh status tương ứng (không có → bỏ bước, ghi rõ).

### 5.4 Luật coding & review được nâng cấp

Vào `flow-implement` (rút từ C1–C8 + phong cách hiện repo, generalize):
- Đơn giản nhất đủ yêu cầu; không abstraction "để sau"; không mã cao siêu.
- Sửa phần được yêu cầu; hàm ngắn, return sớm, lồng tối đa 3 cấp.
- Comment 1 dòng, giải thích *vì sao* (ngôn ngữ theo profile), cấm mô tả lại mã; không dead code.
- Test hành vi, ngắn, mỗi test một ý; chạy lệnh nhỏ nhất bao phủ thay đổi, ghi exit code.

Vào `flow-review` (bổ sung ngoài protocol hiện có):
- Đọc connected code, không chỉ diff; kiểm data-loss, security, error handling, race.
- Không PASS khi test chưa chạy (ghi `Not run` = finding).

### 5.5 Hai skill mới

**`flow-debug`** (debugging — hiện không có):
1. Reproduce trước; ghi lệnh + output thật.
2. Thu hẹp theo evidence, không sửa theo cảm tính.
3. Tìm root cause ở code dùng chung (fix một lần, không patch lặp caller).
4. Fix nhỏ nhất; regression test tái hiện trước khi fix.
5. Không bao giờ "fix" bằng cách xóa test, tắt check, nuốt lỗi.

**`product-review`** (review spec/design/product):
- Review một spec/PRD/design theo: problem có thật không, scope/non-goals rõ chưa,
  success metric đo được chưa, acceptance criteria đầy đủ chưa, rủi ro & phụ thuộc,
  có gì over-built không.
- Checklist design: mục tiêu user, accessible (liên kết skill `accessibility` nếu có),
  nhất quán với docs product hiện có.
- Trả findings phân mức (chặn / nên sửa / đề xuất) — không sửa file trong lúc review
  (giữ mô hình read-only như `flow-review`).

### 5.6 Self-check — `scripts/check-kit.mjs`

Chạy `node .tmp/flowkit/scripts/check-kit.mjs`, exit 0 khi:
- Mỗi thư mục skill có `SKILL.md`, frontmatter có `name` + `description`.
- `skills/**` không chứa `hiraku`, `ROADMAP`, `DECISIONS`, `WP-` (quan chiếu qua profile).
- Không có skill trùng tên với nhau.
- `PROJECT.md.example` có đủ mọi section mà các skill `flow-*` yêu cầu đọc.

Đây là test bắt buộc của thay đổi này (logic mới = có check).

### 5.7 Harness portable — `AGENTS.template.md`

Generalize từ AGENTS.md hiraku, bỏ đặc thù Go/Swift/ADR:
- Đọc trước tài liệu theo mục liên quan; nơi đặt file (`docs/plans`, `docs/reports`,
  tmp theo profile).
- Luật cứng (contract source-of-truth, transaction, time qua `now_ms`…) → thay bằng
  *"Architecture rules live in the file named by PROJECT.md §6"*.
- Quy trình: dùng skills `flow-*`; review độc lập trong subagent; không AI trailer.
- Chỗ trống `PROJECT.md` giải thích cách điền.

README sẽ nói: template này là điểm xuất phát, mỗi dự án sửa lại trước khi commit.

## 6. Những gì đã decided (trong hội thoại)

- Full portable kit, không phải lớp bổ sung hay chỉ 4 nhóm.
- Ngôn ngữ: tiếng Anh.
- Kiến trúc: profile-driven 1:1 port (Approach A).
- Output trong `.tmp/flowkit/`, nhánh `feat/portable-skills-kit`.

### Calls sau builder check (call của builder, PO sửa được khi duyệt)

1. **Commit**: kit được commit vào nhánh này (worktree sinh ra cho cải thiện này).
   `.tmp/` là ngoại lệ có chủ đích so với quy root; ghi rõ trong README kit.
   Ritual PR (CHANGELOG/ROADMAP §11/Kanban) chạy khi nào PO yêu cầu mở PR — kit không
   có WP nên không tự tạo WP; đây là call, không phải bước của task này.
2. **Phạm vi anti-goals**: áp cho `skills/**` (đúng chỗ `check-kit.mjs` quét). README
   được phép chứa bảng mapping hiraku→flow (đây là bằng chứng port 1:1), `profiles/`
   dĩ nhiên chứa tên hiraku.
3. **`profiles/hiraku-native.md` full fidelity**: điền đủ 8 section với giá trị thật
   (ROADMAP §11, lệnh Kanban, path ARCHITECTURE/DECISIONS, check Go/Swift, quy ước
   commit/PR) — đây là bằng chứng Approach A hoạt động, không phải sample.
4. **Acceptance**: `node .tmp/flowkit/scripts/check-kit.mjs` exit 0 (frontmatter +
   không `hiraku`/`ROADMAP`/`DECISIONS`/`WP-` trong `skills/**` + không trùng tên +
   `PROJECT.md.example` có đủ section mà skill yêu cầu). Chạy thử live ở repo trung tính
   là bước tay PO làm sau khi duyệt kit, không thuộc proof của task này.

## 7. Còn lại cho builder

- Port 10 skill + copy/adapt 8 PM + viết 2 skill mới + README/example/profile/template
  + check script.
- Thích nghi frontmatter PM (bỏ `argument-hint`, bỏ tham chiếu `CONNECTORS.md`,
  hướng "cung cấp context thủ công nếu không có connector").
- Chạy `check-kit.mjs` tới khi xanh.

## 8. Risks

- **Quy mô**: ~20 skill, trong đó 8 PM mỗi skill 250–400 dòng — phần lớn là copy, nhưng
  review tốn thời gian. Mitigation: PM gần như nguyên bản, chỉ sửa frontmatter + connector.
- **Generalize contract/feature/spike mất sắc bén hiraku**: chấp nhận được vì bản hiraku
  gốc vẫn chạy; bản kit là generic trung tính.
- **`PROJECT.md` chưa có sẵn ở repo dùng thử**: skill dừng và yêu cầu tạo mẫu — hành vi
  cố ý, không đoán.
