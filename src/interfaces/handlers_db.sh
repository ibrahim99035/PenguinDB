#!/bin/bash

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