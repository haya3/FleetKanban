// Package store persists FleetKanban state to a local SQLite database.
//
// The store splits reads and writes into two *sql.DB handles over the same
// file (WAL mode). Writes are serialized through a single connection to
// avoid SQLite's writer-lock contention; reads use the default pool size
// and run concurrently against WAL snapshots.
//
// modernc.org/sqlite is used for a pure-Go build (no CGO). The driver name
// registered by the import is "sqlite".
package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite" // registers the "sqlite" driver
)

// DB is a FleetKanban SQLite handle pair: a serialized writer and a pooled
// reader. Close must be called at shutdown.
type DB struct {
	write *sql.DB
	read  *sql.DB
	path  string
}

// Options configures Open.
type Options struct {
	// Path is the absolute path to the SQLite file. Parent directories are
	// created if missing. Use ":memory:" for ephemeral (test) databases.
	Path string
	// BusyTimeout for the SQLite busy handler. Defaults to 5s.
	BusyTimeout time.Duration
}

// Open opens (or creates) the SQLite database, applies the required PRAGMAs,
// and runs schema migrations. The returned DB is ready for concurrent read
// and serialized write use.
func Open(ctx context.Context, opts Options) (*DB, error) {
	if opts.Path == "" {
		return nil, errors.New("store: Path is required")
	}
	if opts.BusyTimeout == 0 {
		opts.BusyTimeout = 5 * time.Second
	}
	if opts.Path != ":memory:" {
		if err := os.MkdirAll(filepath.Dir(opts.Path), 0o755); err != nil {
			return nil, fmt.Errorf("store: create parent dir: %w", err)
		}
	}

	// The DSN "file:<path>?_busy_timeout=..." is understood by modernc/sqlite.
	// journal_mode=WAL must be set via PRAGMA on an open connection; passing
	// it as a query parameter is unreliable across driver versions.
	dsn := fmt.Sprintf("file:%s?_pragma=busy_timeout(%d)&_pragma=foreign_keys(1)",
		opts.Path, opts.BusyTimeout.Milliseconds())

	writeDB, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("store: open write handle: %w", err)
	}
	writeDB.SetMaxOpenConns(1)
	writeDB.SetMaxIdleConns(1)
	writeDB.SetConnMaxLifetime(0)

	if err := applyPragmas(ctx, writeDB); err != nil {
		_ = writeDB.Close()
		return nil, err
	}
	if err := migrate(ctx, writeDB); err != nil {
		_ = writeDB.Close()
		return nil, err
	}

	// :memory: databases are per-connection; a second pool would see a
	// different (empty) DB. Alias the single handle for reads in that case.
	var readDB *sql.DB
	if opts.Path == ":memory:" {
		readDB = writeDB
	} else {
		readDB, err = sql.Open("sqlite", dsn+"&mode=ro")
		if err != nil {
			_ = writeDB.Close()
			return nil, fmt.Errorf("store: open read handle: %w", err)
		}
		readDB.SetMaxOpenConns(8)
		readDB.SetMaxIdleConns(4)
		if err := applyReadPragmas(ctx, readDB); err != nil {
			_ = readDB.Close()
			_ = writeDB.Close()
			return nil, err
		}
	}

	return &DB{write: writeDB, read: readDB, path: opts.Path}, nil
}

// Close closes both underlying pools. Safe to call multiple times; subsequent
// calls return the first error.
func (db *DB) Close() error {
	var firstErr error
	if db.read != nil && db.read != db.write {
		if err := db.read.Close(); err != nil {
			firstErr = err
		}
	}
	if db.write != nil {
		if err := db.write.Close(); err != nil && firstErr == nil {
			firstErr = err
		}
	}
	db.read, db.write = nil, nil
	return firstErr
}

// Path returns the database file path (or ":memory:").
func (db *DB) Path() string { return db.path }

// Write returns the serialized write handle. Callers should not share
// transactions across goroutines.
func (db *DB) Write() *sql.DB { return db.write }

// Read returns the pooled read handle. For :memory: databases this is the
// same handle as Write.
func (db *DB) Read() *sql.DB { return db.read }

func applyPragmas(ctx context.Context, db *sql.DB) error {
	stmts := []string{
		"PRAGMA journal_mode = WAL",
		"PRAGMA synchronous  = NORMAL",
		"PRAGMA foreign_keys = ON",
		"PRAGMA auto_vacuum  = INCREMENTAL",
		"PRAGMA temp_store   = MEMORY",
	}
	for _, s := range stmts {
		if _, err := db.ExecContext(ctx, s); err != nil {
			return fmt.Errorf("store: apply %q: %w", s, err)
		}
	}
	return nil
}

func applyReadPragmas(ctx context.Context, db *sql.DB) error {
	// Read-only handle: only need foreign_keys and busy_timeout (set via DSN).
	if _, err := db.ExecContext(ctx, "PRAGMA foreign_keys = ON"); err != nil {
		return fmt.Errorf("store: apply read pragmas: %w", err)
	}
	return nil
}
