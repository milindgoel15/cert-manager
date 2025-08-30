#!/bin/bash
set -e

# Load shared functions & variables
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
source "$ROOT_DIR/utils/common.sh"


setup_dirs


# ========= Menu =========

while true; do
  echo
  echo "===== Certificate Conversion Tool ====="
  echo "1) PEM (.pem) -> DER (.der)"
  echo "2) PEM (.pem) -> CRT (.crt)"
  echo "3) PEM (.pem) -> CER (.cer)"
  echo "4) PEM (.pem) -> PFX (.pfx)"
  echo "5) DER (.der) -> PEM (.pem)"
  echo "6) CRT (.crt) -> PEM (.pem)"
  echo "7) CER (.cer) -> PEM (.pem)"
  echo "8) PFX (.pfx) -> PEM (.pem + key)"
  echo "9) Extract public key from PEM"
  echo "10) Extract private key from PEM"
  echo "11) Exit to cert-manager"
  echo "======================================"
  echo
  read -r -p "Select your option: " choice

  case $choice in
    1)
      INPUT=$(prompt_file "Enter PEM file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").der"
      log $CYAN "Converting PEM -> DER..."
      openssl x509 -outform der -in "$INPUT" -out "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    2)
      INPUT=$(prompt_file "Enter PEM file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").crt"
      log $CYAN "Converting PEM -> CRT..."
      cp "$INPUT" "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    3)
      INPUT=$(prompt_file "Enter PEM file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").cer"
      log $CYAN "Converting PEM -> CER..."
      cp "$INPUT" "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    4)
      INPUT=$(prompt_file "Enter PEM cert file path:")
      [ -z "$INPUT" ] && continue
      KEY_FILE=$(prompt_file "Enter private key file path:")
      [ -z "$KEY_FILE" ] && continue
      OUT="$(basename "${INPUT%.*}").pfx"
      read -r -s -p "Enter export password: " PASS
      echo
      log $CYAN "Converting PEM -> PFX..."
      openssl pkcs12 -export -out "$OUT" -inkey "$KEY_FILE" -in "$INPUT" -password pass:"$PASS"
      log $GREEN "Output: $OUT"
      ;;
    5)
      INPUT=$(prompt_file "Enter DER file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").pem"
      log $CYAN "Converting DER -> PEM..."
      openssl x509 -inform der -in "$INPUT" -out "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    6)
      INPUT=$(prompt_file "Enter CRT file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").pem"
      log $CYAN "Converting CRT -> PEM..."
      openssl x509 -in "$INPUT" -out "$OUT" -outform PEM
      log $GREEN "Output: $OUT"
      ;;
    7)
      INPUT=$(prompt_file "Enter CER file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}").pem"
      log $CYAN "Converting CER -> PEM..."
      openssl x509 -in "$INPUT" -out "$OUT" -outform PEM
      log $GREEN "Output: $OUT"
      ;;
    8)
      INPUT=$(prompt_file "Enter PFX file path:")
      [ -z "$INPUT" ] && continue
      OUT_CERT="$(basename "${INPUT%.*}")-cert.pem"
      OUT_KEY="$(basename "${INPUT%.*}")-key.pem"
      read -r -s -p "Enter import password for PFX: " PASS
      echo
      log $CYAN "Extracting PEM + Key from PFX..."
      openssl pkcs12 -in "$INPUT" -out "$OUT_CERT" -clcerts -nokeys -password pass:"$PASS" -passout pass:"$PASS"
      openssl pkcs12 -in "$INPUT" -out "$OUT_KEY" -nocerts -nodes -password pass:"$PASS"
      log $GREEN "Output: $OUT_CERT, $OUT_KEY"
      ;;
    9)
      INPUT=$(prompt_file "Enter PEM file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}")-public.pem"
      log $CYAN "Extracting public key..."
      openssl x509 -pubkey -noout -in "$INPUT" > "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    10)
      INPUT=$(prompt_file "Enter PEM file path:")
      [ -z "$INPUT" ] && continue
      OUT="$(basename "${INPUT%.*}")-private.pem"
      log $CYAN "Extracting private key..."
      openssl pkey -in "$INPUT" -out "$OUT"
      log $GREEN "Output: $OUT"
      ;;
    11)
      log $CYAN "Returning to cert-manager CLI..."
      exit 0
      ;;
    *)
      log $RED "Invalid option. Try again."
      ;;
  esac
done