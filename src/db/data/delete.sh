#!/bin/bash

# DELETE Operation Module
# Delete records from tables

# Delete records from SQL statement
delete_records_sql() {
    local db_name=$1
    local sql=$2
    
    require_auth || return 1
    
    # Parse DELETE statement
    local parsed=$(parse_delete_statement "$sql")
    
    if [[ -z "$parsed" ]]; then
        return 1
    fi
    
    local table_name=$(echo "$parsed" | cut -d'|' -f1)
    local where=$(echo "$parsed" | cut -d'|' -f2)
    
    # Check permission
    if ! require_permission "$db_name" "$table_name" "$PERM_DELETE"; then
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    # Warn if no WHERE clause
    if [[ -z "$where" ]]; then
        echo ""
        show_warning "WARNING: No WHERE clause specified. This will delete ALL records!"
        
        if ! confirm_action "Are you sure you want to delete all records?"; then
            show_info "Delete cancelled"
            return 0
        fi
    fi
    
    # Delete records
    delete_records "$db_name" "$table_name" "$where"
}

# Delete records from table
delete_records() {
    local db_name=$1
    local table_name=$2
    local where=$3         # WHERE clause (optional)
    
    # Load schema
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        show_error "Failed to load table schema"
        return 1
    fi
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    local temp_file="${table_file}.tmp"
    
    # Check if table is empty
    if [[ ! -s "$table_file" ]]; then
        show_info "No records to delete"
        return 0
    fi
    
    # Process records
    local deleted_count=0
    
    while IFS= read -r record; do
        # Check if record matches WHERE clause
        local should_delete=false
        
        if [[ -z "$where" ]]; then
            # No WHERE clause, delete all
            should_delete=true
        else
            if evaluate_where_clause "$schema" "$record" "$where"; then
                should_delete=true
            fi
        fi
        
        if [[ $should_delete == true ]]; then
            ((deleted_count++))
        else
            # Keep this record
            echo "$record" >> "$temp_file"
        fi
    done < "$table_file"
    
    # Replace original file
    if [[ -f "$temp_file" ]]; then
        mv "$temp_file" "$table_file"
    else
        # All records deleted
        > "$table_file"
    fi
    
    show_success "$deleted_count record(s) deleted"
    log_db_op "DELETE" "$db_name" "$table_name" "count=$deleted_count"
    
    return 0
}