package main

import (
	"testing"

	"google.golang.org/protobuf/proto"

	hirakuv1 "hiraku/core/gen/hirakuv1"
)

func TestGradeRequestRoundTrip(t *testing.T) {
	in := &hirakuv1.GradeRequest{CardId: "c1", Rating: hirakuv1.Rating_RATING_GOOD, NowMs: 1}
	b, err := proto.Marshal(in)
	if err != nil {
		t.Fatal(err)
	}
	var out hirakuv1.GradeRequest
	if err := proto.Unmarshal(b, &out); err != nil {
		t.Fatal(err)
	}
	if out.CardId != "c1" {
		t.Fatalf("card id = %q", out.CardId)
	}
}
