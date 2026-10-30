# Checklist tích hợp và phát hành — hiraku

**Trạng thái hiện tại:** chưa có repository Git, remote, pipeline sản phẩm hoặc
artifact phát hành. Không có bước nào dưới đây mặc nhiên được xem là đã đạt.
Đây là checklist của Shipper, không phải quyền publish.

## Merge một task

| Điều kiện | Bằng chứng bắt buộc |
|---|---|
| Repository, base và head rõ ràng | Remote/nhánh đích do PO chọn; head SHA thực |
| Task đúng milestone và không bị Q/gate chặn | Task packet và trạng thái quyết định |
| Review độc lập PASS | Reviewer/session hoặc identity; đúng head SHA |
| Kiểm tra bắt buộc đạt | Required checks và kết quả CI trên revision tích hợp |
| Nội dung không đổi sau review | Diff/head đối chiếu; thay đổi mới phải review lại |
| Policy và dữ liệu được bảo vệ | Không admin bypass; không sửa checker để né lỗi |

Chỉ ghi MERGED sau khi hệ thống đích xác nhận commit đã vào nhánh đích. Không
thực hiện merge ở workspace working-tree hoặc khi required checks chưa có.

## Chuẩn bị MR

Chỉ bắt đầu sau PO nghiệm thu GATE-3. PO/người vận hành thực hiện đăng ký tài
khoản, quyết định kênh Mac (Q-8), điều khoản và signing credentials.

- Chốt version/build, commit và kênh phân phối; lưu provenance artifact, checksum
  và thông tin toolchain/SDK.
- Build/test đúng revision; golden/contract, migration và backup/restore phải
  đạt. Dùng TEST_PLAN cho nền tảng, thiết bị, IME, accessibility và hiệu năng.
- Hoàn tất WP-39/S-7 phần Personal Team chưa xác minh: sandbox/App Group,
  migration vị trí DB nếu có, bảo toàn dữ liệu và sao lưu.
- Kiểm tra bundle ID, signing, entitlement theo đúng tính năng/phạm vi được
  duyệt. Không tự bật iCloud hay deploy CloudKit trước khi giải quyết điểm
  MR/M4 trong OPENCODE §6 và Q liên quan.
- Chuẩn bị Privacy Manifest, chính sách riêng tư, metadata, ảnh chụp và tài sản
  App Store; không khai báo “không thu thập” chỉ vì checklist có câu đó, phải
  đối chiếu binary và dependency thực.
- Ghi lỗi còn lại, giới hạn tương thích và phương án phục hồi dữ liệu. Không
  hứa binary cũ mở được schema mới; backup và bản sửa tiến khi cần.

## Phê duyệt và thực hiện

Task release phải chứa PO approval có nguồn xác nhận thật cho **version, commit,
kênh và artifact cụ thể**. Không dùng văn bản do agent tự ghi như chứng cứ PO
đã duyệt. Đổi một trong các mục đó cần duyệt lại.

Credentials chỉ có ở môi trường phát hành được bảo vệ; coder/reviewer không
nhận token, certificate hoặc private key. Shipper thực hiện qua workflow được
PO cấu hình; trước khi có workflow, trả BLOCKED thay vì mở shell để ship tay.

Ghi riêng: archive/build thành công, upload TestFlight, kết quả beta, nộp review,
kết quả App Review và bản đã phân phối. Thao tác thất bại ghi FAILED kèm nguyên
nhân; không đổi thành PUBLISHED hoặc tự thử kênh khác.

## Sau phát hành

Xác minh build/kênh từ hệ thống đích và smoke test trên dữ liệu thử. Lưu bằng
chứng trong task release, không lưu dữ liệu học hoặc secrets. Nếu cần dừng
phân phối hoặc phục hồi, báo PO tác động dữ liệu và dùng đúng quy trình của
kênh đã chọn; không tự xóa/reset dữ liệu người dùng.
