#!/bin/bash

validate_username() {
    local username="$1"
    
    if [[ ${#username} -lt $MIN_USERNAME_LENGTH ]]; then
        show_error "Username must be at least $MIN_USERNAME_LENGTH characters"
        return 1
    fi
    
    if [[ ${#username} -gt $MAX_USERNAME_LENGTH ]]; then
        show_error "Username must be at most $MAX_USERNAME_LENGTH characters"
        return 1
    fi
    
    if [[ ! "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
        show_error "Username can only contain letters, numbers, and underscores"
        return 1
    fi
    
    return 0
}

validate_email() {
    local email="$1"
    
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        show_error "Invalid email format"
        return 1
    fi
    
    return 0
}