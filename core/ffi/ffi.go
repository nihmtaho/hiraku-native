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
	"database/sql"
	"sync"
	"unsafe"

	_ "github.com/mattn/go-sqlite3"
)

// Spike-only bridge: hk_call accepts only "ping" and answers with empty bytes.
// The real hiraku.v1 contract (method enum, protobuf payloads) arrives in WP-01.
//
// The handle table is the one allowed mutable in ffi; domain/service stays untouched.
var (
	boundaryMu sync.Mutex
	boundary   = map[C.hk_handle]*sql.DB{}
	nextHandle C.hk_handle = 1
)

//export hk_open
func hk_open(path *C.char, outHandle *C.hk_handle, outErr *C.HKBytes) (code C.int) {
	defer func() {
		if recover() != nil {
			code = 5
			*outErr = C.HKBytes{data: nil, len: 0}
		}
	}()
	*outErr = C.HKBytes{data: nil, len: 0}
	if path == nil || outHandle == nil {
		return 1
	}
	p := C.GoString(path)
	if p == "" {
		return 1
	}
	db, err := sql.Open("sqlite3", p)
	if err != nil {
		return 4
	}
	if err := db.Ping(); err != nil {
		db.Close()
		return 4
	}
	boundaryMu.Lock()
	h := nextHandle
	nextHandle++
	boundary[h] = db
	boundaryMu.Unlock()
	*outHandle = h
	return 0
}

//export hk_call
func hk_call(h C.hk_handle, method *C.char, req C.HKBytes, outResp *C.HKBytes) (code C.int) {
	defer func() {
		if recover() != nil {
			code = 5
			*outResp = C.HKBytes{data: nil, len: 0}
		}
	}()
	_ = req // spike: empty payload in, empty payload out
	*outResp = C.HKBytes{data: nil, len: 0}
	if method == nil || outResp == nil {
		return 1
	}
	if C.GoString(method) != "ping" {
		return 1
	}
	boundaryMu.Lock()
	db, ok := boundary[h]
	boundaryMu.Unlock()
	if !ok || db == nil {
		return 1
	}
	if err := db.Ping(); err != nil {
		return 4
	}
	return 0
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
func hk_close(h C.hk_handle) (code C.int) {
	defer func() {
		if recover() != nil {
			code = 5
		}
	}()
	boundaryMu.Lock()
	db, ok := boundary[h]
	delete(boundary, h)
	boundaryMu.Unlock()
	if !ok {
		return 1
	}
	if err := db.Close(); err != nil {
		return 4
	}
	return 0
}

// main is required by -buildmode=c-archive; the spike links the driver.
func main() {
	_ = sql.ErrNoRows
}
