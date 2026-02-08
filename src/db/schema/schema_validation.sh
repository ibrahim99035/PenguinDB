#!/bin/bash

# Schema Validator Module
# Validate schema definitions and constraints

# Validate table schema
validate_table_schema() {
    local schema=$1
    
    # Check if schema is empty
    if [[ -z "$schema" ]]; then
        show_error "Schema cannot be empty"
        return 1
    fi
    
    # Check for duplicate column names
    local columns=$(echo "$schema" | cut -d"$FIELD_DELIMITER" -f1)
    local unique_cols=$(echo "$columns" | sort -u | wc -l)
    local total_cols=$(echo "$columns" | wc -l)
    
    if [[ $unique_cols -ne $total_cols ]]; then
        show_error "Duplicate column names found"
        return 1
    fi
    
    # Check for multiple PRIMARY KEY constraints
    local pk_count=$(echo "$schema" | grep -c "PRIMARY KEY")
    if [[ $pk_count -gt 1 ]]; then
        show_error "Multiple PRIMARY KEY constraints found (only one allowed)"
        return 1
    fi
    
    # Validate each column
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        # Validate column name
        if [[ ! "$col_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
            show_error "Invalid column name: $col_name (must start with letter, contain only letters, numbers, and underscores)"
            return 1
        fi
        
        # Validate data type
        if ! is_valid_type "$col_type"; then
            show_error "Invalid data type: $col_type"
            return 1
        fi
        
        # Validate default value if present
        if [[ -n "$col_default" && "$col_default" != "NULL" ]]; then
            if ! validate_value "$col_default" "$col_type" "$col_size"; then
                show_error "Invalid default value for column $col_name"
                return 1
            fi
        fi
        
    done <<< "$schema"
    
    return 0
}

# Validate column name
validate_column_name() {
    local column_name=$1
    
    if [[ ! "$column_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        show_error "Invalid column name: $column_name"
        return 1
    fi
    
    return 0
}

# Validate table name
validate_table_name() {
    local table_name=$1
    
    if [[ ! "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        show_error "Invalid table name: $table_name (must start with letter)"
        return 1
    fi
    
    # Check reserved words
    case "$table_name" in
        SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|TABLE|FROM|WHERE|ORDER|BY|LIMIT)
            show_error "Table name cannot be a reserved word: $table_name"
            return 1
            ;;
    esac
    
    return 0
}