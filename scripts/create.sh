#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
source "$ROOT_DIR/utils/common.sh"
# echo "$ROOT_DIR"

setup_dirs

while true; do
    echo
    echo "===== Certificate Creation ====="
    echo "1) Create Root CA"
    echo "2) Create Intermediate CA"
    echo "3) Create Server Certificate"
    echo "4) Create S/MIME Certificate"
    echo "5) Create All (Root + Intermediate + Server/S-MIME)"
    echo "6) Exit"
    read -rp "Select an option: " choice

    case "$choice" in
        1) bash "$ROOT_DIR/scripts/create/create_root.sh" ;;
        2) bash "$ROOT_DIR/scripts/create/create_intermediate.sh" ;;
        3) bash "$ROOT_DIR/scripts/create/create_server.sh" ;;
        4) bash "$ROOT_DIR/scripts/create/create_smime.sh" ;;
        5) bash "$ROOT_DIR/scripts/create/all.sh" ;;
        6) log yellow "Exiting to main menu"; exit 0 ;;
        *) log red "Invalid choice";;
    esac
done




# #!/bin/bash
# set -euo pipefail

# # ========= Pre-check =========
# command -v openssl >/dev/null 2>&1 || { echo >&2 "OpenSSL not found. Exiting."; exit 1; }

# # ========= Colors =========
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# BLUE='\033[0;34m'
# MAGENTA='\033[0;35m'
# CYAN='\033[0;36m'
# RESET='\033[0m'

# # ========= Log Function =========
# log() {
#   local color=$1
#   shift
#   local message="$*"

#   case "$color" in
#     red)    echo -e "${RED}>>> ${message}${RESET}" ;;
#     green)  echo -e "${GREEN}>>> ${message}${RESET}" ;;
#     yellow) echo -e "${YELLOW}>>> ${message}${RESET}" ;;
#     blue)   echo -e "${BLUE}>>> ${message}${RESET}" ;;
#     magenta)echo -e "${MAGENTA}>>> ${message}${RESET}" ;;
#     cyan)   echo -e "${CYAN}>>> ${message}${RESET}" ;;
#     *)      echo ">>> ${message}" ;;
#   esac
# }

# # ========= Helper function =========
# run() {
#   echo "[*]  $*"
#   "$@"
#   echo "[+] Command completed"
#   echo
# }

# # Helper function to read with default "na"
# ask_dn() {
#   local prompt="$1"
#   local var
#   read -p "$prompt: " var
#   if [[ -z "$var" ]]; then
#     echo "na"
#   else
#     echo "$var"
#   fi
# }

# # Usage: create_chain <intermediate_cert> <root_cert> <output_chain_file>
# create_chain() {
#     local intermediate="$1"
#     local root="$2"
#     local output="$3"

#     OS_NAME=$(uname -s 2>/dev/null)
#     echo "Detected OS: $OS_NAME"

#     case "$OS_NAME" in
#         Linux|Darwin|MINGW*) cat "$intermediate" "$root" > "$output" ;;
#         MSYS*) powershell -Command "Get-Content '$intermediate', '$root' | Set-Content '$output'" ;;
#         *)     powershell -Command "Get-Content '$intermediate', '$root' | Set-Content '$output'" ;;
#     esac

#     echo "Certificate chain created: $output"
# }

# # ==========================================================
# # ======== Project-specific adjustments ====================
# # ==========================================================

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ROOT_DIR="$SCRIPT_DIR/.."

# INPUT_DIR="$ROOT_DIR/input"
# OUTPUT_BASE="$ROOT_DIR/output"
# RUN_DIR="$OUTPUT_BASE/$(date +%Y%m%d_%H%M%S)"

# mkdir -p "$INPUT_DIR" "$RUN_DIR"

# cd "$RUN_DIR"

# # ========= Variables =========
# DAYS_ROOT=1825
# DAYS_INTER=1825
# DAYS_SERVER=825

# # Directories inside run folder
# ROOT_CA="ExampleRootCA"
# INTER_CA="ExampleIntermediateCA"
# SERVER_DIR="ServerCert"
# SMIME_DIR="S-MIME"

# # Filenames
# ROOT_KEY="ExampleRootCA.key"
# ROOT_CERT="ExampleRootCA.pem"

# INTER_KEY="Example_RSA_Inter.key"
# INTER_CSR="Example_RSA_Inter.csr"
# INTER_CERT="Example_RSA_Inter.pem"
# INTER_SAN="intermediate.cnf"
# CHAIN_FILE="Example_RSA_Chain.pem"

# SERVER_KEY="server.key"
# SERVER_CSR="server.csr"
# SERVER_CERT="server.crt"
# SERVER_SAN="ip_config.cnf"

# EMAIL_KEY="migoel.key"
# EMAIL_CSR="migoel.csr"
# EMAIL_CERT="migoel.crt"
# EMAIL_P12="migoel.p12"
# EMAIL_PUBLIC_CERT="migoel_public.crt"

# # ========= Ensure directories exist =========
# mkdir -p "$ROOT_CA" "$INTER_CA" "$SERVER_DIR" "$SMIME_DIR"

# # ========= Root CA Check =========
# if [[ -f "$INPUT_DIR/$ROOT_KEY" && -f "$INPUT_DIR/$ROOT_CERT" ]]; then
#   read -p "Root CA found in input/. Do you want to use it? (y/n): " USE_EXISTING_ROOT
#   if [[ "$USE_EXISTING_ROOT" =~ ^[Yy]$ ]]; then
#     cp "$INPUT_DIR/$ROOT_KEY" "$ROOT_CA"
#     cp "$INPUT_DIR/$ROOT_CERT" "$ROOT_CA"
#     log green "Using Root CA from input/"
#   else
#     log cyan "Re-Generating new Root key..."
#     run openssl genrsa -des3 -out "$ROOT_CA/$ROOT_KEY" 2048
#     log cyan "Re-Generating new Root certificate..."
#     run openssl req -x509 -new -nodes -key "$ROOT_CA/$ROOT_KEY" -sha256 -days $DAYS_ROOT -out "$ROOT_CA/$ROOT_CERT"
#   fi
# else
#   log cyan "Generating Root key..."
#   run openssl genrsa -des3 -out "$ROOT_CA/$ROOT_KEY" 2048
#   log cyan "Generating Root certificate..."
#   run openssl req -x509 -new -nodes -key "$ROOT_CA/$ROOT_KEY" -sha256 -days $DAYS_ROOT -out "$ROOT_CA/$ROOT_CERT"
# fi

# # ========= Ask for Intermediate =========
# INTER_USED=false
# read -p "Do you want to use an Intermediate CA? (y/n): " INTER_CHOICE
# if [[ "$INTER_CHOICE" =~ ^[Yy]$ ]]; then
#   INTER_USED=true

#   # ========= Intermediate Key =========
#   if [[ -f "$INPUT_DIR/$INTER_KEY" ]]; then
#     cp "$INPUT_DIR/$INTER_KEY" "$INTER_CA"
#     log yellow "Using Intermediate private key from input/"
#   elif [[ -f "$INTER_CA/$INTER_KEY" ]]; then
#     log yellow "Intermediate private key already exists: $INTER_CA/$INTER_KEY"
#   else
#     log cyan "Generating Intermediate key..."
#     run openssl genrsa -des3 -out "$INTER_CA/$INTER_KEY" 2048
#   fi

#   # ========= Intermediate SAN Config =========
#   if [[ -f "$INPUT_DIR/$INTER_SAN" ]]; then
#     cp "$INPUT_DIR/$INTER_SAN" "$INTER_CA/$INTER_SAN"
#     log yellow "Using Intermediate SAN config from input/"
#   elif [[ -f "$INTER_CA/$INTER_SAN" ]]; then
#     log yellow "Intermediate SAN config already exists: $INTER_CA/$INTER_SAN"
#   else
#     log cyan "Manually configure Intermediate DN values"
#     C=$(ask_dn "Country (C)")
#     ST=$(ask_dn "State (ST)")
#     L=$(ask_dn "Locality (L)")
#     O=$(ask_dn "Organization (O)")
#     OU=$(ask_dn "Organizational Unit (OU)")
#     CN=$(ask_dn "Common Name (CN)")
#     EmailAddress=$(ask_dn "Email Address")

#     cat > "$INTER_CA/$INTER_SAN" <<EOF
# [req]
# default_bits       = 4096
# prompt             = no
# default_md         = sha256
# distinguished_name = dn
# x509_extensions    = v3_ca

# [dn]
# C  = $C
# ST = $ST
# L  = $L
# O  = $O
# OU = $OU
# CN = $CN
# emailAddress = $EmailAddress

# [v3_ca]
# basicConstraints = critical,CA:TRUE,pathlen:0
# keyUsage = critical, cRLSign, keyCertSign
# subjectKeyIdentifier = hash
# authorityKeyIdentifier = keyid:always,issuer
# EOF
#   fi

#   # ========= Intermediate CSR =========
#   if [[ -f "$INPUT_DIR/$INTER_CSR" ]]; then
#     cp "$INPUT_DIR/$INTER_CSR" "$INTER_CA/$INTER_CSR"
#     log yellow "Intermediate CSR already exists from input/"
#   else
#     log cyan "Generating Intermediate CSR..."
#     run openssl req -new -key "$INTER_CA/$INTER_KEY" -out "$INTER_CA/$INTER_CSR" -config "$INTER_CA/$INTER_SAN"
#   fi

#   # ========= Intermediate Certificate =========
#   if [[ -f "$INPUT_DIR/$INTER_CERT" ]]; then
#     cp "$INPUT_DIR/$INTER_CERT" "$INTER_CA/$INTER_CERT"
#     log yellow "Intermediate certificate already exists from input/"
#   else
#     log cyan "Signing Intermediate with Root CA..."
#     run openssl x509 -req -in "$INTER_CA/$INTER_CSR" -CA "$ROOT_CA/$ROOT_CERT" -CAkey "$ROOT_CA/$ROOT_KEY" \
#       -CAcreateserial -out "$INTER_CA/$INTER_CERT" -days $DAYS_INTER -sha256 -extfile "$INTER_CA/$INTER_SAN" -extensions v3_ca
#   fi

#   # ========= Chain File =========
#   if [[ -f "$INPUT_DIR/$CHAIN_FILE" ]]; then
#     cp "$INPUT_DIR/$CHAIN_FILE" "$INTER_CA/$CHAIN_FILE"
#     log yellow "Certificate chain already exists from input/"
#   else
#     log cyan "Creating certificate chain file..."
#     create_chain "$INTER_CA/$INTER_CERT" "$ROOT_CA/$ROOT_CERT" "$INTER_CA/$CHAIN_FILE"
#     log green "Certificate chain created: $CHAIN_FILE"
#   fi
# fi

# # ========= Server or S/MIME Certificate =========
# echo
# echo "Do you want to generate a normal Server Certificate or an S/MIME Certificate?"
# select CERT_TYPE in "Server" "S/MIME"; do
#   case $CERT_TYPE in
#     Server)
#       log cyan "Generating Server key..."
#       run openssl genrsa -des3 -out "$SERVER_DIR/$SERVER_KEY" 2048

#       # ==== Check for existing SAN config ====
#       if [[ -f "$INPUT_DIR/$SERVER_SAN" ]]; then
#         cp "$INPUT_DIR/$SERVER_SAN" "$SERVER_DIR/$SERVER_SAN"
#         log yellow "Using existing Server SAN config from input/"
#       else
#         log cyan "No existing SAN config found. Creating one interactively..."
#         C=$(ask_dn "Country (C)")
#         ST=$(ask_dn "State (ST)")
#         L=$(ask_dn "Locality (L)")
#         O=$(ask_dn "Organization (O)")
#         OU=$(ask_dn "Organizational Unit (OU)")
#         CN=$(ask_dn "Common Name (CN)")

#         ALT_NAMES=""
#         i=1
#         while true; do
#           read -p "Add SubjectAltName entry (IP/DNS/leave empty to stop): " TYPE
#           if [[ -z "$TYPE" ]]; then break; fi
#           read -p "Enter value for $TYPE.$i: " VALUE
#           [[ -z "$VALUE" ]] && VALUE="na"
#           ALT_NAMES+="$TYPE.$i = $VALUE"$'\n'
#           ((i++))
#         done

#         cat > "$SERVER_DIR/$SERVER_SAN" <<EOF
# [req]
# default_bits       = 2048
# prompt             = no
# default_md         = sha256
# distinguished_name = dn
# req_extensions     = req_ext

# [dn]
# C  = $C
# ST = $ST
# L  = $L
# O  = $O
# OU = $OU
# CN = $CN

# [req_ext]
# subjectAltName = @alt_names
# extendedKeyUsage = serverAuth
# keyUsage = critical, digitalSignature, keyEncipherment

# [alt_names]
# $ALT_NAMES
# EOF
#       fi

#       log cyan "Generating Server CSR..."
#       run openssl req -new -key "$SERVER_DIR/$SERVER_KEY" -out "$SERVER_DIR/$SERVER_CSR" -config "$SERVER_DIR/$SERVER_SAN"

#       log cyan "Signing Server certificate..."
#       if [[ "$INTER_USED" == true ]]; then
#         run openssl x509 -req -in "$SERVER_DIR/$SERVER_CSR" -CA "$INTER_CA/$INTER_CERT" -CAkey "$INTER_CA/$INTER_KEY" \
#           -CAcreateserial -out "$SERVER_DIR/$SERVER_CERT" -days $DAYS_SERVER -sha256 -extfile "$SERVER_DIR/$SERVER_SAN" -extensions req_ext
#       else
#         run openssl x509 -req -in "$SERVER_DIR/$SERVER_CSR" -CA "$ROOT_CA/$ROOT_CERT" -CAkey "$ROOT_CA/$ROOT_KEY" \
#           -CAcreateserial -out "$SERVER_DIR/$SERVER_CERT" -days $DAYS_SERVER -sha256 -extfile "$SERVER_DIR/$SERVER_SAN" -extensions req_ext
#       fi

#     #   log cyan "Verifying SANs in server certificate..."
#     #   run openssl x509 -in "$SERVER_DIR/$SERVER_CERT" -noout -text | grep -A 1 "Subject Alternative Name"

#       echo
#       read -p ">> Do you want to generate a PFX certificate? (y/n): " GEN_PFX
#       if [[ "$GEN_PFX" =~ ^[Yy]$ ]]; then
#         if [[ "$INTER_USED" == true ]]; then
#           log yellow "Intermediate CA was used."
#           read -p ">>> Do you want FULL CHAIN PFX (Server + Intermediate + Root)? (y/n): " FULL_CHAIN
#           if [[ "$FULL_CHAIN" =~ ^[Yy]$ ]]; then
#             run openssl pkcs12 -export -out "$SERVER_DIR/server-fullchain.pfx" \
#               -inkey "$SERVER_DIR/$SERVER_KEY" \
#               -in "$SERVER_DIR/$SERVER_CERT" \
#               -certfile "$INTER_CA/$CHAIN_FILE"
#           else
#             run openssl pkcs12 -export -out "$SERVER_DIR/server.pfx" \
#               -inkey "$SERVER_DIR/$SERVER_KEY" \
#               -in "$SERVER_DIR/$SERVER_CERT" \
#               -certfile "$INTER_CA/$INTER_CERT"
#           fi
#         else
#           log yellow "No intermediate CA was used."
#           read -p ">>> Do you want FULL CHAIN PFX (Server + Root)? (y/n): " FULL_CHAIN
#           if [[ "$FULL_CHAIN" =~ ^[Yy]$ ]]; then
#             run openssl pkcs12 -export -out "$SERVER_DIR/server-fullchain.pfx" \
#               -inkey "$SERVER_DIR/$SERVER_KEY" \
#               -in "$SERVER_DIR/$SERVER_CERT" \
#               -certfile "$ROOT_CA/$ROOT_CERT"
#           else
#             run openssl pkcs12 -export -out "$SERVER_DIR/server.pfx" \
#               -inkey "$SERVER_DIR/$SERVER_KEY" \
#               -in "$SERVER_DIR/$SERVER_CERT"
#           fi
#         fi
#       fi

#       log green "Server Certificate generation complete!"
#       break
#       ;;

#     S/MIME)
#       log cyan "Generating S/MIME key..."
#       run openssl genrsa -des3 -out "$SMIME_DIR/$EMAIL_KEY" 2048

#       log cyan "Generating S/MIME CSR..."
#       run openssl req -new -key "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_CSR"

#       log cyan "Signing S/MIME certificate..."
#       if [[ "$INTER_USED" == true ]]; then
#         run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" -CA "$INTER_CA/$INTER_CERT" -CAkey "$INTER_CA/$INTER_KEY" \
#           -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days $DAYS_SERVER -sha256
#       else
#         run openssl x509 -req -in "$SMIME_DIR/$EMAIL_CSR" -CA "$ROOT_CA/$ROOT_CERT" -CAkey "$ROOT_CA/$ROOT_KEY" \
#           -CAcreateserial -out "$SMIME_DIR/$EMAIL_CERT" -days $DAYS_SERVER -sha256
#       fi

#       log cyan "Converting S/MIME certificate to PFX (.p12)..."
#       run openssl pkcs12 -export -in "$SMIME_DIR/$EMAIL_CERT" -inkey "$SMIME_DIR/$EMAIL_KEY" -out "$SMIME_DIR/$EMAIL_P12"

#       log cyan "Extracting public certificate from PFX..."
#       run openssl pkcs12 -in "$SMIME_DIR/$EMAIL_P12" -clcerts -nokeys -out "$SMIME_DIR/$EMAIL_PUBLIC_CERT"

#       log green "S/MIME Certificate generation complete!"
#       break
#       ;;
#   esac
# done
