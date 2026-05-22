# Palm Springs Paradise — PC Transfer Kit audit + optional ingest
# Run in Cursor → PowerShell from repo root:
#   powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1
# With ingest:
#   powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1 -Apply

param(
    [string]$SourcePath = "D:\PC_Transfer_Kit\PalmSpringsParadise\Users\karl\palm-springs-paradise",
    [switch]$Apply,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root

$ManifestDir = Join-Path $Root "vendor-imports\_manifests"
$IncomingRoot = Join-Path $Root "vendor-imports\_incoming"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$PackDate = Get-Date -Format "yyyy-MM-dd"
$PackSlug = "${PackDate}_pc-transfer-karl"

# Extension → taxonomy folder (relative to vendor-imports/)
$CategoryMap = @{
    ".fbx"  = "furniture/decor"
    ".blend" = "furniture/decor"
    ".obj"  = "furniture/decor"
    ".mesh" = "furniture/decor"
    ".gltf" = "furniture/decor"
    ".glb"  = "furniture/decor"
    ".png"  = "textures/world"
    ".jpg"  = "textures/world"
    ".jpeg" = "textures/world"
    ".webp" = "textures/world"
    ".mp3"  = "audio/ambience"
    ".ogg"  = "audio/ambience"
    ".wav"  = "audio/ambience"
    ".rbxm" = "furniture/decor"
    ".rbxl" = "places"
    ".rbxlx" = "places"
    ".lua"  = "legacy-scripts/do-not-ship"
    ".luau" = "legacy-scripts/do-not-ship"
}

# Path keyword overrides (first match wins)
$PathHints = @(
    @{ Pattern = "kaufmann"; Category = "architecture/residential/kaufmann" },
    @{ Pattern = "frey"; Category = "architecture/residential/frey" },
    @{ Pattern = "wexler"; Category = "architecture/residential/wexler" },
    @{ Pattern = "neutra"; Category = "architecture/residential/neutra" },
    @{ Pattern = "el-paseo|elpaseo|storefront"; Category = "architecture/commercial/el-paseo-storefront" },
    @{ Pattern = "garden|plant|cactus|succulent|palm"; Category = "plants/cacti" },
    @{ Pattern = "fashion|runway|outfit"; Category = "fashion/runway-props" },
    @{ Pattern = "boutique|shop"; Category = "boutique/apparel" },
    @{ Pattern = "audio|sound|music|sfx"; Category = "audio/ambience" },
    @{ Pattern = "texture|material"; Category = "textures/world" },
    @{ Pattern = "ui|hud|icon"; Category = "ui/hud" },
    @{ Pattern = "anim"; Category = "animations/emotes" },
    @{ Pattern = "furniture|chair|table|lounge|eames"; Category = "furniture/seating" }
)

function Get-SuggestedCategory {
    param([string]$RelativePath, [string]$Extension)
    $lower = $RelativePath.ToLowerInvariant()
    foreach ($hint in $PathHints) {
        if ($lower -match $hint.Pattern) { return $hint.Category }
    }
    if ($CategoryMap.ContainsKey($Extension)) {
        return $CategoryMap[$Extension]
    }
    return "_incoming/$PackSlug/uncategorized"
}

function Get-SuggestedSlug {
    param([string]$FileName)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $slug = $base.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
    $slug = $slug.Trim('_')
    if ($slug.Length -gt 48) { $slug = $slug.Substring(0, 48) }
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = "asset_$([guid]::NewGuid().ToString('N').Substring(0,8))" }
    return $slug
}

Write-Host "=== PC Transfer Kit Audit ===" -ForegroundColor Cyan
Write-Host "Repo:   $Root"
Write-Host "Source: $SourcePath"

if (-not (Test-Path $SourcePath)) {
    Write-Host ""
    Write-Host "ERROR: Source path not found." -ForegroundColor Red
    Write-Host "Expected (from KRLX Transfer screenshot):" -ForegroundColor Yellow
    Write-Host "  D:\PC_Transfer_Kit\PalmSpringsParadise\Users\karl\palm-springs-paradise"
    Write-Host ""
    Write-Host "Pass your actual path:" -ForegroundColor Yellow
    Write-Host '  -SourcePath "D:\PC_Transfer_Kit\...\palm-springs-paradise"'
    exit 1
}

$files = Get-ChildItem -Path $SourcePath -Recurse -File -ErrorAction SilentlyContinue
if (-not $files -or $files.Count -eq 0) {
    Write-Host "WARN: No files found under source (empty folder?)" -ForegroundColor Yellow
}

$entries = @()
$byExt = @{}
$byCategory = @{}
$warnings = [System.Collections.Generic.List[string]]::new()
$totalBytes = 0

foreach ($f in $files) {
    $rel = $f.FullName.Substring($SourcePath.Length).TrimStart('\', '/')
    $ext = $f.Extension.ToLowerInvariant()
    $cat = Get-SuggestedCategory -RelativePath $rel -Extension $ext
    $slug = Get-SuggestedSlug -FileName $f.Name

    if (-not $byExt.ContainsKey($ext)) { $byExt[$ext] = 0 }
    $byExt[$ext]++
    if (-not $byCategory.ContainsKey($cat)) { $byCategory[$cat] = 0 }
    $byCategory[$cat]++

    $flags = @()
    if ($ext -in ".lua", ".luau") {
        $flags += "LEGACY_LUA_REFERENCE_ONLY"
        $warnings.Add("Legacy Lua (do not ship): $rel")
    }
    if ($f.Length -gt 50MB) {
        $flags += "LARGE_FILE"
        $warnings.Add("Large file (>50MB): $rel ($([math]::Round($f.Length/1MB, 1)) MB)")
    }
    if ($rel -match '(?i)node_modules|\.git\\|__MACOSX|Thumbs\.db') {
        $flags += "SKIP_RECOMMENDED"
    }

    $totalBytes += $f.Length
    $entries += [ordered]@{
        relativePath = $rel
        sizeBytes = $f.Length
        extension = $ext
        suggestedCategory = $cat
        suggestedSlug = $slug
        flags = $flags
    }
}

$report = [ordered]@{
    auditedAt = $Timestamp
    sourcePath = $SourcePath
    repoRoot = $Root
    packSlug = $PackSlug
    summary = [ordered]@{
        fileCount = $entries.Count
        totalBytes = $totalBytes
        totalMegabytes = [math]::Round($totalBytes / 1MB, 2)
        byExtension = $byExt
        byCategory = $byCategory
        warningCount = $warnings.Count
    }
    warnings = $warnings
    files = $entries
}

if (-not (Test-Path $ManifestDir)) { New-Item -ItemType Directory -Path $ManifestDir -Force | Out-Null }

$jsonPath = Join-Path $ManifestDir "pc-transfer-audit.json"
$mdPath = Join-Path $ManifestDir "pc-transfer-audit.md"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$md = @(
    "# PC Transfer Kit Audit",
    "",
    "| Field | Value |",
    "|-------|-------|",
    "| Audited | $Timestamp |",
    "| Source | ``$SourcePath`` |",
    "| Files | $($entries.Count) |",
    "| Size | $([math]::Round($totalBytes/1MB, 2)) MB |",
    "| Warnings | $($warnings.Count) |",
    "",
    "## By category",
    ""
)
foreach ($kv in ($byCategory.GetEnumerator() | Sort-Object Name)) {
    $md += "- ``$($kv.Name)``: $($kv.Value)"
}
$md += "", "## Top warnings", ""
if ($warnings.Count -eq 0) { $md += "_None_" } else {
    foreach ($w in $warnings | Select-Object -First 25) { $md += "- $w" }
    if ($warnings.Count -gt 25) { $md += "- ... and $($warnings.Count - 25) more (see JSON)" }
}
$md += "", "## Next steps", ""
$md += "1. Review ``pc-transfer-audit.json``"
$md += "2. Run with ``-Apply`` to copy into ``vendor-imports/_incoming/$PackSlug/``"
$md += "3. Manus updates ``asset-index.yaml`` after Roblox upload"
$md += "4. Karl approves ``AssetRegistry`` merge per ``docs/karlux/03-vertical-slice-merge-guide.md``"
$md | Set-Content -Path $mdPath -Encoding UTF8

Write-Host ""
Write-Host "Files:    $($entries.Count)"
Write-Host "Size:     $([math]::Round($totalBytes/1MB, 2)) MB"
Write-Host "Warnings: $($warnings.Count)"
Write-Host "Report:   $jsonPath"
Write-Host "Summary:  $mdPath"

# Append import log line
$logPath = Join-Path $ManifestDir "import-log.jsonl"
$logLine = @{
    at = $Timestamp
    actor = $env:USERNAME
    action = if ($Apply) { "audit_and_apply" } else { "audit_only" }
    sourcePath = $SourcePath
    fileCount = $entries.Count
    packSlug = $PackSlug
} | ConvertTo-Json -Compress
Add-Content -Path $logPath -Value $logLine -Encoding UTF8

if ($Apply) {
    $destIncoming = Join-Path $IncomingRoot $PackSlug
    New-Item -ItemType Directory -Path $destIncoming -Force | Out-Null
    $copied = 0
    foreach ($e in $entries) {
        if ($e.flags -contains "SKIP_RECOMMENDED") { continue }
        $srcFile = Join-Path $SourcePath $e.relativePath
        if ($e.suggestedCategory -like "_incoming/*") {
            $destDir = Join-Path $destIncoming "uncategorized"
        } else {
            $destDir = Join-Path $Root (Join-Path "vendor-imports" ($e.suggestedCategory -replace '/', '\'))
        }
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $destName = "$($e.suggestedCategory -replace '/','__')__$($e.suggestedSlug)__$([System.IO.Path]::GetFileName($srcFile))"
        if ($destName.Length -gt 200) {
            $destName = [System.IO.Path]::GetFileName($srcFile)
        }
        $destFile = Join-Path $destDir $destName
        if ($DryRun) {
            Write-Host "DRY-RUN copy: $srcFile -> $destFile"
        } else {
            Copy-Item -Path $srcFile -Destination $destFile -Force
        }
        $copied++
    }
    Write-Host ""
    Write-Host "Applied: $copied files staged under vendor-imports/" -ForegroundColor Green
    Write-Host "Incoming pack: vendor-imports\_incoming\$PackSlug" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Audit only. To copy assets into repo:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1 -Apply"
}

Write-Host "=== Audit complete ===" -ForegroundColor Green
