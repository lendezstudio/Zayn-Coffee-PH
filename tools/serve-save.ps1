param([string]$Root, [int]$Port = 8092)
# Static file server + POST /save?name=<file> that writes the request body to $Root\out\<file>
$types = @{ ".html"="text/html; charset=utf-8"; ".js"="text/javascript"; ".png"="image/png"; ".jpg"="image/jpeg"; ".webp"="image/webp"; ".json"="application/json" }
$rootFull = [IO.Path]::GetFullPath($Root)
New-Item -ItemType Directory -Force (Join-Path $rootFull "out") | Out-Null
$l = New-Object System.Net.HttpListener; $l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
Write-Output "listening $Port"
while ($l.IsListening) {
  $ctx = $l.GetContext(); $req = $ctx.Request; $res = $ctx.Response
  try {
    if ($req.HttpMethod -eq "POST") {
      $name = [IO.Path]::GetFileName($req.QueryString["name"])
      $ms = New-Object IO.MemoryStream; $req.InputStream.CopyTo($ms)
      [IO.File]::WriteAllBytes((Join-Path $rootFull "out\$name"), $ms.ToArray())
      Write-Output "saved $name $($ms.Length)"; $b = [Text.Encoding]::UTF8.GetBytes("ok")
    } else {
      $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
      $path = Join-Path $rootFull $rel
      if (Test-Path $path -PathType Leaf) {
        $ext = [IO.Path]::GetExtension($path).ToLower()
        $res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
        $b = [IO.File]::ReadAllBytes($path)
      } else { $res.StatusCode = 404; $b = [Text.Encoding]::UTF8.GetBytes("404") }
    }
    $res.ContentLength64 = $b.Length; $res.OutputStream.Write($b, 0, $b.Length)
  } catch { $res.StatusCode = 500 } finally { $res.OutputStream.Close() }
}
