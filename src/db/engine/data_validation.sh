#!/bin/bash

validate_text_value() {
    local value="$1"
    return 0
}

validate_number_value() {
    local value="$1"
    
    if [[ ! "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        return 1
    fi
    
    return 0
}

validate_date_value() {
    local value="$1"
    
    if [[ ! "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi
    
    local year=$(echo "$value" | cut -d'-' -f1)
    local month=$(echo "$value" | cut -d'-' -f2)
    local day=$(echo "$value" | cut -d'-' -f3)
    
    if [[ $month -lt 1 || $month -gt 12 ]]; then
        return 1
    fi
    
    if [[ $day -lt 1 || $day -gt 31 ]]; then
        return 1
    fi
    
    return 0
}

validate_data_type() {
    local value="$1"
    local data_type="$2"
    
    case "$data_type" in
        TEXT)
            validate_text_value "$value"
            ;;
        NUMBER)
            if ! validate_number_value "$value"; then
                show_error "Invalid NUMBER value: $value"
                return 1
            fi
            ;;
        DATE)
            if ! validate_date_value "$value"; then
                show_error "Invalid DATE value: $value (expected YYYY-MM-DD)"
                return 1
            fi
            ;;
        *)
            show_error "Unknown data type: $data_type"
            return 1
            ;;
    esac
    
    return 0
}

check_not_null() {
    local value="$1"
    
    if [[ -z "$value" ]]; then
        return 1
    fi
    
    return 0
}

check_unique() {
    local db_name="$1"
    local table_name="$2"
    local col_name="$3"
    local value="$4"
    
    local data_file="$DB_DIR/$db_name/${table_name}.data"
    
    if [[ ! -f "$data_file" || ! -s "$data_file" ]]; then
        return 0
    fi
    
    local col_index=$(get_column_names "$db_name" "$table_name" | grep -n "^${col_name}$" | cut -d':' -f1)
    
    if awk -F"$FIELD_DELIMITER" -v idx="$col_index" -v val="$value" '$idx == val {exit 1}' "$data_file"; then
        return 0
    else
        return 1
    fi
}

check_primary_key() {
    local db_name="$1"
    local table_name="$2"
    local col_name="$3"
    local value="$4"
    
    if ! check_not_null "$value"; then
        show_error "Primary key '$col_name' cannot be NULL"
        return 1
    fi
    
    if ! check_unique "$db_name" "$table_name" "$col_name" "$value"; then
        show_error "Primary key '$col_name' value '$value' already exists"
        return 1
    fi
    
    return 0
}

validate_row_data() {
    local db_name="$1"
    local table_name="$2"
    shift 2
    local values=("$@")
    
    local schema=$(get_table_schema "$db_name" "$table_name")
    local col_count=$(echo "$schema" | wc -l)
    
    if [[ ${#values[@]} -ne $col_count ]]; then
        show_error "Expected $col_count values, got ${#values[@]}"
        return 1
    fi
    
    local idx=0
    while IFS=':' read -r col_name col_type col_constraint; do
        local value="${values[$idx]}"
        
        validate_data_type "$value" "$col_type" || return 1
        
        if [[ "$col_constraint" == "NOT NULL" ]]; then
            if ! check_not_null "$value"; then
                show_error "Column '$col_name' cannot be NULL"
                return 1
            fi
        fi
        
        if [[ "$col_constraint" == "UNIQUE" ]]; then
            if [[ -n "$value" ]] && ! check_unique "$db_name" "$table_name" "$col_name" "$value"; then
                show_error "Value '$value' already exists in UNIQUE column '$col_name'"
                return 1
            fi
        fi
        
        if [[ "$col_constraint" == "PRIMARYKEY" ]]; then
            check_primary_key "$db_name" "$table_name" "$col_name" "$value" || return 1
        fi
        
        ((idx++))
    done <<< "$schema"
    
    return 0
}