package entry

import (
	"app/constants"
	"fmt"
	"os"
	"path/filepath"
)

func Entry(args []string) {
	if len(args) < 1 {
		fmt.Printf("%s v%s\n", constants.Name, constants.Version)
		fmt.Printf("Use `%s help` to display commands.\n", filepath.Base(os.Args[0]))
		os.Exit(0)
	}
}
