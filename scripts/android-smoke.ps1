param([string]$Device = 'emulator-5556')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$adbPath = "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
$package = 'app.ankidsa.mobile'
$activity = "$package/com.example.ankidsa.MainActivity"

function Read-Ui {
    & $adbPath -s $Device shell rm -f /sdcard/ankidsa-ui.xml | Out-Null
    $previousErrorPreference = $ErrorActionPreference
    try {
        # A just-started emulator may have no accessibility root yet.
        # Let Find-Label retry it, including when native stderr is redirected.
        $ErrorActionPreference = 'Continue'
        & $adbPath -s $Device shell uiautomator dump /sdcard/ankidsa-ui.xml 2>$null | Out-Null
        $xml = (& $adbPath -s $Device shell cat /sdcard/ankidsa-ui.xml 2>$null) -join "`n"
    } finally { $ErrorActionPreference = $previousErrorPreference }
    if ($xml -notmatch '<hierarchy') { return $null }
    [IO.File]::WriteAllText((Join-Path $appRoot '.work/android-ui.xml'),$xml)
    return [xml]$xml
}
function Find-Label([string]$Pattern,[switch]$Tap,[switch]$Scroll,[string]$InputKind) {
    $deadline = (Get-Date).AddSeconds(40)
    $swipes = 0
    do {
        $ui = Read-Ui
        $node = $null
        if ($ui) {
            $node = $ui.SelectNodes('//node') | Where-Object {
                if ($InputKind) {
                    $_.GetAttribute('class') -eq 'android.widget.EditText' -and
                        ($_.GetAttribute('password') -eq 'true') -eq ($InputKind -eq 'password')
                } else {
                    ($_.GetAttribute('text') + ' ' + $_.GetAttribute('content-desc')).Trim() -match $Pattern
                }
            } | Select-Object -First 1
        }
        if ($node) {
            if ($Tap) {
                $bounds = [regex]::Match($node.GetAttribute('bounds'),'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
                $x = [int](([int]$bounds.Groups[1].Value + [int]$bounds.Groups[3].Value) / 2)
                $y = [int](([int]$bounds.Groups[2].Value + [int]$bounds.Groups[4].Value) / 2)
                & $adbPath -s $Device shell input tap $x $y | Out-Null
            }
            return
        }
        if ($ui -and $Scroll -and $swipes -lt 4) {
            & $adbPath -s $Device shell input swipe 540 1500 540 550 350 | Out-Null
            $swipes++
        }
        Start-Sleep -Milliseconds 400
    } while ((Get-Date) -lt $deadline)
    throw "Android screen did not show '$Pattern'. Inspect .work/android-ui.xml."
}
function Screenshot([string]$Name) {
    $previousErrorPreference = $ErrorActionPreference
    try {
        # adb writes successful transfer progress to stderr as well.
        $ErrorActionPreference = 'Continue'
        & $adbPath -s $Device shell screencap -p /sdcard/ankidsa-screen.png 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not capture the test emulator screen.' }
        & $adbPath -s $Device pull /sdcard/ankidsa-screen.png (Join-Path $appRoot ".work/$Name") 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not copy the test emulator screenshot.' }
    } finally { $ErrorActionPreference = $previousErrorPreference }
}

$avdName = & $adbPath -s $Device emu avd name
if ($avdName -notcontains 'AnkiDSA_Demo_64') { throw 'Use the dedicated AnkiDSA_Demo_64 test emulator.' }
& $adbPath -s $Device shell am force-stop $package | Out-Null
& $adbPath -s $Device shell pm clear $package | Out-Null
$testEmail = "android-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())@example.com"
$testPassword = 'NativeRecall2026'
$credentials = @{ email=$testEmail; password=$testPassword; name='Native verification' } | ConvertTo-Json -Compress
$session = Invoke-RestMethod http://127.0.0.1:8081/api/auth/register -Method Post -ContentType application/json -Body $credentials
$headers = @{ Authorization = "Bearer $($session.token)" }
$problem = @{ leetcodeUrl='https://leetcode.com/problems/valid-parentheses/'; title='Valid Parentheses'; difficulty='EASY'; tags='stack'; notes='Use a stack of opening brackets. Match each closing bracket with the most recent opening bracket.' } | ConvertTo-Json -Compress
Invoke-RestMethod http://127.0.0.1:8081/api/problems -Method Post -ContentType application/json -Headers $headers -Body $problem | Out-Null
$before = Invoke-RestMethod http://127.0.0.1:8081/api/stats -Headers $headers
& $adbPath -s $Device shell am start -n $activity | Out-Null
Find-Label 'email field' -Tap -Scroll -InputKind email
& $adbPath -s $Device shell input text $testEmail | Out-Null
& $adbPath -s $Device shell input keyevent 4 | Out-Null
Find-Label 'password field' -Tap -Scroll -InputKind password
& $adbPath -s $Device shell input text $testPassword | Out-Null
& $adbPath -s $Device shell input keyevent 4 | Out-Null
Find-Label '^Sign in$' -Tap -Scroll
Find-Label 'Your daily practice'
Find-Label '^Begin a review$'
Screenshot 'android-queue.png'
Find-Label '^Begin a review$' -Tap
Find-Label '^Reveal my notes$' -Tap -Scroll
Find-Label 'Use a stack of opening brackets'
Screenshot 'android-review.png'
Find-Label '^Good' -Tap -Scroll
Find-Label 'Scheduled for'
$after = Invoke-RestMethod http://127.0.0.1:8081/api/stats -Headers $headers
if ($after.totalReviews -ne ($before.totalReviews + 1) -or $after.dueToday -ne ($before.dueToday - 1)) {
    throw 'Native review did not update the backend statistics correctly.'
}
& $adbPath -s $Device shell am force-stop $package | Out-Null
& $adbPath -s $Device shell am start -n $activity | Out-Null
Find-Label 'Your daily practice'
Find-Label 'A good place to pause'
Screenshot 'android-restored-session.png'
Write-Output 'Android sign-in, note reveal, review, backend statistics, and restored session passed.'
