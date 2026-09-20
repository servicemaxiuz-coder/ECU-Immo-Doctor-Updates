# Release process

1. Complete application build, self-tests, release gate, and clean-machine checks.
2. Generate and verify the package `integrity.manifest` locally.
3. ZIP the final Client directory without changing any file.
4. Upload the ZIP to a new draft GitHub Release and obtain its final HTTPS asset URL.
5. In ECU Immo Doctor Admin, generate the signed `update.manifest` for that exact URL and ZIP SHA-256.
6. Run `scripts/verify-update.ps1` against the ZIP and manifest.
7. Upload `update.manifest` to the same GitHub Release and publish it.
8. Replace `stable/update.manifest` with the byte-identical signed manifest and push it to `main`.
9. Confirm the raw stable URL and release asset URL are anonymously downloadable before enabling the client channel.

Never put a private key in this repository or in a GitHub Actions workflow.
