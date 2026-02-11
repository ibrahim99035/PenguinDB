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