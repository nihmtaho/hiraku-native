---
name: hiraku-ship
description: Kiểm điều kiện merge một PR hiraku đã có verdict PASS đúng SHA, rồi bật auto-merge squash qua delivery.mjs; báo BLOCKED nếu thiếu điều kiện. Dùng khi coordinator có PASS và cần merge, hoặc hỏi PR đã sẵn sàng merge chưa. Không dùng để tag hay phát hành.
compatibility: gh đã đăng nhập; quyền merge theo ruleset; chạy từ root dự án.
---

## Quy trình

1. Lấy trạng thái PR: `gh pr view <pr> --json headRefOid,baseRefName,isDraft,state,statusCheckRollup,files`.
   Bất kỳ điều kiện nào dưới đây không đạt thì trả `BLOCKED`:
   - head khác SHA đã review;
   - base không phải `develop`, PR là draft, hoặc PR không còn mở;
   - status `hiraku/review` chưa là success trên đúng SHA;
   - check `ci` chưa xanh. Đang pending thì chờ rồi kiểm lại, không merge khi pending.
     Check fail thì báo senior sửa.
2. Kiểm policy và checker bằng danh sách file: nếu có file trong `AGENTS.md`,
   `docs/process/`, `docs/architecture/DECISIONS.md`, `.github/`, `.agents/` (trừ `.agents/tasks/`),
   cấu hình công cụ agent (`.claude/`, `.opencode/`, `.pi/`, `.commandcode/`, `opencode.json`),
   script `check-*`, `build-xcframework.sh`, hoặc thư mục `gen/` và `generated/`, thì trả
   `BLOCKED` và chuyển người vận hành merge. Bước này thay cho kiểm của guard đã gỡ.
3. Kiểm `[Unreleased]` trong CHANGELOG và `hiraku-wp-status --check`. Lệch thì `BLOCKED`.
4. Đủ điều kiện, chạy:
   `node .agents/hiraku/delivery.mjs merge <pr> --sha <head-sha>`.
   Script kiểm lại base, head, status `hiraku/review` và `ci`, rồi bật auto-merge squash
   có `--match-head-commit`.
5. Script báo lỗi: trả `BLOCKED` kèm lý do nguyên văn. Không lặp lệnh, không `gh pr merge`
   trực tiếp, không `gh api`, không dùng admin bypass.
6. Sau khi bật auto-merge, kiểm lại: `gh pr view <pr> --json state,mergeCommit`.
   - `MERGED`: báo `MERGED` kèm SHA merge.
   - Vẫn `OPEN`: báo `AUTO_MERGE_PENDING`. Không báo merged.
7. Ghi PR, SHA và kết quả vào task record.

## Giới hạn

- Không tag, không release, không đổi version, không đẩy commit sau review.
- Không báo `PASS` cho kiểm tra chưa chạy.

## Đầu ra

`MERGED`, `AUTO_MERGE_PENDING` hoặc `BLOCKED` (kèm lý do), với số PR, SHA và lệnh đã chạy.
