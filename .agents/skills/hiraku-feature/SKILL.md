---
name: hiraku-feature
description: Thêm feature Swift Package hoặc chế độ học mới của hiraku, nối Dependencies, Controller/test, View, Route/composition và resources; không dùng cho sửa nhỏ trong feature đã có.
compatibility: OpenCode 2.2; Swift 6 và Xcode sau WP-01.
---

## Đầu vào và nguồn

Nhận task packet có UC/SC, milestone, phạm vi nền tảng và API core cần dùng.
Đường dẫn trong các bước dưới tính từ root dự án.

Đọc `docs/architecture/ARCHITECTURE.md` §3–5, §9–14; phần spec §2.4 và UC liên quan; DESIGN/COPY
theo màn cần làm. Chưa có quyết định nghiệp vụ thì không cài tạm trong Swift.

## Quy trình

1. Kiểm tra feature đã có và module được ROADMAP duyệt. Ưu tiên mở rộng feature
   hiện tại; không tự thêm package chỉ để chia nhỏ file.
2. Tạo `Packages/Features/FeatureX` với Model/View/Controller và Tests theo mẫu.
   Package chỉ phụ thuộc module được phép; khai báo cả HirakuTesting trong
   package dependencies và test target nếu dùng fake.
3. Định nghĩa Dependencies bằng protocol và entrypoint công khai. Nghiệp vụ
   không cần Apple thuộc Go. Nếu thiếu RPC, dùng `hiraku-contract` và giữ thứ tự
   phụ thuộc; không tự parse notes.fields hoặc truy vấn DB từ Swift.
4. Viết Controller @MainActor/@Observable nhận phụ thuộc qua init, không I/O
   trong init. Nạp ở start(), hủy task ở stop(); dùng AppClock và fake để test
   thành công, lỗi, hủy và không chuyển bước khi ghi thất bại.
5. Viết View thụ động; dùng HK*, AppIcon, String Catalog tiếng Việt và chrome
   gốc. Tên field/profile người dùng đặt là dữ liệu, không đưa vào catalog.
6. Nối Route ở HirakuModels, ánh xạ và Dependencies tại App/Composition; ghép
   qua route/closure/slot, không import feature khác hay HirakuBridge.
   Chế độ học mới cài StudyMode và đăng ký FeatureRegistry, không sửa
   FeatureStudy để biết concrete mode.
7. Kiểm tra layout trong phạm vi milestone, focus/IME, Dynamic Type/VoiceOver,
   Reduce Motion và lỗi/empty/loading. Ghi rõ nền tảng chưa triển khai theo task;
   không tuyên bố simulator đã thay nghiệm thu thiết bị thật.
8. Cập nhật import rules và bảng module/feature khi thực sự thêm module; cập nhật
   spec/UC/DESIGN/COPY theo thay đổi. Policy/checker bị bảo vệ thì trả thay đổi
   cần PO/người vận hành áp dụng, không vượt guard.
9. Chạy test package độc lập với fake, check-imports và App integration/XCUITest
   liên quan. Kiểm tra độc lập package không yêu cầu link core thật.

## SwiftUI trong khuôn MVC

Không thay mô hình Controller/View ở ARCHITECTURE §5; chỉ là mẹo trong khuôn đó
(rút gọn từ `swiftui-patterns` của affaan-m/ecc, MIT, commit `b38be6a`):

- Wrapper đơn giản nhất: `@State` cho trạng thái riêng của View (sheet, focus),
  `@Bindable` cho Controller được truyền vào, `@Environment(Type.self)` thay
  `@EnvironmentObject`; không dùng `ObservableObject`/`@Published` mới.
- Tách subview nhỏ, truyền giá trị thay vì cả Controller, để chỉ phần đọc thuộc
  tính đổi mới vẽ lại.
- `List`/`ForEach` dùng `id` ổn định (ID kiểu bọc), không dùng index; không tính
  toán nặng hay format trong `body`, đưa vào Controller.
- `.task` gọi `controller.start()`; hủy theo vòng đời View, không tự giữ `Task`.
- Preview dựng Controller với fake từ `HirakuTesting`.

## Bàn giao và điều kiện dừng

Trả entrypoint, wiring, resources, tests và bằng chứng theo tiêu chí task.
Thiếu API, quyết định, toolchain hoặc kiểm tra bắt buộc thì ghi PARTIAL/BLOCKED,
không thêm singleton, mock vào sản phẩm hoặc bypass concurrency để build được.

Nếu đang review: chỉ đối chiếu checklist và chạy test được cấp quyền; không
tạo package, cập nhật import rules hoặc sửa source.
