package db

import "database/sql"

func PostgresCheckMigrationsTable(db *sql.DB) (bool, error) {
	var exists bool

	if err := db.QueryRow(`SELECT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = $1
)`, "schema_migrations").Scan(&exists); err != nil {
		return false, err
	}

	return exists, nil
}
