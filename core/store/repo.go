package store

import (
	"context"

	"hiraku/core/domain/id"
)

// Repo runs queries on the store or inside an open transaction.
type Repo struct {
	q     Querier
	store *Store
}

// Repo returns a repository over the store.
func (s *Store) Repo() *Repo { return &Repo{q: s, store: s} }

// Tx runs fn with a repository bound to one transaction.
func (r *Repo) Tx(ctx context.Context, fn func(*Repo) error) error {
	if r.store == nil {
		return fn(r)
	}
	return r.store.Tx(ctx, func(q Querier) error {
		return fn(&Repo{q: q})
	})
}

// Folders lists live folders ordered by position.
func (r *Repo) Folders(ctx context.Context) ([]Folder, error) {
	rows, err := r.q.QueryContext(ctx, `
		SELECT id, name, position FROM folders
		WHERE deleted_at IS NULL ORDER BY position, created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Folder
	for rows.Next() {
		var f Folder
		if err := rows.Scan(&f.ID, &f.Name, &f.Position); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// CreateFolder inserts a folder at the end.
func (r *Repo) CreateFolder(ctx context.Context, nowMs int64, name string) (Folder, error) {
	var folder Folder
	err := r.Tx(ctx, func(r *Repo) error {
		newID, err := id.New(nowMs)
		if err != nil {
			return err
		}
		if err := r.q.QueryRowContext(ctx, `
			SELECT COALESCE(MAX(position), 0) + 1 FROM folders WHERE deleted_at IS NULL`).Scan(&folder.Position); err != nil {
			return err
		}
		if _, err := r.q.ExecContext(ctx, `
			INSERT INTO folders (id, name, position, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?)`, newID, name, folder.Position, nowMs, nowMs); err != nil {
			return err
		}
		folder.ID = newID
		folder.Name = name
		return nil
	})
	return folder, err
}

// UpdateFolder renames a folder.
func (r *Repo) UpdateFolder(ctx context.Context, nowMs int64, f Folder) error {
	result, err := r.q.ExecContext(ctx, `
		UPDATE folders SET name = ?, updated_at = ? WHERE id = ? AND deleted_at IS NULL`,
		f.Name, nowMs, f.ID)
	return requireOneRow(result, err)
}

// DeleteFolder soft deletes the folder and its decks, notes and cards in one transaction.
func (r *Repo) DeleteFolder(ctx context.Context, nowMs int64, folderID string) error {
	return r.Tx(ctx, func(r *Repo) error {
		for _, step := range []string{
			`UPDATE cards SET deleted_at = ? WHERE note_id IN (
				SELECT n.id FROM notes n JOIN decks d ON d.id = n.deck_id WHERE d.folder_id = ?)`,
			`UPDATE notes SET deleted_at = ? WHERE deck_id IN (SELECT id FROM decks WHERE folder_id = ?)`,
			`UPDATE decks SET deleted_at = ? WHERE folder_id = ?`,
			`UPDATE folders SET deleted_at = ? WHERE id = ?`,
		} {
			if _, err := r.q.ExecContext(ctx, step, nowMs, folderID); err != nil {
				return err
			}
		}
		return nil
	})
}

// ReorderFolders writes positions 1..n in the given order in one transaction.
func (r *Repo) ReorderFolders(ctx context.Context, nowMs int64, ids []string) error {
	return r.Tx(ctx, func(r *Repo) error {
		for i, folderID := range ids {
			if _, err := r.q.ExecContext(ctx, `
				UPDATE folders SET position = ?, updated_at = ? WHERE id = ?`,
				i+1, nowMs, folderID); err != nil {
				return err
			}
		}
		return nil
	})
}

// PurgeDeleted removes rows soft deleted before beforeMs in one transaction.
func (r *Repo) PurgeDeleted(ctx context.Context, beforeMs int64) error {
	return r.Tx(ctx, func(r *Repo) error {
		for _, step := range []string{
			`DELETE FROM review_logs WHERE card_id IN (SELECT id FROM cards WHERE deleted_at IS NOT NULL AND deleted_at < ?)`,
			`DELETE FROM card_states WHERE card_id IN (SELECT id FROM cards WHERE deleted_at IS NOT NULL AND deleted_at < ?)`,
			`DELETE FROM cards WHERE deleted_at IS NOT NULL AND deleted_at < ?`,
			`DELETE FROM notes WHERE deleted_at IS NOT NULL AND deleted_at < ?`,
			`DELETE FROM decks WHERE deleted_at IS NOT NULL AND deleted_at < ?`,
			`DELETE FROM folders WHERE deleted_at IS NOT NULL AND deleted_at < ?`,
		} {
			if _, err := r.q.ExecContext(ctx, step, beforeMs); err != nil {
				return err
			}
		}
		return nil
	})
}

// Decks lists live decks in a folder ordered by position.
func (r *Repo) Decks(ctx context.Context, folderID string) ([]Deck, error) {
	rows, err := r.q.QueryContext(ctx, `
		SELECT id, folder_id, note_type_id, name, COALESCE(description, ''), position
		FROM decks WHERE folder_id = ? AND deleted_at IS NULL ORDER BY position, created_at`, folderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Deck
	for rows.Next() {
		var d Deck
		if err := rows.Scan(&d.ID, &d.FolderID, &d.NoteTypeID, &d.Name, &d.Description, &d.Position); err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

// CreateDeck inserts a deck at the end of its folder.
func (r *Repo) CreateDeck(ctx context.Context, nowMs int64, d Deck) (Deck, error) {
	err := r.Tx(ctx, func(r *Repo) error {
		newID, err := id.New(nowMs)
		if err != nil {
			return err
		}
		if d.NoteTypeID == "" {
			d.NoteTypeID = SystemNoteTypeID
		}
		if err := r.q.QueryRowContext(ctx, `
			SELECT COALESCE(MAX(position), 0) + 1 FROM decks
			WHERE folder_id = ? AND deleted_at IS NULL`, d.FolderID).Scan(&d.Position); err != nil {
			return err
		}
		if _, err := r.q.ExecContext(ctx, `
			INSERT INTO decks (id, folder_id, note_type_id, name, description, position, created_at, updated_at)
			VALUES (?, ?, ?, ?, NULLIF(?, ''), ?, ?, ?)`,
			newID, d.FolderID, d.NoteTypeID, d.Name, d.Description, d.Position, nowMs, nowMs); err != nil {
			return err
		}
		d.ID = newID
		return nil
	})
	return d, err
}

// UpdateDeck updates name and description; the note type is immutable once set.
func (r *Repo) UpdateDeck(ctx context.Context, nowMs int64, d Deck) error {
	result, err := r.q.ExecContext(ctx, `
		UPDATE decks SET name = ?, description = NULLIF(?, ''), updated_at = ?
		WHERE id = ? AND deleted_at IS NULL`, d.Name, d.Description, nowMs, d.ID)
	return requireOneRow(result, err)
}

// DeleteDeck soft deletes the deck with its notes and cards in one transaction.
func (r *Repo) DeleteDeck(ctx context.Context, nowMs int64, deckID string) error {
	return r.Tx(ctx, func(r *Repo) error {
		for _, step := range []string{
			`UPDATE cards SET deleted_at = ? WHERE note_id IN (SELECT id FROM notes WHERE deck_id = ?)`,
			`UPDATE notes SET deleted_at = ? WHERE deck_id = ?`,
			`UPDATE decks SET deleted_at = ? WHERE id = ?`,
		} {
			if _, err := r.q.ExecContext(ctx, step, nowMs, deckID); err != nil {
				return err
			}
		}
		return nil
	})
}

// ReorderDecks writes positions 1..n in the given order in one transaction.
func (r *Repo) ReorderDecks(ctx context.Context, nowMs int64, ids []string) error {
	return r.Tx(ctx, func(r *Repo) error {
		for i, deckID := range ids {
			if _, err := r.q.ExecContext(ctx, `
				UPDATE decks SET position = ?, updated_at = ? WHERE id = ?`,
				i+1, nowMs, deckID); err != nil {
				return err
			}
		}
		return nil
	})
}

func requireOneRow(result interface {
	RowsAffected() (int64, error)
}, err error) error {
	if err != nil {
		return err
	}
	affected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if affected == 0 {
		return ErrNotFound
	}
	return nil
}
