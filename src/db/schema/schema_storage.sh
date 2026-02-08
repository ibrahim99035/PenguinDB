#!/bin/bash

#column_name|data_type|size|constraints|default
save_table_schema(){
    local db_name=$1
    local table_name=$2
    local schema=$3
    
    local meta_dir="$DB_DIR/$db_name/.metadata"
    local meta_file="$meta_dir/${table_name}.meta"
    
    mkdir -p "$meta_dir"
    
    echo "$schema" > "$meta_file"
    
    log_db_op "SAVE_SCHEMA" "$db_name" "$table_name"
}

load_table_schema(){
    local db_name=$1
    local table_name=$2
    
    local meta_file="$DB_DIR/$db_name/.metadata/${table_name}.meta"
    
    if [[ ! -f "$meta_file" ]]; then
        return 1
    fi
    
    cat "$meta_file"
}

table_exists(){
    local db_name=$1
    local table_name=$2
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    local meta_file="$DB_DIR/$db_name/.metadata/${table_name}.meta"
    
    [[ -f "$table_file" && -f "$meta_file" ]]
}

#type|size|constraints|default
get_column_info(){
    local db_name=$1
    local table_name=$2
    local column_name=$3
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        return 1
    fi
    
    echo "$schema" | grep "^${column_name}${FIELD_DELIMITER}"
}

get_table_columns() {
    local db_name=$1
    local table_name=$2
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        return 1
    fi
    
    echo "$schema" | cut -d"$FIELD_DELIMITER" -f1
}

get_column_count() {
    local db_name=$1
    local table_name=$2
    
    get_table_columns "$db_name" "$table_name" | wc -l
}

get_column_type() {
    local db_name=$1
    local table_name=$2
    local column_name=$3
    
    local column_info=$(get_column_info "$db_name" "$table_name" "$column_name")
    
    if [[ -z "$column_info" ]]; then
        return 1
    fi
    
    echo "$column_info" | cut -d"$FIELD_DELIMITER" -f2
}

get_column_size() {
    local db_name=$1
    local table_name=$2
    local column_name=$3
    
    local column_info=$(get_column_info "$db_name" "$table_name" "$column_name")
    
    if [[ -z "$column_info" ]]; then
        return 1
    fi
    
    echo "$column_info" | cut -d"$FIELD_DELIMITER" -f3
}

get_column_constraints() {
    local db_name=$1
    local table_name=$2
    local column_name=$3
    
    local column_info=$(get_column_info "$db_name" "$table_name" "$column_name")
    
    if [[ -z "$column_info" ]]; then
        return 1
    fi
    
    echo "$column_info" | cut -d"$FIELD_DELIMITER" -f4
}

get_column_default(){
    local db_name=$1
    local table_name=$2
    local column_name=$3
    
    local column_info=$(get_column_info "$db_name" "$table_name" "$column_name")
    
    if [[ -z "$column_info" ]]; then
        return 1
    fi
    
    echo "$column_info" | cut -d"$FIELD_DELIMITER" -f5
}

column_has_constraint(){
    local db_name=$1
    local table_name=$2
    local column_name=$3
    local constraint=$4
    
    local constraints=$(get_column_constraints "$db_name" "$table_name" "$column_name")
    
    [[ "$constraints" =~ $constraint ]]
}

get_primary_key_column(){
    local db_name=$1
    local table_name=$2
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        return 1
    fi
    
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        if [[ "$col_constraints" =~ PRIMARY[[:space:]]KEY ]]; then
            echo "$col_name"
            return 0
        fi
    done <<< "$schema"
    
    return 1
}

display_table_schema(){
    local db_name=$1
    local table_name=$2
    
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        show_error "Table schema not found"
        return 1
    fi
    
    echo ""
    echo "Table: $table_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-15s %-10s %-20s %-15s\n" "COLUMN" "TYPE" "SIZE" "CONSTRAINTS" "DEFAULT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS="$FIELD_DELIMITER" read -r col_name col_type col_size col_constraints col_default; do
        printf "%-20s %-15s %-10s %-20s %-15s\n" \
            "$col_name" \
            "$col_type" \
            "${col_size:--}" \
            "${col_constraints:--}" \
            "${col_default:--}"
    done <<< "$schema"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}