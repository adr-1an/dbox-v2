package entry

import (
	"app/constants"
	"fmt"
	"os"
	"path/filepath"
)

func Info() {
	app := filepath.Base(os.Args[0])
	spacer := "—————————"

	fmt.Printf("%s - Help\n", constants.Name)

	// init
	fmt.Printf(`
> init - Initialize the database by creating the migrations table.
  Options:
    --verbose or -v: Verbose mode.
  Example:
    %s init -v
%s`, app, spacer)

	// make
	fmt.Printf(`
> make - Make a new migration.
  Arguments:
    [name] - Name of the new migration.
  Example:
    %s make create_users_table
%s`, app, spacer)

	// up / migrate
	fmt.Printf(`
> up / migrate - Run pending migrations.
  Options:
    --count or -c: Only run the specified number of migrations instead of everything.
    --verbose or -v: Verbose mode.
  Example:
    %s up -c 3 -v
%s`, app, spacer)

	// down / rollback
	fmt.Printf(`
> down / rollback - Roll a migration back.
  Options:
    --count or -c: Only rollback the specified number of migrations instead of everything.
  Example:
    %s down -c 3
%s`, app, spacer)

	// stat / status
	fmt.Printf(`
> stat / status - View migration status.
  Example:
    %s stat
%s`, app, spacer)

	// rerun
	fmt.Printf(`
> rerun - Re-run all migrations.
WARNING: All tables will be dropped and re-created, deleting all data.
  Options:
    --transaction or -tx: Run all queries in a transaction, so if one query fails, everything gets reverted.
  Example:
    %s rerun -tx
%s`, app, spacer)

	os.Exit(0)
}
