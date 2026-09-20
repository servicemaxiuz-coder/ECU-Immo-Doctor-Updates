# ECU Immo Doctor — signed update channel

Public distribution channel for signed ECU Immo Doctor software updates.

This repository contains **no application source code, customer licenses, ECU dumps, HWID exports, or private signing keys**.

## Stable channel

The client checks:

`https://raw.githubusercontent.com/servicemaxiuz-coder/ECU-Immo-Doctor-Updates/main/stable/update.manifest`

`stable/update.manifest` is published only after the release package passes build, self-tests, release gate, and signing. Update ZIP files are attached to immutable versioned GitHub Releases.

The client installs an update only when the RSA-PSS/SHA-256 release signature, Product ID, newer build number, HTTPS URL, package SHA-256, and package `integrity.manifest` all validate.

See [SECURITY.md](SECURITY.md) and [stable/README.md](stable/README.md).
ECU Immo Doctor - signed software update channel
