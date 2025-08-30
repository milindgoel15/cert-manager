#!/bin/bash
source "$(dirname "$0")/utils/common.sh"

SESSION_ID=$(date +"%Y%m%d_%H%M%S")
log info "Starting cert-manager run (ID=$SESSION_ID)"

while true; do
    echo
    echo "===== Cert Manager ====="
    echo "1) Create Certificates"
    echo "2) Validate Certificates"
    echo "3) Convert Certificates"
    echo "4) Exit"
    read -rp "Select an operation: " choice

    case "$choice" in
        1) bash "$(dirname "$0")/scripts/create.sh" ;;
        2) bash "$(dirname "$0")/scripts/validate.sh" ;;
        3) bash "$(dirname "$0")/scripts/convert.sh" ;;
        4) log info "Goodbye!"; exit 0 ;;
        *) log warn "Invalid choice";;
    esac
done
