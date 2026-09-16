param([string]$BackendPath = 'C:\SpringBoot\ankidsa')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$backendRoot = (Resolve-Path -LiteralPath $BackendPath).Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stageParent = Join-Path $appRoot ".work/package-$stamp"
$stageRoot = Join-Path $stageParent 'AnkiDSA-local-demo'
$archivePath = Join-Path $appRoot '.work/AnkiDSA-local-demo.zip'
$jarPath = Join-Path $backendRoot 'target/ankidsa-backend-1.0.0.jar'
$apkPath = Join-Path $appRoot 'build/app/outputs/flutter-apk/app-x86_64-debug.apk'
foreach ($required in @($jarPath, $apkPath, (Join-Path $appRoot 'build/web/main.dart.js'))) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Build the demo first; missing $required" }
}

foreach ($folder in @('build', 'backend/target', 'backend/scripts', 'scripts', 'android', 'docs')) {
    New-Item -ItemType Directory -Path (Join-Path $stageRoot $folder) -Force | Out-Null
}
# Copy an explicit list of deliverables. Never copy .local, .work, or a source tree wholesale.
Copy-Item -LiteralPath (Join-Path $appRoot 'build/web') -Destination (Join-Path $stageRoot 'build/web') -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'extension') -Destination (Join-Path $stageRoot 'extension') -Recurse
Copy-Item -LiteralPath $jarPath -Destination (Join-Path $stageRoot 'backend/target/ankidsa-backend-1.0.0.jar')
Copy-Item -LiteralPath $apkPath -Destination (Join-Path $stageRoot 'android/app-x86_64-debug.apk')
Copy-Item -LiteralPath (Join-Path $backendRoot 'scripts/reset-demo.ps1') -Destination (Join-Path $stageRoot 'backend/scripts/reset-demo.ps1')
foreach ($file in @('start-demo.ps1', 'stop-demo.ps1', 'serve-demo.cjs')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $stageRoot "scripts/$file")
}
foreach ($file in @('DEMO.md', 'TESTING.md', 'WORKLOG.md')) {
    Copy-Item -LiteralPath (Join-Path $appRoot $file) -Destination (Join-Path $stageRoot "docs/$file")
}
Copy-Item -LiteralPath (Join-Path $appRoot 'docs/LOCAL_DEMO_PACKAGE.md') -Destination (Join-Path $stageRoot 'README.md')

$startScript = @'
param([switch]$OpenBrowser)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/start-demo.ps1') -BackendPath (Join-Path $PSScriptRoot 'backend') -OpenBrowser:$OpenBrowser
'@
$stopScript = @'
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/stop-demo.ps1')
'@
$resetScript = @'
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'backend/scripts/reset-demo.ps1')
'@
[IO.File]::WriteAllText((Join-Path $stageRoot 'Start-Demo.ps1'), $startScript)
[IO.File]::WriteAllText((Join-Path $stageRoot 'Stop-Demo.ps1'), $stopScript)
[IO.File]::WriteAllText((Join-Path $stageRoot 'Reset-Demo.ps1'), $resetScript)

$manifest = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
    [ordered]@{
        path = $_.FullName.Substring($stageRoot.Length + 1).Replace('\', '/')
        bytes = $_.Length
        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    }
})
[IO.File]::WriteAllText((Join-Path $stageRoot 'checksums.json'), ($manifest | ConvertTo-Json -Depth 3))
Compress-Archive -LiteralPath $stageRoot -DestinationPath $archivePath -CompressionLevel Fastest -Force
$result = [ordered]@{
    archive = $archivePath
    stagedFolder = $stageRoot
    bytes = (Get-Item -LiteralPath $archivePath).Length
    sha256 = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    payloadFiles = $manifest.Count
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $appRoot '.work/demo-package.json') -Encoding UTF8
$result | ConvertTo-Json
