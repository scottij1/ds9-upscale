# DS9 Upscale Project

AI upscale of Star Trek: Deep Space Nine from DVD (480i) to 1080p using Topaz Video AI.

## Pipeline

```
Raw DVD Rip (720×480i) → ffmpeg (IVTC + deinterlace + square pixels) → Topaz Video AI (Iris MQ 2×) → mkvmerge (add subs) → Plex
```

## Requirements

- [ffmpeg](https://www.gyan.dev/ffmpeg/builds/) — pre-processing (IVTC, deinterlace, PAR conversion)
- [Topaz Video AI](https://www.topazlabs.com/topaz-video) — AI upscaling (Iris MQ model)
- [MKVToolNix](https://mkvtoolnix.download/) — muxing subtitles into final files

All three must be installed and on your system PATH.

## Scripts

| Script | Stage | Purpose |
|--------|-------|---------|
| `process-ds9.ps1` | Pre-processing | Batch IVTC + deinterlace + square pixel conversion via ffmpeg |
| `mux-ds9.ps1` | Post-Topaz | Batch mux subtitles from original rips into Topaz output |

### Usage

1. Edit the paths at the top of each script to match your folder layout
2. Right-click → **Run with PowerShell**, or open PowerShell and run `.\process-ds9.ps1`

## Topaz Settings

| Setting | Value |
|---------|-------|
| Video Type | Progressive |
| Output Resolution | 2x Upscale (1440×1080) |
| AI Model | Iris MQ |
| Input Condition | Medium quality |
| Advanced Tuning | Manual |
| Fix Compression | 40 (adjust per season) |
| Improve Detail | 20 |
| Sharpen | 10 |
| Reduce Noise | 15 |
| Dehalo | 10 |
| Anti-alias/Deblur | 14 |
| Add Noise | 2 |
| Recover Detail | 20 |
| Focus Fix | Off |
| Grain | Off |
| All other filters | Off |

See [DS9-Complete-Upscale-Workflow.md](DS9-Complete-Upscale-Workflow.md) for the full detailed workflow and per-season tuning guide.

## Folder Structure

```
E:\Video\
├── Star Trek - Deep Space Nine\    ← Original MakeMKV rips
│   ├── Season 1\
│   ├── Season 2\
│   └── ...
└── DS9 Upscale\
    ├── Season 1\                   ← ffmpeg prepped files (lossless)
    ├── Topaz Output\               ← Topaz upscaled output
    │   ├── Season 1\
    │   └── ...
    └── Final\                      ← Muxed final files (video + audio + subs)
        ├── Season 1\
        └── ...
```

## Disk Space

Budget ~1.5 TB of working space per season. FFV1 lossless intermediates are ~30-50 GB per episode. Process one season at a time and delete intermediates when done.