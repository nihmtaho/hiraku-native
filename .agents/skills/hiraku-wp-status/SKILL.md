---
name: hiraku-wp-status
description: Cập nhật trạng thái WP/spike/Q cho một PR hiraku cùng lúc ở ROADMAP.md §11, Kanban HTML và CHANGELOG [Unreleased]; dùng khi giao task, mở PR, merge hoặc bị chặn, và khi review cần kiểm ba nơi khớp.
compatibility: Node.js 24+; chạy từ root dự án.
---

## Khi nào

Mỗi lần trạng thái đổi theo `docs/process/GIT_WORKFLOW.md` §6: giao task (`rd`→`ip`),
mở PR (`ip`→`rv`), merge và WP đủ tiêu chí (`rv`→`dn`), bị chặn (giữ trạng thái,
ghi `--blk`). Năm giá trị: `bl` `rd` `ip` `rv` `dn`. Mã không có ở §11 là `bl`.

## Quy trình

1. Lấy mã chính xác như trong mảng `raw` của `ROADMAP hiraku — Kanban.html`
   (ví dụ `S-2`, `S-1 + S-7`, `WP-03`, `RV-04`). Không tự đặt mã mới; mã chưa có
   thẻ Kanban thì báo Lead.
2. Cập nhật hai nơi bằng một lệnh (script tách hàng gộp ở §11 nếu cần):

   ```sh
   node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs <mã> <trạng thái> \
     [--pr "#12"] [--note "phần còn lại / blocker"] [--blk Q-11 | --clear-blk]
   ```

   Đổi trạng thái thì luôn truyền `--note` mới; ghi chú cũ thường không còn đúng.
   Script báo lỗi khi không tìm thấy thẻ hoặc không ghi được note/blk: sửa tay
   đúng chỗ đó, không bỏ qua.
3. Với PR có thay đổi: thêm **một dòng** dưới nhóm đúng (`Thêm`, `Đổi`, `Sửa`, `Xóa`,
   `Tài liệu`, `Bảo mật`) trong `## [Unreleased]` của `CHANGELOG.md`, tiếng Việt,
   kết thúc bằng `(<mã>, PR <n>)`. Chưa có số PR thì ghi `PR —`, Shipper bổ sung.
   Không sửa phần lịch sử bên dưới `[Unreleased]`.
4. Kiểm tra khớp và đưa kết quả vào bàn giao:

   ```sh
   node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check
   ```

`dn` chỉ khi mọi tiêu chí ra của WP đạt; PR một phần giữ `ip` và ghi phần còn lại
trong note. Merge không đồng nghĩa milestone được PO nghiệm thu.

## Bàn giao và điều kiện dừng

Trả: mã, trạng thái cũ → mới, dòng CHANGELOG đã thêm, kết quả `--check`. Thiếu
thẻ Kanban, trạng thái mâu thuẫn tiêu chí ra hoặc Q đang chặn mà chưa ghi thì
BLOCKED, không đổi `dn` để cho qua.

Nếu đang review: chỉ chạy `--check` và đọc diff CHANGELOG; lệch hoặc thiếu dòng là
finding chặn. Không chạy lệnh cập nhật, không sửa file.
