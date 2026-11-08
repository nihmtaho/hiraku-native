package notetype

import (
	"errors"
	"fmt"
)

// Role drives study, typing and search behavior; never rely on a field name.
type Role string

const (
	RoleTerm    Role = "term"
	RoleReading Role = "reading"
	RoleMeaning Role = "meaning"
	RoleExample Role = "example"
	RoleText    Role = "text"
)

// Field is the typed definition of one value inside a note.
type Field struct {
	ID         string
	NoteTypeID string
	Ord        int
	Name       string
	Role       Role
	InputKind  string
	Required   bool
	Searchable bool
}

var (
	ErrTooManyFields  = errors.New("note type has more than 10 fields")
	ErrDuplicateName  = errors.New("note type has duplicate field names")
	ErrDuplicateRole  = errors.New("note type has duplicate roles")
	ErrMissingTerm    = errors.New("note type needs exactly one term field")
	ErrMissingRoleKey = errors.New("note type field has an unknown role")
)

// Validate checks the invariants ADR-27 puts on a note type.
func Validate(fields []Field) error {
	if len(fields) > 10 {
		return ErrTooManyFields
	}
	names := make(map[string]bool, len(fields))
	roles := make(map[Role]int, len(fields))
	for _, f := range fields {
		if names[f.Name] {
			return fmt.Errorf("%w: %s", ErrDuplicateName, f.Name)
		}
		names[f.Name] = true
		switch f.Role {
		case RoleTerm, RoleReading, RoleMeaning, RoleExample:
			roles[f.Role]++
			if roles[f.Role] > 1 {
				return fmt.Errorf("%w: %s", ErrDuplicateRole, f.Role)
			}
		case RoleText:
			roles[f.Role]++
		default:
			return fmt.Errorf("%w: %s", ErrMissingRoleKey, f.Role)
		}
	}
	if roles[RoleTerm] != 1 {
		return ErrMissingTerm
	}
	return nil
}
