package fsrs

import (
	"encoding/json"
	"math"
	"os"
	"testing"
	"time"
)

type vectorFile struct {
	Settings struct {
		RequestRetention       float64   `json:"request_retention"`
		MaximumInterval        int       `json:"maximum_interval"`
		LearningStepsMinutes   []float64 `json:"learning_steps_minutes"`
		RelearningStepsMinutes []float64 `json:"relearning_steps_minutes"`
	} `json:"settings"`
	Vectors []struct {
		Name  string `json:"name"`
		Input struct {
			State          int     `json:"state"`
			Due            string  `json:"due"`
			Stability      float64 `json:"stability"`
			Difficulty     float64 `json:"difficulty"`
			Reps           int     `json:"reps"`
			Lapses         int     `json:"lapses"`
			RemainingSteps int     `json:"remaining_steps"`
			LastReview     *string `json:"last_review"`
		} `json:"input"`
		Now    string `json:"now"`
		Rating int    `json:"rating"`
		Want   struct {
			State      int     `json:"state"`
			Due        string  `json:"due"`
			Stability  float64 `json:"stability"`
			Difficulty float64 `json:"difficulty"`
			Reps       int     `json:"reps"`
			Lapses     int     `json:"lapses"`
		} `json:"want"`
	} `json:"vectors"`
}

func TestGoldenVectors(t *testing.T) {
	raw, err := os.ReadFile("../../spike/fsrs_vectors.json")
	if err != nil {
		t.Fatal(err)
	}
	var file vectorFile
	if err := json.Unmarshal(raw, &file); err != nil {
		t.Fatal(err)
	}
	settings := Settings{
		RequestRetention:       file.Settings.RequestRetention,
		MaximumIntervalDays:    file.Settings.MaximumInterval,
		LearningStepsMinutes:   file.Settings.LearningStepsMinutes,
		RelearningStepsMinutes: file.Settings.RelearningStepsMinutes,
		DayStartHour:           4,
	}
	if len(file.Vectors) != 17 {
		t.Fatalf("vectors = %d, want 17", len(file.Vectors))
	}
	for _, vector := range file.Vectors {
		t.Run(vector.Name, func(t *testing.T) {
			card := Card{
				State:          State(vector.Input.State),
				DueMs:          parseMs(t, vector.Input.Due),
				Stability:      vector.Input.Stability,
				Difficulty:     vector.Input.Difficulty,
				Reps:           vector.Input.Reps,
				Lapses:         vector.Input.Lapses,
				RemainingSteps: vector.Input.RemainingSteps,
			}
			if vector.Input.LastReview != nil {
				card.LastReviewMs = parseMs(t, *vector.Input.LastReview)
			}
			got := Next(card, Rating(vector.Rating), parseMs(t, vector.Now), settings)
			if int(got.State) != vector.Want.State {
				t.Errorf("state = %d, want %d", got.State, vector.Want.State)
			}
			if got.DueMs != parseMs(t, vector.Want.Due) {
				t.Errorf("due = %s, want %s", formatMs(got.DueMs), vector.Want.Due)
			}
			if math.Abs(got.Stability-vector.Want.Stability) > 1e-9*math.Max(1, vector.Want.Stability) {
				t.Errorf("stability = %.15f, want %.15f", got.Stability, vector.Want.Stability)
			}
			if math.Abs(got.Difficulty-vector.Want.Difficulty) > 1e-9 {
				t.Errorf("difficulty = %.15f, want %.15f", got.Difficulty, vector.Want.Difficulty)
			}
			if got.Reps != vector.Want.Reps || got.Lapses != vector.Want.Lapses {
				t.Errorf("reps/lapses = %d/%d, want %d/%d", got.Reps, got.Lapses, vector.Want.Reps, vector.Want.Lapses)
			}
		})
	}
}

func TestNewAgainDueInOneMinute(t *testing.T) {
	now := int64(1_000_000)
	got := Next(Card{}, RatingAgain, now, testSettings())
	if got.DueMs != now+60_000 || got.State != StateLearning {
		t.Fatalf("due = %d, state = %d", got.DueMs, got.State)
	}
}

func TestPreviewMatchesNext(t *testing.T) {
	card := Card{State: StateReview, Stability: 5, Difficulty: 5, RemainingSteps: 0, LastReviewMs: 1_000_000}
	now := int64(1_000_000 + 3*dayMs)
	preview := Preview(card, now, testSettings())
	for _, rating := range []Rating{RatingAgain, RatingHard, RatingGood, RatingEasy} {
		want := Next(card, rating, now, testSettings())
		if preview[rating] != want {
			t.Fatalf("rating %d preview %+v, want %+v", rating, preview[rating], want)
		}
	}
}

func TestStudyDayBoundary(t *testing.T) {
	base := time.Date(2026, 11, 1, 3, 55, 0, 0, time.UTC)
	after := time.Date(2026, 11, 1, 4, 5, 0, 0, time.UTC)
	if got := elapsedDays(base.UnixMilli(), after.UnixMilli(), 4); got != 1 {
		t.Fatalf("elapsed across 04:00 = %d, want 1", got)
	}
	late := time.Date(2026, 11, 1, 23, 55, 0, 0, time.UTC)
	early := time.Date(2026, 11, 2, 0, 5, 0, 0, time.UTC)
	if got := elapsedDays(late.UnixMilli(), early.UnixMilli(), 4); got != 0 {
		t.Fatalf("elapsed across midnight = %d, want 0", got)
	}
}

func testSettings() Settings {
	return Settings{
		RequestRetention:       0.9,
		MaximumIntervalDays:    36500,
		LearningStepsMinutes:   []float64{1, 10},
		RelearningStepsMinutes: []float64{10},
		DayStartHour:           4,
	}
}

func parseMs(t *testing.T, value string) int64 {
	t.Helper()
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		t.Fatal(err)
	}
	return parsed.UnixMilli()
}

func formatMs(ms int64) string {
	return time.UnixMilli(ms).UTC().Format(time.RFC3339)
}
