---
name: hiraku-task
description: Lead tạo hoặc cập nhật task record hiraku từ mẫu, tra WP/spike, phụ thuộc, Q chưa chốt và gate trước khi giao Coder; dùng khi giao task mới, resume hoặc chuyển trạng thái task.
compatibility: Node.js 24+; chạy từ root dự án.
---

## Quy trình

1. Lấy ngữ cảnh gọn thay vì đọc cả ROADMAP/DECISIONS:

   ```sh
   node .agents/skills/hiraku-task/scripts/task-context.mjs <WP-xx|S-x|Q-xx>
   ```

   Script in dòng WP, phụ thuộc, trạng thái §11, Q chưa chốt (trực tiếp hoặc qua
   phụ thuộc) và gate liên quan. Chỉ mở thêm mục tài liệu được dòng WP nhắc tới.
2. Quyết định có giao được không:
   - Phụ thuộc chưa `dn` hoặc Q trực tiếp còn **Mở/Đề xuất** ảnh hưởng hành vi →
     task `blocked`; hỏi PO đúng Q đó. Chỉ chặn phần bị ảnh hưởng, phần độc lập
     vẫn có thể tách task.
   - Q qua phụ thuộc: ghi vào "Blocking Q / gate" để Coder biết, không tự chốt.
3. Đặt `task-id` kebab-case theo mã: `<mốc>-<số>-<tóm-tắt>` cho spike
   (`m0-03-fsrs`), `wp-03-fsrs-grade` cho WP. Nhánh: `<type>/<task-id>`
   theo `docs/process/GIT_WORKFLOW.md` §1.
4. Tạo `.agents/tasks/<task-id>.md` từ `.agents/templates/task.md`, viết tiếng Anh.
   Điền đủ phần Contract: mục tiêu, ngoài phạm vi, file/module được sửa, tài liệu
   bắt buộc (đường dẫn + mục), Q/gate chặn, quyết định PO đã có (nguyên văn, nguồn).
5. Viết tiêu chí chấp nhận quan sát được, gồm ca lỗi/rollback và môi trường/thiết
   bị; không dùng "tests pass" thay mô tả hành vi. Điền bảng Checks với lệnh cụ thể,
   cột kết quả để `Not run`.
6. Ghi base: `git rev-parse develop` (hoặc working-tree). Đổi trạng thái WP bằng
   skill `hiraku-wp-status` (`rd`→`ip` khi Coder bắt đầu).
7. Resume: đọc lại record, so revision thực với record; revision đổi thì đánh dấu
   review/approval cũ hết hiệu lực trong "Next".

## Bàn giao và điều kiện dừng

Task packet cho Coder gồm: đường dẫn record, base, phạm vi file, tiêu chí, lệnh
kiểm tra và Q đang chặn. Thiếu thông tin hành vi hoặc Q trực tiếp chưa chốt thì
record ở `blocked`, trả BLOCKED kèm câu hỏi cụ thể cho PO, không giao Coder đoán.

Nếu đang review: dùng các bước như checklist để kiểm record đủ phạm vi, tiêu chí
và Q; không sửa record (việc của Lead).
