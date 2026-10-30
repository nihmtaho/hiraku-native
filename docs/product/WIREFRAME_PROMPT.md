# Prompt tạo wireframe/prototype — hiraku

**Cách dùng**
1. Dán **Prompt gốc** (§1) một lần để đặt bối cảnh. Nếu công cụ cho đính kèm tệp, đính kèm `docs/product/DESIGN.md` và `COPY.md`.
2. Dán lần lượt **Prompt từng màn** (§2). Làm iPhone trước (M1a), iPad/Mac sau (M1b).
3. Cuối cùng dán **Prompt kết nối** (§3) để nối màn hình thành prototype bấm được.
4. Gửi kết quả lại để rà theo checklist §4 trước khi dùng làm đặc tả cho WP-05/WP-06.

Prompt viết bằng tiếng Việt vì nội dung giao diện là tiếng Việt; công cụ đa ngữ vẫn hiểu. Nếu công cụ chỉ nhận tiếng Anh, nhờ nó dịch phần hướng dẫn nhưng **giữ nguyên chuỗi giao diện**.

---

## 1. Prompt gốc (bối cảnh, dán một lần)

```text
Bạn là UX/UI designer cao cấp. Hãy thiết kế wireframe độ trung thực trung bình đến cao và prototype bấm được cho ứng dụng native "hiraku" (開く): học từ vựng tiếng Nhật bằng ôn tập ngắt quãng (FSRS), offline, không tài khoản, giao diện tiếng Việt. Nền tảng: iPhone, iPad, Mac (iOS/iPadOS/macOS 26). Đây là bản thiết kế để lập trình viên SwiftUI triển khai, không phải minh họa trang trí.

PHONG CÁCH "Editorial Ember"
Tối giản kiểu báo in trên giấy ấm: mực đậm, nhiều khoảng trắng, mỗi màn hình MỘT tâm điểm. Trong phiên học, tâm điểm là một chữ kanji cỡ lớn đứng giữa. Phân lớp bằng viền mực và nền giấy/thẻ, KHÔNG dùng bóng đổ nặng.

MÀU (chỉ giao diện sáng, không có chế độ tối)
- Mực #16130F (chữ chính, viền, nền thẻ mặt sau, banner)
- Xám đá #6B655C (chữ phụ, chỉ trên nền sáng)
- Ember #FF4D2E (màu nhấn DUY NHẤT), hover #E83F1F
- Nền giấy #F4F1EA; nền thẻ #FFFDF8; chữ trên mực #F4F1EA; chữ trên Ember #FFFFFF
- Viền mềm #DED8CC; đường kẻ #E8E3D9; mờ #A39C8F (chỉ trang trí/placeholder, KHÔNG cho chữ thông tin; trên nền mực dùng nó làm chữ phụ thay cho xám đá)
- Nền lỗi nhẹ #FFE9E3
- Trạng thái học (chấm tròn 8): Mới #3A6EA5 · Đang học #D9A300 (chữ: #A67C00) · Đã biết #2F9E6F · nền ô đúng #F0F8F4
QUY TẮC EMBER: chỉ dùng cho nút hành động chính, thanh tiến độ, tín hiệu "Học lại"/lỗi, và vài điểm nhấn nhận diện (dấu "·" trong wordmark hira·ku, số lượng trong banner, cách đọc ở mặt sau thẻ). Không dùng Ember làm nền lớn, đường kẻ hay icon trang trí. KHÔNG chữ Ember trên nền giấy #F4F1EA. Không gradient, không emoji.

CHỮ (đơn vị pt; iPhone / iPad / Mac)
- Tiêu đề: Georgia 400, giãn chữ -0.02em. display 40/56/56 · h1 30/34/34 · h2 22/24/24. Một phần tiêu đề in nghiêng, ví dụ "Chào buổi *sáng*".
- Kanji: Noto Sans JP. hero 72/88/88 (một dòng, tự thu nhỏ đến 40 rồi mới xuống dòng) · term 20/20/18.
- Thân/nhãn/nút: Helvetica Neue. body 15/15/13 · nhỏ 13/13/11 · nhãn IN HOA đậm 11, giãn 0.2em · nút đậm 15/15/13.
- Không dùng serif cho nhãn in hoa hay số liệu; không dùng sans cho từ vựng và tiêu đề lớn.

HÌNH KHỐI
- Bo góc kiểu liên tục (squircle): xs 4 · sm 10 · md 14 (thẻ, ô nhập, nút chấm điểm) · lg 20 (thẻ học) · pill (nút hành động, chấm).
- Viền mực 1.5pt cho thẻ phẳng. Thẻ học có bóng rất nhẹ (dịch xuống 6, mờ 10, độ đậm 18%).
- Thang cách: 4 · 8 · 12 · 18 · 24 · 40. Lề màn hình: 18 (iPhone) / 24 (iPad, Mac).
- Vùng chạm tối thiểu 44×44 (iPhone/iPad); điều khiển Mac cao 28–32 (nút chấm điểm 44).
- Icon: SF Symbols, outline mặc định, filled cho mục đang chọn. Dùng tên symbol thật (house, chart.bar, gearshape, plus, ellipsis, xmark, pencil, trash, magnifyingglass, folder, rectangle.stack, keyboard, forward.end, checkmark).

KHUNG THIẾT BỊ
- iPhone 393×852. iPad 11" dọc 834×1194 và ngang 1194×834. Mac cửa sổ 1100×720.
- Chrome là Liquid Glass GỐC của iOS/iPadOS/macOS 26: tab bar nổi dạng viên kính ở đáy iPhone (có thể có một phụ kiện "Đến hạn: N từ · Ôn ngay" ngay phía trên), sidebar kính nổi (cách mép cửa sổ) trên iPad/Mac, nút toolbar là nút tròn/viên kính theo nhóm. Vẽ kính bằng nền ngà bán trong suốt + viền mảnh; KHÔNG tự tạo kiểu mới (không nền mực cho mục đang chọn, không header bảng nền mực). Nội dung cuộn dưới chrome và vẫn đọc được. Bàn phím là thành phần hệ thống: vẽ khung giữ chỗ.
- iPhone: tab bar kính nổi dưới (Trang chủ / Thống kê / Cài đặt (M1a: chỉ Trang chủ và Cài đặt, Thống kê thêm ở M3)). iPad regular và Mac: sidebar kính nổi 232 (wordmark, điều hướng, cây Thư mục → Deck có mở/gập (kéo-thả để sắp xếp), khối "Đến hạn hôm nay" ghim đáy) + vùng nội dung. Phiên học trên iPad/Mac có cột phải 230 (thống kê phiên + hàng đợi) khi vùng nội dung rộng ≥ 760.

THÀNH PHẦN DÙNG LẠI (đặt tên đúng để khớp mã nguồn)
PillButton (primary Ember / secondary viền mực / dark nền mực) · CardSurface · StateDot · ProgressBar · EmptyState (icon 28 + tiêu đề h2 + mô tả + nút chính) · GradeButton · KanaCell · SectionEyebrow.
Mỗi thành phần tương tác cần đủ trạng thái: mặc định, nhấn, hover (iPad/Mac), focus bàn phím, vô hiệu.

NỘI DUNG
- Dùng ĐÚNG chuỗi trong COPY.md (đính kèm hoặc dùng các chuỗi tôi đưa trong từng prompt màn). Không tự viết lại câu chữ. Không dùng lorem ipsum.
- Dữ liệu mẫu: thư mục "Tiếng Nhật N5" (3 deck: "Động từ cơ bản" 24 từ, "Trường học" 18 từ, "Chào hỏi" 9 từ). Từ: 食べる / たべる / ăn · 飲む / のむ / uống · 学校 / がっこう / trường học · 先生 / せんせい / giáo viên · 日本語 / にほんご / tiếng Nhật · 毎日 / まいにち / mỗi ngày. Từ DÀI để thử co chữ: ありがとうございます / cảm ơn (lịch sự). Từ không có kanji: ありがとう (để trống cách đọc).

TRUY CẬP
- Không dùng màu làm kênh duy nhất cho đúng/sai hoặc trạng thái: luôn kèm chữ hoặc icon. Mỗi màn có ghi chú thứ tự đọc VoiceOver cho các điều khiển chính.
- Với mọi màn có chữ, cho xem thêm biến thể cỡ chữ lớn nhất (Dynamic Type accessibility): hàng 4 nút chấm điểm thành lưới 2×2, bảng thành danh sách.

CÁCH LÀM VIỆC
- Làm từng màn khi tôi yêu cầu. Với mỗi màn: (1) wireframe cấu trúc, (2) bản có token đầy đủ, (3) ghi chú: tên thành phần, khoảng cách theo thang, cỡ chữ theo style, trạng thái, hành vi khi tương tác.
- Nếu một yêu cầu mâu thuẫn quy tắc ở trên, nêu mâu thuẫn và đề xuất cách xử lý thay vì tự bỏ qua.
Trả lời "Đã nắm bối cảnh" và chờ prompt màn đầu tiên.
```

---

## 2. Prompt từng màn

### 2.1 Trang chủ (iPhone)

```text
Màn: TRANG CHỦ, iPhone 393×852. Làm 2 biến thể: (a) có dữ liệu, (b) chưa có thư mục.

(a) Từ trên xuống:
- Dòng nhỏ in hoa (eyebrow): ngày hiện tại, ví dụ "THỨ TƯ · 28 THÁNG 10".
- Tiêu đề display Georgia: "Chào buổi *sáng*" (nghiêng chữ cuối).
- Banner nền mực (bo md, đệm 18): nhãn "Ôn hôm nay"; số lượng "%lld từ đến hạn" (con số Ember, phần còn lại #F4F1EA); nút primary "Ôn ngay". Làm thêm trạng thái banner khi không có từ cần ôn: "Hôm nay không có từ cần ôn" kèm nút secondary "Học thêm từ mới".
- Mục "Thư mục": lưới 2 cột CardSurface. Mỗi thẻ: tên thư mục (Georgia h2), "3 deck · 51 từ", cụm ba StateDot cho Mới/Đang học/Đã biết.
- Nút "Thêm thư mục" (icon plus) ở toolbar.
- Tab bar Liquid Glass nổi dạng viên ở đáy; mục "Trang chủ" đang chọn theo kiểu hệ thống (tint Ember). Toolbar trên: nút tròn kính "+" mở menu (Thư mục mới, Thêm từ nhanh).

(b) Trống: EmptyState giữa màn: tiêu đề "Chưa có thư mục", mô tả "Tạo thư mục để bắt đầu thêm từ vựng.", nút primary "Tạo thư mục đầu tiên".

Thêm sheet "Thư mục mới": ô "Tên thư mục" (placeholder "Ví dụ: Tiếng Nhật N5"), nút "Lưu"/"Hủy"; biến thể lỗi inline "Nhập tên thư mục." Menu ⋯ trên thẻ thư mục: Đổi tên, Di chuyển lên, Di chuyển xuống, Xóa; hộp xác nhận "Xóa thư mục “Tiếng Nhật N5”?" với mô tả "Sẽ xóa 3 deck và 51 từ cùng toàn bộ tiến độ học."
Một tâm điểm: banner "Ôn hôm nay".
```

### 2.2 Thư mục → Deck → Danh sách từ (iPhone)

```text
Màn: THƯ MỤC (danh sách deck) và DECK (danh sách từ), iPhone.

THƯ MỤC "Tiếng Nhật N5": nút toolbar "Ôn cả thư mục" và "Tạo deck". Mỗi deck một hàng CardSurface: tên, "24 từ", ba StateDot kèm số. Menu ⋯: Sửa, Di chuyển, Xóa. Trạng thái trống: "Chưa có deck" / "Tạo deck để gom các từ cùng chủ đề." / nút "Tạo deck". Sheet "Deck mới": "Tên deck", "Mô tả" (Tùy chọn), "Kiểu ghi chú" (M1a chỉ hiện "Từ vựng Nhật", không chọn được; vẽ thêm biến thể M3 có Picker). Hộp "Di chuyển deck" với mục bị vô hiệu kèm gợi ý "Cần ít nhất 2 thư mục".

DECK "Động từ cơ bản": ô tìm kiếm hệ thống với placeholder "Tìm theo từ hoặc nghĩa"; menu "Học ▾" ở toolbar kính (Flashcard, Gõ từ), kèm nút "+" (Thêm từ) và "⋯" (Sửa deck, Di chuyển, Xóa) thành các nhóm nút kính; danh sách từ dạng List hai dòng: dòng 1 kanji (Noto Sans JP 20) + cách đọc; dòng 2 nghĩa; StateDot đầu hàng KÈM nhãn chữ "Mới/Đang học/Đã biết" (hoặc nhãn VoiceOver) — màu không là kênh duy nhất. Vuốt hàng: Sửa, Xóa.
Biến thể: không có kết quả tìm ("Không tìm thấy từ" + nút "Xóa bộ lọc"); deck trống ("Chưa có từ" / "Thêm từ đầu tiên để bắt đầu học." / nút "Thêm từ").

SHEET "Từ mới" (các ô dựng theo trường của kiểu ghi chú; kiểu hệ thống có 4 trường): "Từ" (bắt buộc), "Cách đọc" (kèm gợi ý "Để trống nếu từ không có kanji."), "Nghĩa" (bắt buộc), "Câu ví dụ". Nút "Lưu" và "Lưu và thêm tiếp". Biến thể: lỗi "Nhập từ." / "Nhập nghĩa."; cảnh báo trùng "Từ này đã có (nghĩa: ăn)" với hai nút "Vẫn thêm" và "Xem từ đã có".
```

### 2.3 Flashcard (iPhone)

```text
Màn: HỌC FLASHCARD, iPhone 393×852. Toàn màn hình, một tâm điểm: từ vựng.

Thanh trên: nút đóng (xmark) trái, ProgressBar Ember giữa, bộ đếm "7 / 24" phải.
Mặt trước: thẻ lg (bo 20) nền #FFFDF8, viền mực 1.5, bóng rất nhẹ, rộng tối đa 560, cao tối thiểu 360, đệm 40. Giữa thẻ: "食べる" cỡ hero 72, mực. Dưới thẻ gợi ý nhỏ "Chạm để lật".
Mặt sau: nền mực #16130F, chữ #F4F1EA: cách đọc "たべる" (Ember, jp-term), nghĩa "ăn" (h2 Georgia), câu ví dụ "毎日ご飯を食べる。" (body, chữ phụ #A39C8F).
Hàng nút chấm điểm CHỈ xuất hiện sau khi lật. Làm 2 biến thể:
- 2 nút: "Chưa thuộc" (viền + chữ Ember) · "Thuộc" (viền + chữ #2F9E6F).
- 4 nút: "Học lại" (Ember) · "Khó" (#A67C00) · "Tốt" (#2F9E6F) · "Dễ" (#3A6EA5). Nền #FFFDF8, viền cùng màu chữ 1.5, bo md, cao 56, chữ đậm 15. Biến thể phụ P1: dòng khoảng ôn dự kiến dưới nhãn ("10 phút", "3 ngày").
Trạng thái thêm: từ dài "ありがとうございます" (co chữ về một dòng); hộp xác nhận thoát "Thoát phiên học?" / "Các thẻ đã chấm vẫn được giữ." / "Thoát" · "Tiếp tục học"; lỗi ghi "Không ghi được kết quả. Thử lại."; cỡ chữ lớn nhất (lưới 2×2).
Mô tả hiệu ứng lật: xoay trục dọc 350 ms; khi bật Giảm chuyển động thì chuyển mờ 150 ms.
```

### 2.4 Gõ từ (iPhone)

```text
Màn: HỌC GÕ TỪ, iPhone 393×852 (bàn phím tiếng Nhật đang mở, vẽ khung giữ chỗ chiếm khoảng 1/3 dưới).

Cùng thanh trên với Flashcard. Lời nhắc: nhãn "Gõ cách đọc"; nội dung nhắc "食べる" cỡ term lớn (từ có kanji ⇒ đáp án là cách đọc). Dưới là hàng KanaCell, 1 ô cho mỗi ký tự đáp án (た・べ・る ⇒ 3 ô), mỗi ô trên nền thẻ #FFFDF8, bo md, glyph Noto Sans JP 28.
Trạng thái ô: trống (viền #6B655C 1.5) · đang nhập (viền Ember 2) · đang soạn IME (gạch chân mực, CHƯA chấm đúng/sai) · đúng (nền #F0F8F4, chữ #2F9E6F, icon checkmark nhỏ) · sai (nền #FFE9E3, viền Ember, chữ mực #16130F, icon xmark). Chữ Ember KHÔNG đặt trên #FFE9E3.
Các màn cần vẽ:
1. Đang nhập dở (2/3 ô đã đúng, ô thứ 3 đang soạn).
2. Đúng hết: "Chính xác!" (h2) + tự chuyển thẻ sau một nhịp ngắn (ghi chú 600 ms).
3. Sai khi nhấn Return: "Chưa đúng" + "Đáp án: たべる" trên khối nền mực kèm nghĩa "ăn" và ví dụ; nút "Tiếp".
4. Từ không có cách đọc: lời nhắc là nghĩa "cảm ơn", nhãn "Gõ từ", đáp án là từ.
Ghi chú kỹ thuật cần thể hiện: chỉ MỘT trường nhập thật điều khiển các ô (không phải mỗi ô một trường); gợi ý ngôn ngữ "Gõ bằng romaji hoặc kana."; nút "Kiểm tra" (iPhone) và nút "Bỏ qua" (icon forward.end).
```

### 2.5 Màn "Xong!" và Cài đặt (iPhone)

```text
Màn A: XONG! — tiêu đề display "Xong!" (Georgia); dòng "Đã học 24 từ"; "Thời gian: 6 phút"; khối "Phân bố điểm" (biểu đồ cột nằm ngang gọn 4 mức, nhãn chữ trên mỗi cột, màu Ember/#A67C00/#2F9E6F/#3A6EA5); nút primary "Về trang chủ". Một tâm điểm: chữ "Xong!".

Màn B: CÀI ĐẶT, iPhone, hai nhóm "Hiển thị" và "Ôn tập":
- Hiển thị: "Cỡ chữ" với thanh trượt 80%–140% (bước 5%) hiện "100%"; ô xem trước "食べる — học tiếng Nhật" đổi theo cỡ.
- Ôn tập: "Từ mới mỗi ngày" (ô số, mô tả "Số từ mới tối đa được thêm vào mỗi ngày học."); "Độ giữ lại mục tiêu" (thanh trượt 70%–95%, mô tả "Độ giữ lại cao hơn thì ôn nhiều hơn."); "Nút chấm điểm" (2 nút / 4 nút); "Giờ bắt đầu ngày học" (mô tả "Học sau nửa đêm vẫn tính vào ngày trước đó cho tới giờ này."); "Bước học ngắn" (công tắc, mô tả); mục nâng cao thu gọn "Khoảng ôn tối đa" (đơn vị "ngày"). Ghi chú cuối nhóm: "Thay đổi chỉ áp dụng cho các lần chấm sau."
- Điều khiển hệ thống (công tắc, thanh trượt) tint Ember. Biến thể lỗi nhập ngoài miền: "Nhập giá trị từ 0 đến 999."
```

### 2.6 iPad và Mac (M1b)

```text
Màn: VỎ IPAD VÀ MAC. Làm 3 khung: iPad ngang 1194×834, iPad dọc 834×1194, Mac cửa sổ 1100×720. Khi iPad ở Split View hẹp thì quay về bố cục iPhone (tab bar).

Cấu trúc chung: sidebar kính nổi 232 (wordmark "hira·ku" chữ thường Helvetica Neue với dấu · Ember; mục Trang chủ/Thống kê/Cài đặt; mục "Thư mục" kèm cây Thư mục → Deck; khối "Đến hạn hôm nay" ghim đáy với số và nút "Ôn ngay"). Mục sidebar đang chọn theo kiểu chọn của hệ thống (viên kính sáng), không nền mực.
Vẽ các màn:
1. Trang chủ: lưới thư mục 2–3 cột; banner chiếm cột chính; layout hai cột 1.6fr / 1fr nếu đủ chỗ.
2. Deck với Table nhiều cột: Từ · Cách đọc · Nghĩa · Trạng thái (chấm + chữ); sắp xếp theo cột; chọn nhiều hàng; header bảng theo kiểu hệ thống (không nền mực).
3. Phiên học Flashcard có cột phải 230: "Phiên này" (còn lại, mới, ôn) + "Hàng đợi" (danh sách thẻ kế). Thẻ căn giữa vùng nội dung.
4. Mac: thanh menu hiện các mục "Thư mục mới…", "Deck mới…", "Từ mới…", "Lật thẻ", "Thoát phiên học"; trạng thái hover (nền #E8E3D9, nút Ember → #E83F1F) và focus bàn phím.
Trên Mac, Cài đặt không nằm trong sidebar mà mở cửa sổ Settings (⌘,). Kéo-thả: thư mục và deck sắp xếp bằng kéo; deck kéo thả lên thư mục ở sidebar để di chuyển (vẽ vạch chèn Ember). Ghi chú phím tắt: Space/Return lật thẻ; 1–4 chấm điểm; Esc thoát; ⌘N thêm theo ngữ cảnh; ⌘F tìm kiếm.
```

### 2.7 Kiểu ghi chú và trường (M3 — ADR-27, UC-31)

```text
Màn: KIỂU GHI CHÚ, iPhone 393×852 và iPad ngang 1194×834. Một tâm điểm: danh sách trường.

Danh sách kiểu: "Từ vựng Nhật" (kiểu có sẵn, nhãn "Dùng cho 3 deck") và "Kanji N3" (tùy biến). Kiểu có sẵn mở ở chế độ chỉ đọc với dòng "Kiểu có sẵn không sửa được. Nhân bản để tùy biến." và nút "Nhân bản".
Màn sửa "Kanji N3": ô "Tên kiểu"; nhóm "Trường" là List hệ thống, mỗi hàng FieldRow: tay kéo, tên trường, chip vai trò (Từ / Cách đọc / Nghĩa / Ví dụ / Văn bản), icon kiểu nhập (Văn bản / Kana), chữ "Bắt buộc" nếu có. Dữ liệu mẫu: Kanji (Từ, bắt buộc) · On'yomi (Cách đọc, Kana) · Kun'yomi (Văn bản, Kana) · Nghĩa (Nghĩa, bắt buộc) · Bộ thủ (Văn bản). Nút "Thêm trường"; ghi chú "Tối đa 10 trường."
Nhóm "Mẫu thẻ": "Mặt trước" và "Mặt sau" là danh sách chọn nhiều có dấu tích; "Đáp án khi gõ từ" là Picker (gồm "Không dùng gõ từ", kèm gợi ý "Không chọn thì chế độ Gõ từ bị ẩn ở các deck dùng kiểu này.").
Nhóm "Xem trước": CardPreview tỷ lệ 0,6 dùng đúng flashcard-front/back; "Chạm để lật". Kiểu chữ theo vai trò, không theo tên trường.
Sheet "Sửa trường": "Tên trường", "Vai trò" (kèm "Vai trò quyết định cách học, gõ từ và tìm kiếm dùng trường này."), "Kiểu nhập", công tắc "Bắt buộc", "Dùng khi tìm kiếm".
Biến thể cần vẽ: lỗi "Cần một trường vai trò “Từ”."; lỗi "Vai trò này đã dùng cho trường “Nghĩa”."; xác nhận xóa "Xóa trường “Bộ thủ”?" / "42 từ có giá trị ở trường này. Giá trị vẫn được giữ trong bản sao lưu."; toast "Đã xóa trường “Bộ thủ”" + "Hoàn tác"; đủ 10 trường (nút "Thêm trường" vô hiệu).
iPad: hai cột — trái danh sách trường, phải mẫu thẻ và xem trước. Toolbar: [Hủy] trái khi có thay đổi, [Lưu] phải.
Kèm hai hệ quả ở màn khác: (1) Danh sách từ iPad với cột theo trường của "Kanji N3"; (2) menu "Học ▾" khi kiểu không có đáp án gõ: mục "Gõ từ" vô hiệu kèm "Kiểu ghi chú của deck này không có trường đáp án để gõ."
```

### 2.8 Profile (M3 — ADR-28, UC-32)

```text
Màn: PROFILE, iPhone 393×852, iPad ngang 1194×834 và Mac cửa sổ Settings. Một tâm điểm: danh sách profile.

Dữ liệu mẫu: "Tiếng Nhật" (12 deck · 4,2 MB, đang mở, dấu tích Ember kèm nhãn "Đang mở") · "Tiếng Anh" (3 deck · 0,8 MB).
Đầu màn: mô tả "Mỗi profile có dữ liệu riêng, ví dụ một profile cho mỗi ngôn ngữ." Toolbar: "Tạo profile" (+). Mỗi hàng ProfileRow: tên, dòng phụ "N deck · dung lượng"; menu ⋯: Đổi tên, Xóa.
Sheet "Profile mới": "Tên profile" (placeholder "Tiếng Nhật"); sau khi Lưu hỏi "Chuyển sang “Tiếng Anh”?" với "Chuyển" / "Ở lại".
ProfileBadge: chip "Tiếng Nhật" ở Trang chủ iPhone (dưới eyebrow ngày) và đầu sidebar iPad/Mac (dưới wordmark); chạm mở menu chuyển profile. Chỉ hiện khi có ≥ 2 profile.
Mac: thêm menu ứng dụng "Chuyển profile ▸" liệt kê profile, mục đang mở có dấu tích.
Biến thể cần vẽ: chuyển khi đang học ("Phiên học đang mở sẽ kết thúc. Các thẻ đã chấm vẫn được giữ."); lỗi "Không mở được profile này. Vẫn dùng “Tiếng Nhật”."; xóa hai bước — bước 1 "Xóa profile “Tiếng Anh”?" / "Sẽ xóa 3 deck, 240 từ và tiến độ học. Nên sao lưu trước." với "Sao lưu trước", "Xóa" (đỏ hệ thống), "Hủy"; bước 2 "Xóa vĩnh viễn?" / "Không hoàn tác được."; mục Xóa vô hiệu ở profile đang mở ("Không xóa được profile đang mở.") và khi chỉ còn một profile ("Cần ít nhất một profile.").
Trạng thái tải khi chuyển: ProgressView hệ thống ngắn, không màn chờ riêng.
```

---

## 3. Prompt kết nối prototype

```text
Nối các màn đã thiết kế thành prototype bấm được cho iPhone, với các luồng sau. Mỗi bước là một chuyển cảnh có thể bấm; thể hiện cả trạng thái trống và lỗi.

F1 Lần đầu: Trang chủ (trống) → "Tạo thư mục đầu tiên" → sheet → Lưu → Thư mục (trống) → "Tạo deck" → sheet → Lưu → Deck (trống) → "Thêm từ" → sheet → "Lưu và thêm tiếp" (giữ sheet, xóa trường, focus ô "Từ") → Lưu → Danh sách từ.
F2 Học Flashcard: Deck → "Flashcard" → thẻ mặt trước → lật → chấm → thẻ kế … → "Xong!" → "Về trang chủ".
F3 Học Gõ từ: Deck → "Gõ từ" → gõ đúng (tự chuyển) và gõ sai (hiện đáp án, "Tiếp") → "Xong!".
F4 Xóa an toàn: Trang chủ → menu ⋯ thư mục → "Xóa" → hộp xác nhận nêu hậu quả → "Xóa" hoặc "Hủy".
F5 Cài đặt: tab "Cài đặt" → đổi cỡ chữ (xem trước đổi theo) → đổi "Nút chấm điểm" sang 4 nút → quay lại học và thấy 4 nút.
F6 Kiểu ghi chú (M3): Cài đặt → "Kiểu ghi chú" → "Từ vựng Nhật" → "Nhân bản" → thêm trường "Bộ thủ" → bỏ "Ví dụ" khỏi mặt sau → xem trước lật thẻ → Lưu → tạo deck chọn kiểu mới → "Thêm từ" thấy ô "Bộ thủ".
F7 Profile (M3): Cài đặt → "Profile" → "Tạo profile" → nhập "Tiếng Anh" → Lưu → "Chuyển" → Trang chủ trống với badge "Tiếng Anh" → chạm badge → chọn "Tiếng Nhật" → dữ liệu cũ hiện lại.

Yêu cầu: giữ nhất quán token; không thêm màn hay chuỗi ngoài danh sách; cuối cùng liệt kê mọi chỗ bạn phải suy đoán hoặc đề xuất khác quy tắc.
```

---

## 4. Checklist rà kết quả

| # | Kiểm tra |
|---|---|
| 1 | Mỗi màn có đúng một tâm điểm; màn học chỉ một kanji lớn |
| 2 | Ember chỉ ở các chỗ được phép; không có chữ Ember trên nền giấy hoặc nền #FFE9E3 |
| 3 | Mọi chữ thông tin đạt tương phản; `#A39C8F` chỉ trang trí hoặc phụ trên nền mực |
| 4 | Đúng/sai và trạng thái học có chữ hoặc icon đi kèm, không chỉ màu |
| 5 | Vùng chạm ≥ 44×44 (iPhone/iPad); nút chấm điểm cao 56 (iPhone) |
| 6 | Chuỗi khớp `COPY.md`; không lorem ipsum, không emoji |
| 7 | Từ dài "ありがとうございます" không bị cắt; cỡ chữ lớn nhất không cắt nội dung |
| 8 | Đủ trạng thái: trống, lỗi, xác nhận xóa, nhấn/hover/focus/vô hiệu |
| 9 | Thành phần đặt tên đúng (PillButton, CardSurface, StateDot, ProgressBar, EmptyState, GradeButton, KanaCell, SectionEyebrow) |
| 10 | Chrome hệ thống chỉ là khung giữ chỗ; nội dung vẫn đọc được dưới thanh kính (ADR-15) |
| 11 | Có ghi chú VoiceOver và khoảng cách theo thang cho thành phần chính |
| 12 | Màn kiểu ghi chú: kiểu chữ trên thẻ suy ra từ vai trò; không có điều khiển chỉnh màu/cỡ chữ/HTML (D-6); kiểu có sẵn chỉ đọc |
| 13 | Màn profile: tên profile đang mở luôn nhận biết được; xóa có hai bước và gợi ý sao lưu; dấu tích có nhãn chữ/VoiceOver |
