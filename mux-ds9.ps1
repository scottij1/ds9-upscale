# DS9 Post-Topaz Muxing Script
# ==============================
# After Topaz finishes upscaling, this script reunites the upscaled video
# with the original audio and subtitle tracks from your MakeMKV rips.
#
# REQUIRES: mkvtoolnix installed and in PATH
#   Download from: https://mkvtoolnix.download/downloads.html#windows
#   During install, check "Add to PATH"
#
# USAGE:
#   1. Edit the three paths below
#   2. Right-click this file → "Run with PowerShell"

# ============ EDIT THESE THREE PATHS ============

$OriginalRoot = "E:\Video\Star Trek - Deep Space Nine"
$TopazRoot    = "E:\Video\DS9 Upscale\Topaz Output"   # Point this to wherever Topaz saves its files
$FinalRoot    = "E:\Video\DS9 Upscale\Final"

# ================================================

# Check mkvmerge is available
if (-not (Get-Command mkvmerge -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: mkvmerge not found!" -ForegroundColor Red
    Write-Host "Install MKVToolNix from: https://mkvtoolnix.download/downloads.html#windows" -ForegroundColor Yellow
    Write-Host "Make sure 'Add to PATH' is checked during installation." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DS9 Post-Topaz Muxing" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$seasonFolders = Get-ChildItem -Path $TopazRoot -Directory | Sort-Object Name
$processedFiles = 0
$failedFiles = 0

foreach ($season in $seasonFolders) {
    $topazSeason    = $season.FullName
    $originalSeason = Join-Path $OriginalRoot $season.Name
    $finalSeason    = Join-Path $FinalRoot $season.Name

    if (-not (Test-Path $finalSeason)) {
        New-Item -Path $finalSeason -ItemType Directory -Force | Out-Null
    }

    $topazFiles = Get-ChildItem -Path $topazSeason -Filter "*.mkv" | Sort-Object Name

    Write-Host ""
    Write-Host "────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "  $($season.Name) — $($topazFiles.Count) episodes" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────" -ForegroundColor Cyan

    foreach ($topazFile in $topazFiles) {
        $baseName = $topazFile.Name

        # Find matching original file
        $originalFile = Join-Path $originalSeason $baseName

        if (-not (Test-Path $originalFile)) {
            # Try to match by similar name if Topaz appended something
            $candidates = Get-ChildItem -Path $originalSeason -Filter "*.mkv" |
                Where-Object { $topazFile.BaseName -like "*$($_.BaseName)*" -or $_.BaseName -like "*$($topazFile.BaseName)*" }

            if ($candidates.Count -eq 1) {
                $originalFile = $candidates[0].FullName
            } else {
                Write-Host "  SKIP: $baseName — no matching original found" -ForegroundColor Yellow
                $failedFiles++
                continue
            }
        }

        $finalFile = Join-Path $finalSeason $baseName

        if (Test-Path $finalFile) {
            Write-Host "  SKIP: $baseName (already exists)" -ForegroundColor DarkGray
            continue
        }

        Write-Host "  Muxing: $baseName" -ForegroundColor White

        # Mux: video+audio from Topaz + subs from original
        #   Audio is already synced in the Topaz file (kept through ffmpeg prep)
        #   We only need subtitles from the original
        & mkvmerge -o $finalFile `
            $topazFile.FullName `
            --no-video --no-audio $originalFile

        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
            # mkvmerge returns 1 for warnings (still successful)
            $processedFiles++
            Write-Host "  Done" -ForegroundColor Green
        } else {
            $failedFiles++
            Write-Host "  FAILED!" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Muxed:  $processedFiles" -ForegroundColor Green
Write-Host "  Failed: $failedFiles" -ForegroundColor $(if ($failedFiles -gt 0) { "Red" } else { "Green" })
Write-Host ""
Write-Host "  Final files: $FinalRoot" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"