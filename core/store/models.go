package store

import "errors"

// ErrNotFound means the requested live row does not exist.
var ErrNotFound = errors.New("row not found")

// Folder is a top-level grouping of decks.
type Folder struct {
	ID       string
	Name     string
	Position int
}

// Deck belongs to a folder and uses one note type.
type Deck struct {
	ID          string
	FolderID    string
	NoteTypeID  string
	Name        string
	Description string
	Position    int
}

// Note holds field values keyed by note_type_fields.id.
type Note struct {
	ID         string
	DeckID     string
	NoteTypeID string
	Fields     map[string]string
	SortField  string
	SearchText string
}
