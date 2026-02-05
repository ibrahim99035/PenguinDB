#!/bin/bash

list_users(){
    require_admin || return 1
    
    if [[ ! -f "$USERS_FILE" || ! -s "$USERS_FILE" ]]; then
        show_info "No users found"
        return 0
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "%-20s %-30s %-10s %-10s\n" "USERNAME" "EMAIL" "ROLE" "STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS="$FIELD_DELIMITER" read -r username _ email role _ status; do
        printf "%-20s %-30s %-10s %-10s\n" "$username" "$email" "$role" "$status"
    done < "$USERS_FILE"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    log_user_action "LIST_USERS" "by=$CURRENT_USER"
}

disable_user(){
    local target_user="$1"
    
    require_admin || return 1
    
    if [[ "$target_user" == "$CURRENT_USER" ]]; then
        show_error "You cannot disable your own account"
        return 1
    fi
    
    if ! user_exists "$target_user"; then
        show_error "User '$target_user' not found"
        return 1
    fi
    
    update_user_status "$target_user" "disabled"
    
    show_success "User '$target_user' has been disabled"
    log_user_action "USER_DISABLED" "by=$CURRENT_USER target=$target_user"
}

enable_user(){
    local target_user="$1"
    
    require_admin || return 1
    
    if ! user_exists "$target_user"; then
        show_error "User '$target_user' not found"
        return 1
    fi
    
    update_user_status "$target_user" "active"
    
    show_success "User '$target_user' has been enabled"
    log_user_action "USER_ENABLED" "by=$CURRENT_USER target=$target_user"
}