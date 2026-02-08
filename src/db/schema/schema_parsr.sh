#!/bin/bash

# Schema Parser Module
# Parse CREATE TABLE statements and column definitions

# Parse CREATE TABLE statement
# Example: CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100) NOT NULL);
parse_create_table() {
    local sql=$1
    
    # Remove extra whitespace and newlines
    sql=$(echo "$sql" | tr '\n' ' ' | sed 's/  */ /g')
    
    # Extract table name
    if [[ ! "$sql" =~ CREATE[[:space:]]+TABLE[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        show_error "Invalid CREATE TABLE syntax"
        return 1
    fi
    
    local table_name="${BASH_REMATCH[1]}"
    
    # Extract column definitions (between parentheses)
    if [[ ! "$sql" =~ \((.+)\)[[:space:]]*;?[[:space:]]*$ ]]; then
        show_error "Missing column definitions"
        return 1
    fi
    
    local column_defs="${BASH_REMATCH[1]}"
    
    # Return table name and column definitions
    echo "${table_name}|${column_defs}"
}

# Parse column definitions
# Example: id INT PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(255) UNIQUE
parse_column_definitions() {
    local column_defs=$1
    
    # Split by comma (handle commas inside parentheses)
    local schema=""
    local current_col=""
    local paren_depth=0
    
    for ((i=0; i<${#column_defs}; i++)); do
        local char="${column_defs:$i:1}"
        
        if [[ "$char" == "(" ]]; then
            ((paren_depth++))
            current_col+="$char"
        elif [[ "$char" == ")" ]]; then
            ((paren_depth--))
            current_col+="$char"
        elif [[ "$char" == "," && $paren_depth -eq 0 ]]; then
            # Parse this column definition
            local parsed=$(parse_single_column_def "$current_col")
            if [[ -n "$parsed" ]]; then
                [[ -n "$schema" ]] && schema+=$'\n'
                schema+="$parsed"
            fi
            current_col=""
        else
            current_col+="$char"
        fi
    done
    
    # Parse last column
    if [[ -n "$current_col" ]]; then
        local parsed=$(parse_single_column_def "$current_col")
        if [[ -n "$parsed" ]]; then
            [[ -n "$schema" ]] && schema+=$'\n'
            schema+="$parsed"
        fi
    fi
    
    echo "$schema"
}

# Parse single column definition
# Example: id INT PRIMARY KEY
# Format: column_name|data_type|size|constraints|default
parse_single_column_def() {
    local col_def=$1
    
    # Trim whitespace
    col_def=$(echo "$col_def" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Extract column name (first word)
    local col_name=$(echo "$col_def" | awk '{print $1}')
    
    # Extract rest of definition
    local rest=$(echo "$col_def" | sed "s/^${col_name}[[:space:]]*//" )
    
    # Extract data type
    local data_type=""
    local size=""
    
    if [[ "$rest" =~ ^(VARCHAR|TEXT|INT|DATE|BOOLEAN|FLOAT)(\([0-9]+\))? ]]; then
        data_type="${BASH_REMATCH[1]}"
        
        # Extract size if present
        if [[ "$rest" =~ \(([0-9]+)\) ]]; then
            size="${BASH_REMATCH[1]}"
        fi
        
        # Remove type and size from rest
        rest=$(echo "$rest" | sed "s/^${data_type}[[:space:]]*//;s/([0-9]\+)[[:space:]]*//" )
    else
        show_error "Invalid or missing data type in: $col_def"
        return 1
    fi
    
    # Validate data type
    if ! is_valid_type "$data_type"; then
        show_error "Unsupported data type: $data_type"
        return 1
    fi
    
    # Extract constraints and default value
    local constraints=""
    local default_value=""
    
    # Check for PRIMARY KEY
    if [[ "$rest" =~ PRIMARY[[:space:]]+KEY ]]; then
        constraints+="PRIMARY KEY "
        rest=$(echo "$rest" | sed 's/PRIMARY[[:space:]]\+KEY[[:space:]]*//')
    fi
    
    # Check for UNIQUE
    if [[ "$rest" =~ UNIQUE ]]; then
        constraints+="UNIQUE "
        rest=$(echo "$rest" | sed 's/UNIQUE[[:space:]]*//')
    fi
    
    # Check for NOT NULL
    if [[ "$rest" =~ NOT[[:space:]]+NULL ]]; then
        constraints+="NOT NULL "
        rest=$(echo "$rest" | sed 's/NOT[[:space:]]\+NULL[[:space:]]*//')
    fi
    
    # Check for DEFAULT
    if [[ "$rest" =~ DEFAULT[[:space:]]+([^[:space:]]+) ]]; then
        default_value="${BASH_REMATCH[1]}"
        # Remove quotes if present
        default_value=$(echo "$default_value" | sed "s/^['\"]//;s/['\"]$//")
    fi
    
    # Trim constraints
    constraints=$(echo "$constraints" | sed 's/[[:space:]]*$//')
    
    # Format: column_name|data_type|size|constraints|default
    echo "${col_name}${FIELD_DELIMITER}${data_type}${FIELD_DELIMITER}${size}${FIELD_DELIMITER}${constraints}${FIELD_DELIMITER}${default_value}"
}

# Parse INSERT statement
# Example: INSERT INTO users (id, name) VALUES (1, 'John');
parse_insert_statement() {
    local sql=$1
    
    # Remove extra whitespace
    sql=$(echo "$sql" | tr '\n' ' ' | sed 's/  */ /g')
    
    # Extract table name
    if [[ ! "$sql" =~ INSERT[[:space:]]+INTO[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        show_error "Invalid INSERT syntax"
        return 1
    fi
    
    local table_name="${BASH_REMATCH[1]}"
    
    # Extract column names (optional)
    local columns=""
    if [[ "$sql" =~ \(([a-zA-Z0-9_,[:space:]]+)\)[[:space:]]+VALUES ]]; then
        columns="${BASH_REMATCH[1]}"
        # Remove spaces
        columns=$(echo "$columns" | sed 's/[[:space:]]//g')
    fi
    
    # Extract values
    if [[ ! "$sql" =~ VALUES[[:space:]]*\((.+)\)[[:space:]]*;?[[:space:]]*$ ]]; then
        show_error "Missing VALUES clause"
        return 1
    fi
    
    local values="${BASH_REMATCH[1]}"
    
    # Return table_name|columns|values
    echo "${table_name}|${columns}|${values}"
}

# Parse SELECT statement
# Example: SELECT * FROM users WHERE id > 5 ORDER BY name LIMIT 10;
parse_select_statement() {
    local sql=$1
    
    # Remove extra whitespace
    sql=$(echo "$sql" | tr '\n' ' ' | sed 's/  */ /g')
    
    # Extract columns
    local columns="*"
    if [[ "$sql" =~ SELECT[[:space:]]+(.+)[[:space:]]+FROM ]]; then
        columns="${BASH_REMATCH[1]}"
        columns=$(echo "$columns" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    fi
    
    # Extract table name
    local table_name=""
    if [[ "$sql" =~ FROM[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        table_name="${BASH_REMATCH[1]}"
    else
        show_error "Missing FROM clause"
        return 1
    fi
    
    # Extract WHERE clause (optional)
    local where=""
    if [[ "$sql" =~ WHERE[[:space:]]+(.+?)[[:space:]]*(ORDER|LIMIT|;|$) ]]; then
        where="${BASH_REMATCH[1]}"
    fi
    
    # Extract ORDER BY (optional)
    local order_by=""
    if [[ "$sql" =~ ORDER[[:space:]]+BY[[:space:]]+(.+?)[[:space:]]*(LIMIT|;|$) ]]; then
        order_by="${BASH_REMATCH[1]}"
    fi
    
    # Extract LIMIT (optional)
    local limit=""
    if [[ "$sql" =~ LIMIT[[:space:]]+([0-9]+) ]]; then
        limit="${BASH_REMATCH[1]}"
    fi
    
    # Return table_name|columns|where|order_by|limit
    echo "${table_name}|${columns}|${where}|${order_by}|${limit}"
}

# Parse UPDATE statement
# Example: UPDATE users SET name='Jane' WHERE id=1;
parse_update_statement() {
    local sql=$1
    
    # Remove extra whitespace
    sql=$(echo "$sql" | tr '\n' ' ' | sed 's/  */ /g')
    
    # Extract table name
    if [[ ! "$sql" =~ UPDATE[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        show_error "Invalid UPDATE syntax"
        return 1
    fi
    
    local table_name="${BASH_REMATCH[1]}"
    
    # Extract SET clause
    local set_clause=""
    if [[ "$sql" =~ SET[[:space:]]+(.+?)[[:space:]]*(WHERE|;|$) ]]; then
        set_clause="${BASH_REMATCH[1]}"
    else
        show_error "Missing SET clause"
        return 1
    fi
    
    # Extract WHERE clause (optional)
    local where=""
    if [[ "$sql" =~ WHERE[[:space:]]+(.+?)[[:space:]]*(;|$) ]]; then
        where="${BASH_REMATCH[1]}"
    fi
    
    # Return table_name|set_clause|where
    echo "${table_name}|${set_clause}|${where}"
}

# Parse DELETE statement
# Example: DELETE FROM users WHERE id=1;
parse_delete_statement() {
    local sql=$1
    
    # Remove extra whitespace
    sql=$(echo "$sql" | tr '\n' ' ' | sed 's/  */ /g')
    
    # Extract table name
    if [[ ! "$sql" =~ DELETE[[:space:]]+FROM[[:space:]]+([a-zA-Z0-9_]+) ]]; then
        show_error "Invalid DELETE syntax"
        return 1
    fi
    
    local table_name="${BASH_REMATCH[1]}"
    
    # Extract WHERE clause (optional but recommended)
    local where=""
    if [[ "$sql" =~ WHERE[[:space:]]+(.+?)[[:space:]]*(;|$) ]]; then
        where="${BASH_REMATCH[1]}"
    fi
    
    # Return table_name|where
    echo "${table_name}|${where}"
}