package store

import (
	"context"
	"database/sql"
	"errors"
	"strconv"
)

// ErrUnknownSetting is returned for keys that are not profile study settings.
var ErrUnknownSetting = errors.New("unknown or app-level setting")

// ErrInvalidSetting is returned when a value is outside the documented range.
var ErrInvalidSetting = errors.New("setting value is invalid")

type settingSpec struct {
	def   string
	check func(string) bool
}

var studySettings = map[string]settingSpec{
	"fsrs_retention":    {"0.9", floatRange(0.70, 0.95)},
	"fsrs_max_interval": {"36500", intRange(1, 36500)},
	"fsrs_short_term":   {"true", boolValue},
	"new_cards_per_day": {"20", intRange(0, 999)},
	"grading_buttons":   {"2", oneOf("2", "4")},
	"card_direction":    {"word_to_meaning", oneOf("word_to_meaning", "meaning_to_word", "mixed")},
	"day_start_hour":    {"4", intRange(0, 23)},
	"last_backup_at":    {"", epochOrEmpty},
}

// Setting returns a study setting or its default when unset.
func (r *Repo) Setting(ctx context.Context, key string) (string, error) {
	spec, ok := studySettings[key]
	if !ok {
		return "", ErrUnknownSetting
	}
	var value string
	err := r.q.QueryRowContext(ctx, `SELECT value FROM settings WHERE key = ?`, key).Scan(&value)
	if errors.Is(err, sql.ErrNoRows) {
		return spec.def, nil
	}
	return value, err
}

// SetSetting validates and stores a study setting.
func (r *Repo) SetSetting(ctx context.Context, nowMs int64, key, value string) error {
	spec, ok := studySettings[key]
	if !ok {
		return ErrUnknownSetting
	}
	if !spec.check(value) {
		return ErrInvalidSetting
	}
	_, err := r.q.ExecContext(ctx, `
		INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
		ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
		key, value, nowMs)
	return err
}

func floatRange(min, max float64) func(string) bool {
	return func(value string) bool {
		v, err := strconv.ParseFloat(value, 64)
		return err == nil && v >= min && v <= max
	}
}

func intRange(min, max int) func(string) bool {
	return func(value string) bool {
		v, err := strconv.Atoi(value)
		return err == nil && v >= min && v <= max
	}
}

func boolValue(value string) bool { return value == "true" || value == "false" }

func oneOf(allowed ...string) func(string) bool {
	return func(value string) bool {
		for _, candidate := range allowed {
			if value == candidate {
				return true
			}
		}
		return false
	}
}

func epochOrEmpty(value string) bool {
	if value == "" {
		return true
	}
	v, err := strconv.ParseInt(value, 10, 64)
	return err == nil && v > 0
}
