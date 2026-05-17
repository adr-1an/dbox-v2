package main

import (
	"app/app_state"
	"app/conditions/main_condition"
	"app/constants"
	"app/entry"
	"app/helpers/db"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	"github.com/joho/godotenv"
)

func main() {
	args := os.Args[1:]
	entry.Entry(args)

	// Load .env
	if err := godotenv.Load(".env"); err != nil {
		panic(err)
	}

	// Validate .env
	if os.Getenv("MIGRATION_DIR") == "" {
		fmt.Println("MIGRATION_DIR environment variable not set.")
		return
	}

	// Init DB connection
	var state app_state.AppState
	dbType := os.Getenv("DB_TYPE")
	switch dbType {
	case constants.DBTypePostgres:
		state.DB = db.InitPostgres()
	default:
		fmt.Println("Unsupported DB type:", dbType)
		return
	}

	// Check if the schema_migration table exist
	if args[0] != "init" {
		var tableExists bool
		var err error
		switch dbConn := state.DB.(type) {
		case *sql.DB:
			switch os.Getenv("DB_TYPE") {
			case constants.DBTypePostgres:
				tableExists, err = db.PostgresCheckMigrationsTable(dbConn)
				if err != nil {
					panic(err)
				}
			}

		default:
			fmt.Println("Unsupported DB type.")
			return
		}

		if !tableExists {
			fmt.Printf("Migrations table doesn't exist. Run `%s init` to create it.", filepath.Base(os.Args[0]))
			return
		}
	}

	// Main
	main_condition.HandleMainConditions(args, &state)
}
