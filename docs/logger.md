## Logging System of PenguinDB

> Our small Bash logging framework  — These ate a reusable functions that standardize PenguinDB reports events, errors, and user actions.

### Loggin an Audit
```bash
log_audit(){
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$AUDIT_LOG"
}
```
Writes audit events (important actions) to the audit log file `storage/logs/audit.log`.
- `local message="$1"` → first argument passed to the function.
- `date '+%Y-%m-%d %H:%M:%S'` → generates a readable timestamp.
- `>> "$AUDIT_LOG"` → appends to the audit log file.
It does not print anyting in the terminal, its only target is to append the log inside the log file.
<details>
  <summary>Exampel of usage</summary>

  ```bash
  log_audit "User created a database"
  ```
  
  `Sampel Output`
  
  ```bash
  [2026-02-04 18:42:10] User created a database
  ```

</details>

#### Showing an information in a <span style="color:blue">blue</span> line then `log_audit` it:

```bash
show_info(){
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
    log_audit "INFO: $1"
}
```

#### Showing a success message in a <span style="color:green">green</span> line then `log_audit` it:

```bash
show_success(){
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
    log_audit "SUCCESS: $1"
}
```

#### Showing a warning in a <span style="color:yellow">yellow</span> line  then `log_audit` it:

```bash
show_warning(){
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
    log_audit "WARNING: $1"
}
```
---

### Logging an Error

```bash
log_error(){
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$ERROR_LOG"
}
```

Writes errors to the error log file `storage/logs/error.log`.
- `local message="$1"` → first argument passed to the function.
- `date '+%Y-%m-%d %H:%M:%S'` → generates a readable timestamp.
- `>> "$ERROR_LOG"` → appends to the error log file.
It does not print anyting in the terminal, its only target is to append the log inside the log file.
<details>
  <summary>Exampel of usage</summary>

  ```bash
  log_error "ERROR creating a database"
  ```
  
  `Sampel Output`
  
  ```plaintext
  [2026-02-04 18:42:10] User created a database
  ```

</details>

#### Showing an error message in a <span style="color:red">red</span> line then `log_error` it:

```bash
show_error(){
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
    log_error "ERROR: $1"
}
```
---

### Logging a User's Access and Auth

```bash
log_access(){
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$ACCESS_LOG"
}
```

```bash
log_auth(){
    local username="$1"
    local status="$2"
    log_access "AUTH: user=$username status=$status"
}
```
---

### DB Operations

```bash
log_db_op(){
    local operation="$1"
    local database="$2"
    local table="$3"
    local user="${CURRENT_USER:-guest}"
    
    local msg="DB_OP: user=$user op=$operation db=$database"
    [[ -n "$table" ]] && msg="$msg table=$table"
    
    log_audit "$msg"
}
```
---

### User Actions

```bash
log_user_action(){
    local action="$1"
    local details="$2"
    local user="${CURRENT_USER:-guest}"
    
    local msg="USER_ACTION: user=$user action=$action"
    [[ -n "$details" ]] && msg="$msg details=$details"
    
    log_audit "$msg"
}
```