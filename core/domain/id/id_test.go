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
}
