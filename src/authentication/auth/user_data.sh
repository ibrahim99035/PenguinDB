#!/bin/bash

user_exists(){
    local username="$1"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        return 1
    fi
    
    grep -q "^${username}${FIELD_DELIMITER}" "$USERS_FILE"
}

get_user_record(){
    local username="$1"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        return 1
    fi
    
    grep "^${username}${FIELD_DELIMITER}" "$USERS_FILE"
}

#1=username - 2=password_hash - 3=email - 4=role - 5=created_at - 6=status
get_user_field(){
    local username="$1"
    local field_index="$2"
    
    local record=$(get_user_record "$username")
    
    if [[ -z "$record" ]]; then
        return 1
    fi
    
    echo "$record" | cut -d"$FIELD_DELIMITER" -f"$field_index"
}

get_user_password_hash(){
    local username="$1"
    get_user_field "$username" 2
}

get_user_email(){
    local username="$1"
    get_user_field "$username" 3
}

get_user_role(){
    local username="${1:-$CURRENT_USER}"
    get_user_field "$username" 4
}

get_user_status(){
    local username="$1"
    get_user_field "$username" 6
}

#username|password_hash|email|role|created_at|status
create_user_record(){
    local username="$1"
    local password_hash="$2"
    local email="$3"
    local role="$4"
    
    local created_at=$(date '+%Y-%m-%d %H:%M:%S')
    local status="active"
    
    local user_record="${username}${FIELD_DELIMITER}${password_hash}${FIELD_DELIMITER}${email}${FIELD_DELIMITER}${role}${FIELD_DELIMITER}${created_at}${FIELD_DELIMITER}${status}"
    
    echo "$user_record" >> "$USERS_FILE"
}

update_user_password(){
    local username="$1"
    local new_hash="$2"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        return 1
    fi
    
    local record=$(get_user_record "$username")
    local email=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f3)
    local role=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f4)
    local created_at=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f5)
    local status=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f6)
    
    local new_record="${username}${FIELD_DELIMITER}${new_hash}${FIELD_DELIMITER}${email}${FIELD_DELIMITER}${role}${FIELD_DELIMITER}${created_at}${FIELD_DELIMITER}${status}"
    
    #Replace old record with new one
    sed -i.bak "s|^${username}${FIELD_DELIMITER}.*|${new_record}|" "$USERS_FILE"
}

update_user_status(){
    local username="$1"
    local new_status="$2"
    
    if [[ ! -f "$USERS_FILE" ]]; then
        return 1
    fi
    
    #Replace status field
    sed -i.bak "s/^\(${username}${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}\)[^${FIELD_DELIMITER}]*$/\1${new_status}/" "$USERS_FILE"
}