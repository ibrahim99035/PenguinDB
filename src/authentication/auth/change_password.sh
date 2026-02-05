#!/bin/bash

change_password(){
    local username="$1"
    local old_password="$2"
    local new_password="$3"
    
    if ! authenticate_user "$username" "$old_password"; then
        show_error "Current password is incorrect"
        return 1
    fi
    
    validate_password "$new_password" || return 1
    
    local new_hash=$(hash_password "$new_password")
    
    update_user_password "$username" "$new_hash"
    
    show_success "Password changed successfully"
    log_user_action "PASSWORD_CHANGED" "username=$username"
    return 0
}