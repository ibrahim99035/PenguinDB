#!/bin/bash

is_admin() {
    local username="${1:-$CURRENT_USER}"
    local role=$(get_user_role "$username")
    [[ "$role" == "$ROLE_ADMIN" ]]
}

require_auth(){
    if [[ -z "$CURRENT_USER" ]]; then
        show_error "You must be logged in to perform this action"
        return 1
    fi
    return 0
}

require_admin(){
    require_auth || return 1
    
    if ! is_admin; then
        show_error "This action requires administrator privileges"
        log_user_action "UNAUTHORIZED_ACCESS_ATTEMPT" "username=$CURRENT_USER required_role=admin"
        return 1
    fi
    
    return 0
}