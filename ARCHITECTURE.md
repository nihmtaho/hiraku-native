# Kiến trúc — hiraku (開く) · Native Swift + Go core

**Ngày**: 2026-10-29
**Phiên bản**: 2.2
**Đối tượng**: lập trình viên và công cụ AI triển khai mã.
**Ưu tiên**: tài liệu này là nguồn có hiệu lực cho luật và cấu trúc mã. `spec.md` chỉ còn con trỏ tới đây với §2.2–2.3, §5.1–5.2. Lịch sử thay đổi: `CHANGELOG.md`.
**Không lặp lại**: yêu cầu (`spec.md`), use case (`use-cases.md`), quyết định và lý do (`DECISIONS.md`), giá trị hình ảnh (`DESIGN.md`).

---

## 1. Mục tiêu và ràng buộc

**Mục tiêu**
- Logic nghiệp vụ và dữ liệu tái sử dụng được cho nền tảng khác (ADR-20, ADR-25).
- Mỗi tính năng là một module độc lập, ghép nối và tái sử dụng được.
- Logic nghiệp vụ kiểm thử được mà không cần giao diện hay thiết bị.
- Một Controller dùng chung cho iPhone, iPad, Mac; chỉ View và shell khác nhau.

**Ràng buộc**
- iOS 26, iPadOS 26, macOS 26 (Apple silicon) — ADR-13.
- Swift 6 strict concurrency cho phần Swift; Go cho core.
- Offline hoàn toàn, không networking trong core — ADR-12.
- Core không phụ thuộc hệ điều hành: không `time.Now()`, không đường dẫn cố định, không keychain, không thông báo. Thời gian và đường dẫn DB do Swift truyền vào — ADR-20.
- Phụ thuộc ngoài: `modernc.org/sqlite`, `google.golang.org/protobuf`, `swift-protobuf`, công cụ `buf`, và thư viện FSRS Go nếu đạt S-2 (ADR-21…23, 26).

---

## 2. Tổng quan

```
┌────────────────────────────────────────────────────────────────┐
│ Swift (Apple)                                                  │
│  App — composition root: AppContainer, FeatureRegistry, Router │
│        shell (Tab/Split), Commands (menu macOS)                │
│  Feature* (Model · View · Controller)   StudyKit (UI học)      │
│  DesignSystem (token, component, AppIcon)                      │
│  HirakuModels — struct thuần, protocol Repository, Route,      │
│                 AppClock                                       │
│  HirakuBridge — actor điều khiển handle; EventHub; ánh xạ      │
│                 proto ↔ model; adapter Repository              │
├────────────────────────────────────────────────────────────────┤
│ hk_open · hk_call · hk_free · hk_close   (C ABI + protobuf)    │
│ mã lỗi số; không callback ngược (ADR-21)                       │
├────────────────────────────────────────────────────────────────┤
│ Go core (core/)                                                │
│  ffi (duy nhất import "C")                                     │
│  service — use case: Grade, BuildQueue, Search, Import, Backup │
│  domain — thuần: fsrs, kana, queue, dayboundary, importer,     │
│            backup                                              │
│  store — SQLite (modernc, WAL), migrations, repos              │
└────────────────────────────────────────────────────────────────┘
```

**Luồng đọc**: `View → Controller → HirakuModels.Repository → HirakuBridge → hk_call → service → store`. Kết quả quay về qua `await`.

**Luồng ghi**: cùng đường; core trả `ChangeSet`; `HirakuBridge` phát vào `EventHub`; Controller liên quan tải lại (ADR-24).

---

## 3. Cấu trúc workspace

```
hiraku/
├─ AGENTS.md                      # quy tắc ngắn cho công cụ AI
├─ Hiraku.xcodeproj
├─ core/                          # Go — nguồn nghiệp vụ và dữ liệu (ADR-20, ADR-25)
│  ├─ go.mod
│  ├─ proto/hiraku/v1/            # contract, nguồn duy nhất (ADR-22)
│  ├─ gen/hirakuv1/               # sinh từ proto, không sửa tay
│  ├─ domain/                     # thuần, không I/O
│  │  ├─ fsrs/   kana/   queue/   dayboundary/   importer/   backup/   notetype/
│  ├─ store/                      # SQLite modernc, WAL (ADR-23)
│  │  ├─ migrations/              # tiền tố tăng dần; PRAGMA user_version
│  │  └─ repos/                   # truy vấn; kiểu record nội bộ
│  ├─ service/                    # use case: Grade, BuildQueue, Search…
│  ├─ ffi/                        # package main; DUY NHẤT import "C"
│  ├─ testdata/                   # golden: vector FSRS, bảng kana, CSV/backup mẫu, proto bytes
│  └─ scripts/                    # build-xcframework.sh, check-core.sh
├─ App/                           # composition và shell
│  ├─ HirakuApp.swift
│  ├─ Composition/                # AppContainer, FeatureRegistry, Router
│  ├─ Shell/                      # RootTabView (iPhone), RootSplitView (iPad/Mac), MenuCommands
│  └─ Resources/                  # Assets, Fonts, Localizable.xcstrings, SampleData
├─ Extensions/                    # M4: HirakuWidget (chỉ đọc)
├─ Packages/
│  ├─ HirakuModels/               # struct, protocol Repository, Route, AppClock
│  ├─ HirakuBridge/               # actor, EventHub, ánh xạ proto ↔ model, adapter Repository
│  ├─ HirakuTesting/              # fake Swift cho Controller (không chứa logic nghiệp vụ)
│  ├─ DesignSystem/               # Tokens (HK*), Components, Icons (AppIcon)
│  ├─ StudyKit/                   # StudyMode, StudySessionController (UI), GradeBar, DoneView
│  └─ Features/
│     ├─ FeatureHome/   FeatureFolders/   FeatureDecks/   FeatureWords/
│     ├─ FeatureStudy/  FeatureFlashcard/ FeatureTyping/  FeatureSettings/
│     └─ FeatureStats/  FeatureDataTransfer/  FeatureOnboarding/
├─ Frameworks/
│  └─ HirakuCore.xcframework      # sinh bởi build-xcframework.sh; không commit tay
├─ Scripts/                       # check-imports.sh, import-rules.txt
└─ *.md                          # tài liệu ở root repo (Q-13)
```

**Khuôn mẫu một feature Swift**

```
FeatureWords/
├─ Package.swift
├─ Sources/FeatureWords/
│  ├─ FeatureWords.swift          # điểm vào công khai + Dependencies
│  ├─ Model/                      # kiểu và logic riêng của feature (WordQuery, DuplicateChecker…)
│  ├─ View/                       # SwiftUI thụ động
│  └─ Controller/                 # WordListController, WordFormController
└─ Tests/FeatureWordsTests/       # test Controller với fake HirakuTesting
```

`Package.swift` của feature (mẫu; kiểm tra phiên bản tools và `.v26` theo Xcode đang dùng):

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FeatureWords",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "FeatureWords", targets: ["FeatureWords"])],
    dependencies: [
        .package(path: "../../HirakuModels"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../HirakuTesting"),
    ],
    targets: [
        .target(name: "FeatureWords", dependencies: [
            .product(name: "HirakuModels", package: "HirakuModels"),
            .product(name: "DesignSystem", package: "DesignSystem"),
        ]),
        .testTarget(name: "FeatureWordsTests", dependencies: [
            "FeatureWords",
            .product(name: "HirakuTesting", package: "HirakuTesting"),
        ]),
    ]
)
```

**Khuôn mẫu một domain Go**

```
core/domain/fsrs/
├─ fsrs.go          # Next, Preview — hàm thuần
├─ fsrs_test.go     # table-driven, đọc golden từ core/testdata/fsrs/
```

---

## 4. Luật phụ thuộc

### 4.1 Swift

```
App ──► Feature* ──► StudyKit ──► HirakuModels ◄── HirakuBridge ──► hk_call (Go core)
 │          │            │                              ▲
 │          └────────────┴──► DesignSystem (SwiftUI)    │
 └─ biết concrete type; nối mọi thứ ────────────────────┘
```

| Module | Được import | Cấm |
|---|---|---|
| `HirakuModels` | Foundation | SwiftUI, UIKit, AppKit, `HirakuBridge`, mọi module khác |
| `HirakuBridge` | Foundation, `HirakuModels`, `HirakuCoreC` (module map), `SwiftProtobuf`, module proto sinh | SwiftUI, Feature*, `DesignSystem` |
| `HirakuTesting` | Foundation, `HirakuModels`, Swift Testing | `HirakuBridge`, UI |
| `DesignSystem` | Foundation, SwiftUI | `HirakuModels` và mọi module khác |
| `StudyKit` | Foundation, SwiftUI, `HirakuModels`, `DesignSystem` | `HirakuBridge`, feature |
| `Feature*` | Foundation, SwiftUI, `HirakuModels`, `DesignSystem`; thêm `StudyKit` chỉ với `FeatureStudy`, `FeatureFlashcard`, `FeatureTyping` | `HirakuBridge`, `hk_*`, feature khác, `App` |
| `App` | tất cả | — |
| Test target | module cần test + `HirakuTesting` | `HirakuBridge` (trừ test của chính nó) |

### 4.2 Luật Swift (có hiệu lực)

| # | Luật | Kiểm tra |
|---|---|---|
| L1 | Thư mục `Model`/`View`/`Controller` trong mỗi feature; View không truy cập Repository, không chứa logic nghiệp vụ, không gọi `Date()` | Review + grep `*Repository`, `Date()` trong `View/` |
| L2 | Controller là `@MainActor @Observable final class`, nhận phụ thuộc là **protocol** qua `init`; không singleton, không global | Review |
| L3 | `Controller.init` không làm I/O; nạp dữ liệu ở `start()` | Review |
| L4 | Feature không import feature khác và không import `HirakuBridge`; giao tiếp qua `Route`, closure `navigate`, slot `@ViewBuilder` | Tự động (`check-imports.sh`) |
| L5 | Swift không có transaction và không ghi `card_states`/`review_logs`. Mọi ghi nhiều bảng là một RPC trong core | Review + test ở core |
| L6 | Romaji và kana chỉ ở core (`domain/kana`). Swift không tự chuẩn hóa đáp án | Review |
| L7 | Thời gian: `AppClock` ở Swift cấp `now_ms` vào mọi RPC cần thời điểm. Không `Date()`, `Task.sleep` trực tiếp trong Controller | Tự động (grep) |
| L8 | Màu/cỡ chữ/bo góc từ `HK*`; icon qua `AppIcon`; chuỗi trong String Catalog | Tự động (grep hex và literal) |
| L9 | Phụ thuộc mới cần ADR. Hiện đã chốt: `swift-protobuf` (ADR-22), XCFramework (ADR-21) | Review + manifest |
| L10 | Swift 6 strict; không `@unchecked Sendable` thiếu lý do; không `try!`, không force unwrap trong logic nghiệp vụ; chỉ `HirakuBridge` gọi `hk_*` | Compiler + grep |
| L11 | Chrome điều hướng (tab bar, sidebar, toolbar, sheet, inspector) là thành phần gốc Liquid Glass; không tùy biến nền/viền; kính thủ công (`glassEffect`) chỉ trong `DesignSystem`, cho điều khiển nổi, không dùng trên thẻ nội dung (ADR-15) | Review + grep `glassEffect`, `Material` ngoài `DesignSystem` |

### 4.3 Luật Go (G1–G8, mới)

| # | Luật | Kiểm tra |
|---|---|---|
| G1 | Chỉ `core/ffi` được import `"C"` | `check-core.sh` |
| G2 | `domain` không import `store`, `service`, `ffi`; `domain` không I/O | `go list -deps` + `check-core.sh` |
| G3 | Không `time.Now()`, `time.Sleep` trong `domain` và `service`. Thời gian vào qua request (`now_ms`) | `check-core.sh` |
| G4 | Không biến toàn cục có trạng thái. Trạng thái nằm trong handle mở bởi `hk_open` | Review + `go vet` |
| G5 | Không import `net`, `net/http` hoặc thư viện mạng (ADR-12) | `go list -deps` trong `check-core.sh` |
| G6 | Mỗi hàm export trong `ffi` có `recover`; không để panic đi qua ranh giới | Review + test panic |
| G7 | `gen/` không sửa tay; chỉ sinh từ `proto/` | `buf` và review |
| G8 | `go vet` và `go test -race ./...` xanh; không `unsafe` ngoài `ffi` | CI |

### 4.4 Quy tắc phong cách mã (C1–C8)

Áp dụng cho mọi mã, cả Swift lẫn Go, kể cả mã do AI agent viết. Mục tiêu: mã vừa đủ, dễ đọc, comment ngắn (ADR-16).

| # | Quy tắc |
|---|---|
| C1 | **Đơn giản trước.** Dùng cách đơn giản nhất đáp ứng yêu cầu hiện tại. Không thêm lớp trừu tượng, interface, generic, macro, property wrapper hay operator tùy biến "để sau này dùng". Ngoại lệ: các điểm mở rộng đã định (Repository, `StudyMode`, `ImportFormat`, RPC mới). |
| C2 | **Không viết mã cao siêu.** Tránh mẹo, type-erasure, ràng buộc generic phức tạp, result builder, `@dynamicMemberLookup`, reflection, chuỗi `map`/`filter`/`reduce` dài quá 3 bước. Nếu bắt buộc, nêu lý do trong mô tả thay đổi. |
| C3 | **Dễ đọc ngay.** Hàm ngắn, làm một việc; tên rõ nghĩa thay cho comment; `guard`/return sớm; lồng tối đa 3 cấp. |
| C4 | **Dùng sẵn của ngôn ngữ và framework** trước khi tự viết (Swift/SwiftUI; Go stdlib). |
| C5 | **Thay đổi vừa đủ.** Chỉ sửa phần được yêu cầu; không refactor, đổi tên, định dạng lại mã không liên quan. |
| C6 | **Comment ngắn, chỉ về mã, viết bằng tiếng Anh.** Chỉ viết khi giải thích *vì sao*. Một dòng, đặt sát dòng liên quan. Không viết: mô tả lại mã; tham chiếu FR/UC/ADR/WP/ticket; ngày, tác giả; khối chú thích dài; nội dung thuộc tài liệu; mã bị comment. `///` (Swift) hoặc doc comment (Go) chỉ cho API công khai khi tên và chữ ký chưa đủ, tối đa 2 dòng. Ngoại lệ: `// TODO(Q-xx): …`. |
| C7 | **Sạch.** Không `print`, `fmt.Println` còn lại; không mã chết; không import thừa; không biến không dùng. |
| C8 | **Test vừa đủ.** Kiểm hành vi theo UC và quy tắc nghiệp vụ, không kiểm chi tiết cài đặt; test ngắn, mỗi test một ý. |

```swift
// Good: explains a non-obvious reason
// Wraps UIKit to detect marked text; SwiftUI does not expose compose state.

// Bad: restates the code and cites docs
// Load words by deck (see FR-006, ADR-03, spec §4) then filter by query.
```

---

## 5. Khuôn mẫu Swift (MVC)

### 5.1 Model — entity và Repository (`HirakuModels`)

```swift
public struct WordID: Hashable, Sendable, Codable, RawRepresentable {
    public let rawValue: String                      // UUIDv7, do core cấp
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct Word: Identifiable, Equatable, Sendable {
    public let id: WordID
    public var deckID: DeckID
    public var word: String
    public var reading: String                       // rỗng = "không có kanji"
    public var meaning: String
    public var example: String
    public var createdAt: Date
    public var updatedAt: Date
}

public protocol WordRepository: Sendable {
    func page(in deck: DeckID, query: WordQuery, cursor: Int) async throws -> WordPage
    func add(_ draft: WordDraft, nowMs: Int64) async throws -> ChangeSet
    func softDelete(_ ids: [WordID], nowMs: Int64) async throws -> ChangeSet
}
```

Ghi chú: `Word.createdAt` và `updatedAt` là `Date` ở Swift; core lưu epoch ms. Việc chuyển đổi nằm ở `HirakuBridge`, không ở `HirakuModels`. `Word` minh họa kiểu hệ thống; với kiểu tùy biến, Swift nhận note là danh sách `(field_id, value)` kèm định nghĩa kiểu (§8, ADR-27).

### 5.2 Controller (`Feature*/Controller`)

Controller không giữ luồng dữ liệu liên tục. Nó tải lại khi nhận sự kiện từ `EventHub` (ADR-24).

```swift
@MainActor @Observable
public final class WordListController {
    public private(set) var rows: [Word] = []
    public private(set) var phase: LoadPhase = .loading
    public var searchText = "" { didSet { scheduleReload() } }

    private let deck: DeckID
    private let words: any WordRepository
    private let events: any ChangeEvents
    private let clock: any AppClock
    private let navigate: @MainActor (Route) -> Void
    private var listening: Task<Void, Never>?
    private var reloadTask: Task<Void, Never>?

    public init(deck: DeckID, words: any WordRepository, events: any ChangeEvents,
                clock: any AppClock, navigate: @escaping @MainActor (Route) -> Void) {
        self.deck = deck; self.words = words; self.events = events
        self.clock = clock; self.navigate = navigate
    }

    public func start() {
        listening = Task { [weak self, events, deck] in
            for await change in events.changes(for: .words(deck)) {
                guard !Task.isCancelled else { break }
                await self?.reload()
            }
        }
        scheduleReload()
    }

    public func stop() {
        listening?.cancel()
        reloadTask?.cancel()
    }

    private func scheduleReload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            do {
                try await self?.clock.sleep(for: .milliseconds(250))   // debounce
                await self?.reload()
            } catch is CancellationError {}
            catch { self?.phase = .failed(error) }
        }
    }

    private func reload() async {
        do {
            let page = try await words.page(in: deck, query: WordQuery(text: searchText), cursor: 0)
            rows = page.items
            phase = .loaded
        } catch {
            phase = .failed(error)
        }
    }

    public func open(_ word: Word) { navigate(.deck(word.deckID)) }
}
```

Ghi chú: `clock.sleep` chỉ dùng cho debounce UI, không dùng cho nghiệp vụ. Thời gian nghiệp vụ đi qua `nowMs`.

### 5.3 View (`Feature*/View`) — thụ động

```swift
/// Nhận Controller, không sở hữu.
public struct WordListView: View {
    @Bindable var controller: WordListController

    public var body: some View {
        List(controller.rows) { word in WordRow(word: word) }
            .searchable(text: $controller.searchText)
            .task { controller.start() }
            .onDisappear { controller.stop() }
    }
}

/// Sở hữu Controller (tạo một lần).
struct DeckWordsScreen: View {
    @State private var controller: WordListController
    init(make: @autoclosure () -> WordListController) {
        _controller = State(wrappedValue: make())    // chỉ khởi tạo, không I/O
    }
    var body: some View { WordListView(controller: controller) }
}
```

### 5.4 Điểm vào của feature

```swift
public struct WordsFeature: Sendable {
    public struct Dependencies: Sendable {
        public let words: any WordRepository
        public let events: any ChangeEvents
        public let clock: any AppClock
        public init(words: any WordRepository, events: any ChangeEvents, clock: any AppClock) {
            self.words = words; self.events = events; self.clock = clock
        }
    }
    private let deps: Dependencies
    public init(_ deps: Dependencies) { self.deps = deps }

    @MainActor
    public func deckWords(deck: DeckID,
                          navigate: @escaping @MainActor (Route) -> Void) -> some View {
        DeckWordsScreen(make: WordListController(deck: deck, words: deps.words,
                                                 events: deps.events, clock: deps.clock,
                                                 navigate: navigate))
    }
}
```

Feature chỉ công khai thứ App cần (`public`); mọi thứ khác `internal`.

---

## 6. Khuôn mẫu Go core

### 6.1 Contract (`core/proto/hiraku/v1/study.proto`)

```proto
message GradeRequest {
  string card_id   = 1;   // ADR-27: thẻ, không phải note
  Rating rating    = 2;   // enum có UNSPECIFIED = 0
  StudyMode mode   = 3;
  int64 elapsed_ms = 4;
  int64 now_ms     = 5;   // do Swift cấp
}
message GradeResponse {
  int64 next_due_ms = 1;
  ChangeSet changes = 2;
}
```

### 6.2 Domain thuần (`core/domain/fsrs`)

```go
package fsrs

// Next trả thẻ mới sau khi chấm. Không đọc đồng hồ, không ghi DB (G2, G3).
func Next(card Card, r Rating, now time.Time, s Settings) Card {
	// …
}

// Preview trả khoảng ôn dự kiến cho từng rating (FR-026), không ghi gì.
func Preview(card Card, now time.Time, s Settings) map[Rating]time.Time {
	// …
}
```

`now` ở đây là `time.Time` được dựng từ `now_ms` tại ranh giới `service`, không phải từ `time.Now()`.

### 6.3 Service (`core/service`)

```go
// Grade là nơi duy nhất ghi card_states và review_logs (L5).
func (s *Service) Grade(ctx context.Context, req *hirakuv1.GradeRequest) (*hirakuv1.GradeResponse, error) {
	var resp *hirakuv1.GradeResponse
	err := s.store.Tx(ctx, func(tx store.Tx) error {
		prev, err := tx.CardState(req.CardId) // đọc lại bên trong transaction
		if err != nil {
			return err
		}
		next := fsrs.Next(prev.Card, fromProtoRating(req.Rating), msToTime(req.NowMs), s.settings)
		if err := tx.UpsertCardState(next); err != nil {
			return err
		}
		if err := tx.InsertReviewLog(buildLog(prev, next, req)); err != nil {
			return err
		}
		resp = &hirakuv1.GradeResponse{NextDueMs: next.DueMs(), Changes: changeSetFor(req.CardId)}
		return nil
	})
	return resp, err
}
```

### 6.4 Biên FFI (`core/ffi`) — chỉ nơi này import `"C"`

```go
package main

/*
#include <stdint.h>
#include <stddef.h>
typedef struct { uint8_t *ptr; size_t len; } HKBytes;
*/
import "C"

//export hk_call
func hk_call(handle C.uint64_t, method C.uint32_t, req C.HKBytes, resp *C.HKBytes) (code C.int32_t) {
	defer func() {
		if r := recover(); r != nil { // G6
			code = 5
		}
	}()
	return dispatch(uint64(handle), uint32(method), goBytes(req), resp)
}
```

Hàm `dispatch` chỉ giải mã protobuf, gọi `service`, và mã hóa kết quả. Không chứa nghiệp vụ.

---

## 7. Luồng dữ liệu

**Đọc**: `Controller → Repository.page(…)` (async) → `HirakuBridge` (actor) → `hk_call` → `service` → `store` → protobuf trả về → Controller cập nhật state → View vẽ lại. Mọi kết quả danh sách có phân trang; Swift không nạp toàn bộ bảng.

**Ghi một thực thể**: `Repository.add(…)` → RPC → core ghi trong một transaction → trả `ChangeSet` → `HirakuBridge` phát `EventHub` → Controller liên quan tải lại.

**Ghi nhiều bảng** (chấm điểm, nhập, khôi phục, hàng loạt): luôn là một RPC; core mở transaction. Swift không tự tạo transaction (L5).

**Chấm điểm**:

```
FlashcardView ──intent──► StudySessionController.grade(.good)
   └► Repository.grade(cardID, rating, mode, elapsedMs, nowMs)     [HirakuModels]
        └► HirakuBridge → hk_call(Grade)                            [ADR-21]
             └► service.Grade → store.Tx {                          [Go]
                   đọc card_states (trong tx)
                   fsrs.Next(prev, rating, now)                     [thuần]
                   upsert card_states; insert review_logs (prev_*)
                 }
             ◄── GradeResponse(nextDue, ChangeSet)
   └► EventHub.publish(ChangeSet)
   └► nếu nextDue ≤ now + 20 phút: chèn lại thẻ vào hàng đợi phiên (StudySessionController)
```

**Hàng đợi, tìm kiếm, thống kê**: RPC có phân trang (cursor). Tính toán nằm ở core.

---

## 8. Persistence (`core/store`)

- **Vị trí DB**: Swift truyền đường dẫn vào `hk_open` (App Group, ADR-06; container thường khi dev, ADR-17). Core không tự chọn đường dẫn.
- **Handle**: một handle cho cả tiến trình, tạo khi khởi động app; một connection ghi; pool đọc; WAL; `busy_timeout`. Đa cửa sổ dùng chung handle (ADR-24).
- **Ranh giới kiểu**: record SQL là kiểu nội bộ của `store`. Chỉ trả kiểu proto ra ngoài.
- **Thời gian**: lưu epoch ms (INTEGER). Chuyển đổi ISO-8601 chỉ ở biên sao lưu/xuất (`domain/backup`).
- **Xóa mềm**: mọi truy vấn đọc lọc `deleted_at IS NULL` qua một hàm chung; xóa tầng (thư mục → deck → note → thẻ → trạng thái học → nhật ký) trong một transaction.
- **Kiểu ghi chú (ADR-27)**: `domain/notetype` là hàm thuần: kiểm tra định nghĩa kiểu (role, giới hạn field, mẫu thẻ), kiểm tra note theo kiểu, tính `sort_field` và `search_text`. `store` lưu `notes.fields` dạng JSON khóa theo `field_id`; Swift nhận note là danh sách `(field_id, value)` kèm định nghĩa kiểu, không parse JSON. Sửa kiểu là một RPC; `ChangeSet` báo mọi deck dùng kiểu đó.
- **Profile (ADR-28)**: DB đặt tại `profiles/<profile_id>/hiraku.sqlite`; danh sách profile lưu ở Swift (`AppStorage` trong App Group); chuyển profile = `hk_close` rồi `hk_open`; M1a chỉ có profile mặc định; core không biết khái niệm profile.
- **Migration**: danh sách hàm trong `store/migrations` có tiền tố tăng dần (`0001_initial`, `0002_…`); theo dõi bằng `PRAGMA user_version`; mỗi migration chạy trong transaction; **không sửa migration đã phát hành**.
- **Hiệu năng**: chỉ mục theo spec §4; truy vấn hàng đợi dùng `(due)`, `(state)`; không nạp toàn bộ bảng vào RAM (NFR-002).
- **Hợp đồng**: golden test cho từng RPC chạy trên SQLite file tạm; contract suite dùng chung cho mọi driver (SC-012).

---

## 9. Phiên học và plugin chế độ học

`StudyKit` (Swift) giữ phần giao diện của phiên học; logic chấm và hàng đợi nằm ở core.

```swift
public protocol StudyMode: Sendable {
    var id: StudyModeID { get }
    var title: LocalizedStringResource { get }
    var icon: AppIcon { get }
    // AnyView ở ranh giới plugin: mỗi thẻ chỉ dựng một lần.
    @MainActor func makeCardView(for card: StudyCard,
                                 session: StudySessionController) -> AnyView
}
```

- `StudySessionController` (Swift, `StudyKit`): nhận hàng đợi từ core qua `BuildQueue`, giữ thẻ hiện tại, gọi `Grade`, chèn lại thẻ theo `nextDue`, gọi hoàn tác (UC-17), đo `elapsed_ms` ở Swift và chặn trần 60 giây (spec §7.3.6) trước khi gửi.
- `FeatureFlashcard` và `FeatureTyping` mỗi bên cung cấp một `StudyMode`; **App** đăng ký vào `FeatureRegistry`. `FeatureStudy` nhận danh sách mode qua `Dependencies`, không biết concrete type.
- Thêm chế độ học mới: xem §12.

---

## 10. Điều hướng và ghép nối feature

`Route` là giá trị thuần trong `HirakuModels/Routing`:

```swift
public enum Route: Hashable, Sendable, Codable {
    case home
    case folder(FolderID)
    case deck(DeckID)
    case study(scope: StudyScope, mode: StudyModeID)
    case stats, settings, settingsData
    case importData(deck: DeckID?, folder: FolderID?)
}
```

- Mỗi cửa sổ/scene có một `Router` riêng (`NavigationPath`), cùng dùng một `AppContainer` và cùng handle core.
- Feature phát route qua closure `navigate`; `App/Composition/Router` ánh xạ route → view bằng cách gọi điểm vào của feature tương ứng.
- Ghép giao diện bằng **slot**: `FeatureHome` nhận `@ViewBuilder` cho `foldersSection` và `reviewBanner`, do App cung cấp.
- Shell theo nền tảng (`RootTabView` iPhone; `RootSplitView` iPad/Mac) dùng `TabView`, `NavigationSplitView`, `.toolbar`, `.inspector` **gốc** (ADR-15). Ma trận toolbar theo màn ở `DESIGN.md`.

---

## 11. Concurrency, lỗi, thời gian, ID

- **Swift**: Controller `@MainActor`; `HirakuBridge` là actor và là điểm duy nhất gọi `hk_call`. Lời gọi cgo chặn thread, nên không gọi từ main actor.
- **Go**: store có mutex nội bộ như lớp phòng thủ thứ hai; các transaction tuần tự hóa theo handle.
- **Job dài** (import, sao lưu, xuất): chia thành session hoặc lô, mỗi lời gọi p95 ≤ 100 ms (ADR-21): `ImportBegin → ImportAppend(chunk)… → ImportCommit`. Swift hiện tiến trình và cho hủy giữa các lô; core kiểm tra hủy ở ranh giới lô.
- **Hoàn tác**: thao tác đảo ngược được (xóa mềm, di chuyển, sắp xếp lại) đăng ký với `UndoManager` của Swift; thao tác ngược là một RPC do core thực hiện trong một transaction (FR-077).
- **Hủy**: Controller hủy `Task` ở `stop()`; View gọi `stop()` khi biến mất. Không để `Task` sống sau đó.
- **Lỗi**: core trả mã số (ADR-21). `HirakuBridge` ánh xạ sang enum Swift có kiểu (`CoreError`); Controller chuyển thành state (`LoadPhase.failed`, lỗi inline). View chỉ hiển thị chuỗi từ String Catalog. Không nuốt lỗi ghi: ghi thất bại thì không chuyển bước (UC-08 E3).
- **Thời gian**: `AppClock` ở Swift, không đặt tên `Clock` vì trùng `Swift.Clock`:

```swift
public protocol AppClock: Sendable {
    var nowMs: Int64 { get }
    func sleep(for duration: Duration) async throws   // chỉ cho debounce UI
}
```

  `SystemClock` ở App; `ManualClock` ở `HirakuTesting`. Mọi RPC có thời điểm nhận `now_ms` từ `nowMs`.
- **ID**: UUIDv7 do core sinh (tự cài trong `core/domain`, vì thư viện chuẩn không có; spec §3.1); Swift nhận chuỗi và bọc bằng kiểu `FolderID`, `DeckID`, `WordID`, `CardID` để tránh nhầm lẫn.

---

## 12. Kiểm thử

| Lớp | Công cụ | Nội dung |
|---|---|---|
| `domain` (Go) | `go test`, table-driven | FSRS theo vector, kana, hàng đợi, ngày học, parser, backup |
| `store` (Go) | `go test` + SQLite file tạm | Migration, xóa mềm, transaction, đọc lại trong transaction |
| `service` (Go) | `go test` + golden proto bytes | Contract từng RPC; đổi contract mà không đổi golden là lỗi |
| `ffi` (Go) | `go test` | Mã lỗi, `recover`, vòng lặp gọi nhiều lần không rò |
| `HirakuBridge` (Swift) | Integration test với XCFramework thật | Ánh xạ proto ↔ model, mã lỗi, `EventHub` |
| Controller (Swift) | Swift Testing + fake `HirakuTesting` + `AppClock` giả | Mọi UC P0; không cần UI, không cần core |
| E2E | XCUITest | UC P0 trên iPhone, iPad, Mac; kill app giữa phiên; hai cửa sổ |

```swift
@Test @MainActor func searchFiltersRows() async throws {
    let clock = ManualClock()
    let repo = FakeWordRepository(seed: [.fixture(word: "食べる"), .fixture(word: "飲む")])
    let c = WordListController(deck: .fixture, words: repo, events: FakeChangeEvents(),
                               clock: clock, navigate: { _ in })
    c.start(); c.searchText = "食"
    await clock.advance(by: .milliseconds(300))
    #expect(c.rows.map(\.word) == ["食べる"])
}
```

Golden test contract dùng chung: cùng một file `core/testdata/…` được Go đọc khi test core và Swift đọc khi test `HirakuBridge`. Đổi bytes mà không đổi golden là lỗi CI.

Mỗi feature Swift chạy được `swift test` độc lập với fake, không cần core (SC-011). Mỗi package Go chạy được `go test` độc lập (SC-011).

---

## 13. Checklist mở rộng

**Thêm RPC mới** (ví dụ `Search`)
1. Định nghĩa message và method trong `core/proto/hiraku/v1`; số method mới, không tái dùng số cũ.
2. `buf lint` và `buf breaking` xanh.
3. Viết logic trong `domain` (nếu thuần) và `service` (điều phối, transaction).
4. Thêm dispatch trong `core/ffi`.
5. Thêm golden proto bytes trong `core/testdata`; test `service`.
6. Ánh xạ trong `HirakuBridge`; thêm method vào `FakeWordRepository` (`HirakuTesting`).
7. Controller dùng `Repository` mới; test với fake.

**Thêm feature Swift**
1. Tạo `Packages/Features/FeatureX` theo khuôn mẫu §3; `Package.swift` chỉ phụ thuộc module được phép (§4.1).
2. Viết `Dependencies` (protocol cần dùng) và điểm vào công khai.
3. Model → Controller (test với fake) → View.
4. Thêm `Route` (nếu cần) ở `HirakuModels/Routing`; ánh xạ ở `App/Composition/Router`; đăng ký ở `FeatureRegistry`.
5. Chuỗi UI vào String Catalog; dùng token và icon của `DesignSystem`.
6. Cập nhật `Scripts/import-rules.txt`, bảng §4.1 và `spec.md` §2.4.

**Thêm chế độ học**: tạo `FeatureMode` (package mới) phụ thuộc `StudyKit`; cài `StudyMode`; đăng ký trong `FeatureRegistry`. Nếu chế độ cần quy tắc chấm mới, đặt quy tắc ở `core/domain`, không ở Swift. Không sửa `FeatureStudy`.

**Thêm migration**: tạo file mới trong `core/store/migrations` với số tăng dần; không sửa migration cũ; cập nhật `spec.md` §4 nếu schema đổi; thêm test migration từ phiên bản trước.

**Thêm định dạng nhập/xuất**: cài `ImportFormat`/`ExportFormat` trong `core/domain/importer` và đăng ký; không sửa luồng nhập chung. Swift chỉ thêm phần UI chọn định dạng.

**Thêm role field (ADR-27)**: thêm giá trị enum trong proto (không tái dùng số), quy tắc trong `domain/notetype`, golden test; chế độ học dựa vào role, không dựa vào tên field.

**Thêm token/icon**: sửa `DESIGN.md` trước, rồi `DesignSystem/Tokens` hoặc `AppIcon`; không hard-code ở feature.

---

## 14. Kiểm tra tự động (CI)

- **Proto**: `buf lint`, `buf breaking` so với nhánh chính.
- **Go** (`core/`): `go vet`, `go test -race ./...`, `core/scripts/check-core.sh`:
  - chỉ `core/ffi` có `import "C"` (G1);
  - không `time.Now`, `time.Sleep` trong `domain/` và `service/` (G3);
  - không `net`, `net/http` trong `go list -deps` (G5);
  - `domain/` không import `store/`, `service/`, `ffi/` (G2);
  - không `unsafe` ngoài `ffi/` (G8).
- **XCFramework**: `core/scripts/build-xcframework.sh` build ba slice và đóng gói; chạy trên simulator (S-8 định nghĩa tiêu chí).
- **Swift**: `Scripts/check-imports.sh` đọc `Scripts/import-rules.txt`, quét `import` trong `Sources/` của từng package; kiểm tra `Package.swift` không khai báo `HirakuBridge` trong feature; không `Date()`/`Task.sleep` ngoài `SystemClock`; không `*Repository` trong `View/`; không `glassEffect`/`Material` ngoài `DesignSystem`; không hex màu ngoài `Tokens/`; không `try!` ngoài test; không `print(` còn lại.
- **Comment**: không có tham chiếu tài liệu (`FR-`, `UC-`, `ADR-`, `WP-`) ngoại trừ `TODO(Q-xx)` (C6).
- **Build và test App**: `xcodebuild test`.

---

## 15. Thay đổi so với v1.3

Xem `CHANGELOG.md`.

---

## 16. Liên kết

`spec.md` (yêu cầu) · `use-cases.md` (UC) · `DESIGN.md` (token, UI) · `DECISIONS.md` (ADR-02, 03, 06, 09, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 24, 25, 26) · `ROADMAP.md` (WP-01…WP-10, WP-02a/02b) · `AGENTS.md` (quy tắc rút gọn) · `CHANGELOG.md` (lịch sử).
