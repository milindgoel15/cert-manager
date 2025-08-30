# #!/bin/bash

# ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
# source "$ROOT_DIR/utils/common.sh"
# # echo "$ROOT_DIR"

# setup_dirs

source "$(dirname "$0")/common.sh"

log magenta "=== Creating ALL (Root + Intermediate + Server + S/MIME) ==="
bash "$(dirname "$0")/create_root.sh"
bash "$(dirname "$0")/create_intermediate.sh"
bash "$(dirname "$0")/create_server.sh"
bash "$(dirname "$0")/create_smime.sh"
log green "All certificates generated successfully!"