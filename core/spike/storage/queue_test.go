package storage

import (
	"database/sql"
	"testing"
	"time"
)

const queueQuery = `
WITH due AS (
  SELECT c.id AS card_id, cs.state AS state, cs.due AS sort_at
  FROM card_states cs
  JOIN cards c ON c.id = cs.card_id
  JOIN notes n ON n.id = c.note_id
  WHERE cs.suspended = 0
    AND cs.due <= ?
    AND cs.deleted_at IS NULL
    AND c.deleted_at IS NULL
    AND n.deleted_at IS NULL
  ORDER BY CASE WHEN cs.state IN (1, 3) THEN 0 ELSE 1 END, cs.due
  LIMIT ?
), fresh AS (
  SELECT c.id AS card_id, 0 AS state, n.created_at AS sort_at
  FROM cards c
  JOIN notes n ON n.id = c.note_id
  WHERE c.deleted_at IS NULL
    AND n.deleted_at IS NULL
    AND NOT EXISTS (SELECT 1 FROM card_states cs WHERE cs.card_id = c.id AND cs.deleted_at IS NULL)
  ORDER BY n.created_at
  LIMIT ?
)
SELECT card_id, state, sort_at FROM due
UNION ALL
SELECT card_id, state, sort_at FROM fresh
`

const firstReviewsToday = `
SELECT COUNT(*) FROM review_logs
WHERE prev_state = 0 AND deleted_at IS NULL AND reviewed_at >= ? AND reviewed_at < ?
`

func studyDay(now, dayStartHour int64) (start, end int64) {
	const day = int64(24 * time.Hour / time.Millisecond)
	start = (now-dayStartHour*int64(time.Hour/time.Millisecond))/day*day + dayStartHour*int64(time.Hour/time.Millisecond)
	return start, start + day
}

func runQueue(tx *sql.Tx, cutoff int64, dueLimit, freshLimit int) (int, error) {
	rows, err := tx.Query(queueQuery, cutoff, dueLimit, freshLimit)
	if err != nil {
		return 0, err
	}
	defer rows.Close()
	n := 0
	for rows.Next() {
		var cardID string
		var state int
		var sortAt int64
		if err := rows.Scan(&cardID, &state, &sortAt); err != nil {
			return 0, err
		}
		n++
	}
	return n, rows.Err()
}

func TestQueueBuild(t *testing.T) {
	requireSpike(t)
	path := ensureFixture(t)
	db := openDB(t, path)
	defer db.Close()

	base := time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC).UnixMilli()
	start, end := studyDay(base, 4)
	cutoff := end

	var firstReviews int
	if err := db.QueryRow(firstReviewsToday, start, end).Scan(&firstReviews); err != nil {
		t.Fatal(err)
	}
	allowed := 20 - firstReviews
	if allowed < 0 {
		allowed = 0
	}
	t.Logf("study day start=%d end=%d first reviews today=%d new allowed=%d", start, end, firstReviews, allowed)

	var duePopulation int
	if err := db.QueryRow(`SELECT COUNT(*) FROM card_states cs
		JOIN cards c ON c.id = cs.card_id
		JOIN notes n ON n.id = c.note_id
		WHERE cs.suspended = 0 AND cs.due <= ? AND cs.deleted_at IS NULL
		  AND c.deleted_at IS NULL AND n.deleted_at IS NULL`, cutoff).Scan(&duePopulation); err != nil {
		t.Fatal(err)
	}
	t.Logf("due population on fixture (no new-card modelling) = %d", duePopulation)

	firstOut := percentile(t, "first reviews today", 20, func() error {
		var n int
		return db.QueryRow(firstReviewsToday, start, end).Scan(&n)
	})
	firstOut.report(t, "first reviews today (new-card budget)")

	explain(t, db, queueQuery, cutoff, 1000, allowed)

	// Remove one state row in twenty so the new-card branch has a realistic population to scan.
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	res, err := tx.Exec(`DELETE FROM card_states WHERE card_id IN (SELECT id FROM cards WHERE rowid % 20 = 0)`)
	if err != nil {
		t.Fatal(err)
	}
	deleted, _ := res.RowsAffected()
	t.Logf("queue mix: removed %d card_states to model new cards; due limit=1000, new limit=%d", deleted, allowed)

	if n, err := runQueue(tx, cutoff, 1000, allowed); err != nil {
		t.Fatal(err)
	} else {
		t.Logf("queue rows (due limit 1000): %d", n)
	}
	if n, err := runQueue(tx, cutoff, -1, allowed); err != nil {
		t.Fatal(err)
	} else {
		t.Logf("queue rows (uncapped due): %d", n)
	}

	out := percentile(t, "queue build", 20, func() error {
		_, err := runQueue(tx, cutoff, 1000, allowed)
		return err
	})
	out.report(t, "queue build capped 1000 (spec §7.3 rules 1-3)")

	uncapped := percentile(t, "queue build uncapped", 20, func() error {
		_, err := runQueue(tx, cutoff, -1, allowed)
		return err
	})
	uncapped.report(t, "queue build uncapped (spec §7.3 rules 1-3)")
}
