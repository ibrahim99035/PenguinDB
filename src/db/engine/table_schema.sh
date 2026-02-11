#!/bin/bash

validate_column_type() {
    local col_type="$1"
    
    case "$col_type" in
        TEXT|NUMBER|DATE)
            return 0
            ;;
        *)
            show_error "Invalid data type: $col_type. Allowed: TEXT, NUMBER, DATE"
            return 1
            ;;
    esac
}

validate_constraint() {
    local constraint="$1"
    
    case "$constraint" in
        UNIQUE|"NOT NULL"|PRIMARYKEY|"")
            return 0
            ;;
        *)
            show_error "Invalid constraint: $constraint. Allowed: UNIQUE, NOT NULL, PRIMARYKEY"
            return 1
            ;;
    esac
}

parse_column_definition() {
    local col_def="$1"
    
    local col_name=$(echo "$col_def" | awk '{print $1}')
    local col_type=$(echo "$col_def" | awk '{print $2}')
    local col_constraint=$(echo "$col_def" | awk '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":"")}')
    
    if [[ -z "$col_name" || -z "$col_type" ]]; then
        show_error "Column definition must have name and type"
        return 1
    fi
    
    if [[ ! "$col_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        show_error "Invalid column name: $col_name"
        return 1
    fi
    
    validate_column_type "$col_type" || return 1
    validate_constraint "$col_constraint" || return 1
    
    echo "${col_name}:${col_type}:${col_constraint}"
}

create_table_schema() {
    local db_name="$1"
    local table_name="$2"
    shift 2
    local column_defs=("$@")
    
    local meta_file="$DB_DIR/$db_name/${table_name}.meta"
    
    > "$meta_file"
    
    local primary_key_count=0
    
    for col_def in "${column_defs[@]}"; do
        local parsed=$(parse_column_definition "$col_def") || return 1
        
        if [[ "$parsed" == *":PRIMARYKEY"* ]]; then
            ((primary_key_count++))
            if [[ $primary_key_count -gt 1 ]]; then
                show_error "Only one primary key allowed per table"
                return 1
            fi
        fi
        
        echo "$parsed" >> "$meta_file"
    done
    
    return 0
}

get_table_schema() {
    local db_name="$1"
    local table_name="$2"
    
    local meta_file="$DB_DIR/$db_name/${table_name}.meta"
    
    if [[ ! -f "$meta_file" ]]; then
        return 1
    fi
    
    cat "$meta_file"
}

get_column_names() {
    local db_name="$1"
    local table_name="$2"
    
    get_table_schema "$db_name" "$table_name" | cut -d':' -f1
}

get_column_type() {
    local db_name="$1"
    local table_name="$2"
    local col_name="$3"
    
    get_table_schema "$db_name" "$table_name" | grep "^${col_name}:" | cut -d':' -f2
}

get_column_constraint() {
    local db_name="$1"
    local table_name="$2"
    local col_name="$3"
    
    get_table_schema "$db_name" "$table_name" | grep "^${col_name}:" | cut -d':' -f3
}

get_primary_key() {
    local db_name="$1"
    local table_name="$2"
    
    get_table_schema "$db_name" "$table_name" | grep ":PRIMARYKEY$" | cut -d':' -f1
}