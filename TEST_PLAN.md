# Kế hoạch kiểm thử — hiraku

## Trạng thái và nguyên tắc

Hiện ở M0, chưa có mã sản phẩm. Bộ OpenCode có kiểm tra riêng, không thay kiểm
thử ứng dụng. Thiết bị chuẩn theo Q-11 và người thử SC-002 chưa được xác nhận;
kết quả tương ứng phải ghi chưa xác minh, không tự thay bằng simulator.

Mỗi task ghi tiêu chí → test/lệnh → môi trường/toolchain → revision → kết quả
và artifact. Kết quả gồm đạt, không đạt, chưa chạy hoặc bị chặn; hai trạng thái
cuối không được tính đạt. Không lưu dữ liệu hoặc credentials thật trong fixtures.

## Bộ cấu hình OpenCode

Chạy `node --test .opencode/tests/*.test.mjs` tại root. Kiểm tra permissions,
đường dẫn/symlink, secret, multi-file edit, generated/policy, allowlist raw shell,
phân quyền agents và plugin API v2. Dùng OpenCode thực để kiểm discovery và
schema; scenario evals của từng skill kiểm cách xử lý task hợp lệ và đối kháng.

Các checks này không chứng minh tính đúng đắn của FSRS, Swift hoặc chất lượng
model trên mọi task.

## Ma trận sản phẩm theo milestone

| Phạm vi | Tự động | Bằng chứng khác |
|---|---|---|
| M0 S-0/S-8 | Build iOS arm64, iOS simulator arm64, macOS arm64; vòng lặp FFI/error/panic/lifetime | RSS, runtime startup, kiểm rò và chạy thiết bị thật theo tiêu chí spike |
| Core domain | Vector FSRS, bảng kana, ngày học, hàng đợi/limit, field role và validation | Quyết định Q nghiệp vụ phải chốt trước khi đóng băng expected output |
| Store/service | SQLite file tạm, migration, rollback, golden proto, concurrency/grade đúng một log | Kill/crash giữa ghi; không dùng DB của người dùng |
| Bridge | XCFramework thật, mapping/error/ChangeSet/EventHub, ownership handle | Xác minh reload theo phạm vi và không chặn main thread |
| Controller | Swift Testing, fake HirakuTesting và ManualClock; lỗi/hủy/start/stop | Không link core để chứng minh package độc lập |
| M1a | XCUITest UC P0 trên iPhone; offline; kill/relaunch; phím cứng theo phạm vi | IME thật, VoiceOver, Dynamic Type; SC-001 và SC-002 với người thử |
| M1b | iPad/Mac shell, hai cửa sổ/scene, chấm trùng thẻ và undo | Bàn phím phần cứng, focus, IME trên cả ba nền tảng |
| M2 | Nhập/backup v2→v3, restore lặp idempotent, dòng lỗi, cancel/rollback | Kiểm lại dữ liệu/tiến độ trước chia sẻ app cho người khác |
| M3/MR | Profile isolation, kiểu ghi chú, regression, build/Privacy/signing theo phạm vi | PO nghiệm thu; phần S-7 cần tài khoản trả phí; beta và checklist RELEASE |
| M4 | Sync mock/idempotency/merge sau khi Q-25 và contract được duyệt | Ba thiết bị thật, cloud/account/quota/offline; không áp dụng vào nghiệm thu M1 |

## Hiệu năng và truy cập

Dữ liệu tổng hợp: 50.000 từ và 200.000 log theo spike, schema notes/cards và
search_text hiện hành. Đo trên mỗi thiết bị tối thiểu đã chốt, ghi OS/build,
dataset và phương pháp đo.

Ngưỡng theo NFR-002: cuộn 60 fps, tìm kiếm <150 ms, dựng hàng đợi <200 ms,
khởi động nguội <1,5 s. Không suy ra các ngưỡng này từ unit test hoặc máy mạnh hơn.
Mọi RPC/chunk dài còn phải đối chiếu ADR-21 về p95.

Kiểm Dynamic Type lớn nhất/font_scale 140%, VoiceOver, Increase Contrast,
Reduce Motion, focus/bàn phím và phản hồi đúng/sai không chỉ dựa vào màu.
SC-002 yêu cầu ≥90% người thử hoàn tất không hướng dẫn; PO xác nhận nhóm người
thử và cách thu kết quả trước khi nghiệm thu, không thay bằng đánh giá của AI.

## Điều kiện đóng

Áp dụng SC theo milestone trong spec/ROADMAP; không yêu cầu M4 ở M1 hoặc bỏ
kiểm tra bắt buộc của M1 vì chưa có máy. CI bị thiếu, skip hoặc lỗi là blocker,
không phải đạt. Khi chưa bootstrap lệnh WP-01, ghi đúng tình trạng; không tạo
script trả exit 0 để giữ pipeline xanh.
