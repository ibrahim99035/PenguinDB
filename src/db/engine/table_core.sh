#!/bin/bash

create_table() {
    local table_name="$1"
    shift
    local column_defs=("$@")
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected. Use 'use_database <name>' first"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "" "$PERM_INSERT" || return 1
    
    if [[ -z "$table_name" ]]; then
        show_error "Table name is required"
        return 1
    fi
    
    if [[ ! "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        show_error "Invalid table name"
        return 1
    fi
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    local meta_file="$DB_DIR/$CURRENT_DB/${table_name}.meta"
    
    if [[ -f "$data_file" || -f "$meta_file" ]]; then
        show_error "Table '$table_name' already exists"
        return 1
    fi
    
    if [[ ${#column_defs[@]} -eq 0 ]]; then
        show_error "At least one column is required"
        return 1
    fi
    
    create_table_schema "$CURRENT_DB" "$table_name" "${column_defs[@]}" || return 1
    
    touch "$data_file"
    
    show_success "Table '$table_name' created successfully"
    log_db_op "CREATE_TABLE" "$CURRENT_DB" "$table_name"
    
    return 0
}

list_tables() {
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "" "$PERM_SELECT" || return 1
    
    local db_path="$DB_DIR/$CURRENT_DB"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tables in database: $CURRENT_DB"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local found=0
    for table_file in "$db_path"/*.data; do
        [[ -f "$table_file" ]] || continue
        
        local table_name=$(basename "$table_file" .data)
        echo "  $table_name"
        found=1
    done
    
    if [[ $found -eq 0 ]]; then
        echo "  No tables found"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_db_op "LIST_TABLES" "$CURRENT_DB" ""
}

describe_table() {
    local table_name="$1"
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_SELECT" || return 1
    
    local meta_file="$DB_DIR/$CURRENT_DB/${table_name}.meta"
    
    if [[ ! -f "$meta_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Schema for table: $CURRENT_DB.$table_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-15s %-20s\n" "COLUMN" "TYPE" "CONSTRAINT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS=':' read -r col_name col_type col_constraint; do
        printf "%-20s %-15s %-20s\n" "$col_name" "$col_type" "${col_constraint:-none}"
    done < "$meta_file"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_db_op "DESCRIBE_TABLE" "$CURRENT_DB" "$table_name"
}

drop_table() {
    local table_name="$1"
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_DELETE" || return 1
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    local meta_file="$DB_DIR/$CURRENT_DB/${table_name}.meta"
    
    if [[ ! -f "$data_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    read -p "Are you sure you want to drop table '$table_name'? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        show_info "Drop table cancelled"
        return 1
    fi
    
    rm -f "$data_file" "$meta_file"
    
    show_success "Table '$table_name' dropped successfully"
    log_db_op "DROP_TABLE" "$CURRENT_DB" "$table_name"
    
    return 0
}