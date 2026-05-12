# upload-to-conf.ps1
# Called via confupload: custom protocol from md.htm Copy2Conf button.
# Reads a JSON packet from clipboard (written by JS), uploads localhost images
# to Confluence as page attachments, then puts the modified HTML back in clipboard.
#
# Uses System.Net.Http.HttpClient + ByteArrayContent for upload (raw bytes, no encoding)
# Uses WebClient.DownloadData for download (raw bytes, no temp file)
# Writes debug log to tmp/copy2conf-debug.log for diagnosing issues

param([string]$url)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http

function Set-HtmlClipboard([string]$htmlFragment) {
    $startHtml      = "<html><head><meta charset='utf-8'></head><body><!--StartFragment-->"
    $endHtml        = "<!--EndFragment--></body></html>"
    $headerTemplate = "Version:0.9`r`nStartHTML:{0:D10}`r`nEndHTML:{1:D10}`r`nStartFragment:{2:D10}`r`nEndFragment:{3:D10}`r`n"

    $dummyHeader  = $headerTemplate -f 0, 0, 0, 0
    $headerLen    = $dummyHeader.Length
    $startHtmlPos = $headerLen
    $startFragPos = $headerLen + $startHtml.Length
    $endFragPos   = $startFragPos + $htmlFragment.Length
    $endHtmlPos   = $endFragPos + $endHtml.Length

    $header      = $headerTemplate -f $startHtmlPos, $endHtmlPos, $startFragPos, $endFragPos
    $fullContent = $header + $startHtml + $htmlFragment + $endHtml

    [System.Windows.Forms.Clipboard]::SetText($fullContent, [System.Windows.Forms.TextDataFormat]::Html)
}

function Get-ExistingAttachments([string]$baseUrl, [string]$pageId, [hashtable]$headers) {
    # Returns hashtable: filename -> @{id, path}
    $map   = @{}
    $start = 0
    $limit = 200
    do {
        try {
            $uri   = "$baseUrl/wiki/rest/api/content/$pageId/child/attachment?limit=$limit&start=$start&expand=_links"
            $resp  = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            foreach ($att in $resp.results) {
                $map[$att.title] = @{ id = $att.id; path = $att._links.download }
            }
            $count = $resp.results.Count
        } catch {
            Write-Warning "Could not fetch existing attachments: $_"
            break
        }
        $start += $limit
    } while ($count -eq $limit)
    return $map
}

function Get-MimeType([string]$filename) {
    switch ([System.IO.Path]::GetExtension($filename).ToLower()) {
        ".jpg"  { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".gif"  { return "image/gif"  }
        ".webp" { return "image/webp" }
        default { return "image/png"  }
    }
}

function Upload-ImageToConf([string]$srcUrl, [string]$baseUrl, [string]$pageId, [string]$authHeader, [hashtable]$existingMap) {
    # Derive filename from URL
    $decoded  = [System.Uri]::UnescapeDataString($srcUrl)
    $filename = [System.IO.Path]::GetFileName(([System.Uri]$decoded).LocalPath)
    if ([string]::IsNullOrWhiteSpace($filename)) { $filename = "image.png" }

    # Download image as raw bytes — no temp file, no encoding conversion
    try {
        $imgBytes = (New-Object System.Net.WebClient).DownloadData($srcUrl)
    } catch {
        Add-Content $script:logFile "[FAIL-DL] $filename from $srcUrl : $_"
        return $null
    }

    # Log download result — first 8 bytes let us verify PNG/JPG magic bytes
    $first8  = ($imgBytes[0..7] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    $isPng   = ($imgBytes.Length -ge 4 -and $imgBytes[0] -eq 0x89 -and $imgBytes[1] -eq 0x50)
    $isJpeg  = ($imgBytes.Length -ge 2 -and $imgBytes[0] -eq 0xFF -and $imgBytes[1] -eq 0xD8)
    Add-Content $script:logFile "[DL] $filename : $($imgBytes.Length) bytes | first8=[$first8] | PNG=$isPng JPEG=$isJpeg"

    $mime = Get-MimeType $filename

    # Update existing attachment OR create new one.
    # Do NOT delete existing attachments — that breaks any Confluence page
    # that was previously pasted with those attachment URLs (they'd become 404).
    $existing = $existingMap[$filename]
    if ($existing) {
        $endpointUrl = "$baseUrl/wiki/rest/api/content/$pageId/child/attachment/$($existing.id)/data"
    } else {
        $endpointUrl = "$baseUrl/wiki/rest/api/content/$pageId/child/attachment"
    }

    try {
        # Build multipart/form-data body as raw bytes using MemoryStream.
        # ByteArrayContent (below) sends it as-is without any encoding.
        $boundary = [System.Guid]::NewGuid().ToString('N')

        $fileHeader = [System.Text.Encoding]::ASCII.GetBytes(
            "--$boundary`r`n" +
            "Content-Disposition: form-data; name=`"file`"; filename=`"$filename`"`r`n" +
            "Content-Type: $mime`r`n`r`n")

        $minorEditPart = [System.Text.Encoding]::ASCII.GetBytes(
            "`r`n--$boundary`r`n" +
            "Content-Disposition: form-data; name=`"minorEdit`"`r`n`r`n" +
            "true`r`n--$boundary--`r`n")

        $ms = New-Object System.IO.MemoryStream
        $ms.Write($fileHeader,    0, $fileHeader.Length)
        $ms.Write($imgBytes,      0, $imgBytes.Length)
        $ms.Write($minorEditPart, 0, $minorEditPart.Length)
        $bodyBytes = $ms.ToArray()
        $ms.Dispose()

        Add-Content $script:logFile "[UP] $filename : body=$($bodyBytes.Length) bytes -> $endpointUrl"

        # HttpClient + ByteArrayContent: sends raw bytes with zero encoding overhead.
        # This is the only PS approach guaranteed not to corrupt binary content.
        $content = New-Object System.Net.Http.ByteArrayContent -ArgumentList (, $bodyBytes)
        $content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse(
            "multipart/form-data; boundary=$boundary")

        $resp     = $script:httpClient.PostAsync($endpointUrl, $content).Result
        $respBody = $resp.Content.ReadAsStringAsync().Result
        Add-Content $script:logFile "[RESP] $filename : HTTP $([int]$resp.StatusCode) | $respBody"

        $json         = $respBody | ConvertFrom-Json
        # Update response: top-level _links.download
        # Create response: results[0]._links.download
        $downloadPath = if ($existing) {
            $json._links.download
        } else {
            if ($json.results -and $json.results.Count -gt 0) { $json.results[0]._links.download } else { $null }
        }

        if ($downloadPath) {
            Add-Content $script:logFile "[OK] $filename -> $downloadPath"
            return @{ path = $downloadPath; updated = ($existing -ne $null) }
        } else {
            Add-Content $script:logFile "[FAIL-RESP] $filename : no download path in response"
            return $null
        }
    } catch {
        Add-Content $script:logFile "[ERROR] $filename : $_"
        return $null
    }
}

# ── Read JSON packet from clipboard ──────────────────────────────────────────
$packet = [System.Windows.Forms.Clipboard]::GetText()

try {
    $data = $packet | ConvertFrom-Json
    if (-not $data.settings -or -not $data.html) { throw "Missing fields" }
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not read settings from clipboard.`nPlease click Copy2Conf again.",
        "Copy2Conf Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

$settings   = $data.settings
$html       = $data.html
$authHeader = 'Basic ' + [Convert]::ToBase64String(
    [System.Text.Encoding]::ASCII.GetBytes("$($settings.email):$($settings.apiToken)"))
$apiHeaders = @{ 'Authorization' = $authHeader }

# ── Pre-fetch existing attachments (to update them, not create duplicates) ────
$existingMap = Get-ExistingAttachments $settings.baseUrl $settings.pageId $apiHeaders

# ── Setup tmp dir, progress status file, and debug log ───────────────────────
$mdRoot     = Split-Path $PSScriptRoot -Parent
$tmpDir     = Join-Path $mdRoot "tmp"
$statusFile = Join-Path $tmpDir "copy2conf-status.json"
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir | Out-Null }

$script:logFile = Join-Path $tmpDir "copy2conf-debug.log"
Set-Content -Path $script:logFile -Value "=== Copy2Conf $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -Encoding UTF8
Add-Content  $script:logFile "BaseUrl=$($settings.baseUrl)  PageId=$($settings.pageId)"

# Shared HttpClient — auth headers set once; ByteArrayContent sends raw bytes
$script:httpClient = New-Object System.Net.Http.HttpClient
$script:httpClient.DefaultRequestHeaders.Add('Authorization',     $authHeader)
$script:httpClient.DefaultRequestHeaders.Add('X-Atlassian-Token', 'no-check')

# ── Find and replace localhost image URLs ─────────────────────────────────────
$pattern    = '(?i)src="(https?://(?:127\.0\.0\.1|localhost)[^"]+)"'
$imgMatches = [regex]::Matches($html, $pattern)

$created = 0
$updated = 0
$failed  = 0
$total   = $imgMatches.Count
$done    = 0
Set-Content -Path $statusFile -Value (ConvertTo-Json @{ done = 0; total = $total; complete = $false }) -Encoding UTF8

foreach ($m in $imgMatches) {
    $srcUrl = $m.Groups[1].Value
    $result = Upload-ImageToConf $srcUrl $settings.baseUrl $settings.pageId $authHeader $existingMap
    if ($result) {
        $newSrc = "$($settings.baseUrl)$($result.path)"   # full versioned URL; api=v2 is required by Confluence Cloud
        Add-Content $script:logFile "[SRC] $([System.IO.Path]::GetFileName($srcUrl)) -> $newSrc"
        $html   = $html.Replace($srcUrl, $newSrc)
        if ($result.updated) { $updated++ } else { $created++ }
    } else {
        $failed++
    }
    $done++
    Set-Content -Path $statusFile -Value (ConvertTo-Json @{ done = $done; total = $total; complete = $false }) -Encoding UTF8
}

# ── Mark upload complete so JS can dismiss the progress toast ─────────────────
Set-Content -Path $statusFile -Value (ConvertTo-Json @{ done = $done; total = $total; complete = $true }) -Encoding UTF8

# ── Cleanup ───────────────────────────────────────────────────────────────────
$script:httpClient.Dispose()
Add-Content $script:logFile "Done: created=$created updated=$updated failed=$failed"

# ── Put modified HTML in clipboard ────────────────────────────────────────────
Set-HtmlClipboard $html

# ── Notify user ───────────────────────────────────────────────────────────────
$parts = @()
if ($created -gt 0) { $parts += "$created new" }
if ($updated -gt 0) { $parts += "$updated updated" }
if ($failed  -gt 0) { $parts += "$failed failed (kept as localhost)" }

$summary = if ($parts.Count -gt 0) { $parts -join ", " } else { "no images found" }
$icon    = if ($failed -gt 0) { [System.Windows.Forms.MessageBoxIcon]::Warning } `
           else { [System.Windows.Forms.MessageBoxIcon]::Information }

[System.Windows.Forms.MessageBox]::Show(
    "Ready to paste!`n`n$summary.",
    "Copy2Conf",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    $icon)
