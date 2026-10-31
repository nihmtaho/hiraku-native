package storage

import (
	"database/sql"
	"testing"
	"time"
)

func runChangeSet(db *sql.DB, revision int64) (notes, logs int, err error) {
	noteRows, err := db.Query(`SELECT id FROM notes WHERE updated_at > ? ORDER BY updated_at`, revision)
	if err != nil {
		return 0, 0, err
	}
	for noteRows.Next() {
		var id string
		if err := noteRows.Scan(&id); err != nil {
			noteRows.Close()
			return 0, 0, err
		}
		notes++
	}
	if err := noteRows.Err(); err != nil {
		noteRows.Close()
		return 0, 0, err
	}
	noteRows.Close()

	logRows, err := db.Query(`SELECT id FROM review_logs WHERE reviewed_at > ? ORDER BY reviewed_at`, revision)
	if err != nil {
		return 0, 0, err
	}
	defer logRows.Close()
	for logRows.Next() {
		var id string
		if err := logRows.Scan(&id); err != nil {
			return 0, 0, err
		}
		logs++
	}
	return notes, logs, logRows.Err()
}

func TestChangeSetQuery(t *testing.T) {
	requireSpike(t)
	path := ensureFixture(t)
	db := openDB(t, path)
	defer db.Close()

	base := time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC).UnixMilli()
	noteQuery := `SELECT id FROM notes WHERE updated_at > ? ORDER BY updated_at`
	logQuery := `SELECT id FROM review_logs WHERE reviewed_at > ? ORDER BY reviewed_at`
	explain(t, db, noteQuery, base-7*24*3600*1000)
	explain(t, db, logQuery, base-7*24*3600*1000)

	for _, window := range []struct {
		name     string
		revision int64
	}{
		{"1h", base - int64(time.Hour/time.Millisecond)},
		{"7d", base - int64(7*24*time.Hour/time.Millisecond)},
	} {
		notes, logs, err := runChangeSet(db, window.revision)
		if err != nil {
			t.Fatal(err)
		}
		t.Logf("changeset %s: notes=%d review_logs=%d", window.name, notes, logs)
		out := percentile(t, "changeset", 20, func() error {
			_, _, err := runChangeSet(db, window.revision)
			return err
		})
		out.report(t, "ChangeSet reload "+window.name)
	}
}
