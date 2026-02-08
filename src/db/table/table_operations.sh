#!/bin/bash

# Table Operations Module
# Drop, list, and describe tables

# Drop table
drop_table() {
    local db_name=$1
    local table_name=$2
    
    require_auth || return 1
    
    # Check permission
    if ! has_db_permission "$db_name" "$CURRENT_USER" "$PERM_DELETE"; then
        show_error "You don't have permission to drop tables in this database"
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    local meta_file="$DB_DIR/$db_name/.metadata/${table_name}.meta"
    
    # Delete table and metadata
    rm -f "$table_file"
    rm -f "$meta_file"
    
    show_success "Table '$table_name' dropped successfully"
    log_db_op "DROP_TABLE" "$db_name" "$table_name"
    
    return 0
}

# List all tables in database
list_tables() {
    local db_name=$1
    
    require_auth || return 1
    
    # Check access
    if ! can_access_db "$db_name"; then
        show_error "You don't have access to database '$db_name'"
        return 1
    fi
    
    local db_path="$DB_DIR/$db_name"
    
    if [[ ! -d "$db_path" ]]; then
        show_error "Database '$db_name' does not exist"
        return 1
    fi
    
    echo ""
    echo "Tables in database: $db_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-30s %-15s %-15s\n" "TABLE NAME" "ROWS" "COLUMNS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local found=0
    
    for table_file in "$db_path"/*.dat; do
        [[ -f "$table_file" ]] || continue
        
        local table_name=$(basename "$table_file" .dat)
        local row_count=$(wc -l < "$table_file" 2>/dev/null || echo "0")
        local col_count=$(get_column_count "$db_name" "$table_name")
        
        printf "%-30s %-15s %-15s\n" "$table_name" "$row_count" "$col_count"
        found=1
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No tables found"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_db_op "LIST_TABLES" "$db_name"
}

# Describe table (show structure)
describe_table() {
    local db_name=$1
    local table_name=$2
    
    require_auth || return 1
    
    # Check access
    if ! can_access_db "$db_name"; then
        show_error "You don't have access to database '$db_name'"
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    # Display schema
    display_table_schema "$db_name" "$table_name"
    
    # Show row count
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    local row_count=$(wc -l < "$table_file" 2>/dev/null || echo "0")
    
    echo "Rows: $row_count"
    echo ""
    
    log_db_op "DESCRIBE_TABLE" "$db_name" "$table_name"
}

# Get table size
get_table_size() {
    local db_name=$1
    local table_name=$2
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    
    if [[ -f "$table_file" ]]; then
        du -h "$table_file" | cut -f1
    else
        echo "0"
    fi
}

# Truncate table (delete all rows but keep structure)
truncate_table() {
    local db_name=$1
    local table_name=$2
    
    require_auth || return 1
    
    # Check permission
    if ! has_table_permission "$db_name" "$table_name" "$CURRENT_USER" "$PERM_DELETE"; then
        show_error "You don't have permission to truncate this table"
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    
    # Empty the file
    > "$table_file"
    
    show_success "Table '$table_name' truncated successfully"
    log_db_op "TRUNCATE_TABLE" "$db_name" "$table_name"
    
    return 0
}

# Rename table
rename_table() {
    local db_name=$1
    local old_name=$2
    local new_name=$3
    
    require_auth || return 1
    
    # Check permission (need to be owner or admin)
    if ! is_admin && ! is_db_owner "$db_name"; then
        show_error "Only database owner or admin can rename tables"
        return 1
    fi
    
    # Validate new name
    validate_table_name "$new_name" || return 1
    
    # Check if old table exists
    if ! table_exists "$db_name" "$old_name"; then
        show_error "Table '$old_name' does not exist"
        return 1
    fi
    
    # Check if new name already exists
    if table_exists "$db_name" "$new_name"; then
        show_error "Table '$new_name' already exists"
        return 1
    fi
    
    local old_table_file="$DB_DIR/$db_name/${old_name}.dat"
    local new_table_file="$DB_DIR/$db_name/${new_name}.dat"
    local old_meta_file="$DB_DIR/$db_name/.metadata/${old_name}.meta"
    local new_meta_file="$DB_DIR/$db_name/.metadata/${new_name}.meta"
    
    # Rename files
    mv "$old_table_file" "$new_table_file"
    mv "$old_meta_file" "$new_meta_file"
    
    show_success "Table renamed from '$old_name' to '$new_name'"
    log_db_op "RENAME_TABLE" "$db_name" "$old_name" "new_name=$new_name"
    
    return 0
}