#!/bin/bash

log_audit() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$AUDIT_LOG"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$ERROR_LOG"
}

log_access() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$ACCESS_LOG"
}

show_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
    log_audit "INFO: $1"
}

show_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
    log_audit "SUCCESS: $1"
}

show_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
    log_audit "WARNING: $1"
}

show_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
    log_error "ERROR: $1"
}

log_auth() {
    local username="$1"
    local status="$2"
    log_access "AUTH: user=$username status=$status"
}

log_db_op() {
    local operation="$1"
    local database="$2"
    local table="$3"
    local user="${CURRENT_USER:-guest}"
    
    local msg="DB_OP: user=$user op=$operation db=$database"
    [[ -n "$table" ]] && msg="$msg table=$table"
    
    log_audit "$msg"
}

log_user_action() {
    local action="$1"
    local details="$2"
    local user="${CURRENT_USER:-guest}"
    
    local msg="USER_ACTION: user=$user action=$action"
    [[ -n "$details" ]] && msg="$msg details=$details"
    
    log_audit "$msg"
}