package kana

import (
	"encoding/json"
	"os"
	"slices"
	"testing"
)

type golden struct {
	Same      [][2]string `json:"same"`
	Different [][2]string `json:"different"`
}

func loadGolden(t *testing.T) golden {
	t.Helper()
	data, err := os.ReadFile("../../testdata/kana_golden.json")
	if err != nil {
		t.Fatal(err)
	}
	var g golden
	if err := json.Unmarshal(data, &g); err != nil {
		t.Fatal(err)
	}
	return g
}

func TestGoldenPairsMatch(t *testing.T) {
	for _, pair := range loadGolden(t).Same {
		got, want := Normalize(pair[0]), Normalize(pair[1])
		if got != want {
			t.Errorf("Normalize(%q) = %q, Normalize(%q) = %q", pair[0], got, pair[1], want)
		}
	}
}

func TestGoldenPairsDiffer(t *testing.T) {
	for _, pair := range loadGolden(t).Different {
		if Normalize(pair[0]) == Normalize(pair[1]) {
			t.Errorf("Normalize(%q) == Normalize(%q) = %q", pair[0], pair[1], Normalize(pair[0]))
		}
	}
}

func TestRomajiConversion(t *testing.T) {
	cases := map[string]string{
		"kan":         "かん",
		"kann":        "かん",
		"kon'nichiwa": "こんにちわ",
		"kya":         "きゃ",
		"xtu":         "っ",
		"ltsu":        "っ",
		"shashin":     "しゃしん",
		"tcha":        "っちゃ",
		"vu":          "ゔ",
	}
	for in, want := range cases {
		if got := Normalize(in); got != want {
			t.Errorf("Normalize(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestMatchFlagsEachAnswerCharacter(t *testing.T) {
	got := Match("たべる", "たべら")
	want := []bool{true, true, false}
	if len(got) != len(want) {
		t.Fatalf("len(Match) = %d, want %d", len(got), len(want))
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("Match(%q) = %v, want %v", "たべる", got, want)
		}
	}
}

func TestMatchRomajiAndKatakana(t *testing.T) {
	if got := Match("カタカナ", "katakana"); !slices.Equal(got, []bool{true, true, true, true}) {
		t.Fatalf("Match(カタカナ, katakana) = %v", got)
	}
}

func TestMatchKeepsLaterCharactersAfterAMismatch(t *testing.T) {
	cases := []struct {
		answer string
		input  string
		want   []bool
	}{
		{"しんぶん", "しんふん", []bool{true, true, false, true}},
		{"たべる", "たへる", []bool{true, false, true}},
		{"かたかな", "かたがな", []bool{true, true, false, true}},
	}
	for _, c := range cases {
		if got := Match(c.answer, c.input); !slices.Equal(got, c.want) {
			t.Errorf("Match(%q, %q) = %v, want %v", c.answer, c.input, got, c.want)
		}
	}
}

func TestMatchKeepsToleratedCharactersTrue(t *testing.T) {
	got := Match("がっこう", "がっこ")
	if len(got) != 4 {
		t.Fatalf("len(Match) = %d, want 4", len(got))
	}
	for i, ok := range got {
		if !ok {
			t.Fatalf("Match(がっこう, がっこ)[%d] = false", i)
		}
	}
}

func TestMatchEmptyInputMarksEveryCharacter(t *testing.T) {
	got := Match("か", "")
	if len(got) != 1 || got[0] {
		t.Fatalf("Match(か, empty) = %v", got)
	}
}
