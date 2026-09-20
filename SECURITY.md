# Update-channel security policy

- Never commit private signing keys, licenses, HWID exports, ECU dumps, customer information, or application source code.
- `stable/update.manifest` must be signed locally with the dedicated release private key.
- The release private key must never be stored in GitHub Actions secrets for this public repository.
- Never modify a ZIP after its signed update manifest has been created.
- Every ZIP must contain a separately signed `integrity.manifest` and `ECUImmoDoctor.exe` at its root.
- Reject a release if local SHA-256, signed-manifest SHA-256, and uploaded GitHub asset digest do not agree.
- If any release binary changes, repeat build, self-tests, release gate, package creation, integrity signing, and update-manifest signing.
- Do not reuse or overwrite an existing release tag or asset. Publish a new build and tag.
