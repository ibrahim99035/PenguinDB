#!/bin/bash

DB_MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DB_MAIN_DIR/engine/table_schema.sh"
source "$DB_MAIN_DIR/engine/data_validation.sh"
source "$DB_MAIN_DIR/engine/db_core.sh"
source "$DB_MAIN_DIR/engine/table_core.sh"
source "$DB_MAIN_DIR/engine/crud_operations.sh"