# AGENTS.md — hiraku

App học từ vựng tiếng Nhật (FSRS). Logic và dữ liệu ở Go core (`core/`); UI ở Swift (iOS/iPadOS/macOS 26+, Apple silicon). Offline mặc định, không tài khoản riêng; đồng bộ iCloud là tùy chọn, mặc định tắt, từ M4 (ADR-29). UI tiếng Việt. Giai đoạn: M0 (spike), chưa có mã.

## Đọc trước (theo mã, đừng đọc cả file)
- `docs/architecture/ARCHITECTURE.md` v2.2: luật Swift (L1–L11), luật Go (G1–G8), checklist §13. **Bắt buộc** cho mọi thay đổi mã.
- `docs/architecture/DECISIONS.md`: ADR-20…30 đã chốt (ADR-27 field tùy biến, ADR-28 profile, ADR-29/30 đồng bộ iCloud); Q mở và đã đóng.
- `docs/product/spec.md`, `docs/product/use-cases.md`, `docs/product/DESIGN.md`, `ROADMAP.md`: đọc theo mục liên quan.
- `COPY.md`: chuỗi UI, đọc khi thêm hoặc sửa chuỗi. `docs/product/WIREFRAME_PROMPT.md`, `CHANGELOG.md`: không cần khi viết mã.
- `PROJECT.md`: điểm vào cho skill Flowkit (trạng thái, Git & PR, checks, docs map); kit phân phối ở `.tmp/flowkit/`.

## Nơi đặt file
- Root chỉ có `AGENTS.md`, `PROJECT.md`, `CHANGELOG.md`, `COPY.md`, `ROADMAP.md`, Kanban. Tài liệu ở `docs/` (kế hoạch `docs/plans/`, kết quả `docs/reports/`; xem `docs/README.md`). File tạm, log của AI: `.agents/tmp/`.

## Ranh giới Go và Swift
- Go (`core/`) sở hữu: FSRS, kana, hàng đợi, ngày học, transaction chấm điểm, schema, migration, truy vấn, parser, sao lưu, kiểm tra kiểu ghi chú và note (`domain/notetype`), `sort_field`/`search_text`.
- Swift sở hữu thêm: danh sách profile và profile đang mở (`AppStorage` App Group); chọn đường dẫn DB cho `hk_open`.
- Swift sở hữu: SwiftUI, Controller, Route, DesignSystem, StudyKit (UI), tích hợp OS, adapter CKSyncEngine (transport CloudKit, ADR-30). Go sở hữu change log và merge của đồng bộ; core không import `net`.
- Nếu đoạn logic không cần biết đang chạy trên Apple, nó thuộc Go.

## Luật cứng
1. Contract: `core/proto/hiraku/v1` là nguồn duy nhất. Không sửa tay `gen/` (Go) hoặc thư mục sinh của Swift. Không tái dùng field number.
2. Chỉ `core/ffi` được import `"C"`. Chỉ `HirakuBridge` gọi `hk_*`.
3. Go: không `time.Now()` trong `domain`/`service` (thời gian đến qua `now_ms`); không `net`; không biến toàn cục; không `unsafe` ngoài `ffi`.
4. Swift: Feature chỉ import `HirakuModels`, `DesignSystem` (và `StudyKit` với feature học). Không import `HirakuBridge` hay feature khác.
5. Mọi ghi nhiều bảng nằm trong một transaction của core. Swift không có transaction.
6. Thời gian: `AppClock` ở Swift cấp `now_ms`. Không `Date()` hay `Task.sleep` trực tiếp trong Controller.
7. UI: token `HK*`, `AppIcon` (SF Symbols), String Catalog tiếng Việt. Không hard-code màu, chuỗi, cỡ chữ.
8. Phụ thuộc mới cần ADR. Đã chốt: `github.com/mattn/go-sqlite3` (ADR-32), `swift-protobuf`, `google.golang.org/protobuf`, buf (ADR-22). GRDB đã bỏ (ADR-20).
9. Swift 6 strict; không `try!`, force unwrap trong logic nghiệp vụ.
10. Field tùy biến (ADR-27): không hard-code bốn field cũ (`word`, `reading`, `meaning`, `example`) ngoài định nghĩa kiểu hệ thống. Logic học, gõ từ, trùng từ, tìm kiếm, kiểu chữ chọn theo **role**, không theo tên field. Giá trị khóa theo `field_id`. Swift không parse `notes.fields`. FSRS và log khóa theo `card_id`, không `word_id`.
11. Profile (ADR-28): core không biết khái niệm profile, không tự chọn đường dẫn. Không tách DB theo deck. Không truy vấn chéo profile; mọi dữ liệu (hàng đợi, settings, thống kê, sao lưu) là của profile đang mở.
12. Tên field và tên profile do người dùng đặt là dữ liệu, không vào String Catalog.

## Phong cách mã (C1–C8, áp dụng cho cả Go và Swift; chi tiết ARCHITECTURE §4.4)
- Đơn giản trước; không trừu tượng "để sau"; không mã cao siêu.
- Hàm ngắn, tên rõ, return sớm, lồng tối đa 3 cấp.
- Dùng sẵn thư viện chuẩn và framework.
- Chỉ sửa phần được yêu cầu.
- Comment một dòng, **viết bằng tiếng Anh**, chỉ giải thích *vì sao*. Cấm: mô tả lại mã; nhắc FR, UC, ADR, WP; lịch sử; khối dài. Ngoại lệ: `// TODO(Q-xx): …`.
- Không `print` (Swift) hoặc `fmt.Println` còn lại; không mã chết; không import thừa.
- Test hành vi, ngắn, mỗi test một ý.

## Quy trình
- Quy trình agent: `docs/process/AGENT_WORKFLOW.md`. Không dùng agent tùy chỉnh; điều phối bằng skill `flow-coordinator`; đọc và lập kế hoạch dùng built-in `Explore`/`Plan`; review độc lập chạy trong subagent dựng sẵn của công cụ.
- Skills: `flow-coordinator` (điều phối task), `flow-task` (tạo task), `flow-implement` (senior), `flow-pr`, `flow-review`, `flow-ship`, `flow-status` (CHANGELOG + ROADMAP §11 + Kanban), `flow-interface` (RPC/proto/FFI/bridge), `flow-feature` (feature/StudyMode), `flow-debug` (sửa lỗi), `flow-spike` (spike M0), `product-review` (review spec/PRD); quản lý sản phẩm: `write-spec`, `sprint-planning`, `roadmap-update`, `stakeholder-update`, `synthesize-research`, `competitive-brief`, `metrics-review`, `product-brainstorming`. Quy trình lặp lại mới thì viết skill trong `.agents/skills/`, không thêm agent.
- Delivery: `flow-implement` commit/push nhánh task và mở PR vào `develop` bằng `flow-pr`; `flow-review` trả verdict độc lập; `flow-ship` merge bằng `gh pr merge --squash --match-head-commit <sha>` sau PASS đúng SHA (quy ước, không có script chặn; ADR-33 cần amendment). PR chạm policy/checker nên do người vận hành review trước khi merge; tag/phát hành vẫn đóng. Không báo PASS/merged khi kiểm tra chưa chạy.
- Không ghi "Generated by AI", đồng tác giả AI hay biểu tượng robot trong commit, tiêu đề và body PR (quy ước trong skill `flow-pr`, không có bước kiểm tự động).
- Git: `docs/process/GIT_WORKFLOW.md`; mỗi PR cập nhật `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11 và Kanban qua `flow-status`, trừ thay đổi không có work item, khi đó ghi lý do trong PR body (xem `PROJECT.md` §Quality rules).
- Quyết định **Mở** trong DECISIONS: hỏi người dùng. Đổi contract: `buf breaking`, golden, ADR nếu phá vỡ. Đổi hành vi: cập nhật spec, UC, DESIGN.
- Chưa có Apple Developer (ADR-17): dùng Personal Team.

## Lệnh (tạo ở WP-01; chưa chạy được)
- `core/scripts/check-core.sh` — cấm `net`, `time.Now` trong domain/service, `import "C"` ngoài ffi
- `core/scripts/build-xcframework.sh` — build c-archive và đóng XCFramework
- `buf lint`, `buf breaking` — kiểm contract
- `cd core && go test -race ./...` — test core
- `Scripts/check-imports.sh` — luật import Swift
- `xcodebuild test -scheme Hiraku -destination '<iOS 26 simulator | macOS>'` — test app

Tài liệu và chuỗi UI: tiếng Việt. Định danh, comment, PR và template: tiếng Anh.
