package service_test

import (
	"context"
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/proto"

	hirakuv1 "hiraku/core/gen/hirakuv1"
	"hiraku/core/service"
	"hiraku/core/store"
)

func newCatalog(t *testing.T) (*service.Service, context.Context) {
	t.Helper()
	s, err := store.Open(filepath.Join(t.TempDir(), "hiraku.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return service.New(s), context.Background()
}

func call[T proto.Message](t *testing.T, svc *service.Service, ctx context.Context, method hirakuv1.Method, request proto.Message, response T) T {
	t.Helper()
	body, err := proto.Marshal(request)
	if err != nil {
		t.Fatal(err)
	}
	out, err := svc.Handle(ctx, method, body)
	if err != nil {
		t.Fatalf("%v: %v", method, err)
	}
	if err := proto.Unmarshal(out, response); err != nil {
		t.Fatal(err)
	}
	return response
}

func TestFolderCreateRenameReorderAndDelete(t *testing.T) {
	svc, ctx := newCatalog(t)
	first := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "  N5  ", NowMs: 10}, &hirakuv1.CreateFolderResponse{})
	second := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "N4", NowMs: 11}, &hirakuv1.CreateFolderResponse{})

	if len(first.GetChanges().GetChanges()) != 1 || first.GetChanges().GetChanges()[0].GetEntity() != hirakuv1.EntityType_ENTITY_TYPE_FOLDER {
		t.Fatalf("create folder changes = %v", first.GetChanges())
	}
	call(t, svc, ctx, hirakuv1.Method_METHOD_UPDATE_FOLDER,
		&hirakuv1.UpdateFolderRequest{FolderId: first.GetFolderId(), Name: "N5 mới", NowMs: 12}, &hirakuv1.UpdateFolderResponse{})
	call(t, svc, ctx, hirakuv1.Method_METHOD_REORDER_FOLDERS,
		&hirakuv1.ReorderFoldersRequest{FolderIds: []string{second.GetFolderId(), first.GetFolderId()}, NowMs: 13},
		&hirakuv1.ReorderFoldersResponse{})

	folders := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_FOLDERS,
		&hirakuv1.ListFoldersRequest{}, &hirakuv1.ListFoldersResponse{})
	if len(folders.GetFolders()) != 2 {
		t.Fatalf("folders = %v", folders.GetFolders())
	}
	if folders.GetFolders()[0].GetId() != second.GetFolderId() || folders.GetFolders()[1].GetName() != "N5 mới" {
		t.Fatalf("folders order/name = %v", folders.GetFolders())
	}

	call(t, svc, ctx, hirakuv1.Method_METHOD_DELETE_FOLDER,
		&hirakuv1.DeleteFolderRequest{FolderId: first.GetFolderId(), NowMs: 14}, &hirakuv1.DeleteFolderResponse{})
	folders = call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_FOLDERS,
		&hirakuv1.ListFoldersRequest{}, &hirakuv1.ListFoldersResponse{})
	if len(folders.GetFolders()) != 1 {
		t.Fatalf("folders after delete = %v", folders.GetFolders())
	}
}

func TestFolderRejectsEmptyAndLongNames(t *testing.T) {
	svc, ctx := newCatalog(t)
	long := make([]rune, 101)
	for i := range long {
		long[i] = 'a'
	}
	for _, name := range []string{"   ", string(long)} {
		body, err := proto.Marshal(&hirakuv1.CreateFolderRequest{Name: name, NowMs: 10})
		if err != nil {
			t.Fatal(err)
		}
		if _, err := svc.Handle(ctx, hirakuv1.Method_METHOD_CREATE_FOLDER, body); err == nil {
			t.Fatalf("name %q accepted", name)
		}
	}
}

func TestDeckCreateMoveAndCounts(t *testing.T) {
	svc, ctx := newCatalog(t)
	origin := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "Gốc", NowMs: 10}, &hirakuv1.CreateFolderResponse{})
	target := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "Đích", NowMs: 11}, &hirakuv1.CreateFolderResponse{})
	deck := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_DECK,
		&hirakuv1.CreateDeckRequest{FolderId: origin.GetFolderId(), Name: "Động từ", NowMs: 12},
		&hirakuv1.CreateDeckResponse{})

	call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_NOTE, &hirakuv1.CreateNoteRequest{
		DeckId: deck.GetDeckId(),
		Fields: []*hirakuv1.FieldValue{
			{FieldId: "nf-term", Value: "食べる"},
			{FieldId: "nf-meaning", Value: "ăn"},
		},
		NowMs: 13,
	}, &hirakuv1.CreateNoteResponse{})

	decks := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_DECKS,
		&hirakuv1.ListDecksRequest{FolderId: origin.GetFolderId()}, &hirakuv1.ListDecksResponse{})
	if len(decks.GetDecks()) != 1 || decks.GetDecks()[0].GetNoteCount() != 1 || decks.GetDecks()[0].GetStateNewCount() != 1 {
		t.Fatalf("decks = %v", decks.GetDecks())
	}
	folders := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_FOLDERS,
		&hirakuv1.ListFoldersRequest{}, &hirakuv1.ListFoldersResponse{})
	if folders.GetFolders()[0].GetDeckCount() != 1 || folders.GetFolders()[0].GetNoteCount() != 1 {
		t.Fatalf("folder counts = %v", folders.GetFolders()[0])
	}

	call(t, svc, ctx, hirakuv1.Method_METHOD_MOVE_DECK,
		&hirakuv1.MoveDeckRequest{DeckId: deck.GetDeckId(), TargetFolderId: target.GetFolderId(), NowMs: 14},
		&hirakuv1.MoveDeckResponse{})
	originDecks := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_DECKS,
		&hirakuv1.ListDecksRequest{FolderId: origin.GetFolderId()}, &hirakuv1.ListDecksResponse{})
	moved := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_DECKS,
		&hirakuv1.ListDecksRequest{FolderId: target.GetFolderId()}, &hirakuv1.ListDecksResponse{})
	if len(originDecks.GetDecks()) != 0 || len(moved.GetDecks()) != 1 {
		t.Fatalf("after move: origin %v, target %v", originDecks.GetDecks(), moved.GetDecks())
	}
}

func TestDeletesReportMissingIdsAndRequireTime(t *testing.T) {
	svc, ctx := newCatalog(t)
	for _, call := range []struct {
		method  hirakuv1.Method
		request proto.Message
	}{
		{hirakuv1.Method_METHOD_DELETE_FOLDER, &hirakuv1.DeleteFolderRequest{FolderId: "missing", NowMs: 10}},
		{hirakuv1.Method_METHOD_DELETE_DECK, &hirakuv1.DeleteDeckRequest{DeckId: "missing", NowMs: 10}},
		{hirakuv1.Method_METHOD_CREATE_FOLDER, &hirakuv1.CreateFolderRequest{Name: "F", NowMs: 0}},
	} {
		body, err := proto.Marshal(call.request)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := svc.Handle(ctx, call.method, body); err == nil {
			t.Fatalf("%v accepted %v", call.method, call.request)
		}
	}
}

func TestReorderDecksNeedsTheFolder(t *testing.T) {
	svc, ctx := newCatalog(t)
	body, err := proto.Marshal(&hirakuv1.ReorderDecksRequest{DeckIds: []string{"d1"}, NowMs: 10})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.Handle(ctx, hirakuv1.Method_METHOD_REORDER_DECKS, body); err == nil {
		t.Fatal("reorder without a folder accepted")
	}
}

func TestNoteTypesExposeTheSystemType(t *testing.T) {
	svc, ctx := newCatalog(t)
	types := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_NOTE_TYPES,
		&hirakuv1.ListNoteTypesRequest{}, &hirakuv1.ListNoteTypesResponse{})
	if len(types.GetNoteTypes()) == 0 {
		t.Fatal("no note types")
	}
	system := types.GetNoteTypes()[0]
	if !system.GetIsSystem() || len(system.GetFields()) != 4 || system.GetTypingAnswerFieldId() != "nf-reading" {
		t.Fatalf("system type = %v", system)
	}
	if system.GetFields()[0].GetRole() != "term" || system.GetFields()[1].GetInputKind() != "kana" {
		t.Fatalf("field order/role = %v", system.GetFields())
	}
}

func TestNotesListSearchAndState(t *testing.T) {
	svc, ctx := newCatalog(t)
	folder := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "F", NowMs: 10}, &hirakuv1.CreateFolderResponse{})
	deck := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_DECK,
		&hirakuv1.CreateDeckRequest{FolderId: folder.GetFolderId(), Name: "D", NowMs: 11},
		&hirakuv1.CreateDeckResponse{})
	for _, word := range []struct{ term, meaning string }{{"水", "nước"}, {"火", "lửa"}} {
		call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_NOTE, &hirakuv1.CreateNoteRequest{
			DeckId: deck.GetDeckId(),
			Fields: []*hirakuv1.FieldValue{{FieldId: "nf-term", Value: word.term}, {FieldId: "nf-meaning", Value: word.meaning}},
			NowMs:  12,
		}, &hirakuv1.CreateNoteResponse{})
	}

	all := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_NOTES,
		&hirakuv1.ListNotesRequest{DeckId: deck.GetDeckId()}, &hirakuv1.ListNotesResponse{})
	if all.GetTotal() != 2 || len(all.GetNotes()) != 2 || all.GetNotes()[0].GetState() != hirakuv1.NoteState_NOTE_STATE_NEW {
		t.Fatalf("notes = %v", all)
	}
	if all.GetNotes()[0].GetFields()[0].GetFieldId() != "nf-term" {
		t.Fatalf("field order = %v", all.GetNotes()[0].GetFields())
	}

	found := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_NOTES,
		&hirakuv1.ListNotesRequest{DeckId: deck.GetDeckId(), Query: "lửa"}, &hirakuv1.ListNotesResponse{})
	if found.GetTotal() != 1 || found.GetNotes()[0].GetFields()[0].GetValue() != "火" {
		t.Fatalf("search = %v", found)
	}

	duplicate := call(t, svc, ctx, hirakuv1.Method_METHOD_CHECK_DUPLICATE,
		&hirakuv1.CheckDuplicateRequest{DeckId: deck.GetDeckId(), Term: " 火 "}, &hirakuv1.CheckDuplicateResponse{})
	if !duplicate.GetExists() || duplicate.GetMeaning() != "lửa" {
		t.Fatalf("duplicate = %v", duplicate)
	}
	missing := call(t, svc, ctx, hirakuv1.Method_METHOD_CHECK_DUPLICATE,
		&hirakuv1.CheckDuplicateRequest{DeckId: deck.GetDeckId(), Term: "空"}, &hirakuv1.CheckDuplicateResponse{})
	if missing.GetExists() {
		t.Fatalf("missing duplicate = %v", missing)
	}
}

func TestNoteDeleteHidesItFromTheList(t *testing.T) {
	svc, ctx := newCatalog(t)
	folder := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_FOLDER,
		&hirakuv1.CreateFolderRequest{Name: "F", NowMs: 10}, &hirakuv1.CreateFolderResponse{})
	deck := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_DECK,
		&hirakuv1.CreateDeckRequest{FolderId: folder.GetFolderId(), Name: "D", NowMs: 11},
		&hirakuv1.CreateDeckResponse{})
	note := call(t, svc, ctx, hirakuv1.Method_METHOD_CREATE_NOTE, &hirakuv1.CreateNoteRequest{
		DeckId: deck.GetDeckId(),
		Fields: []*hirakuv1.FieldValue{{FieldId: "nf-term", Value: "空"}, {FieldId: "nf-meaning", Value: "trống"}},
		NowMs:  12,
	}, &hirakuv1.CreateNoteResponse{})

	deleted := call(t, svc, ctx, hirakuv1.Method_METHOD_DELETE_NOTE,
		&hirakuv1.DeleteNoteRequest{NoteId: note.GetNoteId(), NowMs: 13}, &hirakuv1.DeleteNoteResponse{})
	if deleted.GetChanges().GetChanges()[0].GetKind() != hirakuv1.ChangeKind_CHANGE_KIND_DELETE {
		t.Fatalf("delete changes = %v", deleted.GetChanges())
	}
	all := call(t, svc, ctx, hirakuv1.Method_METHOD_LIST_NOTES,
		&hirakuv1.ListNotesRequest{DeckId: deck.GetDeckId()}, &hirakuv1.ListNotesResponse{})
	if all.GetTotal() != 0 || len(all.GetNotes()) != 0 {
		t.Fatalf("notes after delete = %v", all)
	}
}
