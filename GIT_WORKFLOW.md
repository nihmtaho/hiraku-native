# Git workflow — hiraku (Agentic AI Coding)

Một luồng duy nhất cho mọi agent. Bổ sung `OPENCODE.md` §2 và §4; không mở thêm quyền.
Skills Git dùng chung ở `.agents/skills/` (`git-branch`, `git-commit`, `git-pr`, `git-rebase`, `git-release`, `changelog`, `git-hooks`).

## 1. Nhánh

| Nhánh | Vai trò | Ai ghi |
|---|---|---|
| `main` | Luôn phát hành được; chỉ nhận merge từ `release/*` và `hotfix/*`. Mỗi tag `vX.Y.Z` nằm trên `main`. | Chỉ qua PR đã bảo vệ |
| `develop` | Nhánh tích hợp; mọi task merge vào đây. | Chỉ qua PR đã bảo vệ |
| `<type>/<task-id>-<tóm-tắt>` | Một task = một nhánh = một PR, tạo từ `develop`. | Coder |
| `release/vX.Y.Z` | Cắt từ `develop` khi PO duyệt gate; chỉ sửa lỗi và đổi version. | Coder theo task của Lead |
| `hotfix/<tóm-tắt>` | Cắt từ `main`, merge về `main` rồi về `develop`. | Coder theo task của Lead |

`type`: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `release`, `hotfix`. Ví dụ `feat/wp-03-fsrs-grade`.

Tạo nhánh **luôn** chỉ rõ base, vì script tự dò sẽ chọn `main`:

```sh
.agents/skills/git-branch/scripts/new-branch.sh -b develop feat wp-03 fsrs grade
```

## 2. Vòng đời một task (khớp trạng thái task record)

| Bước | Trạng thái | Việc | Chủ |
|---|---|---|---|
| 1 | `ready` | Lead tạo task record; ghi WP/gate/Q, base = `develop` | Lead |
| 2 | `coding` | Tạo nhánh; commit nhỏ; cập nhật **trong cùng nhánh**: tài liệu liên quan, `CHANGELOG.md` (`[Unreleased]`), trạng thái WP ở `ROADMAP.md` và Kanban | Coder |
| 3 | `review` | Mở PR vào `develop` theo `.github/pull_request_template.md`; Reviewer độc lập kiểm diff **và** mục §3 | Reviewer |
| 4 | `ready-to-merge` | Review PASS đúng head SHA + CI bắt buộc xanh + §3 đủ | Shipper |
| 5 | `merged` | Squash merge vào `develop`; xóa nhánh task; ghi SHA merge vào task record | Shipper |
| 6 | — | Lead đối chiếu: `[Unreleased]` và trạng thái ROADMAP/Kanban trên `develop` khớp task đã merge; lệch thì mở task `docs` sửa ngay | Lead |

Đẩy thêm commit sau Review PASS thì PASS cũ vô hiệu; review lại đúng SHA mới. Sau hai vòng sửa không đạt: quay Lead (OPENCODE §2).
Rebase nhánh task lên `develop` (không merge `develop` vào nhánh task) khi cần cập nhật; dùng skill `git-rebase`. Không force-push nhánh đã có review trừ khi review lại.

## 3. Điều kiện bắt buộc trước merge (Shipper chặn nếu thiếu)

1. Review PASS đúng head SHA; CI bắt buộc xanh trên revision tích hợp.
2. **CHANGELOG**: PR thêm mục dưới `## [Unreleased]` của `CHANGELOG.md` (§5). PR chỉ chạm tài liệu quy trình nội bộ cũng ghi mục `Tài liệu`; chỉ `chore` thuần công cụ mới được bỏ, kèm lý do trong PR.
3. **ROADMAP**: trạng thái WP/Q/S liên quan được cập nhật ở **cả** `ROADMAP.md` (§11) **và** `ROADMAP hiraku — Kanban.html` (§6), cùng giá trị.
4. Hành vi đổi thì spec/UC/DESIGN đã cập nhật (AGENTS "Quy trình").
5. Không còn Q mở chặn task; không file ngoài phạm vi task.

Merge approved **không** đồng nghĩa WP `Hoàn thành` ở mốc: WP chỉ sang `dn` khi mọi tiêu chí ra của WP đạt; PR một phần giữ `ip` và ghi phần còn lại trong cột ghi chú §11.

## 4. Commit và PR

- Commit: Conventional Commits, một dòng `<type>(<scope>): <subject>`, tiếng Anh, imperative, không body/footer, không task ID, không dòng đồng tác giả AI (skill `git-commit`; hook `commit-msg`, `pre-commit` chặn commit trên `main`).
- Task ID, FR/UC/ADR đi vào **mô tả PR** và task record, không vào commit.
- PR: tiêu đề `<type>(<scope>): <subject>` bằng tiếng Anh; mô tả theo template, ghi đúng lệnh đã chạy; không đánh dấu pass cho kiểm tra chưa chạy.
- Merge vào `develop`: squash (một commit mỗi task, tiêu đề PR thành commit). Merge vào `main`: merge commit để giữ lịch sử release.

## 5. CHANGELOG

`CHANGELOG.md` có hai phần: **`## [Unreleased]`** ở đầu (mục sản phẩm, theo Keep a Changelog) và lịch sử tài liệu bên dưới (giữ nguyên, không sửa).

Mỗi mục là một dòng tiếng Việt, đặt dưới nhóm `Thêm`, `Đổi`, `Sửa`, `Xóa`, `Tài liệu`, `Bảo mật`, kết thúc bằng `(WP-xx, PR)`:

```
### Thêm
- RPC `Grade` ghi thẻ và log trong một transaction (WP-03, PR 12)
```

Khi phát hành (`release/vX.Y.Z`): đổi `[Unreleased]` thành `## [X.Y.Z] - YYYY-MM-DD`, thêm `[Unreleased]` trống, dùng skill `changelog`. Tag chỉ trên `main`, theo `RELEASE.md` và chỉ sau PO duyệt.

## 6. Cập nhật ROADMAP (mọi lần phát triển)

Trạng thái dùng đúng năm giá trị của Kanban: `bl` Backlog · `rd` Sẵn sàng · `ip` Đang làm · `rv` Chờ duyệt · `dn` Hoàn thành.

| Thời điểm | Trạng thái | Cập nhật |
|---|---|---|
| Lead giao task | `rd` → `ip` | Coder đổi ở commit đầu của nhánh |
| Mở PR | `ip` → `rv` | Coder, trong PR |
| Merge xong và WP đủ tiêu chí | `rv` → `dn` | Đã nằm sẵn trong PR (§3.3) |
| Bị chặn | giữ nguyên | Ghi `blk` ở Kanban, cột ghi chú ở §11 |

Hai nơi phải khớp: bảng `ROADMAP.md` §11 và mảng `raw` trong `ROADMAP hiraku — Kanban.html` (trường thứ 5 của thẻ, thêm `blk` hoặc `note` nếu cần). Đổi lịch, phạm vi hoặc phiên bản tài liệu ở các mục khác vẫn theo `ROADMAP.md` §8 (kiểm soát thay đổi).

## 7. Release và hotfix

1. PO duyệt gate; Lead giao task `release/vX.Y.Z` từ `develop`; Coder đổi version + CHANGELOG; PR vào `main`.
2. Sau merge: Shipper (hoặc PO) tag `vX.Y.Z` trên `main`; PR đồng bộ `main` → `develop`.
3. Hotfix: `hotfix/*` từ `main`; PR vào `main` rồi PR vào `develop`; cùng yêu cầu §3.

## 8. Điều kiện môi trường (người vận hành, một lần)

Repo đã có Git và remote `origin` (GitHub); chưa có CI, hooks cài sẵn hay branch protection, và quyền commit/push/merge của agent vẫn đóng (OPENCODE §4). Việc còn lại cho PO/người vận hành, không agent nào tự làm:

```sh
git switch -c develop
cp .agents/skills/git-hooks/hooks/* .git/hooks/ && chmod +x .git/hooks/commit-msg .git/hooks/pre-commit
```

Sau đó bảo vệ `main`, `develop`: cấm push trực tiếp, bắt buộc PR, required checks (`go test -race`, `check-core.sh`, `check-imports.sh`, `buf lint`/`buf breaking`, `xcodebuild test`), Review PASS đúng SHA, squash cho `develop`. Mở quyền cho Coder (commit/push nhánh task) và Shipper (merge qua entrypoint được bảo vệ) bằng thay đổi `opencode.json` + test guard riêng, do PO review. Cho đến lúc đó: agent không báo merged.

Rulesets import sẵn: `.github/rulesets/main.json` (chỉ merge commit) và `develop.json` (chỉ squash). GitHub → Settings → Rules → Rulesets → New ruleset → Import a ruleset. Cả hai cấm push trực tiếp, xóa và force-push, bắt buộc PR. Số approval để 0 vì một tài khoản không tự duyệt PR của mình; nâng lên 1 khi có identity reviewer riêng (OPENCODE §4). Thêm `required_status_checks` khi có CI.
