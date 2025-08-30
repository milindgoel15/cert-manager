#!/bin/bash
set -euo pipefail

# ========= Load common utilities =========
ROOT_DIR="$(dirname "$(dirname "$(dirname "$0")")")" 
source "$ROOT_DIR/utils/common.sh"

# ========= Setup dirs =========
setup_dirs
ROOT_CA_DIR="ExampleRootCA" 
ROOT_KEY="ExampleRootCA.key" 
ROOT_CERT="ExampleRootCA.pem" 
mkdir -p "$ROOT_CA_DIR"

# ========= Check if Root CA exists in input =========
if [[ -f "$INPUT_DIR/$ROOT_KEY" && -f "$INPUT_DIR/$ROOT_CERT" ]]; then
  read -p "Root CA found in input/. Do you want to use it? (y/n): " USE_EXISTING
  if [[ "$USE_EXISTING" =~ ^[Yy]$ ]]; then
    cp "$INPUT_DIR/$ROOT_KEY" "$ROOT_CA_DIR/"
    cp "$INPUT_DIR/$ROOT_CERT" "$ROOT_CA_DIR/"
    log green "Using Root CA from input/ and copied into $ROOT_CA_DIR"
    exit 0
  fi
fi

# ========= Generate new Root CA =========
log cyan "Generating Root CA..."
run openssl genrsa -des3 -out "$ROOT_CA_DIR/$ROOT_KEY" 2048
run openssl req -x509 -new -nodes -key "$ROOT_CA_DIR/$ROOT_KEY" -sha256 -days 1825 -out "$ROOT_CA_DIR/$ROOT_CERT"

log green "Root CA created at $ROOT_CA_DIR"


cleanup_run_dir_if_empty



echo "ROOT_CA_DIR=$ROOT_CA_DIR" >> "$ROOT_DIR/env.sh"
echo "ROOT_CERT=$ROOT_CERT" >> "$ROOT_DIR/env.sh"