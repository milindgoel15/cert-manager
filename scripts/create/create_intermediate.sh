#!/bin/bash

ROOT_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
echo "Using $ROOT_DIR"
source "$ROOT_DIR/utils/common.sh"

setup_dirs

INTER_CA="ExampleIntermediateCA"

INTER_KEY="Example_RSA_Inter.key"
INTER_CSR="Example_RSA_Inter.csr"
INTER_CERT="Example_RSA_Inter.pem"
INTER_SAN="intermediate.cnf"
CHAIN_FILE="Example_RSA_Chain.pem"

mkdir -p "$INTER_CA"


# ========= Ask for Intermediate =========
INTER_USED=false
read -p "Do you want to use an Intermediate CA? (y/n): " INTER_CHOICE
if [[ "$INTER_CHOICE" =~ ^[Yy]$ ]]; then
  INTER_USED=true

  # ========= Intermediate Key =========
  if [[ -f "$INPUT_DIR/$INTER_KEY" ]]; then
    cp "$INPUT_DIR/$INTER_KEY" "$INTER_CA"
    log yellow "Using Intermediate private key from input/"
  elif [[ -f "$INTER_CA/$INTER_KEY" ]]; then
    log yellow "Intermediate private key already exists: $INTER_CA/$INTER_KEY"
  else
    log cyan "Generating Intermediate key..."
    run openssl genrsa -des3 -out "$INTER_CA/$INTER_KEY" 2048
  fi

  # ========= Intermediate SAN Config =========
  if [[ -f "$INPUT_DIR/$INTER_SAN" ]]; then
    cp "$INPUT_DIR/$INTER_SAN" "$INTER_CA/$INTER_SAN"
    log yellow "Using Intermediate SAN config from input/"
  elif [[ -f "$INTER_CA/$INTER_SAN" ]]; then
    log yellow "Intermediate SAN config already exists: $INTER_CA/$INTER_SAN"
  else
    log cyan "Manually configure Intermediate DN values"
    C=$(ask_dn "Country (C)")
    ST=$(ask_dn "State (ST)")
    L=$(ask_dn "Locality (L)")
    O=$(ask_dn "Organization (O)")
    OU=$(ask_dn "Organizational Unit (OU)")
    CN=$(ask_dn "Common Name (CN)")
    EmailAddress=$(ask_dn "Email Address")

    cat > "$INTER_CA/$INTER_SAN" <<EOF
[req]
default_bits       = 4096
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = v3_ca

[dn]
C  = $C
ST = $ST
L  = $L
O  = $O
OU = $OU
CN = $CN
emailAddress = $EmailAddress

[v3_ca]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical, cRLSign, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF
  fi

  # ========= Intermediate CSR =========
  if [[ -f "$INPUT_DIR/$INTER_CSR" ]]; then
    cp "$INPUT_DIR/$INTER_CSR" "$INTER_CA/$INTER_CSR"
    log yellow "Intermediate CSR already exists from input/"
  else
    log cyan "Generating Intermediate CSR..."
    run openssl req -new -key "$INTER_CA/$INTER_KEY" -out "$INTER_CA/$INTER_CSR" -config "$INTER_CA/$INTER_SAN"
  fi

  # ========= Intermediate Certificate =========
  if [[ -f "$INPUT_DIR/$INTER_CERT" ]]; then
    cp "$INPUT_DIR/$INTER_CERT" "$INTER_CA/$INTER_CERT"
    log yellow "Intermediate certificate already exists from input/"
  else
    log cyan "Signing Intermediate with Root CA..."
    run openssl x509 -req -in "$INTER_CA/$INTER_CSR" -CA "$ROOT_CA/$ROOT_CERT" -CAkey "$ROOT_CA/$ROOT_KEY" \
      -CAcreateserial -out "$INTER_CA/$INTER_CERT" -days $DAYS_INTER -sha256 -extfile "$INTER_CA/$INTER_SAN" -extensions v3_ca
  fi

  # ========= Chain File =========
  if [[ -f "$INPUT_DIR/$CHAIN_FILE" ]]; then
    cp "$INPUT_DIR/$CHAIN_FILE" "$INTER_CA/$CHAIN_FILE"
    log yellow "Certificate chain already exists from input/"
  else
    log cyan "Creating certificate chain file..."
    create_chain "$INTER_CA/$INTER_CERT" "$ROOT_CA/$ROOT_CERT" "$INTER_CA/$CHAIN_FILE"
    log green "Certificate chain created: $CHAIN_FILE"
  fi
fi


echo "INTER_USED=$INTER_USED" >> "$ROOT_DIR/env.sh"
echo "INTER_CA=$INTER_CA" >> "$ROOT_DIR/env.sh"
echo "INTER_CERT=$INTER_CERT" >> "$ROOT_DIR/env.sh"
echo "INTER_KEY=$INTER_KEY" >> "$ROOT_DIR/env.sh"
echo "CHAIN_FILE=$CHAIN_FILE" >> "$ROOT_DIR/env.sh"