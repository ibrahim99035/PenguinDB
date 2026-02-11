#!/bin/bash

insert_into() {
    local table_name="$1"
    shift
    local values=("$@")
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_INSERT" || return 1
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    
    if [[ ! -f "$data_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    validate_row_data "$CURRENT_DB" "$table_name" "${values[@]}" || return 1
    
    local row_data=$(IFS="$FIELD_DELIMITER"; echo "${values[*]}")
    
    echo "$row_data" >> "$data_file"
    
    show_success "1 row inserted into '$table_name'"
    log_db_op "INSERT" "$CURRENT_DB" "$table_name"
    
    return 0
}

select_from() {
    local table_name="$1"
    local where_col="${2:-}"
    local where_val="${3:-}"
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_SELECT" || return 1
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    local meta_file="$DB_DIR/$CURRENT_DB/${table_name}.meta"
    
    if [[ ! -f "$data_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    local columns=($(get_column_names "$CURRENT_DB" "$table_name"))
    local col_count=${#columns[@]}
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local header_format=""
    for ((i=0; i<col_count; i++)); do
        header_format="${header_format}%-20s "
    done
    
    printf "$header_format\n" "${columns[@]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ ! -s "$data_file" ]]; then
        echo "No rows found"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        return 0
    fi
    
    local row_count=0
    
    if [[ -n "$where_col" && -n "$where_val" ]]; then
        local col_index=$(printf '%s\n' "${columns[@]}" | grep -n "^${where_col}$" | cut -d':' -f1)
        
        if [[ -z "$col_index" ]]; then
            show_error "Column '$where_col' not found"
            return 1
        fi
        
        while IFS="$FIELD_DELIMITER" read -r -a row; do
            if [[ "${row[$((col_index-1))]}" == "$where_val" ]]; then
                printf "$header_format\n" "${row[@]}"
                ((row_count++))
            fi
        done < "$data_file"
    else
        while IFS="$FIELD_DELIMITER" read -r -a row; do
            printf "$header_format\n" "${row[@]}"
            ((row_count++))
        done < "$data_file"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$row_count row(s) selected"
    echo ""
    
    log_db_op "SELECT" "$CURRENT_DB" "$table_name"
    
    return 0
}

update_table() {
    local table_name="$1"
    local set_col="$2"
    local set_val="$3"
    local where_col="$4"
    local where_val="$5"
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_UPDATE" || return 1
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    
    if [[ ! -f "$data_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    if [[ -z "$set_col" || -z "$where_col" ]]; then
        show_error "SET and WHERE columns are required"
        return 1
    fi
    
    local columns=($(get_column_names "$CURRENT_DB" "$table_name"))
    local set_idx=$(printf '%s\n' "${columns[@]}" | grep -n "^${set_col}$" | cut -d':' -f1)
    local where_idx=$(printf '%s\n' "${columns[@]}" | grep -n "^${where_col}$" | cut -d':' -f1)
    
    if [[ -z "$set_idx" ]]; then
        show_error "Column '$set_col' not found"
        return 1
    fi
    
    if [[ -z "$where_idx" ]]; then
        show_error "Column '$where_col' not found"
        return 1
    fi
    
    local set_type=$(get_column_type "$CURRENT_DB" "$table_name" "$set_col")
    validate_data_type "$set_val" "$set_type" || return 1
    
    local updated=0
    
    awk -F"$FIELD_DELIMITER" -v OFS="$FIELD_DELIMITER" \
        -v set_idx="$set_idx" -v set_val="$set_val" \
        -v where_idx="$where_idx" -v where_val="$where_val" \
        '{
            if ($where_idx == where_val) {
                $set_idx = set_val
                updated = 1
            }
            print
        }
        END {
            exit (!updated)
        }' "$data_file" > "$data_file.tmp"
    
    if [[ $? -eq 0 ]]; then
        mv "$data_file.tmp" "$data_file"
        updated=1
    else
        rm -f "$data_file.tmp"
        updated=0
    fi
    
    if [[ $updated -eq 1 ]]; then
        show_success "Row(s) updated in '$table_name'"
        log_db_op "UPDATE" "$CURRENT_DB" "$table_name"
        return 0
    else
        show_warning "No rows matched the WHERE condition"
        return 0
    fi
}

delete_from() {
    local table_name="$1"
    local where_col="$2"
    local where_val="$3"
    
    require_auth || return 1
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected"
        return 1
    fi
    
    require_permission "$CURRENT_DB" "$table_name" "$PERM_DELETE" || return 1
    
    local data_file="$DB_DIR/$CURRENT_DB/${table_name}.data"
    
    if [[ ! -f "$data_file" ]]; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    if [[ -z "$where_col" ]]; then
        read -p "Delete ALL rows from '$table_name'? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            show_info "Delete cancelled"
            return 1
        fi
        
        > "$data_file"
        show_success "All rows deleted from '$table_name'"
        log_db_op "DELETE_ALL" "$CURRENT_DB" "$table_name"
        return 0
    fi
    
    local columns=($(get_column_names "$CURRENT_DB" "$table_name"))
    local where_idx=$(printf '%s\n' "${columns[@]}" | grep -n "^${where_col}$" | cut -d':' -f1)
    
    if [[ -z "$where_idx" ]]; then
        show_error "Column '$where_col' not found"
        return 1
    fi
    
    awk -F"$FIELD_DELIMITER" -v where_idx="$where_idx" -v where_val="$where_val" \
        '$where_idx != where_val' "$data_file" > "$data_file.tmp"
    
    mv "$data_file.tmp" "$data_file"
    
    show_success "Row(s) deleted from '$table_name'"
    log_db_op "DELETE" "$CURRENT_DB" "$table_name"
    
    return 0
}