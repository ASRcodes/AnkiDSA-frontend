$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = Split-Path $PSScriptRoot -Parent
$master = New-Object Drawing.Bitmap 1024,1024
$graphics = [Drawing.Graphics]::FromImage($master)
$graphics.Clear([Drawing.ColorTranslator]::FromHtml('#234F40'))
$graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$font = New-Object Drawing.Font 'Georgia',540,([Drawing.FontStyle]::Bold),([Drawing.GraphicsUnit]::Pixel)
$brush = New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml('#FFFEFA'))
$format = New-Object Drawing.StringFormat
$format.Alignment = [Drawing.StringAlignment]::Center
$format.LineAlignment = [Drawing.StringAlignment]::Center
$graphics.DrawString('a.',$font,$brush,([Drawing.RectangleF]::new(0,-35,1024,1024)),$format)

function Save-Icon([string]$relativePath,[int]$size) {
    $target = Join-Path $appRoot $relativePath
    $bitmap = New-Object Drawing.Bitmap $size,$size
    $canvas = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $canvas.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $canvas.DrawImage($master,0,0,$size,$size)
        $bitmap.Save($target,[Drawing.Imaging.ImageFormat]::Png)
    } finally { $canvas.Dispose(); $bitmap.Dispose() }
}
try {
    foreach ($size in @(16,48,128)) { Save-Icon "extension/icons/$size.png" $size }
    Save-Icon 'web/favicon.png' 32
    foreach ($size in @(192,512)) {
        Save-Icon "web/icons/Icon-$size.png" $size
        Save-Icon "web/icons/Icon-maskable-$size.png" $size
    }
    $densities = @{mdpi=48;hdpi=72;xhdpi=96;xxhdpi=144;xxxhdpi=192}
    foreach ($density in $densities.Keys) {
        Save-Icon "android/app/src/main/res/mipmap-$density/ic_launcher.png" $densities[$density]
    }
    foreach ($catalog in @('ios/Runner/Assets.xcassets/AppIcon.appiconset','macos/Runner/Assets.xcassets/AppIcon.appiconset')) {
        $manifest = Join-Path $appRoot "$catalog/Contents.json"
        if (-not (Test-Path -LiteralPath $manifest)) { continue }
        $contents = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
        foreach ($entry in $contents.images) {
            if (-not $entry.filename) { continue }
            $size = [int]([double]($entry.size -split 'x')[0] * [double]($entry.scale -replace 'x',''))
            Save-Icon "$catalog/$($entry.filename)" $size
        }
    }
    # Windows supports a PNG image inside an ICO directory entry.
    $stream = New-Object IO.MemoryStream
    $windowsIcon = New-Object Drawing.Bitmap $master,256,256
    try { $windowsIcon.Save($stream,[Drawing.Imaging.ImageFormat]::Png) } finally { $windowsIcon.Dispose() }
    $imageBytes = $stream.ToArray()
    $stream.Dispose()
    $ico = [IO.File]::Create((Join-Path $appRoot 'windows/runner/resources/app_icon.ico'))
    $writer = New-Object IO.BinaryWriter $ico
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]0)
        $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$imageBytes.Length); $writer.Write([uint32]22)
        $writer.Write($imageBytes)
    } finally { $writer.Dispose() }
} finally {
    $format.Dispose(); $brush.Dispose(); $font.Dispose(); $graphics.Dispose(); $master.Dispose()
}
Write-Output 'AnkiDSA icons generated.'
