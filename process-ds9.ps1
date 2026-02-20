# DS9 Pre-Processing Script for Topaz Video AI
# =============================================
# This script runs ffmpeg on all MKV files in each season folder to:
#   1. Inverse telecine (recover 23.976fps from 29.97fps)
#   2. Deinterlace any remaining interlaced frames
#   3. Convert to square pixels (720x540)
#   4. Output as lossless FFV1 for maximum Topaz input quality
#
# USAGE:
#   1. Edit the two paths below
#   2. Right-click this file → "Run with PowerShell"
#      OR open PowerShell and run: .\process-ds9.ps1

# ============ EDIT THESE TWO PATHS ============

$InputRoot  = "E:\Video\Star Trek - Deep Space Nine"
$OutputRoot = "E:\Video\DS9 Upscale"

# ===============================================

# Check ffmpeg is available
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: ffmpeg not found!" -ForegroundColor Red
    Write-Host "Make sure ffmpeg is installed and added to your PATH." -ForegroundColor Red
    Write-Host "Download from: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check input folder exists
if (-not (Test-Path $InputRoot)) {
    Write-Host ""
    Write-Host "ERROR: Input folder not found: $InputRoot" -ForegroundColor Red
    Write-Host "Edit the `$InputRoot variable at the top of this script." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Find all season folders
$seasonFolders = Get-ChildItem -Path $InputRoot -Directory | Sort-Object Name

if ($seasonFolders.Count -eq 0) {
    Write-Host ""
    Write-Host "ERROR: No subfolders found in $InputRoot" -ForegroundColor Red
    Write-Host "Expected folders like 'Season 1', 'Season 2', etc." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DS9 Pre-Processing for Topaz Video AI" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Input:  $InputRoot"
Write-Host "Output: $OutputRoot"
Write-Host "Seasons found: $($seasonFolders.Count)"
Write-Host ""

# Counters
$totalFiles = 0
$processedFiles = 0
$skippedFiles = 0
$failedFiles = 0
$startTime = Get-Date

foreach ($season in $seasonFolders) {
    $seasonInput  = $season.FullName
    $seasonOutput = Join-Path $OutputRoot $season.Name

    # Create output season folder
    if (-not (Test-Path $seasonOutput)) {
        New-Item -Path $seasonOutput -ItemType Directory -Force | Out-Null
    }

    # Find all MKV files in this season
    $mkvFiles = Get-ChildItem -Path $seasonInput -Filter "*.mkv" | Sort-Object Name

    if ($mkvFiles.Count -eq 0) {
        Write-Host "[$($season.Name)] No MKV files found, skipping." -ForegroundColor Yellow
        continue
    }

    Write-Host ""
    Write-Host "────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "  $($season.Name) — $($mkvFiles.Count) episodes" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────" -ForegroundColor Cyan

    foreach ($mkv in $mkvFiles) {
        $totalFiles++
        $inputFile  = $mkv.FullName
        $outputFile = Join-Path $seasonOutput $mkv.Name

        # Skip if already processed
        if (Test-Path $outputFile) {
            Write-Host "  SKIP: $($mkv.Name) (already exists)" -ForegroundColor DarkGray
            $skippedFiles++
            continue
        }

        Write-Host ""
        Write-Host "  Processing: $($mkv.Name)" -ForegroundColor White
        Write-Host "  Started:    $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGray

        $episodeStart = Get-Date

        # Run ffmpeg
        #   fieldmatch    → inverse telecine (matches fields to recover progressive frames)
        #   yadif         → deinterlace any remaining interlaced frames that fieldmatch missed
        #   decimate      → drop duplicate frames from telecine pattern (29.97 → 23.976 fps)
        #   scale         → convert non-square DVD pixels to square pixels at 720x540
        #   ffv1          → lossless codec so Topaz gets the cleanest possible input
        #   -c:a copy     → copies audio stream as-is to keep sync after IVTC

        & ffmpeg -hide_banner -loglevel warning -stats `
            -i $inputFile `
            -vf "fieldmatch,yadif=deint=interlaced,decimate,scale=720:540:flags=lanczos" `
            -c:v ffv1 -level 3 -pix_fmt yuv420p10le `
            -c:a copy `
            $outputFile

        if ($LASTEXITCODE -eq 0) {
            $elapsed = (Get-Date) - $episodeStart
            $processedFiles++
            Write-Host "  Done in $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
        } else {
            $failedFiles++
            Write-Host "  FAILED! Check the file manually." -ForegroundColor Red
        }
    }
}

# Summary
$totalElapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Processed: $processedFiles" -ForegroundColor Green
Write-Host "  Skipped:   $skippedFiles" -ForegroundColor DarkGray
Write-Host "  Failed:    $failedFiles" -ForegroundColor $(if ($failedFiles -gt 0) { "Red" } else { "Green" })
Write-Host "  Total time: $($totalElapsed.ToString('hh\:mm\:ss'))"
Write-Host ""
Write-Host "  Output location: $OutputRoot" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Open Topaz Video AI" -ForegroundColor White
Write-Host "    2. Import files from $OutputRoot" -ForegroundColor White
Write-Host "    3. Set Video Type → Progressive" -ForegroundColor White
Write-Host "    4. Set Output Resolution → 2x Upscale (gives 1440x1080)" -ForegroundColor White
Write-Host "    5. Pick your AI model (Iris MQ or Starlight Mini)" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"