<#
  Zayn Coffee PH - remove the "Matcha Soy Lattè" caption from photo 690854093
  -----------------------------------------------------------------------------
  The client photo has white caption text printed over the steel tray. This
  masks the caption (bright pixels inside a diagonal band along the text) and
  fills it from the surrounding tray by diffusion. The original in /Images is
  NOT modified; a separate edited copy is written next to it:
    Images/690854093_edited_no-caption.jpg
  tools/optimize-images.ps1 then uses that copy.

  Usage (from the project root):
    powershell -ExecutionPolicy Bypass -File tools/remove-caption.ps1 [-Debug <overlay.png>]
#>
param([string]$DebugOverlay = "")

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class CaptionRemover {
  // Band: centre line y = cy0 + slope * (x - x0) (fractions of width/height), half-height hh
  public static Bitmap Run(Bitmap src, double x0, double x1, double cy0, double slope, double hh,
                           int lumThreshold, int dilate, int iterations, out bool[] maskOut) {
    int w = src.Width, h = src.Height;
    var bmp = src.Clone(new Rectangle(0, 0, w, h), PixelFormat.Format24bppRgb);
    var data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb);
    int stride = data.Stride;
    byte[] px = new byte[stride * h];
    Marshal.Copy(data.Scan0, px, 0, px.Length);

    bool[] mask = new bool[w * h];
    int xa = (int)(x0 * w), xb = (int)(x1 * w);
    for (int x = xa; x < xb; x++) {
      double cy = cy0 + slope * ((double)x / w - x0);
      int ya = Math.Max(0, (int)((cy - hh) * h)), yb = Math.Min(h - 1, (int)((cy + hh) * h));
      for (int y = ya; y <= yb; y++) {
        int i = y * stride + x * 3;
        int b = px[i], g = px[i + 1], r = px[i + 2];
        int lum = (r + g + b) / 3;
        int sat = Math.Max(r, Math.Max(g, b)) - Math.Min(r, Math.Min(g, b));
        if (lum >= lumThreshold && sat < 40) mask[y * w + x] = true;
      }
    }
    // Keep only bright shapes lying entirely inside the band (the letters).
    // Cup handles and the tray's bright rim extend past the band edges, so drop them.
    Func<int, int, bool> inBand = (x, y) => {
      if (x < xa || x >= xb || y < 0 || y >= h) return false;
      double cy = cy0 + slope * ((double)x / w - x0);
      return y >= (int)((cy - hh) * h) && y <= (int)((cy + hh) * h);
    };
    bool[] seen = new bool[w * h];
    var stack = new System.Collections.Generic.Stack<int>();
    var comp = new System.Collections.Generic.List<int>();
    for (int s = 0; s < w * h; s++) {
      if (!mask[s] || seen[s]) continue;
      comp.Clear(); bool touchesEdge = false;
      stack.Push(s); seen[s] = true;
      while (stack.Count > 0) {
        int k = stack.Pop(); comp.Add(k);
        int cx = k % w, cyy = k / w;
        for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
          int nx = cx + dx, ny = cyy + dy;
          if (!inBand(nx, ny)) { touchesEdge = true; continue; }
          int nk = ny * w + nx;
          if (mask[nk] && !seen[nk]) { seen[nk] = true; stack.Push(nk); }
        }
      }
      if (touchesEdge) foreach (int k in comp) mask[k] = false;
    }
    // The final "è" touches the tray's bright reflection, so the shape filter
    // skips it. Mask its near-white pixels inside a tight box instead.
    int ex0 = (int)(0.737 * w), ex1 = (int)(0.771 * w), ey0 = (int)(0.607 * h), ey1 = (int)(0.645 * h);
    for (int y = ey0; y < ey1; y++) for (int x = ex0; x < ex1; x++) {
      int i = y * stride + x * 3;
      if ((px[i] + px[i + 1] + px[i + 2]) / 3 >= 225) mask[y * w + x] = true;
    }
    // Dilate to catch anti-aliased letter edges
    for (int d = 0; d < dilate; d++) {
      bool[] m2 = (bool[])mask.Clone();
      for (int y = 1; y < h - 1; y++) for (int x = 1; x < w - 1; x++) {
        if (mask[y * w + x]) { m2[y * w + x - 1] = m2[y * w + x + 1] = m2[(y - 1) * w + x] = m2[(y + 1) * w + x] = true; }
      }
      mask = m2;
    }
    // Diffusion fill (Jacobi iterations) using only the colour channels as floats
    float[] R = new float[w * h], G = new float[w * h], B = new float[w * h];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int i = y * stride + x * 3, k = y * w + x;
      B[k] = px[i]; G[k] = px[i + 1]; R[k] = px[i + 2];
    }
    for (int it = 0; it < iterations; it++) {
      for (int y = 1; y < h - 1; y++) for (int x = 1; x < w - 1; x++) {
        int k = y * w + x;
        if (!mask[k]) continue;
        R[k] = (R[k - 1] + R[k + 1] + R[k - w] + R[k + w]) / 4f;
        G[k] = (G[k - 1] + G[k + 1] + G[k - w] + G[k + w]) / 4f;
        B[k] = (B[k - 1] + B[k + 1] + B[k - w] + B[k + w]) / 4f;
      }
    }
    // Light grain so the filled area matches the photo's texture
    var rnd = new Random(7);
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int k = y * w + x; if (!mask[k]) continue;
      int i = y * stride + x * 3; float n = (float)(rnd.NextDouble() * 3 - 1.5);
      px[i] = (byte)Math.Max(0, Math.Min(255, B[k] + n));
      px[i + 1] = (byte)Math.Max(0, Math.Min(255, G[k] + n));
      px[i + 2] = (byte)Math.Max(0, Math.Min(255, R[k] + n));
    }
    Marshal.Copy(px, 0, data.Scan0, px.Length);
    bmp.UnlockBits(data);
    maskOut = mask;
    return bmp;
  }
}
"@

$root   = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "Images"
$file   = Get-ChildItem $srcDir -Filter "690854093_9*.jpg" | Select-Object -First 1
$out    = Join-Path $srcDir "690854093_edited_no-caption.jpg"

$src = [System.Drawing.Bitmap]::FromFile($file.FullName)
$mask = $null
# Caption runs diagonally from about (0.47, 0.72) to (0.79, 0.61) of the frame
$res = [CaptionRemover]::Run($src, 0.455, 0.81, 0.722, -0.345, 0.040, 205, 3, 600, [ref]$mask)

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]95)
$res.Save($out, $jpeg, $ep)
Write-Output "Wrote $out"

if ($DebugOverlay) {
  $dbg = $src.Clone()
  for ($y = 0; $y -lt $src.Height; $y++) { for ($x = 0; $x -lt $src.Width; $x++) {
    if ($mask[$y * $src.Width + $x]) { $dbg.SetPixel($x, $y, [System.Drawing.Color]::Red) } } }
  $dbg.Save($DebugOverlay); $dbg.Dispose(); Write-Output "Mask overlay: $DebugOverlay"
}
$res.Dispose(); $src.Dispose()
