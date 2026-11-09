package service

import (
	"context"
	"fmt"
	"strconv"

	"hiraku/core/domain/dayboundary"
	"hiraku/core/domain/fsrs"
	"hiraku/core/store"

	hirakuv1 "hiraku/core/gen/hirakuv1"
)

const (
	defaultQueueLimit = 200
	maxQueueLimit     = 500
)

// Grade applies one review in a single transaction and returns the change set.
func (s *Service) grade(ctx context.Context, req *hirakuv1.GradeRequest) (*hirakuv1.GradeResponse, error) {
	if req.GetCardId() == "" || req.GetNowMs() <= 0 {
		return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
	}
	rating := fsrs.Rating(req.GetRating())
	if rating < fsrs.RatingAgain || rating > fsrs.RatingEasy {
		return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
	}
	mode := "flashcard"
	switch req.GetMode() {
	case hirakuv1.StudyMode_STUDY_MODE_FLASHCARD, hirakuv1.StudyMode_STUDY_MODE_UNSPECIFIED:
	case hirakuv1.StudyMode_STUDY_MODE_TYPING:
		mode = "typing"
	default:
		return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
	}
	elapsed := req.GetElapsedMs()
	if elapsed < 0 {
		elapsed = 0
	}
	if elapsed > 60_000 {
		elapsed = 60_000
	}
	settings, _, err := s.schedulingSettings(ctx)
	if err != nil {
		return nil, MapError(err)
	}

	var next fsrs.Card
	err = s.repo.Tx(ctx, func(r *store.Repo) error {
		exists, err := r.CardExists(ctx, req.GetCardId())
		if err != nil {
			return err
		}
		if !exists {
			return store.ErrNotFound
		}
		prev, _, err := r.CardState(ctx, req.GetCardId())
		if err != nil {
			return err
		}
		next = fsrs.Next(prev, rating, req.GetNowMs(), settings)
		if err := r.SaveCardState(ctx, req.GetNowMs(), req.GetCardId(), next); err != nil {
			return err
		}
		return r.InsertReviewLog(ctx, store.ReviewLog{
			CardID:       req.GetCardId(),
			Rating:       int(rating),
			ReviewedAtMs: req.GetNowMs(),
			Mode:         mode,
			ElapsedMs:    elapsed,
			Prev:         prev,
		})
	})
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.GradeResponse{
		NextDueMs: next.DueMs,
		Reinsert:  next.DueMs <= req.GetNowMs()+20*60_000,
		Changes: &hirakuv1.ChangeSet{Changes: []*hirakuv1.Change{{
			EntityId: req.GetCardId(),
			Kind:     hirakuv1.ChangeKind_CHANGE_KIND_UPSERT,
			Entity:   hirakuv1.EntityType_ENTITY_TYPE_CARD,
		}}},
	}, nil
}

// buildQueue lists due cards, then new cards within the daily limit.
func (s *Service) buildQueue(ctx context.Context, req *hirakuv1.BuildQueueRequest) (*hirakuv1.BuildQueueResponse, error) {
	if req.GetNowMs() <= 0 {
		return nil, &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
	}
	limit := int(req.GetLimit())
	if limit <= 0 {
		limit = defaultQueueLimit
	}
	if limit > maxQueueLimit {
		limit = maxQueueLimit
	}
	scope := store.Scope{FolderID: req.GetFolderId(), DeckID: req.GetDeckId()}
	settings, newPerDay, err := s.schedulingSettings(ctx)
	if err != nil {
		return nil, MapError(err)
	}
	dayStart := dayboundary.Start(req.GetNowMs(), settings.DayStartHour)
	graded, err := s.repo.NewGradedCount(ctx, dayStart)
	if err != nil {
		return nil, MapError(err)
	}
	allowed := newPerDay - graded
	if allowed < 0 {
		allowed = 0
	}

	due, err := s.repo.DueCards(ctx, dayboundary.End(req.GetNowMs(), settings.DayStartHour), limit, scope)
	if err != nil {
		return nil, MapError(err)
	}
	items := make([]*hirakuv1.QueueItem, 0, limit)
	for _, card := range due {
		items = append(items, queueItem(card))
	}
	remaining := limit - len(items)
	if allowed < remaining {
		remaining = allowed
	}
	if remaining > 0 {
		fresh, err := s.repo.NewCards(ctx, remaining, scope)
		if err != nil {
			return nil, MapError(err)
		}
		for _, card := range fresh {
			items = append(items, queueItem(card))
		}
	}
	return &hirakuv1.BuildQueueResponse{Items: items}, nil
}

func queueItem(card store.QueueCard) *hirakuv1.QueueItem {
	return &hirakuv1.QueueItem{
		CardId: card.CardID,
		NoteId: card.NoteID,
		DeckId: card.DeckID,
		State:  int32(card.State),
	}
}

func (s *Service) schedulingSettings(ctx context.Context) (fsrs.Settings, int, error) {
	retention, err := s.repo.Setting(ctx, "fsrs_retention")
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	maxInterval, err := s.repo.Setting(ctx, "fsrs_max_interval")
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	dayStart, err := s.repo.Setting(ctx, "day_start_hour")
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	newPerDay, err := s.repo.Setting(ctx, "new_cards_per_day")
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	parse := func(value string) (float64, error) {
		parsed, err := strconv.ParseFloat(value, 64)
		if err != nil {
			return 0, fmt.Errorf("stored setting %q: %w", value, err)
		}
		return parsed, nil
	}
	retentionValue, err := parse(retention)
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	intervalValue, err := parse(maxInterval)
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	dayStartValue, err := parse(dayStart)
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	newPerDayValue, err := parse(newPerDay)
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	shortTerm, err := s.repo.Setting(ctx, "fsrs_short_term")
	if err != nil {
		return fsrs.Settings{}, 0, err
	}
	settings := fsrs.Settings{
		RequestRetention:     retentionValue,
		MaximumIntervalDays:  int(intervalValue),
		LearningStepsMinutes: []float64{1, 10},
		DayStartHour:         int(dayStartValue),
	}
	if shortTerm == "true" {
		settings.RelearningStepsMinutes = []float64{10}
	} else {
		settings.LearningStepsMinutes = nil
	}
	return settings, int(newPerDayValue), nil
}
