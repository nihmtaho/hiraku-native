package storage

import (
	"database/sql"
	"fmt"
	"sync"
	"testing"
	"time"
)

// Fixture logs end on 2026-10-30, so anything reviewed at or after this instant was written by the test.
var gradeEpoch = time.Date(2026, 10, 31, 12, 0, 0, 0, time.UTC).UnixMilli()

// Two "windows" grade the same cards at the same time; every grade must re-read state inside its transaction.
func gradeWindows(t *testing.T, windows []*sql.DB, cards, perWindow int) (failed int) {
	t.Helper()
	var mu sync.Mutex
	var wg sync.WaitGroup
	now := gradeEpoch
	for w, db := range windows {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < perWindow; i++ {
				card := idOf(i % cards)
				if err := gradeOnce(db, (w+1)*1000+i, card, now+int64(i)); err != nil {
					mu.Lock()
					failed++
					mu.Unlock()
					t.Logf("window %d grade %d: %v", w, i, err)
				}
			}
		}()
	}
	wg.Wait()
	return failed
}

// Each card's logs, ordered by reviewed_at, must chain prev_reps 0,1,2...: a stale read would repeat a value.
func assertNoStaleGrade(t *testing.T, db *sql.DB, cards, perWindow, windows int) {
	t.Helper()
	var integrity string
	if err := db.QueryRow("PRAGMA integrity_check").Scan(&integrity); err != nil || integrity != "ok" {
		t.Fatalf("integrity_check = %q, %v", integrity, err)
	}
	var logs int
	if err := db.QueryRow("SELECT COUNT(*) FROM review_logs WHERE reviewed_at >= ?", gradeEpoch).Scan(&logs); err != nil {
		t.Fatal(err)
	}
	if logs != windows*perWindow {
		t.Fatalf("review_logs written = %d, want %d: lost or duplicate writes", logs, windows*perWindow)
	}
	for c := 0; c < cards; c++ {
		rows, err := db.Query(`SELECT prev_reps FROM review_logs WHERE card_id = ? AND reviewed_at >= ? ORDER BY prev_reps`, idOf(c), gradeEpoch)
		if err != nil {
			t.Fatal(err)
		}
		var prev *int
		for rows.Next() {
			var reps int
			if err := rows.Scan(&reps); err != nil {
				t.Fatal(err)
			}
			if prev != nil && reps != *prev+1 {
				t.Fatalf("card %d: prev_reps %d follows %d, a grade used stale state", c, reps, *prev)
			}
			prev = &reps
		}
		rows.Close()
	}
}

func openWindow(t *testing.T, path, txlock string) *sql.DB {
	t.Helper()
	db, err := sql.Open("sqlite3", fmt.Sprintf("file:%s?_txlock=%s&_busy_timeout=5000&_journal_mode=WAL&_synchronous=FULL", path, txlock))
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { db.Close() })
	return db
}

// S-5 as designed (R-05): one core handle, one writer, shared by both windows.
func TestTwoWindowsShareOneHandle(t *testing.T) {
	requireSpike(t)
	db := openDB(t, copyFixture(t, "hiraku-s5-shared.sqlite"))
	defer db.Close()
	const cards, perWindow = 10, 200
	start := time.Now()
	if failed := gradeWindows(t, []*sql.DB{db, db}, cards, perWindow); failed != 0 {
		t.Fatalf("%d grades failed on a shared handle", failed)
	}
	t.Logf("2 windows x %d grades on %d shared cards: %v", perWindow, cards, time.Since(start))
	assertNoStaleGrade(t, db, cards, perWindow, 2)
}

// Two handles to one file (second window or an extension in another process); immediate lock is the safe setting.
func TestTwoHandlesImmediateLock(t *testing.T) {
	requireSpike(t)
	path := copyFixture(t, "hiraku-s5-immediate.sqlite")
	a, b := openWindow(t, path, "immediate"), openWindow(t, path, "immediate")
	const cards, perWindow = 10, 200
	start := time.Now()
	if failed := gradeWindows(t, []*sql.DB{a, b}, cards, perWindow); failed != 0 {
		t.Fatalf("%d grades failed with immediate lock", failed)
	}
	t.Logf("2 handles x %d grades on %d cards: %v", perWindow, cards, time.Since(start))
	assertNoStaleGrade(t, a, cards, perWindow, 2)
}

// Records what the default deferred lock does when two handles race: read then write can return SQLITE_BUSY.
func TestTwoHandlesDeferredLockBehavior(t *testing.T) {
	requireSpike(t)
	path := copyFixture(t, "hiraku-s5-deferred.sqlite")
	a, b := openWindow(t, path, "deferred"), openWindow(t, path, "deferred")
	const cards, perWindow = 10, 200
	failed := gradeWindows(t, []*sql.DB{a, b}, cards, perWindow)
	t.Logf("deferred lock, 2 handles: %d of %d grades failed", failed, 2*perWindow)
	var integrity string
	if err := a.QueryRow("PRAGMA integrity_check").Scan(&integrity); err != nil || integrity != "ok" {
		t.Fatalf("integrity_check = %q, %v", integrity, err)
	}
}
