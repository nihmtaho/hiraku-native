package store

import (
	"errors"

	"hiraku/core/domain/notetype"
)

// ErrNotFound means the requested live row does not exist.
var ErrNotFound = errors.New("row not found")

// Folder is a top-level grouping of decks; the counts drive the folder meta line.
type Folder struct {
	ID        string
	Name      string
	Position  int
	DeckCount int
	NoteCount int
}

// Deck belongs to a folder and uses one note type.
type Deck struct {
	ID          string
	FolderID    string
	NoteTypeID  string
	Name        string
	Description string
	Position    int
	NoteCount   int
	StateNew    int
	StateLearn  int
	StateKnown  int
}

// Note holds field values keyed by note_type_fields.id.
type Note struct {
	ID         string
	DeckID     string
	NoteTypeID string
	Fields     map[string]string
	SortField  string
	SearchText string
	State      int
}

// NoteType carries the field definitions and the single card template a deck uses.
type NoteType struct {
	ID            string
	Name          string
	IsSystem      bool
	Fields        []notetype.Field
	FrontFieldIDs []string
	BackFieldIDs  []string
	AnswerFieldID string
}
