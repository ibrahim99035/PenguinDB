#!/bin/bash

# Get the directory where THIS script is located
AUTH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$AUTH_DIR/authorization/ownership.sh"
source "$AUTH_DIR/authorization/perm_data.sh"
source "$AUTH_DIR/authorization/perm_check.sh"
source "$AUTH_DIR/authorization/grant.sh"
source "$AUTH_DIR/authorization/revoke.sh"
source "$AUTH_DIR/authorization/list_perms.sh"