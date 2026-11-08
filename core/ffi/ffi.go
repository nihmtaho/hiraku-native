package main

/*
#include <stdlib.h>
#include <stdint.h>

typedef struct {
	uint8_t *data;
	uint64_t len;
} HKBytes;

typedef int64_t hk_handle;
*/
import "C"

import (
	"context"
	"sync"
	"unsafe"

	"google.golang.org/protobuf/proto"

	hirakuv1 "hiraku/core/gen/hirakuv1"
	"hiraku/core/service"
	"hiraku/core/store"
)

// The handle table is the one allowed mutable state; domain and service stay pure.
var (
	boundaryMu sync.Mutex
	boundary               = map[C.hk_handle]*store.Store{}
	nextHandle C.hk_handle = 1
)

//export hk_open
func hk_open(path *C.char, outHandle *C.hk_handle, outErr *C.HKBytes) (code C.int32_t) {
	defer func() {
		if recover() != nil {
			code = 5
		}
	}()
	*outErr = C.HKBytes{}
	if path == nil || outHandle == nil {
		return 1
	}
	dbPath := C.GoString(path)
	if dbPath == "" {
		return 1
	}
	opened, err := store.Open(dbPath)
	if err != nil {
		return 4
	}
	boundaryMu.Lock()
	handle := nextHandle
	nextHandle++
	boundary[handle] = opened
	boundaryMu.Unlock()
	*outHandle = handle
	return 0
}

//export hk_call
func hk_call(handle C.hk_handle, method C.uint32_t, req C.HKBytes, outResp *C.HKBytes) (code C.int32_t) {
	*outResp = C.HKBytes{}
	result, response, err := dispatch(uint64(handle), uint32(method), goBytes(req))
	if err != nil {
		encoded, marshalErr := proto.Marshal(&hirakuv1.Error{Code: err.Code, SubCode: err.SubCode})
		if marshalErr == nil {
			*outResp = cBytes(encoded)
		}
		return C.int32_t(result)
	}
	if len(response) > 0 {
		*outResp = cBytes(response)
	}
	return C.int32_t(result)
}

// dispatch maps one call to the service and never lets a panic cross the ABI.
func dispatch(handle uint64, method uint32, req []byte) (code int32, response []byte, contractErr *service.Error) {
	defer func() {
		if recover() != nil {
			code = 5
			response = nil
			contractErr = nil
		}
	}()
	boundaryMu.Lock()
	opened, ok := boundary[C.hk_handle(handle)]
	boundaryMu.Unlock()
	if !ok {
		return 1, nil, &service.Error{Code: hirakuv1.ErrorCode_ERROR_CODE_INVALID_ARGUMENT}
	}
	response, err := service.New(opened).Handle(context.Background(), hirakuv1.Method(method), req)
	if err != nil {
		contractErr = service.MapError(err)
		return int32(contractErr.Code), nil, contractErr
	}
	return 0, response, nil
}

//export hk_free
func hk_free(b C.HKBytes) {
	defer func() { _ = recover() }()
	if b.data == nil {
		return
	}
	C.free(unsafe.Pointer(b.data))
}

//export hk_close
func hk_close(h C.hk_handle) (code C.int32_t) {
	defer func() {
		if recover() != nil {
			code = 5
		}
	}()
	boundaryMu.Lock()
	opened, ok := boundary[h]
	delete(boundary, h)
	boundaryMu.Unlock()
	if !ok {
		return 1
	}
	if err := opened.Close(); err != nil {
		return 4
	}
	return 0
}

func goBytes(b C.HKBytes) []byte {
	if b.data == nil || b.len == 0 {
		return nil
	}
	return C.GoBytes(unsafe.Pointer(b.data), C.int(b.len))
}

func cBytes(data []byte) C.HKBytes {
	memory := C.malloc(C.size_t(len(data)))
	if memory == nil {
		return C.HKBytes{}
	}
	copy(unsafe.Slice((*byte)(memory), len(data)), data)
	return C.HKBytes{data: (*C.uint8_t)(memory), len: C.uint64_t(len(data))}
}

// main is required by -buildmode=c-archive.
func main() {}
