#!/bin/bash

# UPDATE Operation Module
# Update records in tables

# Update records from SQL statement
update_records_sql() {
    local db_name=$1
    local sql=$2
    
    require_auth || return 1
    
    # Parse UPDATE statement
    local parsed=$(parse_update_statement "$sql")
    
    if [[ -z "$parsed" ]]; then
        return 1
    fi
    
    local table_name=$(echo "$parsed" | cut -d'|' -f1)
    local set_clause=$(echo "$parsed" | cut -d'|' -f2)
    local where=$(echo "$parsed" | cut -d'|' -f3)
    
    # Check permission
    if ! require_permission "$db_name" "$table_name" "$PERM_UPDATE"; then
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    # Update records
    update_records "$db_name" "$table_name" "$set_clause" "$where"
}

# Update records in table
update_records() {
    local db_name=$1
    local table_name=$2
    local set_clause=$3    # "column=value" or "col1=val1, col2=val2"
    local where=$4         # WHERE clause (optional)
    
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
        show_info "No records to update"
        return 0
    fi
    
    # Parse SET clause (column=value pairs)
    declare -A updates
    
    # Split by comma
    IFS=',' read -ra set_parts <<< "$set_clause"
    
    for part in "${set_parts[@]}"; do
        # Parse column=value
        if [[ "$part" =~ ([a-zA-Z0-9_]+)[[:space:]]*=[[:space:]]*(.+) ]]; then
            local col="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"
            
            # Remove quotes
            val=$(echo "$val" | sed "s/^['\"]//;s/['\"]$//")
            
            updates[$col]="$val"
        fi
    done
    
    if [[ ${#updates[@]} -eq 0 ]]; then
        show_error "No updates specified"
        return 1
    fi
    
    # Process records
    local updated_count=0
    
    while IFS= read -r record; do
        # Check if record matches WHERE clause
        local should_update=true
        
        if [[ -n "$where" ]]; then
            if ! evaluate_where_clause "$schema" "$record" "$where"; then
                should_update=false
            fi
        fi
        
        if [[ $should_update == true ]]; then
            # Update the record
            local new_record=$(update_single_record "$schema" "$record" updates)
            echo "$new_record" >> "$temp_file"
            ((updated_count++))
        else
            # Keep original record
            echo "$record" >> "$temp_file"
        fi
    done < "$table_file"
    
    # Replace original file with updated one
    mv "$temp_file" "$table_file"
    
    show_success "$updated_count record(s) updated"
    log_db_op "UPDATE" "$db_name" "$table_name" "count=$updated_count"
    
    return 0
}

# Update single record
update_single_record() {
    local schema=$1
    local record=$2
    local -n update_map=$3
    
    # Split record into fields
    IFS="$FIELD_DELIMITER" read -ra fields <<< "$record"
    
    # Build column name to index mapping
    local col_index=0
    declare -A col_info
    
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints rest; do
        col_info["${col_name}_index"]=$col_index
        col_info["${col_name}_type"]=$col_type
        col_info["${col_name}_size"]=$col_size
        col_info["${col_name}_constraints"]=$col_constraints
        ((col_index++))
    done <<< "$schema"
    
    # Update fields
    for col_name in "${!update_map[@]}"; do
        local new_value="${update_map[$col_name]}"
        local idx=${col_info["${col_name}_index"]}
        local type=${col_info["${col_name}_type"]}
        local size=${col_info["${col_name}_size"]}
        local constraints=${col_info["${col_name}_constraints"]}
        
        # Validate new value
        if [[ "$constraints" =~ NOT\ NULL ]] && [[ "$new_value" == "NULL" || -z "$new_value" ]]; then
            show_error "Column '$col_name' cannot be NULL"
            continue
        fi
        
        if [[ "$new_value" != "NULL" ]]; then
            if ! validate_value "$new_value" "$type" "$size"; then
                show_error "Invalid value for column '$col_name'"
                continue
            fi
        fi
        
        # Serialize and update
        fields[$idx]=$(serialize_value "$new_value" "$type")
    done
    
    # Rebuild record
    local new_record=""
    for ((i=0; i<${#fields[@]}; i++)); do
        if [[ $i -gt 0 ]]; then
            new_record+="$FIELD_DELIMITER"
        fi
        new_record+="${fields[$i]}"
    done
    
    echo "$new_record"
}