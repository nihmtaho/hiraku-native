package service_test

import (
	"context"
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/proto"

	"hiraku/core/domain/fsrs"
	hirakuv1 "hiraku/core/gen/hirakuv1"
	"hiraku/core/service"
	"hiraku/core/store"
)

type fixture struct {
	store *store.Store
	ctx   context.Context
	deck  string
	card  string
}

func newFixture(t *testing.T) fixture {
	t.Helper()
	s, err := store.Open(filepath.Join(t.TempDir(), "hiraku.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	ctx := context.Background()
	repo := s.Repo()
	folder, err := repo.CreateFolder(ctx, 1, "F")
	if err != nil {
		t.Fatal(err)
	}
	deck, err := repo.CreateDeck(ctx, 2, store.Deck{FolderID: folder.ID, Name: "D"})
	if err != nil {
		t.Fatal(err)
	}
	note, err := repo.CreateNote(ctx, 3, deck.ID, map[string]string{"nf-term": "水", "nf-meaning": "nước"})
	if err != nil {
		t.Fatal(err)
	}
	return fixture{store: s, ctx: ctx, deck: deck.ID, card: note.ID}
}

func (f fixture) call(t *testing.T, method hirakuv1.Method, request proto.Message) ([]byte, *service.Error) {
	t.Helper()
	var body []byte
	if request != nil {
		encoded, err := proto.Marshal(request)
		if err != nil {
			t.Fatal(err)
		}
		body = encoded
	}
	response, err := service.New(f.store).Handle(f.ctx, method, body)
	if err == nil {
		return response, nil
	}
	var contract *service.Error
	if !asError(err, &contract) {
		t.Fatalf("error = %v", err)
	}
	return nil, contract
}

func asError(err error, target **service.Error) bool {
	if contract, ok := err.(*service.Error); ok {
		*target = contract
		return true
	}
	return false
}

func TestGradeNewCardAgain(t *testing.T) {
	f := newFixture(t)
	now := int64(1_000_000)
	body, contractErr := f.call(t, hirakuv1.Method_METHOD_GRADE, &hirakuv1.GradeRequest{
		CardId: f.card, Rating: hirakuv1.Rating_RATING_AGAIN, NowMs: now,
	})
	if contractErr != nil {
		t.Fatal(contractErr)
	}
	var response hirakuv1.GradeResponse
	if err := proto.Unmarshal(body, &response); err != nil {
		t.Fatal(err)
	}
	if response.NextDueMs != now+60_000 || !response.Reinsert {
		t.Fatalf("next due = %d, reinsert = %v", response.NextDueMs, response.Reinsert)
	}
	if len(response.Changes.GetChanges()) != 1 || response.Changes.Changes[0].Entity != hirakuv1.EntityType_ENTITY_TYPE_CARD {
		t.Fatalf("changes = %+v", response.Changes)
	}
	var prev int
	if err := f.store.DB().QueryRow(`SELECT prev_state FROM review_logs`).Scan(&prev); err != nil {
		t.Fatal(err)
	}
	if prev != 0 {
		t.Fatalf("prev_state = %d", prev)
	}
	card, exists, err := f.store.Repo().CardState(f.ctx, f.card)
	if err != nil || !exists || card.Reps != 1 || card.State != fsrs.StateLearning {
		t.Fatalf("state = %+v %v %v", card, exists, err)
	}
}

func TestGradeRejectsBadInput(t *testing.T) {
	f := newFixture(t)
	_, contractErr := f.call(t, hirakuv1.Method_METHOD_GRADE, &hirakuv1.GradeRequest{
		CardId: f.card, Rating: 9, NowMs: 1000,
	})
	if contractErr == nil || contractErr.Code != hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT {
		t.Fatalf("invalid rating = %+v", contractErr)
	}
	_, contractErr = f.call(t, hirakuv1.Method_METHOD_GRADE, &hirakuv1.GradeRequest{
		CardId: "missing", Rating: hirakuv1.Rating_RATING_GOOD, NowMs: 1000,
	})
	if contractErr == nil || contractErr.Code != hirakuv1.ErrorCode_ERROR_CODE_NOT_FOUND {
		t.Fatalf("missing card = %+v", contractErr)
	}
}

func TestBuildQueueRespectsNewLimit(t *testing.T) {
	f := newFixture(t)
	if err := f.store.Repo().SetSetting(f.ctx, 1, "new_cards_per_day", "1"); err != nil {
		t.Fatal(err)
	}
	second, err := f.store.Repo().CreateNote(f.ctx, 4, f.deck, map[string]string{"nf-term": "火", "nf-meaning": "lửa"})
	if err != nil {
		t.Fatal(err)
	}
	now := int64(1_000_000)
	body, contractErr := f.call(t, hirakuv1.Method_METHOD_BUILD_QUEUE, &hirakuv1.BuildQueueRequest{NowMs: now, Limit: 10})
	if contractErr != nil {
		t.Fatal(contractErr)
	}
	var queue hirakuv1.BuildQueueResponse
	if err := proto.Unmarshal(body, &queue); err != nil {
		t.Fatal(err)
	}
	if len(queue.Items) != 1 || queue.Items[0].CardId != f.card {
		t.Fatalf("queue = %+v", queue.Items)
	}
	if _, contractErr := f.call(t, hirakuv1.Method_METHOD_GRADE, &hirakuv1.GradeRequest{
		CardId: f.card, Rating: hirakuv1.Rating_RATING_AGAIN, NowMs: now,
	}); contractErr != nil {
		t.Fatal(contractErr)
	}
	body, _ = f.call(t, hirakuv1.Method_METHOD_BUILD_QUEUE, &hirakuv1.BuildQueueRequest{NowMs: now + 60_000, Limit: 10})
	queue.Reset()
	if err := proto.Unmarshal(body, &queue); err != nil {
		t.Fatal(err)
	}
	if len(queue.Items) != 1 || queue.Items[0].CardId != f.card {
		t.Fatalf("queue after grade = %+v", queue.Items)
	}
	for _, item := range queue.Items {
		if item.CardId == second.ID {
			t.Fatal("new card passed the exhausted daily limit")
		}
	}
}
