#!/bin/bash

# INSERT Operation Module
# Insert data into tables with validation

# Insert record from SQL statement
insert_record_sql() {
    local db_name=$1
    local sql=$2
    
    require_auth || return 1
    
    # Parse INSERT statement
    local parsed=$(parse_insert_statement "$sql")
    
    if [[ -z "$parsed" ]]; then
        return 1
    fi
    
    local table_name=$(echo "$parsed" | cut -d'|' -f1)
    local columns=$(echo "$parsed" | cut -d'|' -f2)
    local values=$(echo "$parsed" | cut -d'|' -f3)
    
    # Check permission
    if ! require_permission "$db_name" "$table_name" "$PERM_INSERT"; then
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    # Insert record
    insert_record "$db_name" "$table_name" "$columns" "$values"
}

# Insert record into table
insert_record() {
    local db_name=$1
    local table_name=$2
    local columns=$3      # Comma-separated or empty (for all columns)
    local values=$4       # Comma-separated values
    
    # Load schema
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        show_error "Failed to load table schema"
        return 1
    fi
    
    # Parse values (handle quoted strings with commas)
    local value_array=()
    parse_values "$values" value_array
    
    # If columns specified, validate count
    if [[ -n "$columns" ]]; then
        # Parse column names
        local column_array=()
        IFS=',' read -ra column_array <<< "$columns"
        
        if [[ ${#column_array[@]} -ne ${#value_array[@]} ]]; then
            show_error "Column count (${#column_array[@]}) doesn't match value count (${#value_array[@]})"
            return 1
        fi
        
        # Build record with specified columns
        build_record_with_columns "$db_name" "$table_name" column_array value_array
    else
        # Use all columns in schema order
        local total_cols=$(get_column_count "$db_name" "$table_name")
        
        if [[ ${#value_array[@]} -ne $total_cols ]]; then
            show_error "Value count (${#value_array[@]}) doesn't match column count ($total_cols)"
            return 1
        fi
        
        # Build record with all columns
        build_record_all_columns "$db_name" "$table_name" value_array
    fi
}

# Parse comma-separated values (handle quoted strings)
parse_values() {
    local values_str=$1
    local -n result_array=$2
    
    local current=""
    local in_quote=false
    local quote_char=""
    
    for ((i=0; i<${#values_str}; i++)); do
        local char="${values_str:$i:1}"
        
        if [[ "$char" == "'" || "$char" == '"' ]]; then
            if [[ $in_quote == false ]]; then
                in_quote=true
                quote_char="$char"
            elif [[ "$char" == "$quote_char" ]]; then
                in_quote=false
                quote_char=""
            else
                current+="$char"
            fi
        elif [[ "$char" == "," && $in_quote == false ]]; then
            # Trim whitespace
            current=$(echo "$current" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            result_array+=("$current")
            current=""
        else
            current+="$char"
        fi
    done
    
    # Add last value
    current=$(echo "$current" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    result_array+=("$current")
}

# Build record with specified columns
build_record_with_columns() {
    local db_name=$1
    local table_name=$2
    local -n col_array=$3
    local -n val_array=$4
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    local record=""
    local col_index=0
    
    # Process each column in schema
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        # Find value for this column
        local value=""
        local found=false
        
        for ((i=0; i<${#col_array[@]}; i++)); do
            if [[ "${col_array[$i]}" == "$col_name" ]]; then
                value="${val_array[$i]}"
                found=true
                break
            fi
        done
        
        # If not provided, use default or NULL
        if [[ $found == false ]]; then
            if [[ -n "$col_default" ]]; then
                value="$col_default"
            else
                value="NULL"
            fi
        fi
        
        # Validate NOT NULL constraint
        if [[ "$col_constraints" =~ NOT\ NULL ]] && [[ "$value" == "NULL" || -z "$value" ]]; then
            show_error "Column '$col_name' cannot be NULL"
            return 1
        fi
        
        # Validate value
        if [[ "$value" != "NULL" ]]; then
            if ! validate_value "$value" "$col_type" "$col_size"; then
                show_error "Invalid value for column '$col_name'"
                return 1
            fi
        fi
        
        # Check UNIQUE constraint
        if [[ "$col_constraints" =~ UNIQUE ]] || [[ "$col_constraints" =~ PRIMARY\ KEY ]]; then
            if ! check_unique_value "$db_name" "$table_name" "$col_name" "$value"; then
                show_error "Duplicate value for unique column '$col_name': $value"
                return 1
            fi
        fi
        
        # Serialize value
        local serialized=$(serialize_value "$value" "$col_type")
        
        # Add to record
        if [[ $col_index -gt 0 ]]; then
            record+="$FIELD_DELIMITER"
        fi
        record+="$serialized"
        
        ((col_index++))
    done <<< "$schema"
    
    # Append record to table file
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    echo "$record" >> "$table_file"
    
    show_success "Record inserted successfully"
    log_db_op "INSERT" "$db_name" "$table_name"
    
    return 0
}

# Build record with all columns (in schema order)
build_record_all_columns() {
    local db_name=$1
    local table_name=$2
    local -n val_array=$3
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    local record=""
    local col_index=0
    
    # Process each column in schema
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        local value="${val_array[$col_index]}"
        
        # Validate NOT NULL constraint
        if [[ "$col_constraints" =~ NOT\ NULL ]] && [[ "$value" == "NULL" || -z "$value" ]]; then
            show_error "Column '$col_name' cannot be NULL"
            return 1
        fi
        
        # Validate value
        if [[ "$value" != "NULL" ]]; then
            if ! validate_value "$value" "$col_type" "$col_size"; then
                show_error "Invalid value for column '$col_name'"
                return 1
            fi
        fi
        
        # Check UNIQUE constraint
        if [[ "$col_constraints" =~ UNIQUE ]] || [[ "$col_constraints" =~ PRIMARY\ KEY ]]; then
            if ! check_unique_value "$db_name" "$table_name" "$col_name" "$value"; then
                show_error "Duplicate value for unique column '$col_name': $value"
                return 1
            fi
        fi
        
        # Serialize value
        local serialized=$(serialize_value "$value" "$col_type")
        
        # Add to record
        if [[ $col_index -gt 0 ]]; then
            record+="$FIELD_DELIMITER"
        fi
        record+="$serialized"
        
        ((col_index++))
    done <<< "$schema"
    
    # Append record to table file
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    echo "$record" >> "$table_file"
    
    show_success "Record inserted successfully"
    log_db_op "INSERT" "$db_name" "$table_name"
    
    return 0
}

# Check if value is unique in column
check_unique_value() {
    local db_name=$1
    local table_name=$2
    local column_name=$3
    local value=$4
    
    # NULL values are always allowed for unique constraint
    if [[ "$value" == "NULL" || -z "$value" ]]; then
        return 0
    fi
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    
    # If table is empty, value is unique
    if [[ ! -s "$table_file" ]]; then
        return 0
    fi
    
    # Get column index
    local schema=$(load_table_schema "$db_name" "$table_name")
    local col_index=1
    local found_col=false
    
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        if [[ "$col_name" == "$column_name" ]]; then
            found_col=true
            break
        fi
        ((col_index++))
    done <<< "$schema"
    
    if [[ $found_col == false ]]; then
        return 1
    fi
    
    # Check if value exists
    while IFS="$FIELD_DELIMITER" read -r -a fields; do
        local existing_value=$(deserialize_value "${fields[$((col_index-1))]}")
        
        if [[ "$existing_value" == "$value" ]]; then
            return 1  # Duplicate found
        fi
    done < "$table_file"
    
    return 0  # Value is unique
}