// Package dayboundary computes hiraku study days that start at day_start_hour.
package dayboundary

const dayMs int64 = 86_400_000

// Start returns the first millisecond of the study day containing nowMs.
func Start(nowMs int64, dayStartHour int) int64 {
	return Index(nowMs, dayStartHour)*dayMs + int64(dayStartHour)*3_600_000
}

// End returns the first millisecond of the next study day.
func End(nowMs int64, dayStartHour int) int64 {
	return Start(nowMs, dayStartHour) + dayMs
}

// Index counts study days since the epoch.
func Index(nowMs int64, dayStartHour int) int64 {
	shifted := nowMs - int64(dayStartHour)*3_600_000
	q := shifted / dayMs
	if shifted%dayMs != 0 && shifted < 0 {
		q--
	}
	return q
}
