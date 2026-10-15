param([string]$PrivateDirectory = "$env:USERPROFILE\.ankidsa\signing-beta")
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($PrivateDirectory)
$workspace = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
if ($root.StartsWith($workspace, [StringComparison]::OrdinalIgnoreCase)) { throw 'Signing material must be outside the repository.' }
if (Test-Path -LiteralPath $root) { throw 'Directory already exists. Preserve your existing key; do not overwrite it.' }
New-Item -ItemType Directory -Path $root | Out-Null
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe $root /inheritance:r /grant:r "${identity}:(OI)(CI)F" | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not restrict signing directory permissions.' }
$bytes = New-Object byte[] 48
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$passwordFile = Join-Path $root 'password.txt'
[IO.File]::WriteAllText($passwordFile, [Convert]::ToBase64String($bytes))
$keytool = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' } else { (Get-Command keytool.exe).Source }
& $keytool -genkeypair -keystore (Join-Path $root 'ankidsa-release.p12') -storetype PKCS12 -storepass:file $passwordFile -keypass:file $passwordFile -alias ankidsa -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=AnkiDSA Beta' -noprompt
if ($LASTEXITCODE -ne 0) { throw 'Signing key generation failed.' }
Write-Output "Private signing key created outside the repository: $root. Back up this directory securely before distributing builds."
