package id

import (
	"strings"
	"testing"
)

func TestNewIsUUIDv7(t *testing.T) {
	first, err := New(1000)
	if err != nil {
		t.Fatal(err)
	}
	second, _ := New(1000)
	if len(first) != 36 || strings.Count(first, "-") != 4 {
		t.Fatalf("not a UUID: %q", first)
	}
	if first[14] != '7' || first == second {
		t.Fatalf("version or randomness wrong: %q %q", first, second)
	}
	compact := strings.ReplaceAll(first, "-", "")
	if compact[:12] != "0000000003e8" {
		t.Fatalf("timestamp bits = %q", compact[:12])
	}
	if !strings.ContainsRune("89ab", rune(compact[16])) {
		t.Fatalf("variant nibble = %c", compact[16])
	}
}
