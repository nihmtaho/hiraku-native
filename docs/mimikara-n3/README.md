# Mimikara Oboeru N3 – Từ vựng (JSON)

Nguồn: https://www.vnjpclub.com/mimikara-n3-tu-vung-full/ (bản dịch tiếng Việt của VNJPCLUB).
Tổng cộng 880 từ (số 1–880), chia thành 15 bài / 66 trang.

## Cấu trúc thư mục

```
mimikara-n3/
├── index.json      # Mục lục: bài, tiêu đề, khoảng số thứ tự, danh sách file con
├── all.json        # Toàn bộ 880 từ trong một mảng (mỗi từ có thêm "unit", "cd")
└── units/
    ├── u01_cd02.json … u12_cd62.json   # Mỗi file = 1 trang (1 track CD) trên web
    ├── u06.json, u11.json               # Bài Katakana (không có CD)
    └── u2A.json, u3A.json, u11A.json    # Phần tổng hợp (không có CD)
```

## Các bài

| Bài | Nội dung | Số thứ tự |
|---|---|---|
| 01 | Danh từ A | 1–120 |
| 02 | Động từ A | 121–220 |
| 2A | Tổng hợp – Danh từ gốc động từ | 221–258 |
| 03 | Tính từ A | 259–298 |
| 3A | Tổng hợp – Tính từ い + ～まる/～める | 299–310 |
| 04 | Danh từ B | 311–410 |
| 05 | Động từ B | 411–510 |
| 06 | Katakana A | 511–550 |
| 07 | Tính từ B | 551–590 |
| 08 | Phó từ A | 591–635 |
| 09 | Danh từ C | 636–715 |
| 10 | Động từ C | 716–795 |
| 11 | Katakana B | 796–835 |
| 11A | Tổng hợp – Động từ nấu ăn | 836–845 |
| 12 | Phó từ B, liên thể từ, liên từ | 846–880 |

## Cấu trúc một từ

```json
{
  "no": 637,
  "word": "演奏",                 // chữ viết, đã bỏ furigana
  "reading": "えんそう",           // cách đọc (kana)
  "word_raw": "演奏（えんそう）",   // nguyên văn trên web
  "ruby": [{"t": "演奏", "r": "えんそう"}],  // t = chữ, r = furigana (nếu có)
  "han_viet": "diễn tấu",          // null nếu từ không có kanji
  "meaning_vi": "biểu diễn",
  "examples": [
    {"no": 1, "jp": "楽器を演奏する", "jp_raw": "楽器（がっき）を演奏（えんそう）する",
     "jp_ruby": [...], "vi": "Biểu diễn nhạc cụ."}
  ],
  "related": [
    {"type": "compound", "marker": "合", "raw": "＿者（しゃ）、　＿会（かい）",
     "items": [{"text": "＿者", "ruby": [...], "pattern": true}, ...],
     "meaning_vi": "Người biểu diễn, hội biểu diễn"}
  ]
}
```

Ký hiệu `related.type`:
関 related · 合 compound (từ ghép) · 対 antonym (trái nghĩa) · 類 synonym (đồng nghĩa) ·
連 collocation (kết hợp từ) · 慣 idiom (thành ngữ) · 名 noun_form · 動 verb_form ·
副 adverb_form · 形 adjective_form · 派 derived · 自 intransitive · 他 transitive.
`"pattern": true` nghĩa là mục có dấu ＿ hoặc ＋ (chỗ trống để ghép với từ chính).

## Lưu ý

- `items` được tách theo dấu "、". Những mục nguyên văn có dạng "A  B" (hai khoảng trắng, trên web là ⇔) vẫn giữ nguyên trong một item; xem thêm `raw`.
- Từ số 585: trên web có thêm một dòng "<=> bị cấm", dòng này được nối vào `meaning_vi` của mục ghi chú cuối.
- Từ số 555: một mục 合 chứa cả câu ví dụ, được giữ nguyên như trên web.
- Furigana chỉ được nhận khi dấu （…） đứng ngay sau kanji; ngoặc khác được giữ là văn bản thường.
