package store

import (
	"context"
	"database/sql"
	"errors"

	"hiraku/core/domain/fsrs"
	"hiraku/core/domain/id"
)

// ReviewLog is the snapshot written with every grade.
type ReviewLog struct {
	CardID       string
	Rating       int
	ReviewedAtMs int64
	Mode         string
	ElapsedMs    int64
	Prev         fsrs.Card
}

// CardState reads the scheduling state; missing rows mean a new card.
func (r *Repo) CardState(ctx context.Context, cardID string) (fsrs.Card, bool, error) {
	var card fsrs.Card
	var lastReview sql.NullInt64
	err := r.q.QueryRowContext(ctx, `
		SELECT state, due, stability, difficulty, elapsed_days, scheduled_days,
		       learning_steps, reps, lapses, last_review, suspended
		FROM card_states WHERE card_id = ?`, cardID).Scan(
		&card.State, &card.DueMs, &card.Stability, &card.Difficulty,
		new(int), new(int), &card.RemainingSteps, &card.Reps, &card.Lapses,
		&lastReview, new(int))
	if errors.Is(err, sql.ErrNoRows) {
		return fsrs.Card{State: fsrs.StateNew}, false, nil
	}
	if err != nil {
		return fsrs.Card{}, false, err
	}
	if lastReview.Valid {
		card.LastReviewMs = lastReview.Int64
	}
	return card, true, nil
}

// SaveCardState inserts or replaces the scheduling state of a card.
func (r *Repo) SaveCardState(ctx context.Context, nowMs int64, cardID string, card fsrs.Card) error {
	var lastReview any
	if card.LastReviewMs != 0 {
		lastReview = card.LastReviewMs
	}
	_, err := r.q.ExecContext(ctx, `
		INSERT INTO card_states
		  (card_id, state, due, stability, difficulty, elapsed_days, scheduled_days,
		   learning_steps, reps, lapses, last_review, suspended, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, 0, ?, ?)
		ON CONFLICT(card_id) DO UPDATE SET
		  state = excluded.state, due = excluded.due, stability = excluded.stability,
		  difficulty = excluded.difficulty, learning_steps = excluded.learning_steps,
		  reps = excluded.reps, lapses = excluded.lapses,
		  last_review = excluded.last_review, updated_at = excluded.updated_at`,
		cardID, card.State, card.DueMs, card.Stability, card.Difficulty,
		card.RemainingSteps, card.Reps, card.Lapses, lastReview, nowMs, nowMs)
	return err
}

// InsertReviewLog writes one immutable review log.
func (r *Repo) InsertReviewLog(ctx context.Context, log ReviewLog) error {
	newID, err := id.New(log.ReviewedAtMs)
	if err != nil {
		return err
	}
	var lastReview any
	if log.Prev.LastReviewMs != 0 {
		lastReview = log.Prev.LastReviewMs
	}
	_, err = r.q.ExecContext(ctx, `
		INSERT INTO review_logs
		  (id, card_id, rating, reviewed_at, mode, elapsed_ms,
		   prev_state, prev_due, prev_stability, prev_difficulty,
		   prev_learning_steps, prev_reps, prev_lapses, prev_last_review, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		newID, log.CardID, log.Rating, log.ReviewedAtMs, log.Mode, log.ElapsedMs,
		log.Prev.State, log.Prev.DueMs, log.Prev.Stability, log.Prev.Difficulty,
		log.Prev.RemainingSteps, log.Prev.Reps, log.Prev.Lapses, lastReview,
		log.ReviewedAtMs)
	return err
}

// QueueCard is one entry of a built session queue.
type QueueCard struct {
	CardID string
	NoteID string
	DeckID string
	State  int
}

// DueCards lists unsuspended cards due before dueBefore, learning first.
func (r *Repo) DueCards(ctx context.Context, dueBefore int64, limit int) ([]QueueCard, error) {
	return r.queryQueue(ctx, `
		SELECT c.id, c.note_id, n.deck_id, s.state
		FROM cards c
		JOIN notes n ON n.id = c.note_id AND n.deleted_at IS NULL
		JOIN decks d ON d.id = n.deck_id AND d.deleted_at IS NULL
		JOIN card_states s ON s.card_id = c.id
		WHERE c.deleted_at IS NULL AND s.suspended = 0 AND s.due <= ?
		ORDER BY CASE s.state WHEN 1 THEN 0 WHEN 3 THEN 0 ELSE 1 END, s.due, c.id
		LIMIT ?`, dueBefore, limitArg(limit))
}

// NewCards lists cards without state, oldest note first.
func (r *Repo) NewCards(ctx context.Context, limit int) ([]QueueCard, error) {
	return r.queryQueue(ctx, `
		SELECT c.id, c.note_id, n.deck_id, 0
		FROM cards c
		JOIN notes n ON n.id = c.note_id AND n.deleted_at IS NULL
		JOIN decks d ON d.id = n.deck_id AND d.deleted_at IS NULL
		LEFT JOIN card_states s ON s.card_id = c.id
		WHERE c.deleted_at IS NULL AND s.card_id IS NULL
		ORDER BY n.created_at, c.id
		LIMIT ?`, limitArg(limit))
}

func (r *Repo) queryQueue(ctx context.Context, query string, args ...any) ([]QueueCard, error) {
	rows, err := r.q.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []QueueCard
	for rows.Next() {
		var item QueueCard
		if err := rows.Scan(&item.CardID, &item.NoteID, &item.DeckID, &item.State); err != nil {
			return nil, err
		}
		out = append(out, item)
	}
	return out, rows.Err()
}

// NewGradedCount counts first reviews since sinceMs.
func (r *Repo) NewGradedCount(ctx context.Context, sinceMs int64) (int, error) {
	var count int
	err := r.q.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM review_logs WHERE prev_state = 0 AND reviewed_at >= ?`,
		sinceMs).Scan(&count)
	return count, err
}

// CardExists reports whether a live card exists.
func (r *Repo) CardExists(ctx context.Context, cardID string) (bool, error) {
	var found int
	err := r.q.QueryRowContext(ctx, `
		SELECT 1 FROM cards WHERE id = ? AND deleted_at IS NULL`, cardID).Scan(&found)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

func limitArg(limit int) int {
	if limit <= 0 {
		return -1
	}
	return limit
}
