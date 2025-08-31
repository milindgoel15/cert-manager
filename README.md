📜 Certificate Manager CLI

A Bash-based Certificate Management CLI to create, validate, and convert SSL/TLS certificates easily using OpenSSL.
This tool is designed for developers, sysadmins, and security engineers who want a one-stop CLI for handling certificates without remembering complex openssl commands.

---

✨ Features

- Central CLI (cert-manager.sh)
- Navigate to sub-tools (create, validate, convert).
- Clean exit back to shell.
- Validation (validate.sh)
- Validate a certificate file (.pem, .crt, .cer, .der, .pfx).
- Show expiration date, issuer, subject, key usage, SANs.
- Check if the certificate is expired or about to expire.
- Verify certificate chain (Root / Intermediate / Server).
- Conversion (convert.sh)
- Convert between multiple certificate formats:
   - PEM ↔ DER
   - PEM ↔ CRT
   - PEM ↔ CER
   - PEM + KEY → PFX
   - PFX → PEM (cert + key extraction)


---


📖 Notes

- The tool can create Root CA, Intermediate CA, and Server/Client certificates (with SAN support).
- Supports S/MIME certificate generation for secure email communication.
- Recommended for testing, learning, and lab environments (not production-grade PKI).

---

📂 Project Structure

```
cert-manager/
│
├── cert-manager.sh     # Main CLI script
├── validate.sh         # Validation tool
├── convert.sh          # Conversion tool
├── input/              # Place input files here (optional)
└── README.md           # Documentation
```

For input folder, you can place any file there such as root key and root certificate and reference its name within the create_root.sh script


⚡ Requirements

- Linux / macOS / WSL
- OpenSSL installed

Check installation:

```
openssl version
```

If not installed:

Ubuntu/Debian:

```
sudo apt install openssl -y
```

CentOS/RHEL:

```
sudo yum install openssl -y
```

macOS (Homebrew):

```
brew install openssl
```

---

🚀 Usage
1. Run the main CLI
```
bash cert-manager.sh
```

Main Menu
===== Certificate Manager =====
1) Create certificates
2) Validate a certificate
3) Convert certificates
4) Exit


🔍 Validate Certificates
bash validate.sh

Example:
```
[*] Enter certificate file path: ./input/server.crt
>>> Certificate is valid
>>> Expiration: Nov 20 12:00:00 2026 GMT
>>> Issuer: CN=RootCA
>>> SAN: DNS:example.com, DNS:www.example.com
```
---

Other Features:

- File existence check (before every conversion/validation).
- Detects expired/expiring certificates.
- Handles Windows-style paths (C:\path\to\file.crt) by normalizing to /mnt/c/path/to/file.crt in WSL.
- Password prompts are hidden (-s).

---

📌 Best Practices

- Keep your private keys secure (.key files should not be shared).
- Always use strong export passwords for .pfx files.
- Validate certificates regularly to avoid downtime due to expiration.
- Store certificates and keys in the input/ folder for better organization.

---

🏁 Exit

From any sub-tool, choose Exit to return to the main menu or quit.
This allows seamless navigation between validate and convert.

---

📜 License

Use at your own risk — especially when dealing with private keys.