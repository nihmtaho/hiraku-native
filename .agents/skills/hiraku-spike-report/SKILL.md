---
name: hiraku-spike-report
description: Chạy một spike M0 của hiraku (S-0…S-8, ADR-15) và ghi bằng chứng vào docs/reports/M0_SPIKE.md theo một khuôn; dùng khi thực hiện hoặc báo cáo spike, đo hiệu năng hay kiểm chứng khả thi trước GATE-1.
compatibility: Toolchain theo spike (Go, Xcode, simulator, thiết bị thật); chạy từ root dự án.
---

## Đầu vào và nguồn

Nhận task packet có mã spike. Đọc đúng dòng spike trong `docs/product/spec.md` §3.3
(câu hỏi, tiêu chí đạt), `ROADMAP.md` §3.1 (nội dung, gate) và ADR/Q được nhắc.
Tiêu chí còn là "đề xuất, PO xác nhận" (ví dụ ngưỡng khởi động S-8) thì đo và ghi
số, không tự kết luận đạt theo ngưỡng chưa chốt.

## Quy trình

1. Viết ra trước khi chạy: câu hỏi, tiêu chí đạt (trích nguyên văn), môi trường
   cần (simulator, MacBook, iPhone/iPad thật), lệnh dự kiến.
2. Mã thử nghiệm để tách khỏi mã sản phẩm (`core/spike/`, `Spikes/<mã>/`), không
   import từ package sản phẩm sang spike ngược lại. Phụ thuộc mới vẫn cần ADR/PO.
3. Chạy từng lệnh, giữ exit code và output. Log thô vào `.agents/tmp/<mã>/`;
   artifact build vào thư mục build của module (gitignore). Báo cáo chỉ trích phần
   cần làm bằng chứng.
4. Ghi phiên bản toolchain và môi trường: Go, Xcode/SDK, OS, model máy, thư viện
   (bản thật đang dùng), revision (`git rev-parse HEAD` hoặc working-tree).
5. Gắn **mức xác minh** cho từng kết quả, không nâng mức:
   `build-only` · `simulator` · `MacBook` · `thiết bị chuẩn (Q-11)`. Thiếu thiết bị
   thì ghi "chưa xác minh trên thiết bị", không thay bằng simulator.
6. Kết luận mỗi hạng mục bằng một trong bốn: **Đạt**, **Không đạt**, **Chưa chạy**,
   **Bị chặn** (kèm Q/thiết bị chặn). Hai giá trị cuối không tính là đạt.
7. Thêm hoặc thay mục `## <mã>` trong `docs/reports/M0_SPIKE.md` theo
   `references/report-template.md`. Không xóa kết quả spike khác; chạy lại thì ghi
   ngày mới và giữ lý do thay đổi.
8. Spike trượt tiêu chí bắt buộc ở GATE-1 (S-1, S-3, S-8) thì nêu phương án lùi đã
   ghi trong spec/DECISIONS (ví dụ ADR-03 cho S-8) và dừng, chờ PO; không tự đổi
   kiến trúc.
9. Cập nhật trạng thái bằng skill `hiraku-wp-status` (`rv` khi chờ review).

## Bàn giao và điều kiện dừng

Trả: mã spike, bảng hạng mục → lệnh → exit → kết quả → mức xác minh, kết luận,
việc còn lại, Q cần PO. Thiếu thiết bị, toolchain hoặc tiêu chí chưa chốt thì
PARTIAL/BLOCKED, không báo Đạt.

Nếu đang review: đối chiếu báo cáo với tiêu chí spec §3.3, lệnh có thể chạy lại,
mức xác minh và số liệu; không chạy lại phép đo trên thiết bị thay người thử,
không sửa báo cáo.
