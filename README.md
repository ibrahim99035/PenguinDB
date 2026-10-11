# PenguinDB

A lightweight **Database Management System written entirely in Bash**.

- Builds a real shell-based CLI around a flat-file database engine
- Supports user registration, authentication, session-based login, roles and permissions
- Provides database, table and data operation menus from the terminal
- Stores its own data as plain files under `src/storage`

---

## Quick start

```bash
cd PenguinDB/src
./main.sh
```

On the very first run, PenguinDB asks you to create an **admin account**, then drops you
into the interactive CLI (login -> database -> table -> data menus).

## What you get

```text
src/storage/
├── databases/          # .dat / .meta / .owner per database
├── logs/               # audit.log, error.log, access.log
└── users/              # users.dat, sessions.dat
```

## Tech stack

- **Shell** (`bash`) only - no external database server required
- Filesystem as the storage engine
- Standard Unix utilities only (`sed`, `awk`, `grep`, `sort`, `cut`, `wc`)

## Notes

- All data is stored in `src/storage/` - back it up by copying that directory.
- Authentication, roles and permissions live in `src/authentication/`.
