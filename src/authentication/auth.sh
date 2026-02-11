#!/bin/bash

# Get the directory where THIS script is located
AUTH_MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$AUTH_MAIN_DIR/auth/validation.sh"
source "$AUTH_MAIN_DIR/auth/password.sh"
source "$AUTH_MAIN_DIR/auth/user_data.sh"

source "$AUTH_MAIN_DIR/auth/session.sh"

source "$AUTH_MAIN_DIR/auth/register.sh"
source "$AUTH_MAIN_DIR/auth/authenticate.sh"
source "$AUTH_MAIN_DIR/auth/change_password.sh"

source "$AUTH_MAIN_DIR/auth/role_check.sh"

source "$AUTH_MAIN_DIR/auth/user_management.sh"