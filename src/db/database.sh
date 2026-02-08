#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/db/schema/data_types.sh"
source "$SCRIPT_DIR/db/schema/schema_storage.sh"
source "$SCRIPT_DIR/db/schema/schema_parser.sh"
source "$SCRIPT_DIR/db/schema/schema_validator.sh"

source "$SCRIPT_DIR/db/table/table_create.sh"
source "$SCRIPT_DIR/db/table/table_operations.sh"

source "$SCRIPT_DIR/db/data/insert.sh"
source "$SCRIPT_DIR/db/data/select.sh"
source "$SCRIPT_DIR/db/data/update.sh"
source "$SCRIPT_DIR/db/data/delete.sh"