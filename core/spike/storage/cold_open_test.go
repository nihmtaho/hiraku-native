package storage

import (
	"database/sql"
	"testing"
	"time"
)

func coldOpen(path, check string) (time.Duration, string, error) {
	start := time.Now()
	db, err := sql.Open("sqlite3", "file:"+path)
	if err != nil {
		return 0, "", err
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	if err := db.Ping(); err != nil {
		return 0, "", err
	}
	for _, pragma := range []string{
		"PRAGMA busy_timeout = 5000",
		"PRAGMA journal_mode = WAL",
		"PRAGMA synchronous = FULL",
	} {
		if _, err := db.Exec(pragma); err != nil {
			return 0, "", err
		}
	}
	result := ""
	if check != "" {
		if err := db.QueryRow("PRAGMA " + check).Scan(&result); err != nil {
			return 0, "", err
		}
	}
	var notes int
	if err := db.QueryRow("SELECT COUNT(*) FROM notes").Scan(&notes); err != nil {
		return 0, "", err
	}
	return time.Since(start), result, nil
}

func TestColdOpen(t *testing.T) {
	requireSpike(t)
	path := ensureFixture(t)

	for _, check := range []string{"", "quick_check", "integrity_check"} {
		label := map[string]string{"": "no check", "quick_check": "quick_check", "integrity_check": "integrity_check"}[check]
		var out samples
		result := ""
		for i := 0; i < 5; i++ {
			elapsed, got, err := coldOpen(path, check)
			if err != nil {
				t.Fatalf("%s run %d: %v", label, i, err)
			}
			result = got
			out = append(out, elapsed)
		}
		if check != "" {
			t.Logf("cold open %-16s result=%q", label, result)
		}
		out.report(t, "cold open "+label)
	}
}
