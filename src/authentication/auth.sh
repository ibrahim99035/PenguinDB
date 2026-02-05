#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/auth/validation.sh"
source "$SCRIPT_DIR/auth/password.sh"
source "$SCRIPT_DIR/auth/user_data.sh"

source "$SCRIPT_DIR/auth/session.sh"

source "$SCRIPT_DIR/auth/register.sh"
source "$SCRIPT_DIR/auth/authenticate.sh"
source "$SCRIPT_DIR/auth/change_password.sh"

source "$SCRIPT_DIR/auth/role_check.sh"

source "$SCRIPT_DIR/auth/user_management.sh"