// Package kana normalizes Japanese answers and reports per-character matches.
package kana

import "strings"

const longO = "おこそとのほもよろょ"
const longE = "えけせてねへめれ"

// Normalize returns the comparison form of s.
func Normalize(s string) string {
	runes, _ := normalize(s)
	return string(runes)
}

// Match reports one flag per answer character, false where input diverged.
// Answers are kana; a romaji answer is not a product case.
func Match(answer, input string) []bool {
	answerRunes, origin := normalize(answer)
	inputRunes, _ := normalize(input)
	matched := make([]bool, len([]rune(answer)))
	for i := range matched {
		matched[i] = true
	}
	for i, r := range answerRunes {
		if i < len(inputRunes) && r == inputRunes[i] {
			continue
		}
		matched[origin[i]] = false
	}
	return matched
}

// normalize returns runes with the index of the raw rune each one came from.
func normalize(s string) ([]rune, []int) {
	raw := []rune(strings.ToLower(strings.TrimSpace(s)))
	var runes []rune
	var origin []int
	for i := 0; i < len(raw); {
		kana, size := romajiAt(string(raw[i:]))
		if size == 0 {
			kana, size = string(toHiragana(raw[i])), 1
		}
		for _, r := range kana {
			runes = append(runes, r)
			origin = append(origin, i)
		}
		i += size
	}
	return fold(runes, origin)
}

func fold(runes []rune, origin []int) ([]rune, []int) {
	out := runes[:0]
	outOrigin := origin[:0]
	for i, r := range runes {
		if r == 'ー' || foldsInto(out, r) {
			continue
		}
		out = append(out, r)
		outOrigin = append(outOrigin, origin[i])
	}
	return out, outOrigin
}

// foldsInto drops a long vowel or a repeat that comparison tolerates.
func foldsInto(out []rune, r rune) bool {
	if len(out) == 0 {
		return false
	}
	prev := out[len(out)-1]
	if r == prev {
		return true
	}
	if strings.ContainsRune(longO, prev) {
		return r == 'う' || r == 'お'
	}
	if strings.ContainsRune(longE, prev) {
		return r == 'い' || r == 'え'
	}
	return false
}

func toHiragana(r rune) rune {
	if r >= 0x30A1 && r <= 0x30F6 {
		return r - 0x60
	}
	return r
}

// romajiAt converts the longest romaji syllable at the start of rest.
func romajiAt(rest string) (string, int) {
	if rest == "" || rest[0] < 'a' || rest[0] > 'z' {
		return "", 0
	}
	if rest[0] == 'n' {
		if len(rest) == 1 {
			return "ん", 1
		}
		// n before a consonant is ん; nn keeps one n for the next syllable.
		if rest[1] == 'n' || rest[1] == '\'' || !strings.ContainsRune("aiueoy", rune(rest[1])) {
			if rest[1] == '\'' {
				return "ん", 2
			}
			return "ん", 1
		}
	}
	for size := 4; size >= 1; size-- {
		if len(rest) < size {
			continue
		}
		if kana, ok := romaji[rest[:size]]; ok {
			return kana, size
		}
	}
	if strings.HasPrefix(rest, "tch") {
		return "っ", 1
	}
	if len(rest) > 1 && rest[1] == rest[0] && strings.ContainsRune("bcdfghjkmpqrstvwxyz", rune(rest[0])) {
		return "っ", 1
	}
	return "", 0
}

var romaji = map[string]string{
	"a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
	"ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
	"ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
	"sa": "さ", "si": "し", "shi": "し", "su": "す", "se": "せ", "so": "そ",
	"za": "ざ", "zi": "じ", "ji": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
	"ta": "た", "ti": "ち", "chi": "ち", "tu": "つ", "tsu": "つ", "te": "て", "to": "と",
	"da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
	"na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
	"ha": "は", "hi": "ひ", "hu": "ふ", "fu": "ふ", "he": "へ", "ho": "ほ",
	"ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
	"pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
	"ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
	"ya": "や", "yu": "ゆ", "yo": "よ",
	"ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
	"wa": "わ", "wo": "を", "vu": "ゔ",
	"kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
	"gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
	"sha": "しゃ", "shu": "しゅ", "sho": "しょ",
	"sya": "しゃ", "syu": "しゅ", "syo": "しょ",
	"ja": "じゃ", "ju": "じゅ", "jo": "じょ",
	"zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",
	"cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
	"tya": "ちゃ", "tyu": "ちゅ", "tyo": "ちょ",
	"nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
	"hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
	"bya": "びゃ", "byu": "びゅ", "byo": "びょ",
	"pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
	"mya": "みゃ", "myu": "みゅ", "myo": "みょ",
	"rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
	"xa": "ぁ", "xi": "ぃ", "xu": "ぅ", "xe": "ぇ", "xo": "ぉ",
	"la": "ぁ", "li": "ぃ", "lu": "ぅ", "le": "ぇ", "lo": "ぉ",
	"xya": "ゃ", "xyu": "ゅ", "xyo": "ょ",
	"lya": "ゃ", "lyu": "ゅ", "lyo": "ょ",
	"xtu": "っ", "ltu": "っ", "xtsu": "っ", "ltsu": "っ",
}
