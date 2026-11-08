// Package id creates time-ordered UUIDv7 values without an extra dependency.
package id

import (
	"crypto/rand"
	"encoding/hex"
)

// New returns a UUIDv7 string for the given epoch milliseconds.
func New(nowMs int64) (string, error) {
	var b [16]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	b[0] = byte(nowMs >> 40)
	b[1] = byte(nowMs >> 32)
	b[2] = byte(nowMs >> 24)
	b[3] = byte(nowMs >> 16)
	b[4] = byte(nowMs >> 8)
	b[5] = byte(nowMs)
	b[6] = (b[6] & 0x0f) | 0x70
	b[8] = (b[8] & 0x3f) | 0x80
	var out [36]byte
	hex.Encode(out[0:8], b[0:4])
	out[8] = '-'
	hex.Encode(out[9:13], b[4:6])
	out[13] = '-'
	hex.Encode(out[14:18], b[6:8])
	out[18] = '-'
	hex.Encode(out[19:23], b[8:10])
	out[23] = '-'
	hex.Encode(out[24:36], b[10:16])
	return string(out[:]), nil
}
