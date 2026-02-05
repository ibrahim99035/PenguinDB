#!/bin/bash

generate_session_token(){
    echo "$(date +%s)_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
}

create_session(){
    local username="$1"
    
    local session_token=$(generate_session_token)
    local created_at=$(date '+%Y-%m-%d %H:%M:%S')
    local expires_at=$(date -d '+24 hours' '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v+24H '+%Y-%m-%d %H:%M:%S')
    
    #session_token|username|created_at|expires_at|status
    local session_record="${session_token}${FIELD_DELIMITER}${username}${FIELD_DELIMITER}${created_at}${FIELD_DELIMITER}${expires_at}${FIELD_DELIMITER}active"
    
    echo "$session_record" >> "$SESSIONS_FILE"
    
    export CURRENT_SESSION="$session_token"
    export CURRENT_USER="$username"
    
    log_user_action "SESSION_CREATED" "username=$username"
    echo "$session_token"
}

get_session_record(){
    local session_token="$1"
    
    if [[ ! -f "$SESSIONS_FILE" ]]; then
        return 1
    fi
    
    grep "^${session_token}${FIELD_DELIMITER}" "$SESSIONS_FILE" | tail -1
}

validate_session(){
    local session_token="$1"
    
    if [[ ! -f "$SESSIONS_FILE" ]]; then
        return 1
    fi
    
    local record=$(get_session_record "$session_token")
    
    if [[ -z "$record" ]]; then
        return 1
    fi
    
    local username=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f2)
    local expires_at=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f4)
    local status=$(echo "$record" | cut -d"$FIELD_DELIMITER" -f5)
    
    if [[ "$status" != "active" ]]; then
        return 1
    fi
    
    local current_time=$(date '+%s')
    local expire_time=$(date -d "$expires_at" '+%s' 2>/dev/null || date -j -f '%Y-%m-%d %H:%M:%S' "$expires_at" '+%s')
    
    if [[ $current_time -gt $expire_time ]]; then
        return 1
    fi
    
    export CURRENT_SESSION="$session_token"
    export CURRENT_USER="$username"
    
    return 0
}

invalidate_session(){
    local session_token="$1"
    
    if [[ -z "$session_token" ]]; then
        return 1
    fi
    
    if [[ -f "$SESSIONS_FILE" ]]; then
        sed -i.bak "s/^\(${session_token}${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}[^${FIELD_DELIMITER}]*${FIELD_DELIMITER}\)active$/\1inactive/" "$SESSIONS_FILE"
    fi
}

logout_user(){
    local session_token="${1:-$CURRENT_SESSION}"
    
    if [[ -z "$session_token" ]]; then
        show_error "No active session"
        return 1
    fi
    
    invalidate_session "$session_token"
    
    log_user_action "LOGOUT" "username=$CURRENT_USER"
    
    export CURRENT_SESSION=""
    export CURRENT_USER=""
    
    show_success "Logged out successfully"
    return 0
}