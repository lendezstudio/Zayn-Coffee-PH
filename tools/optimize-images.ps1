<#
  Zayn Coffee PH - image optimizer
  ---------------------------------
  Reads the untouched client originals in /Images and /Images from Client
  (JPEG, HEIF or HEIC) and writes resized, web-ready JPEGs into /assets/img.
  Originals are never modified.

  Usage (from the project root):
    powershell -ExecutionPolicy Bypass -File tools/optimize-images.ps1

  To add or replace a photo: add a line to $manifest below and re-run.
    src   = start of the original filename (unique prefix)
    dir   = optional "client" to read from /Images from Client (default /Images)
    out   = output path under assets/img, without extension
    w     = widths to generate (skipped if larger than the source)
    crop  = optional [x, y, w, h] as fractions of the source image
    size  = optional fixed [width, height] output (used with crop)
#>

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore, WindowsBase   # Windows imaging codecs (HEIF/HEIC)

$root    = Split-Path -Parent $PSScriptRoot
$srcDir  = Join-Path $root "Images"
$clientDir = Join-Path $root "Images from Client"
$outDir  = Join-Path $root "assets\img"
$quality = 82

$manifest = @(
  # Hero
  @{ src="809876097"; out="hero/cup-hallway";            w=@(480,960) }
  @{ src="528314007"; out="hero/latte-art-pour";         w=@(480,960) }

  # Our Story
  @{ src="675176519"; out="story/barista-espresso-machine"; w=@(480,960) }
  # Thatched-roof tile: client photo of the entrance under the thatched roof
  @{ src="IMG_5902";  dir="client"; out="story/entrance-thatched-roof"; w=@(480,960) }
  @{ src="601854507"; out="story/rattan-seating-nook";      w=@(480,960) }
  @{ src="602335049"; out="story/pendant-lights-arch";      w=@(480,960) }
  @{ src="IMG_3621";  dir="client"; out="story/table-dried-flowers"; w=@(480,960) }
  # Materials strip (whole photos, uncropped)
  @{ src="601814454"; out="story/textured-cream-wall";      w=@(480,960) }
  @{ src="676023496"; out="story/metal-tables";             w=@(480,960) }

  # Menu: drinks named by Zayn Coffee in their filenames (Images from Client)
  @{ src="Cinnamon Latt";      dir="client"; out="menu/cinnamon-latte";      w=@(480,960) }
  @{ src="Iced spanish Latt";  dir="client"; out="menu/spanish-latte-iced";  w=@(480,960) }
  @{ src="Iced caff";          dir="client"; out="menu/cafe-latte-iced";     w=@(480,960) }
  @{ src="Cold brew";          dir="client"; out="menu/cold-brew";           w=@(480,960) }
  @{ src="Mont Blanc";         dir="client"; out="menu/mont-blanc";          w=@(480,960) }
  @{ src="Hot V60";            dir="client"; out="menu/hot-v60";             w=@(480,960) }
  @{ src="Iced Japanese Pour"; dir="client"; out="menu/iced-japanese-v60";   w=@(480,960) }
  @{ src="Matcha Orange";      dir="client"; out="menu/matcha-orange";       w=@(480,960) }
  @{ src="Iced Long Black";    dir="client"; out="menu/iced-long-black";     w=@(480,960) }
  @{ src="IMG_3620";           dir="client"; out="menu/toasted-sandwich";    w=@(480,960) }
  # Menu: earlier photos (photo-to-item matches PENDING CLIENT CONFIRMATION)
  @{ src="680132209"; out="menu/cinnamon-rolls";         w=@(480,960) }
  @{ src="749330169"; out="menu/matcha-cookies";         w=@(480,960) }
  @{ src="749355219"; out="menu/coffee-served-on-tray";  w=@(480,960) }
  @{ src="690854093_edited"; out="menu/matcha-latte-hot";       w=@(480,960) }
  @{ src="601433788"; out="menu/pastry-case";            w=@(480,960) }

  # Cafe gallery (Zayn Experience): client photos of the space, bar, coffee and entrance
  @{ src="IMG_3623";     dir="client"; out="gallery/window-table-rattan";   w=@(480,960) }
  @{ src="IMG_3618";     dir="client"; out="gallery/window-bar-cacti";      w=@(480,960) }
  @{ src="IMG_3619";     dir="client"; out="gallery/need-more-coffee-wall"; w=@(480,960) }
  @{ src="IMG_3616";     dir="client"; out="gallery/coffee-bar";            w=@(480,960) }
  @{ src="IMG_3578";     dir="client"; out="gallery/seating-life-happens";  w=@(480,960,1600) }
  @{ src="721387732";    out="gallery/latte-art-cup";         w=@(480,960) }
  @{ src="718075932";    out="gallery/doorway-night";           w=@(480,960) }

  # Merchandise (client product photos; beans photo PENDING CLIENT CONFIRMATION)
  @{ src="678935518"; out="merch/coffee-beans";     w=@(480,960) }
  @{ src="V60 dripper (whitecolor)";  dir="client"; out="merch/v60-white";  w=@(480,960) }
  @{ src="V60 dripper (transparent)"; dir="client"; out="merch/v60-clear";  w=@(480,960) }
  @{ src="Switch V60";                dir="client"; out="merch/v60-switch"; w=@(480,960) }
  @{ src="Zayn Coffee Decanter";      dir="client"; out="merch/decanter";   w=@(480,960) }
  @{ src="Zayn Coffee Glass";         dir="client"; out="merch/glass";      w=@(480,960) }
  @{ src="IMG_3563";                  dir="client"; out="merch/tshirts";    w=@(480,960,1600) }

  # Mobile Coffee Events: real event setups (Images from Client)
  @{ src="att.";      dir="client"; out="events/cart-canopy-lawn";    w=@(480,960) }
  @{ src="IMG_2721";  dir="client"; out="events/cart-covered-patio";  w=@(480,960) }
  # Package cards (coffee mood images)
  @{ src="720823189"; out="events/pkg-latte-tray";  w=@(480,960) }
  @{ src="795661510"; out="events/pkg-latte-golden-hour"; w=@(480,960) }
  @{ src="611988043"; out="events/pkg-iced-latte";  w=@(480,960) }

  # Visit + final CTA
  @{ src="IMG_5459";  dir="client"; out="visit/storefront-sunny"; w=@(480,960) }
  @{ src="IMG_5921."; dir="client"; out="cta/storefront-dusk";    w=@(960,1600,2048) }
  # Night doorway: no longer on the page, kept because tools/og-template.html uses it
  @{ src="718075932"; out="visit/doorway-night";   w=@(960) }

  # (Social preview image is rendered separately by tools/make-og-image.ps1)
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
  $bmp.SetResolution(96, 96)   # fixed DPI metadata, so re-runs produce identical files
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

# HEIF/HEIC (iPhone) files: decode with the Windows imaging codec, hand over as a Bitmap
function Load-Image($file) {
  if ($file.Extension -match '^\.(heif|heic)$') {
    $bi = New-Object System.Windows.Media.Imaging.BitmapImage
    $bi.BeginInit(); $bi.UriSource = New-Object Uri($file.FullName); $bi.CacheOption = 'OnLoad'; $bi.EndInit()
    $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bi))
    $ms = New-Object IO.MemoryStream; $enc.Save($ms); $ms.Position = 0
    return [System.Drawing.Bitmap]::FromStream($ms)
  }
  $img = [System.Drawing.Image]::FromFile($file.FullName)
  Fix-Orientation $img
  return $img
}

foreach ($m in $manifest) {
  $dir = if ($m.dir -eq "client") { $clientDir } else { $srcDir }
  $file = Get-ChildItem -LiteralPath $dir -File |
    Where-Object { $_.Name.StartsWith($m.src) -and $_.Extension -match '^\.(jpe?g|png|heif|heic)$' } |
    Sort-Object Name | Select-Object -First 1
  if (-not $file) { Write-Warning "Missing source: $($m.src)"; continue }

  $img = Load-Image $file

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

# ---- Brand + favicons, all made from the official "Zayn Logo" file ----
# Small tab icons use the logo's thumbs-up mark (the ZAYN COFFEE wording is
# unreadable at 16-48px); larger icons use the full logo. Proportions are kept.
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class LogoAlpha {
  // Black-on-white artwork -> ink-coloured artwork on transparency (alpha = darkness)
  public static Bitmap Make(Bitmap src, int r, int g, int b) {
    int w = src.Width, h = src.Height;
    var s = src.Clone(new Rectangle(0, 0, w, h), PixelFormat.Format32bppArgb);
    var d = s.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    byte[] p = new byte[d.Stride * h]; Marshal.Copy(d.Scan0, p, 0, p.Length);
    for (int i = 0; i < p.Length; i += 4) {
      int a = 255 - (p[i] + p[i + 1] + p[i + 2]) / 3;
      a = Math.Min(255, Math.Max(0, (a - 12) * 255 / 230));   // clean near-white paper
      p[i] = (byte)b; p[i + 1] = (byte)g; p[i + 2] = (byte)r; p[i + 3] = (byte)a;
    }
    Marshal.Copy(p, 0, d.Scan0, p.Length); s.UnlockBits(d); return s;
  }
  static byte[] Alpha(Bitmap b, out int stride) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    stride = d.Stride; byte[] p = new byte[d.Stride * b.Height]; Marshal.Copy(d.Scan0, p, 0, p.Length); b.UnlockBits(d); return p;
  }
  // Bounding box of visible artwork (alpha > 24)
  public static Rectangle Bounds(Bitmap b) {
    int st; byte[] p = Alpha(b, out st); int x0 = b.Width, y0 = b.Height, x1 = 0, y1 = 0;
    for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++)
      if (p[y * st + x * 4 + 3] > 24) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
    return new Rectangle(x0, y0, x1 - x0 + 1, y1 - y0 + 1);
  }
  // Thicken strokes (circular max filter on alpha) so tiny icons stay legible
  public static Bitmap Embolden(Bitmap src, int r) {
    int w = src.Width, h = src.Height, st; byte[] p = Alpha(src, out st);
    var outB = (Bitmap)src.Clone();
    var d = outB.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    byte[] q = new byte[d.Stride * h]; Marshal.Copy(d.Scan0, q, 0, q.Length);
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int m = 0;
      for (int dy = -r; dy <= r; dy++) { int yy = y + dy; if (yy < 0 || yy >= h) continue;
        for (int dx = -r; dx <= r; dx++) { int xx = x + dx; if (xx < 0 || xx >= w || dx * dx + dy * dy > r * r) continue;
          int a = p[yy * st + xx * 4 + 3]; if (a > m) m = a; } }
      q[y * d.Stride + x * 4 + 3] = (byte)m;
    }
    Marshal.Copy(q, 0, d.Scan0, q.Length); outB.UnlockBits(d); return outB;
  }
}
"@

$iconDir = Join-Path $root "assets\icons"
New-Item -ItemType Directory -Force $iconDir | Out-Null
$logo = [System.Drawing.Image]::FromFile((Get-ChildItem $srcDir -Filter "Zayn Logo*.jpg" | Select-Object -First 1).FullName)
$markRect = New-Object System.Drawing.RectangleF (0.24*$logo.Width), (0.06*$logo.Height), (0.60*$logo.Width), (0.60*$logo.Height)
$cream = [System.Drawing.Color]::FromArgb(247,240,228)

function Crop-Bitmap($img, $rect, $size) {
  $b = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($b); $g.Clear([System.Drawing.Color]::White)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, (New-Object System.Drawing.Rectangle 0, 0, $size, $size), $rect.X, $rect.Y, $rect.Width, $rect.Height, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose(); return $b
}
# Ink (#241A12) artwork on transparency: the thumbs-up mark, and the full logo
$markInk = [LogoAlpha]::Make((Crop-Bitmap $logo $markRect 600), 36, 26, 18)
$fullRect = New-Object System.Drawing.RectangleF 0, 0, $logo.Width, $logo.Height
$logoInkRaw = [LogoAlpha]::Make((Crop-Bitmap $logo $fullRect 900), 36, 26, 18)
# Trim to the visible artwork so icons aren't shrunk by the file's own margins
$lb = [LogoAlpha]::Bounds($logoInkRaw)
$logoInk = $logoInkRaw.Clone($lb, $logoInkRaw.PixelFormat); $logoInkRaw.Dispose()
$mb = [LogoAlpha]::Bounds($markInk)
$markTrim = $markInk.Clone($mb, $markInk.PixelFormat); $markInk.Dispose(); $markInk = $markTrim

function New-Icon($art, $size, $fill, $rounded) {
  $b = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.SetResolution(96, 96)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $brush = New-Object System.Drawing.SolidBrush $cream
  if ($rounded) {
    $r = [math]::Max(3, [int]($size * 0.22)); $d = 2 * $r
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $d, $d, 180, 90); $path.AddArc($size - $d - 1, 0, $d, $d, 270, 90)
    $path.AddArc($size - $d - 1, $size - $d - 1, $d, $d, 0, 90); $path.AddArc(0, $size - $d - 1, $d, $d, 90, 90)
    $path.CloseFigure(); $g.FillPath($brush, $path)
  } else { $g.FillRectangle($brush, 0, 0, $size, $size) }
  $inner = [int]($size * $fill)
  $scale = [math]::Min($inner / $art.Width, $inner / $art.Height)
  $dw = [int]($art.Width * $scale); $dh = [int]($art.Height * $scale)
  $g.DrawImage($art, [int](($size - $dw) / 2), [int](($size - $dh) / 2), $dw, $dh)
  $g.Dispose(); return $b
}

# Browser-tab icons: mark on a cream rounded square (legible on light and dark tabs)
$icoPngs = @()
# Line weight is thickened slightly at 16/32px only, so the outline holds as solid pixels
$markBold16 = [LogoAlpha]::Embolden($markInk, 11); $markBold32 = [LogoAlpha]::Embolden($markInk, 5)
foreach ($s in 16, 32, 48) {
  $art = switch ($s) { 16 { $markBold16 } 32 { $markBold32 } default { $markInk } }
  $b = New-Icon $art $s 0.84 $true
  $path = Join-Path $iconDir "favicon-$s.png"; $b.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
  $icoPngs += ,@($s, [IO.File]::ReadAllBytes($path)); Write-Output "icons/favicon-$s.png"
}
# favicon.ico at the site root (browsers request /favicon.ico automatically); PNG-compressed entries
$icoPath = Join-Path $root "favicon.ico"
$fs = [IO.File]::Create($icoPath); $bw = New-Object IO.BinaryWriter $fs
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$icoPngs.Count)
$offset = 6 + 16 * $icoPngs.Count
foreach ($e in $icoPngs) {
  $bw.Write([byte]$e[0]); $bw.Write([byte]$e[0]); $bw.Write([byte]0); $bw.Write([byte]0)
  $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$e[1].Length); $bw.Write([uint32]$offset)
  $offset += $e[1].Length
}
foreach ($e in $icoPngs) { $bw.Write([byte[]]$e[1]) }
$bw.Close(); Write-Output "favicon.ico (16, 32, 48)"

# Home-screen / app icons: full logo (mark + ZAYN COFFEE) on cream; iOS/Android round the corners
foreach ($icon in @(@{n="apple-touch-icon.png";s=180;f=0.66}, @{n="icon-192.png";s=192;f=0.62}, @{n="icon-512.png";s=512;f=0.62})) {
  $b = New-Icon $logoInk $icon.s $icon.f $false
  $b.Save((Join-Path $iconDir $icon.n), [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
  Write-Output "icons/$($icon.n)"
}
$markInk.Dispose(); $logoInk.Dispose(); $markBold16.Dispose(); $markBold32.Dispose()

# ---- Transparent brand mark (black mark, alpha from darkness) for use on any background ----
$ms = 160
$tmp = New-Object System.Drawing.Bitmap $ms, $ms
$g = [System.Drawing.Graphics]::FromImage($tmp)
$g.Clear([System.Drawing.Color]::White)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($logo, (New-Object System.Drawing.Rectangle 0, 0, $ms, $ms), $markRect.X, $markRect.Y, $markRect.Width, $markRect.Height, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$png = New-Object System.Drawing.Bitmap $ms, $ms, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$png.SetResolution(96, 96)
for ($y = 0; $y -lt $ms; $y++) { for ($x = 0; $x -lt $ms; $x++) {
  $c = $tmp.GetPixel($x, $y)
  $a = 255 - [int](($c.R + $c.G + $c.B) / 3)
  $png.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, 36, 26, 18))
} }
$png.Save((Join-Path $outDir "brand\zayn-mark.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$tmp.Dispose(); $png.Dispose()
Write-Output "img/brand/zayn-mark.png"

$logo.Dispose()
