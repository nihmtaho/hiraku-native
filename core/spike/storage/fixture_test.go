package storage

import (
	"database/sql"
	"fmt"
	"math/rand/v2"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"testing"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

const (
	noteCount      = 50000
	cardCount      = 50000
	cardStateCount = 50000
	reviewLogCount = 200000
	deckCount      = 50
	folderCount    = 2
	seed1          = 20261030
	seed2          = 1
)

const schemaDDL = `
CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  position INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE note_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  is_system INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE note_type_fields (
  id TEXT PRIMARY KEY,
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  ord INTEGER NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  input_kind TEXT NOT NULL,
  required INTEGER NOT NULL,
  searchable INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE decks (
  id TEXT PRIMARY KEY,
  folder_id TEXT NOT NULL REFERENCES folders(id),
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  name TEXT NOT NULL,
  description TEXT,
  position INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE card_templates (
  id TEXT PRIMARY KEY,
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  front_fields TEXT NOT NULL,
  back_fields TEXT NOT NULL,
  typing_answer_field_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES decks(id),
  note_type_id TEXT NOT NULL REFERENCES note_types(id),
  fields TEXT NOT NULL,
  sort_field TEXT NOT NULL,
  search_text TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL REFERENCES notes(id),
  template_id TEXT NOT NULL REFERENCES card_templates(id),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  UNIQUE (note_id, template_id)
);
CREATE TABLE card_states (
  card_id TEXT PRIMARY KEY REFERENCES cards(id),
  state INTEGER NOT NULL,
  due INTEGER NOT NULL,
  stability REAL NOT NULL,
  difficulty REAL NOT NULL,
  elapsed_days INTEGER NOT NULL,
  scheduled_days INTEGER NOT NULL,
  learning_steps INTEGER NOT NULL,
  reps INTEGER NOT NULL,
  lapses INTEGER NOT NULL,
  last_review INTEGER,
  suspended INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE review_logs (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES cards(id),
  rating INTEGER NOT NULL,
  reviewed_at INTEGER NOT NULL,
  mode TEXT NOT NULL,
  elapsed_ms INTEGER NOT NULL,
  prev_state INTEGER NOT NULL,
  prev_due INTEGER NOT NULL,
  prev_stability REAL NOT NULL,
  prev_difficulty REAL NOT NULL,
  prev_learning_steps INTEGER NOT NULL,
  prev_reps INTEGER NOT NULL,
  prev_lapses INTEGER NOT NULL,
  prev_last_review INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER
);
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE INDEX idx_notes_deck ON notes (deck_id);
CREATE INDEX idx_notes_deck_sort ON notes (deck_id, sort_field);
CREATE INDEX idx_notes_updated ON notes (updated_at);
CREATE INDEX idx_cards_note ON cards (note_id);
CREATE INDEX idx_card_states_due ON card_states (due);
CREATE INDEX idx_card_states_state ON card_states (state);
CREATE INDEX idx_review_logs_card ON review_logs (card_id);
CREATE INDEX idx_review_logs_reviewed ON review_logs (reviewed_at);
`

var (
	fieldIDs = [4]string{"field-term", "field-reading", "field-meaning", "field-example"}
	kanji    = []string{"日", "本", "語", "学", "生", "時", "間", "人", "大", "小", "上", "下", "中", "前", "後", "東", "西", "南", "北", "花", "山", "川", "空", "海", "雨", "風", "月", "火", "水", "木", "金", "土"}
	kana     = []string{"にち", "ほん", "ご", "がく", "せい", "じ", "かん", "ひと", "だい", "しょう", "じょう", "げ", "ちゅう", "ぜん", "ご", "とう", "せい", "なん", "ぼく", "はな", "やま", "かわ", "そら", "うみ", "あめ", "かぜ", "つき", "ひ", "みず", "き", "かね", "つち"}
	meaning  = []string{"ngày", "sách", "tiếng", "học", "sinh", "thời", "gian", "người", "lớn", "nhỏ", "trên", "dưới", "giữa", "trước", "sau", "đông", "tây", "nam", "bắc", "hoa", "núi", "sông", "trời", "biển", "mưa", "gió", "trăng", "lửa", "nước", "cây", "vàng", "đất"}
)

func fixtureDir(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	root := filepath.Join(filepath.Dir(file), "..", "..", "..")
	dir := filepath.Join(root, ".agents", "tmp", "m0-04")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	return dir
}

func fixturePath(t *testing.T) string {
	return filepath.Join(fixtureDir(t), "hiraku-s1.sqlite")
}

func requireSpike(t *testing.T) {
	t.Helper()
	if os.Getenv("HIRAKU_SPIKE_S1") != "1" {
		t.Skip("set HIRAKU_SPIKE_S1=1 to run S-1 storage measurements")
	}
}

func openDB(t *testing.T, path string) *sql.DB {
	t.Helper()
	db, err := sql.Open("sqlite3", "file:"+path)
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	if _, err := db.Exec("PRAGMA busy_timeout = 5000"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("PRAGMA journal_mode = WAL"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("PRAGMA synchronous = FULL"); err != nil {
		t.Fatal(err)
	}
	if err := db.Ping(); err != nil {
		t.Fatal(err)
	}
	return db
}

func idOf(i int) string {
	return fmt.Sprintf("%08x-0000-7000-8000-%012x", i, i)
}

func buildFixture(t *testing.T, path string) time.Duration {
	t.Helper()
	removeDB(t, path)
	db, err := sql.Open("sqlite3", "file:"+path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	for _, pragma := range []string{
		"PRAGMA journal_mode = WAL",
		"PRAGMA synchronous = OFF",
		"PRAGMA busy_timeout = 5000",
	} {
		if _, err := db.Exec(pragma); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := db.Exec(schemaDDL); err != nil {
		t.Fatal(err)
	}

	base := time.Date(2026, 10, 30, 12, 0, 0, 0, time.UTC).UnixMilli()
	rng := rand.New(rand.NewPCG(seed1, seed2))
	start := time.Now()
	tx, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	fail := func(err error) {
		_ = tx.Rollback()
		t.Fatal(err)
	}

	mustExec := func(query string, args ...any) {
		t.Helper()
		if _, err := tx.Exec(query, args...); err != nil {
			fail(err)
		}
	}
	for i := 0; i < folderCount; i++ {
		mustExec(`INSERT INTO folders (id, name, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?)`,
			idOf(i), fmt.Sprintf("Thư mục %d", i+1), i+1, base, base)
	}
	mustExec(`INSERT INTO note_types (id, name, is_system, created_at, updated_at) VALUES (?, ?, 1, ?, ?)`,
		"nt-japanese", "Từ vựng Nhật", base, base)
	fieldRows := [][3]any{
		{fieldIDs[0], "term", "text"},
		{fieldIDs[1], "reading", "kana"},
		{fieldIDs[2], "meaning", "text"},
		{fieldIDs[3], "example", "text"},
	}
	required := []bool{true, false, true, false}
	searchable := []bool{true, true, true, false}
	for i, row := range fieldRows {
		mustExec(`INSERT INTO note_type_fields
			(id, note_type_id, ord, name, role, input_kind, required, searchable, created_at, updated_at)
			VALUES (?, 'nt-japanese', ?, ?, ?, ?, ?, ?, ?, ?)`,
			row[0], i+1, row[1], row[1], row[2], boolInt(required[i]), boolInt(searchable[i]), base, base)
	}
	mustExec(`INSERT INTO card_templates
		(id, note_type_id, front_fields, back_fields, typing_answer_field_id, created_at, updated_at)
		VALUES ('tmpl-japanese', 'nt-japanese', ?, ?, ?, ?, ?)`,
		`["field-term"]`, `["field-reading","field-meaning","field-example"]`, fieldIDs[1], base, base)

	for i := 0; i < deckCount; i++ {
		mustExec(`INSERT INTO decks (id, folder_id, note_type_id, name, description, position, created_at, updated_at)
			VALUES (?, ?, 'nt-japanese', ?, NULL, ?, ?, ?)`,
			idOf(1000+i), idOf(i%folderCount), fmt.Sprintf("Bộ %d", i+1), i+1, base, base)
	}

	noteStmt, err := tx.Prepare(`INSERT INTO notes
		(id, deck_id, note_type_id, fields, sort_field, search_text, created_at, updated_at)
		VALUES (?, ?, 'nt-japanese', ?, ?, ?, ?, ?)`)
	if err != nil {
		fail(err)
	}
	defer noteStmt.Close()
	cardStmt, err := tx.Prepare(`INSERT INTO cards (id, note_id, template_id, created_at, updated_at) VALUES (?, ?, 'tmpl-japanese', ?, ?)`)
	if err != nil {
		fail(err)
	}
	defer cardStmt.Close()
	stateStmt, err := tx.Prepare(`INSERT INTO card_states
		(card_id, state, due, stability, difficulty, elapsed_days, scheduled_days, learning_steps, reps, lapses, last_review, suspended, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?)`)
	if err != nil {
		fail(err)
	}
	defer stateStmt.Close()

	for i := 0; i < noteCount; i++ {
		a := rng.IntN(len(kanji))
		b := rng.IntN(len(kanji))
		c := rng.IntN(len(kanji))
		d := rng.IntN(len(kanji))
		term := kanji[a] + kanji[b] + kanji[c] + kanji[d]
		reading := kana[a] + kana[b] + kana[c] + kana[d]
		ex := kanji[b] + kanji[c] + "を" + meaning[a] + "。"
		fields := fmt.Sprintf(`{%q:%q,%q:%q,%q:%q,%q:%q}`,
			fieldIDs[0], term, fieldIDs[1], reading, fieldIDs[2], meaning[b]+" "+meaning[c], fieldIDs[3], ex)
		searchText := strings.ToLower(term + " " + reading + " " + meaning[b] + " " + meaning[c])
		createdAt := base - int64(noteCount-i)*60000
		updatedAt := base - rng.Int64N(int64(28*24*time.Hour/time.Millisecond))
		if _, err := noteStmt.Exec(idOf(i), idOf(1000+i%deckCount), fields, term, searchText, createdAt, updatedAt); err != nil {
			fail(err)
		}
		if _, err := cardStmt.Exec(idOf(i), idOf(i), base, base); err != nil {
			fail(err)
		}
		state := 2
		switch i % 10 {
		case 6, 7:
			state = 1
		case 8:
			state = 3
		}
		due := base + int64(rng.IntN(4801)-2400)*3600000
		if state == 1 || state == 3 {
			due = base + int64(rng.IntN(120)-60)*60000
		}
		if _, err := stateStmt.Exec(idOf(i), state, due, 1.5+rng.Float64()*30, 2+rng.Float64()*8,
			rng.IntN(60), rng.IntN(365), 0, rng.IntN(20), rng.IntN(5), base-int64(rng.IntN(60))*86400000, base, base); err != nil {
			fail(err)
		}
	}

	logStmt, err := tx.Prepare(`INSERT INTO review_logs
		(id, card_id, rating, reviewed_at, mode, elapsed_ms,
		 prev_state, prev_due, prev_stability, prev_difficulty, prev_learning_steps, prev_reps, prev_lapses, prev_last_review,
		 created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		fail(err)
	}
	defer logStmt.Close()
	for i := 0; i < reviewLogCount; i++ {
		card := i % cardCount
		rating := 1 + rng.IntN(4)
		reviewedAt := base - int64(i%180)*86400000 + int64(card)*1000
		mode := "flashcard"
		if i%5 == 0 {
			mode = "typing"
		}
		prevState := 2
		if i%7 == 0 {
			prevState = 1
		}
		if i%18000 == 0 {
			prevState = 0
		}
		prevDue := reviewedAt - int64(rng.IntN(10))*86400000
		if _, err := logStmt.Exec(
			fmt.Sprintf("log-%012d", i), idOf(card), rating, reviewedAt, mode, 800+rng.IntN(12000),
			prevState, prevDue, 1.5+rng.Float64()*30, 2+rng.Float64()*8, 0, rng.IntN(20), rng.IntN(5),
			reviewedAt-int64(rng.IntN(30))*86400000, reviewedAt, reviewedAt); err != nil {
			fail(err)
		}
	}

	if _, err := tx.Exec(`INSERT INTO settings (key, value, updated_at) VALUES
		('fsrs_retention', '0.9', ?), ('new_cards_per_day', '20', ?), ('day_start_hour', '4', ?)`,
		base, base, base); err != nil {
		fail(err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatal(err)
	}
	return time.Since(start)
}

func boolInt(v bool) int {
	if v {
		return 1
	}
	return 0
}

func removeDB(t *testing.T, path string) {
	t.Helper()
	for _, suffix := range []string{"", "-wal", "-shm"} {
		if err := os.Remove(path + suffix); err != nil && !os.IsNotExist(err) {
			t.Fatal(err)
		}
	}
}

func ensureFixture(t *testing.T) string {
	t.Helper()
	path := fixturePath(t)
	if _, err := os.Stat(path); err == nil {
		return path
	}
	t.Log("fixture missing; building it")
	buildFixture(t, path)
	return path
}

func copyFixture(t *testing.T, name string) string {
	t.Helper()
	src := ensureFixture(t)
	dst := filepath.Join(fixtureDir(t), name)
	removeDB(t, dst)
	body, err := os.ReadFile(src)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(dst, body, 0o644); err != nil {
		t.Fatal(err)
	}
	return dst
}

func tableCounts(t *testing.T, db *sql.DB) map[string]int {
	t.Helper()
	counts := make(map[string]int)
	for _, table := range []string{"folders", "note_types", "note_type_fields", "decks", "card_templates", "notes", "cards", "card_states", "review_logs", "settings"} {
		var n int
		if err := db.QueryRow("SELECT COUNT(*) FROM " + table).Scan(&n); err != nil {
			t.Fatal(err)
		}
		counts[table] = n
	}
	return counts
}

func fileSizes(t *testing.T, path string) (main, wal, shm int64) {
	t.Helper()
	size := func(suffix string) int64 {
		info, err := os.Stat(path + suffix)
		if os.IsNotExist(err) {
			return 0
		}
		if err != nil {
			t.Fatal(err)
		}
		return info.Size()
	}
	return size(""), size("-wal"), size("-shm")
}

func TestBuildFixture(t *testing.T) {
	requireSpike(t)
	path := fixturePath(t)
	elapsed := buildFixture(t, path)
	t.Logf("build: %s (seed %d/%d)", elapsed, seed1, seed2)

	db, err := sql.Open("sqlite3", "file:"+path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	counts := tableCounts(t, db)
	for _, table := range []string{"folders", "note_types", "note_type_fields", "decks", "card_templates", "notes", "cards", "card_states", "review_logs", "settings"} {
		t.Logf("count %-16s %d", table, counts[table])
	}
	want := map[string]int{"notes": noteCount, "cards": cardCount, "card_states": cardStateCount, "review_logs": reviewLogCount, "decks": deckCount, "folders": folderCount}
	for table, n := range want {
		if counts[table] != n {
			t.Fatalf("%s = %d, want %d", table, counts[table], n)
		}
	}

	var logical int64
	if err := db.QueryRow("SELECT page_count * page_size FROM pragma_page_count(), pragma_page_size()").Scan(&logical); err != nil {
		t.Fatal(err)
	}
	main, wal, shm := fileSizes(t, path)
	t.Logf("size before VACUUM: logical=%d main=%d wal=%d shm=%d", logical, main, wal, shm)

	if _, err := db.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("VACUUM"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("PRAGMA wal_checkpoint(TRUNCATE)"); err != nil {
		t.Fatal(err)
	}
	main, wal, shm = fileSizes(t, path)
	t.Logf("size after CHECKPOINT+VACUUM: main=%d wal=%d shm=%d", main, wal, shm)

	var notesFingerprint, logsFingerprint string
	if err := db.QueryRow(`SELECT COUNT(*) || ':' || COALESCE(SUM(updated_at),0) || ':' || COALESCE(SUM(LENGTH(fields) + LENGTH(search_text)),0) FROM notes`).Scan(&notesFingerprint); err != nil {
		t.Fatal(err)
	}
	if err := db.QueryRow(`SELECT COUNT(*) || ':' || COALESCE(SUM(reviewed_at),0) || ':' || COALESCE(SUM(rating),0) FROM review_logs`).Scan(&logsFingerprint); err != nil {
		t.Fatal(err)
	}
	t.Logf("fingerprint notes=%s logs=%s", notesFingerprint, logsFingerprint)

	if err := os.WriteFile(filepath.Join(fixtureDir(t), "schema.sql"), []byte(schemaDDL), 0o644); err != nil {
		t.Fatal(err)
	}
}

type samples []time.Duration

func (s samples) report(t *testing.T, label string) {
	t.Helper()
	sorted := append(samples(nil), s...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i] < sorted[j] })
	median := sorted[(len(sorted)-1)/2]
	p95 := sorted[(len(sorted)*95+99)/100-1]
	var total time.Duration
	for _, d := range sorted {
		total += d
	}
	t.Logf("%-34s n=%d median=%s p95=%s max=%s mean=%s", label, len(sorted), median, p95, sorted[len(sorted)-1], total/time.Duration(len(sorted)))
}

func percentile(t *testing.T, label string, n int, run func() error) samples {
	t.Helper()
	out := make(samples, 0, n)
	for i := 0; i < n; i++ {
		start := time.Now()
		if err := run(); err != nil {
			t.Fatalf("%s run %d: %v", label, i, err)
		}
		out = append(out, time.Since(start))
	}
	return out
}

func explain(t *testing.T, db *sql.DB, query string, args ...any) {
	t.Helper()
	rows, err := db.Query("EXPLAIN QUERY PLAN "+query, args...)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var id, parent, unused int
		var detail string
		if err := rows.Scan(&id, &parent, &unused, &detail); err != nil {
			t.Fatal(err)
		}
		t.Logf("plan: %s", detail)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
}
