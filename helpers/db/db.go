package db

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/lib/pq"
)

func dsn() string {
	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		log.Println("DB_DSN environment variable is not set.")
		os.Exit(1)
	}

	return dsn
}

func InitPostgres() *sql.DB {
	pool, err := sql.Open("postgres", dsn())
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}

	return pool
}
