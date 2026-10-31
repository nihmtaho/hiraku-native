package main

import (
	"database/sql"

	_ "github.com/mattn/go-sqlite3"
)

// OpenMemory keeps the sqlite driver reachable so the archive link resolves it.
func OpenMemory() error {
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		return err
	}
	return db.Close()
}

// main is required by -buildmode=c-archive; the spike only verifies the link.
func main() {
	_ = OpenMemory()
}
