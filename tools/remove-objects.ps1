<#
  Zayn Coffee PH - remove small stray objects from a client photo (diffusion fill from surroundings).
  Writes an edited copy next to the original; the original is never modified.
  Currently: IMG_3578 (Metal details) - white box and white object on the floor, bottom-right.
  Usage: powershell -ExecutionPolicy Bypass -File tools/remove-objects.ps1
#>
Add-Type -AssemblyName System.Drawing, PresentationCore, WindowsBase
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Inpaint {
  // rects: [x0,y0,x1,y1] fractions; pixels brighter than lumMin inside them are filled from neighbours
  public static void Run(Bitmap bmp, double[][] rects, int lumMin, int dilate, int iterations) {
    int w = bmp.Width, h = bmp.Height;
    var d = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb);
    int st = d.Stride; byte[] p = new byte[st * h]; Marshal.Copy(d.Scan0, p, 0, p.Length);
    bool[] m = new bool[w * h];
    foreach (var r in rects) {
      int x0 = (int)(r[0] * w), y0 = (int)(r[1] * h), x1 = Math.Min(w, (int)(r[2] * w)), y1 = Math.Min(h, (int)(r[3] * h));
      for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) {
        int i = y * st + x * 3; if ((p[i] + p[i + 1] + p[i + 2]) / 3 >= lumMin) m[y * w + x] = true; }
    }
    for (int k = 0; k < dilate; k++) { var m2 = (bool[])m.Clone();
      for (int y = 1; y < h - 1; y++) for (int x = 1; x < w - 1; x++) if (m[y * w + x]) { m2[y*w+x-1]=m2[y*w+x+1]=m2[(y-1)*w+x]=m2[(y+1)*w+x]=true; }
      m = m2; }
    // Seed each masked pixel by mirroring the floor just to the LEFT of the masked run in its row
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { if (!m[y*w+x]) continue;
      int left = x; while (left > 0 && m[y*w+left-1]) left--;
      int src = left - 1 - (x - left); if (src < 0) src = 0;   // pixels to the left are already seeded
      int i = y*st+x*3, j = y*st+src*3; p[i]=p[j]; p[i+1]=p[j+1]; p[i+2]=p[j+2]; }
    float[] R = new float[w*h], G = new float[w*h], B = new float[w*h];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { int i = y*st+x*3, k = y*w+x; B[k]=p[i]; G[k]=p[i+1]; R[k]=p[i+2]; }
    // Light smoothing only on the mask border so seams disappear but texture stays
    bool[] edge = new bool[w*h];
    for (int y = 1; y < h-1; y++) for (int x = 1; x < w-1; x++) { int k=y*w+x; if (m[k] && (!m[k-1]||!m[k+1]||!m[k-w]||!m[k+w])) edge[k]=true; }
    // feather: widen the smoothing band to ~10px around the patch border
    for (int k2 = 0; k2 < 4; k2++) { var e2 = (bool[])edge.Clone();
      for (int y = 1; y < h-1; y++) for (int x = 1; x < w-1; x++) if (edge[y*w+x]) { e2[y*w+x-1]=e2[y*w+x+1]=e2[(y-1)*w+x]=e2[(y+1)*w+x]=true; }
      edge = e2; }
    m = edge;
    for (int it = 0; it < iterations; it++)
      for (int y = 1; y < h - 1; y++) for (int x = 1; x < w - 1; x++) { int k = y*w+x; if (!m[k]) continue;
        R[k]=(R[k-1]+R[k+1]+R[k-w]+R[k+w])/4f; G[k]=(G[k-1]+G[k+1]+G[k-w]+G[k+w])/4f; B[k]=(B[k-1]+B[k+1]+B[k-w]+B[k+w])/4f; }
    // bottom/right edge rows: copy from the row/column inside
    for (int x = 0; x < w; x++) { int k = (h-1)*w+x; if (m[k]) { R[k]=R[k-w]; G[k]=G[k-w]; B[k]=B[k-w]; } }
    for (int y = 0; y < h; y++) { int k = y*w+w-1; if (m[k]) { R[k]=R[k-1]; G[k]=G[k-1]; B[k]=B[k-1]; } }
    var rnd = new Random(3);
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { int k = y*w+x; if (!m[k]) continue; int i = y*st+x*3;
      float n = (float)(rnd.NextDouble()*7-3.5);
      p[i]=(byte)Math.Max(0,Math.Min(255,B[k]+n)); p[i+1]=(byte)Math.Max(0,Math.Min(255,G[k]+n)); p[i+2]=(byte)Math.Max(0,Math.Min(255,R[k]+n)); }
    Marshal.Copy(p, 0, d.Scan0, p.Length); bmp.UnlockBits(d);
  }
}
"@

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "Images from Client\IMG_3578.HEIC"
$out = Join-Path $root "Images from Client\IMG_3578_edited_no-box.jpg"

# Decode HEIC at 1600px wide (plenty for the website)
$bi = New-Object System.Windows.Media.Imaging.BitmapImage
$bi.BeginInit(); $bi.UriSource = New-Object Uri($src); $bi.DecodePixelWidth = 1600; $bi.CacheOption = 'OnLoad'; $bi.EndInit()
$enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder; $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bi))
$ms = New-Object IO.MemoryStream; $enc.Save($ms); $ms.Position = 0
$tmp = [System.Drawing.Bitmap]::FromStream($ms)
$bmp = $tmp.Clone((New-Object System.Drawing.Rectangle 0, 0, $tmp.Width, $tmp.Height), [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

$rects = [double[][]]@(
  [double[]]@(0.845, 0.875, 1.0, 1.0),   # white box, bottom-right
  [double[]]@(0.655, 0.960, 0.735, 1.0)  # white object, bottom edge
)
[Inpaint]::Run($bmp, $rects, 0, 2, 30)

$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]95)
$bmp.Save($out, $jpeg, $ep); Write-Output "Wrote $out ($($bmp.Width)x$($bmp.Height))"
$bmp.Dispose(); $tmp.Dispose()
