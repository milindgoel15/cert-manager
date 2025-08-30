#!/bin/bash
set -euo pipefail

# ========= Colors =========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ========= Log Function =========
log() {
  local color=$1
  shift
  local message="$*"
  case "$color" in
    red)     echo -e "${RED}>>> ${message}${RESET}" ;;
    green)   echo -e "${GREEN}>>> ${message}${RESET}" ;;
    yellow)  echo -e "${YELLOW}>>> ${message}${RESET}" ;;
    blue)    echo -e "${BLUE}>>> ${message}${RESET}" ;;
    magenta) echo -e "${MAGENTA}>>> ${message}${RESET}" ;;
    cyan)    echo -e "${CYAN}>>> ${message}${RESET}" ;;
    *)       echo ">>> ${message}" ;;
  esac
}

# ========= Helper function =========
run() {
  echo "[*]  $*"
  "$@"
  echo "[+] Command completed"
  echo
}

# ========= Ask for DN field =========
ask_dn() {
  local prompt="$1"
  local var
  read -p "$prompt: " var
  [[ -z "$var" ]] && echo "na" || echo "$var"
}

# ========= Create chain =========
create_chain() {
    local intermediate="$1"
    local root="$2"
    local output="$3"
    case "$(uname -s)" in
        Linux|Darwin|MINGW*) cat "$intermediate" "$root" > "$output" ;;
        *) powershell -Command "Get-Content '$intermediate', '$root' | Set-Content '$output'" ;;
    esac
    log green "Certificate chain created: $output"
}

# ========= Setup directories =========
setup_dirs() {
    # Resolve project root (cert-manager dir)
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ROOT_DIR="$SCRIPT_DIR/.."
    export INPUT_DIR="$ROOT_DIR/input"
    export OUTPUT_BASE="$ROOT_DIR/output"

    # Create run ID only once per session
    if [ -z "${CERTMGR_RUN_ID:-}" ]; then
        export CERTMGR_RUN_ID="$(date +%Y%m%d_%H%M%S)"
    fi

    export RUN_DIR="$OUTPUT_BASE/$CERTMGR_RUN_ID"

    mkdir -p "$INPUT_DIR" "$RUN_DIR"
    cd "$RUN_DIR"
    log cyan "Using output directory: $RUN_DIR"
}

# ========= Cleanup run dir if empty =========
cleanup_run_dir_if_empty() {
    if [ -d "$RUN_DIR" ] && [ -z "$(ls -A "$RUN_DIR")" ]; then
        rm -rf "$RUN_DIR"
        log yellow "Deleted empty run directory: $RUN_DIR"
    fi
}


# ========= Prompt for file =========
prompt_file() {
  local msg="$1"
  local ans norm
  read -r -p "[*] $msg " ans
  [ -z "$ans" ] && echo "" && return
  ans=$(echo "$ans" | sed -e 's/^"//' -e 's/"$//')
  norm=$(echo "$ans" | sed -e 's#\\#/#g')
  if [ ! -f "$norm" ]; then
    echo "Error: File does not exist -> $norm"
    exit 1
  fi
  echo "$norm"
}