---
name: hiraku-coding
description: Senior triển khai một task hiraku đã có task record: sửa Go, proto và Swift trong phạm vi, thêm test hành vi, cập nhật tài liệu, CHANGELOG và ROADMAP trên nhánh task, rồi commit và push. Dùng khi được giao code một task, khi sửa theo findings review, hoặc khi viết tiếp một task đang dở.
compatibility: Git; Go và Xcode theo core/go.mod và App; chạy từ root dự án.
---

Bạn triển khai một task packet. Đọc task record, `AGENTS.md`, `docs/process/AGENT_WORKFLOW.md`
và mục `docs/architecture/ARCHITECTURE.md` liên quan trước khi sửa mã.

## Quy trình

1. Thiếu task record hoặc quyết định Mở ảnh hưởng hành vi: trả `BLOCKED`, không đoán.
2. Kiểm trạng thái Git: nhánh, working tree, thay đổi có sẵn. Không ghi đè việc không phải
   của mình. Nhánh task đã có thì làm tiếp trên nhánh đó.
3. Nếu chưa có nhánh: tạo `<type>/<task-id>` từ `develop` (`docs/process/GIT_WORKFLOW.md` §1).
   Đổi WP sang `ip` bằng `hiraku-wp-status`.
4. Đổi contract: nạp `hiraku-contract`. Feature Swift mới: nạp `hiraku-feature`. Spike M0:
   nạp `hiraku-spike-report`. Việc khác: đọc tài liệu trực tiếp, không tạo lớp trừu tượng mới.
5. Chọn giải pháp đơn giản nhất đủ yêu cầu. Go giữ nghiệp vụ và transaction; Swift giữ UI
   và tích hợp OS. Không hard-code tên field thay vì role, không đưa profile vào core,
   không sửa tay `gen/` hoặc thư mục sinh.
6. Thêm test hành vi và ca lỗi. Chạy kiểm tra nhỏ nhất bao phủ thay đổi; mở rộng khi
   đụng contract hoặc bridge. Ghi lệnh và exit code.
7. Đổi hành vi thì cập nhật spec, UC và DESIGN cùng lúc. Trong cùng nhánh: thêm dòng
   `[Unreleased]` ở `CHANGELOG.md`, đổi trạng thái WP ở `ROADMAP.md` §11 và Kanban bằng
   `hiraku-wp-status`.
8. Commit nhỏ, theo skill `git-commit`. Không `--amend`, không `--no-verify`.
   Push: `git push -u origin <type>/<task-id>`.
9. Sửa theo findings review: sửa trong phạm vi, commit mới, push. Nếu cần rebase:
   `git rebase develop`, rồi `git push --force-with-lease origin <nhánh-task>`. Chỉ trên
   nhánh task. Không force lên `develop` hoặc `main`; không dùng `--force` trần.
10. Cập nhật task record: trạng thái, revision, file đã đổi, lệnh đã chạy kèm exit code.

## Giới hạn

- Không mở PR (việc của `hiraku-create-pr`), không merge, tag, release, không đọc signing secrets.
- Không sửa CI, checker, `AGENTS.md`, `docs/process/`, DECISIONS. Không sửa golden hoặc
  migration đã phát hành chỉ để test xanh.
- Phụ thuộc mới hoặc quyết định Mở: hỏi coordinator hoặc PO trước khi cài hay áp dụng.
- Kiểm tra chưa chạy hoặc bị skip ghi là `Not run`, không báo PASS.
- Test và build chạy code của repo; không dùng credential phát hành hay mạng ngoài phạm vi được cho phép.

## Đầu ra

`IMPLEMENTED`, `PARTIAL` hoặc `BLOCKED`, kèm task ID, nhánh và SHA, file đã đổi, tiêu
chí đã đáp ứng, lệnh và exit code, phần chưa xác minh, Q cần quyết định. Không tự tuyên bố merged.
