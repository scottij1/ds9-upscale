# DS9 Complete Upscale Workflow
## From Raw DVD Rip to Finished 1080p — Every Step

---

## Overview

Your files go through 4 stages:

```
RAW DVD RIP (720×480i, 29.97fps, non-square pixels)
    │
    ▼
STAGE 1: Pre-Processing (IVTC + deinterlace + square pixel conversion)
    │  ── Option A: ffmpeg (simple, good quality)
    │  ── Option B: AviSynth+ via StaxRip (harder setup, best quality)
    │
    ▼
PREPPED FILE (720×540p, 23.976fps, square pixels, lossless)
    │
    ▼
STAGE 2: AI Upscale in Topaz Video AI (Iris MQ)
    │
    ▼
UPSCALED FILE (1440×1080p, 23.976fps, video only)
    │
    ▼
STAGE 3: Mux video + original audio/subs
    │
    ▼
STAGE 4: Final encode (optional) + copy to Plex
```

---

## What You Need Installed

| Software | Purpose | Download |
|----------|---------|----------|
| **ffmpeg** | Pre-processing (Option A) or final encode | https://www.gyan.dev/ffmpeg/builds/ |
| **StaxRip** | Pre-processing (Option B) — bundles AviSynth+, QTGMC, TIVTC | https://github.com/staxrip/staxrip/releases |
| **Topaz Video AI** | AI upscaling | https://www.topazlabs.com/topaz-video |
| **MKVToolNix** | Muxing video + audio + subs | https://mkvtoolnix.download/downloads.html |

---

## STAGE 1: Pre-Processing

The goal: convert your 720×480 interlaced 29.97fps DVD rip into a
720×540 progressive 23.976fps lossless file with square pixels.

### Why this matters

DS9 was shot on 35mm film at 23.976fps. To fit NTSC DVD standards,
the studio applied a "telecine" process that interlaced the frames
and padded the framerate to 29.97fps. We need to undo this to
recover the original progressive film frames before Topaz sees them.

Additionally, DVD pixels are rectangular (non-square). We convert to
square pixels so Topaz produces a correctly proportioned output.

---

### Option A: ffmpeg (Recommended for most users)

**Pros:** Single command, no installation headaches, good quality
**Cons:** Not quite as accurate as AviSynth+ TIVTC for hybrid content

#### Install ffmpeg

1. Download **ffmpeg-release-essentials.zip** from https://www.gyan.dev/ffmpeg/builds/
2. Extract to `C:\ffmpeg`
3. Add to PATH:
   - Press Win+R → type `sysdm.cpl` → Enter
   - Advanced tab → Environment Variables
   - Under System variables, find **Path** → Edit → New
   - Type `C:\ffmpeg\bin`
   - OK → OK → OK
4. Open a new Command Prompt → type `ffmpeg -version` → should print version info

#### Process a single file

Open PowerShell (Win+R → `powershell`) and run:

```powershell
ffmpeg -hide_banner -i "E:\Video\DS9 Upscale\Star Trek Deep Space Nine - S01E01-E02 - Emissary-original.mkv" -vf "fieldmatch,yadif=deint=interlaced,decimate,scale=720:540:flags=lanczos" -c:v ffv1 -level 3 -pix_fmt yuv420p10le -an "E:\Video\DS9 Upscale\Star Trek Deep Space Nine - S01E01-E02 - Emissary-prepped.mkv"
```

What each part does:
- `fieldmatch` → Inverse telecine (matches fields to recover original frames)
- `yadif=deint=interlaced` → Catches any remaining interlaced frames fieldmatch missed
- `decimate` → Drops duplicate frames (29.97fps → 23.976fps)
- `scale=720:540:flags=lanczos` → Converts to square pixels
- `-c:v ffv1` → Lossless output codec
- `-an` → Strips audio (we mux it back later)

#### Batch process all seasons

Use the `process-ds9.ps1` script (provided separately). It processes
every MKV in every season folder and skips files already done.

---

### Option B: StaxRip + AviSynth+ (Best quality)

**Pros:** TIVTC + QTGMC is the gold standard for telecined DVD content
**Cons:** More complex setup, GUI-based (harder to batch), slower

StaxRip is a free encoding GUI that bundles AviSynth+, QTGMC, TIVTC,
and all their dependencies. This avoids the nightmare of manually
installing AviSynth+ plugins and DLLs.

#### Install StaxRip

1. Download the latest release from https://github.com/staxrip/staxrip/releases
   (get the `.7z` file, e.g. `StaxRip-v2.41.0-x64.7z`)
2. Extract to a folder like `C:\StaxRip`
3. Run `StaxRip.exe`
4. On first launch it will prompt to download required tools — let it
   download everything. This includes AviSynth+, ffmpeg, and all plugins.

#### Configure for DS9

1. **Load your file:**
   - Drag an MKV file onto the StaxRip window, or use File → Open

2. **Set the source filter:**
   - In the Filters panel (AviSynth script area), the source line
     should auto-detect. If not, right-click the Source line and select
     `FFVideoSource` or `LWLibavVideoSource`

3. **Set up IVTC (Inverse Telecine):**
   - In the Filters panel, right-click the **Field** line (or add one)
   - Select **IVTC** → **TFM + TDecimate**
   - This recovers 23.976fps progressive frames from the telecined source
   - The script should look something like:
     ```
     TFM(order=1)
     TDecimate(mode=1)
     ```

4. **Add QTGMC cleanup (optional but recommended):**
   - QTGMC catches orphaned fields and scene-cut artifacts that TIVTC misses
   - Right-click and add a filter → Deinterlace → QTGMC
   - Set Preset to **"Medium"** (good balance of speed/quality)
   - IMPORTANT: Since we already did IVTC, QTGMC should run in
     "progressive cleanup" mode. Set `InputType=3` to tell it the input
     is already progressive and it should only denoise/cleanup:
     ```
     QTGMC(Preset="Medium", InputType=3, FPSDivisor=2)
     ```

5. **Set up resize (square pixel conversion):**
   - In the Filters panel, right-click and add → Resize
   - Set to **720 × 540** using Lanczos or Spline36 resizer

6. **Your full AviSynth script should look approximately like:**
   ```avisynth
   FFVideoSource("E:\Video\Star Trek - Deep Space Nine\Season 1\episode.mkv")
   AssumeTFF()
   TFM(order=1, mode=5)
   TDecimate(mode=1)
   QTGMC(Preset="Medium", InputType=3, FPSDivisor=2)
   Spline36Resize(720, 540)
   ```

7. **Set output codec:**
   - In the encoder section, select **FFV1** for lossless output
   - If FFV1 isn't listed, select **Lossless** → **FFV1**
   - Container: **MKV**

8. **Set output location:**
   - Set the output path to your `E:\Video\DS9 Upscale\Season X` folder

9. **Process:**
   - Click the encode button (the shovel icon)
   - StaxRip will process the file through the AviSynth filter chain
     and output a lossless MKV

10. **Repeat for each episode:**
    - Once you have settings dialed in for a season, you can use
      File → Open to load the next episode — your filter settings persist
    - StaxRip also supports batch/queue processing via the job system

#### Which Option should I pick?

For this project, **Option A (ffmpeg) is recommended** unless you're
willing to invest time learning StaxRip. Here's why:

- ffmpeg's fieldmatch + yadif + decimate gets you 90-95% of the way
  there compared to TIVTC + QTGMC
- The difference is most noticeable on VFX-heavy scenes where the
  telecine pattern breaks — TIVTC handles these edge cases better
- For a dialogue-heavy show going through AI upscaling afterward,
  the difference is minimal in the final output
- ffmpeg is fully scriptable for batch processing 176 episodes;
  StaxRip requires more manual intervention per file

If you do a test episode with ffmpeg and notice combing artifacts
(horizontal lines) in the Topaz output, switch to Option B for
that season.

---

## STAGE 2: AI Upscale in Topaz Video AI

### Import

1. Open Topaz Video AI
2. Drag your prepped file(s) from `E:\Video\DS9 Upscale\Season X` into Topaz
3. In the **Import Settings** popup:
   - **Telecined**: ☐ Unchecked (you already did IVTC)
   - **Black & White**: ☐ Unchecked
   - Everything else: leave default

### Configure Enhancement

In the **Controls Sidebar** on the right:

1. **Video Type** → **Progressive**

2. **Output Resolution** → **2x Upscale**
   (This gives you 1440×1080 from your 720×540 input)

3. **AI Model** → **Iris** → **MQ** (Medium Quality)
   - Click the Iris MQ icon (white outline = selected)

4. **Advanced Tuning** → **Manual**
   - Click **Estimate** first to get baseline values
   - Then adjust:

   | Slider | Seasons 1-2 | Seasons 3-4 | Seasons 5-7 |
   |--------|-------------|-------------|-------------|
   | Fix Compression | 45-55 | 35-45 | 30-40 |
   | Recover Detail | 15-25 | 15-20 | 10-20 |
   | Reduce Noise | 15-25 | 10-20 | 5-15 |
   | Sharpen | 5-15 | 5-12 | 5-10 |
   | Dehalo | 5-10 | 0-8 | 0-5 |
   | Anti-Alias/Deblur | 10-20 (Deblur) | 8-18 (Deblur) | 8-15 (Deblur) |

5. **Add Noise** (grain):
   - Size: **2**
   - Amount: **2**
   - This adds subtle film grain to prevent the waxy/plastic AI look

6. **Recover Detail**: 15-25

7. **Focus Fix** → **Off**

### Other Filter Toggles (all OFF)

- Frame Interpolation — OFF
- SDR to HDR — OFF
- Stabilization — OFF
- Motion Deblur — OFF
- Denoise — OFF
- Grain — OFF (using Add Noise inside Enhancement instead)

### Preview

1. Scrub to different scene types and preview:
   - Bright dialogue scene (Ops, Quark's)
   - Dark scene (Defiant bridge)
   - VFX scene (wormhole, space)
   - Wide shot with background characters (Promenade)
2. Use **Split** or **Side by Side** view to compare
3. Hold left mouse button to flash back to original

**Troubleshooting:**
- Waxy skin → Lower Recover Detail, increase grain Amount
- Edge haloing → Increase Dehalo
- Striations/banding → Increase Reduce Noise + Fix Compression together
- Weird faces on background characters → Lower Recover Detail
- Oversharpened → Lower Sharpen and Deblur

### Export

1. Click **Export As**
2. Settings:
   - **Encoder**: H265 Main10 (or FFV1 if you want to do a separate final encode)
   - **Container**: MKV
   - **Bitrate**: Dynamic
3. Set output folder to: `E:\Video\DS9 Upscale\Topaz Output\Season X`
4. Export

### Batch Processing

1. Import all episodes for one season
2. Configure settings on the first episode
3. Click the three dots ⋯ → **Select All**
4. Click **Start Processing**

Expected speed on your RTX 3090: ~20-35 fps
Expected time per standard episode (~45 min): **1-2 hours**
Expected time per season (~26 episodes): **1-3 days**
Expected time for all 7 seasons: **1-2 weeks**

---

## STAGE 3: Mux Video + Audio + Subtitles

After Topaz finishes, you need to combine the upscaled video with
the original audio and subtitle tracks.

### Install MKVToolNix

1. Download from https://mkvtoolnix.download/downloads.html#windows
2. During install, check **"Add to PATH"**

### Mux a single file

```powershell
mkvmerge -o "E:\Video\DS9 Upscale\Final\Season 1\Star Trek Deep Space Nine - S01E01-E02 - Emissary.mkv" `
  --no-audio --no-subtitles "E:\Video\DS9 Upscale\Topaz Output\Season 1\Star Trek Deep Space Nine - S01E01-E02 - Emissary-prepped.mkv" `
  --no-video "E:\Video\Star Trek - Deep Space Nine\Season 1\Star Trek Deep Space Nine - S01E01-E02 - Emissary-original.mkv"
```

What this does:
- Takes **only video** from the Topaz output file
- Takes **only audio + subtitles** from the original MakeMKV rip
- Combines them into one final MKV

### Batch mux all seasons

Use the `mux-ds9.ps1` script (provided separately).

---

## STAGE 4: Final Steps

### Set correct aspect ratio (if needed)

If your media player stretches the 1440×1080 to fill 16:9, the
aspect ratio metadata may need to be set. Add this flag to your
mkvmerge command:

```
--aspect-ratio 0:4/3
```

### Copy to Plex

1. Copy final files from `E:\Video\DS9 Upscale\Final\Season X\`
   to your Plex server's DS9 folder
2. In Plex, refresh the library metadata
3. Plex should detect the 1440×1080 files and pillarbox them
   correctly on 16:9 displays

### Clean up intermediates

After confirming the final files look good on Plex, you can delete:
- The prepped files in `E:\Video\DS9 Upscale\Season X\`
- The Topaz output files in `E:\Video\DS9 Upscale\Topaz Output\Season X\`

Keep the originals on your Plex server as backup.

---

## Folder Structure

```
E:\Video\
├── Star Trek - Deep Space Nine\    ← Original MakeMKV rips
│   ├── Season 1\
│   │   ├── Star Trek Deep Space Nine - S01E01-E02 - Emissary-original.mkv
│   │   ├── Star Trek Deep Space Nine - S01E03 - Past Prologue.mkv
│   │   └── ...
│   ├── Season 2\
│   └── ...
│
└── DS9 Upscale\
    ├── Season 1\                   ← Stage 1 output (prepped, lossless)
    │   ├── Star Trek Deep Space Nine - S01E01-E02 - Emissary-prepped.mkv
    │   └── ...
    │
    ├── Topaz Output\               ← Stage 2 output (upscaled, video only)
    │   ├── Season 1\
    │   └── ...
    │
    └── Final\                      ← Stage 3 output (video + audio + subs)
        ├── Season 1\
        └── ...
```

---

## Disk Space Estimates

| Stage | Per Episode (45 min) | Per Season (26 eps) | Notes |
|-------|---------------------|--------------------|----|
| Original MKV | ~2 GB | ~52 GB | Your MakeMKV rips |
| Prepped (FFV1) | ~30-50 GB | ~800 GB - 1.3 TB | Lossless = huge |
| Topaz Output (H265) | ~3-6 GB | ~80-160 GB | Dynamic bitrate |
| Final (muxed) | ~3-6 GB | ~80-160 GB | Same as Topaz + audio |

**Working space needed at any one time:** You need room for at least
one season of prepped files + the Topaz output. Budget **~1.5 TB**
of free space on your E: drive to work comfortably one season at a time.

Process one season at a time:
1. Pre-process Season X → ~1 TB of FFV1 files
2. Feed to Topaz → ~150 GB of H265 output
3. Mux → ~150 GB of final files
4. Delete the FFV1 intermediates → reclaim ~1 TB
5. Copy finals to Plex → delete Topaz output
6. Repeat for next season

---

## Quick Reference Checklist

For each season:

- [ ] Copy raw MKVs from Plex server to `E:\Video\Star Trek - Deep Space Nine\Season X\`
- [ ] Run pre-processing (ffmpeg script or StaxRip)
- [ ] Verify prepped files: 720×540, progressive, 23.976fps
- [ ] Import prepped files into Topaz Video AI
- [ ] Set: Progressive → 2x Upscale → Iris MQ → Manual → season settings
- [ ] Preview multiple scene types — adjust if needed
- [ ] All other filters OFF (Frame Interp, SDR→HDR, Stabilization, Motion Deblur, Denoise, Grain, Focus Fix)
- [ ] Export as H265 Main10 MKV with Dynamic bitrate
- [ ] Run mux script to combine with original audio/subs
- [ ] Verify final files play correctly with audio
- [ ] Copy to Plex server
- [ ] Delete intermediate files
- [ ] Move on to next season
