## Gloabl Configuration Variables

> Defining a export variables for all child processes.
---

### Root Path Resolution:

```bash
export PENGUIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

- `BASH_SOURCE` is a built-in bash array variable, it keeps track of the current file that being executed and other chain fo bash scripts that sourced that script.
- `BASH_SOURCE[0]` is current bash script file.
- `dir` Extract the parent directory.
- `$()` is a way to execute a command and replace it with its output in another command.
- `&& pwd` then gets the absolute path of the app after moving to it.

### Srorage Area Directories Definition:

#### Propesed File Structure:

```plaintext
storage/                            
├── .gitkeep                        
├── users/                          
│   ├── .gitkeep
│   ├── users.dat                   
│   └── sessions.dat                
│
├── databases/                      
│   ├── .gitkeep
│   └── [database_name]/            
│       ├── .owner                  
│       ├── .metadata/              
│       │   ├── [table_name].meta   
│       │   └── .permissions        
│       └── [table_name].dat        
│
├── logs/                           
│   ├── .gitkeep
│   ├── audit.log                   
│   ├── error.log                   
│   └── access.log                  
│
└── temp/                           
    └── .gitkeep
```
#### Required defintions inside configuration file:

```bash
export STORAGE_DIR="$PENGUIN_ROOT/storage"

export USER_DIR="$STORAGE_DIR/users"
export USERS_FILE="$USER_DIR/users.dat"
export SESSIONS_FILE="$USER_DIR/sessions.dat"

export LOG_DIR="$STORAGE_DIR/logs"
export AUDIT_LOG="$LOG_DIR/audit.log"
export ERROR_LOG="$LOG_DIR/error.log"
export ACCESS_LOG="$LOG_DIR/access.log"

export DB_DIR="$STORAGE_DIR/databases"

export TEMP_DIR="$STORAGE_DIR/temp"
```
- First: we defining the storage directory.
- Then: define the directory we would store users inside and files + sessions file.
- Then: The Logging required files.
- Then The Databases directory that would include the entire data.
- Finally: the temp directory.
---

### Delimiters:

```bash
export FIELD_DELIMITER="|"
export RECORD_DELIMITER=$'\n'
```
- Defining a splitter for fields inside a DB record as the pipe `|`.
- Defining a delimiter to mark a record using the new-line character `\n`.
---

### Self-Descriptive Auth data validation limits:

```bash
export MAX_USERNAME_LENGTH=20
export MIN_USERNAME_LENGTH=3
export MIN_PASSWORD_LENGTH=6
```
---

### Self-Descriptive User Roles:

```bash
export ROLE_ADMIN="admin"
export ROLE_USER="user"
export ROLE_GUEST="guest"
```
---

### Permissions for database operations:

```bash
export PERM_SELECT="SELECT"
export PERM_INSERT="INSERT"
export PERM_UPDATE="UPDATE"
export PERM_DELETE="DELETE"
export PERM_ALL="ALL"
```
---

### Colors:

```bash
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_RESET='\033[0m'
```
---

### Global Placeholders to hold current session info:

```bash
export CURRENT_USER=""
export CURRENT_SESSION=""
export CURRENT_DB=""
export CURRENT_TABLE=""
```