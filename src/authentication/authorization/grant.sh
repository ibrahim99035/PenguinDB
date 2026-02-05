#!/bin/bash

validate_permission_type(){
    local permission="$1"
    
    case "$permission" in
        "$PERM_SELECT"|"$PERM_INSERT"|"$PERM_UPDATE"|"$PERM_DELETE"|"$PERM_ALL")
            return 0
            ;;
        *)
            show_error "Invalid permission: $permission"
            return 1
            ;;
    esac
}

grant_permission(){
    local target_user="$1"
    local db_name="$2"
    local table_name="$3"
    local permission="$4"
    
    require_auth || return 1
    
    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can grant permissions"
        return 1
    fi
    
    validate_permission_type "$permission" || return 1
    
    if ! user_exists "$target_user"; then
        show_error "User '$target_user' does not exist"
        return 1
    fi
    
    init_db_permissions "$db_name"
    
    if permission_exists "$db_name" "$target_user" "$table_name" "$permission"; then
        show_warning "Permission already granted"
        return 0
    fi
    
    add_permission_record "$db_name" "$target_user" "$table_name" "$permission"
    
    show_success "Permission granted: $permission on $db_name${table_name:+.$table_name} to $target_user"
    log_user_action "GRANT_PERMISSION" "by=$CURRENT_USER to=$target_user db=$db_name table=$table_name perm=$permission"
    
    return 0
}

grant_all_on_db(){
    local target_user="$1"
    local db_name="$2"
    
    grant_permission "$target_user" "$db_name" "" "$PERM_ALL"
}

grant_all_on_table(){
    local target_user="$1"
    local db_name="$2"
    local table_name="$3"
    
    grant_permission "$target_user" "$db_name" "$table_name" "$PERM_ALL"
}