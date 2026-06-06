---
name: "ffmpeg"
description: "Use when a task involves FFmpeg or ffprobe: converting, extracting, transcoding, trimming, merging, remuxing, compressing, streaming, recording, filtering, repairing, inspecting, or batch-processing audio/video/subtitle/media files."
---

# FFmpeg Skill

## When to Use

Use this skill for media work that should be done with `ffmpeg` or `ffprobe`, including:

- Convert audio or video formats.
- Extract audio, frames, subtitles, metadata, chapters, thumbnails, or streams.
- Trim, concatenate, crop, scale, rotate, overlay, watermark, normalize, denoise, stabilize, or filter media.
- Re-encode, remux, compress, repair, stream, record devices, create HLS/DASH outputs, or prepare web/mobile/social exports.
- Batch process local media files.

For task-specific command templates, read `references/cookbook.md`.

## Core Workflow

1. Inspect the input before writing commands:
   - `ffprobe -hide_banner -i "$INPUT"`
   - For structured data: `ffprobe -v error -show_format -show_streams -of json "$INPUT"`
2. Decide whether the task needs stream copy, remuxing, or re-encoding:
   - Use `-c copy` when only the container or stream selection changes and codecs are already compatible.
   - Re-encode when changing codec, dimensions, frame rate, bitrate, filters, loudness, sample rate, or pixel format.
3. Put input options before `-i` and output options before the output path.
4. Quote paths and protect existing files:
   - Prefer `-n` unless the user explicitly wants overwrite.
   - Use `-y` only when replacing outputs is intended.
5. Verify the result:
   - `ffprobe -v error -show_format -show_streams -of json "$OUTPUT"`
   - For visual edits, generate a short preview or thumbnails before full processing.

## Common Decision Rules

- MP4 video for broad compatibility: H.264 video + AAC audio + `-movflags +faststart`.
- WebM: VP9/AV1 video + Opus audio.
- Audio extraction to MP3: `-vn -codec:a libmp3lame -q:a 2`.
- Lossless audio extraction when source already has AAC/M4A and the target supports it: use `-vn -c:a copy`.
- Preserve quality during resize/filtering by using CRF-based encoding instead of fixed bitrate unless a platform requires bitrate.
- Avoid generational loss: do not re-encode already-compressed media unless needed.
- Prefer filtergraphs for deterministic edits; use scripts for batch traversal and repeated operations.

## Safety

- Never include secrets, cookies, signed URLs, or private tokens in reusable commands or skill files.
- Do not delete source media unless the user explicitly asks.
- Be careful with recursive batch jobs; print or dry-run command plans when many files are affected.
- Report missing codecs, encoders, filters, hardware acceleration, or build limitations instead of guessing.
- For downloads or network inputs, verify legal/permission assumptions with the user when unclear.

## Local Helper

Use `scripts/ffmpeg_batch.py` for safe local batch jobs. It supports dry-runs, recursive traversal, overwrite control, and MP4-to-MP3 audio extraction.

Examples:

```bash
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py mp4-to-mp3 ~/Desktop --dry-run
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py mp4-to-mp3 ~/Desktop --recursive --overwrite
```

## Reference Sources

Prefer local capability probing and official docs because FFmpeg builds vary by version and compile flags.

- Official FFmpeg docs: https://ffmpeg.org/documentation.html
- FFmpeg filters manual: https://ffmpeg.org/ffmpeg-filters.html
- FFmpeg codecs manual: https://ffmpeg.org/ffmpeg-codecs.html
- FFmpeg formats manual: https://ffmpeg.org/ffmpeg-formats.html
- FFmpeg protocols manual: https://ffmpeg.org/ffmpeg-protocols.html
- FFmprovisr recipes: https://amiaopensource.github.io/ffmprovisr/
