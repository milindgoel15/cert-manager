#!/bin/bash
ROOT_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
echo "Using $ROOT_DIR"

source "$ROOT_DIR/env.sh"
source "$ROOT_DIR/utils/common.sh"


setup_dirs

SERVER_DIR="ServerCert"

SERVER_KEY="server.key"
SERVER_CSR="server.csr"
SERVER_CERT="server.crt"
SERVER_SAN="ip_config.cnf"


# ========= Server or S/MIME Certificate =========
echo

mkdir -p "$SERVER_DIR"

log cyan "Generating Server key..."

if [[ -f "$INPUT_DIR/$SERVER_KEY" ]]; then
  cp "$INPUT_DIR/$SERVER_KEY" "$SERVER_DIR/$SERVER_KEY"
  log yellow "Using existing Server key file from input/"
else
  log yellow "Generating new Server key file..."
  run openssl genrsa -des3 -out "$SERVER_DIR/$SERVER_KEY" 2048
fi

# ==== Check for existing SAN config ====
if [[ -f "$INPUT_DIR/$SERVER_SAN" ]]; then
  cp "$INPUT_DIR/$SERVER_SAN" "$SERVER_DIR/$SERVER_SAN"
  log yellow "Using existing Server SAN config from input/"
else
  log cyan "No existing SAN config found. Creating one interactively..."
  C=$(ask_dn "Country (C)")
  ST=$(ask_dn "State (ST)")
  L=$(ask_dn "Locality (L)")
  O=$(ask_dn "Organization (O)")
  OU=$(ask_dn "Organizational Unit (OU)")
  CN=$(ask_dn "Common Name (CN)")
  ALT_NAMES=""
  i=1
  while true; do
    read -p "Add SubjectAltName entry (IP/DNS/leave empty to stop): " TYPE
    if [[ -z "$TYPE" ]]; then break; fi
    read -p "Enter value for $TYPE.$i: " VALUE
    [[ -z "$VALUE" ]] && VALUE="na"
    ALT_NAMES+="$TYPE.$i = $VALUE"$'\n'
    ((i++))
  done
  cat > "$SERVER_DIR/$SERVER_SAN" <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[dn]
C  = $C
ST = $ST
L  = $L
O  = $O
OU = $OU
CN = $CN

[req_ext]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth
keyUsage = critical, digitalSignature, keyEncipherment

[alt_names]
$ALT_NAMES
EOF
    fi

log cyan "Generating Server CSR..."
run openssl req -new -key "$SERVER_DIR/$SERVER_KEY" -out "$SERVER_DIR/$SERVER_CSR" -config "$SERVER_DIR/$SERVER_SAN"
log cyan "Signing Server certificate..."
if [[ "${INTER_USED:-}" == true ]]; then
  log yellow "Intermediate CA was used."
  run openssl x509 -req -in "$SERVER_DIR/$SERVER_CSR" -CA "$INTER_CA/$INTER_CERT" -CAkey "$INTER_CA/$INTER_KEY" \
    -CAcreateserial -out "$SERVER_DIR/$SERVER_CERT" -days 825 -sha256 -extfile "$SERVER_DIR/$SERVER_SAN" -extensions req_ext
else
  run openssl x509 -req -in "$SERVER_DIR/$SERVER_CSR" -CA "$ROOT_CA_DIR/$ROOT_CERT" -CAkey "$ROOT_CA_DIR/$ROOT_KEY" \
    -CAcreateserial -out "$SERVER_DIR/$SERVER_CERT" -days 825 -sha256 -extfile "$SERVER_DIR/$SERVER_SAN" -extensions req_ext
fi
#  log cyan "Verifying SANs in server certificate..."
#  run openssl x509 -in "$SERVER_DIR/$SERVER_CERT" -noout -text | grep -A 1 "Subject Alternative Name"
echo
read -p ">> Do you want to generate a PFX certificate? (y/n): " GEN_PFX
if [[ "$GEN_PFX" =~ ^[Yy]$ ]]; then
  if [[ "${INTER_USED:-}" == true ]]; then
    log yellow "Intermediate CA was used."
    read -p ">>> Do you want FULL CHAIN PFX (Server + Intermediate + Root)? (y/n): " FULL_CHAIN
    if [[ "$FULL_CHAIN" =~ ^[Yy]$ ]]; then
      run openssl pkcs12 -export -out "$SERVER_DIR/server-fullchain.pfx" \
        -inkey "$SERVER_DIR/$SERVER_KEY" \
        -in "$SERVER_DIR/$SERVER_CERT" \
        -certfile "$INTER_CA/$CHAIN_FILE"
    else
      run openssl pkcs12 -export -out "$SERVER_DIR/server.pfx" \
        -inkey "$SERVER_DIR/$SERVER_KEY" \
        -in "$SERVER_DIR/$SERVER_CERT" \
        -certfile "$INTER_CA/$INTER_CERT"
    fi
  else
    log yellow "No intermediate CA was used."
    read -p ">>> Do you want FULL CHAIN PFX (Server + Root)? (y/n): " FULL_CHAIN
    if [[ "$FULL_CHAIN" =~ ^[Yy]$ ]]; then
      run openssl pkcs12 -export -out "$SERVER_DIR/server-fullchain.pfx" \
        -inkey "$SERVER_DIR/$SERVER_KEY" \
        -in "$SERVER_DIR/$SERVER_CERT" \
        -certfile "$ROOT_CA_DIR/$ROOT_CERT"
    else
      run openssl pkcs12 -export -out "$SERVER_DIR/server.pfx" \
        -inkey "$SERVER_DIR/$SERVER_KEY" \
        -in "$SERVER_DIR/$SERVER_CERT"
    fi
  fi
fi
log green "Server Certificate generation complete!"
