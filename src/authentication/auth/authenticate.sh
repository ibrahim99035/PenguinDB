#!/bin/bash

authenticate_user(){
    local username="$1"
    local password="$2"
    
    local record=$(get_user_record "$username")
    
    if [[ -z "$record" ]]; then
        show_error "Invalid username or password"
        log_auth "$username" "failed"
        return 1
    fi
    
    local stored_hash=$(get_user_password_hash "$username")
    local status=$(get_user_status "$username")
    
    if [[ "$status" != "active" ]]; then
        show_error "Account is disabled"
        log_auth "$username" "failed_disabled"
        return 1
    fi
    
    if ! verify_password "$password" "$stored_hash"; then
        show_error "Invalid username or password"
        log_auth "$username" "failed"
        return 1
    fi
    
    log_auth "$username" "success"
    return 0
}

login_interactive() {
    echo ""
    read -p "Username: " username
    read -s -p "Password: " password
    echo ""
    
    if authenticate_user "$username" "$password"; then
        create_session "$username"
        show_success "Welcome, $username!"
        return 0
    else
        return 1
    fi
}