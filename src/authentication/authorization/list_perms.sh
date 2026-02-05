#!/bin/bash

list_db_permissions(){
    local db_name="$1"
    
    require_auth || return 1

    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can view permissions"
        return 1
    fi
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" || ! -s "$perm_file" ]]; then
        show_info "No permissions granted for database '$db_name'"
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Permissions for database: $db_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-15s %-20s %-15s %-15s\n" "USERNAME" "DATABASE" "TABLE" "PERMISSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS="$FIELD_DELIMITER" read -r username database table permission; do
        [[ "$database" == "$db_name" ]] || continue
        local table_display="${table:-*}"
        printf "%-15s %-20s %-15s %-15s\n" "$username" "$database" "$table_display" "$permission"
    done < "$perm_file"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_user_action "LIST_PERMISSIONS" "db=$db_name by=$CURRENT_USER"
}

list_user_permissions(){
    local target_user="${1:-$CURRENT_USER}"
    
    require_auth || return 1
    
    if [[ "$target_user" != "$CURRENT_USER" ]] && ! is_admin; then
        show_error "You can only view your own permissions"
        return 1
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Permissions for user: $target_user"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-15s %-15s\n" "DATABASE" "TABLE" "PERMISSION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local found=0
    
    for db_path in "$DB_DIR"/*/; do
        [[ -d "$db_path" ]] || continue
        
        local db_name=$(basename "$db_path")
        local perm_file=$(get_permissions_file "$db_name")
        
        [[ -f "$perm_file" ]] || continue
        
        while IFS="$FIELD_DELIMITER" read -r username database table permission; do
            if [[ "$username" == "$target_user" ]]; then
                local table_display="${table:-*}"
                printf "%-20s %-15s %-15s\n" "$database" "$table_display" "$permission"
                found=1
            fi
        done < "$perm_file"
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No explicit permissions granted"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}