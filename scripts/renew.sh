#!/bin/bash

# ========= Colors =========
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ========= Logging =========
log() {
  local COLOR=$1
  local MSG=$2
  echo -e "${COLOR}>>> ${MSG}${RESET}"
}

# ========= Pre-check =========
command -v openssl >/dev/null 2>&1 || { echo >&2 "OpenSSL not found. Exiting."; exit 1; }

prompt_file() {
  local msg="$1"
  local ans norm
  read -r -p "[*] $msg " ans
  if [ -z "$ans" ]; then
    echo ""
    return
  fi
  ans=$(echo "$ans" | sed -e 's/^"//' -e 's/"$//')
  norm=$(echo "$ans" | sed -e 's#\\#/#g')
  if [ ! -f "$norm" ]; then
    echo "Error: File does not exist -> $norm"
    exit 1
  fi
  echo "$norm"
}

echo
log $CYAN "Starting Certificate Renewal Process..."
echo

# ===== Get Inputs =====
OLD_CERT=$(prompt_file "Enter path to your existing certificate (PEM format):")
OLD_KEY=$(prompt_file "Enter path to your existing private key (PEM format):")

# Extract subject + SANs from old certificate
OLD_SUBJECT=$(openssl x509 -in "$OLD_CERT" -noout -subject | sed 's/^subject= //')
OLD_CNS=$(openssl x509 -in "$OLD_CERT" -noout -text | grep "Subject:" | sed -n 's/.*CN *= *//p')
OLD_SANS=$(openssl x509 -in "$OLD_CERT" -noout -text | grep -A1 "Subject Alternative Name" | tail -n1 | sed 's/ *//g')

echo
log $YELLOW "Existing Certificate Subject: $OLD_SUBJECT"
log $YELLOW "Existing Common Name (CN): $OLD_CNS"
log $YELLOW "Existing SANs: $OLD_SANS"
echo

# Allow reusing old key or generating a new one
read -r -p "[*] Do you want to reuse the old private key? (y/n): " REUSE_KEY
if [[ "$REUSE_KEY" =~ ^[Yy]$ ]]; then
  PRIV_KEY="$OLD_KEY"
  log $YELLOW "Reusing existing private key."
else
  PRIV_KEY="renewed-key.pem"
  log $CYAN "Generating a new 2048-bit private key..."
  openssl genrsa -out "$PRIV_KEY" 2048
  log $GREEN "New private key generated: $PRIV_KEY"
fi
echo

# Confirm renewal CN and SANs (default = old values)
read -r -p "[*] Enter Common Name (default: $OLD_CNS): " NEW_CN
NEW_CN=${NEW_CN:-$OLD_CNS}

echo
log $CYAN "Keep or update SANs? (comma-separated, e.g. DNS:example.com,IP:1.2.3.4)"
read -r -p "[*] Enter SANs (default: $OLD_SANS): " NEW_SANS
NEW_SANS=${NEW_SANS:-$OLD_SANS}

# Warn if changed
if [ "$NEW_CN" != "$OLD_CNS" ]; then
  log $RED "WARNING: CN has changed from '$OLD_CNS' to '$NEW_CN'"
fi
if [ "$NEW_SANS" != "$OLD_SANS" ]; then
  log $RED "WARNING: SANs have changed from '$OLD_SANS' to '$NEW_SANS'"
fi
echo

# Build CSR config
CSR_CONF="renew_csr.conf"
cat > "$CSR_CONF" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
CN = $NEW_CN

[ req_ext ]
subjectAltName = $NEW_SANS
EOF

# Generate CSR
NEW_CSR="renewed.csr.pem"
log $CYAN "Generating new CSR..."
openssl req -new -key "$PRIV_KEY" -out "$NEW_CSR" -config "$CSR_CONF"
log $GREEN "CSR generated: $NEW_CSR"

# Choose signing authority
echo
read -r -p "[*] Sign with Intermediate CA? (y/n): " USE_INTER
if [[ "$USE_INTER" =~ ^[Yy]$ ]]; then
  CA_CERT=$(prompt_file "Enter Intermediate CA certificate path:")
  CA_KEY=$(prompt_file "Enter Intermediate CA private key path:")
  SERIAL="intermediate.srl"
else
  CA_CERT=$(prompt_file "Enter Root CA certificate path:")
  CA_KEY=$(prompt_file "Enter Root CA private key path:")
  SERIAL="root.srl"
fi

# Sign certificate
NEW_CERT="renewed-cert.pem"
log $CYAN "Signing new certificate..."
openssl x509 -req -in "$NEW_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$NEW_CERT" -days 365 -sha256 -extfile "$CSR_CONF" -extensions req_ext
log $GREEN "New certificate generated: $NEW_CERT"

# Verify renewal
log $CYAN "Verifying renewed certificate..."
openssl x509 -in "$NEW_CERT" -noout -subject -dates
echo

log $GREEN "Certificate renewal completed successfully!"
