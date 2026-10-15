param([Parameter(Mandatory=$true)][string]$ConfigFile,
      [switch]$ApkOnly,
      [string]$PrivateDirectory = "$env:USERPROFILE\.ankidsa\signing-beta")
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
if ($config.APP_ENV -notin @('production','staging')) { throw 'Use production or staging release configuration.' }
$env:ANDROID_KEYSTORE_PATH = Join-Path $PrivateDirectory 'ankidsa-release.p12'
$password = [IO.File]::ReadAllText((Join-Path $PrivateDirectory 'password.txt')).Trim()
$env:ANDROID_KEYSTORE_PASSWORD = $password
$env:ANDROID_KEY_PASSWORD = $password
$env:ANDROID_KEY_ALIAS = 'ankidsa'
try {
    # Windows PowerShell treats native stderr as ErrorRecords even for warnings.
    # Check the actual exit code instead of terminating on the first warning.
    $ErrorActionPreference = 'Continue'
    & flutter.bat build apk --release --no-pub --dart-define-from-file=$ConfigFile
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    if (-not $ApkOnly) {
        & flutter.bat build appbundle --release --no-pub --dart-define-from-file=$ConfigFile
        if ($LASTEXITCODE -ne 0) { throw 'AAB build failed.' }
    }
} finally {
    $ErrorActionPreference = 'Stop'
    Remove-Item Env:ANDROID_KEYSTORE_PASSWORD,Env:ANDROID_KEY_PASSWORD -ErrorAction SilentlyContinue
    $password = $null
}
Write-Output 'APK: build/app/outputs/flutter-apk/app-release.apk'
if (-not $ApkOnly) { Write-Output 'AAB: build/app/outputs/bundle/release/app-release.aab' }
if ($config.VALIDATION_ONLY -eq 'true') { Write-Output 'VALIDATION ONLY: do not distribute these artifacts to beta users.' }
