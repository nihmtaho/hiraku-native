# Bảng chuỗi giao diện — hiraku (開く) · Tiếng Việt

**Ngày**: 2026-10-29
**Phiên bản**: 1.6 (nút “Kiểm tra” = nộp đáp án; thuật ngữ đồng bộ rà soát 2026-10-29) · 1.5 (thêm chuỗi profile — ADR-28, UC-32) · 1.4 (thêm chuỗi kiểu ghi chú và field tùy biến — ADR-27, UC-31) · 1.3 (bản đề xuất, chờ duyệt; thêm chuỗi hoàn tác, bảo vệ thay đổi, thêm nhanh, sắp xếp/lọc theo ADR-18)
**Phạm vi**: các màn của M1a (iPhone) cộng chuỗi menu macOS của M1b. Chuỗi của M2–M4 thêm khi tới mốc.
**Tài liệu liên quan**: `docs/product/use-cases.md` (nguồn kịch bản và một số câu đã chốt), `docs/product/spec.md` §8.2 (String Catalog), `docs/product/DESIGN.md` (kiểu chữ), `docs/architecture/ARCHITECTURE.md` (L8: không hard-code chuỗi)

---

## 1. Cách dùng

- Mỗi dòng là một mục trong `Localizable.xcstrings`. **Key** theo mẫu `khu_vực.màn.phần_tử` (chữ thường, dấu chấm), ví dụ `folders.create.title`.
- `%@` = chuỗi, `%lld` = số nguyên, `%%` = ký hiệu %. Trong Swift viết nội suy (`"\(count) từ"`), Xcode tự chuyển thành `%lld`.
- Tiếng Việt không chia số ít/số nhiều nên **không cần biến thể plural**.
- Định dạng số, ngày, giờ dùng formatter theo locale `vi_VN` (ví dụ 50.000 từ, "Thứ Tư, 28 tháng 10"), không viết tay trong chuỗi.
- Cột **Ghi chú** nêu ngữ cảnh cho người dịch và tên biến. Chữ in hoa ở nhãn (`label-caps`) do kiểu chữ tạo ra; chuỗi lưu ở dạng chữ thường/hoa chữ cái đầu.
- Trạng thái: toàn bộ là *đề xuất*. Câu đã có trong use case giữ nguyên nội dung.

## 2. Giọng văn

| Quy tắc | Ví dụ đúng | Tránh |
|---|---|---|
| Ngắn, dùng động từ cho nút | "Thêm từ" | "Nhấn vào đây để thêm từ" |
| Chữ hoa đầu câu, không viết hoa từng từ | "Tạo thư mục đầu tiên" | "Tạo Thư Mục Đầu Tiên" |
| Hạn chế "bạn"; ưu tiên câu không chủ ngữ | "Chưa có từ" | "Bạn chưa có từ nào" |
| Dấu chấm than chỉ cho khoảnh khắc hoàn thành | "Xong!", "Chính xác!" | "Lỗi!" |
| Lỗi: nói chuyện gì xảy ra và làm gì tiếp; không đổ lỗi, không thuật ngữ kỹ thuật | "Không lưu được. Thử lại." | "Transaction thất bại" |
| Không emoji; dấu nháy kiểu “ ” cho tên người dùng đặt; dấu … cho mục mở hộp thoại ở menu macOS | “Từ vựng N5” | "Từ vựng N5" |
| Nhãn nút xác nhận lặp lại hành động, không dùng "OK" | "Xóa", "Hủy" | "OK" |

## 3. Thuật ngữ

| Khái niệm | Dùng | Ghi chú |
|---|---|---|
| Folder | thư mục | |
| Deck | deck | Giữ như spec và use case; đổi sang "bộ thẻ" nếu muốn thuần Việt (quyết định ở GATE-1, ảnh hưởng toàn bộ chuỗi) |
| Word | từ | |
| Word / Reading / Meaning / Example | Từ / Cách đọc / Nghĩa / Câu ví dụ | Tên field của kiểu hệ thống |
| Note type | kiểu ghi chú | ADR-27 |
| Profile | profile | ADR-28; giữ nguyên tiếng Anh như "deck", chốt cùng ở GATE-1 |
| Field | trường | Tài liệu kỹ thuật viết "field"; giao diện viết "trường" (PO duyệt 2026-10-28; chốt chung với "deck"/"bộ thẻ" ở GATE-1) |
| Card template / front / back | mẫu thẻ / mặt trước / mặt sau | |
| Field role (term, reading, meaning, example, text) | vai trò: Từ, Cách đọc, Nghĩa, Ví dụ, Văn bản | |
| New / Learning / Known | Mới / Đang học / Đã biết | |
| Again / Hard / Good / Easy (4 nút) | Học lại / Khó / Tốt / Dễ | |
| Again / Good (2 nút) | Chưa thuộc / Thuộc | Theo UC-06 |
| Review session | phiên học | |
| Due today | đến hạn hôm nay / ôn hôm nay | |
| Flashcard / Typing mode | Flashcard / Gõ từ | |

---

## 4. Chung

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| common.save | Lưu | |
| common.cancel | Hủy | |
| common.delete | Xóa | |
| common.edit | Sửa | |
| common.rename | Đổi tên | |
| common.move | Di chuyển | |
| common.close | Đóng | Nút icon `xmark` |
| common.done | Xong | Nút đóng sheet/hộp thoại |
| common.next | Tiếp | |
| common.skip | Bỏ qua | |
| common.retry | Thử lại | |
| common.more | Thêm | Nhãn VoiceOver của menu ⋯ |
| common.required | Bắt buộc | Nhãn phụ dưới ô nhập |
| common.optional | Tùy chọn | |
| common.wordCount | %lld từ | |
| common.deckCount | %lld deck | |
| common.folderMeta | %lld deck · %lld từ | Thẻ thư mục |
| common.undo | Hoàn tác | Nút trên toast (FR-020, FR-077) |
| undo.graded | Đã chấm: %@ | Toast sau khi chấm; `%@` = nhãn nút |
| undo.deleted.word | Đã xóa “%@” | Toast sau khi xóa từ (P1) |
| undo.deleted.deck | Đã xóa deck “%@” | |
| undo.deleted.folder | Đã xóa thư mục “%@” | |
| undo.moved | Đã di chuyển | |
| undo.reordered | Đã sắp xếp lại | |
| discard.title | Bỏ thay đổi? | FR-075 |
| discard.message | Nội dung vừa nhập sẽ không được lưu. | |
| discard.confirm | Bỏ thay đổi | Vai trò hủy bỏ |
| discard.cancel | Tiếp tục chỉnh sửa | |
| deck.due | %lld đến hạn | Thẻ deck/thư mục (FR-079, P1) |
| error.generic.title | Có lỗi xảy ra | |
| error.generic.message | Không thực hiện được. Thử lại. | |
| error.save.failed | Không lưu được. Thử lại. | |
| error.storage.full | Bộ nhớ thiết bị đã đầy. Giải phóng dung lượng rồi thử lại. | UC-21 E1 |
| error.database.title | Không mở được dữ liệu | UC-21 E2 |
| error.database.message | Dữ liệu có thể bị hỏng. Đừng xóa ứng dụng. Khôi phục từ file sao lưu nếu có. | M1a chỉ hiện thông báo; khôi phục ở M2 |

## 5. Điều hướng

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| nav.home | Trang chủ | Tab / sidebar |
| nav.stats | Thống kê | M3 |
| nav.settings | Cài đặt | |
| nav.folders | Thư mục | Tiêu đề mục trong sidebar |
| nav.dueToday | Đến hạn hôm nay | Khối ghim đáy sidebar; kèm số |
| nav.study | Học | Menu toolbar ở màn deck (Flashcard, Gõ từ) |
| nav.accessory.due | Đến hạn: %lld từ | Phụ kiện đáy tab bar (P1) |
| app.name | hiraku | Tên hiển thị; wordmark "hira·ku" là tài sản đồ họa, không phải chuỗi |

## 6. Trang chủ (FeatureHome)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| home.greeting.morning | Chào buổi *sáng* | Markdown nghiêng cho từ cuối (DESIGN: tiêu đề serif) |
| home.greeting.noon | Chào buổi *trưa* | |
| home.greeting.afternoon | Chào buổi *chiều* | |
| home.greeting.evening | Chào buổi *tối* | |
| home.banner.title | Ôn hôm nay | Eyebrow của banner |
| home.banner.count | %lld từ đến hạn | |
| home.banner.cta | Ôn ngay | `button-primary` |
| home.banner.empty | Hôm nay không có từ cần ôn | UC-06 E1 |
| home.banner.learnNew | Học thêm từ mới | Chỉ khi còn từ mới ngoài hạn mức |
| home.folders.title | Thư mục | |
| home.empty.title | Chưa có thư mục | |
| home.empty.message | Tạo thư mục để bắt đầu thêm từ vựng. | |
| home.empty.cta | Tạo thư mục đầu tiên | UC-01 |

Khung giờ lời chào theo đồng hồ máy: 04:00–10:59 sáng · 11:00–12:59 trưa · 13:00–17:59 chiều · 18:00–03:59 tối.

## 7. Thư mục (FeatureFolders)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| folders.add | Thêm thư mục | Nút toolbar |
| folders.create.title | Thư mục mới | Tiêu đề sheet |
| folders.rename.title | Đổi tên thư mục | |
| folders.name.label | Tên thư mục | |
| folders.name.placeholder | Ví dụ: Tiếng Nhật N5 | |
| folders.name.error.empty | Nhập tên thư mục. | Lỗi inline (UC-01 E2) |
| folders.name.error.tooLong | Tên tối đa 100 ký tự. | |
| folders.menu.moveUp | Di chuyển lên | |
| folders.menu.moveDown | Di chuyển xuống | |
| folders.delete.title | Xóa thư mục “%@”? | `%@` = tên |
| folders.delete.message | Sẽ xóa %lld deck và %lld từ cùng toàn bộ tiến độ học. | UC-01 A3; biến: số deck, số từ |
| folders.openStudy | Ôn cả thư mục | Toolbar màn thư mục |

## 8. Deck (FeatureDecks)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| decks.add | Tạo deck | |
| decks.create.title | Deck mới | |
| decks.edit.title | Sửa deck | |
| decks.name.label | Tên deck | |
| decks.description.label | Mô tả | Kèm nhãn "Tùy chọn" |
| decks.noteType.label | Kiểu ghi chú | UC-02 bước 2; M1a chỉ hiện "Từ vựng Nhật", chọn kiểu khác từ M3 |
| decks.noteType.locked | Không đổi được kiểu khi deck đã có từ. | Ghi chú dưới ô khi sửa deck |
| decks.editFields | Sửa trường | Mục menu ⋯ của deck (M3) |
| decks.name.error.empty | Nhập tên deck. | |
| decks.name.error.tooLong | Tên tối đa 100 ký tự. | |
| decks.move.title | Di chuyển deck | |
| decks.move.prompt | Chọn thư mục đích | |
| decks.move.disabledHint | Cần ít nhất 2 thư mục | UC-02 A2 |
| decks.delete.title | Xóa deck “%@”? | |
| decks.delete.message | Sẽ xóa %lld từ và tiến độ học. | UC-02 A3 |
| decks.empty.title | Chưa có deck | |
| decks.empty.message | Tạo deck để gom các từ cùng chủ đề. | |
| decks.empty.cta | Tạo deck | |

## 9. Từ vựng (FeatureWords)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| words.add | Thêm từ | |
| words.create.title | Từ mới | |
| words.edit.title | Sửa từ | |
| words.field.word | Từ | |
| words.field.reading | Cách đọc | |
| words.field.meaning | Nghĩa | |
| words.field.example | Câu ví dụ | |
| words.field.word.placeholder | 食べる | Ví dụ minh họa, không dịch |
| words.field.reading.placeholder | たべる | |
| words.field.meaning.placeholder | ăn | |
| words.field.example.placeholder | 毎日ご飯を食べる。 | |
| words.field.reading.hint | Để trống nếu từ không có kanji. | Ảnh hưởng chế độ Gõ từ (FR-004) |
| words.error.word.empty | Nhập từ. | |
| words.error.meaning.empty | Nhập nghĩa. | |
| words.saveAndNext | Lưu và thêm tiếp | UC-03 bước 5 |
| words.duplicate.title | Từ này đã có (nghĩa: %@) | UC-03 A3; `%@` = nghĩa của từ đã có |
| words.duplicate.addAnyway | Vẫn thêm | |
| words.duplicate.viewExisting | Xem từ đã có | |
| words.delete.title | Xóa “%@”? | `%@` = từ |
| words.delete.message | Tiến độ học của từ này cũng bị xóa. | UC-03 A2 |
| words.empty.title | Chưa có từ | |
| words.empty.message | Thêm từ đầu tiên để bắt đầu học. | |
| words.empty.cta | Thêm từ | |
| words.search.prompt | Tìm theo từ hoặc nghĩa | M1a: Từ/Nghĩa; P1 thêm Cách đọc |
| words.search.empty.title | Không tìm thấy từ | UC-04 |
| words.search.empty.clear | Xóa bộ lọc | |
| words.column.word | Từ | Tiêu đề cột `Table` |
| words.column.reading | Cách đọc | |
| words.column.meaning | Nghĩa | |
| words.column.state | Trạng thái | |
| words.state.new | Mới | |
| words.state.learning | Đang học | |
| words.state.known | Đã biết | |
| words.study.flashcard | Flashcard | Mục trong menu "Học" ở toolbar màn deck |
| words.study.typing | Gõ từ | Mục trong menu "Học" ở toolbar màn deck |
| words.sort | Sắp xếp | Menu (P1) |
| words.sort.added | Mới thêm trước | |
| words.sort.alpha | Theo từ | |
| words.filter.all | Tất cả | Chip lọc (P1) |
| words.filter.new | Mới | |
| words.filter.learning | Đang học | |
| words.filter.known | Đã biết | |
| words.filter.due | Đến hạn | |
| words.reading.suggest | Gợi ý: %@ | Chip gợi ý cách đọc (P2, FR-083) |
| quickadd.menu | Thêm từ nhanh | Mục trong menu "+" ở Trang chủ (P1) |
| quickadd.title | Thêm từ nhanh | Tiêu đề sheet |
| quickadd.deck.label | Deck | |
| quickadd.deck.prompt | Chọn deck | |
| quickadd.added | Đã thêm vào “%@” | Toast; `%@` = tên deck |

## 10. Phiên học (FeatureStudy, StudyKit)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| study.exit | Thoát | Nhãn VoiceOver của nút đóng |
| study.progress | %lld / %lld | Đã chấm / tổng |
| study.exit.title | Thoát phiên học? | Chỉ hỏi khi giữa chừng |
| study.exit.message | Các thẻ đã chấm vẫn được giữ. | |
| study.exit.confirm | Thoát | |
| study.exit.cancel | Tiếp tục học | |
| study.rail.session | Phiên này | Cột phải (inspector) trên iPad/Mac |
| study.rail.remaining | Còn lại | |
| study.rail.new | Mới | |
| study.rail.review | Ôn | |
| study.rail.queue | Hàng đợi | |
| study.done.title | Xong! | |
| study.done.learned | Đã học %lld từ | |
| study.done.time | Thời gian: %@ | `%@` = thời lượng đã định dạng |
| study.done.distribution | Phân bố điểm | |
| study.done.home | Về trang chủ | |
| study.empty.title | Hôm nay không có từ cần ôn | UC-06 E1 |
| study.empty.learnNew | Học thêm từ mới | |
| study.error.save | Không ghi được kết quả. Thử lại. | UC-08 E3; không chuyển thẻ |

**Chấm điểm**

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| grade.again | Học lại | 4 nút |
| grade.hard | Khó | |
| grade.good | Tốt | |
| grade.easy | Dễ | |
| grade.again.simple | Chưa thuộc | 2 nút |
| grade.good.simple | Thuộc | |
| grade.interval | %@ | Khoảng ôn dự kiến, ví dụ "10 phút", "3 ngày" (FR-026, P1) |

## 11. Flashcard (FeatureFlashcard)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| flashcard.flip | Lật thẻ | Nút/VoiceOver |
| flashcard.flip.hint.touch | Chạm để lật | Gợi ý nhỏ dưới thẻ (iPhone) |
| flashcard.flip.hint.keyboard | Nhấn Space để lật | Khi có bàn phím phần cứng |
| flashcard.a11y.front | Thẻ: %@. Chạm đúp để lật. | `%@` = từ |
| flashcard.a11y.back | Cách đọc %@. Nghĩa: %@. | |
| flashcard.a11y.grade | Chấm: %@ | `%@` = nhãn nút |

## 12. Gõ từ (FeatureTyping)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| typing.prompt.reading | Gõ cách đọc | Khi từ có kanji |
| typing.prompt.word | Gõ từ | Khi từ không có cách đọc; lời nhắc là nghĩa |
| typing.hint | Gõ bằng romaji hoặc kana. | |
| typing.correct | Chính xác! | UC-07 bước 3 |
| typing.wrong | Chưa đúng | |
| typing.answer | Đáp án: %@ | Hiện đáp án đúng (FR-019) |
| typing.submit | Kiểm tra | Nút trên iPhone, tương đương Return: nộp đáp án (UC-07) |
| typing.next | Tiếp | |
| typing.skip | Bỏ qua | |
| typing.a11y.cell | Ô %lld trên %lld | |
| typing.a11y.cell.correct | Ô %lld trên %lld: đúng | |
| typing.a11y.cell.wrong | Ô %lld trên %lld: sai | |
| typing.a11y.result.correct | Chính xác | Thông báo VoiceOver |
| typing.a11y.result.wrong | Chưa đúng. Đáp án là %@ | |

## 13. Cài đặt (FeatureSettings)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| settings.title | Cài đặt | |
| settings.section.display | Hiển thị | |
| settings.section.review | Ôn tập | |
| settings.fontScale | Cỡ chữ | |
| settings.fontScale.value | %lld%% | |
| settings.fontScale.preview | 食べる — học tiếng Nhật | UC-13; không dịch |
| settings.newPerDay | Từ mới mỗi ngày | |
| settings.newPerDay.help | Số từ mới tối đa được thêm vào mỗi ngày học. | |
| settings.retention | Độ giữ lại mục tiêu | |
| settings.retention.help | Độ giữ lại cao hơn thì ôn nhiều hơn. | UC-14 |
| settings.gradingButtons | Nút chấm điểm | |
| settings.gradingButtons.two | 2 nút | |
| settings.gradingButtons.four | 4 nút | |
| settings.dayStart | Giờ bắt đầu ngày học | |
| settings.dayStart.help | Học sau nửa đêm vẫn tính vào ngày trước đó cho tới giờ này. | |
| settings.shortTerm | Bước học ngắn | |
| settings.shortTerm.help | Thẻ mới và thẻ quên quay lại sau vài phút trong cùng phiên. | |
| settings.maxInterval | Khoảng ôn tối đa | Mục nâng cao, thu gọn |
| settings.maxInterval.unit | ngày | |
| settings.error.range | Nhập giá trị từ %lld đến %lld. | Lỗi inline |
| settings.note.future | Thay đổi chỉ áp dụng cho các lần chấm sau. | UC-14 |
| settings.resetDefaults | Khôi phục mặc định | Theo nhóm (P1) |

## 13a. Kiểu ghi chú (M3 — ADR-27, UC-31)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| noteTypes.title | Kiểu ghi chú | Mục Cài đặt và tiêu đề màn |
| noteTypes.system.name | Từ vựng Nhật | Tên kiểu hệ thống |
| noteTypes.system.readOnly | Kiểu có sẵn không sửa được. Nhân bản để tùy biến. | UC-31 E2 |
| noteTypes.duplicate | Nhân bản | |
| noteTypes.duplicate.defaultName | %@ (bản sao) | `%@` = tên kiểu gốc |
| noteTypes.name.label | Tên kiểu | |
| noteTypes.name.error.duplicate | Tên này đã có. | |
| noteTypes.usage | Dùng cho %lld deck | |
| noteTypes.section.fields | Trường | |
| noteTypes.section.template | Mẫu thẻ | |
| noteTypes.section.preview | Xem trước | |
| fields.add | Thêm trường | |
| fields.newName | Trường mới | Tên mặc định |
| fields.edit.title | Sửa trường | |
| fields.name.label | Tên trường | |
| fields.name.error.empty | Nhập tên trường. | |
| fields.name.error.tooLong | Tên tối đa 40 ký tự. | |
| fields.name.error.duplicate | Trường này đã có trong kiểu. | |
| fields.role.label | Vai trò | |
| fields.role.term | Từ | Bắt buộc, đúng một trường |
| fields.role.reading | Cách đọc | |
| fields.role.meaning | Nghĩa | |
| fields.role.example | Ví dụ | |
| fields.role.text | Văn bản | |
| fields.role.help | Vai trò quyết định cách học, gõ từ và tìm kiếm dùng trường này. | |
| fields.role.error.termMissing | Cần một trường vai trò “Từ”. | UC-31 E1 |
| fields.role.error.taken | Vai trò này đã dùng cho trường “%@”. | `%@` = tên trường |
| fields.inputKind.label | Kiểu nhập | |
| fields.inputKind.text | Văn bản | |
| fields.inputKind.kana | Kana | |
| fields.required | Bắt buộc | |
| fields.searchable | Dùng khi tìm kiếm | |
| fields.limit | Tối đa 10 trường. | |
| fields.delete.title | Xóa trường “%@”? | |
| fields.delete.message | %lld từ có giá trị ở trường này. Giá trị vẫn được giữ trong bản sao lưu. | UC-31 A1 |
| fields.delete.toast | Đã xóa trường “%@” | Kèm nút `common.undo` |
| template.front | Mặt trước | |
| template.back | Mặt sau | |
| template.front.error.empty | Chọn ít nhất một trường cho mặt trước. | |
| template.typingAnswer | Đáp án khi gõ từ | |
| template.typingAnswer.none | Không dùng gõ từ | |
| template.typingAnswer.hint | Không chọn thì chế độ Gõ từ bị ẩn ở các deck dùng kiểu này. | UC-31 E3 |
| template.preview.tapToFlip | Chạm để lật | |
| study.typing.unavailable | Kiểu ghi chú của deck này không có trường đáp án để gõ. | Thay mục "Gõ từ" bị vô hiệu |
| a11y.fieldRow | %@, vai trò %@ | `%@` = tên, vai trò; thêm "bắt buộc" khi có |
| a11y.fieldReorder | Sắp xếp trường | |

## 13b. Profile (M3 — ADR-28, UC-32)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| profiles.title | Profile | Mục Cài đặt và tiêu đề màn |
| profiles.help | Mỗi profile có dữ liệu riêng, ví dụ một profile cho mỗi ngôn ngữ. | Mô tả đầu màn |
| profiles.default.name | Profile chính | Tên profile tạo ở lần chạy đầu |
| profiles.add | Tạo profile | |
| profiles.create.title | Profile mới | |
| profiles.name.label | Tên profile | Placeholder: "Tiếng Nhật" |
| profiles.name.error.empty | Nhập tên profile. | |
| profiles.name.error.tooLong | Tên tối đa 40 ký tự. | |
| profiles.name.error.duplicate | Tên này đã có. | |
| profiles.rename | Đổi tên | |
| profiles.row.detail | %lld deck · %@ | `%@` = dung lượng (ByteCountFormatter) |
| profiles.current | Đang mở | Nhãn VoiceOver cho dấu tích |
| profiles.switch | Chuyển profile | Menu và tiêu đề menu ứng dụng (Mac) |
| profiles.switch.ask | Chuyển sang “%@”? | Sau khi tạo |
| profiles.switch.confirm | Chuyển | |
| profiles.switch.stay | Ở lại | |
| profiles.switch.sessionWarning | Phiên học đang mở sẽ kết thúc. Các thẻ đã chấm vẫn được giữ. | |
| profiles.switch.error | Không mở được profile này. Vẫn dùng “%@”. | UC-32 E2 |
| profiles.delete.title | Xóa profile “%@”? | |
| profiles.delete.message | Sẽ xóa %lld deck, %lld từ và tiến độ học. Nên sao lưu trước. | UC-32 A2, bước 1 |
| profiles.delete.backupFirst | Sao lưu trước | |
| profiles.delete.final.title | Xóa vĩnh viễn? | Bước 2 |
| profiles.delete.final.message | Không hoàn tác được. | |
| profiles.delete.disabled.current | Không xóa được profile đang mở. | |
| profiles.delete.disabled.only | Cần ít nhất một profile. | |
| data.storage.profile | Dung lượng profile này: %@ | Màn dữ liệu, FR-091 |
| backup.profileName | Profile: %@ | Hiện khi chọn tệp khôi phục |
| a11y.profileBadge | Profile: %@. Chạm để chuyển. | |

## 14. Menu macOS (M1b)

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| menu.file.newFolder | Thư mục mới… | |
| menu.file.newDeck | Deck mới… | |
| menu.file.newWord | Từ mới… | ⌘N theo ngữ cảnh |
| menu.edit.undoGrade | Hoàn tác chấm điểm | P1 |
| menu.study | Học | Tên menu |
| menu.study.flip | Lật thẻ | |
| menu.study.exit | Thoát phiên học | |
| menu.help.shortcuts | Phím tắt | P1 |
| menu.app.switchProfile | Chuyển profile | M3; menu con liệt kê profile |

## 15. Trợ năng chung

| Key | Tiếng Việt | Ghi chú |
|---|---|---|
| a11y.stateDot | Trạng thái: %@ | `%@` = Mới / Đang học / Đã biết |
| a11y.progress | Tiến độ phiên: %lld trên %lld | |
| a11y.menu | Thêm hành động | Menu ⋯ |
| a11y.addFolder | Thêm thư mục | Nút icon `plus` |
| a11y.back | Quay lại | |
| a11y.dueBadge | %lld từ đến hạn | |

---

## 16. Kiểm tra và quy trình

- Mỗi chuỗi mới thêm vào bảng này **trước** khi vào String Catalog; không hard-code trong mã (ARCHITECTURE L8).
- Bản duyệt: kiểm tra đủ chuỗi cho mọi trạng thái (trống, lỗi, xác nhận) của từng UC P0 và độ dài nhãn ở Dynamic Type lớn nhất.
- Chuỗi kiểu ghi chú (§13a) thuộc M3; key `words.field.*` vẫn dùng cho kiểu hệ thống, tên trường của kiểu tùy biến là dữ liệu người dùng, không vào String Catalog.
- Chuỗi ngoài phạm vi M1a (dữ liệu, thống kê, onboarding, nhắc ôn, hoàn tác, thao tác hàng loạt) bổ sung ở mốc tương ứng.
