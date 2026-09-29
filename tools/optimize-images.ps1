<#
  Zayn Coffee PH - image optimizer
  ---------------------------------
  Reads the untouched client originals in /Images and writes resized,
  web-ready JPEGs into /assets/img. Originals are never modified.

  Usage (from the project root):
    powershell -ExecutionPolicy Bypass -File tools/optimize-images.ps1

  To add or replace a photo: add a line to $manifest below and re-run.
    src   = start of the original filename in /Images (unique prefix)
    out   = output path under assets/img, without extension
    w     = widths to generate (skipped if larger than the source)
    crop  = optional [x, y, w, h] as fractions of the source image
    size  = optional fixed [width, height] output (used with crop)
#>

Add-Type -AssemblyName System.Drawing

$root    = Split-Path -Parent $PSScriptRoot
$srcDir  = Join-Path $root "Images"
$outDir  = Join-Path $root "assets\img"
$quality = 82

$manifest = @(
  # Hero
  @{ src="809876097"; out="hero/cup-hallway";            w=@(480,960) }
  @{ src="528314007"; out="hero/latte-art-pour";         w=@(480,960) }

  # Our Story
  @{ src="675176519"; out="story/barista-espresso-machine"; w=@(480,960) }
  @{ src="600344374"; out="story/storefront-thatched-roof"; w=@(480,960,1600) }
  @{ src="601854507"; out="story/rattan-seating-nook";      w=@(480,960) }
  @{ src="602335049"; out="story/pendant-lights-arch";      w=@(480,960) }
  @{ src="601457202"; out="story/coffee-bar-pastry-fridge"; w=@(480,960) }
  # Materials strip (whole photos, uncropped)
  @{ src="601814454"; out="story/textured-cream-wall";      w=@(480,960) }
  @{ src="676023496"; out="story/metal-tables";             w=@(480,960) }

  # Menu (photo-to-item matches are PENDING CLIENT CONFIRMATION)
  @{ src="721387732"; out="menu/cafe-latte";             w=@(480,960) }
  @{ src="612236182"; out="menu/iced-matcha-latte";      w=@(480,960) }
  @{ src="603863609"; out="menu/butter-croissant";       w=@(480,960) }
  @{ src="615782441"; out="menu/blueberry-cheesecake";   w=@(480,960) }
  @{ src="749330169"; out="menu/matcha-cookies";         w=@(480,960) }
  @{ src="778972777"; out="menu/long-black-and-latte";   w=@(480,960) }
  @{ src="690854093"; out="menu/matcha-latte-hot";       w=@(480,960) }
  @{ src="601433788"; out="menu/pastry-case";            w=@(480,960) }
  @{ src="612463648"; out="menu/turkey-cheese-sandwich"; w=@(480,960) }

  # Zayn Experience
  @{ src="601436075"; out="experience/window-bar-arch";    w=@(480,960) }
  @{ src="602390018"; out="experience/dining-room";        w=@(480,960) }
  @{ src="718075932"; out="experience/doorway-night";      w=@(480,960) }
  @{ src="602322424"; out="experience/backlit-seating";    w=@(480,960) }
  @{ src="600286684"; out="experience/window-table";       w=@(480,960) }
  @{ src="527737296"; out="experience/espresso-machine";   w=@(480,960) }
  @{ src="603925583"; out="experience/bar-station";        w=@(480,960) }
  @{ src="603881604"; out="experience/cup-on-metal-table"; w=@(480,960) }

  # Merchandise (PENDING CLIENT CONFIRMATION of product match)
  @{ src="678935518"; out="merch/coffee-beans";     w=@(480,960) }
  @{ src="673590696"; out="merch/decanter-glass";   w=@(480,960) }

  # Mobile Coffee Events (temporary mood image, not an event photo)
  @{ src="602317368"; out="events/branded-cups";    w=@(480,960) }
  @{ src="720823189"; out="events/pkg-latte-tray";  w=@(480,960) }
  @{ src="721169758"; out="events/pkg-latte-water"; w=@(480,960) }
  @{ src="611988043"; out="events/pkg-iced-latte";  w=@(480,960) }

  # Visit + final CTA
  @{ src="604525695"; out="visit/coffee-sign-cacti"; w=@(480,960) }
  @{ src="600883003"; out="cta/storefront-night";    w=@(960,1600,2048) }

  # Brand + social preview
  @{ src="600344374"; out="og/zayn-coffee-og"; crop=@(0.0,0.12,1.0,0.66); size=@(1200,630) }
)

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]$quality)

function Fix-Orientation($img) {
  if ($img.PropertyIdList -contains 274) {
    $o = $img.GetPropertyItem(274).Value[0]
    switch ($o) {
      3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
      6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
      8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
  }
}

function Save-Resized($img, $rect, $w, $h, $path) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $attr = New-Object System.Drawing.Imaging.ImageAttributes
  $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
  $dest = New-Object System.Drawing.Rectangle 0, 0, $w, $h
  $g.DrawImage($img, $dest, $rect.X, $rect.Y, $rect.Width, $rect.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
  $bmp.Save($path, $jpeg, $encParams)
  $g.Dispose(); $bmp.Dispose()
}

foreach ($m in $manifest) {
  $file = Get-ChildItem $srcDir -Filter "$($m.src)*.jpg" | Select-Object -First 1
  if (-not $file) { Write-Warning "Missing source: $($m.src)"; continue }

  $img = [System.Drawing.Image]::FromFile($file.FullName)
  Fix-Orientation $img

  if ($m.crop) {
    $rect = New-Object System.Drawing.RectangleF ($m.crop[0]*$img.Width), ($m.crop[1]*$img.Height), ($m.crop[2]*$img.Width), ($m.crop[3]*$img.Height)
  } else {
    $rect = New-Object System.Drawing.RectangleF 0, 0, $img.Width, $img.Height
  }

  $base = Join-Path $outDir $m.out
  New-Item -ItemType Directory -Force (Split-Path $base) | Out-Null

  if ($m.size) {
    # Fixed output: fit crop to the target aspect ratio (centre)
    $ta = $m.size[0] / $m.size[1]; $ra = $rect.Width / $rect.Height
    if ($ra -gt $ta) { $nw = $rect.Height * $ta; $rect.X += ($rect.Width - $nw) / 2; $rect.Width = $nw }
    else { $nh = $rect.Width / $ta; $rect.Y += ($rect.Height - $nh) / 2; $rect.Height = $nh }
    Save-Resized $img $rect $m.size[0] $m.size[1] "$base.jpg"
    Write-Output ("{0}.jpg  {1}x{2}" -f $m.out, $m.size[0], $m.size[1])
  } else {
    foreach ($w in $m.w) {
      if ($w -gt $rect.Width) { continue }
      $h = [int][math]::Round($rect.Height * $w / $rect.Width)
      Save-Resized $img $rect $w $h "$base-$w.jpg"
      Write-Output ("{0}-{1}.jpg  {1}x{2}" -f $m.out, $w, $h)
    }
  }
  $img.Dispose()
}

# ---- Favicons: thumbs-up mark on brand cream, written to /assets/icons ----
$iconDir = Join-Path $root "assets\icons"
New-Item -ItemType Directory -Force $iconDir | Out-Null
$logo = [System.Drawing.Image]::FromFile((Get-ChildItem $srcDir -Filter "Zayn Logo*.jpg" | Select-Object -First 1).FullName)
$markRect = New-Object System.Drawing.RectangleF (0.24*$logo.Width), (0.06*$logo.Height), (0.60*$logo.Width), (0.60*$logo.Height)
$cream = [System.Drawing.Color]::FromArgb(247,240,228)
foreach ($icon in @(@{n="favicon-32.png";s=32;p=0.08}, @{n="apple-touch-icon.png";s=180;p=0.16}, @{n="icon-512.png";s=512;p=0.16})) {
  $s = $icon.s; $pad = [int]($s * $icon.p)
  $bmp = New-Object System.Drawing.Bitmap $s, $s
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear($cream)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  # Multiply-style: draw the black-on-white mark, then knock white to cream
  $inner = $s - 2*$pad
  $scale = [math]::Min($inner / $markRect.Width, $inner / $markRect.Height)
  $dw = [int]($markRect.Width * $scale); $dh = [int]($markRect.Height * $scale)
  $attr = New-Object System.Drawing.Imaging.ImageAttributes
  $attr.SetColorKey([System.Drawing.Color]::FromArgb(200,200,200), [System.Drawing.Color]::White)
  $g.DrawImage($logo, (New-Object System.Drawing.Rectangle ([int](($s-$dw)/2)), ([int](($s-$dh)/2)), $dw, $dh), $markRect.X, $markRect.Y, $markRect.Width, $markRect.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
  $bmp.Save((Join-Path $iconDir $icon.n), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output "icons/$($icon.n)"
}

# ---- Transparent brand mark (black mark, alpha from darkness) for use on any background ----
$ms = 160
$tmp = New-Object System.Drawing.Bitmap $ms, $ms
$g = [System.Drawing.Graphics]::FromImage($tmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($logo, (New-Object System.Drawing.Rectangle 0, 0, $ms, $ms), $markRect.X, $markRect.Y, $markRect.Width, $markRect.Height, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$png = New-Object System.Drawing.Bitmap $ms, $ms, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $ms; $y++) { for ($x = 0; $x -lt $ms; $x++) {
  $c = $tmp.GetPixel($x, $y)
  $a = 255 - [int](($c.R + $c.G + $c.B) / 3)
  $png.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, 36, 26, 18))
} }
$png.Save((Join-Path $outDir "brand\zayn-mark.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$tmp.Dispose(); $png.Dispose()
Write-Output "img/brand/zayn-mark.png"

$logo.Dispose()
