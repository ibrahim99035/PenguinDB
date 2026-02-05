#!/bin/bash

set_db_owner() {
    local db_name="$1"
    local owner="${2:-$CURRENT_USER}"
    
    local db_path="$DB_DIR/$db_name"
    
    if [[ ! -d "$db_path" ]]; then
        show_error "Database '$db_name' does not exist"
        return 1
    fi
    
    echo "$owner" > "$db_path/.owner"
    log_db_op "SET_OWNER" "$db_name" "" "owner=$owner"
    return 0
}

get_db_owner() {
    local db_name="$1"
    local owner_file="$DB_DIR/$db_name/.owner"
    
    if [[ -f "$owner_file" ]]; then
        cat "$owner_file"
    else
        echo ""
    fi
}

is_db_owner() {
    local db_name="$1"
    local username="${2:-$CURRENT_USER}"
    
    local owner=$(get_db_owner "$db_name")
    
    [[ "$owner" == "$username" ]]
}

can_access_db(){
    local db_name="$1"
    local username="${2:-$CURRENT_USER}"
    
    if is_admin "$username"; then
        return 0
    fi
    
    if is_db_owner "$db_name" "$username"; then
        return 0
    fi
    
    if has_db_permission "$db_name" "$username" "$PERM_SELECT"; then
        return 0
    fi
    
    return 1
}