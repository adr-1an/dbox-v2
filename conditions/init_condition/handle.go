package init_condition

import (
	"app/app_state"
	"app/constants"
	"database/sql"
	"fmt"
	"log"
	"os"
)

// HandleInit initializes the database by creating the "migrations" table.
func HandleInit(args []string, state *app_state.AppState) {
	args = args[1:]

	var opts struct {
		verbose bool
	}

	for _, arg := range args {
		switch arg {
		case constants.OptVerboseFull, constants.OptVerbose:
			opts.verbose = true
		default:
			fmt.Println("Unknown option:", arg)
			return
		}
	}

	fmt.Printf("Initializing %s...\n", constants.Name)
	if opts.verbose {
		fmt.Println("Running table creation query...")
	}

	var err error
	switch db := state.DB.(type) {
	case *sql.DB:
		if opts.verbose {
			fmt.Println("Detected database type:", constants.DBTypePostgres)
		}
		switch os.Getenv("DB_TYPE") {
		case constants.DBTypePostgres:
			_, err = db.Exec(`
CREATE TABLE IF NOT EXISTS schema_migrations (
    id TEXT PRIMARY KEY,
    checksum TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
)`)
		}
	default:
		fmt.Println("Unsupported DB type.")
		return
	}
	if err != nil {
		log.Println(err)
		return
	}

	if opts.verbose {
		fmt.Println("Created migrations table.")
	}

	fmt.Println("Database initialized.")
}
