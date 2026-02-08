#!/bin/bash

declare -A DATA_TYPES=(
    ["INT"]="Integer number"
    ["VARCHAR"]="Variable length string"
    ["TEXT"]="Long text"
    ["DATE"]="Date (YYYY-MM-DD)"
    ["BOOLEAN"]="True/False"
    ["FLOAT"]="Decimal number"
)

is_valid_type() {
    local type=$1
    local base_type=$(echo "$type" | sed 's/(.*//')
    [[ -n "${DATA_TYPES[$base_type]}" ]]
}

parse_type_declaration() {
    local declaration=$1
    
    local base_type=$(echo "$declaration" | sed 's/(.*//')
    
    local size=""
    if [[ "$declaration" =~ \(([0-9]+)\) ]]; then
        size="${BASH_REMATCH[1]}"
    fi
    
    echo "${base_type}|${size}"
}

validate_value(){
    local value=$1
    local type=$2
    local size=$3
    
    if [[ "$value" == "NULL" || -z "$value" ]]; then
        return 0
    fi
    
    case "$type" in
        INT)
            if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
                show_error "Invalid INT value: $value"
                return 1
            fi
            ;;
            
        VARCHAR|TEXT)
            if [[ -n "$size" ]] && [[ ${#value} -gt $size ]]; then
                show_error "String too long: max $size characters, got ${#value}"
                return 1
            fi
            ;;
            
        DATE)
            if [[ ! "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                show_error "Invalid DATE format: $value (expected YYYY-MM-DD)"
                return 1
            fi
            ;;
            
        BOOLEAN)
            local lower=$(echo "$value" | tr '[:upper:]' '[:lower:]')
            if [[ ! "$lower" =~ ^(true|false|1|0|yes|no)$ ]]; then
                show_error "Invalid BOOLEAN value: $value"
                return 1
            fi
            ;;
            
        FLOAT)
            if [[ ! "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
                show_error "Invalid FLOAT value: $value"
                return 1
            fi
            ;;
            
        *)
            show_error "Unknown data type: $type"
            return 1
            ;;
    esac
    
    return 0
}

serialize_value() {
    local value=$1
    local type=$2
    
    if [[ -z "$value" || "$value" == "NULL" ]]; then
        echo "NULL"
    else
        echo "${type}:${value}"
    fi
}

deserialize_value() {
    local stored=$1
    
    if [[ "$stored" == "NULL" ]]; then
        echo ""
        return 0
    fi
    
    echo "$stored" | cut -d':' -f2-
}

get_value_type() {
    local stored=$1
    
    if [[ "$stored" == "NULL" ]]; then
        echo "NULL"
        return 0
    fi
    
    echo "$stored" | cut -d':' -f1
}

normalize_boolean() {
    local value=$1
    local lower=$(echo "$value" | tr '[:upper:]' '[:lower:]')
    
    case "$lower" in
        true|1|yes)
            echo "true"
            ;;
        false|0|no)
            echo "false"
            ;;
        *)
            echo "$value"
            ;;
    esac
}

show_supported_types() {
    echo "Supported Data Types:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for type in "${!DATA_TYPES[@]}"; do
        printf "  %-10s - %s\n" "$type" "${DATA_TYPES[$type]}"
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}