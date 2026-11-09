package store_test

import (
	"context"
	"testing"

	"hiraku/core/domain/dayboundary"
	"hiraku/core/domain/fsrs"
	"hiraku/core/store"
)

func TestCardStateDefaultsAndUpsert(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)
	_, deckID := seedDeck(t, r)
	note, err := r.CreateNote(ctx, 100, deckID, map[string]string{"nf-term": "火", "nf-meaning": "lửa"})
	if err != nil {
		t.Fatal(err)
	}
	card, exists, err := r.CardState(ctx, note.ID)
	if err != nil || exists || card.State != fsrs.StateNew {
		t.Fatalf("initial = %+v %v %v", card, exists, err)
	}
	next := fsrs.Card{State: fsrs.StateLearning, DueMs: 5000, Stability: 1, Difficulty: 5, RemainingSteps: 1, Reps: 1, LastReviewMs: 1000}
	if err := r.SaveCardState(ctx, 1000, note.ID, next); err != nil {
		t.Fatal(err)
	}
	loaded, exists, err := r.CardState(ctx, note.ID)
	if err != nil || !exists || loaded.Stability != 1 || loaded.RemainingSteps != 1 || loaded.LastReviewMs != 1000 {
		t.Fatalf("loaded = %+v %v %v", loaded, exists, err)
	}
}

func TestQueueOrderAndLimits(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)
	_, deckID := seedDeck(t, r)
	first, _ := r.CreateNote(ctx, 200, deckID, map[string]string{"nf-term": "一", "nf-meaning": "một"})
	second, _ := r.CreateNote(ctx, 300, deckID, map[string]string{"nf-term": "二", "nf-meaning": "hai"})

	due, err := r.DueCards(ctx, 10_000, 10)
	if err != nil || len(due) != 0 {
		t.Fatalf("due = %+v %v", due, err)
	}
	fresh, err := r.NewCards(ctx, 1)
	if err != nil || len(fresh) != 1 || fresh[0].NoteID != first.ID {
		t.Fatalf("new = %+v %v", fresh, err)
	}

	if err := r.SaveCardState(ctx, 400, first.ID, fsrs.Card{State: fsrs.StateReview, DueMs: 5000, Stability: 1, Difficulty: 5}); err != nil {
		t.Fatal(err)
	}
	if err := r.SaveCardState(ctx, 400, second.ID, fsrs.Card{State: fsrs.StateLearning, DueMs: 6000, Stability: 1, Difficulty: 5}); err != nil {
		t.Fatal(err)
	}
	due, err = r.DueCards(ctx, 10_000, 10)
	if err != nil || len(due) != 2 || due[0].CardID != second.ID {
		t.Fatalf("due order = %+v %v", due, err)
	}
	if err := r.InsertReviewLog(ctx, storeLog(first.ID, 0, 5000)); err != nil {
		t.Fatal(err)
	}
	if count, err := r.NewGradedCount(ctx, 4000); err != nil || count != 1 {
		t.Fatalf("count = %d %v", count, err)
	}
}

func storeLog(cardID string, prev fsrs.State, at int64) store.ReviewLog {
	return store.ReviewLog{CardID: cardID, Rating: 3, ReviewedAtMs: at, Mode: "flashcard", Prev: fsrs.Card{State: prev}}
}

func TestDueQueueExcludesSuspendedAndStopsAtDayEnd(t *testing.T) {
	ctx := context.Background()
	s, r := openRepo(t)
	_, deckID := seedDeck(t, r)
	note, _ := r.CreateNote(ctx, 500, deckID, map[string]string{"nf-term": "水", "nf-meaning": "nước"})
	now := int64(10_000_000_000)
	end := dayboundary.End(now, 4)
	if err := r.SaveCardState(ctx, now, note.ID, fsrs.Card{State: fsrs.StateReview, DueMs: end - 1, Stability: 1, Difficulty: 5}); err != nil {
		t.Fatal(err)
	}
	due, _ := r.DueCards(ctx, end, 10)
	if len(due) != 1 {
		t.Fatalf("due = %+v", due)
	}
	if _, err := s.DB().Exec(`UPDATE card_states SET suspended = 1`); err != nil {
		t.Fatal(err)
	}
	if due, _ := r.DueCards(ctx, end, 10); len(due) != 0 {
		t.Fatalf("suspended leaked = %+v", due)
	}
	if _, err := s.DB().Exec(`UPDATE card_states SET suspended = 0, due = ?`, end+1); err != nil {
		t.Fatal(err)
	}
	if due, _ := r.DueCards(ctx, end, 10); len(due) != 0 {
		t.Fatalf("due after end leaked = %+v", due)
	}
}
