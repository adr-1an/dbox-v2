# DBox - Database Toolbox
DBox is a simple migration tool written entirely in Go.
This is the second verson of DBox - find the first one [here](https://github.com/adr-1an/dbox).

## Currently supported databases
- Postgres

More databases will be added in later releases. [DBox v1](https://github.com/adr-1an/dbox) supports more databases however, so you can use that until v2 adds support.

## Env file options
`DB_TYPE` - Database type, "postgres" for example.

`DB_DSN` - DSN for the database DBox should connect to. Example: `postgres://user:password@host:port/database`

`MIGRATION_DIR` - The directory where DBox will store all the migration files. By default, it's `db/migrations` (in the directory you run DBox from).

## Notes
This is my personal project, mainly intended for internal use in my apps.
My goal isn't to make this some kinda big/serious project, as long as it gets the job done for my projects.
