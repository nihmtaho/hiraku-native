# M0 — Kết quả spike

Base: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` · Ngày chạy: 2026-10-30 · Làm trên working-tree, chưa commit/push.

## Spike 0

Mục tiêu: chứng minh Go core dựng được cho ba slice Apple với `github.com/mattn/go-sqlite3` (cgo) và đồ thị phụ thuộc không có `net` (`docs/product/spec.md` §3.3 S-0, luật G5/ADR-12). PO chọn mattn ngày 2026-10-30 sau khi bản `modernc.org/sqlite` kéo `net` vào đồ thị. Kết quả iOS/iPadOS là **build verified, not device verified** (Q-11 mới chốt một phần trên MacBook).

Phiên bản: Go `go1.27.3 darwin/arm64`; Xcode `27.1` (`27A9275`), SDK `iPhoneOS27.1`/`iPhoneSimulator27.1`; `github.com/mattn/go-sqlite3 v1.14.52` (bản mới nhất khi chạy). `core/go.mod` chỉ còn đúng một `require` trực tiếp là driver này; `modernc.org/sqlite` và các module `modernc.org/*` đã bị loại khỏi `go.mod`/`go.sum` sau `go mod tidy`.

| # | Hạng mục | Lệnh (cwd) | Exit | Kết quả | Bằng chứng |
|---|---|---|---|---|---|
| 1 | Thêm driver | `go get github.com/mattn/go-sqlite3@latest` (`core/`) | 0 | Đạt | `go: added github.com/mattn/go-sqlite3 v1.14.52` |
| 2 | Chuẩn hoá phụ thuộc | `go mod tidy` (`core/`) | 0 | Đạt | `core/go.mod`: `require github.com/mattn/go-sqlite3 v1.14.52`; không còn `modernc.org/sqlite` |
| 3 | Smoke test host | `go test -race ./...` (`core/`) | 0 | Đạt | `ok hiraku/core/spike 1.358s`; `hiraku/core/ffi [no test files]` |
| 4 | Không có `net` | `go list -deps ./... \| grep -E '(^\|/)net$'` (`core/`) | 1 (grep không khớp) | **Đạt** | Không in dòng nào; xem chi tiết bên dưới |
| 5 | Build ba slice | `bash core/scripts/spike-build.sh` (root) | 0 | Đạt (build-only) | 3 archive arm64 trong `core/.spike/`, có symbol `sqlite3` |

### Không có `net` — Đạt

Lệnh lọc đã chạy (cwd `core/`):

```sh
go list -deps ./... | grep -E '(^|/)net$'
```

Exit 1, không in dòng nào: không có package nào có import path đúng bằng `net`.

Còn lại các package họ `net` sau (không phải `net`):

```sh
go list -deps ./... | grep -E '(^|/)(net/netip|net/url)$'
# net/netip
# net/url
```

Truy vết importer:

```sh
go list -deps -f '{{.ImportPath}} {{join .Imports " "}}' ./... | grep -E ' (net/url|net/netip)( |$)'
```

cho thấy `github.com/mattn/go-sqlite3` import `net/url`, và `net/url` import `net/netip`. Cả hai không import `net`; `go mod why -m github.com/google/uuid` không còn trong đồ thị. Tiêu chí S-0 ("không có `net`") **đạt**; `net/url`/`net/netip` chỉ dùng để phân tích DSN, không mở socket. Ghi nhận để Reviewer cân nhắc cách hiểu "thư viện mạng" của ADR-12.

`core/ffi/ffi.go` cũng đã đổi sang `database/sql` + `_ "github.com/mattn/go-sqlite3"`, `sql.Open("sqlite3", ":memory:")`, để driver cgo thực sự được link vào archive (vẫn là `package main` tối giản cho `-buildmode=c-archive`, chưa dùng `import "C"`).

### Build ba slice — Đạt, build-only

Script `core/scripts/spike-build.sh` đặt `CC` và sysroot theo SDK, mỗi slice một lệnh `go build -buildmode=c-archive`:

| Slice | CC / cờ cgo | Exit | Artifact | Kiểm chứng |
|---|---|---|---|---|
| iOS device arm64 | `xcrun --sdk iphoneos --find clang`; `CGO_CFLAGS`/`CGO_LDFLAGS = -isysroot <iPhoneOS27.1.sdk> -mios-version-min=26.0` | 0 | `core/.spike/ios_arm64.a` (8.213.592 byte) | ar archive; `go.o` arm64; 1.951 symbol khớp `sqlite3`, có `T _sqlite3_open_v2`; **build verified, not device verified** |
| iOS simulator arm64 | `xcrun --sdk iphonesimulator --find clang`; `CGO_CFLAGS`/`CGO_LDFLAGS = -isysroot <iPhoneSimulator27.1.sdk> -mios-simulator-version-min=26.0`; thêm `-tags=iossimulator` | 0 | `core/.spike/iossimulator_arm64.a` (8.212.984 byte) | ar archive; `go.o` arm64; 1.951 symbol khớp `sqlite3`, có `T _sqlite3_open_v2`; **build verified, not device verified** |
| macOS arm64 | `xcrun --sdk macosx --find clang`; `CGO_CFLAGS`/`CGO_LDFLAGS = -isysroot <MacOSX27.1.sdk> -mmacosx-version-min=26.0`; `MACOSX_DEPLOYMENT_TARGET=26.0` | 0 | `core/.spike/darwin_arm64.a` (8.196.352 byte) | ar archive; `go.o` arm64; 1.951 symbol khớp `sqlite3`, có `T _sqlite3_open_v2` |

Ghi chú cờ: cgo cần `-isysroot` trỏ đúng SDK và `-mios-version-min` / `-mios-simulator-version-min` / `-mmacosx-version-min` khớp mức OS tối thiểu (iOS/macOS 26, ADR-13); slice macOS đặt thêm `MACOSX_DEPLOYMENT_TARGET=26.0` và không dùng `cc` môi trường. Lần biên dịch đầu in cảnh báo của sqlite amalgamation (`sqlite3-binding.c:40329:8: warning: "gethostuuid() is disabled."`) nhưng exit 0; các lần sau lấy từ cache nên không in lại. Không còn cảnh báo `loadinternal: cannot find runtime/cgo` của bản modernc vì lần này cgo thực sự chạy.

Kiểm chứng archive:

```sh
nm core/.spike/ios_arm64.a | grep -c sqlite3       # 1951
nm core/.spike/ios_arm64.a | grep ' T _sqlite3_open_v2'
ar t core/.spike/ios_arm64.a | head                # __.SYMDEF SORTED, go.o, 000000.o, ...
lipo -info <go.o trích từ archive>                 # architecture: arm64
```

Kết luận S-0: **Đạt** ở mức build-only — không còn `net`, cả ba slice build xanh với `mattn/go-sqlite3 v1.14.52`, archive chứa symbol `sqlite3` bản C. Chưa chạy trên thiết bị thật (Q-11 partial); chưa kiểm tra runtime/ABI `import "C"` thật của ADR-21 (thuộc S-8). Còn `net/url`/`net/netip` qua driver, không phải `net`.

## S-2 — Thư viện FSRS Go

Base: working-tree trên `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` · Ngày chạy: 2026-10-30 · Kết luận: **Không đạt** (mức `host`, test Go)

Câu hỏi (spec §3.3): "Thư viện FSRS Go hiện có: đúng thuật toán, bước học ngắn, bảo trì".
Tiêu chí đạt (spec §3.3, ADR-26): "Khớp bảng kỳ vọng §7.1; nếu không đạt → tự cài trong `core/domain/fsrs` (ADR-26)". ADR-26 yêu cầu khớp bộ vector sinh từ triển khai tham chiếu với cùng tham số, hỗ trợ bước học ngắn, giấy phép tương thích, còn bảo trì.

Môi trường: Go `go1.27.3 darwin/arm64`; `uv 0.12.10`; Python host `3.14.7`; bộ vector sinh bằng **CPython 3.13.5** trong venv tạm (`fsrs 6.3.2`, PyPI, FSRS-6); ứng viên `github.com/open-spaced-repetition/go-fsrs/v4 v4.0.0` (FSRS-6). Mạng được phép cho `go get` và cài `fsrs` (task packet).

| # | Hạng mục | Lệnh (cwd) | Exit | Kết quả | Mức xác minh | Bằng chứng |
|---|---|---|---|---|---|---|
| 1 | Công cụ tham chiếu | `uv --version`, `python3 -V` | 0 | Đạt | host | `uv 0.12.10`, `Python 3.14.7` (host; vector sinh bằng CPython 3.13.5, xem #3) |
| 2 | Kiểm kê ứng viên | `go list -m -versions`, GitHub API, `.info` của proxy | 0 | Đạt | host | Bảng ở dưới; chỉ `go-fsrs/v4` đủ điều kiện |
| 3 | Sinh vector tham chiếu | `uv run --python 3.13.5 --with fsrs==6.3.2 python core/spike/gen_fsrs_vectors.py` (root) | 0 | Đạt | host | `vectors: 17` → `core/spike/fsrs_vectors.json`, `reference.interpreter = "CPython 3.13.5"` |
| 4 | Thêm ứng viên | `go get github.com/open-spaced-repetition/go-fsrs/v4@v4.0.0`, `go mod tidy` (`core/`) | 0 | Đạt | host | `core/go.mod`, `core/go.sum` |
| 5 | Khớp vector (Next) | `go test -run TestFSRSVectors -v ./spike` (`core/`) | **1** | **Không đạt** | host | 9/17 vector khớp tuyệt đối; 3 vector lệch `due` |
| 6 | Preview 4 rating | `go test -run TestFSRSPreviewAllRatings -v ./spike` (`core/`) | **1** | **Không đạt** | host | 2/4 kết quả preview khớp (cùng 3 lỗi của #5) |
| 7 | Toàn bộ core | `go test -race ./...` (`core/`) | **1** | **Không đạt** | host | Đỏ do #5–#6; `core/ffi` vẫn `[no test files]`. Sau dọn dẹp: exit 0, `ok hiraku/core/spike` |
| 8 | Tính thuần | `grep -rn 'time\.Now' $(go list -m -f '{{.Dir}}' github.com/open-spaced-repetition/go-fsrs/v4)` + đọc mã | 0 | Đạt (có điều kiện) | đọc mã | Chỉ 2 chỗ; `now` là tham số của `Next`/`Repeat` |
| 9 | Giấy phép và bảo trì | `LICENSE`, GitHub API, proxy `.info` | 0 | Đạt | host | MIT; tag `v4.0.0` 2026-07-17; push cuối 2026-10-25; 156 sao |

### Kiểm kê ứng viên

Ngưỡng: giấy phép MIT/BSD/Apache và có hoạt động trong 12 tháng tính đến 2026-10-30 (tức sau 2025-10-30).

| Module | Bản mới nhất | Giấy phép | Release / commit gần nhất | Sao | API next-state và preview | Đủ điều kiện |
|---|---|---|---|---|---|---|
| `github.com/open-spaced-repetition/go-fsrs/v4` | `v4.0.0` | MIT | tag 2026-07-17 (release 2026-07-25), push 2026-10-25 | 156 | `FSRS.Next(card, now, rating) (SchedulingInfo, error)`; `FSRS.Repeat(card, now) (RecordLog, error)` trả đủ 4 rating; `Parameters.NewBasicScheduler(card, now).Preview()/Review(r)` | **Có** |
| `github.com/open-spaced-repetition/go-fsrs/v3` | `v3.3.1` | MIT | tag 2024-12-17 | (cùng repo) | FSRS-5, không có `Decay`/`Factor` | Không — bản cũ, v4 thay thế |
| `github.com/open-spaced-repetition/go-fsrs` (v1, không hậu tố) | `v1.2.1` | MIT | tag 2024-05-01 | (cùng repo) | API cũ, FSRS-4.5 | Không — bản cũ |
| `github.com/patricksuo/fsrs` | `v0.1.0` | MIT | 2025-07-18 | 3 | Không có preview 4 rating tách bạch | Không — 15 tháng không hoạt động |
| `github.com/yantology/go-fsrs` | không tag | MIT | 2025-09-28 | 0 | `fsrs` tự viết, không tag | Không — 13 tháng không hoạt động, không release |
| `github.com/imxw/go-fsrs` | `v0.2.0` | **không có** | 2026-04-30 | 0 | Port của py-fsrs 6.3.1 | Không — không có giấy phép, không được phân phối |
| `github.com/Qxy0happy/fsrs-dual-optimizer` | không tag | MIT | 2026-09-22 | 0 | Dẫn xuất `go-fsrs` + optimizer FSRS-6/7 | Không — không release, 0 sao, trọng tâm là optimizer |

Kết luận kiểm kê: chỉ `go-fsrs/v4` là ứng viên khả dụng; các bản cũ, không tag hoặc không có giấy phép bị loại theo tiêu chí 1.

### Vector tham chiếu

Sinh bằng `fsrs 6.3.2` trên **CPython 3.13.5** với `Scheduler(desired_retention=0.9, learning_steps=(1m, 10m), relearning_steps=(10m,), maximum_interval=36500, enable_fuzzing=False)`; script sinh lại ở `core/spike/gen_fsrs_vectors.py` (đầu tệp ghim `fsrs==6.3.2`, 21 trọng số và cài đặt; tự thoát nếu phiên bản `fsrs` cài đặt hoặc trọng số khác). `uv` tự dựng môi trường tạm, không cần venv trong cây; lệnh sinh lại từ root:

```sh
uv run --with fsrs==6.3.2 python core/spike/gen_fsrs_vectors.py
```

Thêm `--python 3.13.5` để tái lập đúng trường `reference.interpreter` đã ghi; 17 vector và mọi giá trị là **byte-identical** giữa CPython 3.13.5 và 3.14.7 (đã chạy cả hai và `diff`), chỉ trường `interpreter` đổi theo trình thông dịch đang chạy.

- `request_retention = 0.9`; `maximum_interval = 36500` (chọn bằng mặc định của cả hai thư viện, cũng là trần `Validate` của ứng viên; giá trị thật là cài đặt người dùng ở M1); `enable_short_term = true`; `enable_fuzz = false`.
  - `enable_short_term` là **tên trường của spec**, không phải tham số của py-fsrs: py-fsrs không có công tắc này — hành vi ngắn hạn là hệ quả của bước học khác rỗng (`1m`/`10m`). Ghi chú mapping nằm trong `mapping.enable_short_term` của `core/spike/fsrs_vectors.json`; phía ứng viên mới có `EnableShortTerm = true` → `basicScheduler`.
- Trọng số FSRS-6 dùng chung, ghi trong `core/spike/fsrs_vectors.json` (`weights`): `0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542` — trùng `DefaultWeights()`/`DEFAULT_PARAMETERS` của hai bên, tức **cùng phiên bản thuật toán FSRS-6**; không có tình huống "ứng viên chạy bản FSRS cũ hơn py-fsrs", nên không phải chạy lại tham chiếu với `fsrs` cũ (mục 6 của packet).
- 17 vector, mỗi vector là một lần chấm độc lập (`input` thẻ đầy đủ, `now`, `rating` → `want`):
  - `new/r1…r4` — thẻ New chấm 1/2/3/4;
  - `good-good-again-good/r3, r3, r1, r3` — Good→Good→Again→Good;
  - `lapse-from-review/r4, r1` — Easy (ra Review) rồi Again → Relearning;
  - `lapse-after-good-then-good/…` — chuỗi 5 lần có lapse rồi Good;
  - `midnight-gap/r3, r3` — Review lúc 23:55Z, chấm lại 00:05Z (10 phút, vắt qua nửa đêm UTC).
- Cách quy đổi sang model của ứng viên (ghi trong `mapping` của tệp): py-fsrs không có state New và không đếm `reps`/`lapses`; `state` 0=New, 1=Learning, 2=Review, 3=Relearning; `remaining_steps = len(steps) − step`; `reps` tăng mỗi lần chấm; `lapses` tăng khi Again từ Review (đúng luật spec §7.1). `last_review` được ghi để hai bên tính cùng số ngày đã trôi.

### Khớp vector — 9/17 tuyệt đối

`go test -run TestFSRSVectors -v ./spike` → exit 1; 17 subtest, **9 PASS / 8 FAIL**; preview 4 rating: **2/4** (`TestFSRSPreviewAllRatings`). So sánh `(state, due, stability, difficulty, reps, lapses)`, `due` quy về giây nguyên, dung sai 0.

| Vector | Trường lệch | Ứng viên | Tham chiếu | Nguyên nhân (đọc mã) |
|---|---|---|---|---|
| `new/r2` (Hard trên New) | `due` | 09:06:00Z | 09:05:30Z | `hardDelayMinutes` **làm tròn phút** `(1+10)/2 = 5,5 → 6`; py-fsrs giữ 5,5 phút |
| `lapse-after-good-then-good/r3#03` (Good trên Review) | `due` | 2026-11-05 | 2026-11-04 | `reviewState` ép **hard < good < easy** (`good = max(good, hard+1)`); py-fsrs không ép |
| `midnight-gap/r3#01` (Good trên Learning) | `due`, `stability` | 2026-11-07, 7,3153 | 2026-11-02, 2,3065 | Số ngày đã trôi: ứng viên `dateDiffInDays` theo **ngày lịch UTC** (23:55Z→00:05Z = 1 ngày) → dùng công thức recall; py-fsrs dùng `timedelta.days` (**0 ngày**) → `shortTermStability` |
| `new/r3`, `good-good-again-good/r3`, `lapse-after-good-then-good/r3`, `midnight-gap/r3` | `difficulty` | 2,118103970459015 | 2,1181039704590159 | Nhiễu số thực cuối (~2 ULP, `math.Pow` với `**`), không đổi hành vi |
| `new/r2` | `difficulty` | 5,1121707056010548 | 5,1121707056010557 | như trên |
| `lapse-from-review/r1` | `stability` | 1,3886324609821163 | 1,3886324609821161 | như trên |
| `lapse-after-good-then-good/r3#03` | `stability` | 2,4892333541386416 | 2,4892333541386376 | như trên |
| `midnight-gap/r3#01` | `stability` | 7,3153007440772804 | 2,3065000000000002 | khác công thức, xem hàng `due` |

Tổng hợp: `state`, `reps`, `lapses` khớp **17/17**; `due` khớp **14/17**; `stability`/`difficulty` khớp tuyệt đối ở **9/17** vector, 8 vector còn lại lệch ở 9 trường (6 `difficulty`, 3 `stability`), biên độ ≤ 4·10⁻¹⁵ tuyệt đối (≤ 9 ULP) — trừ `midnight-gap/r3#01` lệch hẳn công thức. Ba lệch `due` không phải lỗi phiên bản thuật toán: cả hai bên đều FSRS-6, cùng 21 trọng số; chúng là **khác biệt chính sách lập lịch** (làm tròn bước Hard, ràng buộc thứ tự hard/good/easy, và cơ sở tính số ngày đã trôi) giữa `go-fsrs` (port của ts-fsrs/Anki) và `fsrs` (py-fsrs).

Vì `due` so với dung sai 0, tiêu chí "khớp bộ test vector tham chiếu" của ADR-26 **không đạt**. Hệ quả nặng nhất cho sản phẩm là hàng `midnight-gap`: ứng viên tự tính số ngày đã trôi theo ngày lịch UTC, trong khi spec §7.3 định nghĩa ngày học bắt đầu lúc `day_start_hour` (mặc định 04:00) — thư viện không nhận ngày học của hiraku.

### Bước học ngắn và tính thuần

- Bước học ngắn: có. `EnableShortTerm = true` chọn `basicScheduler`; `LearningSteps`/`RelearningSteps` là `[]float64` phút; Again trên thẻ New ra `due` +1 phút (vector `new/r1`, khớp tuyệt đối), đủ cho luật "chèn lại thẻ nếu `due ≤ now + 20 phút`" (§7.3).
- `now` vào qua tham số: `FSRS.Next(card, now, rating)`, `FSRS.Repeat(card, now)`, `Parameters.NewBasicScheduler(card, now)`, `Retrievability(card, now)`. Không có `now_ms` toàn cục.
- `time.Now` trong mã nguồn ứng viên: đúng 2 chỗ — `alea.go:26` (chỉ khi seed `nil`, tức `ApplyFuzz` gọi ngoài Scheduler; `Scheduler` luôn truyền seed chuỗi từ `initSeed`, và `EnableFuzz = false` thì không gọi fuzz) và `models.go:29` (`NewCard()` không truyền tham số; dùng `NewCard(now)` là tránh được).
- Không đọc DB, không `net`, không `os`, không `sync`; không có biến toàn cục thay đổi được (chỉ `fuzzRanges` bảng hằng đọc và các `var` lỗi); `Parameters` được copy vào scheduler nên `seed` không rò ra ngoài. Hàm thuần theo nghĩa ADR-26, miễn sản phẩm truyền `now` và tắt fuzz.

### Quyết định — Không đạt

Tiêu chí trượt: **"khớp bộ test vector sinh từ triển khai tham chiếu với cùng tham số"** (ADR-26), cụ thể 3/17 `due` lệch với dung sai 0. Ba tiêu chí còn lại đạt: bước học ngắn có, giấy phép MIT, bảo trì tốt (tag 2026-07, push 2026-10).

Theo ADR-26, hướng đi là **tự cài FSRS trong `core/domain/fsrs`**. Phác thảo (không làm trong task này):

1. API thuần: `Next(card, rating, now_ms, settings) (Card, error)` và `Preview(card, now_ms, settings) map[Rating]Card`, cùng bộ vector `core/spike/fsrs_vectors.json` làm golden (ADR-22).
2. Model: `Card{state, due_ms, last_review_ms, stability, difficulty, reps, lapses, remaining_steps}`; `Settings{request_retention, maximum_interval, enable_short_term, enable_fuzz=false, learning_steps, relearning_steps}`; trọng số FSRS-6 đóng băng thành hằng 21 phần tử, chép đúng thứ tự phép tính của py-fsrs 6.3.2 để vector khớp bit.
3. Số ngày đã trôi do hiraku tự quyết theo `day_start_hour` (spec §7.3) thay vì ngày lịch UTC — đây là chỗ cố ý khác py-fsrs, phải sinh lại golden và ghi trong ADR/SPEC trước khi chốt. Lưu ý cho WP-03: **không vector nào trong 17 vector vắt qua mốc `day_start_hour` 04:00** (`midnight-gap` 23:55Z → 00:05Z vẫn nằm trong cùng một ngày học hiraku), nên khi định nghĩa luật số ngày đã trôi WP-03 phải thêm vector vắt mốc 04:00 (ví dụ 03:55 → 04:05).
4. Test bắt buộc: toàn bộ 17 vector ở trên (state/due/stability/difficulty/reps/lapses), Again trên thẻ New ra `due` phút, lapse +1 khi Again từ Review, `Preview` khớp `Next` cho cả 4 rating, và không đọc đồng hồ (truyền `now_ms`).

Ước lượng sơ bộ: 1–1,5 tuần-người cho `core/domain/fsrs` + golden (đề xuất, hiệu chỉnh ở GATE-1).

### Dọn dẹp sau quyết định

Harness so sánh (`core/spike/fsrs_vectors_test.go` chạy `go-fsrs/v4`) chỉ dùng một lần; bằng chứng sinh lại được là `core/spike/gen_fsrs_vectors.py` + `core/spike/fsrs_vectors.json` + bảng lệch ở trên. Đã xoá harness và gỡ `github.com/open-spaced-repetition/go-fsrs/v4` khỏi `core/go.mod`/`core/go.sum` (`go mod tidy`); từ root:

```sh
cd core && go mod tidy && go test -race ./...
```

exit 0, `ok hiraku/core/spike`. Bộ vector ở lại làm golden cho WP-03.

Kết quả S-2: **tự cài FSRS trong `core/domain/fsrs` (WP-03)**. Chưa có package `core/domain/fsrs` trong cây mã; việc tạo nó thuộc WP-03, không thuộc task này.

### Còn lại và quyết định cần PO

- **Q cần PO/Lead**: có chấp nhận ngữ nghĩa ts-fsrs (làm tròn bước Hard, ép hard<good<easy) và ngày lịch UTC làm "chuẩn" thay py-fsrs không? Nếu có, S-2 lật thành Đạt với `go-fsrs/v4`, nhưng **không thể chỉ ghi chú trong báo cáo**: cần một sửa đổi ADR-26/spec do PO phê duyệt, gồm (a) dung sai số thực cho `stability`/`difficulty`, (b) luật số ngày đã trôi theo `day_start_hour` thay ngày lịch UTC, và (c) tuyên bố chấp nhận làm tròn bước Hard cùng ràng buộc hard<good<easy. Việc sửa `docs/architecture/DECISIONS.md` và spec là **PO-only**; nếu không có sửa đổi đó thì đi theo tự cài. Báo cáo này kết luận **Không đạt** theo đúng tiêu chí dung sai 0.
- Harness so sánh đã bị xoá sau quyết định (xem "Dọn dẹp sau quyết định"); suite mặc định của `core/` xanh trở lại. WP-03 viết test của `core/domain/fsrs` trên cùng bộ vector golden.
- Chưa kiểm: optimizer/`go-fsrs/optimizer` (ngoài phạm vi), fuzz, per-deck parameters, FSRS-7; chưa chạy trên thiết bị (không cần cho S-2).
- Nhiễu ≤ 9 ULP ở `stability`/`difficulty` là khác biệt thứ tự phép tính số thực, không phải hành vi; nếu PO yêu cầu khớp bit tuyệt đối thì tự cài cũng phải chép đúng thứ tự phép tính của py-fsrs.

## S-1 — SQLite `mattn/go-sqlite3` trên 50k từ / 200k log (nửa Go, MacBook)

Base: working-tree trên `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` (HEAD làm việc `f6fb9f0`, cây còn file chưa commit của Spike 0/S-2) · Ngày chạy: 2026-10-30, đo lại 2026-10-31 sau review · Kết luận: **Đạt trên MacBook, iOS/iPadOS chưa xác minh** (Q-11).

Câu hỏi (spec §3.3 S-1): hiệu năng `github.com/mattn/go-sqlite3` (Go core) với 50.000 từ + 200.000 `review_logs` trên schema §4; tiêu chí NFR-002: dựng hàng đợi < 200 ms, tìm kiếm < 150 ms, khởi động nguội < 1,5 s (kèm NFR-003: chọn kiểm tra toàn vẹn khi mở). Task packet: `.agents/tasks/m0-04-s1-storage.md`.

Phạm vi: chỉ **host macOS** (Q-11 chốt 2026-10-30: MacBook của PO; chưa có iPhone/iPad). Không có Swift app, không đo 60 fps, không cài FSRS thật (S-2 kết luận tự cài; transaction chấm điểm dùng trạng thái kế tiếp cố định), không tạo `core/store`/migration. Mã đo nằm ở `core/spike/storage` (chỉ file `_test.go`, không có API sản phẩm).

### Môi trường

| Hạng mục | Giá trị | Lệnh |
|---|---|---|
| Máy | MacBook, Apple M4 Pro, 24 GiB RAM | `sysctl -n machdep.cpu.brand_string`, `sysctl -n hw.memsize` → `25769803776` |
| OS | macOS 27.2 (build 26B123) | `sw_vers` |
| Go | `go1.27.3 darwin/arm64` | `go version` |
| Driver | `github.com/mattn/go-sqlite3 v1.14.52` (cgo) | `core/go.mod` |
| SQLite | 3.53.4 (bản nhúng trong driver) | `SELECT sqlite_version()` |
| DB | WAL, `synchronous = FULL`, `busy_timeout = 5000` ms, `wal_autocheckpoint` mặc định | `PRAGMA` trong test |

### Fixture

Sinh bằng `math/rand/v2` với seed cố định `NewPCG(20261030, 1)`, không dùng `time.Now()`; dữ liệu tiếng Nhật sinh từ bảng âm tiết cố định. 2 folder, 50 deck, 1 kiểu hệ thống "Từ vựng Nhật" (4 field `term`/`reading`/`meaning`/`example`, role theo ADR-27), 1 `card_template`.

| Bảng | Số dòng | Ghi chú |
|---|---|---|
| `folders` | 2 | |
| `note_types` / `note_type_fields` / `card_templates` | 1 / 4 / 1 | kiểu hệ thống, `typing_answer_field_id = field-reading` |
| `decks` | 50 | chia đều 2 folder |
| `notes` | 50.000 | `fields` JSON khóa theo `field_id`, `sort_field` = term, `search_text` = term + reading + meaning (lowercase) |
| `cards` | 50.000 | 1 thẻ/note, `UNIQUE(note_id, template_id)` |
| `card_states` | 50.000 | 70% Review / 20% Learning / 10% Relearning; Review `due` rải ±100 ngày quanh mốc, Learning/Relearning `due` ±60 phút; 32.601 thẻ đến hạn ở mốc đo (fixture gốc, chưa mô phỏng thẻ mới) |
| `review_logs` | 200.000 | 180 ngày gần nhất, 4 rating, `prev_state` 0/1/2; 12 log `prev_state = 0` rơi vào ngày học |
| `settings` | 3 | `fsrs_retention`, `new_cards_per_day = 20`, `day_start_hour = 4` |

- Thời gian sinh: **1,260 s**.
- Kích thước logic (`page_count * page_size`): **94.851.072 B**; trên đĩa trước `VACUUM`: main **94.851.072 B**, `-wal` 0, `-shm` 32.768 B.
- Sau `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM` + checkpoint: main **90.759.168 B** (≈86,6 MiB), `-wal` 0, `-shm` 196.608 B.
- Determinism: chạy `TestBuildFixture` hai lần cho cùng fingerprint `notes=50000:89607494284501589:6183928 logs=200000:357130898140000000:500514` (`COUNT`, `SUM(updated_at)`, `SUM(LENGTH(fields)+LENGTH(search_text))` / `SUM(reviewed_at)`, `SUM(rating)`).
- DDL đầy đủ: hằng `schemaDDL` trong `core/spike/storage/fixture_test.go`; bản sao ghi ra `.agents/tmp/m0-04/schema.sql` (gitignored). Chỉ mục: `notes(deck_id)`, `notes(deck_id, sort_field)`, `notes(updated_at)`, `cards(note_id)`, `card_states(due)`, `card_states(state)`, `review_logs(card_id)`, `review_logs(reviewed_at)`; khóa chính/unique tự tạo index cho `notes.id`, `cards.id`, `card_states.card_id`. **`notes(updated_at)` (`idx_notes_updated`) do spike thêm để đo ChangeSet, không có trong spec §4**; khi vào sản phẩm phải thêm bằng migration và ghi chi phí ghi/không gian.

`notes` / `cards` / `card_states` mỗi bảng đúng 50.000 dòng; `review_logs` 200.000. Phân bố `card_states`: `i % 10 ∈ {6,7}` → Learning, `i % 10 = 8` → Relearning, còn lại Review (70/20/10). Trên fixture gốc có **32.601 thẻ đến hạn** ở mốc đo (`due ≤ cuối ngày học`, không tạm ngưng, chưa xoá mềm); vì fixture đã seed đủ `card_states` cho mọi thẻ, nhánh "thẻ mới" của §7.3 chỉ có dòng sau khi test xoá tạm 2.500 `card_states` trong một transaction (còn 31.334 thẻ đến hạn), đo rồi rollback (xem Hàng đợi).

### Cách chạy

Các test đo bị bỏ qua mặc định để `go test -race ./...` vẫn nhanh; đặt `HIRAKU_SPIKE_S1=1` để chạy. FTS5 cần build tag của driver (`sqlite_fts5`), nên test FTS5 nằm trong file có `//go:build sqlite_fts5`.

```sh
cd core
HIRAKU_SPIKE_S1=1 go test -run TestBuildFixture -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -run TestColdOpen -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -run TestQueueBuild -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -run TestSearch -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -tags sqlite_fts5 -run TestSearchFTS5 -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -run TestGradeTx -v -count=1 ./spike/storage
HIRAKU_SPIKE_S1=1 go test -run TestChangeSetQuery -v -count=1 ./spike/storage
go test -race ./...
```

DB tạm ở `.agents/tmp/m0-04/` (gitignored): `hiraku-s1.sqlite`, bản sao cho GradeTx `hiraku-s1-grade.sqlite`, bản FTS5 `hiraku-s1-fts.sqlite`; log từng lần chạy `fixture-run.log`, `cold-run.log`, `queue-run.log`, `search-run.log`, `fts-run.log`, `grade-run-1.log`, `grade-run-2.log`, `changeset-run.log`, `race.log`, `race-spike.log`.

### Kết quả

| # | Hạng mục | Lệnh (cwd `core/`) | Exit | Số đo | Ngưỡng | Kết luận |
|---|---|---|---|---|---|---|
| 1 | Fixture + kích thước | `HIRAKU_SPIKE_S1=1 go test -run TestBuildFixture -v -count=1 ./spike/storage` | 0 | sinh 1,260 s; 90.759.168 B sau VACUUM | — | Đạt |
| 2 | Cold open, không kiểm tra | `... -run TestColdOpen ...` | 0 | 5 lần: median **0,595 ms**, max **1,943 ms** | < 1,5 s | Đạt* |
| 3 | Cold open, `quick_check` | như trên | 0 | 5 lần: median **90,043 ms**, max **105,827 ms**, kết quả `ok` | < 1,5 s | Đạt* |
| 4 | Cold open, `integrity_check` | như trên | 0 | 5 lần: median **324,099 ms**, max **329,779 ms**, kết quả `ok` | < 1,5 s | Đạt* |
| 5 | Dựng hàng đợi §7.3 (cap 1.000) | `... -run TestQueueBuild ...` | 0 | 20 lần: median **132,021 ms**, p95 **136,786 ms**, max 143,420 ms; 1.008 dòng (1.000 đến hạn + 8 mới) | < 200 ms | Đạt* |
| 5b | Dựng hàng đợi §7.3 (không cap) | như trên | 0 | 20 lần: median **149,061 ms**, p95 **150,611 ms**, max 150,807 ms; 31.342 dòng (31.334 đến hạn + 8 mới) trên 31.334 thẻ đến hạn còn lại | < 200 ms | Đạt* |
| 5c | `firstReviewsToday` (hạn mức thẻ mới) | như trên | 0 | 20 lần: median **0,651 ms**, p95 **0,859 ms**, max 1,101 ms; 12 log `prev_state = 0` trong ngày học | — | Đo riêng |
| 6 | Tìm `LIKE` 1 ký tự | `... -run TestSearch ...` | 0 | prefix median 3,937 ms / p95 4,544 ms; substring 5,478 / 5,873 ms | < 150 ms | Đạt* |
| 7 | Tìm `LIKE` 2 ký tự | như trên | 0 | prefix 3,855 / 4,069 ms; substring 5,499 / 5,747 ms | < 150 ms | Đạt* |
| 8 | Tìm `LIKE` 3 ký tự | như trên | 0 | prefix 3,857 / 4,032 ms; substring 5,643 / 5,979 ms | < 150 ms | Đạt* |
| 9 | FTS5 trigram 3 ký tự | `... -tags sqlite_fts5 -run TestSearchFTS5 ...` | 0 | prefix median 10,0 µs / p95 18,0 µs; substring 12,2 / 31,7 µs; build index 113,252 ms; +4.755.456 B | — | Đạt (chỉ ≥3 ký tự) |
| 10 | FTS5 trigram 1–2 ký tự | như trên | 0 | `MATCH "川"` = 0, `MATCH "川上"` = 0 (không lỗi) | — | Không dùng được |
| 11 | Transaction chấm điểm | `... -run TestGradeTx ...` | 0 | 100 lần (lần chạy thứ 2): median **115,9 µs**, p95 **155,5 µs**, max 507,2 µs; `review_logs` +100; 100/100 thẻ `state = 2` | ghi bền/atomic | Đạt* |
| 12 | ChangeSet reload 1 giờ | `... -run TestChangeSetQuery ...` | 0 | 90 note + 1.112 log; 20 lần: median **1,177 ms**, p95 **1,482 ms** | — | Đo được |
| 13 | ChangeSet reload 7 ngày | như trên | 0 | 12.410 note + 8.896 log; median **17,063 ms**, p95 **17,753 ms** | — | Đo được |
| 14 | Không hồi quy | `go test -race ./...` | 0 | `ok hiraku/core/spike`, `ok hiraku/core/spike/storage`, `ffi [no test files]` | xanh | Đạt |
| 15 | Race trên đường đo | `HIRAKU_SPIKE_S1=1 go test -race -run 'Test(BuildFixture\|ColdOpen\|QueueBuild\|Search\|GradeTx\|ChangeSetQuery)' -count=1 ./spike/storage` | 0 | `ok hiraku/core/spike/storage 17,095s` | xanh | Đạt |

`*` = số đo trên **MacBook M4 Pro host**, không phải thiết bị iOS/iPadOS; xem "Chưa xác minh". `p95` của 5 lần cold open bằng max (công thức p95 với n=5).

Chi tiết từng phép đo:

- **Cold open**: `sql.Open` + `Ping` + `PRAGMA busy_timeout/journal_mode/synchronous` + (kiểm tra toàn vẹn nếu có) + `SELECT COUNT(*) FROM notes`; mỗi lần một `*sql.DB` mới, đóng sau khi đo. `quick_check` và `integrity_check` đều trả `ok`. File đã nằm trong page cache của OS (không xoá cache, không reboot) nên đây là **cold open ở mức tiến trình**, không phải cold start sau reboot.
- **Hàng đợi**: một câu SQL theo §7.3 luật 1–3: `card_states` đến hạn (`due <= cuối ngày học`, không tạm ngưng, `cs.deleted_at IS NULL`) xếp Learning/Relearning trước Review rồi `due`; nhánh thẻ mới = `cards` không có `card_states` chưa xoá mềm (`NOT EXISTS (… AND cs.deleted_at IS NULL)`), xếp theo `notes.created_at`, giới hạn `new_cards_per_day` − số log có `prev_state = 0` trong ngày học (`review_logs.deleted_at IS NULL`). Ngày học dùng `day_start_hour = 4` tính bằng số học trên `now_ms` (spike dùng UTC vì core không có timezone; app sẽ truyền mốc đã quy đổi). Mốc `now_ms` = 2026-10-30T12:00Z, ngày học 2026-10-30 04:00Z → 2026-10-31 04:00Z. Fixture gốc có **32.601 thẻ đến hạn**; để nhánh "mới" có dữ liệu thật, test xoá 2.500 `card_states` (`rowid % 20 = 0`) trong transaction (còn **31.334** thẻ đến hạn), đo, rồi rollback — DB cuối cùng không đổi. Đo cả bản **cap 1.000** thẻ đến hạn (1.008 dòng) và bản **không cap** (31.342 dòng = 31.334 đến hạn + 8 mới); `firstReviewsToday` đo riêng (12 log, median 0,651 ms). Kế hoạch truy vấn: `SEARCH cs USING INDEX idx_card_states_due (due<?)` + `USE TEMP B-TREE FOR ORDER BY` cho nhánh đến hạn; nhánh mới `SCAN c` + tra `card_states`/`notes` theo khóa chính + temp B-tree.
- **Tìm kiếm**: `SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL AND search_text LIKE ?` với mẫu lấy từ term thật của một note (`川上水本`): 1/2/3 ký tự, dạng prefix `x%` và substring `%x%`. Đếm toàn bộ kết quả (không `LIMIT`) nên là chi phí quét đầy đủ. Độ dài `search_text` trung bình của fixture: **22,0 ký tự / 48,2 byte** (`LENGTH` / `LENGTH(CAST(… AS BLOB))`); dữ liệu thật dài hơn (nghĩa/ví dụ dài, nhiều field `searchable`), nên coi đây là **cận dưới** chi phí quét. `LIKE` luôn `SCAN notes` (không index dùng được cho substring). FTS5 dùng bảng ảo ngoài `notes_fts` (`tokenize='trigram'`, `content='notes'`, `content_rowid='rowid'`) trên **bản sao** DB, truy vấn join `notes` để lọc `deleted_at IS NULL`; `MATCH` 3 ký tự; 1–2 ký tự trả 0 dòng vì trigram cần ≥3 ký tự.
- **Chấm điểm**: test chạy trên **bản sao** `hiraku-s1-grade.sqlite` của fixture, nên mỗi lần chạy là độc lập và không để lại log/thay đổi trên fixture dùng chung; ID log lấy từ bộ đếm lần chèn (`seq`), không suy từ `now`. Mỗi lần một transaction `SELECT` trạng thái hiện tại → `UPDATE card_states` (state 2, `due = now + 3 ngày`, `reps + 1`) → `INSERT review_logs` đủ ảnh chụp `prev_*` → `COMMIT`; thời gian đo cả commit. WAL + `synchronous = FULL` (`PRAGMA synchronous` = 2). Một `*sql.DB` với `SetMaxOpenConns(1)` (một writer như ADR-24), `busy_timeout = 5000`. Hai lần chạy liên tiếp (không rebuild fixture) đều exit 0; sau 100 lần, `review_logs` tăng đúng 100 và 100/100 thẻ đọc lại có `state = 2`: không có lost-write trong đường một writer.
- **ChangeSet (ADR-24, phía Go)**: hai truy vấn `notes WHERE updated_at > ?` và `review_logs WHERE reviewed_at > ?`, cả hai dùng index (`idx_notes_updated`, `idx_review_logs_reviewed`). Truy vấn `notes` **không lọc `deleted_at IS NULL`** để dòng đã xoá mềm vẫn về phía client (client cần biết để bỏ khỏi danh sách); fixture không có dòng xoá mềm nên chi phí không đổi. Revision 1 giờ trước `now` và 7 ngày trước `now`. Số log ở đây đo trên fixture **không bị TestGradeTx chạm vào** (grade chạy trên bản sao), nên không còn phụ thuộc thứ tự chạy. Đây là chi phí **truy vấn tải lại**, không phải thời gian UI/khung hình.

### Kết luận theo NFR-002

| Chỉ tiêu NFR-002 | Ngưỡng | Số đo MacBook | Kết luận |
|---|---|---|---|
| Khởi động nguội (phần lưu trữ) | < 1,5 s | 0,59 ms (không check) · 90,0 ms (`quick_check`) · 324,1 ms (`integrity_check`) | **Đạt** trên MacBook; thiết bị chưa xác minh |
| Dựng hàng đợi | < 200 ms | cap 1.000: median 132,0 ms · p95 136,8 ms; không cap: median 149,1 ms · p95 150,6 ms | **Đạt** trên MacBook, biên ≈1,3×; thiết bị chưa xác minh |
| Tìm kiếm | < 150 ms | xấu nhất p95 5,98 ms (`LIKE`, 3 ký tự substring) | **Đạt** trên MacBook; thiết bị chưa xác minh |
| Cuộn 60 fps | 60 fps | không đo (không có UI) | **Chưa xác minh** |

SC-006 (50.000 từ đạt NFR-002 trên thiết bị tối thiểu mỗi nền tảng) giữ **chưa xác minh**: không có thiết bị, không có app.

### Khuyến nghị NFR-003 — kiểm tra toàn vẹn khi mở

Chạy **`PRAGMA quick_check` đồng bộ khi mở** (90,0 ms trên MacBook, **6,0%** ngân sách 1,5 s) và **`PRAGMA integrity_check` chạy nền** sau khi màn học đã lên (324,1 ms, **21,6%** ngân sách). Lý do: `quick_check` bắt được hỏng cấu trúc/index với chi phí thấp; `integrity_check` đắt gấp ~3,6 lần và trên iPhone sẽ lâu hơn, nên không đặt trên đường mở đồng bộ. Không bỏ kiểm tra (NFR-003 yêu cầu kiểm tra khi mở). Nếu S-1 bổ sung trên thiết bị cho thấy `quick_check` vượt ngân sách, chuyển cả hai sang nền và chỉ chặn khi mở DB thất bại.

### Khuyến nghị chỉ mục tìm kiếm

**Giữ `LIKE` trên `search_text`, không thêm FTS5 ở M1–M3.** `LIKE '%…%'` đạt p95 ≤ 6,0 ms trên 50k dòng, cách ngưỡng 150 ms ~25×; `LIKE` phục vụ được cả 1, 2 và 3 ký tự. FTS5 trigram nhanh hơn (~10–12 µs cho ≥3 ký tự) nhưng:

- **Không phục vụ 1–2 ký tự**: trigram cần ≥3 ký tự, `MATCH` 1–2 ký tự trả 0 dòng — đúng nhóm query hay gặp khi gõ tiếng Nhật.
- **Chi phí**: +4.755.456 B (~5,2% DB) và 113 ms dựng index cho 50k note, cộng trigger/đồng bộ khi ghi note, migration mới, và build tag `sqlite_fts5` (bật `SQLITE_ENABLE_FTS5` trong archive c-archive, ảnh hưởng S-8).
- `LIKE` là quét tuyến tính: chi phí tăng theo số note, nhưng 50k là mục tiêu NFR-002 và biên còn lớn.

Điều kiện xem lại: S-1 bổ sung trên iPhone/iPad cho `LIKE` > 150 ms, hoặc dữ liệu vượt xa 50k. Khi đó FTS5 trigram chỉ giải quyết ≥3 ký tự; 1–2 ký tự vẫn cần `LIKE` hoặc một index prefix riêng.

### Chưa xác minh

- **iOS/iPadOS**: mọi số đo là macOS 27.2 trên Apple M4 Pro. Chưa chạy trên iPhone 11 (A13) hay iPad; NFR-002/SC-006 nói "thiết bị tối thiểu", nên hàng đợi 132,0 ms có thể vượt 200 ms trên thiết bị — cần đo ở S-1 bổ sung.
- **60 fps cuộn danh sách và reload UI theo `ChangeSet` (ADR-24)**: chỉ đo truy vấn tải lại (1,2 ms / 17,1 ms), không đo vẽ UI, không có Swift app.
- **S-1 bổ sung**: đo lại trên schema ADR-27 **trên thiết bị** và kiểm reload theo phạm vi giữ 60 fps vẫn mở (ROADMAP §3.3).
- **Cold start thật**: chưa xoá page cache/reboot; số cold open là mức tiến trình với file đã được OS cache.
- **Mở sau crash/WAL recovery**: chưa mô phỏng WAL còn sót sau crash; số đo chỉ là mở file đã checkpoint sạch, chưa gồm thời gian replay WAL.
- **Ghi đồng thời hai cửa sổ (S-5)**, widget đọc cùng DB, App Group/sao lưu iCloud (S-7): chưa kiểm.
- **FSRS thật**: transaction chấm điểm dùng trạng thái kế tiếp cố định (S-2 kết luận tự cài; WP-03), không đo chi phí tính FSRS.
- **Hàng đợi**: nhánh thẻ mới đo với 2.500 thẻ "mới" giả lập trong transaction đã rollback, không phải dữ liệu người dùng thật; chưa có `ANALYZE`, chưa thử phương án index/viết lại truy vấn để tăng biên trên thiết bị.
- **FTS5**: chưa thử `unicode61`/external-content trigger, chưa đo **chi phí ghi/trigger khi note thay đổi**, chưa đo trên dữ liệu lớn hơn, chưa kiểm ảnh hưởng build tag tới archive iOS (thuộc S-8).

## App shell

Mục tiêu: có host thật cho S-3, S-4, S-6, S-7, S-8 (task `m0-05-app-skeleton`). Một target multiplatform SwiftUI, một màn hình, không nghiệp vụ.

Môi trường: Xcode `27.1` (`27A9275`), SDK `iPhoneSimulator27.1`/`MacOSX27.0`; host macOS `27.2` (`26B123`), Apple silicon `arm64`. Không có runtime iOS 26.x trong máy (chỉ `iOS 27.0`), nên deployment target `26.0` mới là **build-time**, chưa chạy trên OS 26.

Bố cục:

```
App/Hiraku.xcodeproj/project.pbxproj              # kiểm in, không sinh lúc build
App/Hiraku.xcodeproj/xcshareddata/xcschemes/Hiraku.xcscheme
App/Hiraku/HirakuApp.swift                        # @main, WindowGroup
App/Hiraku/ShellView.swift                        # một màn hình
App/Hiraku/Localizable.xcstrings                  # String Catalog, sourceLanguage vi
```

Một target `Hiraku`: `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx`, `TARGETED_DEVICE_FAMILY = 1,2`, `IPHONEOS_DEPLOYMENT_TARGET = MACOSX_DEPLOYMENT_TARGET = 26.0`, `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, `PRODUCT_BUNDLE_IDENTIFIER = com.example.hiraku` (tạm), `CODE_SIGN_STYLE = Automatic`, không có `DEVELOPMENT_TEAM` (`_DEVELOPMENT_TEAM_IS_EMPTY = YES`); ký bằng "Sign to Run Locally" (ad-hoc). Info.plist sinh tự động (`GENERATE_INFOPLIST_FILE = YES`).

| # | Hạng mục | Lệnh (cwd root) | Exit | Kết quả | Bằng chứng |
|---|---|---|---|---|---|
| 1 | Phiên bản Xcode | `xcodebuild -version` | 0 | Đạt | `Xcode 27.1` / `27A9275` |
| 2 | Cú pháp project | `plutil -lint App/Hiraku.xcodeproj/project.pbxproj` | 0 | Đạt | `OK` |
| 3 | Cú pháp scheme | `xmllint --noout App/Hiraku.xcodeproj/xcshareddata/xcschemes/Hiraku.xcscheme` | 0 | Đạt | không in gì |
| 4 | Project đọc được | `xcodebuild -project App/Hiraku.xcodeproj -list` | 0 | Đạt | target `Hiraku`, scheme `Hiraku` |
| 5 | Build iOS | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath .agents/tmp/m0-05/dd build` | 0 | Đạt | `** BUILD SUCCEEDED **`, 0 warning; log `.agents/tmp/m0-05/ios-build.log` |
| 6 | Build iPad | như trên, `name=iPad Pro 13-inch (M5)` | 0 | Đạt (build-only) | `** BUILD SUCCEEDED **`; log `.agents/tmp/m0-05/ipad-build.log` |
| 7 | Boot simulator | `xcrun simctl boot 379C674F-6B1F-43CC-B5F1-75963192C629`; `xcrun simctl bootstatus <UDID> -b` | 0; 0 | Đạt | `Finished`, elapsed 8 s |
| 8 | Cài app | `xcrun simctl install <UDID> .agents/tmp/m0-05/dd/Build/Products/Debug-iphonesimulator/Hiraku.app` | 0 | Đạt | — |
| 9 | Chạy app | `xcrun simctl launch <UDID> com.example.hiraku` | 0 | Đạt | `com.example.hiraku: 96488` |
| 10 | Không crash | `sleep 3; xcrun simctl spawn <UDID> launchctl list \| grep -i hiraku` | 0 | Đạt | `96488 0 UIKitApplication:com.example.hiraku[d2fb][rb-legacy]` — PID còn sống, mã thoát 0; `simctl terminate` sau đó exit 0 |
| 11 | Ảnh màn hình | `xcrun simctl io <UDID> screenshot .agents/tmp/m0-05/ios-shell.png` | 0 | Đạt | ảnh 1206×2622: chữ `hiraku` lớn ở giữa, dưới là `Khung M0 — chưa có tính năng` màu phụ, nền hệ thống sáng |
| 12 | Build macOS | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' -derivedDataPath .agents/tmp/m0-05/dd build` | 0 | Đạt | `** BUILD SUCCEEDED **`; chỉ 1 warning của `appintentsmetadataprocessor` ("no AppIntents.framework dependency"), không phải cảnh báo mã |
| 13 | Chạy macOS | `open -n .agents/tmp/m0-05/dd/Build/Products/Debug/Hiraku.app` | 0 | Đạt | tiến trình `96903 …/Debug/Hiraku.app/Contents/MacOS/Hiraku` |
| 14 | Cửa sổ macOS | `pgrep -fl 'Debug/Hiraku.app/Contents/MacOS/Hiraku'`; `lsappinfo find bundleID=com.example.hiraku`; `osascript -e 'tell application "System Events" to get name of every window of process "hiraku"'` | 0; 0; 0 | Đạt | PID 96903; `ASN:0x0-0xca9ca9-"hiraku"`; System Events trả `hiraku` (có cửa sổ) |
| 15 | Thoát macOS | `osascript -e 'tell application id "com.example.hiraku" to quit'` | 0 | Đạt | `pgrep` sau đó exit 1 (không còn tiến trình) |
| 16 | Không cấm | `grep -rn -e 'try!' -e 'print(' App --include='*.swift'` | 1 | **Đạt** (không khớp) | không in dòng nào |
| 17 | Build settings | `xcodebuild … -showBuildSettings \| grep -E 'SWIFT_VERSION\|SWIFT_STRICT_CONCURRENCY\|DEPLOYMENT_TARGET\|PRODUCT_BUNDLE_IDENTIFIER\|CODE_SIGN_STYLE'` | 0 | Đạt | `EFFECTIVE_SWIFT_VERSION = 6`, `SWIFT_STRICT_CONCURRENCY = complete`, cả hai deployment target `26.0`, `CODE_SIGN_STYLE = Automatic`, team rỗng |

Simulator: `iPhone 18 Pro`, UDID `379C674F-6B1F-43CC-B5F1-75963192C629`, runtime iOS 27.0. App: bundle id `com.example.hiraku`, bundle `.agents/tmp/m0-05/dd/Build/Products/Debug-iphonesimulator/Hiraku.app`; bản macOS `.agents/tmp/m0-05/dd/Build/Products/Debug/Hiraku.app`. Toàn bộ log, ảnh và DerivedData nằm trong `.agents/tmp/m0-05/` (đã gitignore).

Ngoại lệ tạm thời có chủ đích: `DesignSystem` chưa tồn tại nên màn hình dùng kiểu hệ thống (`.largeTitle`, `.subheadline`, `.foregroundStyle(.secondary)`) và không đặt màu/cỡ chữ cụ thể — không hard-code hex hay point size. Chuỗi cần bản địa hoá duy nhất là nhãn shell, nằm trong `App/Hiraku/Localizable.xcstrings` (vi); tên app `hiraku` là nhãn thương hiệu, dùng `Text(verbatim:)` nên không phải khoá catalog. Không có `Assets.xcassets`/`AppIcon` nên icon là mặc định của hệ thống.

### Chưa xác minh

- **Signing team và bundle id**: chưa có Apple Developer (ADR-17 gom bundle ID/signing chính thức vào mốc MR); bản chạy chỉ ký ad-hoc "Sign to Run Locally". Task packet ghi Q-12/Q-13 cho hai mục này nhưng trong `DECISIONS.md` Q-12 là chia M1a/M1b và Q-13 là quy ước tên tài liệu — coi là chênh lệch của packet, không phải quyết định mới.
- **OS 26**: chỉ có runtime iOS 27.0; deployment target 26.0 chưa được chạy thử trên iOS/iPadOS/macOS 26.
- **Thiết bị thật**: không cài lên iPhone/iPad (Q-11), không chạy iPad sau khi build.
- **Release/archive**: chỉ build cấu hình Debug; chưa `archive`, chưa ký phân phối.
- **Phạm vi ngoài shell**: App Group và widget (S-7), `HirakuBridge`/XCFramework (S-8), IME (S-3), layout thích ứng (S-4), font (S-6) — chưa có trong app này.

## S-8 — XCFramework + bridge hk_* + đo khởi động Go runtime

Đường thành phẩm của ADR-21: `core/ffi` (c-archive) → `core/.spike/Hiraku.xcframework` → package Swift `Packages/HirakuBridge` → app chạy và ping.

Ràng buộc của spike:

- **Payload rỗng — chỉ chứng minh transport**: `hk_call` chỉ chấp nhận `method = "ping"` và trả `HKBytes` rỗng (data nil, len 0). Method enum và payload protobuf `hiraku.v1` (golden, `buf`) thuộc WP-01; đây không phải contract thật.
- Đúng bốn hàm ABI: `hk_open(db_path, &handle, &err)`, `hk_call(handle, method, req, &resp)`, `hk_free(bytes)`, `hk_close(handle)`. Mã lỗi 0…5 của ADR-21 (0 thành công, 1 tham số sai, 4 lỗi lưu trữ, 5 panic đã recover; 2/3 chưa có nhánh sinh ra vì spike không có nghiệp vụ). Mỗi hàm export có `recover`.
- Không con trỏ Go qua ranh giới: handle là id trong bảng của `ffi`; reply/err là bộ đệm do C malloc hoặc rỗng; Swift đọc xong gọi `hk_free` ngay, kể cả nhánh lỗi. Không `time.Now`, không `net`.
- `hk_open` mở DB **tại đường dẫn** Swift cấp; SQLite `:memory:` không đánh địa chỉ được qua path nên scratch DB là `.agents/tmp/m0-06/hiraku-s8.sqlite` (app tự tạo thư mục).
- `core/spike/storage` và `core/spike/fsrs*` giữ nguyên.

### Bài kiểm tra và kết quả

| # | Hạng mục | Lệnh (cwd root) | Exit | Kết quả |
|---|---|---|---|---|
| 1 | Build 3 slice + đóng gói | `bash core/scripts/build-xcframework.sh` | 0 | Đạt — 3 slice 7.9 MB mỗi file; `Hiraku.xcframework` 24 MB |
| 2 | Ký hiệu export | `nm -gU core/.spike/*.a \| grep _hk_` | 0 | Đạt — đủ `_hk_open/_hk_call/_hk_free/_hk_close` ở cả 3 slice |
| 3 | Test Go | `cd core && go test -race -count=1 ./...` | 0 | Đạt |
| 4 | Vet ffi | `cd core && go vet ./ffi` | 0 | Đạt |
| 5 | Kiểm project | `plutil -convert xml1 -o /dev/stdout App/Hiraku.xcodeproj/project.pbxproj`; `xcodebuild -list` | 0; 0 | Đạt — phân giải package: `HirakuBridge … @ local` |
| 6 | Build macOS | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' build` | 0 | Đạt — `** BUILD SUCCEEDED **` |
| 7 | Run + đo macOS | `HK_SPIKE_RUN=1 HK_SPIKE_OUT=…/m0-06/spike8-macos.json …/Debug/Hiraku.app/Contents/MacOS/Hiraku` | 0 | Đạt — tiến trình sống, đo xong, `kill` sạch |
| 8 | Build simulator | `xcodebuild … -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build` | 0 | Đạt — `** BUILD SUCCEEDED **` |
| 9 | Boot/cài/chạy | `simctl boot` + `simctl install` + `SIMCTL_CHILD_HK_SPIKE_RUN=1 SIMCTL_CHILD_HK_SPIKE_OUT=… xcrun simctl launch 379C674F-6B1F-43CC-B5F1-75963192C629 com.example.hiraku` | 0; 0; 0 | Đạt — `com.example.hiraku: 73915`; PID còn sống sau 8 s; screenshot `.agents/tmp/m0-06/spike8-sim.png` hiện dòng kết quả và nút ping |

Layout framework (`core/.spike/Hiraku.xcframework`, 24 MB): `Info.plist` + `ios-arm64/` (Headers + ios_arm64.a), `ios-arm64-simulator/` (Headers + iossimulator_arm64.a), `macos-arm64/` (Headers + darwin_arm64.a). Headers = `hk.h` + `module.modulemap`.

Kết quả đo lần lượt, **simulator/host, not device** (từ JSON `.agents/tmp/m0-06/spike8-{macos,sim}.json`):

- **macOS host**: cold 0.992 ms; median 20 lần open→ping 0.064 ms; 1.000 `hk_call("ping")` median 0.0000 ms (dưới độ phân giải in), p95 0.001 ms; RSS 89.632 → 89.632 KB (không tăng) — leak check Đạt.
- **iOS simulator** (iPhone 18 Pro, runtime iOS 27.0): cold 10.788 ms; median 20 lần 0.134 ms; 1.000 call median 0.001 ms, p95 0.001 ms; RSS 198.336 → 198.400 KB (+64 KB, dao động GC không tăng đơn điệu) — leak check Đạt.
- Do chưa có thiết bị chuẩn, mọi con số trên đều chỉ có giá trị *biết đường ranh giới sống được*; **ngưỡng "< 300 ms" chỉ là đề xuất** và phần thiết bị (SC-006) chờ PO.

### Cách nối

- `core/scripts/build-xcframework.sh`: gọi lại `spike-build.sh` (CC/sysroot/min-version, `set -eu`, delete-before-build), rồi `xcodebuild -create-xcframework` với headers `core/ffi/include/{hk.h,module.modulemap}`.
- `core/ffi/ffi.go`: bốn hàm ADR-21, recover từng hàm, mã lỗi, bảng handle int64 + mutex trong `ffi` (riêng `core/ffi/**` được import "C" theo G2), không `time.Now`/`net`.
- `Packages/HirakuBridge`: C target `CHirakuBridge` (hk.h + `spike_metrics.c` đo `CLOCK_MONOTONIC` và `mach_task_basic_info`), Swift target `HirakuBridge` (API an toàn kiểu: `open`/`call`/`close`, đọc reply rồi `hk_free`; `HirakuSpikeMetrics.timeNs/rssKb`). Không force unwrap, không `try!`.
- `App/Hiraku/{PingCheckView,Spike8}.swift` (debug-only, `#if DEBUG`): view có nút "S-8 ping check" (mở → ping → đóng, hiển thị kết quả); harness đo chạy khi env `HK_SPIKE_RUN=1`, ghi JSON ra `HK_SPIKE_OUT`, không print.
- `App/Hiraku.xcodeproj/project.pbxproj`: thêm `XCLocalSwiftPackageReference ../Packages/HirakuBridge` + product dependency + per-SDK `OTHER_LDFLAGS[sdk=…]= -force_load <flat .a>` (3 file `core/.spike/{darwin,ios,iossimulator}_arm64.a`). vì vậy không dựa vào cơ chế chọn slice tự động của xcframework.

### Chưa xác minh / vượt QR

- **Thiết bị chuẩn**: cần PO chạy app trên iPhone/iPad thật (SC-006). Ngưỡng **"< 300 ms" là đề xuất cần PO xác nhận** trên thiết bị.
- **Contract thật `hiraku.v1`** (method enum, protobuf, mã lỗi 2/3, giao thức `err` trả về thông điệp, golden): WP-01.
- **Test riêng cho package `main` ffi**: `go vet`/`go test ./...` sạch; spike dùng run thực trên hai platform thay vì unit test riêng (chưa có golden file để test).
- **"Go counters tăng đơn điệu" trong ADR-21/S-8**: spike dùng RSS `mach_task_basic_info` như đề bài; việc đo `runtime.ReadMemStats`/`runtime/metrics` của Go cụ thể còn cần hook debug riêng — chưa có thiết bị để đo.
- **Kiểm từ ngoài**: `footprint`/`ps rss` không chạy được đối chiếu chính xác trong cùng lúc app đang chạy; chỉ có số RSS in-process. RSS máy có dao động GC bình thường.

### Kết luận S-8 theo dòng chấp nhận

| Dòng | Verdict |
|---|---|
| Archive + framework (script, 3 slice, headers, exit 0) | Đạt |
| ABI: 4 hàm ADR-21, `recover`, mã lỗi 0…5, không Go pointer | Đạt |
| Bridge package type-safe, `hk_free` ngay sau đọc; app link; màn hình debug ping thành công | Đạt |
| Chạy macOS + simulator với DB path scratch | Đạt |
| Đo: startup (cold + 20 lần), per-call 1.000 (median/p95), leak RSS | Đạt — **simulator/host, not device** |
| Thiết bị chuẩn (SC-006), ngưỡng 300 ms, contract thật WP-01 | chưa xác minh |

Cảnh báo driver: build c-archive in cảnh báo `gethostuuid() is disabled` từ `sqlite3-binding.c` của mattn (lỗi subsystem có chủ đích của sandbox Apple); không ảnh hưởng hành vi trên Apple và đã xuất hiện từ Spike 0.

## S-6 — Đóng gói Noto Sans JP

Nguồn: `google/fonts` `ofl/notosansjp/NotoSansJP[wght].ttf` (variable, 9.589.900 B, v2.004) và `OFL.txt` cùng thư mục, tải 2026-10-31. OFL 1.1 cho phép đóng gói và subset; Reserved Font Name là "Source", bản subset giữ tên "Noto Sans JP" nên hợp lệ; `OFL.txt` được đưa vào bundle.

Build: `uv run --with fonttools --with brotli Scripts/build-noto-jp.py <NotoSansJP[wght].ttf> App/Hiraku/Fonts/NotoSansJP-Regular.ttf`. Cố định `wght=400` (DESIGN `jp-hero`/`jp-term` đều 400), bỏ hinting, giữ `kern/vert/vrt2/palt/ccmp`, sửa name/PostScript thành `NotoSansJP-Regular`. Charset: ASCII, dấu câu CJK/fullwidth, kana, toàn bộ JIS X 0208 (6.355 kanji ⊃ jōyō ⊃ JLPT N5–N1) — 7.192 codepoint yêu cầu, 7.167 có glyph trong font.

| Chỉ số | Kết quả |
|---|---|
| Kích thước file | 2.293.328 B (2,19 MiB), ngưỡng 10 MB → Đạt |
| Thêm vào app | ≈ 2,2 MB (`du`: 2240 KB trong `.app`, cả iOS simulator và macOS) |
| Glyph | 1.251 ký tự non-Latin của 880 mục N3 (`docs/mimikara-n3`): thiếu 0 → Đạt |
| Giấy phép | OFL 1.1 → Đạt |
| Hiển thị | `FontCheckView` (debug) trên iPhone 18 Pro simulator: `CTFontCopyFamilyName == "Noto Sans JP"`, 開/kana/kanji hiếm (憂鬱, 薔薇) đúng, đối chiếu cạnh fallback hệ thống → Đạt |
| Build | macOS và iOS simulator `BUILD SUCCEEDED` |

Kết luận: phương án A (đóng gói) đạt cả ba tiêu chí S-6 → đề xuất chốt Q-5 = A (quyền PO/Design).

Chưa xác minh: danh sách JLPT N5–N1 chính thức (không có nguồn trong repo; dùng JIS X 0208 làm cận trên); chạy macOS (chỉ build); thiết bị thật; trọng số khác 400 (mỗi static weight thêm ≈ 2,3 MB); đăng ký bằng `CTFontManagerRegisterFontsForURL` lúc chạy thay vì Info.plist như DESIGN §Font (một đoạn mã dùng chung hai nền tảng; DESIGN cần cập nhật khi chốt).


## S-3 — IME: nhận biết compose và Return chốt IME

Cài đặt: `App/Hiraku/KanaInputField.swift` bọc `UITextField` (iOS/iPadOS) và `NSTextField` (macOS) thành một trường nhập thật (ADR-09); `ImeCheckView` (debug) phản chiếu text thành từng ô, đổi màu ô khi đang compose, đếm số lần nộp.

- **Nhận biết compose**: iOS `markedTextRange != nil` (cập nhật qua `.editingChanged`); macOS `NSTextView.hasMarkedText()` (qua `controlTextDidChange`). `updateUIView`/`updateNSView` không ghi đè text khi đang compose để không hủy marked text.
- **Return chốt IME**: iOS `textFieldShouldReturn` — có marked text thì `unmarkText()` và không nộp; macOS `control(_:textView:doCommandBy:)` với `insertNewline:` — có marked text thì trả `false` để IME xử lý, không nộp.

| Kiểm tra | Cách | Kết quả |
|---|---|---|
| Build macOS, iOS simulator | `xcodebuild` (hai destination) | `BUILD SUCCEEDED` |
| iOS: compose được nhận biết | iPhone 18 Pro simulator, nút debug đặt marked text "か" bằng `setMarkedText` | `composing: true`, ô vàng, text `djか` |
| iOS: Return khi đang compose | nút debug gọi đường `textFieldShouldReturn` | `composing: false`, `submits: 0` — Đạt |
| iOS: Return sau khi chốt | như trên | `submits: 1`, `graded: djか` — Đạt |

**Chưa xác minh (đây là điểm chính của S-3):** marked text trong các kiểm tra trên do mã debug đặt bằng API, **không phải IME Nhật thật**. Chưa kiểm: bàn phím kana/romaji thật trên iPhone, bàn phím phần cứng trên iPad, IME macOS; macOS chỉ build, chưa chạy; việc `textFieldShouldReturn` có được gọi khi IME thật đang compose hay không (nhánh `markedTextRange != nil` có thể không bao giờ chạy trên iOS, khi đó IME tự tiêu thụ Return và kết quả vẫn đúng); thanh gợi ý và VoiceOver. Cần PO thử tay trên thiết bị theo SC-007 trước khi coi S-3 Đạt (GATE-1).

## S-5 — Hai cửa sổ cùng chấm một DB

Mã: `core/spike/storage/concurrent_grade_test.go`, chạy trên bản sao fixture S-1 (50.000 thẻ) với `gradeOnce` của S-1 (đọc `card_states` trong transaction, cập nhật, ghi một `review_logs`). Hai "cửa sổ" là hai goroutine chấm xen kẽ cùng 10 thẻ, mỗi cửa sổ 200 lần; thẻ trùng giữa hai cửa sổ chính là tình huống UC-08 E6. Kiểm: `PRAGMA integrity_check = ok`, đúng 400 `review_logs` mới, và với mỗi thẻ `prev_reps` của các log xếp theo thứ tự liền nhau (0,1,2…): một lần chấm dùng trạng thái cũ sẽ lặp giá trị.

```sh
cd core
HIRAKU_SPIKE_S1=1 go test -race -run 'TestTwoWindows|TestTwoHandles' -v -count=1 ./spike/storage
```

| # | Kịch bản | Kết quả | Kết luận |
|---|---|---|---|
| 1 | Một handle core dùng chung (`MaxOpenConns(1)`, thiết kế R-05) | 400/400 lần chấm thành công, 356 ms, không log mất/trùng, `prev_reps` liền mạch, `integrity_check` ok, `-race` sạch | Đạt |
| 2 | Hai handle riêng cùng một file, `_txlock=immediate` | 400/400 thành công, 379 ms, cùng kiểm tra đạt | Đạt |
| 3 | Hai handle riêng, `_txlock=deferred` (mặc định) | **267–282/400 lần chấm lỗi `database is locked`** (ba lần chạy), DB không hỏng (`integrity_check` ok) | Không dùng được |

Kết luận: trong thiết kế hiện tại (một handle core, một writer) S-5 **Đạt**: chấm trùng thẻ không hỏng dữ liệu và mỗi lần chấm đọc lại trạng thái mới nhất. Phát hiện cho WP-02a: transaction chấm điểm bắt đầu bằng `SELECT` rồi `UPDATE` nên với `deferred` sẽ lỗi `SQLITE_BUSY` ngay khi có hai handle (cửa sổ phụ, widget/extension ở tiến trình khác, S-7) dù đã có `busy_timeout`; mọi handle ghi phải mở với `_txlock=immediate`, hoặc chỉ một handle ghi.

Chưa xác minh: hai cửa sổ thật (macOS/iPad) qua UI, hai tiến trình khác nhau (test dùng hai handle trong một tiến trình, cùng cơ chế khóa file), widget ghi (S-7), thiết bị thật.

## S-1 bổ sung — đo lại trên schema ADR-27

Fixture S-1 đã dựng trên schema ADR-27 (`note_types`/`note_type_fields`/`card_templates`/`notes`/`cards`/`card_states`, `search_text`, `sort_field`; xem bảng Fixture ở S-1), nên đây là lần chạy lại cả bộ đo trên cùng MacBook (M4 Pro) ngày 2026-10-31, không đổi mã. Cùng lệnh như S-1; DB dựng lại từ đầu (`TestBuildFixture`: 90.759.168 B sau VACUUM, khớp lần trước).

**Điều kiện đo không sạch**: lúc chạy, load average 5,6–5,9 (GeForceNOW, WindowServer và Claude chạy nền), nên mọi số có nhiễu; số sạch ngày 2026-10-30 vẫn là số tham chiếu.

| Hạng mục | 2026-10-30 (sạch) | 2026-10-31 (máy tải) | Ngưỡng |
|---|---|---|---|
| Cold open không kiểm tra / `quick_check` / `integrity_check` (median) | 0,595 / 90,0 / 324,1 ms | 0,602 / 70,5 / 289,4 ms | < 1,5 s |
| Dựng hàng đợi cap 1.000 (median / p95) | 132,0 / 136,8 ms | lần 1: 817,6 / 1.138 ms · lần 2: 210,9 / 853,2 ms | < 200 ms |
| Dựng hàng đợi không cap (median / p95) | 149,1 / 150,6 ms | lần 1: 934,8 / 1.296 ms · lần 2: 156,6 / 164,0 ms | < 200 ms |
| Tìm `LIKE` 3 ký tự substring (median / p95) | 5,6 / 6,0 ms | lần 1: 37,8 / 44,8 ms · lần 2: 5,7 / 5,9 ms | < 150 ms |
| Transaction chấm điểm (median / p95) | 115,9 / 155,5 µs | 583,2 µs / 2,32 ms | — |
| ChangeSet reload 1 giờ / 7 ngày (median) | 1,2 / 17,1 ms | 7,2 / 132,8 ms | — |

Đọc kết quả: khi máy rảnh hơn (lần 2) tìm kiếm và hàng đợi không cap trở về mức cũ; hàng đợi có cap vẫn có đuôi dài (median 211 ms, p95 853 ms) cho thấy biên 200 ms rất mỏng (≈1,3× khi sạch) và nhạy với tải nền. Không rút kết luận Đạt/Không đạt mới từ lần chạy nhiễu: giữ kết luận S-1 (Đạt trên MacBook sạch, biên mỏng) và chuyển việc đo hàng đợi sang thiết bị chuẩn kèm phương án `ANALYZE`/index đã ghi ở "Chưa xác minh" của S-1.

**Chưa xác minh**: giữ 60 fps khi reload theo phạm vi `ChangeSet` (cần UI Swift và Instruments trên thiết bị; không đo được trên simulator hay host), thiết bị chuẩn iPhone/iPad (Q-11), đo lại khi máy rảnh.

## S-4 — Layout thích ứng

Mã: `App/Hiraku/AdaptiveCheckView.swift` (debug-only, bật bằng biến môi trường `HK_SPIKE_S4=1`, chọn trong `HirakuApp`). Một `@Observable` controller (`SampleWordsController`) cấp dữ liệu giả cho cả hai View. Compact (`horizontalSizeClass == .compact`): `TabView` + `NavigationStack` + `List` + `tabViewBottomAccessory` ("Đến hạn: 12 từ" + "Ôn ngay"). Regular: `NavigationSplitView` (sidebar) + `Table` ba cột + `.inspector` với `inspectorColumnWidth(min:ideal:max: 230)`. Tất cả là thành phần hệ thống, không tùy biến kiểu dáng (ADR-15). Chạy: `SIMCTL_CHILD_HK_SPIKE_S4=1 xcrun simctl launch <udid> com.example.hiraku`.

| Nền tảng | Cách kiểm | Kết quả |
|---|---|---|
| macOS | `xcodebuild -destination 'platform=macOS' build` | `BUILD SUCCEEDED`; app khởi chạy (tiến trình chạy); **không chụp được màn hình** (thiếu quyền Screen Recording/Accessibility) → hiển thị macOS chưa xác minh |
| iPhone 18 Pro simulator (iOS 27.0) | build + chụp ảnh | `TabView` kính với ba tab và phụ kiện đáy hiển thị; tab Deck là `List` cuộn dưới kính, chữ Noto Sans JP đọc rõ; phụ kiện đáy hiện ở **mọi** tab kể cả Trang chủ (ADR-15 muốn ẩn ở Trang chủ: cần điều kiện theo tab chọn, chưa làm) |
| iPad Pro 11-inch (M5) simulator, dọc | build + chụp ảnh | `NavigationSplitView` sidebar + `Table` + inspector hiển thị, inspector 230pt; Table chỉ hiện hai cột "Từ", "Cách đọc" — cột "Nghĩa" bị ẩn khi sidebar và inspector cùng mở ở bề ngang dọc (cần kiểm ngang, đóng sidebar/inspector, và đặt ưu tiên cột) |

Kết luận: các thành phần gốc (`TabView` + phụ kiện đáy, `NavigationSplitView`, `Table`, `inspector`) dựng được với một controller dùng chung, khác biệt nằm ở View, nên **chưa có dấu hiệu S-4 không đáp ứng** (điều kiện xem lại ADR-15). Cần xác minh trên thiết bị thật theo ADR-15: nội dung cuộn dưới kính đọc được, tab đang chọn đọc được, phụ kiện đáy và tab bar không che CTA — ảnh simulator không thay kiểm thiết bị.

Chưa xác minh: macOS (hiển thị), iPad ngang và đa cửa sổ, thiết bị thật, tương phản tab chọn Ember trên kính (chưa đặt `AccentColor`), ẩn phụ kiện đáy theo tab, ba cột của Table ở bề ngang hẹp.

