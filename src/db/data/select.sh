#!/bin/bash

# SELECT Operation Module
# Query data from tables with filtering

# Select records from SQL statement
select_records_sql() {
    local db_name=$1
    local sql=$2
    
    require_auth || return 1
    
    # Parse SELECT statement
    local parsed=$(parse_select_statement "$sql")
    
    if [[ -z "$parsed" ]]; then
        return 1
    fi
    
    local table_name=$(echo "$parsed" | cut -d'|' -f1)
    local columns=$(echo "$parsed" | cut -d'|' -f2)
    local where=$(echo "$parsed" | cut -d'|' -f3)
    local order_by=$(echo "$parsed" | cut -d'|' -f4)
    local limit=$(echo "$parsed" | cut -d'|' -f5)
    
    # Check permission
    if ! require_permission "$db_name" "$table_name" "$PERM_SELECT"; then
        return 1
    fi
    
    # Check if table exists
    if ! table_exists "$db_name" "$table_name"; then
        show_error "Table '$table_name' does not exist"
        return 1
    fi
    
    # Select records
    select_records "$db_name" "$table_name" "$columns" "$where" "$order_by" "$limit"
}

# Select records from table
select_records() {
    local db_name=$1
    local table_name=$2
    local columns=$3      # "*" or "col1,col2"
    local where=$4        # WHERE clause (optional)
    local order_by=$5     # ORDER BY column (optional)
    local limit=$6        # LIMIT number (optional)
    
    # Load schema
    local schema=$(load_table_schema "$db_name" "$table_name")
    
    if [[ -z "$schema" ]]; then
        show_error "Failed to load table schema"
        return 1
    fi
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    
    # Check if table is empty
    if [[ ! -s "$table_file" ]]; then
        echo ""
        echo "No records found"
        echo ""
        return 0
    fi
    
    # Parse column list
    local col_array=()
    if [[ "$columns" == "*" ]]; then
        # Select all columns
        while IFS="$FIELD_DELIMITER" read -r col_name rest; do
            col_array+=("$col_name")
        done <<< "$schema"
    else
        # Parse specific columns
        IFS=',' read -ra col_array <<< "$columns"
        # Trim whitespace
        for i in "${!col_array[@]}"; do
            col_array[$i]=$(echo "${col_array[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        done
    fi
    
    # Display header
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Print column headers
    for col in "${col_array[@]}"; do
        printf "%-20s " "$col"
    done
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Read and display records
    local count=0
    
    while IFS= read -r record; do
        # Apply WHERE filter if specified
        if [[ -n "$where" ]]; then
            if ! evaluate_where_clause "$schema" "$record" "$where"; then
                continue
            fi
        fi
        
        # Extract and display selected columns
        display_record "$schema" "$record" col_array
        
        ((count++))
        
        # Apply LIMIT if specified
        if [[ -n "$limit" && $count -ge $limit ]]; then
            break
        fi
    done < "$table_file"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$count row(s) returned"
    echo ""
    
    log_db_op "SELECT" "$db_name" "$table_name"
    
    return 0
}

# Display single record
display_record() {
    local schema=$1
    local record=$2
    local -n display_cols=$3
    
    # Split record into fields
    IFS="$FIELD_DELIMITER" read -ra fields <<< "$record"
    
    # Build column name to index mapping
    local col_index=0
    declare -A col_map
    
    while IFS="$FIELD_DELIMITER" read -r col_name rest; do
        col_map[$col_name]=$col_index
        ((col_index++))
    done <<< "$schema"
    
    # Display selected columns
    for col in "${display_cols[@]}"; do
        local idx=${col_map[$col]}
        
        if [[ -n "$idx" ]]; then
            local value=$(deserialize_value "${fields[$idx]}")
            printf "%-20s " "${value:--}"
        else
            printf "%-20s " "?"
        fi
    done
    echo ""
}

# Evaluate WHERE clause for a record
evaluate_where_clause() {
    local schema=$1
    local record=$2
    local where=$3
    
    # Simple WHERE clause evaluation (column operator value)
    # Supports: =, !=, >, <, >=, <=
    
    # Parse WHERE clause
    local column=""
    local operator=""
    local value=""
    
    if [[ "$where" =~ ([a-zA-Z0-9_]+)[[:space:]]*(=|!=|>=|<=|>|<)[[:space:]]*(.+) ]]; then
        column="${BASH_REMATCH[1]}"
        operator="${BASH_REMATCH[2]}"
        value="${BASH_REMATCH[3]}"
        
        # Remove quotes from value
        value=$(echo "$value" | sed "s/^['\"]//;s/['\"]$//")
    else
        # Invalid WHERE clause, skip filtering
        return 0
    fi
    
    # Get column index and type
    local col_index=0
    local col_type=""
    local found=false
    
    while IFS="$FIELD_DELIMITER" read -r col_name type rest; do
        if [[ "$col_name" == "$column" ]]; then
            col_type="$type"
            found=true
            break
        fi
        ((col_index++))
    done <<< "$schema"
    
    if [[ $found == false ]]; then
        return 0
    fi
    
    # Get field value
    IFS="$FIELD_DELIMITER" read -ra fields <<< "$record"
    local field_value=$(deserialize_value "${fields[$col_index]}")
    
    # Compare values based on operator
    case "$operator" in
        =)
            [[ "$field_value" == "$value" ]]
            ;;
        !=)
            [[ "$field_value" != "$value" ]]
            ;;
        \>)
            if [[ "$col_type" == "INT" || "$col_type" == "FLOAT" ]]; then
                (( $(echo "$field_value > $value" | bc -l 2>/dev/null || echo "0") ))
            else
                [[ "$field_value" > "$value" ]]
            fi
            ;;
        \<)
            if [[ "$col_type" == "INT" || "$col_type" == "FLOAT" ]]; then
                (( $(echo "$field_value < $value" | bc -l 2>/dev/null || echo "0") ))
            else
                [[ "$field_value" < "$value" ]]
            fi
            ;;
        \>=)
            if [[ "$col_type" == "INT" || "$col_type" == "FLOAT" ]]; then
                (( $(echo "$field_value >= $value" | bc -l 2>/dev/null || echo "0") ))
            else
                [[ "$field_value" > "$value" || "$field_value" == "$value" ]]
            fi
            ;;
        \<=)
            if [[ "$col_type" == "INT" || "$col_type" == "FLOAT" ]]; then
                (( $(echo "$field_value <= $value" | bc -l 2>/dev/null || echo "0") ))
            else
                [[ "$field_value" < "$value" || "$field_value" == "$value" ]]
            fi
            ;;
        *)
            return 0
            ;;
    esac
}

# Count records
count_records() {
    local db_name=$1
    local table_name=$2
    local where=$3
    
    local table_file="$DB_DIR/$db_name/${table_name}.dat"
    
    if [[ ! -s "$table_file" ]]; then
        echo "0"
        return 0
    fi
    
    if [[ -z "$where" ]]; then
        wc -l < "$table_file"
    else
        local schema=$(load_table_schema "$db_name" "$table_name")
        local count=0
        
        while IFS= read -r record; do
            if evaluate_where_clause "$schema" "$record" "$where"; then
                ((count++))
            fi
        done < "$table_file"
        
        echo "$count"
    fi
}