package status_condition

import (
	"app/app_state"
	"app/constants"
	"database/sql"
	"fmt"
	"log"
	"os"
)

func HandleStatus(args []string, state *app_state.AppState) {
	args = args[1:]

	type migration struct {
		id      string
		applied bool
	}

	var migrations []migration

	migrationsDir := os.Getenv("MIGRATIONS_DIR")
	if migrationsDir == "" {
		migrationsDir = "db/migrations"
	}

	entries, err := os.ReadDir(migrationsDir)
	if err != nil {
		log.Println(err)
		return
	}

	for _, e := range entries {
		if !e.IsDir() {
			continue
		}

		var m migration
		m.id = e.Name()

		switch db := state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				if err := db.QueryRow(`SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE id = $1)`,
					e.Name()).Scan(&m.applied); err != nil {
					log.Println(err)
					return
				}
			}
		}

		migrations = append(migrations, m)
	}

	total := 0
	applied := 0
	nonApplied := 0
	for i, m := range migrations {
		var status string
		var emoji string
		if m.applied {
			status = "Applied"
			emoji = "✅"
			applied++
		} else {
			status = "Not applied"
			emoji = "❌"
			nonApplied++
		}

		fmt.Printf("[%d] [%s] %s - %s\n", i+1, emoji, m.id, status)
		total++
	}

	fmt.Printf("%d migrations found, %d applied, %d not applied.\n", total, applied, nonApplied)
}
