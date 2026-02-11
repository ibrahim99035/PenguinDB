#!/bin/bash

create_database() {
    local db_name="$1"
    
    require_auth || return 1
    
    if [[ -z "$db_name" ]]; then
        show_error "Database name is required"
        return 1
    fi
    
    if [[ ! "$db_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        show_error "Invalid database name. Must start with letter and contain only letters, numbers, and underscores"
        return 1
    fi
    
    local db_path="$DB_DIR/$db_name"
    
    if [[ -d "$db_path" ]]; then
        show_error "Database '$db_name' already exists"
        return 1
    fi
    
    mkdir -p "$db_path"
    mkdir -p "$db_path/.metadata"
    
    set_db_owner "$db_name" "$CURRENT_USER"
    init_db_permissions "$db_name"
    
    show_success "Database '$db_name' created successfully"
    log_db_op "CREATE_DATABASE" "$db_name" ""
    
    return 0
}

list_databases() {
    require_auth || return 1
    
    if [[ ! -d "$DB_DIR" ]]; then
        show_info "No databases found"
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-25s %-15s\n" "DATABASE" "OWNER"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local found=0
    for db_path in "$DB_DIR"/*/; do
        [[ -d "$db_path" ]] || continue
        
        local db_name=$(basename "$db_path")
        
        if can_access_db "$db_name"; then
            local owner=$(get_db_owner "$db_name")
            printf "%-25s %-15s\n" "$db_name" "${owner:-unknown}"
            found=1
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No accessible databases found"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_db_op "LIST_DATABASES" "" ""
}

use_database() {
    local db_name="$1"
    
    require_auth || return 1
    
    if [[ -z "$db_name" ]]; then
        show_error "Database name is required"
        return 1
    fi
    
    local db_path="$DB_DIR/$db_name"
    
    if [[ ! -d "$db_path" ]]; then
        show_error "Database '$db_name' does not exist"
        return 1
    fi
    
    if ! can_access_db "$db_name"; then
        show_error "Access denied to database '$db_name'"
        return 1
    fi
    
    export CURRENT_DB="$db_name"
    
    show_success "Using database '$db_name'"
    log_db_op "USE_DATABASE" "$db_name" ""
    
    return 0
}

drop_database() {
    local db_name="$1"
    
    require_auth || return 1
    
    if [[ -z "$db_name" ]]; then
        show_error "Database name is required"
        return 1
    fi
    
    local db_path="$DB_DIR/$db_name"
    
    if [[ ! -d "$db_path" ]]; then
        show_error "Database '$db_name' does not exist"
        return 1
    fi
    
    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can drop database"
        return 1
    fi
    
    read -p "Are you sure you want to drop database '$db_name'? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        show_info "Drop database cancelled"
        return 1
    fi
    
    rm -rf "$db_path"
    
    if [[ "$CURRENT_DB" == "$db_name" ]]; then
        export CURRENT_DB=""
    fi
    
    show_success "Database '$db_name' dropped successfully"
    log_db_op "DROP_DATABASE" "$db_name" ""
    
    return 0
}