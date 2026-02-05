#!/bin/bash

revoke_permission(){
    local target_user="$1"
    local db_name="$2"
    local table_name="$3"
    local permission="$4"
    
    require_auth || return 1
    
    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can revoke permissions"
        return 1
    fi
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" ]]; then
        show_error "No permissions found for database '$db_name'"
        return 1
    fi
    
    remove_permission_record "$db_name" "$target_user" "$table_name" "$permission"
    
    show_success "Permission revoked: $permission on $db_name${table_name:+.$table_name} from $target_user"
    log_user_action "REVOKE_PERMISSION" "by=$CURRENT_USER from=$target_user db=$db_name table=$table_name perm=$permission"
    
    return 0
}

revoke_all_from_db(){
    local target_user="$1"
    local db_name="$2"
    
    require_auth || return 1
    
    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can revoke permissions"
        return 1
    fi
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" ]]; then
        show_error "No permissions found for database '$db_name'"
        return 1
    fi
    
    remove_all_user_permissions "$db_name" "$target_user"
    
    show_success "All permissions revoked from $target_user on database $db_name"
    log_user_action "REVOKE_ALL_PERMISSIONS" "by=$CURRENT_USER from=$target_user db=$db_name"
}