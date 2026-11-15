package service

import (
	"context"
	"strings"

	"google.golang.org/protobuf/proto"

	"hiraku/core/store"

	hirakuv1 "hiraku/core/gen/hirakuv1"
)

const maxNameLength = 100

// catalog dispatches the folder, deck, note-type and note methods; handled is false for the rest.
func (s *Service) catalog(ctx context.Context, method hirakuv1.Method, req []byte) (proto.Message, bool, error) {
	switch method {
	case hirakuv1.Method_METHOD_LIST_FOLDERS:
		var request hirakuv1.ListFoldersRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.listFolders(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_CREATE_FOLDER:
		var request hirakuv1.CreateFolderRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.createFolder(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_UPDATE_FOLDER:
		var request hirakuv1.UpdateFolderRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.updateFolder(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_DELETE_FOLDER:
		var request hirakuv1.DeleteFolderRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.deleteFolder(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_REORDER_FOLDERS:
		var request hirakuv1.ReorderFoldersRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.reorderFolders(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_LIST_DECKS:
		var request hirakuv1.ListDecksRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.listDecks(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_CREATE_DECK:
		var request hirakuv1.CreateDeckRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.createDeck(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_UPDATE_DECK:
		var request hirakuv1.UpdateDeckRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.updateDeck(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_DELETE_DECK:
		var request hirakuv1.DeleteDeckRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.deleteDeck(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_REORDER_DECKS:
		var request hirakuv1.ReorderDecksRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.reorderDecks(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_MOVE_DECK:
		var request hirakuv1.MoveDeckRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.moveDeck(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_LIST_NOTE_TYPES:
		var request hirakuv1.ListNoteTypesRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.listNoteTypes(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_LIST_NOTES:
		var request hirakuv1.ListNotesRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.listNotes(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_CREATE_NOTE:
		var request hirakuv1.CreateNoteRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.createNote(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_UPDATE_NOTE:
		var request hirakuv1.UpdateNoteRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.updateNote(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_DELETE_NOTE:
		var request hirakuv1.DeleteNoteRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.deleteNote(ctx, &request)
		return response, true, err
	case hirakuv1.Method_METHOD_CHECK_DUPLICATE:
		var request hirakuv1.CheckDuplicateRequest
		if !decode(req, &request) {
			return nil, true, invalidArgument()
		}
		response, err := s.checkDuplicate(ctx, &request)
		return response, true, err
	default:
		return nil, false, nil
	}
}

func decode(req []byte, message proto.Message) bool {
	return proto.Unmarshal(req, message) == nil
}

func (s *Service) listFolders(ctx context.Context, _ *hirakuv1.ListFoldersRequest) (*hirakuv1.ListFoldersResponse, error) {
	folders, err := s.repo.Folders(ctx)
	if err != nil {
		return nil, MapError(err)
	}
	response := &hirakuv1.ListFoldersResponse{}
	for _, folder := range folders {
		response.Folders = append(response.Folders, &hirakuv1.Folder{
			Id:        folder.ID,
			Name:      folder.Name,
			Position:  int32(folder.Position),
			DeckCount: int32(folder.DeckCount),
			NoteCount: int32(folder.NoteCount),
		})
	}
	return response, nil
}

func (s *Service) createFolder(ctx context.Context, req *hirakuv1.CreateFolderRequest) (*hirakuv1.CreateFolderResponse, error) {
	name, err := folderName(req.GetName())
	if err != nil {
		return nil, err
	}
	if req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	folder, err := s.repo.CreateFolder(ctx, req.GetNowMs(), name)
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.CreateFolderResponse{
		FolderId: folder.ID,
		Changes:  changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_FOLDER, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, folder.ID)),
	}, nil
}

func (s *Service) updateFolder(ctx context.Context, req *hirakuv1.UpdateFolderRequest) (*hirakuv1.UpdateFolderResponse, error) {
	name, err := folderName(req.GetName())
	if err != nil {
		return nil, err
	}
	if req.GetFolderId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	err = s.repo.UpdateFolder(ctx, req.GetNowMs(), store.Folder{ID: req.GetFolderId(), Name: name})
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.UpdateFolderResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_FOLDER, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, req.GetFolderId())),
	}, nil
}

func (s *Service) deleteFolder(ctx context.Context, req *hirakuv1.DeleteFolderRequest) (*hirakuv1.DeleteFolderResponse, error) {
	if req.GetFolderId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.FolderExists(ctx, req.GetFolderId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	decks, err := s.repo.Decks(ctx, req.GetFolderId())
	if err != nil {
		return nil, MapError(err)
	}
	if err := s.repo.DeleteFolder(ctx, req.GetNowMs(), req.GetFolderId()); err != nil {
		return nil, MapError(err)
	}
	// Cascade deletes reach the notes through their deck, so the changes name the folder and its decks.
	changes := []*hirakuv1.Change{change(hirakuv1.EntityType_ENTITY_TYPE_FOLDER, hirakuv1.ChangeKind_CHANGE_KIND_DELETE, req.GetFolderId())}
	for _, deck := range decks {
		changes = append(changes, change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_DELETE, deck.ID))
	}
	return &hirakuv1.DeleteFolderResponse{Changes: changeSet(changes...)}, nil
}

func (s *Service) reorderFolders(ctx context.Context, req *hirakuv1.ReorderFoldersRequest) (*hirakuv1.ReorderFoldersResponse, error) {
	if len(req.GetFolderIds()) == 0 || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	if err := s.repo.ReorderFolders(ctx, req.GetNowMs(), req.GetFolderIds()); err != nil {
		return nil, MapError(err)
	}
	changes := make([]*hirakuv1.Change, 0, len(req.GetFolderIds()))
	for _, folderID := range req.GetFolderIds() {
		changes = append(changes, change(hirakuv1.EntityType_ENTITY_TYPE_FOLDER, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, folderID))
	}
	return &hirakuv1.ReorderFoldersResponse{Changes: changeSet(changes...)}, nil
}

func (s *Service) listDecks(ctx context.Context, req *hirakuv1.ListDecksRequest) (*hirakuv1.ListDecksResponse, error) {
	decks, err := s.repo.Decks(ctx, req.GetFolderId())
	if err != nil {
		return nil, MapError(err)
	}
	response := &hirakuv1.ListDecksResponse{}
	for _, deck := range decks {
		response.Decks = append(response.Decks, &hirakuv1.Deck{
			Id:                 deck.ID,
			FolderId:           deck.FolderID,
			Name:               deck.Name,
			Description:        deck.Description,
			Position:           int32(deck.Position),
			NoteTypeId:         deck.NoteTypeID,
			NoteCount:          int32(deck.NoteCount),
			StateNewCount:      int32(deck.StateNew),
			StateLearningCount: int32(deck.StateLearn),
			StateKnownCount:    int32(deck.StateKnown),
		})
	}
	return response, nil
}

func (s *Service) createDeck(ctx context.Context, req *hirakuv1.CreateDeckRequest) (*hirakuv1.CreateDeckResponse, error) {
	name, err := folderName(req.GetName())
	if err != nil {
		return nil, err
	}
	if req.GetFolderId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.FolderExists(ctx, req.GetFolderId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	deck, err := s.repo.CreateDeck(ctx, req.GetNowMs(), store.Deck{
		FolderID:    req.GetFolderId(),
		Name:        name,
		Description: req.GetDescription(),
		NoteTypeID:  req.GetNoteTypeId(),
	})
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.CreateDeckResponse{
		DeckId:  deck.ID,
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, deck.ID)),
	}, nil
}

func (s *Service) updateDeck(ctx context.Context, req *hirakuv1.UpdateDeckRequest) (*hirakuv1.UpdateDeckResponse, error) {
	name, err := folderName(req.GetName())
	if err != nil {
		return nil, err
	}
	if req.GetDeckId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	err = s.repo.UpdateDeck(ctx, req.GetNowMs(), store.Deck{
		ID:          req.GetDeckId(),
		Name:        name,
		Description: req.GetDescription(),
	})
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.UpdateDeckResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, req.GetDeckId())),
	}, nil
}

func (s *Service) deleteDeck(ctx context.Context, req *hirakuv1.DeleteDeckRequest) (*hirakuv1.DeleteDeckResponse, error) {
	if req.GetDeckId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.DeckExists(ctx, req.GetDeckId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	if err := s.repo.DeleteDeck(ctx, req.GetNowMs(), req.GetDeckId()); err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.DeleteDeckResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_DELETE, req.GetDeckId())),
	}, nil
}

func (s *Service) reorderDecks(ctx context.Context, req *hirakuv1.ReorderDecksRequest) (*hirakuv1.ReorderDecksResponse, error) {
	if req.GetFolderId() == "" || len(req.GetDeckIds()) == 0 || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	if err := s.repo.ReorderDecks(ctx, req.GetNowMs(), req.GetDeckIds()); err != nil {
		return nil, MapError(err)
	}
	changes := make([]*hirakuv1.Change, 0, len(req.GetDeckIds()))
	for _, deckID := range req.GetDeckIds() {
		changes = append(changes, change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, deckID))
	}
	return &hirakuv1.ReorderDecksResponse{Changes: changeSet(changes...)}, nil
}

func (s *Service) moveDeck(ctx context.Context, req *hirakuv1.MoveDeckRequest) (*hirakuv1.MoveDeckResponse, error) {
	if req.GetDeckId() == "" || req.GetTargetFolderId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.FolderExists(ctx, req.GetTargetFolderId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	if err := s.repo.MoveDeck(ctx, req.GetNowMs(), req.GetDeckId(), req.GetTargetFolderId()); err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.MoveDeckResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_DECK, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, req.GetDeckId())),
	}, nil
}

func (s *Service) listNoteTypes(ctx context.Context, _ *hirakuv1.ListNoteTypesRequest) (*hirakuv1.ListNoteTypesResponse, error) {
	types, err := s.repo.NoteTypes(ctx)
	if err != nil {
		return nil, MapError(err)
	}
	response := &hirakuv1.ListNoteTypesResponse{}
	for _, noteType := range types {
		response.NoteTypes = append(response.NoteTypes, &hirakuv1.NoteType{
			Id:                  noteType.ID,
			Name:                noteType.Name,
			IsSystem:            noteType.IsSystem,
			Fields:              protoFields(noteType),
			FrontFieldIds:       noteType.FrontFieldIDs,
			BackFieldIds:        noteType.BackFieldIDs,
			TypingAnswerFieldId: noteType.AnswerFieldID,
		})
	}
	return response, nil
}

func (s *Service) listNotes(ctx context.Context, req *hirakuv1.ListNotesRequest) (*hirakuv1.ListNotesResponse, error) {
	if req.GetDeckId() == "" {
		return nil, invalidArgument()
	}
	limit := req.GetLimit()
	if limit <= 0 {
		limit = 100
	}
	if limit > 500 {
		limit = 500
	}
	offset := max(req.GetOffset(), 0)
	query := strings.TrimSpace(req.GetQuery())
	var notes []store.Note
	var err error
	if query == "" {
		notes, err = s.repo.Notes(ctx, req.GetDeckId(), int(limit), int(offset))
	} else {
		notes, err = s.repo.Search(ctx, req.GetDeckId(), query, int(limit), int(offset))
	}
	if err != nil {
		return nil, MapError(err)
	}
	total, err := s.repo.CountNotes(ctx, req.GetDeckId(), query)
	if err != nil {
		return nil, MapError(err)
	}
	orders := map[string][]string{}
	response := &hirakuv1.ListNotesResponse{Total: int32(total)}
	for _, note := range notes {
		order, cached := orders[note.NoteTypeID]
		if !cached {
			fields, err := s.repo.Fields(ctx, note.NoteTypeID)
			if err != nil {
				return nil, MapError(err)
			}
			for _, field := range fields {
				order = append(order, field.ID)
			}
			orders[note.NoteTypeID] = order
		}
		response.Notes = append(response.Notes, &hirakuv1.Note{
			Id:     note.ID,
			DeckId: note.DeckID,
			Fields: noteFieldValues(note.Fields, order),
			State:  noteState(note.State),
		})
	}
	return response, nil
}

func (s *Service) createNote(ctx context.Context, req *hirakuv1.CreateNoteRequest) (*hirakuv1.CreateNoteResponse, error) {
	if req.GetDeckId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.DeckExists(ctx, req.GetDeckId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	note, err := s.repo.CreateNote(ctx, req.GetNowMs(), req.GetDeckId(), fieldValues(req.GetFields()))
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.CreateNoteResponse{
		NoteId:  note.ID,
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_NOTE, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, note.ID)),
	}, nil
}

func (s *Service) updateNote(ctx context.Context, req *hirakuv1.UpdateNoteRequest) (*hirakuv1.UpdateNoteResponse, error) {
	if req.GetNoteId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	if _, err := s.repo.UpdateNote(ctx, req.GetNowMs(), req.GetNoteId(), fieldValues(req.GetFields())); err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.UpdateNoteResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_NOTE, hirakuv1.ChangeKind_CHANGE_KIND_UPSERT, req.GetNoteId())),
	}, nil
}

func (s *Service) deleteNote(ctx context.Context, req *hirakuv1.DeleteNoteRequest) (*hirakuv1.DeleteNoteResponse, error) {
	if req.GetNoteId() == "" || req.GetNowMs() <= 0 {
		return nil, invalidArgument()
	}
	exists, err := s.repo.NoteExists(ctx, req.GetNoteId())
	if err != nil {
		return nil, MapError(err)
	}
	if !exists {
		return nil, MapError(store.ErrNotFound)
	}
	if err := s.repo.DeleteNote(ctx, req.GetNowMs(), req.GetNoteId()); err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.DeleteNoteResponse{
		Changes: changeSet(change(hirakuv1.EntityType_ENTITY_TYPE_NOTE, hirakuv1.ChangeKind_CHANGE_KIND_DELETE, req.GetNoteId())),
	}, nil
}

func (s *Service) checkDuplicate(ctx context.Context, req *hirakuv1.CheckDuplicateRequest) (*hirakuv1.CheckDuplicateResponse, error) {
	if req.GetDeckId() == "" || strings.TrimSpace(req.GetTerm()) == "" {
		return nil, invalidArgument()
	}
	meaning, exists, err := s.repo.DuplicateMeaning(ctx, req.GetDeckId(), req.GetTerm())
	if err != nil {
		return nil, MapError(err)
	}
	return &hirakuv1.CheckDuplicateResponse{Exists: exists, Meaning: meaning}, nil
}

func folderName(raw string) (string, error) {
	name := strings.TrimSpace(raw)
	if name == "" || len([]rune(name)) > maxNameLength {
		return "", invalidArgument()
	}
	return name, nil
}

func invalidArgument() *Error {
	return &Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
}

func changeSet(changes ...*hirakuv1.Change) *hirakuv1.ChangeSet {
	return &hirakuv1.ChangeSet{Changes: changes}
}

func change(entity hirakuv1.EntityType, kind hirakuv1.ChangeKind, id string) *hirakuv1.Change {
	return &hirakuv1.Change{Entity: entity, Kind: kind, EntityId: id}
}

func protoFields(noteType store.NoteType) []*hirakuv1.NoteTypeField {
	fields := make([]*hirakuv1.NoteTypeField, 0, len(noteType.Fields))
	for _, field := range noteType.Fields {
		fields = append(fields, &hirakuv1.NoteTypeField{
			Id:         field.ID,
			Role:       string(field.Role),
			Name:       field.Name,
			Ord:        int32(field.Ord),
			InputKind:  field.InputKind,
			Required:   field.Required,
			Searchable: field.Searchable,
		})
	}
	return fields
}

func fieldValues(fields []*hirakuv1.FieldValue) map[string]string {
	values := make(map[string]string, len(fields))
	for _, field := range fields {
		values[field.GetFieldId()] = field.GetValue()
	}
	return values
}

func noteFieldValues(fields map[string]string, order []string) []*hirakuv1.FieldValue {
	values := make([]*hirakuv1.FieldValue, 0, len(fields))
	for _, fieldID := range order {
		if value, ok := fields[fieldID]; ok {
			values = append(values, &hirakuv1.FieldValue{FieldId: fieldID, Value: value})
		}
	}
	return values
}

func noteState(state int) hirakuv1.NoteState {
	switch state {
	case 1, 3:
		return hirakuv1.NoteState_NOTE_STATE_LEARNING
	case 2:
		return hirakuv1.NoteState_NOTE_STATE_KNOWN
	default:
		return hirakuv1.NoteState_NOTE_STATE_NEW
	}
}
