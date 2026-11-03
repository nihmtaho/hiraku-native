---
name: hiraku-review
description: Review độc lập một PR hoặc diff hiraku theo đúng head SHA: đối chiếu task và luật kiến trúc, chạy kiểm tra, rồi trả verdict PASS hoặc FAIL cho coordinator. Dùng khi coordinator giao review một PR, hoặc khi cần kiểm một SHA trước khi merge. Chạy trong phiên độc lập, không phải phiên đã viết mã.
compatibility: gh đã đăng nhập; Node.js 24+; chạy từ root dự án.
---

Bạn review độc lập và không sửa gì. Báo cáo của senior chỉ là manh mối, không thay việc
đọc diff và luồng gọi.

## Quy trình

1. Xác nhận phiên này không viết mã của PR. Nếu đã viết, dừng và báo coordinator: verdict
   từ phiên đó không được ghi.
2. Lấy đúng SHA: `gh pr view <pr> --json headRefOid,baseRefName,state`. Head khác SHA được
   giao thì dừng và báo head đã đổi.
3. Đọc task record, phạm vi, tiêu chí, và diff của SHA đó (`gh pr diff <pr>`). Đọc caller và
   callee cần thiết.
4. Đối chiếu:
   - file ngoài phạm vi task, hoặc Q chưa chốt bị bỏ qua;
   - lỗi nghiệp vụ, mất dữ liệu, atomicity, concurrency và lifetime, lỗi và hủy, wiring thiếu;
   - luật `docs/architecture/ARCHITECTURE.md` (L1–L11, G1–G8) theo phần bị tác động;
   - field theo role, `field_id`, `card_id`; cách ly profile; `now_ms`; tương thích contract.
5. Contract hoặc feature: nạp `hiraku-contract` hoặc `hiraku-feature` để rà checklist. Không
   thực hiện bước ghi hay sinh mã trong skill.
6. Kiểm tra bắt buộc: diff có dòng `[Unreleased]`; trạng thái WP khớp giữa ROADMAP §11 và
   Kanban (`node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check`). Thiếu hoặc lệch là finding chặn.
7. Chạy test liên quan: `cd core && go test -race ./...` cho Go; `xcodebuild test` khi có
   Swift. Ghi lệnh và exit code. Chưa chạy thì ghi `Not run`.
8. Chọn verdict:
   - `PASS`: đủ bằng chứng, không còn finding chặn, và đã đọc đúng SHA.
   - `FAIL`: có finding với file và dòng, mức độ, đường tái hiện, và kiểm tra cần thêm.
   - `BLOCKED`: thiếu quyết định, môi trường, diff hoặc kiểm tra bắt buộc. Không ghi verdict.
9. Trả coordinator: verdict, SHA, findings, lệnh đã chạy kèm exit code, phần chưa xác minh.
   Không đăng status lên GitHub; coordinator quyết định từ verdict này.

## Giới hạn

- Không sửa source, golden, policy, task record hay PR. Không commit, không push.
- File tạm đặt ở `.agents/tmp/`.
- Không đề xuất refactor theo sở thích. Grep hoặc unit test không thay được review thủ công
  cho quy tắc cần đọc.
- Không ghi `PASS` cho SHA chưa đọc diff hoặc khi kiểm tra chưa chạy.
- Không merge, không gọi `gh pr review` hay `gh api`.

## Đầu ra

Một khối gồm: `verdict`, `pr`, `sha`, findings (file:dòng, mức độ, cách tái hiện), lệnh đã
chạy kèm exit code, và phần chưa xác minh.
