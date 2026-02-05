#!/bin/bash

show_welcome(){
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║                                        ║"
    echo "║           Welcome to PenguinDB         ║"
    echo "║                                        ║"
    echo "║  A Database Management System in Bash  ║"
    echo "║                                        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "First time setup required..."
    echo ""
}

run_first_time_setup() {
    show_info "Creating admin account..."
    echo ""
    
    read -p "Admin username: " admin_user
    read -s -p "Admin password: " admin_pass
    echo ""
    read -s -p "Confirm password: " admin_pass2
    echo ""
    
    if [[ "$admin_pass" != "$admin_pass2" ]]; then
        show_error "Passwords don't match!"
        exit 1
    fi
    
    register_user "$admin_user" "$admin_pass" "admin@dbms.local" "admin"
    
    show_success "Admin account created successfully!"
    echo ""
    read -p "Press Enter to continue..."
}

