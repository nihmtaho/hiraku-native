package notetype

import (
	"errors"
	"testing"
)

func field(name string, role Role) Field {
	return Field{Name: name, Role: role}
}

func TestValidateAcceptsSystemShape(t *testing.T) {
	err := Validate([]Field{
		field("Từ", RoleTerm),
		field("Cách đọc", RoleReading),
		field("Nghĩa", RoleMeaning),
		field("Câu ví dụ", RoleExample),
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestValidateRejectsSecondTerm(t *testing.T) {
	err := Validate([]Field{field("Từ", RoleTerm), field("Từ 2", RoleTerm)})
	if !errors.Is(err, ErrDuplicateRole) {
		t.Fatalf("err = %v, want ErrDuplicateRole", err)
	}
}

func TestValidateRejectsMissingTerm(t *testing.T) {
	err := Validate([]Field{field("Nghĩa", RoleMeaning)})
	if !errors.Is(err, ErrMissingTerm) {
		t.Fatalf("err = %v, want ErrMissingTerm", err)
	}
}

func TestValidateRejectsDuplicateName(t *testing.T) {
	err := Validate([]Field{field("Từ", RoleTerm), field("Từ", RoleText)})
	if err == nil {
		t.Fatal("duplicate name accepted")
	}
}
