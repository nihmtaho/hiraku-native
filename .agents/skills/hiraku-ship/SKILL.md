---
name: hiraku-ship
description: Merge một PR hiraku đã có verdict PASS trên đúng head SHA bằng gh pr merge (squash). Dùng khi coordinator có PASS và quyết định merge, hoặc hỏi PR đã sẵn sàng merge chưa. Không dùng để tag hay phát hành.
compatibility: gh đã đăng nhập; chạy từ root dự án.
---

## Quy trình

1. Lấy trạng thái: `gh pr view <pr> --json headRefOid,baseRefName,isDraft,state,statusCheckRollup`.
   - Head khác SHA đã có verdict PASS: dừng và báo coordinator review lại SHA mới.
   - Check `ci` đang pending: chờ rồi kiểm lại. Check fail: báo senior sửa.
2. Kiểm `[Unreleased]` trong CHANGELOG và `hiraku-wp-status --check`. Lệch thì báo coordinator
   trước khi merge.
3. Merge đúng SHA đã review:
   `gh pr merge <pr> --squash --match-head-commit <head-sha>`.
4. Nếu GitHub từ chối (ví dụ thiếu check bắt buộc của ruleset), báo nguyên văn lỗi. Không
   lặp lệnh và không dùng admin bypass.
5. Sau khi lệnh thành công, xác nhận: `gh pr view <pr> --json state,mergeCommit`.
   - `MERGED`: báo `MERGED` kèm SHA merge.
   - Vẫn `OPEN`: báo `AUTO_MERGE_PENDING` hoặc lỗi, không báo merged.
6. Ghi PR, SHA và kết quả vào task record.

## Giới hạn

- Không tag, không release, không đổi version, không đẩy commit sau review.
- Không báo PASS cho kiểm tra chưa chạy.

## Đầu ra

`MERGED`, `AUTO_MERGE_PENDING` hoặc `BLOCKED` (kèm lý do nguyên văn), với số PR, SHA và lệnh đã chạy.
