package migrate_condition

import (
	"app/app_state"
	"app/constants"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

// HandleMigrate runs pending migrations.
func HandleMigrate(args []string, state *app_state.AppState) {
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

	if opts.verbose {
		if opts.count > 0 {
			if opts.count == 1 {
				fmt.Println("Running 1 migration...")
			} else {
				fmt.Printf("Running %d migrations...\n", opts.count)
			}
		} else {
			fmt.Println("Running all migrations...")
		}
	}

	mainMigrationDir := os.Getenv("MIGRATION_DIR")
	if mainMigrationDir == "" {
		mainMigrationDir = "db/migrations"
	}

	entries, err := os.ReadDir(mainMigrationDir)
	if err != nil {
		log.Println(err)
		return
	}

	count := 0
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		if count >= opts.count && opts.count > 0 {
			break
		}

		migrationID := entry.Name()

		alreadyMigrated := false

		switch db := state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				if err := db.QueryRow(`SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE id = $1)`, migrationID).
					Scan(&alreadyMigrated); err != nil {
					log.Println(err)
					return
				}
			}

		default:
			fmt.Println("Unsupported DB type.")
			return
		}

		if alreadyMigrated {
			continue
		}

		var migrationFile string
		switch state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				migrationFile = filepath.Join(mainMigrationDir, migrationID, "up.sql")
			}

		default:
			fmt.Println("Unsupported DB type.")
			return
		}

		migrationQuery, err := os.ReadFile(migrationFile)
		if err != nil {
			log.Println(err)
			return
		}

		query := string(migrationQuery)

		total := min(opts.count, len(entries))
		fmt.Printf("┌%d/%d │ Running migration: %s\n", count+1, total, migrationID)

		sum := sha256.Sum256([]byte(query))
		checksum := hex.EncodeToString(sum[:])

		if opts.verbose {
			fmt.Printf("├─ Datetime: %s\n", time.Now().Format("2006-01-02 15:04:05.000"))
			fmt.Printf("└─ Checksum: %s\n", checksum)
		}

		count++

		switch db := state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				if err = runPostgresMigration(db, migrationID, query, checksum); err != nil {
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
		fmt.Println("No migrations to run.")
		return
	}

	if count == 1 {
		fmt.Printf("Finished running %d migration.\n", count)
	} else {
		fmt.Printf("Finished running %d migrations.\n", count)
	}
}

func runPostgresMigration(db *sql.DB, migrationID string, query string, checksum string) error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err = tx.Exec(query); err != nil {
		return err
	}

	if _, err = tx.Exec(
		`INSERT INTO schema_migrations (id, checksum) VALUES ($1, $2)`,
		migrationID,
		checksum,
	); err != nil {
		return err
	}

	return tx.Commit()
}
