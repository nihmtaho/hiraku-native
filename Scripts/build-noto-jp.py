"""Build the bundled Noto Sans JP Regular subset (S-6).

Usage: uv run --with fonttools --with brotli Scripts/build-noto-jp.py <NotoSansJP[wght].ttf> <out.ttf>
Charset: ASCII, kana, CJK/fullwidth punctuation, and every JIS X 0208 kanji (covers JLPT N5-N1).
"""
import sys
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

src, out = sys.argv[1:3]

def jis0208():
    for row in range(0xA1, 0xF5):
        for col in range(0xA1, 0xFF):
            try:
                yield ord(bytes([row, col]).decode("euc_jp"))
            except UnicodeDecodeError:
                pass

ranges = [(0x20, 0x7E), (0x2010, 0x2027), (0x3000, 0x303F), (0x3040, 0x30FF), (0xFF00, 0xFFEF)]
chars = {c for lo, hi in ranges for c in range(lo, hi + 1)} | set(jis0208())

font = instancer.instantiateVariableFont(TTFont(src), {"wght": 400})
opts = subset.Options(layout_features=["kern", "vert", "vrt2", "palt", "ccmp"], notdef_outline=True,
                      name_IDs=[0, 1, 2, 3, 4, 5, 6, 13, 14], hinting=False)
sub = subset.Subsetter(opts)
sub.populate(unicodes=chars)
sub.subset(font)

# instancer keeps the default-instance (Thin) names; rewrite them so the PostScript name resolves
names = {1: "Noto Sans JP", 2: "Regular", 3: "NotoSansJP-Regular;subset", 4: "Noto Sans JP Regular", 6: "NotoSansJP-Regular"}
table = font["name"]
for nid in (16, 17, 21, 22, 25):
    table.removeNames(nameID=nid)
for nid, value in names.items():
    table.setName(value, nid, 3, 1, 0x409)
    table.setName(value, nid, 1, 0, 0)
font["OS/2"].usWeightClass = 400
font.save(out)
print(len(chars), "codepoints requested")
