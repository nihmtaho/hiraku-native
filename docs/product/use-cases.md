# Tài liệu Use Case — hiraku (開く) · Native Swift

**Ngày**: 2026-10-29
**Phiên bản**: 3.9 · Lịch sử thay đổi: `CHANGELOG.md`.
**Tài liệu liên quan**: `docs/product/spec.md` (mã FR/NFR/SC, kiến trúc feature), `docs/product/DESIGN.md`

---

## 1. Giới thiệu

### 1.1 Phạm vi

Ứng dụng native **iOS, iPadOS, macOS** (một codebase SwiftUI), local-first, offline mặc định (đồng bộ iCloud tùy chọn, ADR-29), giao diện tiếng Việt, học từ vựng tiếng Nhật bằng FSRS. Mỗi use case áp dụng cho cả ba nền tảng; khác biệt được ghi bằng thẻ **[iPhone]**, **[iPad]**, **[Mac]**. Mỗi UC ánh xạ tới một feature module (`docs/product/spec.md` §2.4) và một `Route` (spec §5.3) thay cho URL web.

### 1.2 Tác nhân

| Actor | Mô tả |
|---|---|
| **Người học** | Tác nhân chính duy nhất: tạo nội dung, học/ôn, xem thống kê, tùy chỉnh. |
| **Hệ thống** | Lập lịch FSRS, lưu trữ SQLite, nhập/xuất, sao lưu, thông báo cục bộ. |
| **Hệ điều hành** | Tác nhân phụ: IME/bàn phím, bộ chọn tệp, quyền thông báo, vòng đời ứng dụng (nền/kết thúc), quản lý cửa sổ, sao lưu thiết bị/iCloud. Liên quan trực tiếp tới rủi ro mất dữ liệu (UC-21). |

### 1.3 Quy ước

- **P0** = MVP bắt buộc (M1) · **P1** = sau MVP (M2–M3; riêng UC-17 hoàn tác chấm điểm là P1 nhưng làm ở M1b, ADR-19) · **P2** = mở rộng (M4) · **P3** = tùy chọn.
- Mức chi tiết: P0 đầy đủ; P1 gọn; P2/P3 chỉ nêu mục tiêu và điểm cần quyết định.
- Nhãn và thông báo là gợi ý, chốt trong String Catalog.
- Trong tài liệu này "hộp thoại nhập" nghĩa là sheet (iPhone/iPad) hoặc sheet gắn cửa sổ (Mac).

---

## 2. Thay đổi so với bản web

Nghiệp vụ và mã UC giữ nguyên. Bảng thay đổi: `CHANGELOG.md`.

---

## 3. Sơ đồ & danh mục

### 3.1 Quan hệ chính

```
Người học
 ├─ Nội dung ── UC-01 Thư mục ─ UC-02 Deck ─ UC-03 Từ ─ UC-04 Tìm kiếm ─ UC-18 Hàng loạt
 ├─ Học ─────── UC-08 Phiên FSRS ◄─extend─ UC-06 Flashcard
 │                     ▲        ◄─extend─ UC-07 Gõ từ
 │                     ├─ include ─ UC-19 Hướng thẻ
 │                     ├─ extend ── UC-17 Hoàn tác
 │                     └─ extend ── UC-22 Ôn tùy chỉnh (P2)
 ├─ Dữ liệu ─── UC-05 Nhập ─include→ UC-02 (tạo deck đích)
 │              UC-09 Xuất · UC-10 Sao lưu · UC-11 Khôi phục
 ├─ Theo dõi ── UC-12 Thống kê · UC-15 Từ ngẫu nhiên · UC-26 Mục tiêu/streak · UC-29 Widget
 ├─ Tùy chỉnh ─ UC-13 Hiển thị · UC-14 Lịch ôn · UC-20 Phím tắt · UC-28 Nhắc ôn
 └─ Nền tảng ── UC-16 Lần đầu · UC-21 Bảo vệ dữ liệu/đa cửa sổ · UC-27 Đồng bộ iCloud (P3)
```

### 3.2 Danh mục

| ID | Tên | Ưu tiên | Giai đoạn | Feature module | So với v2 |
|---|---|---|---|---|---|
| UC-01 | Quản lý thư mục | **P0** | M1 | FeatureFolders | Giữ, chỉnh theo nền tảng |
| UC-02 | Quản lý deck | **P0** | M1 | FeatureDecks | Giữ, chỉnh (kiểu ghi chú — ADR-27) |
| UC-03 | Quản lý từ vựng | **P0** | M1 | FeatureWords | Giữ, chỉnh (form theo field) |
| UC-04 | Tìm kiếm từ | **P0** | M1 | FeatureWords | Chỉnh (phím tắt) |
| UC-05 | Nhập từ vựng | P1 | M2 | FeatureDataTransfer | Sửa (tệp hệ thống, Excel → P2) |
| UC-06 | Học bằng Flashcard | **P0** | M1 | FeatureFlashcard | Giữ, chỉnh |
| UC-07 | Học bằng Gõ từ | **P0** | M1 | FeatureTyping | Sửa (IME native) |
| UC-08 | Phiên ôn tập FSRS | **P0** | M1 | FeatureStudy + StudyKit | Giữ, chỉnh (vòng đời app) |
| UC-09 | Xuất dữ liệu | P1 | M2 | FeatureDataTransfer | Giữ (CSV/JSON; Excel P2) |
| UC-10 | Sao lưu | P1 | M2 | FeatureDataTransfer | Giữ |
| UC-11 | Khôi phục | P1 | M2 | FeatureDataTransfer | Giữ; nhận file sao lưu bản web |
| UC-12 | Xem thống kê | P1 | M3 | FeatureStats | Giữ (Swift Charts) |
| UC-13 | Tùy chỉnh hiển thị | **P0** | M1 | FeatureSettings | Sửa (Dynamic Type) |
| UC-14 | Tùy chỉnh lịch ôn | **P0** | M1 | FeatureSettings | Giữ |
| UC-15 | Từ ngẫu nhiên | P2 | M4 | FeatureHome | Giữ |
| UC-16 | Lần chạy đầu & dữ liệu mẫu | P1 | M3 | FeatureOnboarding | Sửa (bỏ xin lưu trữ bền) |
| UC-17 | Hoàn tác (chấm điểm, nội dung) | P1 | M1b (chấm điểm) / M3 (nội dung) | FeatureStudy + feature nội dung | Mở rộng (ADR-18, ADR-19) |
| UC-18 | Thao tác hàng loạt trên từ | P1 | M3 | FeatureWords | Giữ |
| UC-19 | Hướng thẻ học | P1 | M3 | FeatureStudy | Giữ |
| UC-20 | Phím tắt & trợ giúp | P1 | M3 | FeatureSettings + App | Sửa (menu bar) |
| UC-21 | Bảo vệ dữ liệu, đa cửa sổ & vòng đời | **P0** (lõi) / P1 (UI) | M1/M2 | Go core (`store`) + FeatureDataTransfer | **Viết lại** |
| UC-22 | Ôn tập tùy chỉnh / học trước | P2 | M4 | FeatureStudy | Giữ |
| UC-23 | Chi tiết từ, lịch sử & tạm ngưng | P2 | M4 | FeatureWords | Giữ |
| UC-24 | Tags & lọc | P2 | M4 | FeatureWords | Giữ |
| UC-25 | Phát âm (TTS) | P2 | M4 | FeatureFlashcard / FeatureTyping | Đổi sang `AVSpeechSynthesizer` |
| UC-26 | Mục tiêu ngày & streak | P2 | M4 | FeatureStats | Giữ |
| UC-27 | Đồng bộ iCloud | P3 | M4 | Go core (đồng bộ) + FeatureSettings | Đổi từ "tài khoản" sang iCloud; tùy chọn bật/tắt (ADR-29) |
| UC-28 | Nhắc ôn hằng ngày | P1 | M3 | FeatureSettings + App | **Mới** |
| UC-29 | Widget "Đến hạn hôm nay" | P2 | M4 | Widget extension | **Mới** |
| UC-30 | Thêm từ nhanh | P1 | M3 | FeatureWords | **Mới** |
| UC-31 | Quản lý kiểu ghi chú & field | P1 | M3 | FeatureDecks | **Mới** (ADR-27 Pha B) |
| UC-32 | Quản lý profile | P1 | M3 | FeatureSettings + App | **Mới** (ADR-28) |

---

## 4. Use case MVP (P0) — chi tiết

### 4.0 Hành vi thống nhất theo nền tảng (áp dụng cho mọi UC)

Liên quan FR-071, FR-072, FR-074. Mỗi Controller dùng chung; chỉ View và shell khác nhau.

| Khía cạnh | [iPhone] | [iPad] | [Mac] |
|---|---|---|---|
| Điều hướng | Tab bar Liquid Glass gốc (Trang chủ / Thống kê / Cài đặt (M1a: chỉ Trang chủ và Cài đặt, Thống kê thêm ở M3)) + ngăn xếp | Sidebar kính nổi dạng cây Thư mục → Deck + vùng nội dung | Sidebar kính nổi dạng cây Thư mục → Deck + vùng nội dung; Cài đặt ở cửa sổ Settings |
| Toolbar | Nhóm nút kính theo màn (`docs/product/DESIGN.md` §Chrome hệ thống) | Như iPhone, thêm ô tìm kiếm ở toolbar | Như iPad |
| Thao tác trên mục | Vuốt + menu ⋯ | Menu ⋯ / nhấn giữ | Menu ⋯ / chuột phải |
| Form tạo/sửa | Sheet | Sheet | Sheet gắn cửa sổ; Return = Lưu, Esc = Hủy |
| Danh sách từ | `List` | `Table` đa cột, sắp xếp theo cột | `Table` đa cột, sắp xếp theo cột |
| Phím tắt | Không (dùng nút) | Bàn phím phần cứng; giữ ⌘ để xem | Thanh menu + phím tắt chuẩn |
| Con trỏ | — | Hover (nền `divider`; nút Ember đậm hơn) | Như iPad + con trỏ tay trên điều khiển tùy biến |
| Cửa sổ | Một | Nhiều scene (Split View/Stage) | Nhiều cửa sổ |
| Phiên học | Toàn màn hình | Trong vùng nội dung, inspector phải 230pt | Như iPad |

Yêu cầu chung: mục tiêu chạm ≥ 44×44pt (iOS/iPadOS), ≥ 28pt (macOS); VoiceOver có nhãn cho mọi điều khiển; đúng/sai không chỉ dựa vào màu; Dynamic Type không cắt nội dung (SC-009); tôn trọng *Reduce Motion*.

### 4.0.1 Quy ước tương tác (rà soát hành vi — ADR-18)

Nguyên tắc: (1) mỗi hành động có ít nhất hai đường, trong đó một đường không cần cử chỉ (nút, menu hoặc bàn phím); (2) kéo-thả là cách chính để sắp xếp và di chuyển; (3) hoàn tác thay cho xác nhận với thao tác đảo ngược được, xác nhận chỉ dành cho thao tác lan truyền; (4) không mất những gì đã nhập; (5) mở lại là quay về đúng chỗ; (6) hành động thường dùng nằm trong tầm ngón cái trên iPhone.

| Tình huống | [iPhone] | [iPad] | [Mac] | FR |
|---|---|---|---|---|
| Sắp xếp thư mục, deck | Nhấn giữ rồi kéo, thả để chốt | Như iPhone; kéo cả trong sidebar | Kéo bằng chuột; kéo trong sidebar | FR-001, FR-002 |
| Phương án thay kéo-thả | Menu "Di chuyển lên/xuống"; hành động VoiceOver | Như iPhone | Như iPhone | FR-001, FR-002 |
| Di chuyển deck sang thư mục khác | Menu "Di chuyển…" | Kéo deck thả lên thư mục ở sidebar | Như iPad | FR-002, FR-080 |
| Mở menu hành động | Nhấn giữ hàng/thẻ hoặc nút ⋯ | Như iPhone | Chuột phải hoặc ⋯ | — |
| Xóa | Vuốt trái → Xóa | Như iPhone; phím Delete | Phím Delete hoặc ⌘⌫ | FR-007, FR-077 |
| Hoàn tác | Lắc máy hoặc toast "Hoàn tác" (~5 giây) | ⌘Z; toast | ⌘Z; toast | FR-020, FR-077 |
| Chọn nhiều | "Chọn" ở toolbar rồi chạm | Chạm giữ hoặc ⇧/⌘ chạm | ⇧/⌘ click, ⌘A | FR-008 |
| Đóng sheet đang có thay đổi | Vuốt xuống hoặc Hủy ⇒ hỏi "Bỏ thay đổi?" | Như iPhone; Esc | Esc hoặc Hủy ⇒ hỏi | FR-075 |
| Quay lại | Vuốt từ mép trái hoặc nút Quay lại | Như iPhone | ⌘[ hoặc nút Quay lại | — |
| Mở lại ứng dụng | Về đúng tab, màn, vị trí cuộn | Thêm: từng scene | Từng cửa sổ | FR-076 |
| Xúc giác (P1) | Nhẹ khi lật, rõ hơn khi chấm, kiểu thành công/lỗi khi Gõ từ | Như iPhone | Không dùng | FR-081 |
| Cài đặt | Tab Cài đặt | Mục sidebar | Cửa sổ Settings (⌘,) | FR-072 |

---

### UC-01 — Quản lý thư mục

**Mục tiêu**: Tổ chức vốn từ thành các nhóm cấp 1.
**Tiền điều kiện**: Đang ở Trang chủ (`.home`).

**Kịch bản chính (tạo)**
1. Người học bấm "Thêm thư mục" (toolbar) hoặc "Tạo thư mục đầu tiên" (empty state).
2. Hệ thống mở hộp thoại nhập tên, tự focus ô tên.
3. Người học nhập tên và bấm "Lưu" (hoặc Return).
4. Hệ thống tạo thư mục ở cuối danh sách; lưới cập nhật ngay.

**Thay thế**
- **A1 Đổi tên**: menu ⋯ → "Đổi tên" → hộp thoại điền sẵn → Lưu.
- **A2 Sắp xếp lại (kéo-thả là cách chính)**: **[iPhone/iPad]** nhấn giữ thẻ rồi kéo tới vị trí mới, thả để chốt (các thẻ khác nhường chỗ); **[Mac]** kéo bằng chuột; **[iPad/Mac]** kéo được cả trong sidebar. Đường phụ cho trợ năng và bàn phím: "Di chuyển lên/xuống" trong menu và hành động tùy chỉnh của VoiceOver. `position` gán lại 1..n; hoàn tác được (FR-077).
- **A3 Xóa**: menu ⋯ → "Xóa" → xác nhận nêu "sẽ xóa N deck và M từ cùng toàn bộ tiến độ học" → **xóa mềm** cả cây.
- **E1 Hủy**: không thay đổi.
- **E2 Tên rỗng/quá 100 ký tự**: lỗi inline, không đóng hộp thoại.
- **E3 Trùng tên**: cho phép, không cảnh báo.

**Hậu điều kiện**: Danh sách phản ánh ngay; thay đổi ghi bền.
**Quy tắc**: tên 1–100 ký tự sau trim; thư mục mới ở cuối; xóa mềm theo tầng (deck → từ → trạng thái học → nhật ký); không hoàn tác xóa ở MVP (xem UC-23).
**FR**: FR-001, FR-007, FR-065, FR-077.

---

### UC-02 — Quản lý deck

**Mục tiêu**: Gom từ thành bộ bài trong một thư mục.
**Tiền điều kiện**: Đang ở màn thư mục (`.folder(id)`).

**Kịch bản chính (tạo)**
1. Bấm "Tạo deck" (toolbar/empty state).
2. Hộp thoại: Tên*, Mô tả (tùy chọn) và Kiểu ghi chú (mặc định "Từ vựng Nhật"; chọn kiểu khác là P1 — UC-31).
3. Lưu → deck được tạo; danh sách hiện deck với số từ = 0.

**Thay thế**
- **A1 Sửa tên/mô tả**: menu ⋯ → "Sửa".
- **A2 Di chuyển**: menu ⋯ → "Di chuyển" → chọn thư mục đích (loại thư mục hiện tại). Chỉ có 1 thư mục ⇒ mục bị vô hiệu kèm gợi ý "Cần ít nhất 2 thư mục". **[iPad/Mac]** kéo deck thả lên thư mục ở sidebar (FR-080).
- **A3 Xóa**: xác nhận nêu "sẽ xóa N từ và tiến độ học" → xóa mềm.
- **A4 Sắp xếp deck**: kéo-thả trong danh sách deck như A2 của UC-01; `decks.position` gán lại 1..n.
- **E1 Hủy / E2 Tên không hợp lệ**: như UC-01.

**Hậu điều kiện**: Danh sách deck + số từ + phân bố trạng thái (chấm Mới/Đang học/Đã biết) đúng.
**Quy tắc**: mỗi deck thuộc đúng một thư mục và có đúng một kiểu ghi chú; không đổi kiểu khi deck đã có từ; số từ không tính từ đã xóa mềm.
**FR**: FR-002, FR-007, FR-077, FR-080, FR-086.

---

### UC-03 — Quản lý từ vựng

**Mục tiêu**: Thêm/sửa/xóa từ trong deck.
**Tiền điều kiện**: Đang ở màn deck (`.deck(id)`).

**Kịch bản chính (thêm)**
1. Bấm "Thêm từ" (toolbar/empty state; **[Mac/iPad]** ⌘N).
2. Hộp thoại dựng theo field của kiểu ghi chú của deck, theo `ord`; kiểu hệ thống có 4 trường: Từ*, Cách đọc, Nghĩa*, Câu ví dụ. Field `input_kind = kana` dùng ô nhập hỗ trợ IME.
3. Người học điền và Lưu.
4. Hệ thống trim các trường, tạo từ (chưa có `card_states` ⇒ **Mới**), hiện ngay trong danh sách.
5. Tùy chọn **"Lưu và thêm tiếp"**: giữ hộp thoại, xóa trường, focus về ô Từ.
6. **Bàn phím**: **[iPhone]** phím Return chuyển ô kế (Từ → Cách đọc → Nghĩa → Câu ví dụ), ô cuối = Lưu; **[iPad/Mac]** Tab chuyển ô, Return = Lưu, ⌘Return = Lưu và thêm tiếp, Esc = Hủy.

**Thay thế**
- **A1 Sửa**: **[iPhone]** vuốt hoặc menu; **[iPad/Mac]** chọn hàng + menu/chuột phải/double-click → hộp thoại điền sẵn → Lưu (cập nhật `updated_at`). Sửa **không** đặt lại tiến độ.
- **A2 Xóa**: xác nhận "Xóa 'X'? Tiến độ học của từ này cũng bị xóa" → xóa mềm. (P1: bỏ xác nhận, thay bằng toast "Hoàn tác" — FR-077.)
- **A3 Trùng từ**: `word` đã có trong deck ⇒ cảnh báo "Từ này đã có (nghĩa: …)" kèm "Vẫn thêm" / "Xem từ đã có". Không chặn.
- **E1 Thiếu Từ/Nghĩa**: lỗi inline, không đóng hộp thoại.
- **E2 Hủy**: không thay đổi.
- **A4 Đóng khi có thay đổi chưa lưu**: vuốt xuống, Hủy hoặc Esc ⇒ hỏi "Bỏ thay đổi?" với "Bỏ thay đổi" / "Tiếp tục chỉnh sửa"; chưa nhập gì thì đóng ngay (FR-075).
- **A5 Gợi ý cách đọc (P2)**: khi Từ có kanji và Cách đọc trống, hiện chip "Gợi ý: たべる" từ dữ liệu hệ thống; chạm để điền, không tự điền (FR-083).

**Hậu điều kiện**: Danh sách phản ánh ngay; bền vững.
**Quy tắc**: Từ & Nghĩa bắt buộc; Cách đọc rỗng ⇒ "không có kanji" (ảnh hưởng UC-07); danh sách lazy, mỗi hàng có chấm trạng thái; **[iPad/Mac]** bảng nhiều cột, sắp xếp theo cột.
**FR**: FR-003, FR-004, FR-005, FR-006, FR-007, FR-075, FR-077, FR-083, FR-086.

**Ghi chú (ADR-27)**: "Từ", "Nghĩa", "Cách đọc" trong UC này là field theo role `term`, `meaning`, `reading`. Với kiểu tùy biến, field bắt buộc lấy theo định nghĩa kiểu; bảng **[iPad/Mac]** có một cột mỗi field.

---

### UC-04 — Tìm kiếm từ

**Mục tiêu**: Lọc nhanh danh sách từ trong deck (và, P1, trên toàn app).
**Tiền điều kiện**: Đang ở màn deck có từ.

**Kịch bản chính**
1. Người học gõ vào ô tìm kiếm của màn (**[iPad/Mac]** ⌘F để focus).
2. Hệ thống debounce rồi lọc: giữ từ có **Từ**, **Nghĩa** (MVP) hoặc **Cách đọc** (P1) chứa từ khóa, không phân biệt hoa thường.
3. Không có kết quả ⇒ empty state "Không tìm thấy từ" + nút xóa bộ lọc.
4. Xóa từ khóa ⇒ trở lại danh sách đầy đủ.

**Mở rộng (P1)**: romaji khớp kana trong Cách đọc (`taberu` ⇒ `たべる`) dùng `HirakuCore/Kana`; tìm toàn app từ ô tìm kiếm chung.
**Sắp xếp và lọc (P1)**: menu "Sắp xếp" (Mới thêm trước / Theo từ) và chip lọc (Tất cả / Mới / Đang học / Đã biết / Đến hạn); thẻ deck và thư mục hiện số từ đến hạn (FR-079).
**Quy tắc**: so khớp chuỗi con; 50.000 từ vẫn mượt (NFR-002); bộ lọc không làm mất vị trí cuộn ngoài ý muốn; IME trong ô tìm kiếm chỉ lọc sau khi chốt.
**FR**: FR-013, FR-079.

---

### UC-06 — Học bằng Flashcard

**Mục tiêu**: Xem mặt trước, lật, tự chấm điểm.
**Tiền điều kiện**: Phiên hợp lệ (UC-08), `mode = flashcard`.

**Kịch bản chính**
1. Hệ thống hiện thẻ đầu: **từ cỡ lớn ở giữa** là tâm điểm duy nhất (`docs/product/DESIGN.md`).
2. Người học lật (chạm thẻ, hoặc **[Mac/iPad]** Space/Return) → mặt sau nền mực: Cách đọc (Ember), Nghĩa, Ví dụ.
3. Người học chấm điểm bằng nút hoặc phím số.
4. Hệ thống gọi UC-08 để ghi điểm + cập nhật lịch, rồi sang thẻ kế (đã reset lật).
5. Hết hàng đợi ⇒ màn "Xong!" (số từ đã học, thời gian, phân bố điểm) + "Về trang chủ".

**Thay thế**
- **A1 2 nút**: "Chưa thuộc" (Again) / "Thuộc" (Good); phím `1` = Again, `2`–`4` = Good.
- **A2 4 nút**: Again / Hard / Good / Easy, phím `1`–`4`; hiển thị khoảng ôn dự kiến dưới nút (P1, FR-026).
- **A3 Chưa lật mà bấm phím chấm**: bỏ qua.
- **E1 Không có thẻ cần ôn**: empty state "Hôm nay không có từ cần ôn" + CTA "Học thêm từ mới" (nếu còn từ mới ngoài hạn mức) hoặc "Về trang chủ".
- **E2 Lỗi dữ liệu**: thông báo lỗi + nút thử lại.
- **E3 Thoát giữa chừng** (Esc, đóng cửa sổ, vuốt thoát, app bị hệ điều hành kết thúc): không mất gì vì mỗi lần chấm đã ghi bền; mở lại dựng hàng đợi mới.

**Hậu điều kiện**: Mỗi lần chấm có đúng 1 `review_logs` (`mode='flashcard'`) và `card_states` mới.
**Quy tắc**: chống chấm hai lần (khóa trong lúc đang ghi); đo `elapsed_ms` từ lúc hiện thẻ tới lúc chấm; hiệu ứng lật tôn trọng *Reduce Motion* (chuyển mờ).
**Cử chỉ và phản hồi**: chạm thẻ để lật; xúc giác nhẹ khi lật, rõ hơn khi chấm (P1, FR-081). Tùy chọn mặc định tắt (P2, FR-082): vuốt trái/phải để chấm "Chưa thuộc"/"Thuộc" ở chế độ 2 nút, luôn kèm nút bấm.
**FR**: FR-010, FR-016, FR-017, FR-022; FR-026, FR-081 (P1); FR-082 (P2).

---

### UC-07 — Học bằng Gõ từ

**Mục tiêu**: Gõ đáp án và nhận phản hồi đúng/sai tức thì.
**Tiền điều kiện**: Phiên hợp lệ (UC-08), `mode = typing`.

**Kịch bản chính**
1. Hệ thống hiện **lời nhắc** và các ô đáp án (1 ô/ký tự):
   - Từ có `reading`: nhắc = **Từ**, đáp án = **Cách đọc**.
   - Từ không có `reading`: nhắc = **Nghĩa**, đáp án = **Từ**.
2. Người học gõ (romaji, hiragana hoặc katakana, qua bàn phím tiếng Nhật hoặc bàn phím thường); hệ thống so khớp **theo từng ký tự**: ô khớp nền xanh + dấu tích, ô sai nền hồng nhạt + viền Ember + dấu ✕ (không chỉ dựa vào màu).
3. Khớp hoàn toàn ⇒ báo "Chính xác!", ghi **Good (3)**, tự chuyển thẻ sau một nhịp ngắn.
4. Nhấn Return khi chưa khớp ⇒ coi là **sai**: ghi **Again (1)**, **hiện đáp án đúng** cùng nghĩa/ví dụ, chờ Return hoặc nút "Tiếp".
5. Nút "Bỏ qua" = như bước 4. **[iPhone]** nút "Kiểm tra" trên thanh bàn phím = Return: nộp đáp án; chưa khớp ⇒ như bước 4.
6. Hết hàng đợi ⇒ "Xong!".

**IME (iOS/iPadOS/macOS)**
- Khi ô nhập đang có *marked text* (đang compose): chỉ hiển thị ký tự đang compose, **không** chấm đúng/sai từng ô.
- Chỉ so khớp sau khi người học chốt (kết thúc compose).
- Return dùng để **chốt IME** không được tính là "nộp đáp án".
- Cùng cơ chế cho bàn phím cảm ứng và bàn phím phần cứng.

**Thay thế**
- **A1 Người học tin mình đúng nhưng hệ thống chấm sai** (vd từ đồng âm): nút "Tôi đúng" (P1) thực hiện như Hoàn tác (UC-17) rồi chấm lại **Good**; chỉ còn một `review_logs` (rating 3). *(FR-025; phụ thuộc UC-17.)*
- **E1/E2**: như UC-06.

**Hậu điều kiện**: Mỗi thẻ kết thúc có 1 `review_logs` (`mode='typing'`).
**Quy tắc chuẩn hóa**: `docs/product/spec.md` §7.2 (trim, lowercase, romaji→kana, katakana→hiragana, bỏ `ー`, dung sai dakuten/handakuten, kana nhỏ=lớn, nguyên âm dài lặp, ký tự lặp). Mọi phản hồi dùng `HirakuCore/Kana`.
**Phản hồi**: xúc giác kiểu thành công khi đúng, kiểu lỗi khi sai (P1, FR-081).
**FR**: FR-011, FR-012, FR-016, FR-019; FR-025, FR-081 (P1).

---

### UC-08 — Phiên ôn tập FSRS

**Mục tiêu**: Dựng phiên (từ đến hạn + từ mới trong hạn mức), nhận điểm, lập lịch bằng FSRS.
**Tác nhân**: Người học (khởi tạo), Hệ thống (thực thi).

**Điểm vào** (route `.study(scope, mode)`)
- Banner "Ôn hôm nay" / sidebar ⇒ `scope = .all`.
- "Ôn cả thư mục" ⇒ `.folder(id)`.
- Menu "Học" ở toolbar màn deck (Flashcard / Gõ từ) ⇒ `.deck(id)`.

**Kịch bản chính — Dựng phiên**
1. Xác định "ngày học" theo `day_start_hour` (mặc định 04:00).
2. **Thẻ đến hạn**: `due ≤ cuối ngày học`, không tạm ngưng, trong phạm vi; Learning/Relearning xếp trước, rồi Review theo `due` tăng dần.
3. **Số từ mới được phép** = `new_cards_per_day` − số từ đã chấm lần đầu trong ngày học (đếm `review_logs` có `prev_state = 0`), tối thiểu 0.
4. **Từ mới**: chưa có `card_states`, theo `created_at`, giới hạn bởi số được phép.
5. Hàng đợi = [đến hạn…, mới…] ⇒ giao cho UC-06/UC-07 qua `StudyMode` đã đăng ký.

**Kịch bản chính — Chấm điểm** (do UC-06/07 gọi)
1. Đọc cài đặt (`fsrs_retention`, `fsrs_max_interval`, `fsrs_short_term`; fuzz tắt).
2. **Trong một transaction**: đọc `card_states` hiện tại của từ (chưa có ⇒ thẻ New), chạy Scheduler với rating đã chọn, upsert `card_states` và chèn `review_logs` (kèm ảnh chụp `prev_*`).
3. Nếu `due` mới ≤ bây giờ + 20 phút ⇒ chèn lại thẻ vào hàng đợi phiên.
4. Trả điều khiển cho màn hình để sang thẻ kế.

**Ánh xạ điểm**: `docs/product/spec.md` §7.1.

**Thay thế / biên**
- **E1 Hết từ mới trong ngày**: số cho phép = 0 ⇒ phiên chỉ có thẻ đến hạn.
- **E2 Không có gì đến hạn và hết từ mới** ⇒ empty state (UC-06 E1).
- **E3 Ghi thất bại** (hết dung lượng thiết bị…): báo lỗi, **không** sang thẻ kế, cho thử lại; không để lại trạng thái nửa vời.
- **E4 Đồng hồ/múi giờ thay đổi**: dùng giờ hiện tại của máy; không cố sửa.
- **E5 Ứng dụng vào nền / cửa sổ mất focus giữa thẻ**: `elapsed_ms` bị giới hạn trần (vd 60 giây) để không làm lệch dữ liệu (spec §7.3.6).
- **E6 Hai cửa sổ cùng học một thẻ**: lần chấm sau đọc lại trạng thái mới nhất trong transaction; mỗi lần chấm vẫn đúng 1 `review_logs`; không hỏng dữ liệu (xem UC-21).

**Hậu điều kiện**: mọi thẻ đã chấm có lịch mới; nhật ký đầy đủ.
**FR**: FR-014, FR-015, FR-016, FR-017, FR-018, FR-050.

---

### UC-13 — Tùy chỉnh hiển thị

**Mục tiêu**: Điều chỉnh cỡ chữ trong app.
**Tiền điều kiện**: Cài đặt → Hiển thị.

**Kịch bản chính**
1. Kéo thanh trượt 80%–140% (bước 5%); áp dụng ngay.
2. Ô xem trước hiện mẫu ("食べる — học tiếng Nhật") theo cỡ đang chọn.
3. Lưu sau debounce (~400 ms) vào `font_scale`.

**Quy tắc**: **[iPhone/iPad]** `font_scale` nhân thêm trên Dynamic Type của hệ thống; **[Mac]** chỉ dùng `font_scale`; không cắt nội dung ở mức lớn nhất (SC-009).
**Không có ở v3**: chọn phông (do `docs/product/DESIGN.md` quy định); chủ đề Sáng/Tối (hoãn, Q-2: MVP khóa giao diện sáng).
**FR**: FR-060, FR-074.

---

### UC-14 — Tùy chỉnh lịch ôn tập

**Mục tiêu**: Điều chỉnh tham số FSRS và hành vi phiên.
**Tiền điều kiện**: Cài đặt → Ôn tập.

**Kịch bản chính**
1. **Từ mới/ngày**: nhập số 0–999 (mặc định 20); lưu khi rời ô hoặc Return.
2. **Độ giữ lại mục tiêu**: thanh trượt 70%–95%; lưu sau debounce.
3. **Nút chấm điểm**: 2 nút ↔ 4 nút; áp dụng cho phiên kế tiếp.
4. **Giờ bắt đầu ngày học** (mặc định 4).
5. **Bước học ngắn** (bật/tắt).
6. (Nâng cao, thu gọn) **Khoảng ôn tối đa**.

**Quy tắc**: giá trị ngoài miền bị chặn với thông báo inline; thay đổi chỉ ảnh hưởng các lần chấm **sau**, không tính lại lịch của thẻ đã chấm; câu giải thích ngắn dưới mỗi tham số ("Độ giữ lại cao hơn ⇒ ôn nhiều hơn").
**Điều khiển**: số dùng stepper kèm nhập trực tiếp; nút "Khôi phục mặc định" cho từng nhóm (P1, FR-060).
**FR**: FR-018, FR-060.

---

### UC-21 — Bảo vệ dữ liệu, đa cửa sổ & vòng đời ứng dụng

**Mục tiêu**: Giảm rủi ro mất/hỏng dữ liệu do vòng đời ứng dụng, đa cửa sổ và thiết bị.
**Tác nhân**: Hệ thống, Hệ điều hành, Người học.

**Lõi (P0)**
1. **Ghi nguyên tử**: mọi thao tác ghi nhiều bảng chạy trong một transaction. Hệ điều hành có thể kết thúc app bất kỳ lúc nào; lần mở sau không mất dữ liệu và không có trạng thái nửa vời (SC-003, SC-004).
2. **Đa cửa sổ** (**[Mac]** nhiều cửa sổ, **[iPad]** nhiều scene): mở được nhiều cửa sổ cùng lúc, dùng chung một cơ sở dữ liệu; ghi được điều phối để không hỏng. Mỗi cửa sổ có điều hướng riêng; thay đổi ở cửa sổ này hiện sang cửa sổ kia mà không cần tải lại.

**UI (P1)**
3. Cài đặt → Dữ liệu hiển thị dung lượng dữ liệu đã dùng và thời điểm sao lưu gần nhất (FR-061).
4. Nếu chưa từng sao lưu hoặc đã lâu chưa sao lưu (vd 14 ngày) ⇒ banner nhắc "Sao lưu ngay" (UC-10) (FR-062).

**Thay thế / biên**
- **E1 Hết dung lượng thiết bị khi ghi**: báo lỗi rõ ràng, đề nghị giải phóng bộ nhớ hoặc xuất/sao lưu; không ghi nửa vời.
- **E2 Cơ sở dữ liệu hỏng hoặc migration thất bại khi mở**: không chạy tiếp với dữ liệu không toàn vẹn; hiện màn lỗi nghiêm trọng, đề nghị khôi phục từ file sao lưu; không tự xóa tệp dữ liệu.
- **E3 Xóa app / cài lại / thiết bị mới**: dữ liệu chỉ còn nếu có sao lưu thiết bị/iCloud hoặc file sao lưu của người học; nếu không, lần mở sau như lần chạy đầu (UC-16) kèm gợi ý khôi phục từ file.

**FR**: FR-061, FR-062, FR-064. **Rủi ro**: R-01, R-05.

---

## 5. Use case P1 — mô tả gọn

### UC-05 — Nhập từ vựng từ file / dán văn bản

**Mục tiêu**: Nhập hàng loạt từ CSV/JSON hoặc dán văn bản vào deck mới/có sẵn.
**Điểm vào**: `.importData` từ một thư mục hoặc nút "Nhập" trong deck.

**Luồng**
1. **Chọn nguồn**: chọn tệp `.csv/.json` bằng bộ chọn tệp hệ thống; **[iPad/Mac]** kéo-thả tệp; hoặc **dán** văn bản (TSV/CSV copy từ Excel, Google Sheets, Anki). Xử lý ngoài luồng giao diện.
2. Hệ thống tự phát hiện encoding (UTF-8/BOM; cảnh báo nếu nghi Shift-JIS), dấu phân cách, dòng tiêu đề; ánh xạ cột tự động qua bí danh (spec §7.5).
3. **Deck đích**: chọn deck có sẵn hoặc "＋ Tạo deck mới…" (include UC-02).
4. **Ánh xạ cột**: chỉnh tay hoặc "Bỏ qua cột"; preview tính lại ngay.
5. **Chính sách trùng** (theo `word` đã trim, cùng deck): Bỏ qua / Ghi đè / Thêm lại.
6. Bảng xem trước tối đa 200 dòng; dòng lỗi (thiếu Từ/Nghĩa) tô đỏ kèm lý do; hiện số lỗi.
7. Bấm "Nhập" ⇒ xử lý **toàn bộ** trong một transaction; tổng kết thêm/ghi đè/bỏ qua/lỗi.
8. Đóng tổng kết ⇒ về thư mục/deck. P2: tải danh sách dòng lỗi.

**Biên**: file rỗng, sai định dạng, JSON không phải mảng, file rất lớn (xử lý theo lô, có tiến trình, hủy được, chặn bấm lặp), lỗi giữa chừng ⇒ rollback toàn bộ. **Excel (.xlsx) là P2.**
**FR**: FR-033, FR-034, FR-035, FR-036.

### UC-09 — Xuất dữ liệu

Cài đặt → Dữ liệu → chọn phạm vi (toàn app / một deck) và định dạng (CSV/JSON; Excel P2) → lưu qua `fileExporter` hoặc chia sẻ qua `ShareLink`; tên `hiraku-<ngày>.<ext>`. Cột `folder, deck` + tên các trường theo thứ tự của kiểu ghi chú (kiểu hệ thống: `word, reading, meaning, example`); deck khác kiểu xuất thành tệp riêng (spec §7.5). Phạm vi "toàn app" = profile đang mở. Không có từ ⇒ thông báo. Xuất lớn chạy ngoài luồng giao diện. **FR**: FR-032.

### UC-10 — Sao lưu

Cài đặt → Dữ liệu → "Tạo bản sao lưu" ⇒ gói mọi bảng theo spec §7.6 thành tệp `hiraku-backup-<ngày giờ>.hirakubackup` (nội dung JSON, định dạng v3 theo spec §7.6, ghi tên profile; bản web không đọc được); lưu qua Tệp hoặc chia sẻ (AirDrop, iCloud Drive…). Ghi nhận `last_backup_at` (dùng cho nhắc ở UC-21). **FR**: FR-030.

### UC-11 — Khôi phục (gộp, idempotent)

1. Chọn tệp sao lưu (v3, hoặc v2 từ bản web — ánh xạ sang kiểu "Từ vựng Nhật") ⇒ kiểm tra `format`/`version`; sai ⇒ báo lỗi, không đụng dữ liệu. Khôi phục vào profile đang mở; tệp ghi tên profile khác thì hỏi lại.
2. Xem trước số lượng từng nhóm sẽ gộp.
3. Trong **một transaction**: upsert theo `id` (giữ bản có `updated_at` mới hơn); `review_logs` chèn-nếu-chưa-có.
4. Hộp thoại kết quả theo từng nhóm.

**Quy tắc**: không bao giờ xóa dữ liệu hiện có; khôi phục lần 2 cùng tệp không làm thay đổi gì. Nhận thêm backup cũ `goi-full-backup` (P2, FR-040). **FR**: FR-031, FR-040.

### UC-12 — Xem thống kê

**Hiển thị**: 3 số Mới / Đang học / Đã biết; biểu đồ **7 ngày** (nhãn T2–CN), chuyển 30 ngày; danh sách **Sắp đến hạn** (chọn ⇒ mở deck); **dự báo** số thẻ đến hạn 7 ngày tới; tỷ lệ nhớ gần đây (P2).
**Quy tắc**: Mới = chưa có `card_states`; Đã biết = state 2; còn lại = Đang học. Dùng "ngày học" theo `day_start_hour`. Biểu đồ trống ⇒ empty state. Dùng Swift Charts; biểu đồ có mô tả cho VoiceOver. **FR**: FR-051, FR-052, FR-053, FR-054.

### UC-16 — Lần chạy đầu & dữ liệu mẫu

1. Lần mở đầu: một màn chào ngắn, giải thích "dữ liệu nằm trên máy bạn" và khuyến nghị sao lưu định kỳ (UC-21).
2. Hai lối: **"Bắt đầu từ trống"** hoặc **"Thêm deck mẫu (JLPT N5, ~20 từ)"**.
3. Deck mẫu chỉ là dữ liệu thường, xóa/sửa như deck khác.

Mục tiêu: SC-001, để người mới thử ngay Flashcard/Gõ từ. **FR**: FR-066.

### UC-17 — Hoàn tác (chấm điểm và thao tác nội dung)

1. Ngay sau khi chấm, hiện toast/nút "Hoàn tác"; **[Mac/iPad]** ⌘Z hoặc Delete.
2. Hệ thống khôi phục `card_states` từ ảnh chụp `prev_*` của `review_logs` gần nhất và **đánh dấu/xóa mềm** dòng log đó trong một transaction; quay lại đúng thẻ vừa chấm (đã lật nếu là Flashcard).

**Quy tắc**: chỉ hoàn tác lần chấm **gần nhất** của phiên hiện tại; thẻ vừa chèn lại hàng đợi (nếu có) bị gỡ ra. Dòng log bị hoàn tác không tính vào hạn mức từ mới và thống kê. Không hoàn tác được nếu thẻ đã được chấm lại ở cửa sổ khác.

**Hoàn tác thao tác nội dung (P1, FR-077)**: xóa từ/deck/thư mục (xóa mềm), di chuyển và sắp xếp lại đăng ký với `UndoManager` hệ thống: **[iPhone]** lắc máy hoặc nút "Hoàn tác" trên toast (~5 giây); **[iPad/Mac]** ⌘Z. Xóa **từ** không hỏi xác nhận; xóa thư mục/deck và đặt lại tiến độ hàng loạt vẫn xác nhận vì lan truyền. Hoàn tác khôi phục `deleted_at` hoặc vị trí cũ trong một transaction.
**Giai đoạn**: hoàn tác chấm điểm làm ở M1b (ADR-19); hoàn tác nội dung ở M3.
**FR**: FR-020, FR-077.

### UC-18 — Thao tác hàng loạt trên từ

Chọn nhiều từ: **[iPhone]** chế độ chọn (Edit); **[iPad/Mac]** Shift/⌘-click, chọn tất cả kết quả lọc ⇒ thanh hành động: **Xóa**, **Chuyển sang deck…**, **Sao chép sang deck…**, **Đặt lại tiến độ** (đưa về Mới, xóa `card_states`, giữ `review_logs` — hoặc xóa theo lựa chọn có xác nhận). Mọi thao tác xác nhận số lượng và chạy trong một transaction. Đặt lại tiến độ cũng có ở cấp deck. **FR**: FR-008, FR-009.

### UC-19 — Hướng thẻ học

Cài đặt hoặc ngay trong phiên: **Từ→Nghĩa** (mặc định) / **Nghĩa→Từ** / **Hỗn hợp** (ngẫu nhiên theo thẻ). Nghĩa→Từ: mặt trước = Nghĩa, mặt sau = Từ + Cách đọc. Cùng một `card_states` cho mọi hướng; nếu cần lịch riêng từng hướng thì tách thẻ (quyết định sau). **FR**: FR-021.

### UC-20 — Phím tắt & trợ giúp

- **[Mac]** Thanh menu (File, Edit, Study, Help) hiển thị phím tắt: Thêm mới (⌘N, theo ngữ cảnh), Tìm kiếm (⌘F), Hoàn tác (⌘Z), Bảng phím tắt (⌘/).
- **[iPad]** Bàn phím phần cứng dùng cùng phím tắt; giữ ⌘ để xem danh sách do hệ thống hiển thị.
- **[iPhone]** Không có phím tắt; mọi hành động có nút trên màn hình.
- Phím học theo spec §7.4. Phím tắt học vô hiệu khi đang focus ô nhập (trừ Return/Esc trong Gõ từ).

**FR**: FR-022, FR-072.

### UC-27 — Đồng bộ iCloud (P3, M4 — ADR-29)
**Mục tiêu**: Dùng chung dữ liệu học giữa Mac, iPad và iPhone cùng một tài khoản iCloud, khi người dùng chọn bật.
**Tiền điều kiện**: Thiết bị đã đăng nhập iCloud. Đồng bộ đang tắt (mặc định).

1. Cài đặt → "Đồng bộ iCloud" → bật.
2. Hệ thống kiểm tra tài khoản iCloud và hiện trạng thái.
3. Dữ liệu iCloud đã có từ máy khác được gộp tự động theo ADR-29; không hỏi người dùng.

**Tắt**: app ngừng gọi CloudKit; dữ liệu trên máy không đổi; dữ liệu trên iCloud giữ nguyên, không có thao tác xóa cloud (FR-092, ADR-29).

**Thay thế / biên**
- **A1 Chưa đăng nhập iCloud hoặc đổi tài khoản**: không đồng bộ, hiện trạng thái rõ (FR-093).
- **A2 Mất mạng khi đang bật**: app vẫn dùng bình thường trên máy.

**Hậu điều kiện**: Khi tắt, dữ liệu trên máy giữ nguyên. Đồng bộ chỉ áp dụng cho profile đang mở (ADR-28).

**FR**: FR-070, FR-092, FR-093. **NFR**: NFR-001 (ngoại lệ khi bật, xem ADR-29), NFR-007.

### UC-28 — Nhắc ôn hằng ngày

1. Cài đặt → Ôn tập → bật "Nhắc ôn hằng ngày"; lần đầu hệ thống xin quyền thông báo.
2. Người học chọn giờ nhắc (mặc định 20:00); hệ thống lên lịch thông báo cục bộ lặp hằng ngày với nội dung cố định ("Đến giờ ôn từ vựng"), không nêu số thẻ.
3. Chạm thông báo ⇒ mở app ở Trang chủ (banner "Ôn hôm nay"); không tự bắt đầu phiên.

**Biên**: quyền bị từ chối ⇒ công tắc quay về tắt kèm hướng dẫn mở Cài đặt hệ thống; tắt công tắc ⇒ hủy lịch. Không gửi dữ liệu ra ngoài (NFR-007). Huy hiệu số từ đến hạn trên biểu tượng ứng dụng/Dock (P2, FR-085; cần quyền thông báo).
**FR**: FR-063, FR-085.


### UC-30 — Thêm từ nhanh

**Mục tiêu**: Thêm từ mà không phải đi qua Thư mục → Deck.
**Điểm vào**: **[iPhone/iPad]** menu "+" ở toolbar Trang chủ → "Thêm từ nhanh", hoặc nhấn giữ biểu tượng ứng dụng (P2, chưa có FR và chưa xếp lịch); **[Mac]** ⌘N ngoài màn deck hoặc mục File.

**Luồng**
1. Sheet "Thêm từ nhanh": ô "Deck" mặc định là deck dùng gần nhất (chưa có thì bắt chọn).
2. Điền Từ, Cách đọc, Nghĩa, Câu ví dụ như UC-03 (cùng quy tắc bàn phím và bảo vệ thay đổi chưa lưu).
3. "Lưu và thêm tiếp" giữ nguyên deck đã chọn.
4. Xong ⇒ toast "Đã thêm vào “Tên deck”".

**Biên**: chưa có deck ⇒ đề nghị "Tạo deck" ngay trong sheet; deck đã chọn vừa bị xóa ⇒ yêu cầu chọn lại.
**Sau MR (P2, FR-084) [Cuối cùng]**: thêm từ từ ứng dụng khác qua menu Chia sẻ (iOS/iPadOS) và Services (macOS); cần extension nên làm sau khi đăng ký tài khoản (ADR-17).
**FR**: FR-078, FR-084.

---

### UC-31 — Quản lý kiểu ghi chú & field (P1, M3 — ADR-27 Pha B)

**Mục tiêu**: Người học tự định nghĩa field và cách hiện thẻ cho deck.
**Tiền điều kiện**: Có ít nhất kiểu hệ thống "Từ vựng Nhật".

**Kịch bản chính**
1. Mở Cài đặt → "Kiểu ghi chú", hoặc menu deck → "Sửa field".
2. Chọn kiểu; kiểu hệ thống chỉ cho "Nhân bản" (E2).
3. Thêm, đổi tên, kéo-thả sắp xếp, xóa field; đặt vai trò, kiểu nhập (văn bản/kana), bắt buộc, tìm kiếm.
4. Mẫu thẻ: chọn field mặt trước, mặt sau, field đáp án Gõ từ; xem trước thẻ, chạm để lật.
5. Lưu → core kiểm tra và ghi trong một transaction; mọi deck dùng kiểu này cập nhật ngay (form, bảng, thẻ học).

**Thay thế**
- **A1 Xóa field đã có dữ liệu**: cảnh báo "N từ có giá trị ở field này"; xóa mềm, giá trị giữ trong backup; toast "Hoàn tác" (FR-089, FR-077).
- **A2 Đổi tên field**: không đụng dữ liệu (giá trị khóa theo ID field).
- **A3 Gán kiểu cho deck mới**: chọn kiểu ở hộp thoại tạo deck (UC-02).
- **A4 Đóng khi có thay đổi chưa lưu**: như UC-03 A4 (FR-075).
- **E1 Không hợp lệ**: thiếu field vai trò "Từ", tên trùng/rỗng, quá 10 field, mặt trước rỗng ⇒ lỗi inline, không lưu.
- **E2 Kiểu hệ thống**: không sửa trực tiếp; gợi ý "Nhân bản để tùy biến".
- **E3 Không có field đáp án Gõ từ**: chế độ Gõ từ bị ẩn cho deck dùng kiểu này, kèm giải thích.

**Hậu điều kiện**: Định nghĩa kiểu mới có hiệu lực ở mọi deck dùng nó; tiến độ học không đổi.
**Quy tắc**: chế độ học, kana, trùng từ, tìm kiếm dựa vào vai trò field, không dựa vào tên.
**FR**: FR-077, FR-087, FR-088, FR-089.

---

### UC-32 — Quản lý profile (P1, M3 — ADR-28)

**Mục tiêu**: Tách dữ liệu theo ngôn ngữ học; mỗi profile là một DB nhỏ, độc lập.
**Tiền điều kiện**: Luôn có ít nhất một profile (mặc định tạo ở lần chạy đầu).

**Kịch bản chính**
1. Mở Cài đặt → "Profile" (Mac: menu ứng dụng hoặc cửa sổ Settings).
2. Xem danh sách profile: tên, số deck, dung lượng; profile đang mở có dấu tích.
3. "Tạo profile" → nhập tên → Lưu → hỏi "Chuyển sang profile này?".
4. Chuyển profile: đóng phiên học đang mở (xác nhận nếu giữa chừng), mở DB mới, mọi cửa sổ tải lại; Trang chủ hiện ProfileBadge khi có từ 2 profile (`docs/product/DESIGN.md`).

**Thay thế**
- **A1 Đổi tên**: menu ⋯ → "Đổi tên".
- **A2 Xóa**: không xóa được profile đang mở hoặc profile duy nhất; xác nhận nêu "sẽ xóa N deck, M từ và tiến độ học", gợi ý sao lưu trước; xác nhận lần hai rồi xóa file DB. Không hoàn tác được.
- **A3 Sao lưu/khôi phục**: thực hiện trên profile đang mở; tệp ghi tên profile.
- **E1 Tên rỗng/trùng**: lỗi inline.
- **E2 Không mở được DB**: báo lỗi, giữ profile cũ.

**Hậu điều kiện**: Dữ liệu, hàng đợi, thống kê, settings chỉ của profile đang mở.
**FR**: FR-090, FR-091.

---

## 6. Use case mở rộng (P2/P3) — để cân nhắc

| ID | Use case | Giá trị / lý do | Điểm cần quyết định |
|---|---|---|---|
| **UC-15** Từ ngẫu nhiên | Thẻ trên Trang chủ, làm mới sau 15 phút, bền qua khởi động lại | Gợi lại từ, tăng tương tác nhẹ | `docs/product/DESIGN.md` muốn "một tâm điểm mỗi màn hình": đặt ở cột phụ **[iPad/Mac]**, hoặc bỏ trên **[iPhone]** |
| **UC-22** Ôn tập tùy chỉnh | Học trước, cram theo deck/tag/trạng thái, "chỉ thẻ đang quên" | Ôn gấp trước kỳ thi JLPT | Cram có ghi `review_logs` không? Đề xuất: không cập nhật `card_states` |
| **UC-23** Chi tiết từ, lịch sử & tạm ngưng | Xem lịch sử chấm, độ khó/ổn định, lịch kế; **tạm ngưng** thẻ; (tùy chọn) thùng rác khôi phục xóa mềm | Hiểu vì sao từ khó nhớ | Thùng rác giữ bao lâu (vd 30 ngày)? |
| **UC-24** Tags & lọc | Gắn nhãn (JLPT N5, động từ…), lọc/học theo nhãn | Cắt lát từ vựng xuyên deck | Cần bảng `tags`/`word_tags`; nhập/xuất cột `tags` |
| **UC-25** Phát âm (TTS) | Nút nghe bằng `AVSpeechSynthesizer` (`ja-JP`) | Học cách đọc | Phụ thuộc voice đã cài trên thiết bị ⇒ thoái lui êm khi thiếu voice |
| **UC-26** Mục tiêu ngày & streak | Đặt mục tiêu số thẻ/ngày, hiển thị chuỗi ngày | Động lực | Dễ gây áp lực; có tùy chọn tắt; tính theo "ngày học" |
| **UC-27** Đồng bộ iCloud (P3, M4, bật/tắt — ADR-29) | Đồng bộ đa thiết bị Apple qua CloudKit | Dùng chung dữ liệu iPhone/iPad/Mac | Đi ngược "không tài khoản" nếu phải đăng nhập riêng (iCloud là tài khoản hệ thống); giữ UUID + `updated_at` + `deleted_at`; trước đó dùng UC-10/11; **[Cuối cùng]** cần tài khoản trả phí (ADR-17) |
| **UC-29** Widget "Đến hạn hôm nay" | Hiển thị số thẻ đến hạn trên màn hình chủ/Notification Center | Nhắc ôn không cần mở app | Widget phải đọc cùng DB ⇒ cần **App Group** và đặt DB trong container dùng chung (đổi vị trí DB, ảnh hưởng migration và UC-21); xác định tần suất cập nhật timeline; **[Cuối cùng]** làm sau khi đăng ký Apple Developer Program (ADR-17) |

Ý tưởng đã cân nhắc nhưng **không** đề xuất làm sớm: trắc nghiệm nhiều lựa chọn, nhận dạng chữ viết tay, furigana tự động, chia sẻ deck công khai, palette lệnh, Apple Watch.

---

## 7. Ma trận UC → yêu cầu (`docs/product/spec.md`)

| Use case | FR | Ghi chú |
|---|---|---|
| UC-01 | FR-001, FR-007, FR-065, FR-077 | |
| UC-02 | FR-002, FR-007, FR-077, FR-080, FR-086 | |
| UC-03 | FR-003, FR-004, FR-005, FR-006, FR-007, FR-075, FR-077, FR-083, FR-086 | |
| UC-04 | FR-013, FR-079 | |
| UC-05 | FR-033, FR-034, FR-035, FR-036 | Excel P2; ánh xạ cột theo field (spec §7.5) |
| UC-06 | FR-010, FR-016, FR-017, FR-022, FR-026, FR-081, FR-082, FR-088 | FR-026 là P1 |
| UC-07 | FR-011, FR-012, FR-016, FR-019, FR-025, FR-081, FR-088 | FR-025 là P1, phụ thuộc UC-17 |
| UC-08 | FR-014, FR-015, FR-016, FR-017, FR-018, FR-050 | Trần `elapsed_ms`: spec §7.3.6 |
| UC-09 | FR-032 | |
| UC-10 | FR-030 | |
| UC-11 | FR-031, FR-040 | |
| UC-12 | FR-051, FR-052, FR-053, FR-054 | |
| UC-13 | FR-060, FR-074 | FR-067 (chủ đề tối) hoãn |
| UC-14 | FR-018, FR-060 | |
| UC-15 | FR-055 | |
| UC-16 | FR-066 | |
| UC-17 | FR-020, FR-077 | |
| UC-18 | FR-008, FR-009 | |
| UC-19 | FR-021 | |
| UC-20 | FR-022, FR-072 | |
| UC-21 | FR-061, FR-062, FR-064 | NFR-003 |
| UC-22 | FR-023 | |
| UC-23 | FR-024 | |
| UC-24 | FR-069 | |
| UC-25 | FR-068 | |
| UC-26 | FR-056 | |
| UC-27 | FR-070, FR-092, FR-093 | |
| UC-28 | FR-063, FR-085 | |
| UC-29 | FR-073 | Q-10 (App Group) |
| UC-30 | FR-078, FR-084 | FR-084 sau MR [Cuối cùng] |
| UC-31 | FR-077, FR-087, FR-088, FR-089 | ADR-27 Pha B |
| UC-32 | FR-090, FR-091 | ADR-28 |
| §4.0 (xuyên suốt) | FR-071, FR-072, FR-074, FR-075, FR-076 | NFR-006 |

---

## 8. Thứ tự triển khai đề xuất

Yêu cầu tối thiểu: **thư mục, deck, danh sách từ, FSRS, flashcard, gõ từ, cài đặt.**

| Bước | Nội dung | UC | Ghi chú |
|---|---|---|---|
| 0 | Spike kỹ thuật (hiệu năng 50k từ, thư viện FSRS, IME, layout thích ứng, đa cửa sổ) | UC-21 (lõi) | Chốt các điểm S-1…S-8 của spec §3.3 |
| 1 | Nền: Go core (store, schema kiểu ghi chú — ADR-27, đường dẫn DB theo profile — ADR-28), `HirakuBridge`, `DesignSystem`, shell iPhone/iPad/Mac | — | Khung feature theo `docs/architecture/ARCHITECTURE.md` §3 |
| 2 | Nội dung | UC-01, UC-02, UC-03, UC-04 | Đã dùng được để nhập từ thủ công |
| 3 | Lõi học | UC-08 (+ `StudyKit`) → UC-06 | Flashcard là cách nhanh nhất kiểm chứng FSRS |
| 4 | Gõ từ | UC-07 (+ `Kana`, IME) | Rủi ro cao, dành thời gian test trên 3 nền tảng |
| 5 | Cài đặt | UC-13, UC-14 | |
| **= MVP** | | | |
| 6 | An toàn dữ liệu | UC-10, UC-11, UC-21 (UI) | Ngay sau MVP, trước khi phát hành |
| 7 | Nhập/xuất | UC-05, UC-09 | |
| 8 | Hoàn thiện | UC-12, UC-16, UC-17 (nội dung), UC-18, UC-19, UC-20, UC-28, UC-31, UC-32 | UC-31: schema đã có từ bước 1 (ADR-27 Pha A); UC-32: đường dẫn profile có từ bước 1 |
| 9 | Tích hợp hệ thống (sau MR, ADR-17) | UC-29, UC-25, UC-24, UC-22, UC-26, UC-15; UC-27 (tùy chọn) | M4; Q-10 đã chốt: DB nằm trong App Group từ M1 |

---

## 9. Ghi chú triển khai

- Mỗi UC thuộc đúng một feature module (§3.2); feature không import feature khác, điều hướng qua `Route` (`docs/architecture/ARCHITECTURE.md` §9).
- Phiên học: `StudySessionController` trong `StudyKit` dùng chung UC-06/07/08; chế độ học đăng ký qua `StudyMode`.
- Ghi `card_states` + `review_logs`: duy nhất qua `SchedulerService.grade()` trong transaction.
- Chuẩn hóa đáp án: duy nhất qua `HirakuCore/Kana`.
- Kiểm thử: Controller của mỗi UC P0 có test với `InMemory*Repository` và `AppClock` giả; mỗi UC P0 có kịch bản XCUITest tương ứng (spec §15), gồm kịch bản kết thúc app giữa phiên và hai cửa sổ.
