package dayboundary

import (
	"testing"
	"time"
)

func ms(hour, minute int) int64 {
	return time.Date(2026, 11, 1, hour, minute, 0, 0, time.UTC).UnixMilli()
}

func TestStartAndEndAtFour(t *testing.T) {
	start := Start(ms(3, 55), 4)
	if start != time.Date(2026, 10, 31, 4, 0, 0, 0, time.UTC).UnixMilli() {
		t.Fatalf("start = %v", time.UnixMilli(start).UTC())
	}
	if End(ms(3, 55), 4) != start+dayMs {
		t.Fatal("end is not one day after start")
	}
	if Start(ms(4, 5), 4) != time.Date(2026, 11, 1, 4, 0, 0, 0, time.UTC).UnixMilli() {
		t.Fatal("04:05 should be in the new day")
	}
}

func TestMidnightStaysInSameStudyDay(t *testing.T) {
	if Index(ms(23, 55), 4) != Index(time.Date(2026, 11, 2, 0, 5, 0, 0, time.UTC).UnixMilli(), 4) {
		t.Fatal("00:05 must stay in the 04:00 day")
	}
}
