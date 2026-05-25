package main_condition

import (
	"app/app_state"
	"app/conditions/cleanup_condition"
	"app/conditions/init_condition"
	"app/conditions/make_condition"
	"app/conditions/migrate_condition"
	"app/conditions/rollback_condition"
	"app/conditions/status_condition"
	"app/entry"
	"fmt"
)

func HandleMainConditions(args []string, state *app_state.AppState) {
	switch args[0] {
	case "init":
		init_condition.HandleInit(args, state)

	case "make":
		make_condition.HandleMake(args, state)

	case "status", "stat":
		status_condition.HandleStatus(args, state)

	case "migrate", "up":
		migrate_condition.HandleMigrate(args, state)

	case "rollback", "down":
		rollback_condition.HandleRollback(args, state)

	case "cleanup":
		cleanup_condition.HandleCleanup(args, state)

	case "help":
		entry.Info()

	default:
		fmt.Println("Unknown command:", args[0])
		return
	}
}
