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

For task-specific command templates, option patterns, and filter examples, read `references/cookbook.md`.

## Capability Map

FFmpeg work usually falls into one or more of these areas:

- **Probe and diagnose**: identify containers, codecs, streams, time bases, bitrate, frame rate, color, chapters, metadata, and decode errors.
- **Stream selection**: map, drop, copy, reorder, or replace video, audio, subtitle, attachment, metadata, and chapter streams.
- **Container changes**: remux between MP4, MOV, MKV, WebM, M4A, WAV, image sequences, HLS, DASH, and transport streams.
- **Encoding**: choose codecs, presets, CRF/quality, bitrate ladders, pixel formats, GOP/keyframes, sample rates, channels, and compatibility flags.
- **Editing**: trim, split, concatenate, crop, scale, pad, rotate, deinterlace, change speed, generate thumbnails, and create previews.
- **Filtergraphs**: audio filters, video filters, overlays, subtitles, watermarks, loudness, denoise, equalization, waveform/spectrum, and complex multi-input layouts.
- **Packaging and streaming**: HLS, DASH, RTMP/SRT inputs or outputs, fragmented MP4, faststart, segmenting, and live-style `-re` behavior.
- **Devices and hardware**: screen/camera/mic capture, hardware encoders/decoders, and platform-specific acceleration.
- **Repair and preservation**: timestamp fixes, corrupt packet handling, metadata preservation or stripping, bitstream filters, archival intermediate formats, and validation.

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
- Audio extraction to MP3 is only one common case: `-vn -codec:a libmp3lame -q:a 2`.
- Lossless audio extraction when source already has AAC/M4A and the target supports it: use `-vn -c:a copy`.
- Preserve quality during resize/filtering by using CRF-based encoding instead of fixed bitrate unless a platform requires bitrate.
- Avoid generational loss: do not re-encode already-compressed media unless needed.
- Prefer filtergraphs for deterministic edits; use scripts for batch traversal and repeated operations.
- Use `-map 0` when preserving all input streams matters; FFmpeg's default stream selection may drop subtitles, attachments, alternate audio, or metadata.
- Use local probing (`ffmpeg -filters`, `ffmpeg -encoders`, `ffmpeg -hwaccels`) because available features vary by build.

## Safety

- Never include secrets, cookies, signed URLs, or private tokens in reusable commands or skill files.
- Do not delete source media unless the user explicitly asks.
- Be careful with recursive batch jobs; print or dry-run command plans when many files are affected.
- Report missing codecs, encoders, filters, hardware acceleration, or build limitations instead of guessing.
- For downloads or network inputs, verify legal/permission assumptions with the user when unclear.

## Local Helper

Use `scripts/ffmpeg_batch.py` for safe local batch jobs. It supports dry-runs, recursive traversal, overwrite control, and presets for inspection, audio extraction, remuxing, video transcoding, thumbnail generation, loudness normalization, and custom per-file FFmpeg templates.

Examples:

```bash
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py inspect ~/Movies --pattern "*.mov"
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py extract-audio ~/Desktop --to mp3 --dry-run
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py remux ~/Movies --pattern "*.mkv" --to .mp4 --recursive
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py transcode-video ~/Movies --pattern "*.mov" --to .mp4 --crf 23 --preset medium
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py thumbnails ~/Movies --pattern "*.mp4" --timestamp 00:00:05
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py custom ~/Movies --template '-map 0 -c copy {output}' --suffix .copy --ext .mkv --dry-run
```

For multi-step batches, write each step to a separate `--output-dir` or use narrow `--pattern` values so generated outputs are not picked up by later commands unintentionally.

## Reference Sources

Prefer local capability probing and official docs because FFmpeg builds vary by version and compile flags.

- Official FFmpeg docs: https://ffmpeg.org/documentation.html
- FFmpeg command-line tool manual: https://ffmpeg.org/ffmpeg.html
- FFmpeg filters manual: https://ffmpeg.org/ffmpeg-filters.html
- FFmpeg codecs manual: https://ffmpeg.org/ffmpeg-codecs.html
- FFmpeg formats manual: https://ffmpeg.org/ffmpeg-formats.html
- FFmpeg protocols manual: https://ffmpeg.org/ffmpeg-protocols.html
- FFmpeg bitstream filters manual: https://ffmpeg.org/ffmpeg-bitstream-filters.html
- FFmprovisr recipes: https://amiaopensource.github.io/ffmprovisr/
- FFmpeg cookbook examples: https://github.com/talwrii/ffmpeg-cookbook
