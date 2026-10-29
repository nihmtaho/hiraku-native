# Nhật ký quyết định — hiraku (開く) · Native Swift + Go core

**Ngày**: 2026-10-29
**Phiên bản**: 1.10 (rà soát 2026-10-29: ADR-06 chuyển thành chờ spike; thêm Q-19…Q-29 từ các điểm chưa rõ; thêm điều kiện xem lại cho Spike 0) · 1.9 (thêm ADR-30 kiến trúc đồng bộ: Go giữ DB và logic, Swift giữ CloudKit; chốt ADR-29, đóng Q-6; sửa ADR-12) · 1.8 (thêm ADR-29 đồng bộ iCloud tùy chọn bật/tắt, giữ ở M4) · 1.7 (thêm ADR-27 field tùy biến theo deck, ADR-28 profile; sửa ADR-04; đóng Q-16, Q-17, Q-18) · 1.6 (thêm ADR-20…26 từ việc chuyển logic và dữ liệu sang Go core; thay thế ADR-03; sửa ADR-02, ADR-14; đóng Q-4, Q-A…Q-E)
**Tài liệu liên quan**: `spec.md` (v3.11, §13 chỉ mục Q), `ARCHITECTURE.md` (v2.2), `DESIGN.md` (v0.5.4; D-1…D-6, Q-D1…Q-D5), `use-cases.md` (v3.9), `ROADMAP.md` (v1.9, cổng quyết định), `AGENTS.md`

---

## 1. Cách dùng

Tài liệu này là **nơi duy nhất** ghi trạng thái các quyết định. Spec và DESIGN mô tả nội dung kỹ thuật/thiết kế; khi trạng thái thay đổi, cập nhật ở đây trước, rồi sửa tài liệu bị ảnh hưởng.

**Trạng thái**: *Đã chốt* · *Đã chốt, chờ spike* (quyết định đã ghi nhận, điều kiện kiểm chứng chưa chạy) · *Đề xuất* (có khuyến nghị, chờ xác nhận) · *Mở* (cần dữ liệu từ spike hoặc từ bạn) · *Đã thay thế* (giữ để tra cứu).

**Chủ**: **PO** = quyết định sản phẩm; **Tech** = quyết định kỹ thuật; **Design** = quyết định thiết kế. Một người có thể giữ nhiều vai, nhưng loại quyết định vẫn được tách.

**Cổng (gate)** — mốc mà quyết định phải được chốt (chi tiết ở `ROADMAP.md` §4):

| Cổng | Thời điểm | Ý nghĩa |
|---|---|---|
| GATE-0 | Trước khi bắt đầu M0 | Đủ điều kiện làm spike |
| GATE-1 | Kết thúc M0 và M0b | Go/No-go cho M1a; S-1, S-3, S-8 phải đạt |
| GATE-2 | Kết thúc M1b (MVP) | Quyết định phạm vi M2–M3 |
| GATE-3 | PO nghiệm thu bản develop (cuối M3); mở MR và đăng ký Apple Developer Program | Quyết định liên quan phát hành |
| GATE-4 | Sẵn sàng phát hành (sau MR) | Nộp App Review |

**Quy tắc thay đổi**: quyết định *Đã chốt* không bị xóa; nếu đổi, ghi "Thay thế bởi ADR-xx" và nêu lý do. Mỗi thay đổi nêu rõ tài liệu cần cập nhật.

---

## 2. Chỉ mục

### 2.1 Đã chốt

| ID | Quyết định | Trạng thái | Ngày | Tham chiếu cũ |
|---|---|---|---|---|
| ADR-01 | Chuyển hoàn toàn sang native Swift (iOS, iPadOS, macOS); bỏ web và Android | Đã chốt | 2026-10 | `spec.md` §1.4 |
| ADR-02 | Kiến trúc MVC + SOLID; mỗi feature là một Swift Package độc lập | Đã chốt, **được sửa bởi ADR-20** | 2026-10 | §2.2–2.3 |
| ADR-03 | SQLite + GRDB sau Repository; không dùng SwiftData | **Đã thay thế bởi ADR-20 và ADR-23** | 2026-10 | Q-3 |
| ADR-04 | UUIDv7, xóa mềm, giữ schema và định dạng backup v2 | Đã chốt, **được sửa bởi ADR-27** (schema và backup v3; vẫn nhận v2) | 2026-10 | §3.1, §4, §7.6 |
| ADR-05 | MVP khóa giao diện sáng | Đã chốt | 2026-10 | Q-2, Q-D4 |
| ADR-06 | DB nằm trong App Group ngay từ M1 | Đã chốt, chờ spike (S-7) | 2026-10-28 | Q-10 |
| ADR-07 | SF Symbols; namespace `HK*`; màu trong Asset Catalog | Đã chốt | 2026-10 | `DESIGN.md` |
| ADR-08 | Ba ngoại lệ thiết kế: cảnh báo xóa dùng đỏ hệ thống, `.searchable`, tiêu đề serif trong nội dung | Đã chốt | 2026-10 | D-1, D-2, D-5 |
| ADR-09 | Gõ từ: một trường nhập thật điều khiển các ô kana | Đã chốt | 2026-10 | DESIGN §Components |
| ADR-10 | "Tôi đúng" = Hoàn tác rồi chấm lại Good; không đổi schema | Đã chốt | 2026-10-28 | FR-025 |
| ADR-11 | Nhập/xuất ở M2: CSV, JSON, TSV; Excel hoãn | Đã chốt | 2026-10 | Q-9 |
| ADR-12 | Không mạng, không telemetry (phần mạng sửa bởi ADR-29) | Đã chốt; sửa một phần | 2026-10 | NFR-001, NFR-007 |
| ADR-13 | Mức OS tối thiểu: iOS 26, iPadOS 26, macOS 26 (chỉ Apple silicon) | Đã chốt | 2026-10-28 | Q-1 |
| ADR-14 | Điều chỉnh kiến trúc: `AppClock`, `HirakuTesting`, `StudyKit` → `DesignSystem`, `DesignSystem` chỉ phụ thuộc SwiftUI | **Được sửa một phần bởi ADR-20** | 2026-10-28 | spec §2.2–2.3 |
| ADR-15 | Chrome gốc Liquid Glass: tab bar, sidebar, toolbar, sheet, inspector không tùy biến kiểu dáng | Đã chốt | 2026-10-28 | Q-D1, D-3, D-4 |
| ADR-16 | Phong cách mã cho AI agent: đơn giản, vừa đủ, comment ngắn chỉ về mã | Đã chốt | 2026-10-28 | `ARCHITECTURE.md` C1–C8 |
| ADR-17 | Đăng ký Apple Developer Program sau cùng; việc liên quan đánh dấu [Cuối cùng] (mốc MR) | Đã chốt | 2026-10-28 | Q-14 |
| ADR-18 | Quy ước tương tác: kéo-thả để sắp xếp, hoàn tác thay xác nhận, bảo vệ thay đổi, khôi phục vị trí | Đã chốt | 2026-10-28 | `use-cases.md` §4.0.1 |
| ADR-19 | Phạm vi bổ sung từ rà soát UX: hoàn tác chấm điểm vào M1b; xúc giác tối thiểu | Đã chốt | 2026-10-28 | Q-15, Q-D3 |
| ADR-20 | Go core làm nguồn nghiệp vụ và dữ liệu; Swift giữ UI | **Đã chốt, chờ spike** (S-8, S-1) | 2026-10-28 | Thay ADR-03 |
| ADR-21 | Tích hợp cgo qua c-archive và XCFramework; ABI bốn hàm, payload protobuf | **Đã chốt, chờ spike** (S-8) | 2026-10-28 | Q-A (bối cảnh) |
| ADR-22 | Contract protobuf `hiraku.v1` là nguồn duy nhất; buf lint và buf breaking | Đã chốt | 2026-10-28 | Q-B |
| ADR-23 | SQLite qua `modernc.org/sqlite`; Go sở hữu DB; Swift không mở DB | **Đã chốt, chờ spike** (S-1) | 2026-10-28 | Q-A |
| ADR-24 | Làm mới chủ động qua `ChangeSet` và `EventHub`; Go không gọi ngược | **Đã chốt, chờ spike** (S-1 đo reload) | 2026-10-28 | Q-C |
| ADR-25 | Monorepo, thư mục `core/` ở gốc; chưa xây nền tảng thứ hai | Đã chốt | 2026-10-28 | Q-D, Q-E |
| ADR-26 | FSRS: thư viện Go nếu đạt S-2; nếu không, tự cài trong `core/domain/fsrs` | **Đã chốt, chờ spike** (S-2) | 2026-10-28 | Q-4 |
| ADR-30 | Kiến trúc đồng bộ iCloud: Go giữ SQLite, change log và merge; Swift chỉ giữ adapter CKSyncEngine; không đổi ADR-20 và ADR-23 | **Đã chốt (PO, 2026-10-29), chờ S-9** | 2026-10-29 | Q-6 |
| ADR-29 | Đồng bộ iCloud là tính năng tùy chọn bật/tắt, mặc định tắt, giữ ở M4; tắt không làm mất hay đổi dữ liệu trên máy | **Đã chốt (PO, 2026-10-28 và 2026-10-29)** | 2026-10-28 | Q-6 |
| ADR-28 | Một DB cho mỗi profile; profile dùng để tách ngôn ngữ học và giới hạn dung lượng mỗi DB; không tách theo deck | Đã chốt | 2026-10-28 | Q-16 |
| ADR-27 | Kiểu ghi chú và field tùy biến theo deck; `notes`/`cards` thay `words`; chia Pha A (M1a), B (M2–M3), C (M4) | Đã chốt, chờ đo S-1 trên schema mới | 2026-10-28 | Yêu cầu khách hàng; sửa ADR-04 |
| ADR-31 | OpenCode: bốn agents, hai skills; AI tự merge khi Review độc lập và CI đạt, PO duyệt gate/phát hành | Đã chốt | 2026-10-29 | `OPENCODE.md`; Q-29 xác nhận một phần |

### 2.2 Đề xuất và mở

| ID | Quyết định | Trạng thái | Chủ | Hạn | Chặn |
|---|---|---|---|---|---|
| Q-11 | Thiết bị chuẩn đo hiệu năng | Mở | PO | GATE-0 | S-1, S-8 |
| Q-12 | Chia M1 thành M1a (iPhone) và M1b (iPad + Mac) | Đề xuất | PO | GATE-0 | Lịch M1 |
| Q-13 | Quy ước tên tài liệu và nơi lưu | Đã chốt: tên file (bỏ `_native-swift`), đặt ở root repo | PO | GATE-0 | Không |
| Q-5 | Đóng gói Noto Sans JP hay dùng Hiragino Sans | Mở | Design | GATE-1 | M1a (WP-05) |
| Q-8 | Phát hành macOS: Mac App Store hay trực tiếp **[Cuối cùng]** | Đề xuất | PO | GATE-3 | MR (entitlement) |
| Q-D2 | Màu chấm trạng thái "Đang học" | Đề xuất | Design | GATE-1 | M1a (WP-05) |
| Q-7 | Nhập dữ liệu Flutter cũ (FR-040) | Mở | PO | GATE-2 | Phạm vi M2 |
| Q-D5 | Cỡ body 15pt trên iPhone | Đề xuất | Design | GATE-2 | Không |
| Q-19 | Vòng đời xóa mềm: purge, thùng rác, backup có chứa dữ liệu đã xóa | Mở | PO | GATE-1 | WP-02a |
| Q-20 | Mã lỗi chi tiết trong contract (mã 3 cần mã phụ) | Đề xuất | Tech | GATE-1 | WP-02b |
| Q-21 | Mức nghiêm ngặt chuẩn hóa Gõ từ | Mở | PO | GATE-1 | WP-04 |
| Q-22 | Định nghĩa "Đã biết" trong thống kê | Mở | PO | GATE-1 | WP-06, WP-30 |
| Q-23 | Hướng thẻ với kiểu ghi chú tùy biến và Gõ từ | Đề xuất | PO | GATE-2 | WP-34 |
| Q-24 | Phạm vi settings: cấp ứng dụng hay theo profile | Đề xuất | Tech | GATE-1 | WP-02a, WP-09 |
| Q-25 | Sở hữu danh sách profile giữa ADR-28 và ADR-29/30; nhân đôi dữ liệu mặc định khi bật đồng bộ | Mở | Tech | trước S-9 | UC-27 |
| Q-26 | Nhập: ngữ nghĩa "Ghi đè"; CSV Shift-JIS | Mở | PO | GATE-2 | WP-22 |
| Q-27 | Kéo WP-20 (sao lưu/khôi phục) lên ngay sau M1a | Đề xuất | PO | GATE-1 | Lịch M1b |
| Q-28 | Thuật ngữ UI: "deck" hay "bộ thẻ", "profile" | Đề xuất | PO, Design | GATE-1 | COPY, String Catalog |
| Q-29 | Nhân lực: đã chốt AI coding (ADR-31); còn dự phòng và người thử SC-002 | Mở một phần | PO | GATE-0 | Lịch toàn bộ |
| Q-14 (nhắc lại) | Xem ADR-17 | Đã chốt | — | — | — |

Q-4, Q-A, Q-B, Q-C, Q-D, Q-E đã được đóng bởi ADR-26, ADR-23, ADR-22, ADR-24, ADR-25 tương ứng; Q-6 đóng bởi ADR-29 và ADR-30 (2026-10-29); không còn trong danh sách mở.

---

## 3. Quyết định đã chốt

### ADR-01 — Native Swift thay web/Android
- **Bối cảnh**: kế hoạch cũ là web (TanStack) trước, Expo sau.
- **Quyết định**: một codebase SwiftUI cho iOS, iPadOS, macOS; bản web (`spec.md` v2 cũ) giữ làm tham chiếu.
- **Hệ quả**: bỏ Android và web (R-08); trải nghiệm đúng chuẩn Apple; không còn rủi ro trình duyệt xóa dữ liệu.
- **Xem lại khi**: có nhu cầu thật về Android/web. Xem thêm ADR-25 về điều kiện tái sử dụng.

### ADR-02 — MVC + SOLID, feature độc lập
- **Quyết định**: Model/View/Controller tách thư mục trong mỗi feature; Controller là `@MainActor @Observable`, phụ thuộc protocol Repository; feature chỉ phụ thuộc `HirakuModels`, `DesignSystem`, `StudyKit`; không import feature khác; ghép qua `Route` và slot `@ViewBuilder`; chế độ học là plugin.
- **Sửa bởi ADR-20**: phần Model nghiệp vụ và Persistence chuyển sang Go core. Controller vẫn là Swift. Repository ở Swift là adapter gọi `HirakuBridge`, không còn là nơi chứa SQL.
- **Hệ quả**: chi phí cấu hình cao hơn (R-07); đổi lại thêm/bớt feature không ảnh hưởng nơi khác; CI quét đồ thị `import` (NFR-008).
- **Xem lại khi**: số package gây chậm build/chi phí vượt lợi ích (đo ở GATE-2).

### ADR-03 — SQLite + GRDB *(đã thay thế)*
- **Trạng thái**: đã thay thế bởi ADR-20 (Go core làm nguồn dữ liệu) và ADR-23 (SQLite qua `modernc.org/sqlite`).
- **Lý do giữ lại để tra cứu**: quyết định ban đầu dùng GRDB vì truy vấn FSRS bằng SQL, không nạp 50.000 từ vào RAM, giữ schema v2, tránh ràng buộc của SwiftData với CloudKit. Các lý do này vẫn đúng với SQLite nói chung; thứ bị thay đổi là nơi đặt code truy cập DB.
- **Phương án dự phòng**: nếu S-8 hoặc S-1 trượt, quay lại GRDB theo ADR-03 (xem §5).

### ADR-04 — Định danh, xóa mềm, tương thích backup
- **Quyết định**: ID UUIDv7 (TEXT) tự cài; mọi bảng có `created_at`, `updated_at`, `deleted_at`; thời gian lưu epoch ms; backup `hiraku-backup` version 2 giữ nguyên để dùng chéo với bản web.
- **Hệ quả**: sẵn sàng đồng bộ về sau (Q-6) mà không đổi schema; khôi phục idempotent.

### ADR-05 — Giao diện sáng duy nhất ở MVP
- **Quyết định**: khóa `preferredColorScheme(.light)` ở MVP; nếu làm tối thì thiết kế bộ token riêng, không đảo màu.
- **Xem lại khi**: sau GATE-3, nếu phản hồi người dùng đòi hỏi.

### ADR-06 — DB trong App Group từ M1
- **Quyết định**: đặt DB trong container App Group ngay từ đầu, trên cả iOS/iPadOS và macOS. Swift xác định đường dẫn và truyền vào `hk_open`.
- **Hệ quả**: cần entitlement App Group; cấu hình macOS phụ thuộc Q-8; S-7 kiểm tra phần khả dụng ở M0, phần còn lại ở WP-39. Với Personal Team (ADR-17), nếu App Group không dùng được thì dev dùng container thường qua `DatabaseLocation` và chuyển sang App Group ở MR bằng sao lưu/khôi phục.
- **Xem lại khi**: S-7 thất bại.

### ADR-07 — Token và icon
- **Quyết định**: SF Symbols qua `AppIcon`; token trong namespace `HKColor/HKFont/HKRadius/HKSpacing/HKBorder` (vì `Color.primary` đã tồn tại trong SwiftUI); màu trong Asset Catalog một appearance; không hard-code hex ngoài `Tokens/`.

### ADR-08 — Ba ngoại lệ thiết kế
- **D-1**: cảnh báo xóa dùng màu `destructive` hệ thống, không dùng Ember (dialog do OS vẽ).
- **D-2**: thanh tìm kiếm là `.searchable` hệ thống (IME, toolbar, VoiceOver).
- **D-5**: tiêu đề trang là serif trong nội dung; thanh điều hướng hệ thống giữ chức năng.

### ADR-09 — Gõ từ dùng một trường nhập thật
- **Quyết định**: một trường nhập thật điều khiển các ô kana (ô là hiển thị phản chiếu), để IME, thanh gợi ý và VoiceOver hoạt động; nhận biết compose qua marked text của hệ điều hành. Chuẩn hóa đáp án nằm ở Go (`kana`); IME vẫn là Swift.
- **Xem lại khi**: S-3 thất bại.

### ADR-10 — "Tôi đúng" (FR-025)
- **Quyết định**: thực hiện như Hoàn tác (FR-020) rồi chấm lại Good; chỉ còn một dòng `review_logs`.
- **Hệ quả**: không thêm cột vào schema; phụ thuộc UC-17, làm trong M3 cùng Hoàn tác.

### ADR-11 — Phạm vi nhập/xuất M2
- **Quyết định**: CSV, JSON, TSV/dán văn bản; Excel (.xlsx) hoãn vì cần thư viện bên thứ ba; xem lại sau M3 nếu có nhu cầu thật. Parser và ghi file do Go core thực hiện (ADR-20).

### ADR-12 — Không mạng, không telemetry
- **Quyết định**: ứng dụng không phát request mạng; core Go không import `net` hoặc thư viện mạng (kiểm tra bằng `check-core.sh`); macOS không xin entitlement `network.client`; không SDK phân tích; Privacy Manifest khai báo không thu thập.
- **Hệ quả**: không đo được chỉ số sử dụng tự động; đo qua TestFlight/khảo sát (`ROADMAP.md` §8). Đồng bộ iCloud (ADR-29, ADR-30) đã xem lại: phần mạng chỉ dùng khi người dùng bật; phần còn lại giữ nguyên.

### ADR-13 — Mức OS tối thiểu
- **Quyết định**: iOS 26, iPadOS 26, macOS 26; macOS chỉ trên Apple silicon (Intel không hỗ trợ).
- **Thiết bị tối thiểu** (theo danh sách tương thích công bố của Apple): iPhone 11 trở lên; iPad dùng chip A12 trở lên; Mac Apple silicon (M1 trở lên). Cần Xcode có SDK 26.
- **Hệ quả**: một diện mạo hệ thống duy nhất, nên chrome kính (ADR-15) chỉ cần kiểm tra trên OS 26; API mới dùng trực tiếp.
- **Xem lại khi**: cần mở rộng nhóm người dùng.

### ADR-14 — Điều chỉnh kiến trúc *(được sửa một phần bởi ADR-20)*
- **Quyết định gốc**: (1) protocol thời gian tên `AppClock` vì `Clock` trùng `Swift.Clock`; (2) `InMemory*Repository`, `ManualClock`, fixture và contract suite nằm ở product `HirakuTesting`; (3) `StudyKit` phụ thuộc thêm `DesignSystem`; (4) `DesignSystem` chỉ phụ thuộc SwiftUI.
- **Sửa bởi ADR-20**:
  - Điểm (1) giữ: `AppClock` ở Swift, truyền xuống core dưới dạng `now_ms`.
  - Điểm (2) đổi: `HirakuTesting` chỉ còn fake Swift cho Controller. Contract suite chuyển thành golden test ở `core/testdata`.
  - Điểm (3) và (4) giữ.
  - `HirakuCore` đổi tên thành `HirakuModels` (struct, protocol, Route, AppClock); phần nghiệp vụ và Persistence chuyển sang Go.
- **Hệ quả**: spec §2.2–2.3 và §5.1–5.2 chỉ còn con trỏ tới `ARCHITECTURE.md` v2.2.

### ADR-15 — Chrome gốc Liquid Glass
- **Quyết định**: dùng thành phần hệ thống, không tùy biến kiểu dáng: `TabView`, `NavigationSplitView`, toolbar (nhóm nút kính, `ToolbarSpacer`), sheet, inspector (cột phải phiên học), `Table` và `.searchable` gốc. `AccentColor` = Ember. Nội dung giữ phẳng nền giấy.
- **Hệ quả**: đóng Q-D1, D-3, D-4; bỏ component `table-header` và `sidebar-item-active`; tab đang chọn tô Ember cần kiểm tra tương phản trên kính.
- **Kiểm tra ở M0** (thiết bị thật): nội dung cuộn dưới kính đọc được trên nền giấy; tab chọn đọc được (nếu không, tint tab về mực); phụ kiện đáy và tab bar không che CTA. Tên API theo tài liệu WWDC25, xác minh với SDK đang dùng.
- **Xem lại khi**: S-4 phát hiện thành phần gốc không đáp ứng.

### ADR-16 — Phong cách mã cho AI agent
- **Quyết định**: tám quy tắc C1–C8 ở `ARCHITECTURE.md` §4: đơn giản trước, không mã cao siêu, dễ đọc, dùng sẵn framework, thay đổi vừa đủ, comment một dòng giải thích *vì sao*, mã sạch, test vừa đủ. Áp dụng cho cả Go và Swift. Bản rút gọn trong `AGENTS.md`. Ngoại lệ comment duy nhất: `// TODO(Q-xx)`.
- **Hệ quả**: CI cảnh báo comment chứa mã tài liệu (FR/UC/ADR/WP) và `print(`/`fmt.Println`; Definition of Done thêm một mục; các điểm mở rộng đã định (Repository, `StudyMode`, `ImportFormat`) là ngoại lệ của C1.
- **Xem lại khi**: quy tắc gây khó cho kiểm thử hoặc gây lặp mã đáng kể.

### ADR-17 — Đăng ký Apple Developer Program sau cùng
- **Quyết định**: dùng Personal Team (miễn phí) trong suốt M0–M3; đăng ký ở GATE-3. Mọi việc phụ thuộc tài khoản trả phí đánh dấu **[Cuối cùng]** và gom vào mốc MR: bundle ID và signing chính thức, App Group/sandbox đầy đủ (WP-39), TestFlight, Mac App Store (Q-8), universal purchase, Privacy Manifest, chính sách riêng tư, tài sản App Store, App Review (WP-38). Sau MR: widget (FR-073) và iCloud (ADR-29, ADR-30; entitlement iCloud và deploy schema CloudKit).
- **Căn cứ đã xác minh**: Personal Team cài được lên thiết bị của chính bạn bằng Xcode, không dùng được TestFlight/App Store, profile ký hết hạn ngắn, nhiều dịch vụ không khả dụng. Chưa xác nhận: App Groups trên Personal Team, nhất là macOS.
- **Hệ quả**: S-7 chỉ xác minh phần khả dụng ở M0; GATE-1 chấp nhận rủi ro tồn đọng; không có TestFlight đến MR.
- **Lưu ý dữ liệu**: nếu dùng thật hằng ngày trên bản ký tạm, nên kéo WP-20 (sao lưu/khôi phục) lên ngay sau M1a.
- **Xem lại khi**: S-7 cho thấy Personal Team không đủ cho nhu cầu develop.

### ADR-18 — Quy ước tương tác
- **Quyết định**: (1) mỗi hành động có ít nhất hai đường, trong đó một đường không cần cử chỉ; (2) kéo-thả là cách chính để sắp xếp thư mục/deck và di chuyển deck, kèm menu Lên/Xuống/Di chuyển cho trợ năng; (3) hoàn tác thay xác nhận với thao tác đảo ngược được; xác nhận chỉ cho thao tác lan truyền; (4) đóng sheet có thay đổi thì hỏi "Bỏ thay đổi?"; (5) khôi phục tab, route, vị trí cuộn và cửa sổ; (6) hành động thường dùng nằm trong tầm ngón cái trên iPhone; (7) trên macOS, Cài đặt là cửa sổ Settings (⌘,).
- **Hệ quả**: thêm cột `decks.position`; thêm FR-075…FR-085 và UC-30; hoàn tác qua `UndoManager` ở Swift, thao tác ngược do core thực hiện trong một transaction. Ước lượng M1a +0,5 tuần-người, M1b +0,5, M3 +2 (xem `ROADMAP.md`).
- **Xem lại khi**: kéo-thả trong lưới/danh sách SwiftUI không đạt chất lượng ở spike S-4.

### ADR-19 — Phạm vi bổ sung từ rà soát UX
- **Quyết định**: (1) đưa hoàn tác chấm điểm (UC-17, FR-020) vào M1b — WP-15, 0,75 tuần; "Tôi đúng" (FR-025) còn ở M3 — WP-31, 0,25 tuần; (2) chấp nhận bộ xúc giác tối thiểu (FR-081) — WP-43, 0,25 tuần ở M3.
- **Lý do**: bốn nút chấm điểm đặt sát nhau nên chạm nhầm thường gặp; người thử bản develop cần hoàn tác ngay.
- **Hệ quả**: M1b +0,75 tuần, M3 −0,5 tuần (tổng +0,25). Thay thế Q-15 và Q-D3.

### ADR-20 — Go core làm nguồn nghiệp vụ và dữ liệu
- **Bối cảnh**: cần tái sử dụng logic cho các nền tảng khác sau này (Android, web, desktop khác) mà không viết lại nghiệp vụ.
- **Quyết định**: nghiệp vụ, dữ liệu và schema nằm trong `core/` (Go): FSRS, kana, hàng đợi, ngày học, hạn mức, transaction chấm điểm, schema và migration, truy vấn, tìm kiếm, parser và ghi CSV/JSON/TSV, sao lưu và khôi phục. Swift giữ SwiftUI, Controller, Route, DesignSystem, StudyKit (UI) và tích hợp hệ điều hành (thông báo, bộ chọn tệp, TTS, WidgetKit, IME).
- **Tiêu chí ranh giới**: đoạn logic có cần biết nó đang chạy trên Apple không. Nếu không, nó thuộc Go.
- **Điều kiện ràng buộc**: core không phụ thuộc OS (không `time.Now()`, không đường dẫn cố định, không keychain, không thông báo); thời gian và đường dẫn DB do Swift truyền vào.
- **Thay thế**: ADR-03.
- **Hệ quả**: hai ngôn ngữ, hai bộ test, cần contract (ADR-22). Ước lượng thêm khoảng 3,5 đến 4 tuần-người đến MVP (xem `ROADMAP.md`).
- **Điều kiện kích hoạt xem lại**: S-8 hoặc S-1 không đạt; khi đó quay lại GRDB và logic Swift theo ADR-03 (xem §5).
- **Trạng thái**: *Đã chốt, chờ spike.* Chưa có số đo nào; quyết định dựa trên phân tích, chưa được kiểm chứng.

### ADR-21 — Tích hợp cgo qua c-archive và XCFramework
- **Quyết định**: Go build thành `c-archive` cho ba slice: iOS device arm64, iOS simulator arm64, macOS arm64; đóng gói XCFramework trong script CI (`core/scripts/build-xcframework.sh`), không chạy tay. ABI tối giản gồm bốn hàm: `hk_open(db_path, &handle, &err)`, `hk_call(handle, method, req, &resp)`, `hk_free(bytes)`, `hk_close(handle)`. Dữ liệu vào và ra là `HKBytes` chứa protobuf.
- **Mã lỗi**: 0 thành công; 1 tham số sai; 2 không tìm thấy; 3 vi phạm nghiệp vụ; 4 lỗi lưu trữ; 5 lỗi nội bộ (panic đã được recover). Go không trả chuỗi tiếng Việt; Swift ánh xạ mã sang String Catalog.
- **Quy tắc ranh giới**: mọi hàm export có `recover`; không truyền con trỏ Go qua ranh giới; không callback ngược từ Go sang Swift; chuỗi do Go cấp phát phải được Swift giải phóng bằng `hk_free` ngay sau khi đọc.
- **Ràng buộc hiệu năng**: lời gọi đồng bộ; mỗi lời gọi nghiệp vụ p95 ≤ 100 ms. Import, sao lưu và các job dài chia thành lô hoặc session (`ImportBegin → ImportAppend → ImportCommit`).
- **Ngưỡng S-8 đề xuất (cần PO xác nhận)**: khởi động Go runtime < 300 ms trên thiết bị chuẩn.
- **Phương án dự phòng**: S-8 trượt trên CI thì thử gomobile cho phần API nhỏ; nếu cả hai không đạt thì quay lại ADR-03 (xem §5).
- **Phụ thuộc mới**: không có ngoài cgo; được ADR này bao phủ theo L9.
- **Trạng thái**: *Đã chốt, chờ spike S-8.*

### ADR-22 — Contract protobuf `hiraku.v1`
- **Quyết định**: `core/proto/hiraku/v1/*.proto` là nguồn duy nhất. Go sinh bằng `protoc-gen-go`; Swift sinh bằng `swift-protobuf`. Thư mục sinh ra không sửa tay.
- **Quy tắc**: không tái dùng field number; dùng `reserved` khi xóa; enum có `UNSPECIFIED = 0`; thời gian là `int64` epoch ms; ID là chuỗi UUIDv7; method của `hk_call` là enum có số cố định, không tái dùng số đã xóa.
- **Kiểm tra CI**: `buf lint` và `buf breaking` so với nhánh chính. Vi phạm tương thích thì không merge.
- **Phụ thuộc mới**: `swift-protobuf`, `google.golang.org/protobuf`, công cụ `buf`.
- **Thay thế cho**: Q-B (JSON Schema bị loại vì ít kiểm soát kiểu hơn cho mục tiêu đa nền tảng).
- **Trạng thái**: *Đã chốt.*

### ADR-23 — SQLite qua `modernc.org/sqlite`; Go sở hữu DB
- **Quyết định**: Go mở file DB tại đường dẫn Swift cấp qua `hk_open` (App Group, ADR-06). Một handle; một connection ghi; pool đọc; WAL; `busy_timeout`. Swift không import SQLite và không mở DB.
- **Migration**: danh sách có tiền tố tăng dần trong `core/store/migrations`, theo dõi bằng `PRAGMA user_version`. Không sửa migration đã phát hành. Schema spec §4 không đổi.
- **Lý do chọn modernc** (thuần Go): không cần toolchain C cho từng slice; CI đơn giản hơn; đường đi tự nhiên cho wasm sau này. Đánh đổi: hiệu năng có thể thấp hơn bản C.
- **Phương án thay thế**: `mattn/go-sqlite3` (cgo), dùng khi S-1 không đạt.
- **Điều kiện S-1**: đạt NFR-002 với 50.000 từ và 200.000 log. Nếu không đạt, chuyển sang `mattn/go-sqlite3` và ghi ADR thay thế.
- **Ràng buộc**: core không được import `net` (ADR-12).
- **Trạng thái**: *Đã chốt, chờ spike S-1.*

### ADR-24 — Làm mới chủ động qua `ChangeSet` và `EventHub`
- **Quyết định**: mỗi lệnh ghi thành công trả `ChangeSet` (loại thực thể và ID). `HirakuBridge` (actor) phát sự kiện vào `EventHub`. Controller của mọi cửa sổ đăng ký `AsyncStream` và tải lại phần liên quan. Go không gọi ngược sang Swift.
- **Đa cửa sổ**: cùng tiến trình, cùng handle, nên chỉ có một writer. Không cần IPC.
- **Widget**: là tiến trình riêng, chỉ đọc. Làm mới bằng `WidgetCenter` khi app ghi và khi timeline hết hạn. Không dựa vào sự kiện giữa tiến trình.
- **Đánh đổi**: thay `ValueObservation` bằng tải lại theo phạm vi. Rủi ro đã nêu ở `ROADMAP.md` §6 và được đo ở S-1.
- **Thay thế cho**: Q-C (callback từ Go bị loại vì phức tạp và dễ lỗi ở ranh giới).
- **Trạng thái**: *Đã chốt, chờ đo S-1 (reload theo phạm vi giữ 60 fps).*

### ADR-25 — Monorepo và phạm vi nền tảng
- **Quyết định**: `core/` nằm ở gốc repo, là một Go module. Không xây target thứ hai trong M0 đến M3.
- **Điều kiện tái sử dụng**: giữ ADR-20, 21 và 22 để không khóa việc thêm nền tảng sau này.
- **Mở**: nền tảng tiếp theo (Android, web, Windows, Linux) là quyết định sản phẩm của PO, xét ở GATE-2. Tách repo khi có nền tảng thứ hai được lên lịch.
- **Trạng thái**: *Đã chốt.*

### ADR-26 — FSRS
- **Quyết định**: dùng thư viện FSRS Go nếu đạt S-2: khớp bộ test vector sinh từ triển khai tham chiếu với cùng tham số; hỗ trợ bước học ngắn; giấy phép tương thích; còn được bảo trì. Trượt bất kỳ tiêu chí nào thì tự cài trong `core/domain/fsrs` và dùng cùng bộ test vector.
- **Ràng buộc**: `Next(card, rating, now, settings)` là hàm thuần; không đọc đồng hồ, không ghi DB. `Preview` (FR-026) cũng là hàm thuần.
- **Thay thế cho**: Q-4.
- **Chưa xác minh**: tình trạng và giấy phép các thư viện FSRS Go hiện có. Việc này thuộc S-2.
- **Trạng thái**: *Đã chốt, chờ spike S-2.*

### ADR-27 — Kiểu ghi chú và field tùy biến theo deck
- **Bối cảnh**: khách hàng yêu cầu người dùng tự định nghĩa field cho deck, tương tự Anki (2026-10-28). Schema hiện tại cố định bốn cột trong `words`.
- **Quyết định**:
  1. Thêm `note_types`, `note_type_fields`, `card_templates`. `notes` thay `words`. `cards` là một thẻ học sinh từ note × mẫu thẻ. `card_states` và `review_logs` khóa theo `card_id` (spec §4).
  2. **Mỗi deck đúng một kiểu ghi chú** (`decks.note_type_id`). Không đổi kiểu của deck đã có từ trong M1–M3.
  3. **Mẫu thẻ không dùng HTML/CSS**: chọn danh sách field cho mặt trước, mặt sau và field làm đáp án Gõ từ. Giữ DESIGN native và a11y.
  4. Field có **`role`** (`term`, `reading`, `meaning`, `example`, `text`) và `input_kind` (`text`, `kana`). Mỗi kiểu có đúng một field `term` (bắt buộc); tối đa một field cho mỗi role còn lại trừ `text`. Chế độ học, kana, trùng từ, tìm kiếm dựa vào role, không dựa vào tên field.
  5. Giá trị lưu ở `notes.fields` dạng JSON, **khóa theo `field_id`**. Đổi tên field không đụng dữ liệu. Core tính `sort_field` và `search_text` khi ghi.
  6. Kiểu hệ thống **"Từ vựng Nhật"** (`is_system = 1`) ánh xạ 1–1 bốn cột cũ; không sửa trực tiếp, muốn tùy biến thì nhân bản.
  7. Giới hạn đề xuất (xác nhận ở M0b): tối đa 10 field mỗi kiểu; tên field 1–40 ký tự, duy nhất trong kiểu.
- **Chia pha**:
  - **Pha A — M1a**: schema tổng quát, migration, kiểu hệ thống, một mẫu thẻ mỗi kiểu; form thêm từ và thẻ học dựng theo định nghĩa kiểu; chưa có UI chỉnh.
  - **Pha B — M2–M3**: nhập/xuất theo field (M2); UI quản lý kiểu, field và mẫu thẻ (UC-31, M3).
  - **Pha C — M4 (backlog)**: cloze, nhiều mẫu thẻ cho một kiểu, nhiều kiểu trong một deck, template tự do.
- **Sửa ADR-04**: schema v2 không còn giữ nguyên. Backup lên **v3**; khôi phục vẫn nhận v2 của bản web bằng cách ánh xạ sang kiểu hệ thống. Bản web không đọc được v3.
- **Ước lượng thêm**: Pha A +1 đến 1,5 tuần-người; Pha B +2,5 đến 3,5 tuần-người. Đây là ước lượng chuyên môn, hiệu chỉnh ở GATE-1 (`ROADMAP.md`).
- **Cập nhật tài liệu**: `spec.md` §1, §3, §4, §6.1–6.2, §7.3–7.6, §12–14; `use-cases.md` UC-02, UC-03, UC-31, §7, §8; `ARCHITECTURE.md` §3, §6.1, §8, §13; `ROADMAP.md`. `DESIGN.md`, `COPY.md`, `WIREFRAME_PROMPT.md` bổ sung màn chỉnh field trước khi làm Pha B.
- **Trạng thái**: *Đã chốt* (PO duyệt 2026-10-28); hiệu năng tìm kiếm trên schema mới đo ở S-1.

### ADR-28 — Một DB cho mỗi profile
- **Bối cảnh**: PO xác nhận nhu cầu nhiều DB (2026-10-28): **tách ngôn ngữ học** và **giới hạn dung lượng** mỗi DB.
- **Quyết định**:
  1. Mỗi profile một file SQLite: `profiles/<profile_id>/hiraku.sqlite` trong App Group (ADR-06). Một profile thường ứng với một ngôn ngữ học.
  2. Danh sách profile và profile đang mở lưu ở Swift (`AppStorage` trong App Group), không nằm trong DB nào. Core không biết khái niệm profile; Swift truyền đường dẫn vào `hk_open`.
  3. Chuyển profile = `hk_close` rồi `hk_open` đường dẫn mới; mọi cửa sổ dùng cùng một profile tại một thời điểm.
  4. Hàng đợi, hạn mức từ mới/ngày, thống kê, settings FSRS tính **riêng theo profile**.
  5. Sao lưu, khôi phục, xuất, nhập theo profile; tệp backup ghi tên profile để người dùng nhận biết.
  6. "Giới hạn dung lượng" hiểu là mỗi DB nhỏ và độc lập, không phải hạn mức cứng. Màn dữ liệu (WP-23) hiện dung lượng từng profile. Không đặt hạn mức cứng; ngưỡng hiệu năng vẫn là 50.000 từ mỗi profile (S-1).
  7. Không tách DB theo deck (lý do ở Q-16).
- **Chia pha**: M1a chỉ có profile mặc định nhưng đường dẫn đã theo cấu trúc trên (chi phí gần bằng 0, nằm trong WP-02a). UI quản lý profile làm ở **M3** (WP-45, UC-32; Q-18 đã đóng).
- **Hệ quả**: widget (M4) đọc profile đang mở; kiểu ghi chú (ADR-27) thuộc từng profile, muốn dùng ở profile khác thì xuất/nhập.
- **Cập nhật tài liệu**: `spec.md` §3.1, §13; `ARCHITECTURE.md` §8; `ROADMAP.md` §9.
- **Trạng thái**: *Đã chốt* (PO duyệt 2026-10-28).

### ADR-29 — Đồng bộ iCloud là tùy chọn bật/tắt (M4)
- **Bối cảnh**: PO yêu cầu (2026-10-28) đồng bộ dữ liệu giữa Mac, iPad và iPhone cùng một tài khoản iCloud, người dùng tự chọn bật/tắt. Dữ liệu học không tạo lại được từ máy chủ, vì app không có máy chủ riêng.
- **Quyết định**:
  1. Đồng bộ là tính năng **tùy chọn**, **mặc định tắt**, bật/tắt trong Cài đặt (FR-092).
  2. Tắt không làm mất hay đổi dữ liệu trên máy; khi tắt, app không gọi CloudKit.
  3. Bật lại không tạo bản sao trùng lặp, dựa trên UUID và `updated_at`, `deleted_at` (ADR-04).
  4. Giữ ở M4, sau MR; không thuộc MVP (M1–M3). Lịch không đổi.
  5. Dữ liệu đồng bộ thuộc profile đang mở; không đồng bộ chéo profile (ADR-28).
- **Đã quyết (2026-10-29)**: (a) gộp theo field: field khác nhau gộp tự động; cùng field, `updated_at` mới hơn thắng; một bên xóa, bên kia sửa thì xóa thắng. (b) Tắt: dữ liệu trên iCloud giữ nguyên, không có thao tác xóa cloud. (c) Phạm vi bật/tắt: từng profile. (d) Bật lần đầu khi iCloud đã có dữ liệu: gộp tự động theo (a), không hỏi người dùng. (e) Danh sách profile lưu trên cloud.
- **Ràng buộc đã biết**: CloudKit cần mạng, nên mâu thuẫn ADR-12 và NFR-001 khi đồng bộ đang bật. ADR-12 (hệ quả) và NFR-001 đã sửa phần mạng, chỉ áp dụng khi người dùng bật. CloudKit cần tài khoản trả phí (ADR-17), nên test thật chỉ sau MR.
- **Hệ quả**: transport CloudKit thuộc Swift; logic đồng bộ và merge thuộc Go core, cần contract riêng (ADR-20, ADR-22). Core không import `net` (ADR-12).
- **Cập nhật tài liệu**: `spec.md` v3.10; `use-cases.md` v3.8 (UC-27); `DESIGN.md` v0.5.3 (Cài đặt); `ROADMAP.md` v1.8 (§6, §9). ADR-12 đã sửa phần hệ quả. ARCHITECTURE (mục đồng bộ) viết khi bắt đầu M4.
- **Trạng thái**: *Đã chốt (PO, 2026-10-28 và 2026-10-29).*

### ADR-30 — Kiến trúc đồng bộ iCloud: Go giữ DB và logic, Swift giữ CloudKit
- **Bối cảnh**: ADR-29 yêu cầu đồng bộ tùy chọn qua CloudKit. Có hai hướng: (B) GRDB + CKSyncEngine, SQLite và logic đồng bộ nằm trong Swift; (B') giữ SQLite trong Go (ADR-20, ADR-23), chỉ dùng CKSyncEngine trong Swift làm transport. PO chọn B' (2026-10-29).
- **Quyết định**:
  1. Không đổi ADR-20 và ADR-23. Không khôi phục GRDB (ADR-03 vẫn thay thế). Điều kiện S-1 và S-8 không đổi.
  2. Go core giữ: schema, change log (hàng đợi gửi), áp dụng thay đổi nhận về, merge theo ADR-29. Go không import `net` và không biết CloudKit.
  3. Swift giữ adapter CKSyncEngine: gửi và nhận record, trạng thái tài khoản iCloud, lỗi mạng và dung lượng. Swift truyền record qua contract protobuf `hiraku.v1` (ADR-22) và không mở DB.
  4. Mỗi profile một zone CloudKit (ADR-28). Danh sách profile là một record trên cloud (ADR-29).
  5. Ghi cục bộ và thêm vào hàng đợi gửi nằm trong cùng một transaction của core (luật 5 của AGENTS).
  6. Hệ điều hành tối thiểu giữ theo ADR-13 (iOS 26, macOS 26).
- **Hệ quả**:
  - Contract protobuf mới cho record đồng bộ và change log; kiểm bằng `buf breaking` (ADR-22).
  - Spike S-9 đầu M4: dựng adapter CKSyncEngine với mock và kiểm tra idempotent. Test thật trên iCloud chỉ sau MR (ADR-17).
  - Mục đồng bộ trong ARCHITECTURE viết khi bắt đầu M4.
  - Ước lượng 4–8 tuần trong ROADMAP §9 cần tính lại sau S-9.
- **Trạng thái**: *Đã chốt (PO, 2026-10-29).*

---

### ADR-31 — Vận hành AI Agents với OpenCode
- **Quyết định PO (2026-10-29)**: AI Agents thực hiện coding và chuẩn bị/ship sản phẩm; dùng bốn vai trò Điều phối, Coding, Review độc lập và Ship riêng. AI tự merge khi Review độc lập và CI đạt; PO giữ quyền duyệt cổng sản phẩm và phát hành.
- **Bộ cấu hình**: OpenCode 2.2.0; `hiraku-lead` primary, `hiraku-coder`, `hiraku-reviewer`, `hiraku-shipper` subagents. Chỉ Lead được gọi ba subagents, không giao việc vòng.
- **Skills**: chỉ `hiraku-contract` và `hiraku-feature` cho hai quy trình nhiều bước lặp lại. Không tạo skills task/core/design/review/delivery để lặp prompt agent hoặc tài liệu.
- **Công cụ phát triển**: Node.js 24+ và thư viện chuẩn cho guard/tests; plugin v2 dùng object `id`/`setup`, không thêm package npm. Không thêm dependency runtime của ứng dụng và không thay ADR-20…30.
- **Giới hạn**: guard/permissions không phải OS sandbox; môi trường coder/reviewer không có credential phát hành. Policy/checker chỉ thay qua bảo trì được PO duyệt, không cho agent tự sửa để qua kiểm tra.
- **Delivery**: chưa có Git/remote/CI nên quyền commit/push/merge/publish đóng. Chỉ mở entrypoint được bảo vệ sau khi có môi trường và bằng chứng đúng revision; không dùng admin bypass. Phát hành cần PO approval gắn version/commit/kênh/artifact thật.
- **Hệ quả**: `OPENCODE.md` giữ quy trình; task record giữ bàn giao; `TEST_PLAN.md` và `RELEASE.md` giữ checklist. Người thử và thiết bị thật vẫn cần; phần dự phòng/người thử của Q-29 chưa được tự chốt.
- **Trạng thái**: Đã chốt về mô hình vận hành; hạ tầng Git/CI và các gate sản phẩm vẫn phải được xác minh riêng.

---

## 4. Quyết định đề xuất và mở

### Q-11 — Thiết bị chuẩn đo hiệu năng · PO · GATE-0
- **Cần bạn cung cấp**: tên máy và OS của iPhone cũ nhất chạy được iOS 26 (từ iPhone 11 trở lên), một iPad (chip A12 trở lên), một Mac Apple silicon (M1 trở lên).
- **Dùng cho**: S-1 (dựng hàng đợi < 200 ms, tìm kiếm < 150 ms, cuộn 60 fps, khởi động < 1,5 s), S-8 (RSS, khởi động Go runtime), SC-006.

### Q-12 — Chia M1 thành M1a/M1b · PO · GATE-0
- **Phương án**: (A) M1 một khối, ba nền tảng cùng lúc; (B) **M1a** = lát cắt dọc P0 trên iPhone, **M1b** = vỏ iPad/Mac, `Table`, menu, đa cửa sổ.
- **Đề xuất**: B. Giảm rủi ro IME bị trải ra ba nền tảng cùng lúc; cho phản hồi sớm trên iPhone.
- **Hệ quả nếu B**: `ROADMAP.md` lập theo B. Nếu chọn A, gộp WP-11…WP-14 vào M1a và lịch M1a tăng tương ứng.

### Q-13 — Quy ước tên tài liệu · PO · GATE-0
- **Đã chốt (PO, 2026-10-29)**: bỏ hậu tố `_native-swift`; tên chuẩn `spec.md`, `use-cases.md`, `DESIGN.md`, `ARCHITECTURE.md`, `DECISIONS.md`, `ROADMAP.md`, `AGENTS.md`, `COPY.md`, `WIREFRAME_PROMPT.md`, `CHANGELOG.md`; đặt ở root repo, không dùng thư mục `Docs/` (trùng `docs/` trên macOS).

### Q-5 — Font tiếng Nhật · Design · GATE-1
- **Phương án**: (A) đóng gói Noto Sans JP (subset); (B) dùng Hiragino Sans hệ thống.
- **Đề xuất**: A để đúng nhận diện.
- **Tiêu chí (S-6)**: hiển thị đủ kana và kanji dùng trong JLPT N5–N1; kích thước app tăng không quá ngưỡng đề xuất 10 MB; giấy phép cho phép đóng gói. Vượt ngưỡng hoặc thiếu glyph → B.

### Q-8 — Phát hành macOS **[Cuối cùng]** · PO · GATE-3
- **Phương án**: (A) Mac App Store (App Sandbox, universal purchase); (B) phân phối trực tiếp (notarize).
- **Đề xuất**: A; bật App Sandbox từ M0 để phát hiện sớm hạn chế.
- **Tác động**: entitlement, cấu hình App Group (S-7), cơ chế cập nhật. Phát hành Mac App Store cần tư cách thành viên (ADR-17).

### Q-D2 — Màu chấm "Đang học" · Design · GATE-1
- **Bối cảnh**: `state-learning` (#D9A300) trên nền thẻ chỉ đạt 2,25:1 (ngưỡng 3:1 cho thành phần đồ họa mang thông tin).
- **Phương án**: (A) giữ màu, luôn kèm nhãn chữ/VoiceOver; (B) dùng `state-learning-ink` (#A67C00, 3,75:1) cho mọi chấm và chữ trạng thái trên nền sáng, giữ #D9A300 chỉ cho vùng tô lớn có chú giải; (C) giữ màu và thêm viền mực 1pt.
- **Đề xuất**: B.
- **Tác động**: một dòng trong bảng token của DESIGN; chốt trước khi đóng băng token ở WP-05.

### Q-7 — Dữ liệu Flutter cũ (FR-040) · PO · GATE-2
- **Câu hỏi cho bạn**: có dữ liệu thật trong bản Flutter cũ cần giữ không?
- **Đề xuất**: không có thì loại FR-040 khỏi backlog. Nếu có, ước lượng khoảng 1 tuần (chuyển id integer sang UUID, thực hiện trong Go core) và xếp vào cuối M2.

### Q-D5 — Cỡ body 15pt trên iPhone · Design · GATE-2
- **Đề xuất**: chấp nhận (thấp hơn 17pt mặc định của iOS, bù bằng Dynamic Type và `font_scale`). Kiểm tra đọc trên thiết bị thật cuối M1a; nếu khó đọc, tăng một bậc ở token.

### Q-19 — Vòng đời xóa mềm · PO · GATE-1
- **Vấn đề**: UI nói "xóa", MVP không khôi phục được (UC-01), thùng rác ở P2 (UC-23); chưa có chính sách xóa hẳn, kiểm tra trùng với bản đã xóa, hay backup có chứa dữ liệu đã xóa.
- **Đề xuất**: thùng rác giữ 30 ngày rồi xóa hẳn (UC-23 đã nêu 30 ngày làm ví dụ); backup v3 không chứa bản ghi đã xóa quá hạn; kiểm tra trùng bỏ qua bản đã xóa.

### Q-20 — Mã lỗi chi tiết · Tech · GATE-1
- **Vấn đề**: ADR-21 có 6 mã; mã 3 "vi phạm nghiệp vụ" chung, trong khi UI cần thông điệp riêng (trùng tên, quá 10 trường, thiếu vai trò…) và Go không trả chuỗi.
- **Đề xuất**: mã 3 kèm `sub_code` là enum trong contract; Swift ánh xạ sang String Catalog. Làm trước WP-02b.

### Q-21 — Chuẩn hóa Gõ từ · PO · GATE-1
- **Vấn đề**: §7.2 chấp nhận か = が, っ = つ, bỏ ー, nén ký tự lặp; đáp án sai chính tả vẫn đúng. Phản hồi từng ô khi chuỗi chuẩn hóa khác số ô chưa định nghĩa. Kiểu tùy biến chưa có quy tắc "đáp án rỗng thì dùng Từ".
- **Phương án**: (A) giữ dung sai hiện tại; (B) nghiêm với dakuten và っ, giữ dung sai ー và nguyên âm dài; (C) B kèm cài đặt chọn mức.

### Q-22 — Định nghĩa "Đã biết" · PO · GATE-1
- **Vấn đề**: "Đã biết" = state Review, nên thẻ vừa qua bước học đã tính là đã biết.
- **Phương án**: giữ; hoặc thêm ngưỡng khoảng ôn (ví dụ từ 21 ngày).

### Q-23 — Hướng thẻ và kiểu tùy biến · PO · GATE-2
- **Vấn đề**: UC-19 chưa khớp mẫu thẻ tùy biến (ADR-27) và Gõ từ; một `card_states` cho mọi hướng.
- **Đề xuất**: M3 chỉ áp dụng cho kiểu hệ thống; hướng riêng từng lịch thuộc Pha C.

### Q-24 — Phạm vi settings · Tech · GATE-1
- **Vấn đề**: bảng `settings` nằm trong DB theo profile (ADR-28) nên `font_scale`, `reminder_*` cũng đổi theo profile, dù là cài đặt cấp ứng dụng.
- **Đề xuất**: cài đặt cấp ứng dụng (`font_scale`, `reminder_*`) ở `AppStorage`; cài đặt học (FSRS, hạn mức, số nút, giờ bắt đầu ngày) ở DB theo profile.

### Q-25 — Danh sách profile và đồng bộ · Tech · trước S-9
- **Vấn đề**: ADR-28 giao danh sách profile cho Swift (core không biết profile); ADR-29(e) và ADR-30 coi đó là record cloud do Go merge. Khi bật đồng bộ, profile mặc định và deck mẫu tạo riêng mỗi máy (UUID khác) sẽ bị nhân đôi; "xóa thắng" kèm "không xóa cloud" làm bản ghi xóa tăng mãi; ADR-29(c) bật/tắt theo profile nhưng DESIGN chỉ có một công tắc.
- **Đề xuất**: quyết định trước S-9; dùng ID cố định cho profile mặc định và dữ liệu mẫu; nêu chính sách xóa profile và dọn bản ghi xóa.

### Q-26 — Nhập: "Ghi đè" và Shift-JIS · PO · GATE-2
- **Vấn đề**: "Ghi đè" có giữ tiến độ học không; CSV Shift-JIS chỉ cảnh báo, chưa nói có hỗ trợ không.
- **Đề xuất**: ghi đè nội dung field, giữ tiến độ học; Shift-JIS không hỗ trợ, hướng dẫn xuất lại UTF-8.

### Q-27 — Sao lưu sớm · PO · GATE-1
- **Vấn đề**: dữ liệu thật nằm trên bản ký Personal Team đến khoảng 09/2027 (ADR-17), sao lưu ở M2 sau MVP.
- **Đề xuất**: kéo WP-20 lên ngay sau M1a (+1,75 tuần trước M1b); thêm ca app bị treo/vào nền vào S-7 (WAL trong App Group).

### Q-28 — Thuật ngữ UI · PO, Design · GATE-1
- **Đã thống nhất**: "trường" thay "field" ở giao diện; "Câu ví dụ" là tên trường, "Ví dụ" là tên vai trò.
- **Còn mở**: "deck" hay "bộ thẻ"; giữ "profile" hay đổi. Ảnh hưởng toàn bộ String Catalog.

### Q-29 — Nhân lực và dự phòng · PO · GATE-0
- **Vấn đề**: lịch giả định một lập trình viên toàn thời gian thành thạo cả Go và Swift (ROADMAP §1); dự phòng M3 chỉ khoảng 2%; SC-002 cần người thử.
- **Đã chốt (PO, 2026-10-29)**: dùng AI Agents cho coding và ship, bốn vai trò theo ADR-31. Đây không phải xác nhận các ước lượng nhân lực/lịch cũ còn đúng.
- **Còn cần PO**: mức dự phòng; nhóm/người thử trước GATE-2. Không coi AI thay người thử cho SC-002 hoặc tự nghiệm thu trải nghiệm.

### Q-16 — Tổ chức DB *(đã đóng bởi ADR-28)*
- **Bối cảnh**: lo ngại một DB không đủ khi người dùng có nhiều deck.
- **Phân tích**: một SQLite chứa được rất nhiều deck; giới hạn thực tế là số note, đã có ngưỡng đo ở S-1 (50.000 từ). Tách mỗi deck một DB làm vỡ hàng đợi toàn app (FR-014), hạn mức từ mới/ngày, transaction khi chuyển từ giữa deck (FR-009); sao lưu và migration phải chạy N lần; `EventHub` phức tạp hơn.
- **Phương án**: (A) một DB; (B) mỗi deck một DB; (C) mỗi profile một DB.
- **Đề xuất**: C về cấu trúc, không làm UI ngay. M1a chỉ có profile mặc định, đặt DB tại `profiles/<profile_id>/hiraku.sqlite` trong App Group (ADR-06); `hk_open` đã nhận đường dẫn nên chi phí gần bằng 0. UI quản lý nhiều profile xếp M4 nếu PO xác nhận nhu cầu. Không chọn B.
- **Trả lời của PO (2026-10-28)**: tách ngôn ngữ và giới hạn dung lượng ⇒ chọn C (ADR-28). Chia sẻ deck nên giải bằng gói xuất/nhập deck (mở rộng M2), không bằng tách DB.
- **Tác động nếu C**: widget (M4) đọc profile đang chọn; sao lưu theo profile.

### Q-18 — Mốc làm UI quản lý profile *(đã đóng: M3, PO duyệt 2026-10-28)*
- **Bối cảnh**: ADR-28 cần UI để tạo, đổi tên, chuyển, xóa profile. Không có UI thì người dùng chưa tách được ngôn ngữ.
- **Phương án**: (A) M3, cạnh UC-31; (B) M4 backlog.
- **Đề xuất**: A, vì tách ngôn ngữ là nhu cầu đã xác nhận. Ước lượng thô của Tech Lead: khoảng 1 tuần-người; hiệu chỉnh ở GATE-1.

### Q-17 — Nhập gói `.apkg` của Anki *(đã đóng: backlog M4)*
- **Quyết định PO (2026-10-28)**: để ở backlog M4. Không đưa vào MVP. Định dạng có template HTML, nhiều kiểu trong một deck và media, vượt phạm vi Pha A/B của ADR-27. Chưa ước lượng.

### Q-6 — Đồng bộ iCloud · PO · đã đóng (2026-10-29)
- **Đã chốt (ADR-29, ADR-30)**: giữ ở M4; tùy chọn bật/tắt, mặc định tắt; gộp theo field, xóa thắng; khi tắt giữ dữ liệu trên iCloud; bật/tắt theo profile; danh sách profile lưu trên cloud; Go giữ DB và logic, Swift giữ CloudKit.
- **Lưu ý**: CloudKit cần truy cập mạng nên từng mâu thuẫn ADR-12 và NFR-001; hai quyết định này đã được sửa (ADR-29). Với ADR-20, đồng bộ là việc của Go core và phải có contract riêng. Ước lượng thô 4–8 tuần.

### Đã đóng trong v1.6 (tham chiếu)
- **Q-4** → ADR-26. **Q-A** → ADR-21 và ADR-23. **Q-B** → ADR-22. **Q-C** → ADR-24. **Q-D** và **Q-E** → ADR-25.

---

## 5. Điều kiện kích hoạt xem lại

| Kết quả spike | Quyết định bị ảnh hưởng | Hành động |
|---|---|---|
| S-1 không đạt NFR-002 với modernc | ADR-23 | Chuyển sang `mattn/go-sqlite3`; ghi ADR thay thế |
| S-1 cho thấy reload theo phạm vi làm rớt 60 fps | ADR-24 | Thu hẹp phạm vi reload; xem lại ADR-24 |
| S-2 không đạt | ADR-26 | Tự cài FSRS trong `core/domain/fsrs` |
| S-8 không đạt (build không ổn định hoặc rò bộ nhớ) | ADR-20, ADR-21 | Thử gomobile cho API nhỏ; nếu vẫn không đạt, quay lại GRDB và logic Swift theo ADR-03 |
| S-8 khởi động Go runtime vượt ngưỡng đề xuất | ADR-21 | PO xác nhận ngưỡng hoặc đánh giá lại widget (R-12) |
| S-1 hoặc S-8 không đạt, dẫn đến quay lại ADR-03 | ADR-03, ADR-20 | Khôi phục ADR-03; tính lại lịch (+2 đến 3 tuần-người, `ROADMAP.md` §6) |
| S-4 không đáp ứng | ADR-15 | Dùng thành phần gốc gần nhất và ghi lại |
| S-6 vượt ngưỡng font | Q-5 | Chuyển sang Hiragino Sans |
| S-1: tìm kiếm qua `notes.search_text` không đạt < 150 ms | ADR-27 | Thêm chỉ mục FTS5 cho `search_text`; nếu vẫn không đạt, xem lại cách lưu field |
| S-7 không đạt | ADR-06, Q-8, ADR-17 | Quay lại container thường; widget (FR-073) cần phương án khác |
| S-9 không đạt (adapter CKSyncEngine không ổn định với mock hoặc contract sync) | ADR-30, ADR-29 | Xem lại contract sync; nếu không khả thi, đánh giá lại tính năng đồng bộ ở M4 |
| Spike 0 không đạt (modernc không build cho iOS hoặc có `net` trong phụ thuộc) | ADR-23, ADR-12 | Chuyển sang `mattn/go-sqlite3` hoặc xử lý phụ thuộc; ghi ADR thay thế |
