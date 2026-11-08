package store_test

import (
	"path/filepath"
	"testing"

	"hiraku/core/store"
)

func TestOpenAppliesMigrationsOnce(t *testing.T) {
	path := filepath.Join(t.TempDir(), "hiraku.sqlite")

	first, err := store.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := userVersion(t, first); got != 1 {
		t.Fatalf("user_version = %d, want 1", got)
	}
	first.Close()

	second, err := store.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	defer second.Close()
	if got := userVersion(t, second); got != 1 {
		t.Fatalf("user_version after reopen = %d, want 1", got)
	}

	var name string
	if err := second.DB().QueryRow("SELECT name FROM note_types WHERE id = 'nt-system-ja'").Scan(&name); err != nil {
		t.Fatal(err)
	}
	if name != "Từ vựng Nhật" {
		t.Fatalf("system note type name = %q", name)
	}
}

func userVersion(t *testing.T, s *store.Store) int {
	t.Helper()
	var v int
	if err := s.DB().QueryRow("PRAGMA user_version").Scan(&v); err != nil {
		t.Fatal(err)
	}
	return v
}
