#!/bin/bash

# Table Create Module
# Create new tables with schema

# Create table from SQL statement
create_table_sql() {
    local db_name=$1
    local sql=$2
    
    require_auth || return 1
    
    # Check database access
    if ! has_db_permission "$db_name" "$CURRENT_USER" "$PERM_INSERT"; then
        show_error "You don't have permission to create tables in database '$db_name'"
        return 1
    fi
    
    # Parse CREATE TABLE statement
    local parsed=$(parse_create_table "$sql")
    
    if [[ -z "$parsed" ]]; then
        return 1
    fi
    
    local table_name=$(echo "$parsed" | cut -d'|' -f1)
    local column_defs=$(echo "$parsed" | cut -d'|' -f2-)
    
    # Validate table name
    validate_table_name "$table_name" || return 1
    
    # Check if table already exists
    if table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' already exists"
        return 1
    fi
    
    # Parse column definitions
    local schema=$(parse_column_definitions "$column_defs")
    
    if [[ -z "$schema" ]]; then
        show_error "Failed to parse column definitions"
        return 1
    fi
    
    # Validate schema
    if ! validate_table_schema "$schema"; then
        return 1
    fi
    
    # Create table
    create_table "$db_name" "$table_name" "$schema"
}

# Create table with schema
create_table() {
    local db_name=$1
    local table_name=$2
    local schema=$3
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    local meta_dir="$DB_DIR/$db_name/.metadata"
    
    # Create metadata directory
    mkdir -p "$meta_dir"
    
    # Create empty table file
    touch "$table_file"
    
    # Save schema
    save_table_schema "$db_name" "$table_name" "$schema"
    
    show_success "Table '$table_name' created successfully"
    log_db_op "CREATE_TABLE" "$db_name" "$table_name"
    
    return 0
}

# Create table interactively (for CLI)
create_table_interactive() {
    local db_name=$1
    
    if [[ -z "$db_name" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_auth || return 1
    
    # Check permission
    if ! has_db_permission "$db_name" "$CURRENT_USER" "$PERM_INSERT"; then
        show_error "You don't have permission to create tables in this database"
        return 1
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Create Table"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Get table name
    read -p "Table name: " table_name
    
    validate_table_name "$table_name" || return 1
    
    if table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' already exists"
        return 1
    fi
    
    # Build schema interactively
    local schema=""
    local col_num=1
    
    echo ""
    echo "Define columns (press Enter with empty name to finish):"
    echo ""
    show_supported_types
    echo ""
    
    while true; do
        echo "Column $col_num:"
        
        read -p "  Name: " col_name
        
        # Empty name = done
        if [[ -z "$col_name" ]]; then
            if [[ $col_num -eq 1 ]]; then
                show_error "At least one column is required"
                continue
            fi
            break
        fi
        
        validate_column_name "$col_name" || continue
        
        read -p "  Type (INT/VARCHAR/TEXT/DATE/BOOLEAN/FLOAT): " col_type
        col_type=$(echo "$col_type" | tr '[:lower:]' '[:upper:]')
        
        if ! is_valid_type "$col_type"; then
            show_error "Invalid type"
            continue
        fi
        
        # Get size for VARCHAR
        local col_size=""
        if [[ "$col_type" == "VARCHAR" ]]; then
            read -p "  Size: " col_size
        fi
        
        # Get constraints
        local col_constraints=""
        
        read -p "  Primary Key? (y/n): " is_pk
        if [[ "$is_pk" =~ ^[Yy] ]]; then
            # Check if PK already exists
            if [[ "$schema" =~ PRIMARY\ KEY ]]; then
                show_error "Primary key already defined"
                continue
            fi
            col_constraints+="PRIMARY KEY "
        fi
        
        read -p "  Unique? (y/n): " is_unique
        if [[ "$is_unique" =~ ^[Yy] ]]; then
            col_constraints+="UNIQUE "
        fi
        
        read -p "  Not Null? (y/n): " is_not_null
        if [[ "$is_not_null" =~ ^[Yy] ]]; then
            col_constraints+="NOT NULL "
        fi
        
        # Trim constraints
        col_constraints=$(echo "$col_constraints" | sed 's/[[:space:]]*$//')
        
        # Get default value
        local col_default=""
        read -p "  Default value (leave empty for none): " col_default
        
        # Build column definition
        local col_def="${col_name}${FIELD_DELIMITER}${col_type}${FIELD_DELIMITER}${col_size}${FIELD_DELIMITER}${col_constraints}${FIELD_DELIMITER}${col_default}"
        
        # Add to schema
        if [[ -n "$schema" ]]; then
            schema+=$'\n'
        fi
        schema+="$col_def"
        
        ((col_num++))
        echo ""
    done
    
    if [[ -z "$schema" ]]; then
        show_error "No columns defined"
        return 1
    fi
    
    # Validate schema
    if ! validate_table_schema "$schema"; then
        return 1
    fi
    
    # Create table
    create_table "$db_name" "$table_name" "$schema"
    
    echo ""
    echo "Table structure:"
    display_table_schema "$db_name" "$table_name"
}