//go:build sqlite_fts5

package storage

import (
	"testing"
	"time"
)

func TestSearchFTS5(t *testing.T) {
	requireSpike(t)
	dst := copyFixture(t, "hiraku-s1-fts.sqlite")

	db := openDB(t, dst)
	defer db.Close()

	var version string
	if err := db.QueryRow("SELECT sqlite_version()").Scan(&version); err != nil {
		t.Fatal(err)
	}
	t.Logf("sqlite_version=%s", version)

	before, _, _ := fileSizes(t, dst)
	start := time.Now()
	if _, err := db.Exec(`CREATE VIRTUAL TABLE notes_fts USING fts5(
		search_text,
		content='notes',
		content_rowid='rowid',
		tokenize='trigram'
	)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO notes_fts (rowid, search_text) SELECT rowid, search_text FROM notes`); err != nil {
		t.Fatal(err)
	}
	build := time.Since(start)
	if _, err := db.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatal(err)
	}
	indexed, _, _ := fileSizes(t, dst)
	if _, err := db.Exec("VACUUM"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatal(err)
	}
	after, _, _ := fileSizes(t, dst)
	t.Logf("fts5 build=%s size before=%d with index=%d after vacuum=%d (index cost=%d)", build, before, indexed, after, indexed-before)

	var term string
	if err := db.QueryRow(`SELECT sort_field FROM notes ORDER BY id LIMIT 1`).Scan(&term); err != nil {
		t.Fatal(err)
	}
	runes := []rune(term)
	prefix := string(runes[0:3])
	sub := string(runes[len(runes)-3:])
	t.Logf("sample term=%q prefix=%q substring=%q", term, prefix, sub)

	for _, form := range []struct {
		name  string
		query string
	}{
		{"prefix", `"` + prefix + `"*`},
		{"substring", `"` + sub + `"`},
	} {
		q := form.query
		const ftsCount = `SELECT COUNT(*) FROM notes_fts JOIN notes n ON n.rowid = notes_fts.rowid WHERE notes_fts MATCH ? AND n.deleted_at IS NULL`
		explain(t, db, ftsCount, q)
		var matches int
		if err := db.QueryRow(ftsCount, q).Scan(&matches); err != nil {
			t.Fatal(err)
		}
		t.Logf("FTS5 %s k=3 matches=%d", form.name, matches)
		out := percentile(t, "search", 20, func() error {
			var n int
			return db.QueryRow(ftsCount, q).Scan(&n)
		})
		out.report(t, "FTS5 "+form.name+" 3-char")
	}

	for k := 1; k <= 2; k++ {
		q := `"` + string(runes[:k]) + `"`
		var matches int
		err := db.QueryRow(`SELECT COUNT(*) FROM notes_fts JOIN notes n ON n.rowid = notes_fts.rowid WHERE notes_fts MATCH ? AND n.deleted_at IS NULL`, q).Scan(&matches)
		t.Logf("FTS5 trigram k=%d query=%s matches=%d err=%v", k, q, matches, err)
	}
}
