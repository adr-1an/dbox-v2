package make_condition

import (
	"app/app_state"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func HandleMake(args []string, state *app_state.AppState) {
	args = args[1:]

	if len(args) < 1 {
		fmt.Println("Usage: `make [name]`")
		return
	}

	name := args[0]
	name = strings.ToLower(strings.Replace(name, " ", "_", -1))
	currentTime := time.Now()
	currentTimeStr := currentTime.Format("20060102150405.000")
	name = fmt.Sprintf("%s_%s", currentTimeStr, name)

	mainMigrationDir := os.Getenv("MIGRATION_DIR")
	if mainMigrationDir == "" {
		mainMigrationDir = "db/migrations"
	}

	migrationDir := filepath.Join(mainMigrationDir, name)

	if err := os.MkdirAll(migrationDir, 0755); err != nil {
		log.Println(err)
		return
	}

	var upPath string
	var downPath string

	switch state.DB.(type) {
	case *sql.DB:
		upPath = filepath.Join(migrationDir, "up.sql")
		downPath = filepath.Join(migrationDir, "down.sql")

	default:
		fmt.Println("Unsupported DB type.")
		return
	}

	upFile, err := os.Create(upPath)
	if err != nil {
		log.Println(err)
		return
	}
	defer func() { _ = upFile.Close() }()

	if _, err := upFile.WriteString("-- Up"); err != nil {
		log.Println(err)
		return
	}

	downFile, err := os.Create(downPath)
	if err != nil {
		log.Println(err)
		return
	}
	defer func() { _ = downFile.Close() }()

	if _, err := downFile.WriteString("-- Down"); err != nil {
		log.Println(err)
		return
	}

	fmt.Printf("Created migration `%s`.\n", name)
}
