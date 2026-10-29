# Tài liệu Đặc tả — hiraku (開く) · Native Swift

**Ngày**: 2026-10-29
**Phiên bản tài liệu**: 3.11
**Trạng thái**: Đã chốt: logic và dữ liệu ở Go core (ADR-20…26), kiến trúc Swift (ADR-02), OS 26 (ADR-13), chrome Liquid Glass gốc (ADR-15); điểm còn mở ở §13
**Tài liệu liên quan**: `DESIGN.md` (hệ thống thiết kế Editorial Ember — nguồn sự thật cho giá trị token), `use-cases.md` (mã UC; mã FR giữ nguyên theo bản web, xem `CHANGELOG.md`), `ARCHITECTURE.md` v2.2 (luật kiến trúc có hiệu lực), `DECISIONS.md`, `ROADMAP.md`
**Lịch sử thay đổi**: `CHANGELOG.md`.

---

## 1. Tổng quan

### 1.1 Giới thiệu

**hiraku** là ứng dụng học từ vựng tiếng Nhật (giao diện tiếng Việt), **local-first**, chạy **offline mặc định**, không tài khoản riêng; đồng bộ iCloud là tùy chọn, mặc định tắt (M4, ADR-29), dùng thuật toán ôn tập ngắt quãng **FSRS**.

Hướng đi v3: **bỏ web và Expo, chuyển hoàn toàn sang ứng dụng native viết bằng Swift** cho **iOS, iPadOS, macOS** từ một codebase SwiftUI đa nền tảng. Toàn bộ logic nghiệp vụ và lưu trữ nằm trong **Go core** (`core/`), có contract protobuf và không phụ thuộc nền tảng, để tái sử dụng cho nền tảng khác (ADR-20). Swift giữ UI, tổ chức theo **MVC + SOLID**, mỗi tính năng là một module độc lập; Swift là lớp giao diện và tích hợp hệ điều hành.

### 1.2 Mục tiêu

- Tổ chức từ vựng theo **Thư mục → Deck → Từ**; mỗi deck có một **kiểu ghi chú** với field tùy biến (ADR-27).
- Học bằng 2 chế độ: **Flashcard** và **Gõ từ** (chuẩn hóa kana/romaji, hỗ trợ IME của hệ điều hành).
- Ôn tập theo lịch FSRS, cấu hình được.
- Dữ liệu thuộc về người dùng: lưu cục bộ, sao lưu/xuất được, không khóa vào dịch vụ.
- Trải nghiệm đúng chuẩn từng nền tảng (điều hướng, phím tắt, menu, cửa sổ) nhưng chung một hệ thiết kế (`DESIGN.md`).
- Kiến trúc modular: thêm/bớt/thay một tính năng không phải sửa tính năng khác.

### 1.3 Phạm vi theo giai đoạn

| Giai đoạn | Nội dung | Ưu tiên |
|---|---|---|
| **M0 — Spike** | Xác nhận khả thi (§3.3): SQLite (modernc) + FSRS Go, build XCFramework (S-8), hiệu năng 50k từ, IME gõ từ trên 3 nền tảng, layout thích ứng | Bắt buộc trước M1 |
| **M0b — Chuẩn bị** | Kiến trúc, wireframe, COPY, TEST_PLAN, AGENTS (`ROADMAP.md` §3.2) | Bắt buộc trước M1 |
| **M1 — MVP** (M1a iPhone, M1b iPad/Mac — Q-12) | Thư mục, deck, danh sách từ; FSRS; Flashcard; Gõ từ; Cài đặt; schema field tùy biến với kiểu "Từ vựng Nhật" (ADR-27 Pha A) | **P0** |
| **M2 — Dữ liệu** | Sao lưu/khôi phục, xuất, nhập CSV/JSON/dán văn bản; nhập/xuất theo field | P1 |
| **M3 — Hoàn thiện** | Thống kê (Swift Charts), hoàn tác, thao tác hàng loạt, phím tắt, dữ liệu mẫu, nhắc ôn hằng ngày; quản lý kiểu ghi chú và field (ADR-27 Pha B); quản lý profile (ADR-28) | P1 |
| **MR — Phát hành [Cuối cùng]** | Đăng ký Apple Developer Program, ký chính thức, TestFlight, App Store (ADR-17); chỉ bắt đầu khi PO nghiệm thu bản develop | Sau M3 |
| **M4 — Tích hợp hệ thống** | Widget, TTS, tags, ôn tập tùy chỉnh, streak; iCloud sync (tùy chọn, bật/tắt — ADR-29) | P2/P3 |

> Chỉ M0 → M1 là cam kết cứng. M2 nên làm ngay sau M1 và **trước khi phát hành**: xóa app là mất dữ liệu nếu người dùng không có sao lưu thiết bị/iCloud (R-01).

### 1.4 Nền tảng

| Nền tảng | Hình thức | Điều hướng |
|---|---|---|
| iOS (iPhone) | Ứng dụng | Tab bar Liquid Glass gốc (Trang chủ / Thống kê / Cài đặt (M1a: chỉ Trang chủ và Cài đặt, Thống kê thêm ở M3)) |
| iPadOS | Ứng dụng (cùng target với iOS), multi-window | Sidebar kính nổi + nội dung (`NavigationSplitView`), hỗ trợ bàn phím phần cứng |
| macOS | Ứng dụng native (App Sandbox), multi-window | Sidebar kính nổi cố định, thanh menu, phím tắt hệ thống |

- Một **target SwiftUI đa nền tảng**; chỉ tách mã theo nền tảng khi bắt buộc (`#if os(macOS)`), và chỉ trong lớp View/Platform.
- Tối thiểu hệ điều hành (Q-1, đã chốt): **iOS 26, iPadOS 26, macOS 26 — macOS chỉ trên Apple silicon**. Swift 6, bật strict concurrency. Hệ quả: một diện mạo hệ thống duy nhất (chrome kính của OS 26), không cần xử lý OS cũ.
- **Không còn**: web/PWA, Android. Bản web `spec.md` giữ làm tham chiếu; hai bên trao đổi dữ liệu qua file sao lưu (§7.6).

### 1.5 Mã và thay đổi so với bản web

Mã FR/NFR/SC/UC giữ nguyên từ bản web để `use-cases.md` vẫn tra cứu được. Chi tiết thay đổi: `CHANGELOG.md`.

---

## 2. Tech stack & nguyên tắc phụ thuộc

### 2.1 Stack

| Concern | Lựa chọn | Ghi chú |
|---|---|---|
| Ngôn ngữ core | **Go** (phiên bản pin trong `core/go.mod`) | Nghiệp vụ, dữ liệu, FSRS, kana, contract (ADR-20) |
| Ngôn ngữ UI | **Swift 6** | Strict concurrency; `Sendable` cho model và Repository |
| UI | **SwiftUI** | `NavigationSplitView`, `TabView`, `Table` (macOS/iPad), `List` (iPhone) |
| State / binding | **Observation** (`@Observable`) | Controller là `@MainActor @Observable` |
| Lưu trữ | **SQLite qua `modernc.org/sqlite`** (WAL, Go core) | Swift không mở DB; làm mới qua `ChangeSet`/`EventHub` (ADR-23, ADR-24) |
| Contract | **protobuf `hiraku.v1`**, buf | Nguồn duy nhất cho Swift và Go (ADR-22) |
| FFI | cgo, c-archive, XCFramework | ABI bốn hàm `hk_*` (ADR-21) |
| Lập lịch | FSRS Go (xác minh ở S-2) hoặc cài trong `core/domain/fsrs` | Hàm thuần (ADR-26) |
| Biểu đồ | **Swift Charts** | First-party |
| Icon | **SF Symbols** | Ánh xạ ở §9.3 |
| Phím tắt | `keyboardShortcut`, `Commands` | Menu bar trên macOS, bảng phím giữ ⌘ trên iPad |
| Tệp | `fileImporter`/`fileExporter`/`ShareLink`, `UTType` riêng cho backup | |
| Thông báo | `UserNotifications` (cục bộ) | P1 |
| TTS | `AVSpeechSynthesizer` (`ja-JP`) | P2 |
| Kiểm thử | **`go test`** (core, golden), **Swift Testing** (Swift), **XCUITest** (e2e) | |
| Quản lý gói | **Swift Package Manager** (local packages), **Go modules** | Mỗi feature là một package; `core/` là một Go module |
| Font | Noto Sans JP (đóng gói, subset), Georgia, Helvetica Neue | Georgia/Helvetica Neue có sẵn trên Apple; fallback Hiragino Sans (§9.2) |

Phụ thuộc bên thứ ba: `modernc.org/sqlite`, `google.golang.org/protobuf`, `swift-protobuf`, công cụ buf, và thư viện FSRS Go nếu đạt S-2 (ADR-21…23, 26). Mọi phụ thuộc phải có ADR; lưu trữ và FSRS nằm sau interface để thay được.

### 2.2 Kiến trúc MVC + SOLID

Yêu cầu kiến trúc (ADR-02):
- Mỗi feature có đủ Model/View/Controller, tách thư mục. View thụ động; Controller (`@MainActor @Observable`) điều phối Model qua **protocol**, không singleton.
- Feature độc lập: chỉ phụ thuộc `HirakuModels`, `DesignSystem` (và `StudyKit` với feature học), **không import feature khác**; ghép nối bằng `Route`, closure điều hướng và slot `@ViewBuilder`; chế độ học là plugin.
- Áp dụng SOLID. Logic nghiệp vụ và lưu trữ thuộc Go core (ADR-20). Swift giữ MVC cho UI; luật L1–L11 (Swift) và G1–G8 (Go) nằm ở `ARCHITECTURE.md` v2.2 §4, §14.

### 2.3 Cấu trúc thư mục

Cấu trúc workspace, khuôn mẫu một feature và quy ước đặt tên: `ARCHITECTURE.md` §3. Mỗi feature là một Swift Package/target độc lập (danh sách ở §2.4).

### 2.4 Bản đồ feature ↔ use case

| Feature | UC | Phụ thuộc | Ưu tiên |
|---|---|---|---|
| FeatureHome | UC-15 (P2), banner (FR-050) | Core, DesignSystem | P0 |
| FeatureFolders | UC-01 | Core, DesignSystem | P0 |
| FeatureDecks | UC-02, UC-31 (M3) | Core, DesignSystem | P0 |
| FeatureWords | UC-03, UC-04, UC-18, UC-24, UC-30 | Core, DesignSystem | P0 (P1/P2 phần mở rộng) |
| FeatureStudy | UC-08, UC-17, UC-19, UC-22 | Core, StudyKit, DesignSystem | P0 |
| FeatureFlashcard | UC-06 | StudyKit, DesignSystem | P0 |
| FeatureTyping | UC-07 | StudyKit, Core (`Kana`), DesignSystem | P0 |
| FeatureSettings | UC-13, UC-14, UC-20 (bảng phím), UC-32 (M3, cùng App shell) | Core, DesignSystem | P0 |
| FeatureDataTransfer | UC-05, UC-09, UC-10, UC-11, UC-21 (UI) | Core, DesignSystem | P1 |
| FeatureStats | UC-12, UC-26 | Core, DesignSystem | P1 |
| FeatureOnboarding | UC-16 | Core, DesignSystem | P1 |

---

## 3. Mô hình lưu trữ

### 3.1 Quyết định

**SQLite cục bộ qua `modernc.org/sqlite` (Go core, chế độ WAL), do Go sở hữu** (ADR-20, ADR-23). File DB nằm trong vùng lưu trữ của app (macOS: trong container sandbox), được thiết bị/iCloud backup mặc định. **Quyết định (Q-10, đã chốt 2026-10-28)**: đặt DB trong container dùng chung qua **App Group** ngay từ M1, để widget (FR-073) đọc cùng DB mà không phải di chuyển dữ liệu về sau. Cần entitlement App Group trên cả iOS/iPadOS và macOS; cấu hình và việc sao lưu thiết bị/iCloud được xác minh ở S-7. **Mỗi profile một DB** (ADR-28): `profiles/<profile_id>/hiraku.sqlite`; profile dùng để tách ngôn ngữ học và giữ mỗi DB nhỏ, độc lập; hàng đợi, hạn mức, thống kê, settings và sao lưu tính theo profile. Với Personal Team (ADR-17), nếu App Group không dùng được thì dev dùng container thường và chuyển sang App Group khi đăng ký tài khoản.

Lý do: truy vấn FSRS (đến hạn, đếm theo trạng thái, join) tự nhiên bằng SQL; 50.000 từ không cần nạp hết vào RAM; schema tổng quát theo kiểu ghi chú (ADR-27), backup v2 của bản web vẫn nhập được qua ánh xạ sang kiểu hệ thống; `ChangeSet` và `EventHub` thay `ValueObservation` (ADR-24).

Đã cân nhắc **SwiftData** (first-party, tích hợp CloudKit) nhưng không chọn: truy vấn phức tạp/hiệu năng với dữ liệu lớn kém kiểm soát hơn, ràng buộc của CloudKit (mọi thuộc tính tùy chọn, không unique) làm lệch schema. Quyết định GRDB ban đầu (ADR-03) đã thay thế; xem lại nếu S-1 hoặc S-8 thất bại (`DECISIONS.md` §5).

Hai quyết định giữ để không bị khóa khi thêm đồng bộ:
1. **ID = UUIDv7 (TEXT)**, tự cài `UUIDv7` trong `core/domain` (thư viện chuẩn không có UUIDv7).
2. Mọi bảng có `created_at`, `updated_at`, `deleted_at` (xóa mềm).

### 3.2 Hệ quả kiến trúc

Swift chỉ thấy protocol Repository (adapter gọi core); mọi ghi nhiều bảng là một RPC trong core; Swift không mở DB. Chi tiết: `ARCHITECTURE.md` §6–§7.

### 3.3 Việc cần kiểm chứng ở M0 (spike ≈ 3 tuần, `ROADMAP.md` §3.1)

| # | Câu hỏi | Tiêu chí đạt |
|---|---|---|
| S-0 | `modernc.org/sqlite` build được cho ios/arm64 và simulator; `go list -deps` không có `net` (luật G5) | Build xanh cho 3 slice; không có `net`; nếu không đạt → `mattn/go-sqlite3` (ADR-23) |
| S-1 | Hiệu năng modernc.org/sqlite (Go core) với 50.000 từ + 200.000 `review_logs` trên iPhone cũ nhất bạn có hỗ trợ iOS 26 (từ iPhone 11 trở lên) | Dựng hàng đợi < 200 ms; tìm kiếm < 150 ms; cuộn 60 fps — đo trên schema `notes`/`cards`, tìm kiếm qua `search_text` (ADR-27) |
| S-2 | Thư viện FSRS Go hiện có: đúng thuật toán, bước học ngắn, bảo trì | Khớp bảng kỳ vọng §7.1; nếu không đạt → tự cài trong `core/domain/fsrs` (ADR-26) |
| S-3 | IME gõ từ: nhận biết trạng thái *composing* (marked text) trong ô nhập của SwiftUI trên iOS, iPadOS, macOS | Không chấm giữa chừng; Enter chốt IME không bị tính là nộp (bọc `UIViewRepresentable`/`NSViewRepresentable` nếu cần) |
| S-4 | Layout thích ứng: `Table` đa cột macOS/iPad, `List` iPhone, `NavigationSplitView`, inspector 230pt, phụ kiện đáy tab bar (ADR-15) | Một Controller dùng chung, khác biệt chỉ ở View |
| S-5 | Hai cửa sổ (macOS/iPad) cùng ghi vào một DB | Không hỏng/mất dữ liệu; chấm trùng thẻ được xử lý (UC-08 E6, UC-21) |
| S-6 | Đóng gói Noto Sans JP (subset) | Kích thước app hợp lý; hiển thị đúng; có fallback Hiragino Sans |
| S-7 | App Group (Q-10): DB nằm trong container dùng chung mở được trên iOS, iPadOS, macOS (App Sandbox); một target phụ (giả lập widget) đọc được cùng DB; dữ liệu trong container có nằm trong sao lưu thiết bị/iCloud | Đọc/ghi từ hai target không hỏng; sao lưu/khôi phục thiết bị giữ nguyên dữ liệu; nếu không đạt → ghi lại và xem lại Q-10. Với Personal Team: xác minh phần khả dụng, phần còn lại ở MR (ADR-17) |
| S-8 | Build `core/ffi` thành c-archive cho ba slice (iOS device arm64, iOS simulator arm64, macOS arm64); đóng XCFramework tự động; chạy trên simulator và thiết bị thật; đo RSS và thời gian khởi động của Go runtime; 1.000 lần gọi `hk_call` không rò bộ nhớ | Build xanh trên CI; không rò; khởi động < 300 ms trên thiết bị chuẩn (ngưỡng đề xuất, PO xác nhận); nếu trượt → ADR-03 (xem `DECISIONS.md` §5) |

---

## 4. Mô hình dữ liệu

SQLite, cột `snake_case`. Mọi bảng có thêm `created_at`, `updated_at`, `deleted_at` (nullable) trừ khi ghi chú. **Thời gian lưu dạng epoch milliseconds (INTEGER)** trong DB; chuyển ISO-8601 UTC chỉ ở biên sao lưu/xuất (§7.6). Entity Swift dùng `Date`, ID dùng kiểu bọc (`FolderID`, `DeckID`, `WordID`) để tránh nhầm lẫn.

### 4.1 `folders`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUIDv7 |
| `name` | TEXT | bắt buộc, 1–100 ký tự sau trim |
| `position` | INTEGER | gán lại 1..n khi đổi chỗ |

### 4.2 `decks`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | |
| `folder_id` | TEXT FK → folders | xóa thư mục ⇒ xóa mềm cả deck con |
| `note_type_id` | TEXT FK → note_types | **(mới, ADR-27)** gán khi tạo; mặc định kiểu hệ thống; không đổi khi deck đã có từ |
| `name` | TEXT | bắt buộc, 1–100 |
| `description` | TEXT nullable | |
| `position` | INTEGER | thứ tự trong thư mục; gán lại 1..n khi đổi chỗ; deck mới ở cuối |

### 4.3 Kiểu ghi chú (ADR-27)

**`note_types`**

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | kiểu hệ thống dùng ID cố định |
| `name` | TEXT | bắt buộc, 1–100, duy nhất |
| `is_system` | BOOLEAN | 1 = "Từ vựng Nhật", không sửa trực tiếp; tùy biến bằng nhân bản |

**`note_type_fields`**

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | khóa của giá trị trong `notes.fields` |
| `note_type_id` | TEXT FK | |
| `ord` | INTEGER | thứ tự hiển thị trong form và bảng |
| `name` | TEXT | 1–40 ký tự, duy nhất trong kiểu |
| `role` | TEXT | `term` \| `reading` \| `meaning` \| `example` \| `text`; đúng một `term`, tối đa một mỗi role khác trừ `text` |
| `input_kind` | TEXT | `text` \| `kana` (ô nhập bọc IME, chuẩn hóa §7.2) |
| `required` | BOOLEAN | field `term` luôn bắt buộc |
| `searchable` | BOOLEAN | đưa vào `search_text` |

Tối đa 10 field mỗi kiểu (giá trị đề xuất, xác nhận ở M0b).

**`card_templates`**

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | |
| `note_type_id` | TEXT FK | M1–M3: đúng một mẫu mỗi kiểu |
| `front_fields` | TEXT (JSON mảng `field_id`) | ít nhất một field |
| `back_fields` | TEXT (JSON mảng `field_id`) | |
| `typing_answer_field_id` | TEXT nullable | rỗng ⇒ ẩn chế độ Gõ từ cho deck dùng kiểu này |

Kiểu hệ thống "Từ vựng Nhật": Từ (`term`, bắt buộc) · Cách đọc (`reading`, `kana`) · Nghĩa (`meaning`, bắt buộc) · Câu ví dụ (`example`). Mẫu: mặt trước = Từ; mặt sau = Cách đọc, Nghĩa, Câu ví dụ; đáp án Gõ từ = Cách đọc, rỗng thì dùng Từ (FR-004).

### 4.4 `notes` (thay `words`)

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | khôi phục backup v2 giữ nguyên `words.id` |
| `deck_id` | TEXT FK → decks | |
| `note_type_id` | TEXT FK | bằng `decks.note_type_id`; lưu để truy vấn và khôi phục |
| `fields` | TEXT (JSON) | `{ field_id: giá trị }`; giá trị đã trim; field bị xóa mềm vẫn giữ giá trị |
| `sort_field` | TEXT | giá trị field `term`; dùng sắp xếp và kiểm tra trùng (FR-005) |
| `search_text` | TEXT | ghép field `searchable` đã chuẩn hóa (lowercase, kana chuẩn tắc); core tính khi ghi |

Chỉ mục: `(deck_id)`, `(deck_id, sort_field)`. Tìm kiếm: so khớp chuỗi con trên `search_text` (FR-013); nếu S-1 không đạt, thêm FTS5 (`DECISIONS.md` §5).

### 4.5 `cards`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | khôi phục v2: bằng `notes.id` |
| `note_id` | TEXT FK → notes | |
| `template_id` | TEXT FK → card_templates | |

Unique `(note_id, template_id)`. M1–M3 mỗi note có đúng một thẻ, tạo cùng transaction với note.

### 4.6 `card_states` — trạng thái FSRS (1–1 với thẻ)

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK, FK → cards | *(đổi từ `word_id`, ADR-27)* |
| `state` | INTEGER | 0 New, 1 Learning, 2 Review, 3 Relearning |
| `due` | INTEGER | epoch ms |
| `stability`, `difficulty` | REAL | |
| `elapsed_days`, `scheduled_days` | INTEGER | |
| `learning_steps` | INTEGER | |
| `reps`, `lapses` | INTEGER | |
| `last_review` | INTEGER nullable | |
| `suspended` | BOOLEAN default 0 | P2 |

Thẻ chưa có dòng `card_states` = **Mới**. "Đã biết" suy ra từ `state == 2` (không lưu cột `learned`). Chỉ mục: `(due)`, `(state)`.

### 4.7 `review_logs`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUIDv7 (khôi phục idempotent) |
| `card_id` | TEXT FK → cards | *(đổi từ `word_id`, ADR-27)* |
| `rating` | INTEGER | 1 Again, 2 Hard, 3 Good, 4 Easy |
| `reviewed_at` | INTEGER | epoch ms |
| `mode` | TEXT | `flashcard` \| `typing` |
| `elapsed_ms` | INTEGER | |
| `prev_state`, `prev_due`, `prev_stability`, `prev_difficulty`, `prev_learning_steps`, `prev_reps`, `prev_lapses`, `prev_last_review` | — | ảnh chụp trạng thái trước khi chấm → Hoàn tác (UC-17), tối ưu tham số FSRS sau này |

Chỉ mục: `(card_id)`, `(reviewed_at)`.

### 4.8 `settings` (key/value)

| Key | Mặc định | Miền giá trị | Ý nghĩa |
|---|---|---|---|
| `fsrs_retention` | 0.9 | 0.70–0.95 | Độ giữ lại mục tiêu |
| `fsrs_max_interval` | 36500 | 1–36500 ngày | Khoảng ôn tối đa |
| `fsrs_short_term` | true | bool | Bước học ngắn (phút) |
| `new_cards_per_day` | 20 | 0–999 | Hạn mức từ mới/ngày |
| `grading_buttons` | 2 | 2 \| 4 | Số nút chấm |
| `card_direction` | `word_to_meaning` | + `meaning_to_word`, `mixed` | Hướng thẻ (UC-19) |
| `day_start_hour` | 4 | 0–23 | Giờ bắt đầu "ngày học" |
| `font_scale` | 1.0 | 0.8–1.4 | Hệ số cỡ chữ, nhân thêm trên Dynamic Type |
| `reminder_enabled` | false | bool | Nhắc ôn hằng ngày (P1) |
| `reminder_time` | 20:00 | HH:mm | Giờ nhắc |
| `last_backup_at` | — | epoch ms | Dùng cho nhắc sao lưu |

Trạng thái giao diện tạm (cửa sổ, tab đang chọn) dùng `@SceneStorage`/`@AppStorage`, **không** vào bảng `settings`. `theme_mode` hoãn (Q-2).

### 4.9 Migration

Migration nằm ở Go core (`core/store/migrations`), tên có tiền tố tăng dần, theo dõi bằng `PRAGMA user_version`, mỗi migration chạy trong transaction; không sửa migration đã phát hành (ADR-23). Dữ liệu từ bản web hoặc Flutter cũ nhập qua file sao lưu (FR-031, FR-040).

---

## 5. Luồng dữ liệu & điều hướng

> Tóm tắt; luồng chi tiết ở `ARCHITECTURE.md` §6–§8.

### 5.1 Các lớp

Sơ đồ lớp: `ARCHITECTURE.md` §2.

### 5.2 Quy ước

Bất biến cần giữ: ghi `card_states` + `review_logs` chỉ qua RPC `Grade` trong core, trong một transaction; romaji/kana chỉ ở core (`domain/kana`); thời gian vào core qua `now_ms` (`AppClock` ở Swift); lỗi nghiệp vụ có kiểu; công việc nặng chạy ngoài main thread, có tiến trình và hủy được. Lỗi có mã số, Swift ánh xạ thành chuỗi. Chi tiết: `ARCHITECTURE.md` v2.2 §4 (L5–L7, G1–G8), §7, §11.

### 5.3 Điều hướng

| Route (`HirakuModels.Route`) | Màn hình | Ghi chú |
|---|---|---|
| `.home` | Trang chủ | Banner "Ôn hôm nay", lưới thư mục |
| `.folder(FolderID)` | Thư mục | Danh sách deck |
| `.deck(DeckID)` | Deck | Danh sách từ, bắt đầu học |
| `.study(scope, mode)` | Phiên học | `scope` = `.all` \| `.folder(id)` \| `.deck(id)`; `mode` = id chế độ học |
| `.stats` | Thống kê | M3 |
| `.settings` / `.settingsData` | Cài đặt / Dữ liệu | M2 cho Dữ liệu |
| `.importData(deck?, folder?)` | Nhập dữ liệu | M2 |

Route là giá trị thuần, mã hóa/giải mã được (khôi phục trạng thái cửa sổ). Phiên học trên iPhone mở toàn màn hình; trên iPad/macOS mở trong vùng nội dung với rail phải 230pt (inspector gốc; chỉ hiện khi vùng nội dung rộng ≥ 760pt; hẹp hơn thì ẩn).

---

## 6. Yêu cầu chức năng

Ưu tiên: P0 = MVP (M1), P1 = M2–M3, P2 = M4+. Mã giữ nguyên theo v2; ghi chú "đổi" nêu khác biệt native.

### 6.1 Nội dung

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-001 | Tạo, đổi tên, sắp xếp lại (kéo-thả là cách chính; menu Lên/Xuống làm đường trợ năng), xóa thư mục | P0 |
| FR-002 | Tạo, sửa (tên/mô tả), sắp xếp lại (kéo-thả), di chuyển (kéo-thả hoặc menu), xóa deck | P0 |
| FR-003 | Thêm, sửa, xóa từ; form dựng theo field của kiểu ghi chú. Kiểu hệ thống: Từ*, Cách đọc, Nghĩa*, Câu ví dụ | P0 |
| FR-004 | Field role `reading` rỗng ⇒ "không có kanji", quyết định hành vi Gõ từ | P0 |
| FR-005 | Cảnh báo (không chặn) khi trùng field `term` (`sort_field`) trong cùng deck | P0 |
| FR-006 | Danh sách từ lazy: `Table` đa cột + sắp xếp theo cột (macOS/iPad), `List` (iPhone); chấm trạng thái Mới/Đang học/Đã biết *(đổi: thay Virtual bằng lazy container)* | P0 |
| FR-007 | Mọi thao tác xóa có xác nhận nêu hậu quả; xóa mềm | P0 |
| FR-008 | Chọn nhiều từ: xóa / chuyển deck / đặt lại tiến độ | P1 |
| FR-009 | Sao chép/chuyển từ giữa deck (chỉ giữa các deck cùng kiểu ghi chú) | P1 |
| FR-086 | **(mới, ADR-27)** Mỗi deck gắn một kiểu ghi chú khi tạo, mặc định "Từ vựng Nhật"; không đổi kiểu khi deck đã có từ | P0 (kiểu hệ thống), P1 (chọn kiểu khác) |
| FR-087 | **(mới)** Tạo kiểu bằng nhân bản; thêm, đổi tên, kéo-thả sắp xếp, xóa field (tối đa 10); đặt role, kiểu nhập, bắt buộc, tìm kiếm | P1 |
| FR-088 | **(mới)** Mẫu thẻ: chọn field mặt trước, mặt sau, field đáp án Gõ từ; xem trước thẻ | P1 |
| FR-090 | **(mới, ADR-28)** Quản lý profile: tạo (tên, ví dụ "Tiếng Nhật"), đổi tên, chuyển, xóa (xác nhận nêu số deck/từ; xóa file DB sau khi người dùng xác nhận lần hai). Profile đang mở hiện ở sidebar/Trang chủ | P1 |
| FR-091 | **(mới)** Màn dữ liệu hiện dung lượng từng profile; sao lưu/khôi phục theo profile | P1 |
| FR-092 | **(mới, ADR-29)** Bật/tắt đồng bộ iCloud trong Cài đặt; mặc định **tắt**. Khi tắt, app không gọi CloudKit và dữ liệu trên máy không đổi. Khi bật lại, không tạo bản sao trùng lặp. Dữ liệu đã có trên iCloud khi bật lần đầu được gộp theo ADR-29; khi tắt, dữ liệu trên iCloud giữ nguyên | P3 |
| FR-093 | **(mới, ADR-29)** Trạng thái bật/tắt đồng bộ hiển thị rõ trong Cài đặt. Phạm vi bật/tắt: từng profile (ADR-29) | P3 |
| FR-089 | **(mới)** Xóa field đã có dữ liệu: cảnh báo số từ bị ảnh hưởng; xóa mềm, giá trị giữ trong backup; hoàn tác (FR-077) | P1 |

### 6.2 Học & ôn tập

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-010 | **Flashcard**: hiện field theo mẫu thẻ (§4.3); kiểu hệ thống: mặt trước = Từ; lật → Cách đọc, Nghĩa, Câu ví dụ; chấm điểm | P0 |
| FR-011 | **Gõ từ**: gõ field đáp án của mẫu thẻ; kiểu hệ thống: cách đọc (nếu có kanji) hoặc từ; phản hồi theo từng ký tự | P0 |
| FR-012 | Chuẩn hóa đáp án (§7.2) và **hỗ trợ IME** qua marked text của hệ điều hành *(đổi: thay `compositionstart/end`)* | P0 |
| FR-013 | Tìm kiếm trên các field `searchable` qua `search_text` (kiểu hệ thống: Từ/Nghĩa/Cách đọc); romaji khớp kana; debounce (`Task` + `AppClock`) | P0 (Từ/Nghĩa), P1 (Cách đọc/romaji) |
| FR-014 | Phiên theo phạm vi: toàn app / thư mục / deck | P0 |
| FR-015 | Hàng đợi = thẻ đến hạn + từ mới trong hạn mức (§7.3) | P0 |
| FR-016 | Chấm điểm qua FSRS: cập nhật `card_states` + ghi `review_logs` trong một transaction | P0 |
| FR-017 | 2 hoặc 4 nút chấm; thẻ Again quay lại hàng đợi khi đến hạn | P0 |
| FR-018 | Cấu hình FSRS: retention, max interval, từ mới/ngày, bước học ngắn | P0 |
| FR-019 | Gõ từ sai: hiện đáp án đúng, chờ xác nhận rồi mới sang thẻ kế | P0 |
| FR-020 | Hoàn tác lần chấm gần nhất (làm ở M1b, thuộc MVP — ADR-19) | P1 |
| FR-021 | Hướng thẻ: Từ→Nghĩa / Nghĩa→Từ / Hỗn hợp | P1 |
| FR-022 | Phím tắt khi học (§7.4), mục menu tương ứng trên macOS; bảng trợ giúp | P0 (phím học), P1 (bảng trợ giúp) |
| FR-023 | Ôn tập tùy chỉnh: học trước, theo trạng thái, không ảnh hưởng lịch | P2 |
| FR-024 | Tạm ngưng thẻ; xem lịch sử ôn của từ | P2 |
| FR-025 | Gõ từ: sau khi bị chấm sai, người học có thể chọn "Tôi đúng"; hệ thống thực hiện như Hoàn tác (FR-020) rồi chấm lại Good (chỉ còn một dòng `review_logs`, rating 3) | P1 |
| FR-026 | Chế độ 4 nút: hiển thị khoảng ôn dự kiến dưới mỗi nút (dữ liệu từ `Scheduler.preview`, không ghi DB) | P1 |

### 6.3 Dữ liệu (M2)

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-030 | Sao lưu đầy đủ ra file `.json` (UTType riêng `.hirakubackup`) qua `fileExporter`/`ShareLink` | P1 |
| FR-031 | Khôi phục **gộp**, idempotent; nhận cả file sao lưu của bản web | P1 |
| FR-032 | Xuất deck/toàn app ra **CSV / JSON** (Excel: P2) | P1 |
| FR-033 | Nhập CSV / JSON / **dán văn bản (TSV)**: preview, ánh xạ cột, kiểm tra lỗi, chính sách trùng; kéo-thả file trên macOS/iPad; Excel: P2 | P1 |
| FR-034 | Nhập trong 1 transaction; xử lý UTF-8 BOM, tự phát hiện dấu phân cách | P1 |
| FR-035 | Preview tối đa 200 dòng, nhập xử lý toàn bộ; tổng kết thêm/ghi đè/bỏ qua/lỗi | P1 |
| FR-036 | Tải danh sách dòng lỗi (CSV) | P2 |
| FR-040 | Nhập backup cũ `goi-full-backup` v1 (id integer → UUID) | P2 |

### 6.4 Thống kê & trang chủ

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-050 | Banner "Ôn hôm nay: N từ" + "Ôn ngay" (ghim đáy sidebar trên iPad/macOS) | P0 |
| FR-051 | Thống kê Mới / Đang học / Đã biết | P1 |
| FR-052 | Biểu đồ cột 7 ngày (Swift Charts); 30 ngày + heatmap P2 | P1 / P2 |
| FR-053 | "Sắp đến hạn"; dự báo 7 ngày | P1 |
| FR-054 | Tỷ lệ nhớ theo khoảng thời gian | P2 |
| FR-055 | Thẻ "Từ ngẫu nhiên" | P2 |
| FR-056 | Mục tiêu ngày + streak | P2 |

### 6.5 Cài đặt, hệ thống & UX chung

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-060 | Cài đặt: từ mới/ngày, retention, số nút chấm, cỡ chữ 80–140% có xem trước, giờ bắt đầu ngày; khôi phục mặc định cho từng nhóm (P1) | P0 |
| FR-061 | *(đổi)* Hiển thị dung lượng dữ liệu và thời điểm sao lưu gần nhất | P1 |
| FR-062 | Nhắc sao lưu nếu lâu chưa sao lưu (vd 14 ngày) | P1 |
| FR-063 | *(đổi)* Nhắc ôn hằng ngày bằng thông báo cục bộ (xin quyền khi người dùng bật) | P1 |
| FR-064 | *(đổi)* Đa cửa sổ (macOS/iPad): ghi đồng thời không làm hỏng dữ liệu | P0 |
| FR-065 | Empty state có CTA trên mọi màn danh sách trống | P0 |
| FR-066 | Dữ liệu mẫu (deck N5 ~20 từ) ở lần chạy đầu | P1 |
| FR-067 | Chủ đề sáng/tối | Hoãn (Q-2) |
| FR-068 | Phát âm (`AVSpeechSynthesizer`, `ja-JP`); thoái lui êm nếu thiếu voice | P2 |
| FR-069 | Tags/nhãn và lọc | P2 |
| FR-070 | **(cập nhật, ADR-29)** Đồng bộ đa thiết bị qua iCloud (CloudKit) giữa iPhone, iPad, Mac cùng tài khoản iCloud; **tùy chọn, bật/tắt theo FR-092**; thuộc M4 | P3 |
| FR-071 | **(mới)** Layout thích ứng iPhone/iPad/macOS theo §1.4, cùng Controller, dùng chrome gốc Liquid Glass (ADR-15) | P0 |
| FR-072 | **(mới)** macOS: thanh menu (File/Edit/Study/Help), nhiều cửa sổ, phím tắt chuẩn, Cài đặt ở cửa sổ Settings (⌘,) thay cho mục sidebar; iPad: hỗ trợ bàn phím phần cứng | P0 |
| FR-073 | **(mới)** Widget "Đến hạn hôm nay" (WidgetKit) | P2 |
| FR-074 | **(mới)** VoiceOver/Dynamic Type đầy đủ cho mọi màn hình (§8.3) | P0 |
| FR-075 | **(mới)** Bảo vệ thay đổi chưa lưu: đóng sheet/hộp thoại khi đã nhập thì hỏi "Bỏ thay đổi?"; chưa nhập thì đóng ngay | P0 |
| FR-076 | **(mới)** Khôi phục vị trí khi mở lại: tab, route, vị trí cuộn, từng cửa sổ/scene | P0 |
| FR-077 | **(mới)** Hoàn tác xóa/di chuyển/sắp xếp bằng `UndoManager` hệ thống (⌘Z, lắc iPhone) kèm toast "Hoàn tác"; xóa từ không hỏi xác nhận, xóa thư mục/deck vẫn xác nhận | P1 |
| FR-078 | **(mới)** Thêm từ nhanh từ bất kỳ đâu: chọn deck, nhớ deck dùng gần nhất, "Lưu và thêm tiếp" | P1 |
| FR-079 | **(mới)** Sắp xếp (mới thêm / theo từ) và lọc (trạng thái, đến hạn) danh sách từ; số từ đến hạn trên thẻ deck và thư mục | P1 |
| FR-080 | **(mới)** Sidebar dạng cây Thư mục → Deck (iPad/Mac); kéo deck thả lên thư mục để di chuyển | P1 |
| FR-081 | **(mới)** Phản hồi xúc giác tối thiểu (lật, chấm điểm, đúng/sai); theo cài đặt hệ thống | P1 |
| FR-082 | **(mới)** Chấm điểm bằng vuốt thẻ (chế độ 2 nút), tùy chọn, mặc định tắt | P2 |
| FR-083 | **(mới)** Gợi ý cách đọc từ ô Từ bằng dữ liệu hệ thống; người dùng chạm để điền | P2 |
| FR-084 | **(mới)** Thêm từ từ ứng dụng khác: Share extension (iOS/iPadOS), Services (macOS); **[Cuối cùng]** sau MR | P2 |
| FR-085 | **(mới)** Huy hiệu số từ đến hạn trên biểu tượng ứng dụng/Dock | P2 |

Ghi chú v3.7: các FR nghiệp vụ (FR-013 romaji khớp kana, FR-016 chấm điểm, FR-033…FR-036 nhập, FR-030…FR-031 sao lưu) được thực thi ở Go core; các FR giao diện vẫn ở Swift. Không đổi nội dung FR nào.

**Đã bỏ so với v2**: service worker/PWA offline, `storage.persist()`, cập nhật phiên bản có kiểm soát, nhắc "Cài như ứng dụng" (nội dung của FR-061/063 cũ và phần web của UC-21).

---

## 7. Quy tắc nghiệp vụ

### 7.1 Chấm điểm → FSRS

| Rating | Ý nghĩa | 2 nút | 4 nút | Lapses |
|---|---|---|---|---|
| 1 | Again / Chưa thuộc | ✓ | ✓ | +1 (khi đang ở Review) |
| 2 | Hard | — | ✓ | 0 |
| 3 | Good / Thuộc | ✓ | ✓ | 0 |
| 4 | Easy | — | ✓ | 0 |

- Scheduler tạo từ cài đặt hiện hành: `request_retention`, `maximum_interval`, `enable_short_term`, `enable_fuzz = false`.
- Từ chưa có `card_states` ⇒ khởi tạo thẻ New rồi chấm.
- **Gõ từ** tự chấm: đúng ⇒ Good (3); sai hoặc bỏ qua ⇒ Again (1).
- Với bước học ngắn, Again/Hard trên thẻ mới có thể có `due` chỉ vài phút ⇒ thẻ phải quay lại hàng đợi trong phiên (§7.3).
- Hàm thuần `fsrs.Preview(card, now, settings)` (Go) trả `due` dự kiến cho từng rating (thuần, không ghi DB) — phục vụ FR-026.
- `Grade` (RPC) đọc lại `card_states` **bên trong transaction** (tránh chấm trên dữ liệu cũ khi có nhiều cửa sổ).

### 7.2 Chuẩn hóa đáp án (`core/domain/kana`)

1. `trim()` + lowercase.
2. Có ký tự `[a-z]` ⇒ romaji → kana (っ, `nn→ん`, `n` trước phụ âm → ん, yōon `kya…`, kana nhỏ).
3. Chuẩn tắc: katakana → hiragana; bỏ `ー`; dakuten/handakuten → gốc; kana nhỏ → lớn; bỏ nguyên âm dài lặp; nén ký tự lặp.
4. Khớp khi hai vế chuẩn hóa bằng nhau; tiến trình khớp theo ký tự dùng cho phản hồi từng ô.
5. **IME**: ô nhập bọc `UITextField`/`NSTextField` để biết `markedTextRange`/`hasMarkedText`. Khi đang compose chỉ hiển thị, **chỉ đánh giá sau khi chốt**; Enter dùng để chốt IME không được tính là nộp đáp án.
6. Module thuần Go (`core/domain/kana`) → bộ test bảng (input → kỳ vọng) trong `core/testdata`; đây là logic dễ sai nhất. Swift chỉ gửi chuỗi thô và nhận kết quả từng ô.

### 7.3 Dựng hàng đợi phiên

"Ngày học" bắt đầu lúc `day_start_hour` (mặc định 04:00).

1. **Thẻ đến hạn**: `due ≤ cuối ngày học`, không tạm ngưng, trong phạm vi; Learning/Relearning xếp trước Review, rồi theo `due` tăng dần.
2. **Từ mới được phép** = `new_cards_per_day` − số từ đã chấm lần đầu trong ngày học (đếm `review_logs` có `prev_state = 0`), tối thiểu 0.
3. **Thẻ mới**: chưa có `card_states`, theo `created_at` của note, giới hạn bởi số còn được phép.
4. Hàng đợi = [đến hạn…, mới…]. Sau mỗi lần chấm, nếu `due` mới ≤ `bây giờ + 20 phút` ⇒ chèn lại thẻ.
5. Phiên **không có trạng thái bền riêng**: thoát/đóng cửa sổ rồi mở lại chỉ cần dựng lại hàng đợi từ DB.
6. **`elapsed_ms`** = thời gian từ lúc hiện thẻ đến lúc chấm, **không tính** lúc ứng dụng ở nền hoặc cửa sổ mất focus, và bị chặn trần **60 giây**.

Trạng thái hiển thị: Mới = chưa có `card_states`; Đang học = state 1 hoặc 3; Đã biết = state 2.

### 7.4 Phím tắt khi học

| Phím | Hành động |
|---|---|
| Space / Return | Lật thẻ (Flashcard); Return nộp đáp án / sang thẻ kế (Gõ từ) |
| `1`–`4` | Chấm điểm. 2 nút: `1` = Again, `2`–`4` = Good |
| ⌘Z (hoặc Delete) | Hoàn tác lần chấm gần nhất (P1) |
| `Esc` | Thoát phiên (xác nhận nếu giữa chừng) |
| ⌘/ | Bảng phím tắt (P1) |

Phím tắt học tắt khi focus ở ô nhập (trừ Return/Esc trong Gõ từ). Trên iPhone không có bàn phím phần cứng: dùng nút trên màn hình.

### 7.5 Nhập / xuất

- Bí danh cột: `word`{word, term, từ, 単語}, `reading`{reading, read, yomi, đọc, よみ}, `meaning`{meaning, mean, nghĩa, 意味}, `example`{example, ex, ví dụ, 例文, 例}.
- Dòng thiếu Từ hoặc Nghĩa = lỗi: không nhập, tính vào `failed`.
- Trùng so theo `word` (đã trim) trong deck đích: `skip` / `overwrite` / `addAgain`.
- Xuất: 6 cột `folder, deck, word, reading, meaning, example`; CSV UTF-8 có BOM (Excel Windows đọc đúng tiếng Nhật).
- Mỗi định dạng là một `ImportFormat`/`ExportFormat` đăng ký riêng (OCP) — thêm Excel không sửa luồng nhập.
- Excel (P2): chỉ sheet đầu; JSON: yêu cầu mảng đối tượng.
- **Field tùy biến (ADR-27, M2)**: nhập vào deck đích theo kiểu của deck; ánh xạ cột theo tên field (không phân biệt hoa thường), người dùng chỉnh ánh xạ ở preview; bí danh ở trên áp dụng cho field có role tương ứng. Thiếu field bắt buộc = lỗi dòng. Xuất: `folder, deck` + tên field theo `ord`; deck khác kiểu xuất thành tệp riêng.

### 7.6 Sao lưu / khôi phục

- Định dạng **v3** (ADR-27): `{ format: "hiraku-backup", version: 3, exported_at, folders[], note_types[], note_type_fields[], card_templates[], decks[], notes[], cards[], card_states[], review_logs[], settings[] }`, thời gian ISO-8601 UTC.
- **Khôi phục vẫn nhận v2** (bản web): mỗi `words[]` thành một note kiểu "Từ vựng Nhật" và một thẻ, giữ `id` cũ cho cả note và thẻ để khôi phục lặp lại vẫn idempotent; `card_states`/`review_logs` gắn theo thẻ đó. Bản web không đọc được v3 (chấp nhận, R-08).
- `decks[]` có thêm trường tùy chọn `position`; thiếu (backup bản web) ⇒ xếp theo `created_at`. Bản web bỏ qua trường lạ nên dùng chéo vẫn được.
- Khôi phục: kiểm tra `format`/`version` ⇒ sai thì báo lỗi, không đụng dữ liệu.
- Trùng `id`: giữ bản có `updated_at` mới hơn; `review_logs` chèn-nếu-chưa-có theo `id` (idempotent).
- **Không bao giờ xóa** dữ liệu hiện có; toàn bộ trong một transaction. Core thực hiện trong một RPC; Swift chỉ chọn tệp và hiển thị kết quả.

---

### 7.7 Ranh giới contract

Mọi quy tắc §7.1–7.6 được thực thi trong Go core và có golden test ở `core/testdata` (vector FSRS, bảng kana, CSV và backup mẫu, proto bytes). Swift không tái triển khai các quy tắc này. Thay đổi quy tắc là thay đổi contract hoặc golden, phải qua ADR-22.

---

## 8. Giao diện & trải nghiệm

### 8.1 Màn hình

| Màn hình | Nội dung chính |
|---|---|
| **Trang chủ** | Lời chào editorial ("Chào buổi *sáng*"), banner "Ôn hôm nay", lưới thư mục 2 cột |
| **Thư mục** | Toolbar: Ôn cả thư mục, Nhập, Tạo deck. Danh sách deck + số từ + chấm trạng thái + menu ⋯ |
| **Deck** | Ô tìm kiếm (`searchable`); menu "Học" ở toolbar (Flashcard, Gõ từ); bảng/danh sách từ |
| **Học** | Từ cỡ lớn là **tâm điểm duy nhất**; thanh tiến độ; nút chấm; iPad/macOS có rail phải 230pt (inspector gốc) khi đủ rộng ≥ 760pt (thống kê phiên + hàng đợi); màn "Xong!" |
| **Thống kê** | 3 số trạng thái, biểu đồ, sắp đến hạn |
| **Cài đặt** | FSRS, hiển thị, dữ liệu |

### 8.2 Ngôn ngữ

Tiếng Việt. Mọi chuỗi UI nằm trong String Catalog (`Localizable.xcstrings`), không rải literal; thêm ngôn ngữ sau không đổi mã.

### 8.3 Truy cập (a11y)

- VoiceOver có nhãn cho mọi điều khiển; thứ tự đọc hợp lý ở màn học.
- Phản hồi đúng/sai không chỉ dựa vào màu (icon + văn bản + thông báo VoiceOver).
- Dynamic Type trên iOS/iPadOS; trên macOS dùng `font_scale`. Không cắt nội dung ở mức lớn nhất (SC-009).
- Tôn trọng *Reduce Motion* (lật thẻ thành chuyển mờ), *Increase Contrast*.
- Điều hướng toàn bộ bằng bàn phím trên macOS/iPad; focus ring rõ.
- Tương phản: chữ thường ≥ 4,5:1; chữ lớn/đậm (≥ 14pt đậm hoặc ≥ 18pt) ≥ 3:1, theo bảng ở `DESIGN.md` §Colors. Màu không là kênh duy nhất (đúng/sai, trạng thái học, nút chấm).
- Mục tiêu chạm ≥ 44×44pt (iOS/iPadOS), ≥ 28pt (macOS). *Increase Contrast*: viền 1,5pt → 2pt, chữ phụ dùng `primary`.

---

## 9. Hệ thống thiết kế (từ `DESIGN.md`)

Nguồn sự thật cho màu, cỡ chữ, bo góc, khoảng cách, icon, thành phần và quy tắc dùng Ember là **`DESIGN.md`**; spec không lặp lại giá trị. Yêu cầu ở cấp spec:

### 9.1 Token → Swift

Token trong `DesignSystem/Tokens` (`HK*`, màu trong Asset Catalog) phản chiếu 1-1 `DESIGN.md`; không hard-code màu, cỡ chữ, bo góc ngoài `Tokens/` (`ARCHITECTURE.md` L8).

### 9.2 Font

Georgia và Helvetica Neue (có sẵn trên Apple), Noto Sans JP đóng gói (fallback Hiragino Sans — Q-5). Cỡ chữ ba mức phone/pad/mac; iOS/iPadOS: Dynamic Type × `font_scale`, macOS: `font_scale` (FR-060). Bảng cỡ chữ: `DESIGN.md` §Typography.

### 9.3 Icon (SF Symbols)

Icon dùng SF Symbols qua enum `AppIcon`; bảng ánh xạ: `DESIGN.md` §Iconography.

---

## 10. Yêu cầu phi chức năng

| ID | Yêu cầu |
|---|---|
| NFR-001 | **Offline hoàn toàn khi đồng bộ tắt** (mặc định): không tính năng nào cần mạng. Từ M4, bản build có entitlement `network.client` cho CloudKit; mạng chỉ dùng khi người dùng bật đồng bộ (FR-092, ADR-29, ADR-30). |
| NFR-002 | **Hiệu năng**: 50.000 từ — cuộn 60 fps, tìm kiếm < 150 ms, dựng hàng đợi < 200 ms; khởi động nguội < 1,5 s trên thiết bị tối thiểu. |
| NFR-003 | **Bền vững**: mỗi lần chấm ghi bền ngay (atomic); DB WAL; kiểm tra toàn vẹn khi mở (kiểm tra nhanh hoặc chạy nền để giữ NFR-002; S-1 quyết định). |
| NFR-004 | **An toàn thao tác**: xóa có xác nhận + xóa mềm; khôi phục/nhập không bao giờ xóa dữ liệu hiện có. |
| NFR-005 | **Khởi động nhẹ**: màn học không phụ thuộc module nhập/xuất, biểu đồ. |
| NFR-006 | **Truy cập**: §8.3. |
| NFR-007 | **Riêng tư**: không telemetry, không SDK phân tích, không gửi dữ liệu ra ngoài (trừ khi bật đồng bộ iCloud: dữ liệu chỉ đi tới iCloud của chính người dùng, ADR-30); Privacy Manifest khai báo "không thu thập". |
| NFR-008 | **Bảo trì (kiến trúc)**: `HirakuModels` không import UI; `core/domain` không import `store`, `service`, `ffi`; feature không import feature hay `HirakuBridge`; kiểm tra tự động bằng `check-core.sh` và `check-imports.sh` (`ARCHITECTURE.md` v2.2 §4, §14). |
| NFR-009 | **Tương thích**: iOS 26+, iPadOS 26+, macOS 26+ chỉ Apple silicon (Q-1). |
| NFR-010 | **Đồng thời**: Swift 6 strict concurrency không cảnh báo (chỉ áp dụng cho Swift); không dùng `@unchecked Sendable` nếu không ghi lý do. Go: `go vet` và `go test -race` xanh. |
| NFR-011 | **Tái sử dụng core**: `core/` không phụ thuộc hệ điều hành (không `time.Now()`, đường dẫn cố định, keychain, thông báo) và không có networking (ADR-12, ADR-20). |
| NFR-012 | **Tương thích contract**: mọi thay đổi protobuf phải qua `buf lint` và `buf breaking`; thay đổi phá vỡ phải có ADR (ADR-22). |

---

## 11. Tiêu chí chấp nhận

| ID | Tiêu chí |
|---|---|
| SC-001 | Tạo thư mục → deck → 20 từ trong < 2 phút ở lần dùng đầu. |
| SC-002 | Phiên Flashcard và Gõ từ hoàn tất không cần hướng dẫn (≥ 90% người thử). |
| SC-003 | 100% lượt chấm cập nhật `due` và sinh đúng 1 dòng `review_logs`; không bao giờ ghi một nửa (test ngắt giữa transaction). |
| SC-004 | Thoát app (kể cả bị hệ điều hành kết thúc) rồi mở lại: không mất từ và tiến độ. |
| SC-005 | Chế độ máy bay / không mạng: toàn bộ M1 chạy; app không phát request mạng. |
| SC-006 | 50.000 từ: đạt NFR-002 trên thiết bị tối thiểu mỗi nền tảng. |
| SC-007 | Kana/romaji/IME: bộ test chuẩn hóa pass (`おう/おお`, `ー`, `っ`, `ん`, dakuten) và test thủ công IME trên cả 3 nền tảng. |
| SC-008 | Thẻ Again quay lại đúng thời điểm; hạn mức từ mới/ngày không bị vượt. |
| SC-009 | Dynamic Type lớn nhất / `font_scale` 140% không cắt nội dung ở bất kỳ màn hình nào. |
| SC-010 | (M2) Nhập 200 dòng < 30 s với số liệu chính xác; khôi phục backup (kể cả v2 từ bản web, ánh xạ sang kiểu "Từ vựng Nhật") trả 100% từ + tiến độ; khôi phục lần 2 không nhân đôi. |
| SC-011 | **(mới)** `go test ./...` trong `core/` chạy độc lập; mỗi package Swift build và test độc lập với fake, không cần App target hay core. |
| SC-012 | **(mới)** Thay driver SQLite (modernc sang mattn) không đổi golden test và không sửa dòng nào trong Swift; golden test pass cho cả hai driver. |
| SC-013 | **(mới)** Mọi RPC có golden proto bytes; `buf breaking` không báo lỗi so với nhánh chính. |

---

## 12. Rủi ro

| ID | Rủi ro | Giảm thiểu |
|---|---|---|
| R-01 | **Mất dữ liệu khi xóa app / hỏng thiết bị** nếu không có backup thiết bị/iCloud | Sao lưu thủ công sớm (M2), nhắc sao lưu (FR-062), DB nằm trong vùng được backup mặc định |
| R-02 | Thư viện FSRS Go không đủ chất lượng/bảo trì | Spike S-2; tự cài trong `core/domain/fsrs` (ADR-26) |
| R-03 | IME/marked text khó nhận biết trong SwiftUI thuần | Bọc `UIViewRepresentable`/`NSViewRepresentable` (S-3); test IME thật |
| R-04 | Hành vi UI lệch giữa iPhone/iPad/macOS | Một Controller chung; khác biệt chỉ ở View/shell; XCUITest cho 3 nền tảng |
| R-05 | Ghi đồng thời từ nhiều cửa sổ | Một handle core, một writer; `Grade` đọc lại trạng thái trong transaction; test S-5 |
| R-06 | Chuẩn hóa kana nhiều ca biên | Bộ test bảng lớn; test IME thật |
| R-07 | Module hóa quá mức làm tăng chi phí cấu hình | Giữ đúng 11 feature ở §2.4; chỉ tách module mới khi có ít nhất hai nơi dùng hoặc ranh giới nghiệp vụ rõ |
| R-08 | Chuyển hướng bỏ web/Android: mất phạm vi người dùng | Quyết định có chủ ý của sản phẩm (§1.4); backup chéo cho phép chuyển dữ liệu từ bản web |
| R-09 | Build cgo và XCFramework không ổn định trên CI | Spike S-8 sớm; dự phòng gomobile cho API nhỏ (ADR-21) |
| R-10 | Mất cập nhật UI tự động khi thay `ValueObservation` | Làm mới theo phạm vi qua `EventHub` (ADR-24); đo ở S-1 |
| R-11 | Hai bộ test (Go và Swift) lệch nhau | Golden contract dùng chung, chạy ở cả hai phía; CI bắt buộc |
| R-12 | Go runtime tốn bộ nhớ hoặc thời gian khởi động trong widget (M4) | Đo ở S-8; giới hạn bộ nhớ của extension; widget chỉ đọc |
| R-13 | Field tùy biến làm chậm tìm kiếm/danh sách hoặc làm phình phạm vi | `search_text` và `sort_field` tính sẵn, đo ở S-1; giới hạn 10 field; Pha C ngoài MVP (ADR-27) |
| R-14 | Conflict làm mất thay đổi của thiết bị khác (đồng bộ) | Gộp theo field, xóa thắng (ADR-29); test conflict đồng thời trên 3 thiết bị sau MR |
| R-15 | Schema CloudKit chưa deploy lên Production làm bản phát hành không đồng bộ được | Bước deploy schema trong checklist release; thiết kế schema trước khi deploy, field đã deploy không xóa được |
| R-16 | Phiên bản app khác nhau: bản cũ nhận record có field mới | Ghi schema version trong record; bản cũ bỏ qua field lạ; chặn bật đồng bộ dưới phiên bản tối thiểu |
| R-17 | Restore iCloud Backup rồi sync đẩy dữ liệu cũ lên cloud | Khi phát hiện restore (dữ liệu cũ hơn cloud), đối chiếu với cloud trước khi upload |
| R-18 | Quan hệ cha-con đến không đúng thứ tự (deck, note, card) | Trì hoãn áp dụng bản ghi con khi cha chưa có; không để lỗi |
| R-19 | Hết dung lượng iCloud làm đồng bộ dừng lặng lẽ | Trạng thái lỗi hiển thị trong Cài đặt (FR-093) |
| R-20 | Đồng bộ bị gián đoạn (mất mạng, app bị kill) | Idempotent theo UUID; hàng đợi gửi cùng transaction với ghi cục bộ; chạy lại an toàn |
| R-21 | Test sync thật bị chặn đến MR (ADR-17) | Test bằng adapter mock ở đầu M4 (S-9); test trên 3 thiết bị thật sau MR; báo cáo ghi rõ phần chưa xác minh |

---

## 13. Quyết định còn mở

Nguồn duy nhất: `DECISIONS.md` §4 (Q-xx); thiết kế: `DESIGN.md` (Q-Dx). Không lặp bảng ở đây.

---

## 14. Ngoài phạm vi (hiện tại)

- Web/PWA, Android, Windows, Linux (nền tảng thứ hai: xem ADR-25; core đã sẵn sàng tái sử dụng).
- Tài khoản, đồng bộ đám mây tự dựng, chia sẻ deck công khai.
- Module ngữ pháp, nhận dạng chữ viết tay, Apple Watch/Vision Pro.
- Khôi phục dạng thay thế hoàn toàn (chỉ gộp).
- Mẫu thẻ HTML/CSS, cloze, nhiều mẫu thẻ cho một kiểu, nhiều kiểu trong một deck (ADR-27 Pha C, M4).

---

## 15. Kiểm chứng

Phương pháp, công cụ, khuôn mẫu test và CI: `ARCHITECTURE.md` §11, §13; kế hoạch chi tiết: `TEST_PLAN.md` (M0b). Phạm vi bắt buộc phải kiểm chứng:

- **Logic nghiệp vụ (Go core)**: `kana` (bảng ca), `fsrs` (vector, bước học ngắn, retention), `queue` (hạn mức, `day_start_hour`), parser nhập/xuất + chính sách trùng, backup roundtrip + idempotent, migration; chạy bằng `go test`.
- **Hợp đồng**: golden proto bytes và golden test ở `core/testdata` (SC-013); driver SQLite thay thế phải pass cùng bộ (SC-012).
- **Controller**: mọi UC P0, không cần giao diện (SC-011).
- **E2E trên iPhone, iPad, macOS**: tạo thư mục → deck → từ → học Flashcard → học Gõ từ → đổi cài đặt; kết thúc app giữa phiên; hai cửa sổ (macOS/iPad).
- **Thủ công**: IME thật (bàn phím tiếng Nhật trên iOS, iPadOS có bàn phím, macOS), VoiceOver, Dynamic Type, 50.000 từ trên thiết bị chuẩn (Q-11).
