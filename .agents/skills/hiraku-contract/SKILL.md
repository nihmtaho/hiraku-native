---
name: hiraku-contract
description: Thêm hoặc sửa RPC/protobuf hiraku.v1 xuyên Go service, FFI, HirakuBridge, model/fake và golden; dùng khi thay contract hoặc role field, không dùng cho sửa nội bộ không đổi contract.
compatibility: OpenCode 2.2; Go, buf và Xcode khi đã bootstrap theo WP-01.
---

## Đầu vào và nguồn

Nhận task packet, base revision, hành vi cần đổi và baseline protobuf. Đường dẫn
trong các bước dưới tính từ root dự án, không phải thư mục skill.

Đọc `docs/architecture/ARCHITECTURE.md` §6, §7, §11–14; ADR-21/22 và ADR liên quan trong
`docs/architecture/DECISIONS.md`; phần spec/UC của task. Q mã lỗi hoặc nghiệp vụ chưa chốt ảnh
hưởng task thì báo BLOCKED trước khi chọn schema.

## Quy trình

1. Liệt kê message/method, caller và bên nhận cần đổi. Xác định tương thích, lỗi,
   now_ms, transaction và ChangeSet. Core không biết profile/CloudKit.
2. Sửa nguồn `core/proto/hiraku/v1`; thêm số mới, không tái dùng field/method/enum
   number đã dùng. Khi bỏ field, reserve theo quy ước contract đã có.
3. Chạy `buf lint`, generator của repo và `buf breaking` với baseline được chỉ
   rõ trong task/CI. Đọc cấu hình buf để chạy đúng thư mục; không tự đoán main
   hoặc baseline rỗng. Contract đầu tiên phải ghi rõ chưa có baseline, không
   báo breaking PASS giả.
4. Cài logic thuần ở domain, điều phối/transaction ở service; nối dispatch FFI.
   Bảo vệ panic và ownership hk_open/hk_call/hk_free/hk_close; không để Go gọi
   ngược Swift hoặc Swift tự mở DB.
5. Nối proto ↔ model/error trong HirakuBridge, protocol ở HirakuModels, fake ở
   HirakuTesting và Controller dùng RPC. Phát ChangeSet/EventHub đúng phạm vi.
6. Thêm/cập nhật golden proto bytes dùng chung và test Go/Swift cho thành công,
   lỗi và trường hợp tương thích. Đổi golden có giải thích hành vi, không chỉ
   regenerate để che hồi quy. Không sửa tay thư mục generated.
7. Chạy test core, bridge integration và Controller liên quan; thay ABI/build
   thì kiểm tra XCFramework thực. Ghi lệnh, môi trường và kết quả từng phía.
8. Cập nhật spec/UC/DESIGN khi đổi hành vi; đổi phá vỡ cần PO duyệt ADR trước.

## Bàn giao và điều kiện dừng

Trả bảng: bề mặt thay đổi → file → kiểm tra → kết quả; kèm baseline, revision,
golden và rủi ro tương thích. Thiếu tool, generator, baseline, fake hoặc test
bắt buộc thì nêu rõ BLOCKED/PARTIAL, không tự viết payload Swift thay proto.

Nếu đang review: dùng các bước như checklist read-only; không chạy generator,
đổi golden hoặc sửa source. Verdict theo prompt Reviewer.
