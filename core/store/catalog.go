package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"strings"

	"hiraku/core/domain/notetype"
)

// NoteTypes lists live note types with their fields and card template.
func (r *Repo) NoteTypes(ctx context.Context) ([]NoteType, error) {
	rows, err := r.q.QueryContext(ctx, `
		SELECT id, name, is_system FROM note_types WHERE deleted_at IS NULL ORDER BY is_system DESC, name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []NoteType
	for rows.Next() {
		var t NoteType
		if err := rows.Scan(&t.ID, &t.Name, &t.IsSystem); err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i := range out {
		if out[i].Fields, err = r.Fields(ctx, out[i].ID); err != nil {
			return nil, err
		}
		if err := r.loadTemplate(ctx, &out[i]); err != nil {
			return nil, err
		}
	}
	return out, nil
}

// loadTemplate fills the single card template of a note type; a type without one stays empty.
func (r *Repo) loadTemplate(ctx context.Context, t *NoteType) error {
	var front, back string
	err := r.q.QueryRowContext(ctx, `
		SELECT front_fields, back_fields, COALESCE(typing_answer_field_id, '')
		FROM card_templates WHERE note_type_id = ? AND deleted_at IS NULL LIMIT 1`,
		t.ID).Scan(&front, &back, &t.AnswerFieldID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(front), &t.FrontFieldIDs); err != nil {
		return err
	}
	return json.Unmarshal([]byte(back), &t.BackFieldIDs)
}

// MoveDeck moves a deck to the end of another folder in one transaction.
func (r *Repo) MoveDeck(ctx context.Context, nowMs int64, deckID, folderID string) error {
	return r.Tx(ctx, func(r *Repo) error {
		var position int
		if err := r.q.QueryRowContext(ctx, `
			SELECT COALESCE(MAX(position), 0) + 1 FROM decks
			WHERE folder_id = ? AND deleted_at IS NULL`, folderID).Scan(&position); err != nil {
			return err
		}
		result, err := r.q.ExecContext(ctx, `
			UPDATE decks SET folder_id = ?, position = ?, updated_at = ?
			WHERE id = ? AND deleted_at IS NULL`, folderID, position, nowMs, deckID)
		return requireOneRow(result, err)
	})
}

// CountNotes counts the live notes a query matches, for the page total.
func (r *Repo) CountNotes(ctx context.Context, deckID, query string) (int, error) {
	var total int
	if strings.TrimSpace(query) == "" {
		err := r.q.QueryRowContext(ctx, `
			SELECT COUNT(*) FROM notes WHERE deck_id = ? AND deleted_at IS NULL`, deckID).Scan(&total)
		return total, err
	}
	pattern := "%" + escapeLike(strings.ToLower(strings.TrimSpace(query))) + "%"
	err := r.q.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM notes
		WHERE deck_id = ? AND deleted_at IS NULL AND search_text LIKE ? ESCAPE '\'`,
		deckID, pattern).Scan(&total)
	return total, err
}

// DuplicateMeaning returns the meaning of the live note whose term matches, if one exists.
func (r *Repo) DuplicateMeaning(ctx context.Context, deckID, term string) (string, bool, error) {
	var noteID, noteTypeID, encoded string
	err := r.q.QueryRowContext(ctx, `
		SELECT id, note_type_id, fields FROM notes
		WHERE deck_id = ? AND deleted_at IS NULL AND sort_field = ? LIMIT 1`,
		deckID, strings.TrimSpace(term)).Scan(&noteID, &noteTypeID, &encoded)
	if errors.Is(err, sql.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	fields, err := r.Fields(ctx, noteTypeID)
	if err != nil {
		return "", false, err
	}
	var values map[string]string
	if err := json.Unmarshal([]byte(encoded), &values); err != nil {
		return "", false, err
	}
	for _, field := range fields {
		if field.Role == notetype.RoleMeaning {
			return values[field.ID], true, nil
		}
	}
	return "", true, nil
}

// FolderExists reports whether a live folder has this id.
func (r *Repo) FolderExists(ctx context.Context, folderID string) (bool, error) {
	var found int
	err := r.q.QueryRowContext(ctx, `
		SELECT 1 FROM folders WHERE id = ? AND deleted_at IS NULL`, folderID).Scan(&found)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// DeckExists reports whether a live deck has this id.
func (r *Repo) DeckExists(ctx context.Context, deckID string) (bool, error) {
	var found int
	err := r.q.QueryRowContext(ctx, `
		SELECT 1 FROM decks WHERE id = ? AND deleted_at IS NULL`, deckID).Scan(&found)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// NoteExists reports whether a live note has this id.
func (r *Repo) NoteExists(ctx context.Context, noteID string) (bool, error) {
	var found int
	err := r.q.QueryRowContext(ctx, `
		SELECT 1 FROM notes WHERE id = ? AND deleted_at IS NULL`, noteID).Scan(&found)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}
