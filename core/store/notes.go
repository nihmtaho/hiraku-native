package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"hiraku/core/domain/id"
	"hiraku/core/domain/notetype"
)

// SystemNoteTypeID is the fixed id of the bundled Japanese vocabulary type.
const SystemNoteTypeID = "nt-system-ja"

// ErrInvalidNote means the note values do not respect its note type.
var ErrInvalidNote = errors.New("note does not match its note type")

// Fields returns the field definitions of a note type, ordered for display.
func (r *Repo) Fields(ctx context.Context, noteTypeID string) ([]notetype.Field, error) {
	rows, err := r.q.QueryContext(ctx, `
		SELECT id, note_type_id, ord, name, role, input_kind, required, searchable
		FROM note_type_fields
		WHERE note_type_id = ? AND deleted_at IS NULL ORDER BY ord`, noteTypeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []notetype.Field
	for rows.Next() {
		var f notetype.Field
		if err := rows.Scan(&f.ID, &f.NoteTypeID, &f.Ord, &f.Name, &f.Role, &f.InputKind, &f.Required, &f.Searchable); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// CreateNote inserts a note and its card in one transaction.
func (r *Repo) CreateNote(ctx context.Context, nowMs int64, deckID string, values map[string]string) (Note, error) {
	var note Note
	err := r.Tx(ctx, func(r *Repo) error {
		var noteTypeID string
		if err := r.q.QueryRowContext(ctx, `
			SELECT note_type_id FROM decks WHERE id = ? AND deleted_at IS NULL`, deckID).Scan(&noteTypeID); errors.Is(err, sql.ErrNoRows) {
			return ErrNotFound
		} else if err != nil {
			return err
		}
		fields, err := r.Fields(ctx, noteTypeID)
		if err != nil {
			return err
		}
		note, err = composeNote(noteTypeID, deckID, fields, values)
		if err != nil {
			return err
		}
		newID, err := id.New(nowMs)
		if err != nil {
			return err
		}
		note.ID = newID
		encoded, err := json.Marshal(note.Fields)
		if err != nil {
			return err
		}
		if _, err := r.q.ExecContext(ctx, `
			INSERT INTO notes (id, deck_id, note_type_id, fields, sort_field, search_text, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
			note.ID, deckID, noteTypeID, string(encoded), note.SortField, note.SearchText, nowMs, nowMs); err != nil {
			return err
		}
		result, err := r.q.ExecContext(ctx, `
			INSERT INTO cards (id, note_id, template_id, created_at, updated_at)
			SELECT ?, ?, id, ?, ? FROM card_templates
			WHERE note_type_id = ? AND deleted_at IS NULL LIMIT 1`,
			note.ID, note.ID, nowMs, nowMs, noteTypeID)
		if err != nil {
			return err
		}
		if inserted, err := result.RowsAffected(); err != nil || inserted != 1 {
			return fmt.Errorf("%w: note type has no card template", ErrInvalidNote)
		}
		return nil
	})
	return note, err
}

func composeNote(noteTypeID, deckID string, fields []notetype.Field, values map[string]string) (Note, error) {
	if err := notetype.Validate(fields); err != nil {
		return Note{}, fmt.Errorf("%w: %v", ErrInvalidNote, err)
	}
	note := Note{DeckID: deckID, NoteTypeID: noteTypeID, Fields: map[string]string{}}
	var search []string
	for _, field := range fields {
		value := strings.TrimSpace(values[field.ID])
		if field.Role == notetype.RoleTerm && value == "" {
			return Note{}, fmt.Errorf("%w: term is required", ErrInvalidNote)
		}
		if field.Required && value == "" {
			return Note{}, fmt.Errorf("%w: %s is required", ErrInvalidNote, field.Name)
		}
		if value != "" {
			note.Fields[field.ID] = value
		}
		if field.Role == notetype.RoleTerm {
			note.SortField = value
		}
		if field.Searchable && value != "" {
			search = append(search, strings.ToLower(value))
		}
	}
	note.SearchText = strings.Join(search, " ")
	return note, nil
}

// Notes lists live notes in a deck ordered by sort field.
func (r *Repo) Notes(ctx context.Context, deckID string, limit, offset int) ([]Note, error) {
	return r.queryNotes(ctx, `
		SELECT id, deck_id, note_type_id, fields, sort_field, search_text
		FROM notes WHERE deck_id = ? AND deleted_at IS NULL
		ORDER BY sort_field, created_at LIMIT ? OFFSET ?`, deckID, limit, offset)
}

// Search finds live notes whose search text contains query, case-insensitive.
func (r *Repo) Search(ctx context.Context, deckID, query string, limit, offset int) ([]Note, error) {
	pattern := "%" + escapeLike(strings.ToLower(strings.TrimSpace(query))) + "%"
	return r.queryNotes(ctx, `
		SELECT id, deck_id, note_type_id, fields, sort_field, search_text
		FROM notes WHERE deck_id = ? AND deleted_at IS NULL AND search_text LIKE ? ESCAPE '\'
		ORDER BY sort_field, created_at LIMIT ? OFFSET ?`, deckID, pattern, limit, offset)
}

func (r *Repo) queryNotes(ctx context.Context, query string, args ...any) ([]Note, error) {
	rows, err := r.q.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Note
	for rows.Next() {
		var n Note
		var fields string
		if err := rows.Scan(&n.ID, &n.DeckID, &n.NoteTypeID, &fields, &n.SortField, &n.SearchText); err != nil {
			return nil, err
		}
		if err := json.Unmarshal([]byte(fields), &n.Fields); err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

// Note reads one live note.
func (r *Repo) Note(ctx context.Context, noteID string) (Note, error) {
	notes, err := r.queryNotes(ctx, `
		SELECT id, deck_id, note_type_id, fields, sort_field, search_text
		FROM notes WHERE id = ? AND deleted_at IS NULL`, noteID)
	if err != nil {
		return Note{}, err
	}
	if len(notes) == 0 {
		return Note{}, ErrNotFound
	}
	return notes[0], nil
}

// UpdateNote rewrites values and recomputes sort and search text.
func (r *Repo) UpdateNote(ctx context.Context, nowMs int64, noteID string, values map[string]string) (Note, error) {
	var note Note
	err := r.Tx(ctx, func(r *Repo) error {
		current, err := r.Note(ctx, noteID)
		if err != nil {
			return err
		}
		fields, err := r.Fields(ctx, current.NoteTypeID)
		if err != nil {
			return err
		}
		note, err = composeNote(current.NoteTypeID, current.DeckID, fields, values)
		if err != nil {
			return err
		}
		note.ID = current.ID
		active := make(map[string]bool, len(fields))
		for _, field := range fields {
			active[field.ID] = true
		}
		for fieldID, value := range current.Fields {
			if !active[fieldID] {
				note.Fields[fieldID] = value
			}
		}
		encoded, err := json.Marshal(note.Fields)
		if err != nil {
			return err
		}
		_, err = r.q.ExecContext(ctx, `
			UPDATE notes SET fields = ?, sort_field = ?, search_text = ?, updated_at = ?
			WHERE id = ?`, string(encoded), note.SortField, note.SearchText, nowMs, note.ID)
		return err
	})
	return note, err
}

// DeleteNote soft deletes the note and its cards in one transaction.
func (r *Repo) DeleteNote(ctx context.Context, nowMs int64, noteID string) error {
	return r.Tx(ctx, func(r *Repo) error {
		if _, err := r.q.ExecContext(ctx,
			`UPDATE cards SET deleted_at = ? WHERE note_id = ?`, nowMs, noteID); err != nil {
			return err
		}
		_, err := r.q.ExecContext(ctx,
			`UPDATE notes SET deleted_at = ? WHERE id = ?`, nowMs, noteID)
		return err
	})
}

// DuplicateExists reports a live note in the deck with the same sort field.
func (r *Repo) DuplicateExists(ctx context.Context, deckID, sortField string) (bool, error) {
	var found int
	err := r.q.QueryRowContext(ctx, `
		SELECT 1 FROM notes WHERE deck_id = ? AND sort_field = ? AND deleted_at IS NULL LIMIT 1`,
		deckID, sortField).Scan(&found)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return found == 1, nil
}

func escapeLike(value string) string {
	replacer := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return replacer.Replace(value)
}
