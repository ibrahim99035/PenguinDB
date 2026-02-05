#!/bin/bash

#username|password_hash|email|role|created_at|status
register_user() {
    local username="$1"
    local password="$2"
    local email="$3"
    local role="${4:-$ROLE_USER}"
    
    validate_username "$username" || return 1
    validate_password "$password" || return 1
    validate_email "$email" || return 1
    
    if user_exists "$username"; then
        show_error "Username '$username' already exists"
        log_user_action "REGISTER_FAILED" "username=$username reason=already_exists"
        return 1
    fi
    
    local password_hash=$(hash_password "$password")
    
    create_user_record "$username" "$password_hash" "$email" "$role"
    
    log_user_action "USER_REGISTERED" "username=$username role=$role email=$email"
    return 0
}