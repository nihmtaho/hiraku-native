package storage

import (
	"database/sql"
	"testing"
)

func searchSamples(t *testing.T, db *sql.DB) map[int]string {
	t.Helper()
	var term string
	if err := db.QueryRow(`SELECT sort_field FROM notes ORDER BY id LIMIT 1`).Scan(&term); err != nil {
		t.Fatal(err)
	}
	runes := []rune(term)
	if len(runes) < 4 {
		t.Fatalf("sample term too short: %q", term)
	}
	return map[int]string{
		1: string(runes[0]),
		2: string(runes[0:2]),
		3: string(runes[0:3]),
	}
}

func searchSubstring(k int, term string) string {
	runes := []rune(term)
	return string(runes[len(runes)-k:])
}

func TestSearch(t *testing.T) {
	requireSpike(t)
	path := ensureFixture(t)
	db := openDB(t, path)
	defer db.Close()

	samples := searchSamples(t, db)
	var term string
	if err := db.QueryRow(`SELECT sort_field FROM notes ORDER BY id LIMIT 1`).Scan(&term); err != nil {
		t.Fatal(err)
	}
	t.Logf("sample term=%q", term)

	var avgChars, avgBytes float64
	if err := db.QueryRow(`SELECT AVG(LENGTH(search_text)), AVG(LENGTH(CAST(search_text AS BLOB))) FROM notes`).Scan(&avgChars, &avgBytes); err != nil {
		t.Fatal(err)
	}
	t.Logf("avg search_text: %.1f chars, %.1f bytes", avgChars, avgBytes)

	for k := 1; k <= 3; k++ {
		prefix := samples[k]
		sub := searchSubstring(k, term)
		t.Logf("k=%d prefix=%q substring=%q", k, prefix, sub)

		for _, form := range []struct {
			name    string
			pattern string
		}{
			{"prefix", prefix + "%"},
			{"substring", "%" + sub + "%"},
		} {
			pattern := form.pattern
			query := `SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL AND search_text LIKE ?`
			explain(t, db, query, pattern)
			var matches int
			if err := db.QueryRow(query, pattern).Scan(&matches); err != nil {
				t.Fatal(err)
			}
			t.Logf("LIKE %s k=%d matches=%d", form.name, k, matches)
			out := percentile(t, "search", 20, func() error {
				var n int
				return db.QueryRow(query, pattern).Scan(&n)
			})
			out.report(t, "LIKE "+form.name+textSuffix(k))
		}
	}
}

func textSuffix(k int) string {
	return " " + string(rune('0'+k)) + "-char"
}
