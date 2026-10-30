---
version: 0.5.4
name: Editorial Ember (Native)
description: >
  Hệ thống thiết kế cho hiraku (開く, "mở ra / hé lộ") bản native iOS, iPadOS,
  macOS (SwiftUI). Giữ phong cách editorial tối giản: nền giấy ấm, mực đậm, một
  màu nhấn cam-đỏ duy nhất. Đơn vị là point (pt); cỡ chữ có ba mức theo nền tảng
  (phone / pad / mac); đã hiệu chỉnh theo HIG và độ tương phản truy cập.
colors:
  primary: "#16130F"
  secondary: "#6B655C"
  tertiary: "#FF4D2E"
  neutral: "#F4F1EA"
  surface: "#FFFDF8"
  on-primary: "#F4F1EA"
  on-tertiary: "#FFFFFF"
  border: "#16130F"
  border-soft: "#DED8CC"
  divider: "#E8E3D9"
  faint: "#A39C8F"
  tertiary-container: "#FFE9E3"
  tertiary-hover: "#E83F1F"
  state-new: "#3A6EA5"
  state-learning: "#D9A300"
  state-learning-ink: "#A67C00"
  state-known: "#2F9E6F"
  kana-fill: "#F0F8F4"
typography:
  display:
    fontFamily: Georgia
    fontSize: { phone: 40pt, pad: 56pt, mac: 56pt }
    fontWeight: 400
    lineHeight: 1.0
    letterSpacing: -0.02em
    dynamicType: largeTitle (giới hạn tối đa xxxLarge)
  h1:
    fontFamily: Georgia
    fontSize: { phone: 30pt, pad: 34pt, mac: 34pt }
    fontWeight: 400
    lineHeight: 1.05
    letterSpacing: -0.02em
    dynamicType: title
  h2:
    fontFamily: Georgia
    fontSize: { phone: 22pt, pad: 24pt, mac: 24pt }
    fontWeight: 400
    lineHeight: 1.1
    letterSpacing: -0.02em
    dynamicType: title2
  jp-hero:
    fontFamily: Noto Sans JP
    fontSize: { phone: 72pt, pad: 88pt, mac: 88pt }
    fontWeight: 400
    lineHeight: 1.1
    letterSpacing: -0.03em
    dynamicType: không co giãn theo Dynamic Type; tự thu nhỏ đến 40pt rồi xuống dòng
  jp-term:
    fontFamily: Noto Sans JP
    fontSize: { phone: 20pt, pad: 20pt, mac: 18pt }
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: -0.01em
    dynamicType: title3
  body-md:
    fontFamily: Helvetica Neue
    fontSize: { phone: 15pt, pad: 15pt, mac: 13pt }
    fontWeight: 400
    lineHeight: 1.45
    dynamicType: body
  body-sm:
    fontFamily: Helvetica Neue
    fontSize: { phone: 13pt, pad: 13pt, mac: 11pt }
    fontWeight: 400
    lineHeight: 1.4
    dynamicType: footnote
  label-caps:
    fontFamily: Helvetica Neue
    fontSize: { phone: 11pt, pad: 11pt, mac: 11pt }
    fontWeight: 700
    letterSpacing: 0.2em
    dynamicType: caption
  eyebrow:
    fontFamily: Helvetica Neue
    fontSize: { phone: 12pt, pad: 12pt, mac: 11pt }
    fontWeight: 700
    letterSpacing: 0.24em
    dynamicType: caption
  button:
    fontFamily: Helvetica Neue
    fontSize: { phone: 15pt, pad: 15pt, mac: 13pt }
    fontWeight: 700
    letterSpacing: 0.01em
    dynamicType: headline
rounded:
  xs: 4pt
  sm: 10pt
  md: 14pt
  lg: 20pt
  pill: capsule
spacing:
  xs: 4pt
  sm: 8pt
  md: 12pt
  lg: 18pt
  xl: 24pt
  xxl: 40pt
border:
  width: 1.5pt
  hairline: 1pt
hit-target:
  touch-min: 44pt
  pointer-min: 28pt
components:
  banner-review:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg}"
  button-primary:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-tertiary}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    height: { touch: 44pt, pointer: 32pt }
    padding: 0 20pt
  button-primary-hover:
    backgroundColor: "{colors.tertiary-hover}"
    textColor: "{colors.on-tertiary}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
    border: "1.5pt {colors.border}"
  button-dark:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.pill}"
  card-surface:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    border: "1.5pt {colors.border}"
    padding: "{spacing.lg}"
  flashcard-front:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    rounded: "{rounded.lg}"
    border: "1.5pt {colors.border}"
    padding: "{spacing.xxl}"
  flashcard-back:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.lg}"
    padding: "{spacing.xxl}"
  grade-again:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.tertiary}"
    rounded: "{rounded.md}"
    height: { touch: 56pt, pointer: 44pt }
  grade-hard:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.state-learning-ink}"
    rounded: "{rounded.md}"
  grade-good:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.state-known}"
    rounded: "{rounded.md}"
  grade-easy:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.state-new}"
    rounded: "{rounded.md}"
  kana-cell-correct:
    backgroundColor: "{colors.kana-fill}"
    textColor: "{colors.state-known}"
    rounded: "{rounded.md}"
  kana-cell-wrong:
    backgroundColor: "{colors.tertiary-container}"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    border: "1.5pt {colors.tertiary}"
---

## Overview

Editorial Minimalism gặp học thuật Nhật ngữ. Giao diện gợi cảm giác một tờ broadsheet in trên giấy ấm: mực đậm, khoảng trắng rộng, mỗi màn hình một tâm điểm. Trong phiên học, tâm điểm là chính từ vựng — một kanji cỡ lớn đứng một mình.

Tài liệu này chuyển `docs/product/DESIGN.md` (web) sang native **iOS, iPadOS, macOS** viết bằng SwiftUI. Nguyên tắc chuyển đổi: **giữ nhận diện** (màu, serif/sans, bo góc, viền mực, một màu nhấn) nhưng **dùng cơ chế gốc của nền tảng** (Dynamic Type, SF Symbols, sheet, menu, focus, VoiceOver) thay vì tái tạo hành vi web. Khi phong cách và chức năng gốc xung đột, ưu tiên chức năng gốc và ghi lại ngoại lệ (§Quyết định thiết kế).

Tài liệu liên quan: `docs/product/spec.md` (§8 giao diện, §9 yêu cầu thiết kế), `docs/architecture/ARCHITECTURE.md` §3 (gói `DesignSystem`), `docs/product/use-cases.md` (§4.0 hành vi theo nền tảng).

Wordmark: **hira·ku** — chữ thường Helvetica Neue, giãn âm nhẹ (-0.02em), dấu chấm giữa "·" tô Ember. Dùng ở đầu sidebar (iPad/Mac) và màn chào lần đầu. Không viết hoa, không dùng serif.

## Thay đổi so với bản web

Bảng so sánh với `docs/product/DESIGN.md` web: `CHANGELOG.md`.

## Colors

Bảng màu xây trên tương phản cao giữa mực và giấy, cộng một màu nhấn. Màu lưu trong Asset Catalog (một appearance "Any"); mã truy cập qua `HKColor` (§Triển khai).

- **Primary (#16130F):** mực — tiêu đề, chữ chính, viền, nền thẻ mặt sau, banner, header bảng.
- **Secondary (#6B655C):** chú thích, metadata, nhãn phụ (trên nền giấy/thẻ).
- **Tertiary (#FF4D2E) "Ember":** màu nhấn duy nhất. Hover/pressed: `#E83F1F`.
- **Neutral (#F4F1EA):** nền giấy. **Surface (#FFFDF8):** nền thẻ, sáng hơn một bậc.
- **Border-soft / Divider:** đường phân cách trang trí, không dùng làm biên duy nhất của điều khiển.
- **Faint (#A39C8F):** placeholder, trạng thái disabled, trang trí. Không mang thông tin.
- **Tertiary-container (#FFE9E3):** nền thông báo lỗi nhẹ, ô sai.
- **Ba màu trạng thái học** (chấm 8pt, không thay màu nhấn): `state-new` (Mới), `state-learning` (Đang học), `state-known` (Đã biết). `state-learning-ink` (#A67C00) dùng khi trạng thái xuất hiện dưới dạng **chữ**.

**Ember được dùng cho đúng các việc sau**: CTA (`button-primary`); tiến độ (thanh tiến độ phiên, slider, toggle bật); tín hiệu "Again"/lỗi (nút Again, ô sai); điểm nhấn nhận diện được duyệt (dấu · wordmark, số lượng trong banner, Cách đọc ở mặt sau thẻ). Không dùng Ember cho nền, đường kẻ, icon không tương tác.

### Tương cảm (WCAG 2.x, đã tính)

| Cặp màu | Tỷ lệ | Kết luận / quy tắc |
|---|---|---|
| primary / neutral | 16,41 | Đạt mọi cỡ |
| primary / surface | 18,21 | Đạt mọi cỡ |
| secondary / neutral | 5,11 | Đạt chữ thường |
| secondary / surface | 5,67 | Đạt chữ thường |
| on-primary / primary | 16,41 | Đạt mọi cỡ |
| Ember / primary | 5,60 | Đạt chữ thường (banner, mặt sau thẻ) |
| faint / primary | 6,80 | Đạt; dùng làm chữ phụ **trên nền mực** |
| secondary / primary | 3,21 | **Không dùng** trên nền mực |
| on-tertiary (trắng) / Ember | 3,31 | Chỉ chữ ≥ 14pt đậm (nút 15pt bold) |
| on-tertiary / tertiary-hover | 4,07 | Như trên |
| Ember / surface | 3,25 | Chỉ chữ lớn/đậm (nút Again 15pt bold) |
| Ember / neutral | 2,93 | **Cấm** làm chữ; chỉ dùng làm nền nút hoặc nét ≥ 2pt |
| Ember / tertiary-container | 2,84 | **Cấm** làm chữ; ô sai dùng chữ `primary` (15,89) |
| state-known / surface | 3,31 | Chỉ chữ lớn/đậm (nút Good, ô kana ≥ 20pt) |
| state-known / kana-fill | 3,11 | Như trên, kèm icon dấu tích |
| state-new / surface | 5,22 | Đạt chữ thường |
| state-learning-ink / surface | 3,75 | Chữ lớn/đậm (nút Hard) |
| state-learning / surface | 2,25 | Chỉ chấm; luôn có nhãn đi kèm |
| faint / neutral, surface | 2,41 / 2,68 | **Cấm** cho chữ thông tin |

Quy tắc suy ra: (1) chữ dưới 14pt đậm/18pt thường chỉ dùng cặp ≥ 4,5; (2) chấm trạng thái không bao giờ là kênh duy nhất — luôn kèm nhãn chữ (cột "Trạng thái" trong `Table`, dòng phụ trong `List` ở iPad) và `accessibilityLabel`; (3) kiểm lại bằng công cụ trước khi phát hành.

## Typography

Bắt cặp serif hiển thị (Georgia) với sans body (Helvetica Neue); kanji dùng Noto Sans JP (đóng gói subset, fallback Hiragino Sans). Georgia và Helvetica Neue có sẵn trên iOS, iPadOS, macOS nên không cần đóng gói.

- **display / h1 / h2:** Georgia, một phần tiêu đề đặt nghiêng để tạo nhịp biên tập ("Chào buổi *sáng*").
- **jp-hero:** từ vựng làm tâm điểm; đứng giữa; một dòng, tự thu nhỏ (`minimumScaleFactor`) đến 40pt rồi mới xuống dòng, để từ dài như "ありがとうございます" không bị cắt.
- **jp-term:** kanji trong danh sách, bảng, mặt sau thẻ.
- **label-caps / eyebrow:** in hoa, giãn chữ, cho nhãn mục và dòng dẫn.
- **body-md / body-sm / button:** văn bản phụ, metadata, nút.

**Co giãn theo hệ thống**
- **iOS/iPadOS:** mọi style (trừ jp-hero) gắn `relativeTo` style Dynamic Type tương ứng trong front matter; kết quả nhân thêm `font_scale` (80–140%). display bị chặn ở `xxxLarge`.
- **macOS:** không có Dynamic Type; chỉ dùng `font_scale`.
- Từ cỡ `accessibility1` trở lên: bố cục chuyển dọc (hàng 4 nút chấm thành lưới 2×2, bảng thành danh sách) để không cắt nội dung (SC-009).

Quy tắc: không dùng serif cho nhãn in hoa hoặc số liệu; không dùng sans cho từ vựng và tiêu đề lớn.

## Layout

Bố cục theo lưới, tôn khoảng trắng, mỗi màn hình một tâm điểm.

| | iPhone (compact) | iPad regular / Mac | iPad compact (Split View hẹp) |
|---|---|---|---|
| Khung | `TabView` kính nổi: Trang chủ / Thống kê / Cài đặt (M1a: chỉ Trang chủ và Cài đặt, Thống kê thêm ở M3) | `NavigationSplitView`: sidebar kính nổi 232pt + nội dung | Như iPhone |
| Lề màn hình | `lg` 18pt | `xl` 24pt | `lg` 18pt |
| Lưới thư mục | 2 cột | 2–3 cột thích ứng (`GridItem.adaptive` tối thiểu 220pt) | 2 cột |
| Danh sách từ | `List` | `Table` đa cột | `List` |
| Phiên học | Toàn màn hình | Vùng nội dung + inspector phải 230pt (thống kê phiên + hàng đợi) | Toàn màn hình |
| Dashboard | Một cột | Hai cột 1,6fr / 1fr | Một cột |

- Sidebar (iPad/Mac): `NavigationSplitView` gốc, nổi trên nội dung theo kiểu Liquid Glass; chứa wordmark, điều hướng, cây Thư mục → Deck (mở/gập, kéo-thả để sắp xếp và di chuyển deck — FR-080) và khối "đến hạn hôm nay" ghim đáy bằng `safeAreaInset` (FR-050). Mục đang chọn theo kiểu hệ thống.
- Rail phiên học chỉ hiện khi vùng nội dung ≥ 760pt rộng; nếu hẹp hơn thì ẩn, thống kê phiên rút còn thanh tiến độ.
- Bề rộng đọc tối đa: form 480pt; thẻ học 560pt, căn giữa, cao tối thiểu 360pt.
- Luôn tôn trọng safe area; không đặt điều khiển dưới home indicator hoặc dưới tab bar.
- Thang cách: token `spacing` (4 → 40pt). Gutter thẻ `md` 12pt; khoảng cách khối `lg`–`xl`. Giá trị lẻ của bản web (padding 42, 9, 11, 15) được chuẩn hóa về thang này; không còn ngoại lệ.
- macOS: kích thước cửa sổ tối thiểu 720×520pt; nhớ kích thước/vị trí từng cửa sổ.

## Elevation & Depth

Phân lớp bằng viền mực và nền giấy/thẻ, không bằng bóng nặng.

- **Thẻ phẳng:** chỉ viền `border` 1,5pt (hợp nhất khoảng 1,4–1,5px của web), không bóng — danh sách, ô cài đặt.
- **Flashcard (nổi nhẹ):** `shadow(color: primary 0.18, radius: 10, y: 6)` — xấp xỉ bóng web `0 10 26 -18`; duyệt bằng mắt trên thiết bị thật.
- Mặt sau thẻ đảo nền sang mực thay cho hiệu ứng đổ bóng.
- Chrome hệ thống (tab bar, sidebar, toolbar, sheet, inspector) là **Liquid Glass gốc** của OS 26 (mức OS tối thiểu), nổi trên nội dung; không tùy biến nền/viền/bóng của chúng (ADR-15, §Chrome hệ thống). Nội dung vẫn phẳng; **không** tự thêm vật liệu/blur lên thẻ nội dung.

## Shapes

Bo góc `RoundedRectangle(cornerRadius:, style: .continuous)` (góc liên tục, đúng cảm giác Apple).

- **xs (4pt):** thanh tiến độ, vạch nhỏ.
- **sm (10pt):** mục sidebar, nút chấm điểm nhỏ.
- **md (14pt):** thẻ, ô nhập, ô kana, nút chấm điểm.
- **lg (20pt):** flashcard, khung học lớn.
- **pill:** `Capsule()` — nút hành động, segmented control, chấm trạng thái, avatar.
- Sheet và popover dùng bo góc hệ thống, không ghi đè.

## Iconography

**SF Symbols**, qua enum `AppIcon` trong `DesignSystem/Icons` (không rải tên symbol trong feature).

| Ngữ nghĩa (Ionicons cũ) | SF Symbol (thường / active) |
|---|---|
| home | `house` / `house.fill` |
| stats-chart | `chart.bar` / `chart.bar.fill` |
| settings | `gearshape` / `gearshape.fill` |
| search, add, refresh, close | `magnifyingglass`, `plus`, `arrow.clockwise`, `xmark` |
| chevron-back / forward | `chevron.left` / `chevron.right` |
| ellipsis-horizontal | `ellipsis` |
| create / trash | `pencil` / `trash` |
| folder / albums / keypad | `folder` / `rectangle.stack` / `keyboard` |
| play-skip-forward | `forward.end` |
| return-down-back / backspace | `return` / `delete.left` |
| đúng / sai (mới) | `checkmark` / `xmark` |

- Cỡ: 22pt trên tab bar/toolbar; 16–18pt trong dòng; vùng chạm luôn ≥ 44×44pt (iOS/iPad), ≥ 28pt (Mac).
- Style: outline cho trạng thái thường, `.fill` cho mục đang chọn; màu `currentColor` (ink), Ember khi active.
- Dùng `symbolRenderingMode(.monochrome)`; không dùng nhiều màu/palette.
- Mọi icon-only button có `accessibilityLabel` tiếng Việt.

## Components

Component dùng chung nằm trong `DesignSystem/Components`; feature không tự vẽ lại. Trạng thái bắt buộc cho mọi điều khiển tương tác: **mặc định, pressed (cảm ứng), hover (con trỏ: Mac/iPad), focus (bàn phím), disabled**.

- **button-primary:** nền Ember, chữ trắng 15pt bold (≥ 14pt đậm để đạt 3:1), `Capsule`. Cao tối thiểu 44pt (iOS/iPad), 32pt (Mac). Hover `#E83F1F`; pressed thu nhỏ 0,97 + `#E83F1F`; disabled opacity 0,4.
- **button-secondary / button-dark:** viền mực 1,5pt trên giấy / nền mực chữ giấy; cùng kích thước, trạng thái như trên.
- **banner-review:** nền mực, chữ `on-primary`, số lượng đến hạn Ember, chữ phụ `faint`; kèm `button-primary`. Trên iPad/Mac ghim đáy sidebar.
- **card-surface:** nền surface, viền mực 1,5pt, bo `md`, padding `lg`.
- **flashcard-front / back:** nội dung lấy theo mẫu thẻ của kiểu ghi chú (ADR-27). Mặt trước nền surface: field đầu tiên dùng `jp-hero` nếu role `term`, ngược lại `h2`; field sau dùng `body-md`. Mặt sau nền mực: field role `reading` tô Ember (`jp-term`), `meaning` dùng `h2`, field khác dùng `body-md` (`on-primary`). Kiểu hệ thống: mặt trước = Từ; mặt sau = Cách đọc, Nghĩa, Ví dụ. Field rỗng không hiện, không để khoảng trống. Vẫn một tâm điểm mỗi mặt. Padding `xxl`.
- **GradeButton (again/hard/good/easy):** nền surface, viền 1,5pt + chữ cùng màu: Ember / `state-learning-ink` / `state-known` / `state-new`; chữ 15pt bold; cao 56pt (iOS/iPad), 44pt (Mac). Hàng 4 nút (hoặc 2 nút Again/Good). P1: dòng khoảng ôn dự kiến (`body-sm`, `secondary`) dưới nhãn. Nhãn chữ luôn hiện — màu không phải kênh duy nhất.
- **KanaCell (gõ từ):** ô trên nền surface, 1 ô/ký tự, glyph `jp-term`. Trạng thái: *trống* (viền `secondary` 1,5pt); *đang nhập* (viền Ember 2pt); *đang compose* (gạch chân mực, chưa chấm); *đúng* (nền `kana-fill`, chữ `state-known`, icon `checkmark`); *sai* (nền `tertiary-container`, viền Ember, chữ `primary`, icon `xmark`). **Kỹ thuật:** chỉ một trường nhập thật điều khiển các ô (các ô là hiển thị phản chiếu), để IME, thanh gợi ý và VoiceOver hoạt động; không dùng một trường cho mỗi ô.
- **StateDot:** chấm tròn 8pt, ba màu trạng thái; luôn kèm nhãn chữ hoặc `accessibilityLabel`.
- **ProgressBar:** vạch `xs`, nền `divider`, phần đầy Ember; có `accessibilityValue` theo phần trăm.
- **EmptyState:** icon 28pt (ink) + `h2` + `body-md` (`secondary`) + `button-primary`. Bắt buộc có CTA trên mọi màn danh sách trống (FR-065).
- **FieldRow (M3, ADR-27):** một hàng trong danh sách field của kiểu ghi chú: tay kéo (`line.3.horizontal`), tên field (`body-md`), nhãn vai trò dạng chip viền `secondary` 1pt (`body-sm`), icon kiểu nhập (`character.textbox` cho văn bản, `textformat.alt` cho kana), dấu "bắt buộc" bằng chữ, không chỉ bằng màu. Chạm mở sheet sửa field. Dùng `List` hệ thống với `onMove`/`onDelete`; không tự vẽ kéo-thả.
- **CardPreview (M3):** thẻ thu nhỏ dùng đúng `flashcard-front / back`, tỷ lệ 0,6; chạm để lật; cập nhật ngay khi đổi mẫu thẻ. Có nhãn "Mặt trước"/"Mặt sau" (`label-caps`) và `accessibilityLabel` đọc lần lượt các field.
- **ProfileBadge (M3, ADR-28):** tên profile đang mở dạng chip viền `secondary` 1pt, chữ `body-sm` mực, icon `person.crop.square`. iPhone: dưới eyebrow ngày ở Trang chủ; iPad/Mac: đầu sidebar, dưới wordmark. Chạm mở menu chuyển profile. Chỉ hiện khi có từ 2 profile trở lên.
- **ProfileRow (M3):** hàng `List` hệ thống: tên (`body-md`), dòng phụ "N deck · dung lượng" (`body-sm`, `secondary`), dấu `checkmark` Ember cho profile đang mở kèm nhãn VoiceOver "Đang mở".
- **Bảng và sidebar:** dùng `Table` và sidebar hệ thống, không có component tùy biến (đã bỏ `table-header`, `sidebar-item-active` — ADR-15).
- **Hộp thoại nhập (sheet):** ô nhập nền surface, viền mực 1,5pt, bo `md`; nhãn `label-caps`; lỗi inline dưới ô bằng `body-sm` + icon, chữ `primary` (không dùng chữ Ember). Mac: rộng 420pt, Return = Lưu, Esc = Hủy.
- **Xác nhận xóa:** dùng `confirmationDialog`/`alert` hệ thống với vai trò `destructive` (màu đỏ hệ thống là ngoại lệ có chủ đích); nội dung nêu hậu quả theo UC-01/02/03.
- **Tìm kiếm:** `.searchable` hệ thống (không tái tạo `input-search` dạng pill); tint Ember cho con trỏ/nút.
- **Điều khiển hệ thống** (Toggle, Slider, Stepper, ProgressView): `.tint(HKColor.tertiary)`; Picker/segmented dùng style hệ thống với chữ mực.

## Chrome hệ thống và toolbar (Liquid Glass)

Quyết định ADR-15: tab bar, sidebar, toolbar, sheet và inspector là thành phần **gốc** của iOS/iPadOS/macOS 26, vẽ bằng Liquid Glass nổi trên nội dung. Ứng dụng không tùy biến kiểu dáng của chúng.

**Nguyên tắc**
- Nội dung (nền giấy, thẻ, chữ) cuộn **dưới** chrome kính; chừa inset an toàn, không đặt điều khiển bị chrome che.
- `AccentColor` của ứng dụng = Ember, nên tab đang chọn và điều khiển hệ thống tô Ember; hành động chính trong nội dung vẫn dùng `PillButton` (Ember đặc), không dùng kính.
- Kính thủ công (`glassEffect`) chỉ cho điều khiển nổi thật sự cần, bọc trong `GlassEffectContainer`; không dùng trên thẻ nội dung.
- Giảm trong suốt, Tăng tương phản, Giảm chuyển động do hệ thống xử lý; không ghi đè.
- Tên API (`tabBarMinimizeBehavior`, `tabViewBottomAccessory`, `ToolbarSpacer`, `Tab(role: .search)`, `inspector`) theo tài liệu WWDC25; xác minh với SDK đang dùng ở M0.

**Điều hướng**

| Thành phần | iPhone | iPad | Mac |
|---|---|---|---|
| Điều hướng chính | `TabView` kính nổi (Trang chủ / Thống kê / Cài đặt (M1a: chỉ Trang chủ và Cài đặt, Thống kê thêm ở M3)); thu gọn khi cuộn ở màn danh sách dài (`.onScrollDown`) | `NavigationSplitView`, sidebar kính nổi dạng cây Thư mục → Deck; Cài đặt là mục sidebar | Như iPad; Cài đặt ở cửa sổ Settings (⌘,), không nằm trong sidebar |
| Phụ kiện đáy | `tabViewBottomAccessory`: "Đến hạn: N từ" + "Ôn ngay" (P1; không hiện ở Trang chủ vì đã có banner — kiểm tra API ẩn theo tab) | Khối "Đến hạn hôm nay" ghim đáy sidebar | Như iPad |
| Tìm kiếm | `.searchable` ở màn deck (hệ thống chọn vị trí); P1: `Tab(role: .search)` cho tìm toàn app | `.searchable` trên toolbar, phía trailing | Như iPad |
| Phiên học | Toàn màn hình, ẩn tab bar | Inspector phải 230pt (thống kê phiên + hàng đợi) | Như iPad |

**Toolbar theo màn** (nút liền kề tự gom vào một viên kính; tách nhóm bằng `ToolbarSpacer(.fixed)`; hành động hiếm vào menu ⋯; tối đa 3 nút trailing trên iPhone)

| Màn | Leading | Trailing | Dưới / khác |
|---|---|---|---|
| Trang chủ | (iPad/Mac: nút ẩn/hiện sidebar hệ thống) | [+ ▾: Thư mục mới, Thêm từ nhanh (P1)] | Tab bar (iPhone) |
| Thư mục | Quay lại | [Ôn cả thư mục] ‖ [+ Tạo deck] | Tab bar |
| Deck | Quay lại | [Học ▾: Flashcard, Gõ từ] ‖ [+ Thêm từ] [⋯: Sửa deck, Di chuyển, Xóa]; iPad/Mac thêm ô tìm kiếm | Tab bar; phụ kiện "Ôn ngay" (P1) |
| Chọn nhiều từ (P1) | Xong | — | `bottomBar`: Chuyển, Đặt lại tiến độ, `ToolbarSpacer(.flexible)`, Xóa |
| Học — Flashcard | [✕ Thoát] | Bộ đếm "7 / 24"; thanh tiến độ ở giữa | `bottomBar`: Hoàn tác (P1) |
| Học — Gõ từ (iPhone) | [✕ Thoát] | Bộ đếm | Thanh bàn phím: [Bỏ qua] … [Kiểm tra] |
| Sheet thêm/sửa từ | [Hủy] | [Lưu] (vai trò xác nhận) | "Lưu và thêm tiếp" là nút trong nội dung; các ô theo field của kiểu |
| Profile (M3) | Quay lại | [+ Tạo profile] | Menu ⋯ mỗi hàng: Đổi tên, Xóa |
| Kiểu ghi chú (M3) | Quay lại / [Hủy] khi có thay đổi | [Lưu] | Kiểu hệ thống: thay [Lưu] bằng [Nhân bản]; iPhone dùng `EditButton` để sắp xếp |
| Thống kê (M3) | — | Chọn 7 / 30 ngày | Tab bar |
| Cài đặt | — | — | Tab bar |

**Việc kiểm tra ở M0 (thiết bị thật)**: (1) nội dung cuộn dưới kính vẫn đọc được trên nền giấy; (2) tab đang chọn tô Ember đủ rõ trên kính — nếu không, đổi tint của tab đang chọn về mực và giữ Ember cho CTA; (3) phụ kiện đáy và tab bar không che nút chấm điểm hoặc CTA.

## Màn hình chủ chốt

- **Trang chủ:** eyebrow ngày → `display` "Chào buổi *sáng*" → `banner-review` → lưới thư mục (`card-surface` + `StateDot` tổng hợp). Ẩn tiêu đề thanh điều hướng hệ thống; dùng tiêu đề serif trong nội dung, giữ nút toolbar hệ thống.
- **Học — Flashcard:** thanh trên (nút đóng `xmark`, `ProgressBar`, bộ đếm) → thẻ ở giữa → hàng chấm điểm ở dưới (chỉ xuất hiện sau khi lật). Không có hai tâm điểm cạnh nhau.
- **Học — Gõ từ:** lời nhắc (`jp-term` hoặc `body-md`) → hàng `KanaCell` (xuống dòng khi dài) → phản hồi → nút Bỏ qua (`forward.end`). Sai: hiện đáp án đúng trên nền mực kèm nghĩa/ví dụ, nút "Tiếp".
- **Danh sách từ:** `Table` (iPad/Mac): một cột mỗi field theo `ord` (field role `term` dùng `jp-term`), cột Trạng thái (chấm + chữ) luôn ở cuối; nhiều hơn 5 field thì ẩn bớt cột (ngưỡng PO duyệt 2026-10-28, kiểm lại trên wireframe §2.7), người dùng bật lại qua menu cột hệ thống. `List` (iPhone): hàng hai dòng — dòng 1 field `term` + field `reading`, dòng 2 field `meaning` (không có thì field kế tiếp); chấm trạng thái đầu hàng.
- **Profile (M3, ADR-28):** iPhone: màn đẩy từ Cài đặt; danh sách `ProfileRow`, chạm hàng để chuyển. iPad: mục trong Cài đặt ở sidebar. Mac: tab "Profile" trong cửa sổ Settings, kèm menu ứng dụng "Chuyển profile ▸". Khi chuyển: hiển thị trạng thái tải ngắn bằng `ProgressView` hệ thống, không có màn chờ riêng. Xóa dùng `confirmationDialog` vai trò `destructive` (D-1), hai bước. Một tâm điểm: danh sách profile.
- **Đồng bộ iCloud (M4, ADR-29, FR-092):** một `Toggle` "Đồng bộ iCloud" trong Cài đặt, mặc định tắt. Chú thích dưới công tắc nói rõ dữ liệu trên máy vẫn còn khi tắt. iPhone và iPad: mục trong Cài đặt. Mac: tab "Đồng bộ" trong cửa sổ Settings. Trạng thái tài khoản iCloud hiển thị bằng dòng phụ của hàng, không dùng hộp thoại. Xung đột được gộp tự động, không có màn hình chọn bản. Khi tắt, dữ liệu trên iCloud giữ nguyên (ADR-29).
- **Kiểu ghi chú (M3, ADR-27):** iPhone: màn đẩy từ Cài đặt hoặc menu deck; nhóm "Trường" (danh sách `FieldRow` + "Thêm trường") → nhóm "Mẫu thẻ" (chọn field mặt trước, mặt sau bằng danh sách chọn nhiều; field đáp án Gõ từ bằng `Picker`) → `CardPreview`. iPad/Mac: hai cột — trái danh sách trường, phải mẫu thẻ và `CardPreview`. Kiểu hệ thống chỉ đọc, kèm dòng giải thích và nút "Nhân bản". Một tâm điểm: danh sách trường; xem trước là phụ.
- **Thống kê:** ba số trạng thái, biểu đồ cột Swift Charts màu Ember cho tiến độ, `state-*` cho phân bố; mỗi biểu đồ có mô tả VoiceOver.

## Motion & phản hồi

- **Lật thẻ:** xoay trục Y 350 ms `easeInOut`. Khi bật *Reduce Motion*: chuyển mờ 150 ms.
- **Chuyển thẻ:** trượt/mờ 200 ms; không dùng hiệu ứng nảy (spring) — sai tinh thần editorial.
- **Kéo-thả:** dùng hiệu ứng nâng/thả của hệ thống; điểm thả hiện vạch chèn Ember 2pt giữa hai mục (hoặc viền Ember quanh thư mục đích); không đổi nền mục khác. Có đường phụ không cần cử chỉ (menu Lên/Xuống).
- **Toast hoàn tác:** viên kính nổi phía trên tab bar, ~5 giây, nút "Hoàn tác"; không chặn thao tác kế tiếp.
- **Gõ đúng:** giữ trạng thái "Chính xác!" khoảng 600 ms rồi tự chuyển; không tự chuyển khi sai.
- **Pressed/hover:** 100–150 ms.
- **Haptic (P1, FR-081, ADR-19):** nhẹ khi lật, rõ hơn khi chấm, kiểu thành công/lỗi khi Gõ từ; tôn trọng cài đặt hệ thống; không dùng trên Mac.
- Không có animation trang trí (parallax, confetti) ở màn "Xong!".

## Accessibility

Khớp `docs/product/spec.md` §8.3.

- **VoiceOver:** nhãn tiếng Việt cho mọi điều khiển; thẻ học đọc theo thứ tự: lời nhắc → (sau khi lật) đáp án → nút chấm; đúng/sai được thông báo bằng văn bản (không chỉ màu/icon).
- **Dynamic Type / cỡ chữ:** §Typography; không cắt nội dung ở mức lớn nhất và ở `font_scale` 140%.
- **Reduce Motion:** §Motion. **Increase Contrast:** viền 1,5pt → 2pt và `secondary` → `primary` cho chữ phụ.
- **Bàn phím (Mac/iPad):** mọi thao tác truy cập được không cần chuột; focus ring hệ thống, không ẩn; thứ tự Tab theo thứ tự thị giác.
- **Mục tiêu chạm:** ≥ 44×44pt; khoảng cách giữa hai mục tiêu ≥ 8pt.
- Màu không phải kênh duy nhất ở trạng thái học, đúng/sai, điểm chấm.

## Thích ứng theo nền tảng

| Hạng mục | iPhone | iPad | Mac |
|---|---|---|---|
| Con trỏ | — | Hover trên hàng/nút (nền `divider`, nút Ember `#E83F1F`) | Như iPad + con trỏ tay (`pointingHand`) trên điều khiển tùy biến |
| Menu ngữ cảnh | Vuốt + nhấn giữ + ⋯ | Nhấn giữ + ⋯ | Chuột phải + ⋯ |
| Phím tắt | Không | Giữ ⌘ để xem | Thanh menu + phím tắt (UC-20) |
| Cửa sổ | Một | Nhiều scene, mỗi scene giữ điều hướng riêng | Nhiều cửa sổ, nhớ kích thước |
| Cỡ chữ | Dynamic Type × `font_scale` | Dynamic Type × `font_scale` | `font_scale` |
| Chữ body | 15pt | 15pt | 13pt |
| Nút/điều khiển | Cao ≥ 44pt | Cao ≥ 44pt | Cao 28–32pt (nút chấm 44pt) |

## Biểu tượng ứng dụng & màn khởi động (đề xuất)

- **Biểu tượng:** nền giấy `#F4F1EA`, ký tự **開** (Noto Sans JP) màu mực, một chấm Ember làm điểm nhấn duy nhất; bố cục cho lưới biểu tượng iOS/macOS. Các biến thể tối/tint do hệ điều hành sinh; quy tắc "khóa giao diện sáng" chỉ áp dụng cho UI trong app.
- **Màn khởi động:** nền `neutral`, không chữ, không logo động.

## Triển khai (gói `DesignSystem`)

```
DesignSystem/Sources/DesignSystem/
├─ Tokens/        HKColor, HKFont, HKRadius, HKSpacing, HKBorder
├─ Components/    PillButton, CardSurface, StateDot, ProgressBar, EmptyState,
│                 GradeButton, KanaCell, SectionEyebrow
└─ Icons/         AppIcon (→ SF Symbols)
```

- **Đặt tên:** spec dự kiến `Color.primary/secondary/tertiary…`, nhưng `Color.primary` và `Color.secondary` đã tồn tại trong SwiftUI nên không khai báo lại được. Dùng namespace `HKColor.primary`, `HKColor.tertiary`… (cùng quy ước cho `HKFont`, `HKRadius`, `HKSpacing`).
- **Màu:** khai báo trong Asset Catalog (đặt tên khớp token); không hard-code hex ngoài `Tokens/`.
- **Font:** `HKFont.display(for:)` nhận nền tảng/size class và áp `relativeTo`; Noto Sans JP đăng ký trong `Info.plist`, fallback Hiragino Sans.
- **Giao diện sáng:** `preferredColorScheme(.light)` ở gốc scene.
- **Tint:** `AccentColor` (Asset Catalog) = Ember và `.tint(HKColor.tertiary)` ở gốc; chrome gốc theo kiểu hệ thống (ADR-15).
- **Kiểm thử:** snapshot các component ở 3 cỡ Dynamic Type; kiểm tra tỷ lệ tương phản của mọi cặp màu trong bảng §Colors bằng test đơn vị đọc cùng giá trị token.

## Quyết định thiết kế (ngoại lệ có chủ đích)

| # | Quyết định | Lý do |
|---|---|---|
| D-1 | Cảnh báo xóa dùng màu `destructive` hệ thống (đỏ), không dùng Ember | Alert/dialog do hệ điều hành vẽ; đỏ hệ thống là quy ước người dùng đã quen |
| D-2 | Thanh tìm kiếm là `.searchable` hệ thống | Tích hợp IME, toolbar, VoiceOver; tùy biến sẽ mất hành vi gốc |
| D-3, D-4 | **Đã đóng bởi ADR-15**: dùng `Table` và sidebar hệ thống; bỏ header bảng nền mực và mục sidebar nền mực | Giữ sắp xếp, chọn nhiều, điều hướng bàn phím và VoiceOver; chrome kính gốc |
| D-5 | Tiêu đề trang là serif trong nội dung, thanh điều hướng hệ thống giữ chức năng (nút, quay lại) | Giữ giọng editorial mà không phá hành vi điều hướng |
| D-6 | Mẫu thẻ chỉ chọn field, không cho chỉnh kiểu chữ, màu, HTML (ADR-27) | Giữ một hệ thiết kế, một tâm điểm, tương phản và VoiceOver đã kiểm; kiểu chữ suy ra từ vai trò field |

## Do's and Don'ts

- **Do** giữ Ember cho hành động, tiến độ và tín hiệu lỗi; chỉ dùng ở các chỗ liệt kê trong §Colors.
- **Do** để từ vựng làm tâm điểm: một kanji lớn, đứng giữa, nhiều khoảng trắng.
- **Do** dùng chấm trạng thái nhất quán ở mọi nơi liệt kê từ, luôn kèm nhãn chữ/VoiceOver.
- **Do** dùng SF Symbols, Dynamic Type, `.searchable`, sheet, menu, phím tắt của hệ thống.
- **Do** phân lớp bằng viền mực 1,5pt và nền giấy/thẻ.
- **Don't** đặt chữ Ember lên `neutral` hoặc `tertiary-container`; dùng `faint` cho chữ thông tin; dùng `secondary` trên nền mực.
- **Don't** để màu là kênh duy nhất của đúng/sai hoặc trạng thái học.
- **Don't** tự vẽ lại tab bar, sidebar hay toolbar; dùng thành phần gốc.
- **Don't** thêm gradient tím, nền tối toàn app, bóng đổ mạnh, hiệu ứng nảy, hoặc blur/vật liệu lên nội dung.
- **Don't** tạo một trường nhập cho mỗi ô kana (phá IME).
- **Don't** đặt hai tâm điểm cạnh nhau trên một màn hình học.
- **Don't** chọn kiểu chữ theo tên field; luôn theo vai trò (`term`, `reading`, `meaning`…).
- **Don't** hard-code màu/cỡ chữ ngoài `DesignSystem/Tokens`.

## Đồng bộ với tài liệu khác

Tài liệu này là **nguồn duy nhất** cho giá trị thiết kế (màu, cỡ chữ, bo góc, khoảng cách, icon, thành phần, quy tắc Ember). `docs/product/spec.md` §9 chỉ liên kết tới đây và nêu yêu cầu (token `HK*`, không hard-code); không sao chép giá trị. Khi sửa token hoặc quy tắc: sửa file này, rồi `DesignSystem/Tokens`; không cần sửa spec. UC-07 (ô khớp = xanh + dấu tích; ô sai = Ember + dấu ✕) đã khớp.

## Quyết định còn mở

Nhật ký, tiêu chí và hạn chốt của các mục dưới đây nằm ở `docs/architecture/DECISIONS.md`. Q-D3 (xúc giác) đã chốt ở ADR-19.

| # | Vấn đề | Đề xuất |
|---|---|---|
| Q-D2 | Chấm `state-learning` chỉ đạt 2,25:1 | Giữ màu thương hiệu kèm nhãn chữ; hoặc dùng `state-learning-ink` cho chấm. Cần quyết định |
| Q-D4 | Dark Mode (Q-2 spec) | Hoãn; khi làm, thiết kế bộ token tối riêng thay vì đảo màu |
| Q-D5 | Cỡ nền body iPhone 15pt thay vì 17pt mặc định của iOS | Chấp nhận mật độ editorial; người dùng tăng bằng Dynamic Type/`font_scale` |
