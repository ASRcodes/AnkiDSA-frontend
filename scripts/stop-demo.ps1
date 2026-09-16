$ErrorActionPreference='Stop'
$appRoot=Split-Path $PSScriptRoot -Parent
$statePath=Join-Path $appRoot '.work/demo-processes.json'
if(-not (Test-Path -LiteralPath $statePath)) { Write-Output 'No processes recorded by the demo launcher.'; exit }
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
foreach($entry in $state.psobject.Properties) {
    $info=$entry.Value
    $process=Get-Process -Id $info.id -ErrorAction SilentlyContinue
    $details=Get-CimInstance Win32_Process -Filter "ProcessId=$($info.id)" -ErrorAction SilentlyContinue
    if($process -and $details.CommandLine -like "*$($info.marker)*" -and $process.StartTime.ToUniversalTime().ToString('o') -eq $info.started) {
        Stop-Process -Id $info.id
        Write-Output "Stopped $($entry.Name)."
    }
}
Remove-Item -LiteralPath $statePath
