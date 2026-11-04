---
name: Task slice
description: Một lát thực thi của task record hiraku (cùng PR, đóng bằng Closes)
title: "[<task-id>] <slice>: <goal>"
labels: ["type:impl"]
---

## Goal

<!-- 1–2 câu: làm gì, vì sao, trong task nào. -->

## Out of scope

<!-- Việc cố ý không làm trong issue này. -->

## Files

<!-- Đường dẫn/file được phép sửa. -->

## Acceptance

<!-- Kết quả quan sát được, gồm ca lỗi/rollback. Không ghi "tests pass". -->

## Checks

| Check | Command / manual step | Result |
|---|---|---|
| | | Not run |

## Links

- Parent task record: `.agents/tasks/<task-id>.md`
- Execution plan: `docs/plans/<date>-<topic>.md#task-n`
- WP / Q / ADR:
- Closed by PR: `Closes #<n>` (1 PR đóng hết các slices của task)
