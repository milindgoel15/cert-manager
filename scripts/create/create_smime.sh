#!/bin/bash

ROOT_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
echo "Using $ROOT_DIR"

source "$ROOT_DIR/env.sh"
source "$ROOT_DIR/utils/common.sh"

setup_dirs

SMIME_DIR="S-MIME"
EMAIL_KEY="email_address.key"
EMAIL_CSR="email_address.csr"
EMAIL_CERT="email_address.crt"
EMAIL_P12="email_address.p12"
EMAIL_PUBLIC_CERT="email_address_oublic.crt"
EMAIL_CONF="email_address.cnf"

mkdir -p "$SMIME_DIR"

log cyan "Generating S/MIME key..."
run openssl genrsa -des3 -out "$SMIME_DIR/$EMAIL_KEY" 2048

# ===============================================
#  CSR generation modes
# ===============================================
log cyan "Choose CSR generation method:"
echo "1) Use existing config file from input/"
echo "2) Auto-generate a config file and use it"
echo "3) Classic interactive CSR prompt"
read -p "Select option (1/2/3): " CSR_MODE

case $CSR_MODE in
  1)
    if [[ -f "$INPUT_DIR/email.cnf" ]]; then
      cp "$INPUT_DIR/email.cnf" "$SMIME_DIR"
      log green "Using existing config file from input/"
      run openssl req -new -key "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_CSR" -config "$SMIME_DIR/$EMAIL_CONF"
    else
      log red "No email.cnf found in input/. Falling back to interactive mode."
      run openssl req -new -key "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_CSR"
    fi
    ;;
  2)
    log cyan "Generating default S/MIME config file..."
    cat > "$SMIME_DIR/$EMAIL_CONF" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
C  = IN
ST = Haryana
L  = Gurugram
O  = Ciscap Ltd
OU = Ciscap Security
CN = migoel@cisco.com
emailAddress = migoel@cisco.com

[ req_ext ]
subjectAltName = email:migoel@cisco.com
EOF
    log green "Config file created at $EMAIL_CONF"
    run openssl req -new -key "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_CSR" -config "$SMIME_DIR/$EMAIL_CONF"
    ;;
  3)
    log cyan "Generating CSR using classic interactive prompts..."
    run openssl req -new -key "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_CSR"
    ;;
  *)
    log red "Invalid choice. Exiting..."
    exit 1
    ;;
esac

# ===============================================
#  Sign CSR
# ===============================================
log cyan "Signing S/MIME certificate..."
if [[ "$INTER_USED" == true ]]; then
    if [ -d "$INTER_CA" ]; then
        run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" \
          -CA "$INTER_CA/$INTER_CERT" -CAkey "$INTER_CA/$INTER_KEY" \
          -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days 825 -sha256
    else
        run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" \
          -CA "$INPUT_DIR/$INTER_CERT" -CAkey "$INPUT_DIR/$INTER_KEY" \
          -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days 825 -sha256
    fi
else
    if [ -d "$ROOT_CA" ]; then
        run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" \
          -CA "$ROOT_CA/$ROOT_CERT" -CAkey "$ROOT_CA/$ROOT_KEY" \
          -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days 825 -sha256
    else
        run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" \
          -CA "$INPUT_DIR/$ROOT_CERT" -CAkey "$INPUT_DIR/$ROOT_KEY" \
          -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days 825 -sha256
    fi
fi

# ===============================================
#  Convert to PKCS#12 and Extract Public Cert
# ===============================================
log cyan "Converting S/MIME certificate to PFX (.p12)..."
run openssl pkcs12 -export -in "$SMIME_DIR/$EMAIL_CERT" -inkey "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_P12"

log cyan "Extracting public certificate from PFX..."
run openssl pkcs12 -in "$SMIME_DIR/$EMAIL_P12" -clcerts -nokeys -out "$SMIME_DIR/$EMAIL_PUBLIC_CERT"

log green "S/MIME Certificate generation complete!"

cleanup_run_dir_if_empty
