# Lộ trình triển khai — hiraku (開く) · Native Swift

**Ngày**: 2026-10-29
**Phiên bản**: 1.10 (thêm §11 theo dõi trạng thái WP theo `docs/process/GIT_WORKFLOW.md`) · 1.9 (rà soát 2026-10-29: S-2 sửa thành FSRS Go; thêm S-5 và Spike 0 vào M0; làm rõ S-1 bổ sung; ghi chênh lệch 0,5 tuần ở M1a và Tết 2027; bỏ Q-8 khỏi GATE-1, Q-6 khỏi GATE-3; thêm Q-19…Q-29 vào cổng) · 1.8 (đồng bộ iCloud: ADR-29, ADR-30, rủi ro 17; M4 giữ nguyên) · 1.7 (UI quản lý profile vào M3 — ADR-28, WP-45) · 1.6 (field tùy biến theo deck — ADR-27: Pha A vào M1a, Pha B vào M2–M3; Q-16, Q-17) · 1.5 (bản nháp, chuyển logic sang Go core: WP-02a/02b, S-8, ADR-20…26; — hiệu chỉnh lại ở GATE-1; mốc MR "Cuối cùng" theo ADR-17; thêm việc theo ADR-18)
**Tài liệu liên quan**: `docs/product/spec.md` (§1.3 giai đoạn, §3.3 spike), `docs/product/use-cases.md` (§8 thứ tự), `docs/architecture/DECISIONS.md` (cổng và quyết định), `docs/product/DESIGN.md`, `docs/architecture/ARCHITECTURE.md` v2.2

---

## 1. Giả định và cách đọc

| Giả định | Nội dung |
|---|---|
| Nhân lực | **Đã chuyển sang AI Agents (ADR-31)**: Lead, Coder, Reviewer độc lập và Shipper; PO duyệt gate/phát hành. Các con số tuần-người trong bảng dưới là giả định lịch sử của một lập trình viên toàn thời gian, không phải dự báo năng suất AI. Giữ làm tham chiếu và hiệu chỉnh bằng bằng chứng M0; không tự suy ra hệ số tăng tốc. |
| Lịch (Q-29, 2026-10-30) | **Một AI coding thực hiện tuần tự**, PO duyệt cổng. Lịch chuyển sang **theo cổng**: thứ tự mốc/WP và điểm chờ PO hoặc thiết bị, không cam kết số tuần. Mọi cột tuần-người và ngày kết thúc ở §2–§3 là số lịch sử của một lập trình viên, chỉ để tham chiếu. Số tuần mới chỉ đưa ra ở GATE-1 từ năng suất đo ở M0. |
| Ngày bắt đầu | M0 bắt đầu khi GATE-0 đóng; ngày cụ thể do PO chọn, không có ngày cam kết. |
| Độ chính xác | Đây là ước lượng chuyên môn khi chưa có dữ liệu năng suất; sai số khoảng ±30–50%. Ba cột: lạc quan / khả dĩ / bi quan. **Chốt lại lịch ở GATE-1** bằng năng suất thực đo ở M0. |
| Tài khoản Apple Developer | Đăng ký **sau cùng**, khi PO nghiệm thu bản develop (ADR-17). Đến lúc đó dùng Personal Team; mọi việc cần tài khoản gom vào mốc **MR [Cuối cùng]**. |
| Chưa tính | Kỳ nghỉ (đặc biệt Tết Nguyên Đán, khoảng đầu tháng 2/2027), thời gian chờ xét duyệt đăng ký Apple Developer Program và thời gian chờ App Review. Chừa 1–2 tuần cho Tết nếu lịch rơi vào đó. |
| Thiết bị đo | **MacBook của PO** (Q-11, 2026-10-30). Chưa có iPhone/iPad thật: số đo iOS/iPadOS chưa xác minh cho tới khi có thiết bị. |
| Phạm vi | Chỉ cam kết M0 → M1 (spec §1.3). M2, M3 là kế hoạch; M4 là backlog. Tên **M1** trong spec tương ứng **M1a + M1b** ở đây (theo Q-12). |

---

## 2. Tổng quan lộ trình

**Lịch theo cổng (hiện hành)**: M0 → M0b → **GATE-1** → M1a → M1b → **GATE-2** → M2 → M3 → **GATE-3** → MR → **GATE-4**. AI làm tuần tự từng WP; thời gian thực bị quyết định bởi các điểm chờ ngoài AI:

| Điểm chờ | Khi nào | Người |
|---|---|---|
| Duyệt cổng GATE-1/2/3/4 | cuối mỗi mốc | PO |
| iPhone/iPad thật cho S-1, S-8, IME, SC-006 (hiện chỉ có MacBook) | M0, M1a, M1b | PO |
| Người thử SC-002, SC-001 | M1a, GATE-2 | PO |
| CI Linux và ruleset đã dựng (ADR-33); còn job Xcode/simulator và WP-01 mở rộng CI | đầu M1a | AI + PO |
| Đăng ký Apple Developer, chờ xét duyệt, App Review | MR | PO |

Bảng dưới là **số lịch sử của một lập trình viên**, giữ để tham chiếu (xem §1).

| Mốc | Nội dung | Ước lượng (tuần-người) lạc quan / khả dĩ / bi quan | Kết thúc dự kiến (khả dĩ) | Cổng ra |
|---|---|---|---|---|
| **M0** | Spike kỹ thuật S-1…S-8, duyệt chrome kính (ADR-15) trên thiết bị | 2 / 3 / 4 | ≈ 2026-11-20 | — |
| **M0b** | Chuẩn bị: kiến trúc, wireframe, bảng chuỗi UI, kế hoạch kiểm thử, `AGENTS.md` | 2 / 2,5 / 3,5 | ≈ 2026-12-08 | **GATE-1** |
| **M1a** | Lát cắt dọc P0 trên iPhone (+ ADR-27 Pha A) | 15 / 17,75 / 22,5 | ≈ 2027-04-05 | — |
| **M1b** | Vỏ iPad + Mac, sidebar dạng cây, `Table`, menu, đa cửa sổ, hoàn tác chấm điểm | 4,25 / 5,25 / 6,75 | ≈ 2027-05-10 | **GATE-2 (MVP)** |
| **M2** | Dữ liệu: sao lưu, khôi phục, xuất, nhập (+ theo field) | 4,75 / 5,75 / 7,25 | ≈ 2027-06-18 | — |
| **M3** | Hoàn thiện (nghiệm thu bản develop) (+ UI kiểu ghi chú, profile) | 9,25 / 11,25 / 13,75 | ≈ 2027-09-06 | **GATE-3** |
| **MR** | **[Cuối cùng]** Đăng ký tài khoản và phát hành | 1 / 1,5 / 2,5 | ≈ 2027-09-17 | **GATE-4** |
| M4 | Tích hợp hệ thống (backlog, sau MR) | chưa lập lịch | — | — |

**Tổng đến MVP (M0 → M1b)**: 23,25 / 28,5 / 36,75 tuần-người. **Tổng đến nghiệm thu bản develop (đến M3)**: 37,25 / 45,5 / 57,75. **Tổng đến phát hành (đến MR)**: 38,25 / 47 / 60,25 tuần-người, chưa tính chờ xét duyệt đăng ký và App Review.

Ghi chú v1.7: WP-45 (UI profile, ADR-28) cộng +1 vào M3; GATE-3 và GATE-4 dời khoảng 1 tuần. Ghi chú v1.6: ADR-27 cộng Pha A vào M1a (+1 / +1,25 / +1,5), Pha B vào M2 (+0,75) và M3 (+2,25); các ngày dự kiến dời tương ứng. Ghi chú v1.5: cột M0 và M1a đã cộng chi phí S-8, S-1 bổ sung và WP-02a/02b (xem §3.1, §3.3); các mốc sau dời lịch tương ứng. Quan hệ giữa các mốc là tuần tự; M0b có thể chạy song song với M0 nếu có người làm thiết kế/tài liệu riêng (khi đó rút ngắn lịch, không đổi tuần-người).

---

## 3. Chi tiết từng mốc

### 3.1 M0 — Spike (≈ 3 tuần)

| Việc | Nội dung | Ước lượng (ngày) |
|---|---|---|
| S-1 + S-7 | `github.com/mattn/go-sqlite3` (Go core) trên 50.000 từ + 200.000 log, đo reload theo `ChangeSet`/`EventHub` (ADR-24); App Group trên 3 nền tảng, target phụ đọc cùng DB, kiểm tra sao lưu thiết bị/iCloud | 2,5 |
| S-2 | Đánh giá thư viện FSRS Go với bộ test vector tham chiếu (ADR-26) | 1 |
| S-3 | IME: nhận biết compose, Return chốt IME, ô kana điều khiển bởi một trường nhập, trên iOS/iPadOS/macOS | 1,5 |
| S-4 | Layout thích ứng: `Table`, `NavigationSplitView`, inspector 230pt, phụ kiện đáy tab bar (ADR-15) | 1 |
| S-6 | Đóng gói Noto Sans JP, đo kích thước | 0,5 |
| ADR-15 | Duyệt chrome kính (tab bar, sidebar, toolbar) trên ba nền tảng theo tiêu chí ADR-15 | 0,5 |
| S-8 | Build `core/ffi` thành c-archive cho ba slice; đóng XCFramework tự động; chạy trên simulator và thiết bị thật; đo RSS và khởi động Go runtime; 1.000 lần `hk_call` không rò bộ nhớ (ADR-21) | 5 |
| S-1 bổ sung | Đo lại S-1 trên schema ADR-27 (`notes`/`cards`, `search_text`) trong cùng thiết bị chuẩn; kiểm tra reload theo phạm vi giữ 60 fps | 2 |
| S-5 | Hai cửa sổ cùng ghi một DB; chấm trùng một thẻ (spec §3.3 S-5, UC-08 E6) | 1 (đề xuất) |
| Spike 0 | Xác minh `github.com/mattn/go-sqlite3` build được cho ios/arm64 và simulator, `go list -deps` không có `net` (luật G5); chạy trước S-8 | 1–2 (đề xuất) |
| Báo cáo | Kết quả từng S-*, số đo trên thiết bị chuẩn (Q-11), đề xuất quyết định | 0,5 |

Ghi chú: S-5 và Spike 0 chưa nằm trong ước lượng 3 tuần của M0 (khoảng +2 đến +3 ngày); hiệu chỉnh ở GATE-1.

**Sản phẩm bàn giao**: báo cáo spike; mã thử nghiệm (không đưa vào sản phẩm).
**Lưu ý ADR-17**: với Personal Team, S-7 chỉ xác minh được phần khả dụng; phần chưa xác minh (App Sandbox + App Group trên macOS, widget, sao lưu thiết bị/iCloud) ghi rõ trong báo cáo, hoàn tất ở WP-39 (MR). Nếu App Group không dùng được, dev dùng container thường qua `DatabaseLocation`.
**Tiêu chí ra**: mỗi S-* có kết quả Đạt/Không đạt kèm số đo; đủ dữ liệu để chốt Q-5, Q-8, Q-D2 và xác nhận hoặc thay thế ADR-20, 21, 24, 26, 32 (S-1, S-2, S-8).

### 3.2 M0b — Chuẩn bị M1 (≈ 2,5 tuần)

| Sản phẩm | Nội dung | Ước lượng (tuần) |
|---|---|---|
| `docs/architecture/ARCHITECTURE.md` | Tách từ spec v3.1 §2.2–2.3, §3, §5 (nay spec chỉ còn con trỏ): luật Swift (L1–L11) và Go (G1–G8), khuôn mẫu feature và domain Go, contract `hiraku.v1`, script kiểm tra core và `import`, cách thêm feature/`StudyMode` | 0,5 |
| `AGENTS.md` + bộ OpenCode (ADR-31) | Bốn agents, hai skills `hiraku-contract`/`hiraku-feature`, permissions, guard và task packet; DESIGN/COPY đọc trực tiếp, không tạo skill thiết kế trùng tài liệu | 0,25 (ước lượng lịch sử) |
| Wireframe/prototype (prompt: `docs/product/WIREFRAME_PROMPT.md`) | Home, Deck/Words, Flashcard, Gõ từ, Cài đặt cho iPhone (ưu tiên); iPad/Mac vẽ trước M1b | 1,25 |
| `COPY.md` | Bảng chuỗi UI tiếng Việt cho các màn M1a, làm nền String Catalog (bản đề xuất đã có, chờ duyệt) | 0,25 |
| `docs/process/TEST_PLAN.md` | Đã có khung ma trận thiết bị/OS/IME, dữ liệu và tiêu chí; còn xác nhận Q-11, người thử SC-002 và kiểm thử sản phẩm thực tế | 0,25 |

**Tiêu chí ra**: tài liệu được duyệt; quyết định GATE-1 đã chốt; lịch M1a hiệu chỉnh theo số đo M0.

### 3.3 M1a — Lát cắt dọc P0 trên iPhone (≈ 17,75 tuần)

Ghi chú lịch: cộng 11 WP dưới đây là 17,25 tuần; 0,5 tuần chênh là dự phòng (PO xác nhận ở GATE-1). Tết Nguyên Đán 2027 (khoảng 06/02) rơi vào M1a; ngày kết thúc dự kiến dời thêm ít nhất 1–2 tuần.

Phạm vi: UC-01, 02, 03, 04, 06, 07, 08, 13, 14, phần lõi UC-21 (ghi nguyên tử), phím tắt học (FR-022 P0, dùng được với bàn phím phần cứng).

| WP | Nội dung | Phụ thuộc | Ước lượng (tuần) |
|---|---|---|---|
| WP-01 | Workspace, Go module `core/`, buf (lint, breaking), CI (`go test -race`, `xcodebuild test`, `check-core.sh`, `check-imports.sh`), pipeline XCFramework, cấu trúc repo theo Q-13 | `docs/architecture/ARCHITECTURE.md` v2.2 | 0,75 |
| WP-02a | Store Go: `github.com/mattn/go-sqlite3`, WAL, migration theo `PRAGMA user_version`, repository, xóa mềm, golden test (ADR-23, ADR-32); schema kiểu ghi chú `note_types`/`notes`/`cards`, kiểu hệ thống, `domain/notetype` (ADR-27 Pha A) | WP-01 | 3 |
| WP-02b | Bridge: `ffi` (`hk_open`, `hk_call`, `hk_free`, `hk_close`), `HirakuBridge` (actor, `EventHub`, ánh xạ proto ↔ model), XCFramework, fake Swift trong `HirakuTesting` (ADR-21, ADR-24) | WP-01, WP-02a | 1,25 |
| WP-03 | FSRS trong `core/domain/fsrs` (thư viện Go hoặc tự cài, ADR-26), RPC `Grade` (transaction, đọc lại trong tx), `BuildQueue` (ngày học, hạn mức, chèn lại 20 phút, `elapsed_ms`) | WP-02a, S-2 | 1,5 |
| WP-04 | `core/domain/kana`: romaji → kana, chuẩn hóa, so khớp từng ký tự, golden test bảng | WP-01 | 1 |
| WP-05 | `DesignSystem`: token `HK*`, component, font, `AccentColor` Ember; áp ADR-15 (chrome gốc) | Q-5, Q-D2 | 1,5 |
| WP-06 | FeatureFolders, FeatureDecks, FeatureWords (CRUD, trùng từ, tìm kiếm, `List` iPhone; kéo-thả sắp xếp thư mục/deck; bảo vệ thay đổi chưa lưu; khôi phục vị trí — ADR-18); form từ và danh sách dựng theo định nghĩa kiểu (ADR-27) | WP-02b, WP-05 | 3,5 |
| WP-07 | `StudyKit`, FeatureStudy, FeatureFlashcard (2/4 nút, màn "Xong!"); mặt thẻ theo mẫu thẻ (ADR-27) | WP-03, WP-05 | 1,75 |
| WP-08 | FeatureTyping (IME, ô kana, phản hồi, hiện đáp án đúng) | WP-04, WP-07, S-3 | 1,5 |
| WP-09 | FeatureSettings, FeatureHome (banner "Ôn hôm nay") | WP-05, WP-06 | 0,5 |
| WP-10 | Hoàn thiện: XCUITest iPhone, a11y (VoiceOver, Dynamic Type), kịch bản kết thúc app giữa phiên, sửa lỗi | tất cả WP trên | 1 |

**Tiêu chí ra**: golden contract xanh và `buf breaking` không lỗi; SC-001…SC-004, SC-007…SC-009 đạt trên iPhone chuẩn; mọi UC thuộc phạm vi có kịch bản XCUITest; kiểm tra phụ thuộc trong CI xanh; kiểm tra đọc cỡ 15pt (Q-D5).

### 3.4 M1b — Vỏ iPad + Mac (≈ 5,25 tuần)

| WP | Nội dung | Ước lượng (tuần) |
|---|---|---|
| WP-11 | `RootSplitView` (sidebar kính gốc, khối "đến hạn" ghim bằng `safeAreaInset`), `Table` gốc, inspector 230pt cho phiên học, sidebar dạng cây Thư mục → Deck có kéo-thả deck, Cài đặt ở cửa sổ Settings (macOS), layout thích ứng | 2 |
| WP-12 | macOS: thanh menu, phím tắt, nhiều cửa sổ; iPad: nhiều scene; UC-21 lõi (đa cửa sổ, `Grade` đọc lại trong transaction (core)) | 1 |
| WP-13 | Kiểm tra và sửa IME trên iPad (bàn phím phần cứng) và macOS | 0,5 |
| WP-14 | XCUITest iPad/Mac, hiệu năng 50.000 từ trên cả ba thiết bị chuẩn, a11y bàn phím | 1 |
| WP-15 | Hoàn tác chấm điểm (UC-17, FR-020): nút/toast, ⌘Z, lắc iPhone; khôi phục `card_states` từ `prev_*` (ADR-19) | 0,75 |

**Tiêu chí ra (GATE-2 / MVP)**: SC-001…SC-009 đạt trên ba nền tảng; SC-011, SC-012 đạt; không lỗi chặn mở.

### 3.5 M2 — Dữ liệu (≈ 5,75 tuần)

| WP | Nội dung | UC | Ước lượng (tuần) |
|---|---|---|---|
| WP-20 | Sao lưu và khôi phục gộp, idempotent, nhận tệp backup bản web; định dạng v3, ánh xạ v2 → kiểu hệ thống (logic ở `core/domain/backup`, ADR-27) | UC-10, UC-11 | 1,75 |
| WP-21 | Xuất CSV/JSON | UC-09 | 0,5 |
| WP-22 | Nhập CSV/JSON/TSV/dán văn bản: ánh xạ cột, preview, chính sách trùng, transaction (parser ở `core/domain/importer`); ánh xạ cột theo field, xuất theo kiểu (ADR-27 Pha B) | UC-05 | 2,5 |
| WP-23 | UI dữ liệu: dung lượng, thời điểm sao lưu, nhắc sao lưu | UC-21 (UI) | 0,5 |
| WP-24 | Kiểm thử, hoàn thiện | — | 0,5 |

Cần wireframe và `COPY.md` cho màn nhập (ánh xạ cột, preview, chính sách trùng), sao lưu và khôi phục trước WP-22 (≈ 0,5 tuần, chưa tính vào ước lượng M2; hiệu chỉnh ở GATE-2).

Đã gồm trong M2 nếu Q-7 trả lời "có": nhập backup Flutter cũ (FR-040), +~1 tuần.
**Tiêu chí ra**: SC-010 đạt. Nên hoàn tất M2 **trước khi chia sẻ ứng dụng cho người khác** (R-01).

### 3.6 M3 — Hoàn thiện, nghiệm thu bản develop (≈ 11,25 tuần)

| WP | Nội dung | UC / FR | Ước lượng (tuần) |
|---|---|---|---|
| WP-30 | Thống kê (Swift Charts) | UC-12 | 1 |
| WP-31 | "Tôi đúng" (dùng lại hoàn tác chấm điểm từ WP-15) | UC-07; FR-025 | 0,25 |
| WP-32 | Thao tác hàng loạt trên từ | UC-18 | 1 |
| WP-33 | Lần chạy đầu và deck mẫu | UC-16 | 0,5 |
| WP-34 | Hướng thẻ; khoảng ôn dự kiến dưới nút | UC-19; FR-026 | 0,5 |
| WP-35 | Bảng phím tắt và trợ giúp | UC-20 | 0,5 |
| WP-36 | Nhắc ôn hằng ngày (thông báo cục bộ) | UC-28 | 0,5 |
| WP-37 | Duyệt thiết kế, kiểm toán a11y, hiệu năng, sửa lỗi tồn | — | 1,5 |
| WP-40 | Hoàn tác chung (`UndoManager` ở Swift; thao tác ngược là RPC core; toast; xóa từ không hỏi xác nhận) | UC-17; FR-077 | 0,75 |
| WP-41 | Thêm từ nhanh, nhớ deck gần nhất | UC-30; FR-078 | 0,25 |
| WP-42 | Sắp xếp và lọc danh sách từ (truy vấn ở core); số từ đến hạn trên thẻ deck/thư mục | UC-04; FR-079 | 0,75 |
| WP-43 | Xúc giác tối thiểu (ADR-19) | UC-06, UC-07; FR-081 | 0,25 |
| WP-44 | Quản lý kiểu ghi chú: nhân bản kiểu, thêm/đổi tên/sắp xếp/xóa field, mẫu thẻ, xem trước; chọn kiểu khi tạo deck; RPC sửa kiểu ở core (ADR-27 Pha B) | UC-31, UC-02; FR-086…FR-089 | 2,25 |
| WP-45 | Quản lý profile: tạo, đổi tên, chuyển, xóa; danh sách ở `AppStorage` App Group; `hk_close`/`hk_open` khi chuyển; tên profile trên sidebar/Trang chủ; dung lượng từng profile ở màn dữ liệu (ADR-28) | UC-32; FR-090, FR-091 | 1 |

Tổng WP ≈ 11 tuần; phần còn lại của 11,25 tuần là dự phòng. WP-44 cần `docs/product/DESIGN.md`, `COPY.md` và wireframe cho màn chỉnh field trước khi bắt đầu. FR-082…FR-085 (P2) chưa xếp lịch; FR-084 làm sau MR.
**Tiêu chí ra (GATE-3)**: PO nghiệm thu bản develop — xem §4.

### 3.7 MR — Đăng ký tài khoản và phát hành **[Cuối cùng]** (≈ 1,5 tuần, chưa tính chờ duyệt)

Chỉ bắt đầu sau GATE-3 (PO xác nhận ứng dụng đạt mong muốn ở bản develop). Mọi việc cần tài khoản Apple Developer Program trả phí nằm ở đây (ADR-17).

| WP | Nội dung | Ước lượng (tuần) |
|---|---|---|
| (PO) | Đăng ký Apple Developer Program; chốt Q-8 (Mac App Store hay trực tiếp) | chờ xét duyệt, không tính |
| WP-38 | Chuẩn bị phát hành: `docs/process/RELEASE.md`, bundle ID và signing chính thức, universal purchase, Privacy Manifest, tài sản App Store, chính sách riêng tư, entitlement iCloud và deploy schema CloudKit lên Production (R-15, ADR-29) | 1,25 |
| WP-39 | Hoàn tất S-7 (App Sandbox + App Group trên macOS, sao lưu thiết bị/iCloud); nếu dev dùng container thường thì chuyển DB sang App Group bằng sao lưu/khôi phục | 0,25 |
| (ngoài ước lượng) | TestFlight beta, nộp App Review, xử lý phản hồi | chờ ngoài |

**Tiêu chí ra (GATE-4)**: xem §4.

---

## 4. Cổng quyết định

| Cổng | Điều kiện vào bước kế tiếp | Quyết định phải chốt (`docs/architecture/DECISIONS.md`) |
|---|---|---|
| **GATE-0** (trước M0) | Thiết bị chuẩn: MacBook (Q-11 đã chốt một phần; thiếu iPhone/iPad thật); dùng Personal Team, đăng ký Apple Developer Program sau cùng (ADR-17); repo sẵn sàng | Q-11, Q-12, Q-13 (Q-1 đã chốt: ADR-13); Q-29 |
| **GATE-1** (sau M0 + M0b; Go/No-go M1) | **Bắt buộc đạt**: S-1, S-3, S-8; S-7 xác minh phần khả dụng (ADR-17). S-2 phải có phương án (dùng hoặc tự cài). Tài liệu M0b được duyệt. Lịch M1a hiệu chỉnh theo năng suất đo được | Q-5, Q-D2; Q-19, Q-20, Q-21, Q-22, Q-24, Q-27, Q-28; xác nhận ADR-20, 21, 24, 26, 32; S-1 đo trên schema ADR-27 |
| **GATE-2** (MVP) | Tiêu chí ra M1b đạt; `buf breaking` xanh suốt M1; xem xét thời gian build của ADR-02 và chi phí bridge; chốt phạm vi M2–M3 | Q-7, Q-D5, Q-23, Q-26 |
| **GATE-3** (PO nghiệm thu bản develop; mở MR) | SC-010 đạt; kiểm toán a11y xong; PO xác nhận ứng dụng đạt mong muốn; bắt đầu đăng ký Apple Developer Program | Q-8 (Q-6 đã đóng 2026-10-29) |
| **GATE-4** (sẵn sàng phát hành, sau MR) | Checklist `docs/process/RELEASE.md` đầy đủ; phản hồi TestFlight đã xử lý; nộp App Review | — |

Nếu GATE-1 trượt S-1, S-3 hoặc S-8, dừng M1 và họp lại (S-8 trượt có thể quay lại ADR-03, +2 đến 3 tuần-người) theo bảng "Điều kiện kích hoạt xem lại" ở `docs/architecture/DECISIONS.md` §5.

---

## 5. Sản phẩm bàn giao ngoài mã nguồn

| Tài liệu | Cần trước | Ghi chú |
|---|---|---|
| `docs/architecture/ARCHITECTURE.md` v2.2, `AGENTS.md` | GATE-1 | Đã soạn (có ADR-27, ADR-28); duyệt ở M0b |
| Wireframe iPhone | GATE-1 | iPad/Mac: trước khi bắt đầu M1b |
| Contract `hiraku.v1` và golden testdata | WP-01 | Nguồn sự thật cho Swift và Go (ADR-22) |
| `COPY.md` | Bắt đầu WP-06 | Bản đầu cho các màn M1a |
| `docs/process/TEST_PLAN.md` | GATE-1 | Đã có khung; cập nhật bằng chứng theo từng mốc, không coi tài liệu đã có là test đã đạt |
| `DATA_FORMAT.md` | Bắt đầu M2 | Chỉ cần nếu muốn tách schema/backup/nhập khỏi spec |
| `docs/process/RELEASE.md` | WP-38 (MR) | Đã có checklist; hoàn thiện bằng chứng sau GATE-3. Phạm vi entitlement/deploy CloudKit tại MR so với M4 cần chốt trước khi thực hiện (`docs/process/AGENT_WORKFLOW.md` §6) |

---

## 6. Rủi ro lịch

| # | Rủi ro | Tác động lịch | Giảm thiểu |
|---|---|---|---|
| 1 | IME (R-03, R-06) khó hơn dự kiến, đặc biệt trên ba nền tảng | WP-08, WP-13 vượt 1–2 tuần | Spike S-3 sớm; chia M1a/M1b; test IME thật |
| 2 | Thư viện FSRS Go không dùng được (ADR-26) | WP-03 +1–1,5 tuần | Quyết định ở GATE-1; bộ test vector chuẩn |
| 3 | Năng suất thực thấp hơn giả định | Mọi mốc | Hiệu chỉnh ở GATE-1; báo cáo burn-up hằng tuần |
| 4 | Mở rộng phạm vi (feature mới giữa chừng) | M1 trượt | Quy tắc kiểm soát thay đổi (§8) |
| 5 | Nội dung hoặc Ember khó đọc trên chrome kính (ADR-15) | WP-05, WP-37 thêm vòng duyệt | Duyệt trên thiết bị thật từ M0; phương án đổi tint tab về mực |
| 6 | Cấu hình App Group/sandbox macOS (S-7, Q-8) | Có thể tốn 2–3 ngày ở M0 | Làm sớm; có đường lui về container thường |
| 7 | Kỳ nghỉ Tết, chờ xét duyệt đăng ký và chờ App Review | Lịch dời 1–3 tuần | Chừa dự phòng; nộp đăng ký ngay sau GATE-3 |
| 8 | Chi phí module hóa (R-07) | Build và cấu hình chậm | Giữ 11 feature; xem xét ở GATE-2 |
| 9 | Dùng Personal Team đến MR (ADR-17): S-7 chỉ xác minh một phần, profile ký hết hạn ngắn, không có TestFlight | Rủi ro tồn đọng ở GATE-1; gián đoạn khi dùng thật | Sao lưu thủ công thường xuyên; cân nhắc kéo WP-20 (sao lưu/khôi phục) lên ngay sau M1a nếu dùng thật hằng ngày; cài đè khi ký lại, không xóa app (xác nhận khi thử) |
| 10 | Build cgo/XCFramework không ổn định (R-09) | WP-02b, M1a +1 đến 2 tuần | S-8 trong M0; dự phòng gomobile |
| 11 | Go runtime tốn bộ nhớ hoặc khởi động chậm, ảnh hưởng widget (R-12) | M4 | Đo ở S-8; giới hạn bộ nhớ extension |
| 12 | Mất cập nhật UI tự động khi thay `ValueObservation` (R-10) | WP-06, WP-11 | ADR-24; đo ở S-1 |
| 13 | Hai bộ test (Go và Swift) lệch nhau (R-11) | Lặp công việc | Golden contract dùng chung; CI bắt buộc |
| 14 | Quay về GRDB nếu S-8 hoặc S-1 trượt | +2 đến 3 tuần-người | Giữ tài liệu ADR-03; quyết định ở GATE-1 |
| 15 | Tìm kiếm/danh sách chậm với field JSON (R-13) | WP-02a, WP-06 +0,5 đến 1 tuần | `search_text`, `sort_field` tính sẵn; đo ở S-1; FTS5 dự phòng |
| 16 | Khách mở rộng yêu cầu field theo hướng Anki (cloze, nhiều kiểu/deck, `.apkg`) | M3 trượt | Khóa Pha C ở M4 (ADR-27); Q-17 chốt ở GATE-2; kiểm soát thay đổi §8 |
| 17 | Đồng bộ iCloud không test thật được trước MR (ADR-17); lỗi sync chỉ lộ sau phát hành | M4 trượt; rủi ro phát hành | Adapter mock và test logic đầu M4 (S-9, ADR-30); test 3 thiết bị sau MR |

---

## 7. Definition of Done

**Mức feature/UC** (mọi WP):
1. Chức năng đúng kịch bản chính, thay thế và biên trong `docs/product/use-cases.md`.
2. Controller có test với `InMemory*Repository` và `AppClock` giả; logic nghiệp vụ có test đơn vị.
3. UC P0 có kịch bản XCUITest.
4. VoiceOver, Dynamic Type, bàn phím (Mac/iPad) kiểm tra được; không chỉ dựa vào màu.
5. Chuỗi UI nằm trong String Catalog; token từ `DesignSystem`, không hard-code.
6. CI xanh, gồm kiểm tra đồ thị `import` và strict concurrency không cảnh báo.
7. Không lệch tài liệu: nếu hành vi đổi, đã cập nhật spec/UC/DESIGN/DECISIONS.
8. Mã theo `docs/architecture/ARCHITECTURE.md` C1–C8: đơn giản, vừa đủ, comment ngắn chỉ về mã.
9. Go: `go vet` và `go test -race` xanh; `buf breaking` không báo lỗi; `check-core.sh` xanh; golden contract cập nhật cùng thay đổi.

**Mức mốc**: các tiêu chí ra ở §3 và cổng ở §4.

---

## 8. Theo dõi và kiểm soát thay đổi

- **Nhịp**: rà soát hằng tuần (tiến độ WP, burn-up tuần-người, rủi ro mới, quyết định đến hạn).
- **Kiểm soát thay đổi**: thêm/bớt phạm vi sau GATE-1 phải nêu tác động lịch (tuần-người) và ghi vào `docs/architecture/DECISIONS.md`. Đổi nhỏ trong WP không cần ghi.
- **Chỉ số sản phẩm**: không có telemetry (ADR-12). Đo qua khảo sát ngắn và, sau MR, TestFlight: tỷ lệ hoàn thành SC-001/SC-002, số lỗi mất dữ liệu (mục tiêu 0), thời gian tạo 20 từ đầu tiên.
- **Hiệu chỉnh lịch**: tại GATE-1 và GATE-2, so sánh tuần-người thực với ước lượng và cập nhật các mốc sau.

---

## 9. Backlog sau MR (M4 — chưa lập lịch)

| Mục | UC / FR | Ước lượng thô (tuần) |
|---|---|---|
| Widget "Đến hạn hôm nay" (làm sau khi đăng ký tài khoản; App Group trên Personal Team chưa xác nhận; widget cần link XCFramework của core, xem R-12 trong `docs/product/spec.md`) | UC-29; FR-073 | 1–1,5 |
| Phát âm (TTS) | UC-25; FR-068 | 1 |
| Tags và lọc | UC-24; FR-069 | 1,5 |
| Ôn tập tùy chỉnh | UC-22; FR-023 | 1,5 |
| Chi tiết từ, lịch sử, tạm ngưng | UC-23; FR-024 | 1–1,5 |
| Mục tiêu ngày và streak | UC-26; FR-056 | 0,5 |
| Từ ngẫu nhiên | UC-15; FR-055 | 0,5 |
| Nhập Excel (xem ADR-11) | UC-05 mở rộng | 1 |
| Field tùy biến Pha C: cloze, nhiều mẫu thẻ, nhiều kiểu trong một deck (ADR-27) | — | chưa ước lượng |
| Nhập `.apkg` của Anki (Q-17, PO chốt để backlog) | — | chưa ước lượng |
| Đồng bộ iCloud (ADR-29, ADR-30; cần tài khoản trả phí để test thật) | UC-27; FR-070, FR-092, FR-093 | 4–8 (chưa tính lại sau S-9) |
| Spike S-9: adapter CKSyncEngine với mock, idempotent, contract sync (đầu M4) | ADR-30; R-21 | chưa ước lượng |

Tổng không kể iCloud khoảng 8–11 tuần-người; lập lại ước lượng sau GATE-3.

---

## 10. Bản đồ UC → mốc

| Mốc | Use case |
|---|---|
| M1a | UC-01, UC-02, UC-03, UC-04, UC-06, UC-07, UC-08, UC-13, UC-14, UC-21 (lõi: ghi nguyên tử); schema ADR-27 Pha A |
| M1b | UC-21 (lõi: đa cửa sổ), UC-17 (hoàn tác chấm điểm), §4.0 (hành vi theo nền tảng), phím tắt học trên Mac/iPad |
| M2 | UC-05, UC-09, UC-10, UC-11, UC-21 (UI) |
| M3 | UC-12, UC-16, UC-17 (hoàn tác nội dung), UC-18, UC-19, UC-20, UC-28, UC-30, UC-31, UC-32; FR-025, FR-026, FR-086…FR-089 |
| MR | **[Cuối cùng]** WP-38, WP-39 — không có UC mới |
| M4 | UC-15, UC-22, UC-23, UC-24, UC-25, UC-26, UC-29; UC-27 (tùy chọn) |

---

## 11. Theo dõi trạng thái WP

Nguồn cập nhật bắt buộc cho mọi PR (`docs/process/GIT_WORKFLOW.md` §3, §6). Giá trị trùng Kanban: `bl` Backlog · `rd` Sẵn sàng · `ip` Đang làm · `rv` Chờ duyệt · `dn` Hoàn thành. Mục không có trong bảng là `bl`. Cập nhật **cùng PR** với mã, và đổi cùng giá trị trong `ROADMAP hiraku — Kanban.html` (mảng `raw`, trường thứ 5).

| Mã | Trạng thái | PR / commit | Ghi chú (phần còn lại, blocker) |
|---|---|---|---|
| Spike 0 | dn | 8 | Working-tree; `mattn/go-sqlite3 v1.14.52`, không còn `net`, build 3 slice xanh (build-only, Q-11 partial); ADR-32 đã chốt (PR 8) |
| S-4, S-5, ADR-15 | rd | — | M0; đã có Git/remote, chưa có CI, chưa bắt đầu, chưa có mã `core/` |
| S-3 | rv | — | Wrapper UIKit/AppKit chạy trên simulator với marked text lập trình; IME Nhật thật, iPad bàn phím, macOS chưa xác minh — cần PO thử tay (SC-007) |
| S-6 | rv | — | Spike Đạt trên simulator: 2,19 MB, 0 glyph thiếu (N3), OFL; đề xuất Q-5 = A; macOS/thiết bị chưa chạy — chờ review |
| S-2 | dn | 8 | Working-tree: Không đạt khớp vector (go-fsrs/v4 v4.0.0; 3/17 due lệch, dung sai 0); PO cân nhắc ngữ nghĩa ts-fsrs. |
| S-1 | dn | 8 | Nửa Go Đạt trên MacBook; iOS/iPadOS và 60 fps chưa xác minh (S-1 bổ sung). |
| S-7, S-1 bổ sung, Báo cáo spike | bl | — | Q-11 chốt một phần (MacBook, chưa có iPhone/iPad thật); phần build của S-8 chạy được sau Spike 0 |
| S-8 | rv | — | Working-tree: XCFramework + hk_* spike Đạt trên macOS và simulator; phần thiết bị (SC-006) chưa xác minh, ngưỡng 300 ms chờ PO — chờ review |
| Q-13, Q-1, Q-6 | dn | — | Đã chốt |
| Q-12 | dn | — | PO duyệt phương án B (2026-10-30) |
| Q-11, Q-D2 | rv | — | Q-11 chốt một phần (MacBook; thiếu iPhone/iPad thật), Q-D2 chờ Design |
| `docs/architecture/ARCHITECTURE.md`, `AGENTS.md`, `COPY.md`, `docs/process/TEST_PLAN.md` | rv | `bde958f` | Đã soạn, chờ duyệt M0b; 58 test `.opencode` đạt 2026-10-29 |
| RV-01…RV-08 | rd | — | Việc từ review, chờ quyết định |
| App shell | rv | — | Working-tree: App/Hiraku.xcodeproj build và chạy trên iPhone 18 Pro simulator lẫn macOS; bundle id/team vẫn tạm; chờ review. |
