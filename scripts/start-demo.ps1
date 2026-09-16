param(
    [string]$BackendPath = 'C:\SpringBoot\ankidsa',
    [switch]$Rebuild,
    [switch]$OpenBrowser
)
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$backendRoot = (Resolve-Path -LiteralPath $BackendPath).Path
Set-Location -LiteralPath $appRoot
New-Item -ItemType Directory -Force .work | Out-Null
$jarPath = Join-Path $backendRoot 'target/ankidsa-backend-1.0.0.jar'
$backendReady = $false
try { $backendReady = (Invoke-RestMethod 'http://127.0.0.1:8081/health' -TimeoutSec 5).status -eq 'ok' } catch {}
if ($Rebuild -and $backendReady) { throw 'Stop the running demo before rebuilding its JAR. Use scripts/stop-demo.ps1 if this launcher started it.' }
if ($Rebuild -or -not (Test-Path -LiteralPath $jarPath)) {
    Push-Location -LiteralPath $backendRoot
    try { & ./scripts/maven.ps1 -B package; if ($LASTEXITCODE -ne 0) { throw 'Backend build failed.' } } finally { Pop-Location }
}
if ($Rebuild -or -not (Test-Path build/web/main.dart.js)) {
    & flutter.bat build web --no-wasm-dry-run --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:8081 --dart-define=DEMO_MODE=true
    if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed.' }
}
$runInfo = @{}
if (Test-Path .work/demo-processes.json) {
    $oldRun = Get-Content .work/demo-processes.json -Raw | ConvertFrom-Json
    foreach ($entry in $oldRun.psobject.Properties) { $runInfo[$entry.Name] = $entry.Value }
}
if (-not $backendReady) {
    $localDir = Join-Path $backendRoot '.local'
    New-Item -ItemType Directory -Force $localDir | Out-Null
    $secretPath = Join-Path $localDir 'jwt-secret'
    if (-not (Test-Path -LiteralPath $secretPath)) {
        $bytes = New-Object byte[] 48
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        [IO.File]::WriteAllText($secretPath,[Convert]::ToBase64String($bytes))
    }
    $env:JWT_SECRET = [IO.File]::ReadAllText($secretPath)
    $javaPath = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java.exe' } else { "$env:USERPROFILE/.jdks/ms-21.0.9/bin/java.exe" }
    if (-not (Test-Path -LiteralPath $javaPath)) { throw 'Set JAVA_HOME to a Java 21 installation.' }
    $backendProcess = Start-Process -FilePath $javaPath -ArgumentList @('-Xmx384m','-jar',('"' + $jarPath + '"'),'--spring.profiles.active=demo') -WorkingDirectory $backendRoot -WindowStyle Hidden -RedirectStandardOutput "$appRoot/.work/backend.log" -RedirectStandardError "$appRoot/.work/backend-error.log" -PassThru
    $runInfo.backend = @{ id=$backendProcess.Id; started=$backendProcess.StartTime.ToUniversalTime().ToString('o'); marker=$jarPath }
}
$webReady = $false
try { $webReady = (Invoke-WebRequest 'http://127.0.0.1:3000' -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch {}
if (-not $webReady) {
    $nodePath=(Get-Command node.exe).Source
    $serverScript=Join-Path $appRoot 'scripts/serve-demo.cjs'
    $webProcess=Start-Process -FilePath $nodePath -ArgumentList ('"' + $serverScript + '"') -WorkingDirectory $appRoot -WindowStyle Hidden -RedirectStandardOutput "$appRoot/.work/web.log" -RedirectStandardError "$appRoot/.work/web-error.log" -PassThru
    $runInfo.web=@{ id=$webProcess.Id; started=$webProcess.StartTime.ToUniversalTime().ToString('o'); marker=$serverScript }
}
$runInfo | ConvertTo-Json | Set-Content .work/demo-processes.json
Write-Output 'Starting AnkiDSA. Logs are in .work/backend.log and .work/web.log.'
$deadline=(Get-Date).AddSeconds(90)
do {
    try { $backendReady=(Invoke-RestMethod 'http://127.0.0.1:8081/health' -TimeoutSec 5).status -eq 'ok' } catch { $backendReady=$false }
    if (-not $backendReady) { Start-Sleep -Seconds 2 }
} while (-not $backendReady -and (Get-Date) -lt $deadline)
if (-not $backendReady) { throw 'Backend startup did not finish. Check .work/backend-error.log and .work/backend.log.' }
Write-Output 'Open http://localhost:3000'
Write-Output 'Demo account: demo@ankidsa.local / DemoRecall!2026'
Write-Output "Load this unpacked Chrome extension: $appRoot\extension"
if ($OpenBrowser) { Start-Process 'http://localhost:3000' -WindowStyle Hidden }
