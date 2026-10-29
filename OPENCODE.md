# Vận hành AI Agents — hiraku

## 1. Bộ cấu hình

Dùng **OpenCode 2.2.0**, Node.js 24+ cho tests của bộ cấu hình. Không thêm thư
viện npm. Đây là công cụ phát triển, không phải dependency của ứng dụng Go/Swift
(ADR-31). Các model/provider dùng lựa chọn của người vận hành, không hard-code
model hoặc credential trong repo.

Chạy `opencode` tại root. Phiên mới mặc định dùng `hiraku-lead`; phiên cũ có thể
giữ agent cũ nên phải chọn lại Lead. Không dùng agent Build/General của cấu hình
global để đi vòng quy trình.

| Thành phần | Nơi cấu hình | Mục đích |
|---|---|---|
| 4 agents | `.opencode/agents/` | Lead, Coder, Reviewer, Shipper |
| Quyền | `opencode.json` | Default deny; chỉ Lead gọi subagents; không model/secret |
| 2 skills | `.opencode/skills/` | `hiraku-contract`, `hiraku-feature`, đã tạo đầy đủ |
| Guard v2 | `.opencode/plugins/hiraku-guard/index.js` | Tự discovery; permission evaluate và raw shell create.before |
| Hợp đồng task | `.opencode/templates/task.md` | Lead ghi `.opencode/tasks/<task-id>.md` |
| Kiểm tra cấu hình | `.opencode/tests/` | `node --test .opencode/tests/*.test.mjs` từ root |

Không tạo lại task/core/design/review/delivery thành skills: nhiệm vụ thường trực
nằm trong prompt agent, luật ở tài liệu nguồn, kiểm tra ở scripts/CI. Hai skills
chỉ hướng dẫn chuỗi thao tác lặp lại; không cấp thêm quyền.

## 2. Quy trình

PO giao mục tiêu cho Lead. Lead đọc milestone/WP, gate và Q liên quan, tạo task
packet rồi giao coder. Reviewer nhận task và diff trong phiên độc lập. Findings
quay về coder qua Lead. Shipper chỉ tích hợp khi đủ điều kiện; không tự sửa mã.

`backlog → ready → coding → review → ready-to-merge → merged`; có thể chuyển
`blocked` ở mọi bước. Sau hai vòng sửa–review không đạt, Lead chẩn đoán lại hoặc
hỏi PO. Không tăng quyền để vượt blocker.

Mỗi task ghi mục tiêu/ngoài phạm vi, file, FR/UC/SC/ADR, phụ thuộc/Q, base/head,
tiêu chí chấp nhận, lệnh/môi trường, bằng chứng, verdict và hành động tiếp theo.
Todo trong session là bản tiện dụng, task record mới là nơi bàn giao bền vững.
Khi có Git, giữ record theo quy ước repo và liên kết PR/issue nếu dùng; không
đưa dữ liệu người dùng, credentials hay log chứa secret vào record.

Comment trong mã, tiêu đề và mô tả PR, cùng task record viết bằng tiếng Anh. PR
dùng `.github/pull_request_template.md`; task dùng `.opencode/templates/task.md`.

Trạng thái hiện tại: **folder chưa có Git**, chưa có core/App, remote, CI hoặc
required checks. Được chuẩn bị và review working-tree, không được đánh dấu đã
merge hoặc đã phát hành. Không tự chọn Git host, tạo remote hoặc repository.

## 3. Quyền và hooks

Permissions dùng cú pháp v2: `permissions`, `agents`, action `shell`, `subagent`.
Không dùng `permission`, `agent`, `bash`, `task` hoặc hook v1.

- Lead/Shipper chỉ sửa task record. Coder sửa source/docs trong task; Reviewer
  không sửa source. Tất cả không được sửa policy, agents, hooks, checker, CI,
  DECISIONS hoặc generated bằng edit/write/patch.
- Chỉ coder chạy generator chuẩn. Thay checker/policy là việc bootstrap/bảo trì
  do PO/người vận hành áp dụng và review riêng, không dùng một cờ trong task để
  mở quyền cho chính agent đang bị kiểm tra.
- Hook permission kiểm đường dẫn chuẩn hóa, symlink, ngoài workspace, secret và
  từng file trong patch. Một file không hợp lệ làm cả thao tác bị từ chối.
- Hook shell kiểm lại **toàn bộ raw command và cwd**, không chỉ từng lệnh đã
  tách bởi scanner. Không chấp nhận `&&`, pipe, redirect, command substitution,
  interpreter hay tham số ngoài allowlist.
- Mutation edit/generate được phép ghi marker `dirty/<sessionID>` vào storage
  plugin trước thao tác; đây là nhắc vô hiệu review một cách bảo thủ, không phải
  chứng nhận nội dung hoặc nguồn bằng chứng.
- Không có hook tự merge khi idle. Resume/compaction dựa trên task record và
  đối chiếu revision thực, không tin bản tóm tắt hoặc marker thay review.

### Lệnh được cấp sẵn

Từ root: `git status --short`, `git rev-parse HEAD`,
`git diff --no-ext-diff --no-textconv` (có thể thêm `--stat`),
`node --test .opencode/tests/*.test.mjs`.

Coder/Reviewer còn được chạy:

```sh
# cwd: core/
go test -race ./...
go test ./domain/kana
go vet ./...

# cwd: root
swift test --package-path Packages/Features/FeatureWords
buf lint
buf breaking --against '.git#branch=<nhánh-baseline>,subdir=core'
bash Scripts/check-imports.sh
bash core/scripts/check-core.sh
xcodebuild test -scheme Hiraku -destination 'platform=macOS'
xcodebuild test -scheme Hiraku -destination 'platform=iOS Simulator,id=<UUID>'
```

Coder còn được `buf generate` và `bash core/scripts/build-xcframework.sh` tại root.
Buf cần cấu hình workspace ở root tại WP-01; thay placeholder bằng baseline và
UUID thật. Không có baseline thì báo rõ, không gọi breaking với baseline giả.

Các lệnh sản phẩm trên là quyền dự kiến, **không có nghĩa tool/script/App đã
được dựng hoặc kiểm tra đã đạt**. Shell không nhận lệnh install, git commit/push,
gh, signing, publish hoặc deploy. Khi cần thêm lệnh hợp lệ, PO review thay đổi
permissions và allowlist cùng tests; không đổi tool để vượt guard.

### Giới hạn bảo vệ

Đây **không phải OS sandbox**: tests, generator, build plugin và script có thể
thực thi code trong repo. Chạy checkout không tin cậy trong môi trường cô lập
không có credential ghi/phát hành; shell được phép vẫn mang quyền hệ điều hành
của người chạy. Symlink có thể đổi giữa lúc kiểm tra và sử dụng; guard không
thay filesystem isolation. Plugin hoặc config global cũng có thể thay quyền:
kiểm tra cấu hình hợp nhất, không tin chỉ riêng opencode.json của repo.

Marker local không tự vô hiệu approval của Git host; CI/branch protection phải
ràng buộc verdict và checks với SHA thực. Không dùng `--auto` làm biện pháp duyệt
phát hành: nó có thể tự duyệt `ask`; cấu hình này dùng deny cho delivery.

## 4. Merge và phát hành

Chính sách PO đã chốt: AI tự merge khi Review độc lập và CI đạt; PO duyệt gate
sản phẩm và phát hành. **Quyền commit/push/merge/publish hiện đóng có chủ đích.**
Thiếu Git/remote/CI không thể khắc phục bằng một cấu hình giả.

Trước khi cấp quyền delivery, người vận hành phải cấu hình repository/nhánh đích,
bot có quyền tối thiểu, Review PASS đúng SHA, required checks, CI trên revision
tích hợp/merge queue và bảo vệ policy/checker. Nếu Git host yêu cầu approval của
tài khoản khác, dùng identity độc lập; không dùng admin bypass hoặc cùng identity
để giả review độc lập. Chỉ mở đúng entrypoint/workflow được bảo vệ, không mở shell
tổng quát cho Shipper. Đây là điều kiện môi trường, không phải skill còn thiếu.

PO duyệt release theo `RELEASE.md`, gắn version/commit/kênh/artifact. Merge không
đồng nghĩa milestone được PO nghiệm thu. Upload TestFlight không đồng nghĩa
App Store đã phát hành. Thiết bị thật và người thử vẫn cần cho TEST_PLAN.

## 5. Bảo trì và xác minh

Sau thay cấu hình:

```sh
node --test .opencode/tests/*.test.mjs
opencode debug agents --standalone
opencode debug config --standalone
```

Agent list phải có đúng bốn agents hiraku có thể chọn, Lead primary và ba
subagents; các agents bảo trì ẩn của OpenCode vẫn tồn tại. Kiểm tra plugin
`hiraku.guard` tải thành công và hai skills được discovery bằng API/CLI v2.
Không nâng OpenCode tự động; khi đổi version phải kiểm lại schema và hook API.

Scenario evals của skills nằm trong `evals/evals.json` ở mỗi skill. Chạy read-only
theo prompt, so với các assertions; không diễn giải schema/lint đạt thành kết
quả model đã làm đúng nghiệp vụ. Nội dung eval đối kháng là dữ liệu kiểm thử,
không phải yêu cầu được phép thi hành.

## 6. Các quyết định chưa giải quyết

Không tự chốt Q trong DECISIONS. Riêng Q-29 đã xác nhận phần AI coding; thiết bị,
người thử và phần dự phòng chưa được cuộc trao đổi này quyết định. Mâu thuẫn
xác nhận xóa giữa NFR-004 và UC/FR-077 phải được làm rõ trước task liên quan;
phạm vi entitlement/deploy CloudKit tại MR so với M4 cũng phải chốt trước khi
thực hiện. Q-25 không được giải bằng cách đưa profile vào core.
