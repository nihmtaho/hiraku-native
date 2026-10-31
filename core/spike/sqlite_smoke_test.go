package spike

import (
	"database/sql"
	"testing"

	_ "github.com/mattn/go-sqlite3"
)

func TestSQLiteRoundTrip(t *testing.T) {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	if _, err := db.Exec("CREATE TABLE t (v TEXT NOT NULL)"); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("INSERT INTO t (v) VALUES (?)", "hiraku"); err != nil {
		t.Fatal(err)
	}

	var got string
	if err := db.QueryRow("SELECT v FROM t").Scan(&got); err != nil {
		t.Fatal(err)
	}
	if got != "hiraku" {
		t.Fatalf("got %q, want %q", got, "hiraku")
	}
}
