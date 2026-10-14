Add-Type -AssemblyName System.Drawing

function Resize-Image($srcPath, $dstPath, $w, $h) {
    $src = [System.Drawing.Image]::FromFile($srcPath)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()
    $src.Dispose()
    
    $dstDir = [System.IO.Path]::GetDirectoryName($dstPath)
    if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    if (Test-Path $dstPath) { Remove-Item $dstPath -Force }
    $bmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created: $dstPath ($w x $h)"
}

$logoSrc = 'C:\Users\erd5334\.gemini\antigravity\brain\caef0283-0f52-4958-98e0-55889a335331\sahne_senin_logo_1791724584179.jpg'
$bannerSrc = 'C:\Users\erd5334\.gemini\antigravity\brain\caef0283-0f52-4958-98e0-55889a335331\sahne_senin_banner_1791724602047.jpg'

Resize-Image $logoSrc 'play_store_assets\icon_512x512.png' 512 512
Resize-Image $bannerSrc 'play_store_assets\feature_graphic_1024x500.png' 1024 500

Resize-Image $logoSrc 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' 48 48
Resize-Image $logoSrc 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' 72 72
Resize-Image $logoSrc 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' 96 96
Resize-Image $logoSrc 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' 144 144
Resize-Image $logoSrc 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' 192 192

Write-Host "All icons generated successfully!"
