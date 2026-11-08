package main

import (
	"path/filepath"
	"testing"

	"google.golang.org/protobuf/proto"

	hirakuv1 "hiraku/core/gen/hirakuv1"
	"hiraku/core/store"
)

func openTestHandle(t *testing.T) uint64 {
	t.Helper()
	opened, err := store.Open(filepath.Join(t.TempDir(), "hiraku.sqlite"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { opened.Close() })
	boundaryMu.Lock()
	defer boundaryMu.Unlock()
	handle := nextHandle
	nextHandle++
	boundary[handle] = opened
	return uint64(handle)
}

func TestPingAndUnknownMethod(t *testing.T) {
	handle := openTestHandle(t)

	code, response, contractErr := dispatch(handle, uint32(hirakuv1.Method_METHOD_PING), nil)
	if code != 0 || len(response) != 0 || contractErr != nil {
		t.Fatalf("ping = %d %v %v", code, response, contractErr)
	}

	code, _, contractErr = dispatch(handle, 99, nil)
	if code != 2 || contractErr == nil || contractErr.Code != hirakuv1.ErrorCode_ERROR_CODE_NOT_FOUND {
		t.Fatalf("unknown = %d %+v", code, contractErr)
	}
}

func TestMalformedPingPayload(t *testing.T) {
	handle := openTestHandle(t)
	code, _, contractErr := dispatch(handle, uint32(hirakuv1.Method_METHOD_PING), []byte{0xff})
	if code != 1 || contractErr == nil {
		t.Fatalf("malformed = %d %+v", code, contractErr)
	}
}

func TestInvalidHandle(t *testing.T) {
	code, _, contractErr := dispatch(9999, uint32(hirakuv1.Method_METHOD_PING), nil)
	if code != 1 || contractErr == nil || contractErr.Code != hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT {
		t.Fatalf("invalid handle = %d %+v", code, contractErr)
	}
}

func TestErrorBodyRoundTrips(t *testing.T) {
	encoded, err := proto.Marshal(&hirakuv1.Error{Code: hirakuv1.ErrorCode_ERROR_CODE_BUSINESS_RULE, SubCode: hirakuv1.ErrorSubCode_ERROR_SUB_CODE_DUPLICATE_NAME})
	if err != nil {
		t.Fatal(err)
	}
	var decoded hirakuv1.Error
	if err := proto.Unmarshal(encoded, &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.SubCode != hirakuv1.ErrorSubCode_ERROR_SUB_CODE_DUPLICATE_NAME {
		t.Fatalf("sub code = %v", decoded.SubCode)
	}
}

func TestRepeatedPingsDoNotGrowHandles(t *testing.T) {
	handle := openTestHandle(t)
	boundaryMu.Lock()
	before := len(boundary)
	boundaryMu.Unlock()
	for range 1000 {
		if code, _, _ := dispatch(handle, uint32(hirakuv1.Method_METHOD_PING), nil); code != 0 {
			t.Fatalf("ping code = %d", code)
		}
	}
	boundaryMu.Lock()
	after := len(boundary)
	boundaryMu.Unlock()
	if before != after {
		t.Fatalf("handles grew from %d to %d", before, after)
	}
}
