package service_test

import (
	"context"
	"errors"
	"testing"

	"hiraku/core/domain/notetype"
	hirakuv1 "hiraku/core/gen/hirakuv1"
	"hiraku/core/service"
	"hiraku/core/store"
)

func TestPing(t *testing.T) {
	s, err := store.Open(t.TempDir() + "/hiraku.sqlite")
	if err != nil {
		t.Fatal(err)
	}
	defer s.Close()
	response, err := service.New(s).Handle(context.Background(), hirakuv1.Method_METHOD_PING, nil)
	if err != nil || len(response) != 0 {
		t.Fatalf("ping = %v %v", response, err)
	}
}

func TestMapErrorUsesSubCode(t *testing.T) {
	mapped := service.MapError(notetype.ErrDuplicateName)
	if mapped.Code != hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE || mapped.SubCode != hirakuv1.ErrorSubCode_ERROR_SUB_CODE_DUPLICATE_NAME {
		t.Fatalf("mapped = %+v", mapped)
	}
	if service.MapError(store.ErrNotFound).Code != hirakuv1.ErrorCode_ERROR_CODE_NOT_FOUND {
		t.Fatal("not found not mapped")
	}
	if service.MapError(errors.New("boom")).Code != hirakuv1.ErrorCode_ERROR_CODE_STORAGE {
		t.Fatal("unknown not mapped to storage")
	}
}
