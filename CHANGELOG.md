# Changelog — hiraku

Mục `[Unreleased]` là thay đổi sản phẩm, mỗi PR đã duyệt merge phải thêm một dòng (xem `GIT_WORKFLOW.md` §5). Phần còn lại là lịch sử thay đổi của các tài liệu. Tài liệu hiện hành không lặp lại các mục này; đọc khi cần truy vết lý do chuyển từ bản web hoặc từ v1.3.

## [Unreleased]

Nhóm: Thêm · Đổi · Sửa · Xóa · Tài liệu · Bảo mật. Mỗi dòng kết thúc bằng `(WP-xx, PR n)`. Chưa có mã sản phẩm.

### Tài liệu
- Thêm `GIT_WORKFLOW.md`: nhánh `main`/`develop`, vòng đời task, điều kiện merge, cập nhật CHANGELOG và ROADMAP bắt buộc trong mỗi PR.
- Đồng bộ trạng thái ROADMAP §11 và Kanban: TEST_PLAN/AGENTS sang chờ duyệt, S-8 về backlog (chặn Q-11), bỏ ghi chú đã lỗi thời, thêm Q-19…Q-29 vào cổng.

## Bộ OpenCode 2026-10-29

- Quy ước ngôn ngữ: comment, tiêu đề/mô tả PR và template viết bằng tiếng Anh (ARCHITECTURE C6, AGENTS, OPENCODE); thêm `.github/pull_request_template.md`; `task.md` chuyển sang tiếng Anh.
- Thêm ADR-31: bốn agents; AI tự merge sau Review độc lập và CI đạt, PO duyệt gate/phát hành. Q-29 xác nhận phần AI coding, giữ mở phần dự phòng/người thử.
- Thêm cấu hình OpenCode 2.2.0, guard v2 và tests; chỉ hai skills `hiraku-contract`, `hiraku-feature`, không tạo skills lặp trách nhiệm agent.
- Thêm `OPENCODE.md`, mẫu task, `TEST_PLAN.md` và `RELEASE.md`; đóng quyền delivery khi chưa có Git/remote/CI, không coi checklist là bằng chứng đã đạt.
- Cập nhật AGENTS/ROADMAP theo mô hình AI; sửa mẫu Package.swift để khai báo package HirakuTesting mà test target đang dùng.
- Không tự chốt nghiệp vụ xóa, Q-25 hoặc phạm vi CloudKit MR/M4; ghi blocker rõ trong quy trình.

## Đợt rà soát 2026-10-29

Phiên bản mới: `spec.md` 3.11, `use-cases.md` 3.9, `ARCHITECTURE.md` 2.2, `ROADMAP.md` 1.9, `DECISIONS.md` 1.10, `DESIGN.md` 0.5.4, `COPY.md` 1.6.

- **Sửa mâu thuẫn**: S-2 là FSRS Go (ROADMAP); S-5 thêm vào M0 và tham chiếu đúng UC-08 E6; `card_id` thay `word_id` trong ARCHITECTURE; bỏ "GRDB" và "Persistence"; UUIDv7 tự cài; bản đồ M0b/M1a/M1b trong spec §1.3; spec §3.3 spike ≈ 3 tuần; Q-8 chỉ ở GATE-3, Q-6 bỏ khỏi GATE-3.
- **Thuật ngữ**: "Câu ví dụ" là tên trường, "trường" thay "field" ở giao diện; Trang chủ hiện ProfileBadge khi có từ 2 profile.
- **Hành vi**: nút "Kiểm tra" = Return (UC-07); M1a chỉ có hai tab; hoàn tác chấm điểm không tính vào hạn mức (UC-17); UC-17 là P1 nhưng thuộc M1b.
- **Lịch**: thêm S-5 và Spike 0 vào M0; ghi chênh 0,5 tuần ở M1a và Tết 2027; thêm thiết kế M2 và kế hoạch thử người dùng.
- **Chưa quyết, chuyển thành câu hỏi mở**: Q-19…Q-29 trong `DECISIONS.md`.

## Phiên bản tài liệu

**Lịch sử**: v3.10 — chốt chính sách đồng bộ iCloud (ADR-29, ADR-30): FR-092, FR-093, NFR-001/NFR-007 (ngoại lệ khi bật), R-14…R-21; v3.9 — yêu cầu bật/tắt đồng bộ iCloud (ADR-29): FR-070 cập nhật, FR-092, FR-093; giữ đồng bộ ở M4; v3.8 — field tùy biến theo deck (ADR-27): kiểu ghi chú, `notes`/`cards` thay `words`, FR-086…FR-089, backup v3 (vẫn nhận v2), R-13; một DB mỗi profile (ADR-28): FR-090, FR-091; đóng Q-16, Q-17, Q-18; v3.7 — chuyển logic nghiệp vụ, FSRS, kana, lưu trữ và contract sang Go core (ADR-20…26); thêm S-8, NFR-011/012, SC-013, R-09…R-12; v3.6 — chốt Q-15 và Q-D3 (ADR-19): hoàn tác chấm điểm vào M1b, xúc giác tối thiểu; v3.5 — rà soát hành vi người dùng (ADR-18): kéo-thả sắp xếp, hoàn tác chung, bảo vệ thay đổi chưa lưu, khôi phục vị trí, thêm từ nhanh, sắp xếp/lọc, sidebar dạng cây, `decks.position`, FR-075…FR-085, UC-30; v3.4 — đăng ký Apple Developer Program sau cùng, việc liên quan đánh dấu [Cuối cùng] (ADR-17, mốc MR); v3.3 — chrome Liquid Glass gốc (ADR-15: tab bar, sidebar, toolbar, inspector), menu "Học" ở toolbar deck, luật L11; v3.2 — gỡ phần trùng lặp (kiến trúc → `ARCHITECTURE.md`, giá trị thiết kế → `DESIGN.md`, trạng thái quyết định → `DECISIONS.md`); v3.1 — thêm FR-025, FR-026, S-7, Q-10…Q-14, chốt Q-1 (OS 26), quy tắc §7.3.6 và `Scheduler.preview`.

**Phiên bản**: 3.8 (UC-27 chốt: gộp theo field, khi tắt giữ dữ liệu iCloud — ADR-29, ADR-30; đồng bộ `spec.md` v3.10, `DESIGN.md` v0.5.3) · 3.7 (cập nhật UC-27: bật/tắt đồng bộ iCloud — ADR-29, FR-092, FR-093; đồng bộ `spec.md` v3.9, `DESIGN.md` v0.5.2) · 3.6 (thêm UC-31 field tùy biến — ADR-27, UC-32 profile — ADR-28; đồng bộ `spec.md` v3.8, `DESIGN.md` v0.5.1, `ARCHITECTURE.md` v2.1) · 3.5 (chuyển từ v2.0 web; đồng bộ với `spec.md` v3.6, `DESIGN.md` v0.3.0 và `ARCHITECTURE.md` v1.1)

**Phiên bản**: 2.1 (thêm `domain/notetype` và field tùy biến — ADR-27; đường dẫn DB theo profile — Q-16) · 2.0 (logic và dữ liệu chuyển sang Go core — ADR-20…26; thay thế v1.3, giữ MVC cho Swift — ADR-02; chrome Liquid Glass — ADR-15; phong cách mã C1–C8 — ADR-16)

## spec.md — chuyển web → native

### 1.5 Review `spec.md` v2 → thay đổi khi chuyển native

Mã **FR/NFR/SC/UC giữ nguyên** để `use-cases.md` vẫn tra cứu được; chỉ đổi nội dung nơi cần.

| Hạng mục (v2 web) | Quyết định v3 | Lý do |
|---|---|---|
| TanStack Start/Router/DB/Store/Table/Virtual/Form/Pacer/Hotkeys/Charts | **Bỏ**; thay bằng SwiftUI + `Observation` + Swift Charts + `Commands`/`keyboardShortcut` | Có sẵn first-party, loại bỏ rủi ro alpha/beta (R-02 v2) |
| shadcn/Radix/Tailwind/lucide | **Bỏ**; `DesignSystem` package tự xây, icon = **SF Symbols** | Đồng bộ nền tảng; SF Symbols có biến thể `.fill` đúng yêu cầu `DESIGN.md` |
| SQLite-WASM/OPFS | **SQLite qua `modernc.org/sqlite` trong Go core** (ADR-23) | Cùng engine, cùng schema; bỏ rủi ro WASM/OPFS (S-1, R-03 v2). Cập nhật v3.7: không dùng GRDB (ADR-03 đã thay thế) |
| `ts-fsrs` | Thư viện FSRS Go hoặc tự cài trong `core/domain/fsrs` (ADR-26) | Thuật toán công khai, cô lập sau interface |
| Service worker, PWA, `storage.persist()`, đa tab (UC-21) | **Bỏ**; thay bằng đa cửa sổ + bảo vệ dữ liệu + nhắc sao lưu | Không còn rủi ro trình duyệt xóa dữ liệu |
| Web Worker cho nhập/xuất | Go core xử lý theo lô; Swift giữ tiến trình và hủy (ADR-21) | Tương đương |
| Phản chiếu `font_scale` vào `localStorage` | **Bỏ**; Dynamic Type + `font_scale` | Không còn first-paint flash |
| Excel (`xlsx`) | Dời xuống **P2** (cần thư viện bên thứ ba) | Giảm phụ thuộc |
| Deploy Vercel | CI cục bộ khi develop; TestFlight + App Store sau khi đăng ký Apple Developer Program (ADR-17, [Cuối cùng]) | |
| M4 Mobile (Expo) | **Xóa** — mobile là một phần của M1 | |

---

## use-cases.md — chuyển web → native

### Đánh giá bản v2 (web)

### 2.1 Giữ nguyên

Nghiệp vụ không phụ thuộc nền tảng nên giữ nguyên: cấu trúc mỗi UC, hạn mức từ mới tính từ `review_logs` (UC-08), thẻ Again quay lại hàng đợi, Gõ từ hiện đáp án đúng, khôi phục idempotent (UC-11), nhập liệu atomic, xóa mềm có xác nhận, danh mục UC-01…UC-27 và thứ tự ưu tiên P0.

### 2.2 Thay đổi khi chuyển native

| # | Nội dung ở v2 (web) | Xử lý ở v3 |
|---|---|---|
| 1 | Nêu tên thư viện web trong kịch bản (TanStack Form/Pacer/Hotkeys/Charts, Web Worker, Playwright) | Loại bỏ; chỉ mô tả hành vi quan sát được |
| 2 | Điều hướng bằng URL (`/folders/$folderId`, `/study/...`) | Dùng `Route` và shell theo nền tảng (§4.0) |
| 3 | Hộp thoại web, Enter/Esc | Sheet; **[Mac]** Return = Lưu, Esc = Hủy |
| 4 | Phím `/` để tìm kiếm | Ô tìm kiếm hệ thống; ⌘F **[iPad/Mac]** |
| 5 | IME dựa vào `compositionstart/end`, `isComposing` | Dựa vào *marked text* của iOS/iPadOS/macOS (UC-07) |
| 6 | UC-21 xoay quanh `storage.persist()`, service worker, PWA, nhiều tab, trình duyệt không hỗ trợ OPFS | Viết lại thành **Bảo vệ dữ liệu, đa cửa sổ & vòng đời ứng dụng**; bỏ các mục chỉ có ở web |
| 7 | UC-13 phản chiếu cỡ chữ vào `localStorage` | Bỏ; dùng Dynamic Type **[iPhone/iPad]** và `font_scale` |
| 8 | "Chuyển sang tab khác giữa thẻ" (UC-08 E5) | "Ứng dụng vào nền / cửa sổ mất focus" |
| 9 | Nhập: kéo-thả trình duyệt, Excel mặc định | Bộ chọn tệp hệ thống, kéo-thả **[iPad/Mac]**, dán từ clipboard; Excel xuống P2 |
| 10 | Xuất/sao lưu: tải file trình duyệt | `fileExporter` / `ShareLink` (Lưu vào Tệp, AirDrop…) |
| 11 | Phím tắt toàn cục (`g h`, `g s`, `n`), palette lệnh P2 | Thanh menu **[Mac]**, phím tắt bàn phím phần cứng **[iPad]**; palette lệnh bỏ khỏi phạm vi |
| 12 | Thiếu: nhắc ôn, widget, đa cửa sổ, menu hệ thống | Thêm UC-28, UC-29, UC-21 (đa cửa sổ), §4.0 |
| 13 | Mốc M4 Mobile (Expo) và M5 mở rộng | Bỏ M4 Mobile; mở rộng chuyển thành M4 (spec §1.3) |
| 14 | §2.2 v2 ghi ma trận UC→FR ở "§6" trong khi ma trận nằm ở §7 | Sửa tham chiếu; ma trận ở §7 tài liệu này |

### 2.3 Khoảng trống truy vết đã đóng (v3.1)

| # | Điểm | Cách đóng |
|---|---|---|
| G-1 | "Tôi đúng" (UC-07 A1) và khoảng ôn dự kiến (UC-06 A2) chưa có FR | Thêm **FR-025** và **FR-026** vào spec §6.2 (P1); `Scheduler.preview` ở spec §7.1 |
| G-2 | Trần `elapsed_ms` 60 giây (UC-08 E5) chưa có quy tắc | Thêm quy tắc **spec §7.3.6** |
| G-3 | Widget (UC-29) cần App Group, spec chưa nêu vị trí DB | Thêm **Q-10** và đề xuất ở spec §3.1: đặt DB trong App Group từ M1 — **đã chốt** (xác minh ở S-7) |

---

## DESIGN.md — chuyển web → native

### Review `DESIGN.md` → thay đổi khi chuyển native

| # | Ở bản web | Quyết định native | Lý do |
|---|---|---|---|
| 1 | Đơn vị `px`/`rem` | `pt`; cỡ chữ có 3 mức phone / pad / mac | Phù hợp mật độ điểm ảnh và khoảng nhìn từng thiết bị |
| 2 | `label-caps` 9px, `eyebrow` 10px, `body-sm` 11px, `button` 12px | Nâng: label-caps 11pt, eyebrow 11–12pt, body-sm 13pt (iOS), button 15pt (iOS) | Dưới 11pt khó đọc; nút cần mục tiêu chạm ≥ 44pt |
| 3 | Chữ Ember trên nền giấy | Giới hạn theo bảng tương phản (§Colors) | Ember trên `neutral` chỉ đạt 2,93:1 |
| 4 | `faint` dùng cho chữ phụ | Chỉ dùng trang trí/disabled; trên nền mực dùng `faint` thay `secondary` | `faint` 2,41–2,68:1 trên nền sáng; `secondary` trên mực chỉ 3,21:1 |
| 5 | Quy tắc "Ember cho ký tự gõ đúng" mâu thuẫn với `kana-cell-filled` xanh và UC-07 | Đúng = xanh + dấu tích; sai = Ember + dấu ✕ | Một quy tắc nhất quán, không chỉ dựa vào màu |
| 6 | Ember "không trang trí" nhưng wordmark và cách đọc mặt sau dùng Ember | Liệt kê tường minh các chỗ được dùng Ember (§Colors) | Bỏ mâu thuẫn |
| 7 | Khung điện thoại (`xl` 30px, bóng 24/60) | **Bỏ** `xl` và hai bóng khung | Là mockup web, thiết bị thật tự có khung |
| 8 | Icon Ionicons / lucide | **SF Symbols** (outline/`.fill`) | Gốc nền tảng, có sẵn biến thể filled |
| 9 | Bóng CSS `spread` âm | Xấp xỉ bằng `shadow(radius:y:)` | SwiftUI không có `spread` |
| 10 | `input-search` dạng pill tự vẽ | Dùng `.searchable` hệ thống | Tích hợp toolbar, IME, VoiceOver |
| 11 | Sidebar 232px, rail 230px, tab bar | Giữ 232pt (sidebar kính nổi) và 230pt (inspector); tab bar gốc; thích ứng theo size class (§Layout) | Cùng bố cục, chuyển đúng nền tảng |
| 12 | Không nêu trạng thái hover/pressed/focus/disabled, motion, a11y | Bổ sung (§Components, §Motion, §Accessibility) | Bắt buộc trên native |
| 13 | Dark mode: cấm nền tối toàn app | Giữ: **khóa giao diện sáng** ở MVP (Q-2 spec) | Chưa có bộ token tối được thiết kế |
| 14 | Sidebar nền mực, header bảng nền mực, tab bar tự vẽ | Dùng chrome gốc **Liquid Glass**: tab bar, sidebar nổi, toolbar, sheet, inspector; không tùy biến kiểu dáng (ADR-15) | Đúng nền tảng iOS/macOS 26, giữ hành vi gốc (kéo, thu gọn, VoiceOver, bàn phím) |

## ARCHITECTURE.md — v1.3 → v2.0

### Thay đổi so với v1.3

| # | v1.3 | v2.0 | Lý do |
|---|---|---|---|
| 1 | Persistence (GRDB) và nghiệp vụ bằng Swift | Go core: `domain`, `store`, `service`, `ffi` | ADR-20 |
| 2 | `HirakuCore` là module Swift nghiệp vụ | `HirakuModels` (struct và protocol); nghiệp vụ ở Go | ADR-20 |
| 3 | `ValueObservation` cập nhật UI | `ChangeSet` → `EventHub` → tải lại theo phạm vi | ADR-24 |
| 4 | Ghi nhiều bảng trong `TransactionRunner` Swift | Một RPC; transaction trong `store` | ADR-20, L5 |
| 5 | Không có contract | protobuf `hiraku.v1` có buf | ADR-22 |
| 6 | FSRS và Kana bằng Swift | Go (`domain/fsrs`, `domain/kana`) | ADR-20, ADR-26 |
| 7 | `HirakuTesting` chứa InMemory repository | `HirakuTesting` là fake Swift cho Controller; contract và golden ở Go | ADR-14 (sửa), ADR-20 |
| 8 | Luật L1–L11 | Giữ L1–L11 (cập nhật L4, L5, L6, L7, L9, L10); thêm G1–G8 | ADR-20 |
| 9 | Điểm mở rộng và C1–C8 cho Swift | C1–C8 áp dụng cho cả Go và Swift | ADR-16 |
| 10 | Kiểm thử Swift | Thêm Go và golden contract; CI có `buf` và `check-core.sh` | ADR-20, ADR-22 |
