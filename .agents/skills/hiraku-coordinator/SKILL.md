---
name: hiraku-coordinator
description: >-
  Điều phối một task hiraku từ WP đến PR đã review và merge: tạo task record, giao senior
  (hiraku-coding), mở PR, gọi review độc lập trong subagent built-in, rồi ship. Dùng khi PO giao
  mục tiêu hoặc task, khi resume một task đang dở, hoặc khi cần chạy cả chuỗi coding → review → merge.
compatibility: Node.js 24+; Git và gh đã đăng nhập; chạy từ root dự án.
---

Bạn điều phối, không viết mã sản phẩm. Đọc `AGENTS.md` và `docs/process/AGENT_WORKFLOW.md`,
sau đó chỉ mở mục tài liệu mà task nhắc tới.

## Quy trình

0. kickoff trước mỗi mốc M: chạy `task-context.mjs` cho mọi WP/spike thuộc M, tạo record
   mỏng + plan skeleton có checkbox từng slice (theo `hiraku-task` bước 7), tạo GitHub
   issues con, trình PO danh sách tiêu đề + labels để duyệt. Không tạo issue trùng,
   không giao senior khi task `blocked`.
1. Nạp `hiraku-task`, tạo hoặc cập nhật `.agents/tasks/<task-id>.md`. Task `blocked`
   (phụ thuộc chưa xong, hoặc Q trực tiếp còn Mở) thì dừng phần đó và hỏi PO đúng Q.
   Không giao senior khi còn blocker.
2. Cần đọc rộng hoặc lập kế hoạch: dùng built-in `Explore` hoặc `Plan` (chỉ đọc).
   Việc nhỏ (vài file, vài lệnh) tự làm bằng shell, không tạo subagent.
3. Giao senior: nạp `hiraku-coding` trong phiên này, với task record và plan làm task packet
   (mention cả hai paths; senior thực thi plan bằng executing-plans, cập nhật checkbox
   + ledger và bảng issues trong record).
   Một senior tại một thời điểm (Q-29). Chỉ chạy song song khi có worktree cô lập và
   không chồng file hoặc contract.
4. Khi senior báo `IMPLEMENTED` và đã push nhánh: nạp `hiraku-create-pr` để mở PR.
5. Review độc lập: gọi Agent tool của công cụ, không truyền `subagent_type` (ngữ cảnh mới, subagent dựng sẵn). Prompt gồm số PR,
   head SHA, đường dẫn task record, và dòng "nạp skill `hiraku-review`; không sửa file".
   Không tự review trong phiên đã viết mã.
6. Xử lý verdict:
   - `PASS` đúng SHA: sang bước 7.
   - `FAIL`: gửi findings cho senior trong cùng phiên (`hiraku-coding`). Senior sửa,
     push, SHA đổi. Quay bước 5 để review lại đúng SHA mới; PASS cũ hết hiệu lực.
   - Sau hai vòng vẫn không đạt: dừng, chẩn đoán nguyên nhân hoặc hỏi PO. Không bỏ
     test, không mở quyền, không lặp review vô hạn.
7. Nạp `hiraku-ship`. Ship trả `BLOCKED` thì báo lý do; không thử lại bằng cách khác.
   CI đang pending thì chờ và kiểm lại, không merge khi pending.
8. Sau merge: đối chiếu `[Unreleased]` và `hiraku-wp-status --check`. Lệch thì mở task
   `docs` để sửa.
9. Cập nhật task record: trạng thái, SHA, PR, lệnh kiểm tra đã chạy và kết quả.

## Giới hạn

- Không sửa source, CI, policy hay checker. Chỉ sửa task record và `.agents/tmp/`.
- Không tự review PR do phiên này viết.
- Không tag, không release, không merge khi thiếu PASS đúng SHA hoặc CI chưa xanh.
- Thao tác lặp lại qua nhiều task: đề xuất PO một skill trong `.agents/skills/`,
  không thêm agent.

## Đầu ra

`READY`, `BLOCKED`, `MERGED` hoặc `FAILED`, kèm task ID, SHA, số PR, kiểm tra đã
chạy và điều kiện còn thiếu. Chỉ báo `MERGED` khi đã xác nhận trạng thái PR thật.
