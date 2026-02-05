#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/config/load.conf"
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/authentication/auth.sh"

source "$SCRIPT_DIR/first_run.sh"

main(){
    initialize_system
    
    if is_first_run; then
        show_welcome
        run_first_time_setup
    fi
    
    # start_cli_interface
}

initialize_system(){
    mkdir -p "$STORAGE_DIR"
    mkdir -p "$USER_DIR"
    mkdir -p "$DB_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$TEMP_DIR"
    
    touch "$AUDIT_LOG"
    touch "$ERROR_LOG"
    touch "$ACCESS_LOG"
    
    touch "$USERS_FILE"
    touch "$SESSIONS_FILE"
    
    show_info "System initialized"
}

is_first_run(){
    [[ ! -f "$USERS_FILE" || ! -s "$USERS_FILE" ]]
}

main "$@"