<#
  Zayn Coffee PH - render the social preview image
  -------------------------------------------------
  Renders tools/og-template.html with headless Chrome (or Edge) at 1200x630
  and saves assets/img/og/zayn-coffee-og-v6.jpg. Needs an internet connection for
  the Google Fonts used by the template.

  Usage (from the project root):
    powershell -ExecutionPolicy Bypass -File tools/make-og-image.ps1
#>
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$template = Join-Path $root "tools\og-template.html"
$out = Join-Path $root "assets\img\og\zayn-coffee-og-v6.jpg"
$tmpPng = Join-Path $env:TEMP "zayn-og-render.png"
$profile = Join-Path $env:TEMP "zayn-og-chrome-profile"

$browser = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw "Chrome or Edge not found." }

$url = "file:///" + ($template -replace '\\', '/' -replace ' ', '%20')
& $browser --headless=new --disable-gpu --hide-scrollbars --allow-file-access-from-files `
  "--user-data-dir=$profile" --virtual-time-budget=10000 --window-size=1200,630 `
  "--screenshot=$tmpPng" $url 2>$null | Out-Null
Start-Sleep -Milliseconds 500
if (-not (Test-Path $tmpPng)) { throw "Render failed." }

$img = [System.Drawing.Image]::FromFile($tmpPng)
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]88)
New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
$img.Save($out, $jpeg, $ep)
Write-Output ("Wrote {0} ({1}x{2})" -f $out, $img.Width, $img.Height)
$img.Dispose(); Remove-Item $tmpPng
