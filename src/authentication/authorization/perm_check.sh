#!/bin/bash

has_permission(){
    local username="$1"
    local db_name="$2"
    local table_name="$3"
    local required_perm="$4"
    
    if is_admin "$username"; then
        return 0
    fi
    
    if is_db_owner "$db_name" "$username"; then
        return 0
    fi
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" ]]; then
        return 1
    fi
    
    if grep -q "^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${FIELD_DELIMITER}${PERM_ALL}$" "$perm_file"; then
        return 0
    fi
    
    if [[ -n "$table_name" ]]; then
        if grep -q "^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${table_name}${FIELD_DELIMITER}${PERM_ALL}$" "$perm_file"; then
            return 0
        fi
    fi
    
    if grep -q "^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${FIELD_DELIMITER}${required_perm}$" "$perm_file"; then
        return 0
    fi
    
    if [[ -n "$table_name" ]]; then
        if grep -q "^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${table_name}${FIELD_DELIMITER}${required_perm}$" "$perm_file"; then
            return 0
        fi
    fi
    
    return 1
}

has_db_permission(){
    local db_name="$1"
    local username="${2:-$CURRENT_USER}"
    local permission="${3:-$PERM_SELECT}"
    
    has_permission "$username" "$db_name" "" "$permission"
}

has_table_permission(){
    local db_name="$1"
    local table_name="$2"
    local username="${3:-$CURRENT_USER}"
    local permission="${4:-$PERM_SELECT}"
    
    has_permission "$username" "$db_name" "$table_name" "$permission"
}

require_permission(){
    local db_name="$1"
    local table_name="$2"
    local permission="$3"
    
    require_auth || return 1
    
    if ! has_permission "$CURRENT_USER" "$db_name" "$table_name" "$permission"; then
        show_error "Permission denied: $permission required on $db_name${table_name:+.$table_name}"
        log_user_action "PERMISSION_DENIED" "user=$CURRENT_USER db=$db_name table=$table_name perm=$permission"
        return 1
    fi
    
    return 0
}