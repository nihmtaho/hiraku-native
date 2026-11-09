// Package fsrs implements FSRS-6 with the reference arithmetic of py-fsrs 6.3.2.
// Time never comes from the clock: callers pass now_ms.
package fsrs

import (
	"math"

	"hiraku/core/domain/dayboundary"
)

// State is the scheduling state of a card.
type State int

const (
	StateNew State = iota
	StateLearning
	StateReview
	StateRelearning
)

// Rating is the grade a user gives a card.
type Rating int

const (
	RatingAgain Rating = 1
	RatingHard  Rating = 2
	RatingGood  Rating = 3
	RatingEasy  Rating = 4
)

// Card is the scheduling state of one card; zero values mean a new card.
type Card struct {
	State          State
	DueMs          int64
	Stability      float64
	Difficulty     float64
	Reps           int
	Lapses         int
	RemainingSteps int
	LastReviewMs   int64
	ElapsedDays    int
	ScheduledDays  int
}

// Settings holds the profile study settings that affect scheduling.
type Settings struct {
	RequestRetention       float64
	MaximumIntervalDays    int
	LearningStepsMinutes   []float64
	RelearningStepsMinutes []float64
	DayStartHour           int
}

const stabilityMin = 0.001

// defaultWeights are the FSRS-6 default parameters frozen for hiraku.
var defaultWeights = [21]float64{
	0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666,
	0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
	0.1542,
}

const minuteMs int64 = 60_000
const dayMs int64 = 86_400_000

// Next returns the card after the review, matching py-fsrs review_card.
func Next(card Card, rating Rating, nowMs int64, settings Settings) Card {
	return next(card, rating, nowMs, settings, defaultWeights)
}

// Preview returns the card for each rating without mutating state.
func Preview(card Card, nowMs int64, settings Settings) map[Rating]Card {
	out := make(map[Rating]Card, 4)
	for _, rating := range []Rating{RatingAgain, RatingHard, RatingGood, RatingEasy} {
		out[rating] = Next(card, rating, nowMs, settings)
	}
	return out
}

func next(card Card, rating Rating, nowMs int64, s Settings, w [21]float64) Card {
	decay := -w[20]
	factor := math.Pow(0.9, 1/decay) - 1

	wasReview := card.State == StateReview
	elapsed := elapsedDays(card.LastReviewMs, nowMs, s.DayStartHour)

	switch card.State {
	case StateNew:
		card.State = StateLearning
		card.RemainingSteps = len(s.LearningStepsMinutes)
		card.Stability = initStability(rating, w)
		card.Difficulty = initDifficulty(rating, w)
		learningStep(&card, rating, nowMs, s.LearningStepsMinutes, s, w, factor, decay)
	case StateLearning:
		update(card.LastReviewMs, card.Stability, card.Difficulty, rating, elapsed, nowMs, &card, w, factor, decay)
		learningStep(&card, rating, nowMs, s.LearningStepsMinutes, s, w, factor, decay)
	case StateReview:
		update(card.LastReviewMs, card.Stability, card.Difficulty, rating, elapsed, nowMs, &card, w, factor, decay)
		if rating == RatingAgain && len(s.RelearningStepsMinutes) > 0 {
			card.State = StateRelearning
			card.RemainingSteps = len(s.RelearningStepsMinutes)
			card.DueMs = nowMs + minutes(s.RelearningStepsMinutes[0])
		} else {
			card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
		}
	case StateRelearning:
		update(card.LastReviewMs, card.Stability, card.Difficulty, rating, elapsed, nowMs, &card, w, factor, decay)
		relearningStep(&card, rating, nowMs, s.RelearningStepsMinutes, s, factor, decay)
	}

	card.Reps++
	if rating == RatingAgain && wasReview {
		card.Lapses++
	}
	card.ElapsedDays = elapsed
	card.ScheduledDays = int((card.DueMs - nowMs) / dayMs)
	card.LastReviewMs = nowMs
	return card
}

func learningStep(card *Card, rating Rating, nowMs int64, steps []float64, s Settings, w [21]float64, factor, decay float64) {
	step := len(steps) - card.RemainingSteps
	if len(steps) == 0 || (step >= len(steps) && rating >= RatingHard) {
		card.State = StateReview
		card.RemainingSteps = 0
		card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
		return
	}
	switch rating {
	case RatingAgain:
		card.RemainingSteps = len(steps)
		card.DueMs = nowMs + minutes(steps[0])
	case RatingHard:
		var interval float64
		switch {
		case step == 0 && len(steps) == 1:
			interval = steps[0] * 1.5
		case step == 0 && len(steps) >= 2:
			interval = (steps[0] + steps[1]) / 2
		default:
			interval = steps[step]
		}
		card.DueMs = nowMs + minutes(interval)
	case RatingGood:
		if step+1 == len(steps) {
			card.State = StateReview
			card.RemainingSteps = 0
			card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
			return
		}
		card.RemainingSteps = len(steps) - (step + 1)
		card.DueMs = nowMs + minutes(steps[step+1])
	case RatingEasy:
		card.State = StateReview
		card.RemainingSteps = 0
		card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
	}
}

func relearningStep(card *Card, rating Rating, nowMs int64, steps []float64, s Settings, factor, decay float64) {
	step := len(steps) - card.RemainingSteps
	if len(steps) == 0 || (step >= len(steps) && rating >= RatingHard) {
		card.State = StateReview
		card.RemainingSteps = 0
		card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
		return
	}
	switch rating {
	case RatingAgain:
		card.RemainingSteps = len(steps)
		card.DueMs = nowMs + minutes(steps[0])
	case RatingHard:
		var interval float64
		switch {
		case step == 0 && len(steps) == 1:
			interval = steps[0] * 1.5
		case step == 0 && len(steps) >= 2:
			interval = (steps[0] + steps[1]) / 2
		default:
			interval = steps[step]
		}
		card.DueMs = nowMs + minutes(interval)
	case RatingGood:
		if step+1 == len(steps) {
			card.State = StateReview
			card.RemainingSteps = 0
			card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
			return
		}
		card.RemainingSteps = len(steps) - (step + 1)
		card.DueMs = nowMs + minutes(steps[step+1])
	case RatingEasy:
		card.State = StateReview
		card.RemainingSteps = 0
		card.DueMs = nowMs + intervalMs(card.Stability, s, factor, decay)
	}
}

func update(lastReviewMs int64, stability, difficulty float64, rating Rating, elapsedDays int, nowMs int64, card *Card, w [21]float64, factor, decay float64) {
	if lastReviewMs != 0 && elapsedDays < 1 {
		card.Stability = shortTermStability(stability, rating, w)
	} else {
		retrievability := retrievability(lastReviewMs, nowMs, stability, elapsedDays, factor, decay)
		card.Stability = nextStability(difficulty, stability, retrievability, rating, w)
	}
	card.Difficulty = nextDifficulty(difficulty, rating, w)
}

func initStability(rating Rating, w [21]float64) float64 {
	return math.Max(w[rating-1], stabilityMin)
}

func initDifficulty(rating Rating, w [21]float64) float64 {
	return clampDifficulty(w[4] - math.Exp(w[5]*float64(rating-1)) + 1)
}

func nextDifficulty(difficulty float64, rating Rating, w [21]float64) float64 {
	easy := w[4] - math.Exp(w[5]*3) + 1
	delta := -(w[6] * float64(rating-3))
	arg2 := difficulty + (10-difficulty)*delta/9
	return clampDifficulty(w[7]*easy + (1-w[7])*arg2)
}

func shortTermStability(stability float64, rating Rating, w [21]float64) float64 {
	increase := math.Exp(w[17]*(float64(rating)-3+w[18])) * math.Pow(stability, -w[19])
	if rating >= RatingHard {
		increase = math.Max(increase, 1)
	}
	return math.Max(stability*increase, stabilityMin)
}

func nextStability(difficulty, stability, retrievability float64, rating Rating, w [21]float64) float64 {
	var out float64
	if rating == RatingAgain {
		longTerm := w[11] * math.Pow(difficulty, -w[12]) *
			(math.Pow(stability+1, w[13]) - 1) *
			math.Exp((1-retrievability)*w[14])
		shortTerm := stability / math.Exp(w[17]*w[18])
		out = math.Min(longTerm, shortTerm)
	} else {
		hardPenalty := 1.0
		if rating == RatingHard {
			hardPenalty = w[15]
		}
		easyBonus := 1.0
		if rating == RatingEasy {
			easyBonus = w[16]
		}
		out = stability * (1 + math.Exp(w[8])*(11-difficulty)*math.Pow(stability, -w[9])*
			(math.Exp((1-retrievability)*w[10])-1)*hardPenalty*easyBonus)
	}
	return math.Max(out, stabilityMin)
}

func retrievability(lastReviewMs, nowMs int64, stability float64, elapsed int, factor, decay float64) float64 {
	if lastReviewMs == 0 {
		return 0
	}
	days := math.Max(0, float64(elapsed))
	return math.Pow(1+factor*days/stability, decay)
}

func intervalMs(stability float64, s Settings, factor, decay float64) int64 {
	if s.RequestRetention <= 0 {
		s.RequestRetention = 0.9
	}
	days := (stability / factor) * (math.Pow(s.RequestRetention, 1/decay) - 1)
	interval := int(math.RoundToEven(days))
	if interval < 1 {
		interval = 1
	}
	if s.MaximumIntervalDays > 0 && interval > s.MaximumIntervalDays {
		interval = s.MaximumIntervalDays
	}
	return int64(interval) * dayMs
}

func minutes(v float64) int64 { return int64(math.Round(v * float64(minuteMs))) }

// elapsedDays counts hiraku study days between two timestamps.
func elapsedDays(lastMs, nowMs int64, dayStartHour int) int {
	if lastMs == 0 {
		return 0
	}
	return int(dayboundary.Index(nowMs, dayStartHour) - dayboundary.Index(lastMs, dayStartHour))
}

func clampDifficulty(d float64) float64 { return math.Min(math.Max(d, 1), 10) }
