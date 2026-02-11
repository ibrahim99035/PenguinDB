#!/bin/bash

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CLI_DIR/menus.sh"
source "$CLI_DIR/handlers_db.sh"
source "$CLI_DIR/handlers_admin.sh"
source "$CLI_DIR/main.sh"