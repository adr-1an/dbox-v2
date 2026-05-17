package rollback_condition

import (
	"app/app_state"
	"app/constants"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

func HandleRollback(args []string, state *app_state.AppState) {
	args = args[1:]

	var opts struct {
		count   int
		verbose bool
	}

	for i := 0; i < len(args); i++ {
		arg := args[i]

		switch arg {
		case constants.OptCountFull, constants.OptCount:
			if i+1 >= len(args) {
				fmt.Println("Missing value for:", arg)
				return
			}

			count, err := strconv.Atoi(args[i+1])
			if err != nil {
				fmt.Println("Invalid count:", args[i+1])
				return
			}

			if count <= 0 {
				fmt.Println("Invalid count:", args[i+1])
				return
			}

			opts.count = count
			i++

		case constants.OptVerboseFull, constants.OptVerbose:
			opts.verbose = true

		default:
			fmt.Println("Unknown option:", arg)
			return
		}
	}

	type migration struct {
		id       string
		checksum string
	}
	var migrations []migration

	switch db := state.DB.(type) {
	case *sql.DB:
		switch os.Getenv("DB_TYPE") {
		case constants.DBTypePostgres:
			rows, err := db.Query(`SELECT id, checksum FROM schema_migrations ORDER BY id DESC`)
			if err != nil {
				log.Println(err)
				return
			}
			defer func() { _ = rows.Close() }()

			for rows.Next() {
				var m migration

				if err := rows.Scan(&m.id, &m.checksum); err != nil {
					log.Println(err)
					return
				}

				migrations = append(migrations, m)
			}

			if err := rows.Err(); err != nil {
				log.Println(err)
				return
			}
		}

	default:
		fmt.Println("Unsupported DB type.")
		return
	}

	mainMigrationDir := os.Getenv("MIGRATION_DIR")
	if mainMigrationDir == "" {
		mainMigrationDir = "db/migrations"
	}

	limit := opts.count
	if limit == 0 {
		limit = 1
	}

	count := 0
	for i, m := range migrations {
		if count >= limit {
			break
		}

		fmt.Printf("┌%d/%d │ Rolling back migration: %s\n", i+1, limit, m.id)
		count++

		if opts.verbose {
			fmt.Printf("├─ Datetime: %s\n", time.Now().Format("2006-01-02 15:04:05.000"))
			fmt.Printf("└─ Checksum: %s\n", m.checksum)
		}

		migrationDir := filepath.Join(mainMigrationDir, m.id)

		var migrationFile string
		switch state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				migrationFile = filepath.Join(migrationDir, "down.sql")
			}

		default:
			fmt.Println("Unsupported DB type.")
			return
		}

		rollbackQuery, err := os.ReadFile(migrationFile)
		if err != nil {
			log.Println(err)
			return
		}

		query := string(rollbackQuery)

		switch db := state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				if err := runPostgresRollback(db, m.id, query); err != nil {
					log.Println(err)
					return
				}
			}

		default:
			fmt.Println("Unsupported DB type.")
			return
		}
	}

	if count == 0 {
		fmt.Println("No migrations to roll back.")
		return
	}

	if count == 1 {
		fmt.Println("Rolled back 1 migration.")
	} else {
		fmt.Printf("Rolled back %d migrations.\n", count)
	}
}

func runPostgresRollback(db *sql.DB, migrationID, query string) error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.Exec(query); err != nil {
		return err
	}

	if _, err := db.Exec(
		`DELETE FROM schema_migrations WHERE id = $1`,
		migrationID); err != nil {
		return err
	}

	return tx.Commit()
}
