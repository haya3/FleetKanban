package store

import (
	"database/sql"
	"time"
)

// timeFormat is the canonical string format for timestamps stored in TEXT
// columns. ISO-8601 with microsecond precision and explicit UTC offset.
const timeFormat = "2006-01-02T15:04:05.000000Z07:00"

// nowUTC returns the current time normalized to UTC in the canonical format.
func nowUTC() string { return time.Now().UTC().Format(timeFormat) }

// formatTime renders t for storage. Zero times are stored as empty strings.
func formatTime(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.UTC().Format(timeFormat)
}

// parseTime parses a TEXT timestamp column. Empty strings produce the zero
// time with no error (nullable columns use NULL → sql.NullString instead).
func parseTime(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, nil
	}
	return time.Parse(timeFormat, s)
}

// nullablePtr wraps a *time.Time as a sql.NullString for INSERT/UPDATE.
func nullablePtr(t *time.Time) sql.NullString {
	if t == nil || t.IsZero() {
		return sql.NullString{}
	}
	return sql.NullString{String: t.UTC().Format(timeFormat), Valid: true}
}

// scanNullableTime converts a nullable TEXT column to *time.Time.
func scanNullableTime(s sql.NullString) (*time.Time, error) {
	if !s.Valid || s.String == "" {
		return nil, nil
	}
	t, err := time.Parse(timeFormat, s.String)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
