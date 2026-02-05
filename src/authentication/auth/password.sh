#!/bin/bash

hash_password() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

#Validate password
validate_password() {
    local password="$1"
    
    #Check minimum length
    if [[ ${#password} -lt $MIN_PASSWORD_LENGTH ]]; then
        show_error "Password must be at least $MIN_PASSWORD_LENGTH characters"
        return 1
    fi
    
    return 0
}

#Verify password against hash
verify_password() {
    local password="$1"
    local stored_hash="$2"
    
    local password_hash=$(hash_password "$password")
    
    [[ "$password_hash" == "$stored_hash" ]]
}