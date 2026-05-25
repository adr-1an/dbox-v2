package entry

import (
	"app/constants"
	"fmt"
	"os"
	"path/filepath"
)

func Info() {
	app := filepath.Base(os.Args[0])

	fmt.Printf(`%s - Help

Usage:
  %s <command> [options]

Commands:
  init
    Initialize the database by creating the migrations table.
    Options:
      -v, --verbose    Show detailed output.
    Example:
      %s init -v

  make <name>
    Create a new migration.
    Example:
      %s make create_users_table

  up, migrate
    Run pending migrations.
    Options:
      -c, --count <n>  Run only the next n migrations.
      -v, --verbose    Show detailed output.
    Example:
      %s up -c 3 -v

  down, rollback
    Roll back migrations.
    Options:
      -c, --count <n>  Roll back only the last n migrations.
    Example:
      %s down -c 3

  stat, status
    Show migration status.
    Example:
      %s stat

  cleanup
    Delete migration records that no longer have matching directories.
    Options:
      -v, --verbose    Show detailed output.
    Example:
      %s cleanup -v
`, constants.Name, app, app, app, app, app, app, app)

	os.Exit(0)
}
