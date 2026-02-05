#!/bin/bash

init_db_permissions(){
    local db_name="$1"
    local metadata_dir="$DB_DIR/$db_name/.metadata"
    
    mkdir -p "$metadata_dir"
    
    local perm_file="$metadata_dir/.permissions"
    
    if [[ ! -f "$perm_file" ]]; then
        touch "$perm_file"
    fi
}

get_permissions_file(){
    local db_name="$1"
    echo "$DB_DIR/$db_name/.metadata/.permissions"
}

add_permission_record(){
    local db_name="$1"
    local username="$2"
    local table_name="$3"
    local permission="$4"
    
    local perm_file=$(get_permissions_file "$db_name")
    local perm_record="${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${table_name}${FIELD_DELIMITER}${permission}"
    
    echo "$perm_record" >> "$perm_file"
}

remove_permission_record(){
    local db_name="$1"
    local username="$2"
    local table_name="$3"
    local permission="$4"
    
    local perm_file=$(get_permissions_file "$db_name")
    local perm_pattern="^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${table_name}${FIELD_DELIMITER}${permission}$"
    
    sed -i.bak "/${perm_pattern}/d" "$perm_file"
}

permission_exists(){
    local db_name="$1"
    local username="$2"
    local table_name="$3"
    local permission="$4"
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" ]]; then
        return 1
    fi
    
    local perm_pattern="^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}${table_name}${FIELD_DELIMITER}${permission}$"
    
    grep -q "$perm_pattern" "$perm_file"
}

remove_all_user_permissions(){
    local db_name="$1"
    local username="$2"
    
    local perm_file=$(get_permissions_file "$db_name")
    
    if [[ ! -f "$perm_file" ]]; then
        return 1
    fi
    
    sed -i.bak "/^${username}${FIELD_DELIMITER}${db_name}${FIELD_DELIMITER}/d" "$perm_file"
}