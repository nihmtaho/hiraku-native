package storage

import (
	"database/sql"
	"testing"
	"time"
)

type cardRow struct {
	state      int
	due        int64
	stability  float64
	difficulty float64
	steps      int
	reps       int
	lapses     int
	lastReview sql.NullInt64
}

func gradeOnce(db *sql.DB, seq int, cardID string, now int64) error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var prev cardRow
	if err := tx.QueryRow(`SELECT state, due, stability, difficulty, learning_steps, reps, lapses, last_review
		FROM card_states WHERE card_id = ?`, cardID).Scan(
		&prev.state, &prev.due, &prev.stability, &prev.difficulty, &prev.steps,
		&prev.reps, &prev.lapses, &prev.lastReview); err != nil {
		return err
	}
	const rating = 3
	nextState := 2
	nextDue := now + int64(3*24*time.Hour/time.Millisecond)
	nextStability := prev.stability * 1.2
	if prev.state != 2 {
		nextStability = 2.5
	}
	if _, err := tx.Exec(`UPDATE card_states
		SET state = ?, due = ?, stability = ?, difficulty = ?, elapsed_days = ?, scheduled_days = 3,
		    reps = reps + 1, last_review = ?, updated_at = ?
		WHERE card_id = ?`,
		nextState, nextDue, nextStability, prev.difficulty, 3, now, now, cardID); err != nil {
		return err
	}
	if _, err := tx.Exec(`INSERT INTO review_logs
		(id, card_id, rating, reviewed_at, mode, elapsed_ms,
		 prev_state, prev_due, prev_stability, prev_difficulty, prev_learning_steps, prev_reps, prev_lapses, prev_last_review,
		 created_at, updated_at)
		VALUES (?, ?, ?, ?, 'flashcard', 2500, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		idOf(900000+seq), cardID, rating, now, prev.state, prev.due,
		prev.stability, prev.difficulty, prev.steps, prev.reps, prev.lapses, prev.lastReview, now, now); err != nil {
		return err
	}
	return tx.Commit()
}

func TestGradeTx(t *testing.T) {
	requireSpike(t)
	path := copyFixture(t, "hiraku-s1-grade.sqlite")
	db := openDB(t, path)
	defer db.Close()

	pragma := func(name string) string {
		var value string
		if err := db.QueryRow("PRAGMA " + name).Scan(&value); err != nil {
			t.Fatal(err)
		}
		return value
	}
	t.Logf("journal_mode=%s synchronous=%s busy_timeout=%s", pragma("journal_mode"), pragma("synchronous"), pragma("busy_timeout"))

	ids := make([]string, 0, 100)
	for i := 0; i < 100; i++ {
		ids = append(ids, idOf(i))
	}
	var before int
	if err := db.QueryRow("SELECT COUNT(*) FROM review_logs").Scan(&before); err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC).UnixMilli()
	out := make(samples, 0, len(ids))
	for seq, cardID := range ids {
		start := time.Now()
		if err := gradeOnce(db, seq, cardID, now); err != nil {
			t.Fatalf("grade %s: %v", cardID, err)
		}
		out = append(out, time.Since(start))
		now += 1000
	}
	out.report(t, "grade transaction (read+update+insert+commit)")

	var after int
	if err := db.QueryRow("SELECT COUNT(*) FROM review_logs").Scan(&after); err != nil {
		t.Fatal(err)
	}
	if after-before != len(ids) {
		t.Fatalf("review_logs grew by %d, want %d: lost writes", after-before, len(ids))
	}
	var graded int
	for _, cardID := range ids {
		var state int
		if err := db.QueryRow(`SELECT state FROM card_states WHERE card_id = ?`, cardID).Scan(&state); err != nil {
			t.Fatal(err)
		}
		if state == 2 {
			graded++
		}
	}
	t.Logf("verified: review_logs %d -> %d; graded card_states state=2: %d/%d", before, after, graded, len(ids))
}
