package cleanup_condition

import (
	"app/app_state"
	"app/constants"
	"database/sql"
	"fmt"
	"log"
	"os"
)

func contains(slice []string, target string) bool {
	for _, v := range slice {
		if v == target {
			return true
		}
	}

	return false
}

func HandleCleanup(args []string, state *app_state.AppState) {
	args = args[1:]

	var opts struct {
		verbose bool
	}

	for _, arg := range args {
		switch arg {
		case constants.OptVerboseFull, constants.OptVerbose:
			opts.verbose = true
		}
	}

	if opts.verbose {
		fmt.Println("Deleting stray migration records...")
	}

	var migrationRecords []string
	var migrationDirs []string

	switch db := state.DB.(type) {
	case *sql.DB:
		switch os.Getenv("DB_TYPE") {
		case constants.DBTypePostgres:
			rows, err := db.Query(`SELECT id FROM schema_migrations`)
			if err != nil {
				log.Println(err)
				return
			}
			defer func() { _ = rows.Close() }()

			for rows.Next() {
				var id string
				if err := rows.Scan(&id); err != nil {
					log.Println(err)
					return
				}

				migrationRecords = append(migrationRecords, id)
			}

			if err := rows.Err(); err != nil {
				log.Println(err)
				return
			}
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

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		migrationDirs = append(migrationDirs, entry.Name())
	}

	count := 0
	for _, mr := range migrationRecords {
		if !contains(migrationDirs, mr) {
			switch db := state.DB.(type) {
			case *sql.DB:
				switch os.Getenv("DB_TYPE") {
				case constants.DBTypePostgres:
					if opts.verbose {
						fmt.Printf("┌%d │ Deleting stray record: %s\n", count+1, mr)
					}
					if _, err := db.Exec(`DELETE FROM schema_migrations WHERE id = $1`, mr); err != nil {
						log.Println(err)
						return
					}
					count++
				}
			}
		}
	}

	if count == 0 {
		fmt.Println("No stray migration records found.")
	} else {
		if count == 1 {
			fmt.Printf("Finished deleting %d stray migration record.\n", count)
		} else {
			fmt.Printf("Finished deleting %d stray migration records.\n", count)
		}
	}
}
