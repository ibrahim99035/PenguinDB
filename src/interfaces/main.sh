#!/bin/bash

start_cli_interface() {
    while true; do
        print_main_menu
        read -p "Select option: " choice
        
        if [[ -z "$CURRENT_USER" ]]; then
            # Guest menu
            case "$choice" in
                1)
                    login_interactive
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    echo ""
                    read -p "Username: " username
                    read -s -p "Password: " password
                    echo ""
                    read -s -p "Confirm password: " password2
                    echo ""
                    read -p "Email: " email
                    
                    if [[ "$password" != "$password2" ]]; then
                        show_error "Passwords don't match"
                    else
                        register_user "$username" "$password" "$email"
                    fi
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    echo ""
                    show_info "Goodbye!"
                    exit 0
                    ;;
                *)
                    show_error "Invalid option"
                    read -p "Press Enter to continue..."
                    ;;
            esac
        else
            # Logged in menu
            case "$choice" in
                1)
                    handle_database_operations
                    ;;
                2)
                    handle_table_operations
                    ;;
                3)
                    handle_data_operations
                    ;;
                4)
                    handle_permissions
                    ;;
                5)
                    if is_admin; then
                        handle_admin_panel
                    else
                        show_error "Invalid option"
                        read -p "Press Enter to continue..."
                    fi
                    ;;
                8)
                    echo ""
                    read -s -p "Current password: " old_pass
                    echo ""
                    read -s -p "New password: " new_pass
                    echo ""
                    read -s -p "Confirm new password: " new_pass2
                    echo ""
                    
                    if [[ "$new_pass" != "$new_pass2" ]]; then
                        show_error "Passwords don't match"
                    else
                        change_password "$CURRENT_USER" "$old_pass" "$new_pass"
                    fi
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    logout_user
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    echo ""
                    show_info "Goodbye!"
                    exit 0
                    ;;
                *)
                    show_error "Invalid option"
                    read -p "Press Enter to continue..."
                    ;;
            esac
        fi
    done
}