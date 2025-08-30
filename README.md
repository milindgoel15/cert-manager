📜 Certificate Manager CLI

A Bash-based Certificate Management CLI to create, validate, and convert SSL/TLS certificates easily using OpenSSL.
This tool is designed for developers, sysadmins, and security engineers who want a one-stop CLI for handling certificates without remembering complex openssl commands.

✨ Features

Central CLI (cert-manager.sh)

Navigate to sub-tools (create, validate, convert).

Clean exit back to shell.

Validation (validate.sh)

Validate a certificate file (.pem, .crt, .cer, .der, .pfx).

Show expiration date, issuer, subject, key usage, SANs.

Check if the certificate is expired or about to expire.

Verify certificate chain (Root / Intermediate / Server).

Conversion (convert.sh)

Convert between multiple certificate formats:

PEM ↔ DER

PEM ↔ CRT

PEM ↔ CER

PEM + KEY → PFX

PFX → PEM (cert + key extraction)

Extract keys:

Extract public key from certificate

Extract private key from PEM

Interactive menu for selecting conversion

Loop-back system (perform multiple conversions in one session)

Exit cleanly back to cert-manager

📂 Project Structure
cert-manager/
│
├── cert-manager.sh     # Main CLI script
├── validate.sh         # Validation tool
├── convert.sh          # Conversion tool
├── input/              # Place input files here (optional)
└── README.md           # Documentation

⚡ Requirements

Linux / macOS / WSL

OpenSSL installed

Check installation:

openssl version


If not installed:

Ubuntu/Debian:

sudo apt install openssl -y


CentOS/RHEL:

sudo yum install openssl -y


macOS (Homebrew):

brew install openssl

🚀 Usage
1. Run the main CLI
bash cert-manager.sh

2. Main Menu
===== Certificate Manager =====
1) Validate a certificate
2) Convert certificates
3) Exit

🔍 Validate Certificates
bash validate.sh


Example:

[*] Enter certificate file path: ./input/server.crt
>>> Certificate is valid
>>> Expiration: Nov 20 12:00:00 2026 GMT
>>> Issuer: CN=RootCA
>>> SAN: DNS:example.com, DNS:www.example.com


Validation includes:

Expiration check

Issuer / Subject

SAN values

Key usage

Chain validation (if intermediate/root provided)

🔄 Convert Certificates
bash convert.sh


Interactive menu:

===== Certificate Conversion Tool =====
1) PEM -> DER
2) PEM -> CRT
3) PEM -> CER
4) PEM -> PFX
5) DER -> PEM
6) CRT -> PEM
7) CER -> PEM
8) PFX -> PEM (cert + key)
9) Extract public key
10) Extract private key
11) Exit to cert-manager


Example: Convert CRT → PEM

[*] Enter CRT file path: ./input/server.crt
>>> Converting CRT -> PEM...
>>> Output: ./input/server.pem


Example: Convert PEM + KEY → PFX

[*] Enter PEM file path: ./input/server.pem
[*] Enter private key path: ./input/server.key
Enter export password:
>>> Output: ./input/server.pfx


Example: Extract from PFX

[*] Enter PFX file path: ./input/server.pfx
Enter import password:
>>> Output: server-cert.pem, server-key.pem

🛡️ Extra Validations

File existence check (before every conversion/validation).

Detects expired/expiring certificates.

Handles Windows-style paths (C:\path\to\file.crt) by normalizing to /mnt/c/path/to/file.crt in WSL.

Password prompts are hidden (-s).

📌 Best Practices

Keep your private keys secure (.key files should not be shared).

Always use strong export passwords for .pfx files.

Validate certificates regularly to avoid downtime due to expiration.

Store certificates and keys in the input/ folder for better organization.

🧑‍💻 Example Workflow

Check your server certificate validity

bash validate.sh


→ See if your certificate is valid and not expired.

Convert certificate for a Windows server

bash convert.sh


Select PEM → PFX, enter paths and password, get .pfx for IIS.

Extract public key

bash convert.sh


Select option 9, provide .pem, get public.pem.

🏁 Exit

From any sub-tool, choose Exit to return to the main menu or quit.
This allows seamless navigation between validate and convert.

📜 License

This project is released under the MIT License.
Use at your own risk — especially when dealing with private keys.