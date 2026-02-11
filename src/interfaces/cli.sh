#!/bin/bash

print_main_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║           PenguinDB v1.0               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    if [[ -n "$CURRENT_USER" ]]; then
        local role=$(get_user_role "$CURRENT_USER")
        echo "  Logged in as: $CURRENT_USER ($role)"
        [[ -n "$CURRENT_DB" ]] && echo "  Current DB: $CURRENT_DB"
    else
        echo "  Not logged in"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -z "$CURRENT_USER" ]]; then
        echo "  1. Login"
        echo "  2. Register"
        echo "  0. Exit"
    else
        echo "  1. Database Operations"
        echo "  2. Table Operations"
        echo "  3. Data Operations"
        echo "  4. Permissions"
        if is_admin; then
            echo "  5. Admin Panel"
        fi
        echo "  8. Change Password"
        echo "  9. Logout"
        echo "  0. Exit"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_database_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║        Database Operations             ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  1. Create Database"
    echo "  2. List Databases"
    echo "  3. Use Database"
    echo "  4. Drop Database"
    echo "  0. Back to Main Menu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_table_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║         Table Operations               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected. Please select a database first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo "  Current Database: $CURRENT_DB"
    echo ""
    echo "  1. Create Table"
    echo "  2. List Tables"
    echo "  3. Describe Table"
    echo "  4. Drop Table"
    echo "  0. Back to Main Menu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_data_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║          Data Operations               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    if [[ -z "$CURRENT_DB" ]]; then
        show_error "No database selected. Please select a database first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo "  Current Database: $CURRENT_DB"
    echo ""
    echo "  1. Insert Data"
    echo "  2. Select Data"
    echo "  3. Update Data"
    echo "  4. Delete Data"
    echo "  0. Back to Main Menu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_permissions_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║         Permissions Management         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  1. Grant Permission"
    echo "  2. Revoke Permission"
    echo "  3. Show Database Permissions"
    echo "  4. Show My Permissions"
    echo "  0. Back to Main Menu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_admin_menu() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║            Admin Panel                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  1. List All Users"
    echo "  2. Disable User"
    echo "  3. Enable User"
    echo "  0. Back to Main Menu"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

handle_database_operations() {
    while true; do
        print_database_menu
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                echo ""
                read -p "Database name: " db_name
                create_database "$db_name"
                read -p "Press Enter to continue..."
                ;;
            2)
                list_databases
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Database name: " db_name
                use_database "$db_name"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                read -p "Database name: " db_name
                drop_database "$db_name"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                show_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

handle_table_operations() {
    while true; do
        print_table_menu || return
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                echo ""
                read -p "Table name: " table_name
                echo "Enter column definitions (format: col_name TYPE [CONSTRAINT])"
                echo "Example: id NUMBER PRIMARYKEY"
                echo "Available types: TEXT, NUMBER, DATE"
                echo "Available constraints: PRIMARYKEY, UNIQUE, NOT NULL"
                echo ""
                
                local col_defs=()
                local col_num=1
                while true; do
                    read -p "Column $col_num (or press Enter to finish): " col_def
                    [[ -z "$col_def" ]] && break
                    col_defs+=("$col_def")
                    ((col_num++))
                done
                
                if [[ ${#col_defs[@]} -gt 0 ]]; then
                    create_table "$table_name" "${col_defs[@]}"
                else
                    show_error "At least one column is required"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                list_tables
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Table name: " table_name
                describe_table "$table_name"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                read -p "Table name: " table_name
                drop_table "$table_name"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                show_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

handle_data_operations() {
    while true; do
        print_data_menu || return
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                echo ""
                read -p "Table name: " table_name
                
                # Get column names
                local columns=($(get_column_names "$CURRENT_DB" "$table_name"))
                if [[ ${#columns[@]} -eq 0 ]]; then
                    show_error "Table not found or has no columns"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                echo ""
                echo "Enter values for each column:"
                local values=()
                for col in "${columns[@]}"; do
                    local col_type=$(get_column_type "$CURRENT_DB" "$table_name" "$col")
                    read -p "$col ($col_type): " val
                    values+=("$val")
                done
                
                insert_into "$table_name" "${values[@]}"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Table name: " table_name
                echo ""
                read -p "Filter by column (or press Enter for all): " where_col
                if [[ -n "$where_col" ]]; then
                    read -p "Filter value: " where_val
                    select_from "$table_name" "$where_col" "$where_val"
                else
                    select_from "$table_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Table name: " table_name
                echo ""
                read -p "Column to update: " set_col
                read -p "New value: " set_val
                read -p "WHERE column: " where_col
                read -p "WHERE value: " where_val
                update_table "$table_name" "$set_col" "$set_val" "$where_col" "$where_val"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                read -p "Table name: " table_name
                echo ""
                read -p "Filter by column (or press Enter to delete all): " where_col
                if [[ -n "$where_col" ]]; then
                    read -p "Filter value: " where_val
                    delete_from "$table_name" "$where_col" "$where_val"
                else
                    delete_from "$table_name"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                show_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

handle_permissions() {
    while true; do
        print_permissions_menu
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                echo ""
                read -p "Username: " username
                read -p "Database name: " db_name
                read -p "Table name (or press Enter for database level): " table_name
                echo "Permissions: SELECT, INSERT, UPDATE, DELETE, ALL"
                read -p "Permission: " permission
                
                if [[ -n "$table_name" ]]; then
                    grant_permission "$username" "$db_name" "$table_name" "$permission"
                else
                    grant_permission "$username" "$db_name" "" "$permission"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Username: " username
                read -p "Database name: " db_name
                read -p "Table name (or press Enter for database level): " table_name
                read -p "Permission: " permission
                
                if [[ -n "$table_name" ]]; then
                    revoke_permission "$username" "$db_name" "$table_name" "$permission"
                else
                    revoke_permission "$username" "$db_name" "" "$permission"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Database name: " db_name
                list_db_permissions "$db_name"
                read -p "Press Enter to continue..."
                ;;
            4)
                list_user_permissions "$CURRENT_USER"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                show_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

handle_admin_panel() {
    if ! is_admin; then
        show_error "Access denied. Admin privileges required."
        read -p "Press Enter to continue..."
        return
    fi
    
    while true; do
        print_admin_menu
        read -p "Select option: " choice
        
        case "$choice" in
            1)
                list_users
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Username to disable: " username
                disable_user "$username"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                read -p "Username to enable: " username
                enable_user "$username"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                show_error "Invalid option"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

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