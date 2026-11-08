package store_test

import (
	"context"
	"database/sql"
	"errors"
	"path/filepath"
	"testing"

	"hiraku/core/store"
)

func openRepo(t *testing.T) (*store.Store, *store.Repo) {
	t.Helper()
	s, err := store.Open(filepath.Join(t.TempDir(), "hiraku.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return s, s.Repo()
}

func seedDeck(t *testing.T, r *store.Repo) (string, string) {
	t.Helper()
	ctx := context.Background()
	folder, err := r.CreateFolder(ctx, 1, "Thư mục")
	if err != nil {
		t.Fatal(err)
	}
	deck, err := r.CreateDeck(ctx, 2, store.Deck{FolderID: folder.ID, Name: "Bộ thẻ"})
	if err != nil {
		t.Fatal(err)
	}
	return folder.ID, deck.ID
}

func TestFoldersAndCascade(t *testing.T) {
	ctx := context.Background()
	s, r := openRepo(t)
	folderID, deckID := seedDeck(t, r)

	folders, err := r.Folders(ctx)
	if err != nil || len(folders) != 1 || folders[0].Name != "Thư mục" {
		t.Fatalf("folders = %+v, err = %v", folders, err)
	}

	if err := r.UpdateFolder(ctx, 3, store.Folder{ID: folderID, Name: "Đổi tên"}); err != nil {
		t.Fatal(err)
	}
	second, err := r.CreateFolder(ctx, 4, "Sau")
	if err != nil {
		t.Fatal(err)
	}
	if err := r.ReorderFolders(ctx, 5, []string{second.ID, folderID}); err != nil {
		t.Fatal(err)
	}
	folders, _ = r.Folders(ctx)
	if folders[0].ID != second.ID || folders[1].Position != 2 {
		t.Fatalf("reorder = %+v", folders)
	}

	note, err := r.CreateNote(ctx, 6, deckID, map[string]string{
		"nf-term": "水", "nf-meaning": "nước",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := r.DeleteFolder(ctx, 7, folderID); err != nil {
		t.Fatal(err)
	}
	if _, err := r.Note(ctx, note.ID); !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("note after folder delete: %v", err)
	}
	var cards int
	if err := s.DB().QueryRow(`SELECT COUNT(*) FROM cards WHERE deleted_at IS NULL`).Scan(&cards); err != nil {
		t.Fatal(err)
	}
	if cards != 0 {
		t.Fatalf("live cards = %d, want 0", cards)
	}
}

func TestNotesComposeSearchAndDuplicates(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)
	_, deckID := seedDeck(t, r)

	note, err := r.CreateNote(ctx, 10, deckID, map[string]string{
		"nf-term": "水", "nf-reading": "みず", "nf-meaning": "Nước",
	})
	if err != nil {
		t.Fatal(err)
	}
	if note.SortField != "水" || note.SearchText != "水 みず nước" {
		t.Fatalf("sort = %q, search = %q", note.SortField, note.SearchText)
	}

	if _, err := r.CreateNote(ctx, 11, deckID, map[string]string{"nf-term": "火"}); !errors.Is(err, store.ErrInvalidNote) {
		t.Fatalf("missing meaning err = %v, want ErrInvalidNote", err)
	}

	duplicate, err := r.DuplicateExists(ctx, deckID, "水")
	if err != nil || !duplicate {
		t.Fatalf("duplicate = %v, err = %v", duplicate, err)
	}

	found, err := r.Search(ctx, deckID, "NƯỚC", 10, 0)
	if err != nil || len(found) != 1 {
		t.Fatalf("search = %+v, err = %v", found, err)
	}

	if err := r.DeleteNote(ctx, 12, note.ID); err != nil {
		t.Fatal(err)
	}
	duplicate, _ = r.DuplicateExists(ctx, deckID, "水")
	if duplicate {
		t.Fatal("deleted note still blocks duplicates")
	}
	if found, _ := r.Search(ctx, deckID, "水", 10, 0); len(found) != 0 {
		t.Fatalf("deleted note found = %+v", found)
	}
}

func TestSettingsScopeAndValidation(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)

	if value, err := r.Setting(ctx, "new_cards_per_day"); err != nil || value != "20" {
		t.Fatalf("default = %q, err = %v", value, err)
	}
	if err := r.SetSetting(ctx, 1, "new_cards_per_day", "30"); err != nil {
		t.Fatal(err)
	}
	if value, _ := r.Setting(ctx, "new_cards_per_day"); value != "30" {
		t.Fatalf("value = %q", value)
	}
	if err := r.SetSetting(ctx, 2, "new_cards_per_day", "1000"); !errors.Is(err, store.ErrInvalidSetting) {
		t.Fatalf("range err = %v", err)
	}
	if err := r.SetSetting(ctx, 3, "font_scale", "1.2"); !errors.Is(err, store.ErrUnknownSetting) {
		t.Fatalf("app-level err = %v", err)
	}
}

func TestPurgeDeletedRemovesOldRows(t *testing.T) {
	ctx := context.Background()
	s, r := openRepo(t)
	folderID, _ := seedDeck(t, r)
	if err := r.DeleteFolder(ctx, 100, folderID); err != nil {
		t.Fatal(err)
	}
	if err := r.PurgeDeleted(ctx, 200); err != nil {
		t.Fatal(err)
	}
	var live int
	if err := s.DB().QueryRow(`SELECT COUNT(*) FROM folders`).Scan(&live); err != nil {
		t.Fatal(err)
	}
	if live != 0 {
		t.Fatalf("folders left = %d", live)
	}
}

func TestUpdateNoteRecomputesSearch(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)
	_, deckID := seedDeck(t, r)
	note, err := r.CreateNote(ctx, 20, deckID, map[string]string{"nf-term": "山", "nf-meaning": "núi"})
	if err != nil {
		t.Fatal(err)
	}
	updated, err := r.UpdateNote(ctx, 21, note.ID, map[string]string{"nf-term": "川", "nf-meaning": "sông"})
	if err != nil {
		t.Fatal(err)
	}
	if updated.SortField != "川" || updated.SearchText != "川 sông" {
		t.Fatalf("updated = %+v", updated)
	}
	if old, _ := r.Search(ctx, deckID, "núi", 10, 0); len(old) != 0 {
		t.Fatalf("stale search hit = %+v", old)
	}
}

func TestDecksDefaultTypeAndReorder(t *testing.T) {
	ctx := context.Background()
	_, r := openRepo(t)
	folder, err := r.CreateFolder(ctx, 30, "F")
	if err != nil {
		t.Fatal(err)
	}
	first, err := r.CreateDeck(ctx, 31, store.Deck{FolderID: folder.ID, Name: "A"})
	if err != nil {
		t.Fatal(err)
	}
	if first.NoteTypeID != store.SystemNoteTypeID {
		t.Fatalf("note type = %q", first.NoteTypeID)
	}
	second, _ := r.CreateDeck(ctx, 32, store.Deck{FolderID: folder.ID, Name: "B"})
	if err := r.ReorderDecks(ctx, 33, []string{second.ID, first.ID}); err != nil {
		t.Fatal(err)
	}
	decks, _ := r.Decks(ctx, folder.ID)
	if decks[0].ID != second.ID {
		t.Fatalf("order = %+v", decks)
	}
}
