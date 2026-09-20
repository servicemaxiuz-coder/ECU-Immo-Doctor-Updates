param(
    [Parameter(Mandatory = $true)][string]$Package,
    [Parameter(Mandatory = $true)][string]$Manifest,
    [string]$PublicKey = (Join-Path $PSScriptRoot '..\keys\release_public.pem')
)

$ErrorActionPreference = 'Stop'
$packagePath = (Resolve-Path -LiteralPath $Package).Path
$manifestPath = (Resolve-Path -LiteralPath $Manifest).Path
$publicKeyPath = (Resolve-Path -LiteralPath $PublicKey).Path
if ([IO.Path]::GetExtension($packagePath) -ne '.zip') { throw 'Package must be a ZIP file.' }
if ((Get-Item -LiteralPath $packagePath).Length -gt 600MB) { throw 'Package exceeds 600 MiB.' }

$envelope = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($envelope.payload) -or [string]::IsNullOrWhiteSpace($envelope.signature)) { throw 'Incomplete signed envelope.' }

function Decode-Base64Url([string]$value) {
    $base64 = $value.Replace('-', '+').Replace('_', '/')
    switch ($base64.Length % 4) { 2 { $base64 += '==' } 3 { $base64 += '=' } 1 { throw 'Invalid Base64Url length.' } }
    [Convert]::FromBase64String($base64)
}

$payloadBytes = Decode-Base64Url $envelope.payload
$signatureBytes = Decode-Base64Url $envelope.signature
$rsa = [Security.Cryptography.RSA]::Create()
try {
    $rsa.ImportFromPem((Get-Content -LiteralPath $publicKeyPath -Raw))
    $valid = $rsa.VerifyData($payloadBytes, $signatureBytes, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pss)
} finally { $rsa.Dispose() }
if (-not $valid) { throw 'Invalid release signature.' }

$payload = [Text.Encoding]::UTF8.GetString($payloadBytes) | ConvertFrom-Json
if ($payload.productId -ne 'ECU_IMMO_DOCTOR-CONTINENTAL-V2') { throw 'Product ID mismatch.' }
if ([int]$payload.build -le 0) { throw 'Invalid build.' }
if (-not ([Uri]$payload.packageUrl).Scheme.Equals('https', [StringComparison]::OrdinalIgnoreCase)) { throw 'Package URL must use HTTPS.' }
$actual = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash
if ($actual -ne ([string]$payload.packageSha256).ToUpperInvariant()) { throw 'Package SHA-256 mismatch.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($packagePath)
try {
    $names = @($archive.Entries | ForEach-Object FullName)
    if ($names -notcontains 'ECUImmoDoctor.exe') { throw 'ECUImmoDoctor.exe is not at package root.' }
    if ($names -notcontains 'integrity.manifest') { throw 'integrity.manifest is not at package root.' }
    $forbidden = $names | Where-Object { $_ -match '(?i)(private.*\.(pem|key|pfx|p12)|\.lic$|HWID/|secrets/)' }
    if ($forbidden) { throw ('Forbidden content: ' + ($forbidden -join ', ')) }
} finally { $archive.Dispose() }

[pscustomobject]@{ Status='PASS'; ProductId=$payload.productId; Version=$payload.version; Build=$payload.build; PackageSha256=$actual; PackageUrl=$payload.packageUrl }
