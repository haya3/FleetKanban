//go:build ignore

package main

import (
	"database/sql"
	"fmt"
	"os"
	"strings"

	_ "modernc.org/sqlite"
)

func main() {
	dbPath := "C:/Users/Work/AppData/Roaming/haya3/FleetKanban.db"
	db, err := sql.Open("sqlite", "file:"+dbPath+"?mode=ro&_pragma=busy_timeout(5000)")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer db.Close()

	mode := "running"
	if len(os.Args) > 1 {
		mode = os.Args[1]
	}

	switch mode {
	case "running":
		rows, err := db.Query(`SELECT id, status, substr(goal,1,80), started_at, updated_at
			FROM tasks WHERE status IN ('planning','in_progress')
			ORDER BY updated_at DESC`)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		defer rows.Close()
		for rows.Next() {
			var id, status, goal, started, updated string
			rows.Scan(&id, &status, &goal, &started, &updated)
			fmt.Printf("TASK %s | status=%s | started=%s | updated=%s\n  goal: %s\n",
				id, status, started, updated, goal)
		}
	case "events":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "usage: dbquery events <task_id> [limit]")
			os.Exit(1)
		}
		taskID := os.Args[2]
		limit := "80"
		if len(os.Args) >= 4 {
			limit = os.Args[3]
		}
		rows, err := db.Query(fmt.Sprintf(`SELECT seq, occurred_at, kind, payload
			FROM events WHERE task_id = ?
			ORDER BY seq DESC LIMIT %s`, limit), taskID)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		defer rows.Close()
		for rows.Next() {
			var seq int64
			var occ, kind, payload string
			rows.Scan(&seq, &occ, &kind, &payload)
			if len(payload) > 200 {
				payload = payload[:200] + "…"
			}
			fmt.Printf("[%d] %s %s | %s\n", seq, occ, kind, payload)
		}
	case "kinds":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "usage: dbquery kinds <task_id>")
			os.Exit(1)
		}
		taskID := os.Args[2]
		rows, err := db.Query(`SELECT kind, COUNT(*) FROM events
			WHERE task_id = ? GROUP BY kind ORDER BY 2 DESC`, taskID)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		defer rows.Close()
		for rows.Next() {
			var kind string
			var n int
			rows.Scan(&kind, &n)
			fmt.Printf("%6d  %s\n", n, kind)
		}
	case "tail_deltas":
		if len(os.Args) < 3 {
			fmt.Fprintln(os.Stderr, "usage: dbquery tail_deltas <task_id> [limit]")
			os.Exit(1)
		}
		taskID := os.Args[2]
		limit := "30"
		if len(os.Args) >= 4 {
			limit = os.Args[3]
		}
		rows, err := db.Query(fmt.Sprintf(`SELECT seq, kind, payload FROM events
			WHERE task_id = ? AND kind IN ('assistant.delta','assistant.reasoning.delta','tool.start','tool.end','subtask.start','subtask.end','error')
			ORDER BY seq DESC LIMIT %s`, limit), taskID)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		defer rows.Close()
		out := []string{}
		for rows.Next() {
			var seq int64
			var kind, payload string
			rows.Scan(&seq, &kind, &payload)
			if len(payload) > 120 {
				payload = payload[:120] + "…"
			}
			out = append(out, fmt.Sprintf("[%d] %s | %s", seq, kind, payload))
		}
		for i := len(out) - 1; i >= 0; i-- {
			fmt.Println(out[i])
		}
	default:
		fmt.Fprintln(os.Stderr, "unknown mode", strings.TrimSpace(mode))
		os.Exit(1)
	}
}
