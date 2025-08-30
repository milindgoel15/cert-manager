#!/bin/bash
set -e

# Load shared functions & variables
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
source "$ROOT_DIR/utils/common.sh"

echo
PRIV_KEY=$(prompt_file "Enter path to your private key:")
echo "Private key: $PRIV_KEY"
echo
CERT_FILE=$(prompt_file "Enter path to your signed certificate file:")
echo "Certificate file: $CERT_FILE"
echo
CHAIN_FILE=$(prompt_file "Enter path to the CA chain file (optional, press Enter to skip):")
[ -n "$CHAIN_FILE" ] && echo "CA chain file: $CHAIN_FILE" || echo "No CA chain file provided."
echo

# ========= 1. Validate key & cert match =========
log $CYAN "Checking if private key and certificate match..."
CERT_MOD=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "$PRIV_KEY" 2>/dev/null | openssl md5)
if [ "$CERT_MOD" == "$KEY_MOD" ]; then
  log $GREEN "Certificate > $CERT_MOD"
  log $GREEN "Key > $KEY_MOD"
  log $GREEN "Private key and certificate MATCH."
else
  log $RED "Private key and certificate DO NOT match!"
fi
echo ""

# ========= 2. Validate certificate integrity =========
log $CYAN "Verifying certificate integrity..."
if openssl x509 -in "$CERT_FILE" -noout -text > /dev/null 2>&1; then
  log $GREEN "Certificate is a valid X.509 certificate."
else
  log $RED "Certificate is INVALID or corrupted!"
fi
echo ""

# ========= 3. Check expiry =========
log $CYAN "Checking certificate expiry..."
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
log $GREEN "Certificate expires on: $EXPIRY_DATE"
echo ""

# ========= 4. Validate chain =========
if [ -n "$CHAIN_FILE" ]; then
  log $CYAN "Validating certificate chain..."
  if openssl verify -CAfile "$CHAIN_FILE" "$CERT_FILE"; then
    log $GREEN "Certificate chain is valid."
  else
    log $RED "Certificate chain validation FAILED."
  fi
  echo ""
fi

# ========= 5. Check certificate purpose =========
log $CYAN "Checking certificate purposes..."
openssl x509 -in "$CERT_FILE" -purpose -noout
echo ""

# ========= 6. Show fingerprints =========
log $CYAN "Certificate Fingerprints:"
openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha256
openssl x509 -in "$CERT_FILE" -noout -fingerprint -md5
echo ""

# ========= 7. Validate SAN entries =========
log $CYAN "Listing Subject Alternative Names (SANs)..."
# SAN=$(openssl x509 -in "$CERT_FILE" -noout -text | grep -A1 "Subject Alternative Name")
SAN=$(openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" || true)
if [ -n "$SAN" ]; then
  echo "$SAN"
else
  log $YELLOW "No SAN entries found in certificate."
fi
echo ""

# ========= EXTRA 1. Key strength =========
log $CYAN "Checking private key strength..."
KEY_BITS=$(openssl rsa -in "$PRIV_KEY" -text -noout 2>/dev/null | grep "Private-Key" | awk '{print $2}' | tr -d '()')
if [ -n "$KEY_BITS" ]; then
  echo "Private key size: ${KEY_BITS} bits"
  [ "$KEY_BITS" -lt 2048 ] && log $RED "Weak key detected (<2048 bits)!" || log $GREEN "Key strength OK."
fi
echo ""

# ========= EXTRA 2. Signature algorithm =========
log $CYAN "Checking signature algorithm..."
SIG_ALG=$(openssl x509 -in "$CERT_FILE" -noout -text | grep "Signature Algorithm" | head -1 | awk -F: '{print $2}' | xargs)
echo "Signature Algorithm: $SIG_ALG"
if [[ "$SIG_ALG" =~ "sha1" ]] || [[ "$SIG_ALG" =~ "md5" ]]; then
  log $RED "Insecure signature algorithm ($SIG_ALG). Consider renewing with SHA-256 or higher."
else
  log $GREEN "Signature algorithm is strong."
fi
echo ""

# ========= EXTRA 3. Self-signed check =========
log $CYAN "Checking if certificate is self-signed..."
ISSUER=$(openssl x509 -in "$CERT_FILE" -noout -issuer)
SUBJECT=$(openssl x509 -in "$CERT_FILE" -noout -subject)
if [ "$ISSUER" == "$SUBJECT" ]; then
  log $YELLOW "This certificate is SELF-SIGNED."
else
  log $GREEN "Certificate is issued by a CA."
fi
echo ""

# ========= EXTRA 4. CRL/OCSP =========
log $CYAN "Checking CRL/OCSP information..."
CRL=$(openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep "CRL Distribution" -A1 2>/dev/null | tail -n1 | awk '{$1=$1};1' || true)
OCSP=$(openssl x509 -in "$CERT_FILE" -noout -ocsp_uri 2>/dev/null || true)

if [ -n "$CRL" ]; then
  echo "CRL Distribution Point: $CRL"
else
  log $YELLOW "No CRL Distribution Point found."
fi

if [ -n "$OCSP" ]; then
  echo "OCSP URL: $OCSP"
else
  log $YELLOW "No OCSP endpoint found."
fi
echo ""

# ========= EXTRA 5. Key usage =========
log $CYAN "Checking Key Usage & Extended Key Usage..."
KEY_USAGE=$(openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep -A1 "Key Usage" || true)
EXT_KEY_USAGE=$(openssl x509 -in "$CERT_FILE" -noout -text 2>/dev/null | grep -A1 "Extended Key Usage" || true)

if [ -n "$KEY_USAGE" ]; then
  echo "$KEY_USAGE"
else
  log $YELLOW "No Key Usage found in certificate."
fi

if [ -n "$EXT_KEY_USAGE" ]; then
  echo "$EXT_KEY_USAGE"
else
  log $YELLOW "No Extended Key Usage found in certificate."
fi
echo ""

log $GREEN "Validation completed with extended checks!"
