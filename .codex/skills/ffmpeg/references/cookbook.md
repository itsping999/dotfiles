# FFmpeg Cookbook

This reference is a command-pattern index. Always inspect inputs with `ffprobe` first and adapt codecs/options to the local FFmpeg build.

## Local Capability Checks

```bash
ffmpeg -version
ffmpeg -hide_banner -encoders
ffmpeg -hide_banner -decoders
ffmpeg -hide_banner -formats
ffmpeg -hide_banner -muxers
ffmpeg -hide_banner -demuxers
ffmpeg -hide_banner -filters
ffmpeg -hide_banner -protocols
ffmpeg -hide_banner -hwaccels
ffmpeg -hide_banner -h encoder=libx264
ffmpeg -hide_banner -h filter=scale
```

## Option Placement and Selection

FFmpeg options are positional. Input options go before the related `-i`; output options go before the output path.

```bash
ffmpeg [global] [input options] -i "$INPUT" [output options] "$OUTPUT"
```

Stream mapping:

```bash
# Preserve everything.
ffmpeg -n -i "$INPUT" -map 0 -c copy "$OUTPUT"

# First video and first audio only.
ffmpeg -n -i "$INPUT" -map 0:v:0 -map 0:a:0 -c copy "$OUTPUT"

# Drop all subtitles.
ffmpeg -n -i "$INPUT" -map 0 -map -0:s -c copy "$OUTPUT"

# Keep metadata and chapters explicitly.
ffmpeg -n -i "$INPUT" -map 0 -map_metadata 0 -map_chapters 0 -c copy "$OUTPUT"
```

Use `-c copy` for stream copy/remuxing. Use encoders such as `libx264`, `libx265`, `aac`, `libopus`, or `libmp3lame` when changing quality, size, filters, sample rate, pixel format, or codec.

## Compatibility Targets

Web-compatible MP4:

```bash
ffmpeg -n -i "$INPUT" -map 0:v:0 -map 0:a:0? -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$OUTPUT.mp4"
```

Editing intermediate:

```bash
ffmpeg -n -i "$INPUT" -c:v prores_ks -profile:v 3 -c:a pcm_s16le "$OUTPUT.mov"
```

Archival Matroska stream copy:

```bash
ffmpeg -n -i "$INPUT" -map 0 -map_metadata 0 -map_chapters 0 -c copy "$OUTPUT.mkv"
```

Social/mobile vertical fit:

```bash
ffmpeg -n -i "$INPUT" -vf "scale=1080:-2,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -crf 23 -pix_fmt yuv420p -c:a aac "$OUTPUT.mp4"
```

## Inspect Media

```bash
ffprobe -hide_banner -i "$INPUT"
ffprobe -v error -show_format -show_streams -of json "$INPUT"
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,codec_name,pix_fmt -of default=nw=1 "$INPUT"
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels,bit_rate -of default=nw=1 "$INPUT"
```

Count frames, packets, or duration when needed:

```bash
ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nw=1 "$INPUT"
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=nw=1 "$INPUT"
ffmpeg -v error -i "$INPUT" -f null -
```

## Audio

Extract MP3 from MP4:

```bash
ffmpeg -n -i "$INPUT.mp4" -vn -codec:a libmp3lame -q:a 2 "$OUTPUT.mp3"
```

Extract audio without re-encoding when compatible:

```bash
ffmpeg -n -i "$INPUT.mp4" -vn -c:a copy "$OUTPUT.m4a"
```

Convert to WAV for editing or ASR:

```bash
ffmpeg -n -i "$INPUT" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$OUTPUT.wav"
```

Normalize loudness:

```bash
ffmpeg -n -i "$INPUT" -af loudnorm=I=-16:TP=-1.5:LRA=11 "$OUTPUT"
```

Change volume:

```bash
ffmpeg -n -i "$INPUT" -af volume=1.5 "$OUTPUT"
```

Trim audio:

```bash
ffmpeg -n -ss 00:01:00 -to 00:02:30 -i "$INPUT" -vn -codec:a libmp3lame -q:a 2 "$OUTPUT.mp3"
```

Change speed:

```bash
ffmpeg -n -i "$INPUT" -filter:a "atempo=1.25" "$OUTPUT"
```

Two-pass loudness normalization when precise delivery matters:

```bash
ffmpeg -i "$INPUT" -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null -
ffmpeg -n -i "$INPUT" -af loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=...:measured_TP=...:measured_LRA=...:measured_thresh=...:offset=...:linear=true "$OUTPUT"
```

## Video Conversion and Compression

Broadly compatible MP4:

```bash
ffmpeg -n -i "$INPUT" -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$OUTPUT.mp4"
```

Smaller MP4:

```bash
ffmpeg -n -i "$INPUT" -c:v libx264 -preset slow -crf 28 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart "$OUTPUT.mp4"
```

HEVC MP4:

```bash
ffmpeg -n -i "$INPUT" -c:v libx265 -preset medium -crf 28 -tag:v hvc1 -c:a aac -b:a 160k -movflags +faststart "$OUTPUT.mp4"
```

WebM VP9:

```bash
ffmpeg -n -i "$INPUT" -c:v libvpx-vp9 -crf 32 -b:v 0 -c:a libopus -b:a 128k "$OUTPUT.webm"
```

Remux without re-encoding:

```bash
ffmpeg -n -i "$INPUT.mkv" -map 0 -c copy "$OUTPUT.mp4"
```

AV1 MP4:

```bash
ffmpeg -n -i "$INPUT" -c:v libsvtav1 -crf 35 -preset 6 -c:a libopus -b:a 128k "$OUTPUT.mp4"
```

Image sequence to video:

```bash
ffmpeg -framerate 24 -i "frame_%04d.png" -c:v libx264 -pix_fmt yuv420p "$OUTPUT.mp4"
```

Video to image sequence:

```bash
ffmpeg -i "$INPUT" -vf fps=24 "frame_%04d.png"
```

## Trimming and Splitting

Fast keyframe trim:

```bash
ffmpeg -n -ss 00:01:00 -to 00:02:30 -i "$INPUT" -map 0 -c copy "$OUTPUT"
```

Accurate trim with re-encode:

```bash
ffmpeg -n -i "$INPUT" -ss 00:01:00 -to 00:02:30 -c:v libx264 -crf 23 -c:a aac "$OUTPUT.mp4"
```

Trim by duration:

```bash
ffmpeg -n -ss 00:01:00 -t 30 -i "$INPUT" -map 0 -c copy "$OUTPUT"
```

Split into segments:

```bash
ffmpeg -i "$INPUT" -map 0 -c copy -f segment -segment_time 600 -reset_timestamps 1 "part_%03d.mp4"
```

## Concatenate and Merge

Concat files with same codecs:

```bash
printf "file '%s'\n" "$PWD/part1.mp4" "$PWD/part2.mp4" > list.txt
ffmpeg -n -f concat -safe 0 -i list.txt -c copy "$OUTPUT.mp4"
```

Merge separate video and audio:

```bash
ffmpeg -n -i "$VIDEO" -i "$AUDIO" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "$OUTPUT.mp4"
```

Replace audio:

```bash
ffmpeg -n -i "$VIDEO" -i "$AUDIO" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "$OUTPUT.mp4"
```

## Scaling, Cropping, Rotation

Scale width to 1280, preserve aspect:

```bash
ffmpeg -n -i "$INPUT" -vf "scale=1280:-2" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Crop:

```bash
ffmpeg -n -i "$INPUT" -vf "crop=w:h:x:y" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Rotate 90 degrees:

```bash
ffmpeg -n -i "$INPUT" -vf "transpose=1" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Vertical social export:

```bash
ffmpeg -n -i "$INPUT" -vf "scale=1080:-2,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -crf 23 -c:a aac "$OUTPUT.mp4"
```

Deinterlace:

```bash
ffmpeg -n -i "$INPUT" -vf "yadif=mode=send_frame:parity=auto:deint=all" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Change playback speed:

```bash
ffmpeg -n -i "$INPUT" -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]" "$OUTPUT.mp4"
```

Fix sample aspect ratio:

```bash
ffmpeg -n -i "$INPUT" -vf "setsar=1" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

## Frames, Thumbnails, GIFs

One thumbnail:

```bash
ffmpeg -n -ss 00:00:05 -i "$INPUT" -frames:v 1 -update 1 "$OUTPUT.jpg"
```

Frame sequence:

```bash
ffmpeg -i "$INPUT" -vf fps=1 "frame_%04d.png"
```

Palette-based GIF:

```bash
ffmpeg -y -i "$INPUT" -vf "fps=12,scale=640:-1:flags=lanczos,palettegen" palette.png
ffmpeg -n -i "$INPUT" -i palette.png -lavfi "fps=12,scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse" "$OUTPUT.gif"
```

Contact sheet:

```bash
ffmpeg -n -i "$INPUT" -vf "fps=1/10,scale=320:-1,tile=5x4" "$OUTPUT.jpg"
```

## Subtitles, Metadata, Chapters

List streams:

```bash
ffprobe -v error -show_streams "$INPUT"
```

Extract subtitle stream:

```bash
ffmpeg -n -i "$INPUT" -map 0:s:0 "$OUTPUT.srt"
```

Burn subtitles:

```bash
ffmpeg -n -i "$INPUT" -vf "subtitles=$SUBTITLE_FILE" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Preserve metadata while remuxing:

```bash
ffmpeg -n -i "$INPUT" -map 0 -map_metadata 0 -map_chapters 0 -c copy "$OUTPUT"
```

Strip metadata:

```bash
ffmpeg -n -i "$INPUT" -map_metadata -1 -c copy "$OUTPUT"
```

Attach cover art to audio:

```bash
ffmpeg -n -i "$AUDIO" -i "$COVER" -map 0:a -map 1:v -c:a copy -c:v mjpeg -disposition:v attached_pic "$OUTPUT.m4a"
```

Copy attachments from Matroska:

```bash
ffmpeg -n -i "$INPUT.mkv" -map 0 -c copy "$OUTPUT.mkv"
```

## Filters and Overlays

Text overlay:

```bash
ffmpeg -n -i "$INPUT" -vf "drawtext=text='TEXT':x=20:y=20:fontsize=36:fontcolor=white" -c:a copy "$OUTPUT.mp4"
```

Image watermark:

```bash
ffmpeg -n -i "$INPUT" -i "$LOGO" -filter_complex "overlay=W-w-20:H-h-20" -c:a copy "$OUTPUT.mp4"
```

Picture-in-picture:

```bash
ffmpeg -n -i "$MAIN" -i "$PIP" -filter_complex "[1:v]scale=320:-2[pip];[0:v][pip]overlay=W-w-20:H-h-20" -c:a copy "$OUTPUT.mp4"
```

Side-by-side:

```bash
ffmpeg -n -i "$LEFT" -i "$RIGHT" -filter_complex "[0:v]scale=960:-2[l];[1:v]scale=960:-2[r];[l][r]hstack=inputs=2[v]" -map "[v]" -map 0:a? "$OUTPUT.mp4"
```

Blur background for vertical video:

```bash
ffmpeg -n -i "$INPUT" -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=20[bg];[0:v]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" -c:a copy "$OUTPUT.mp4"
```

Waveform video from audio:

```bash
ffmpeg -n -i "$INPUT" -filter_complex "[0:a]showwaves=s=1280x720:mode=line:rate=30[v]" -map "[v]" -map 0:a -c:v libx264 -c:a aac "$OUTPUT.mp4"
```

Stabilize two-pass, if `vidstab` is enabled:

```bash
ffmpeg -i "$INPUT" -vf vidstabdetect=shakiness=5:accuracy=15 -f null -
ffmpeg -n -i "$INPUT" -vf vidstabtransform=smoothing=30 -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

Color and levels helpers:

```bash
ffmpeg -n -i "$INPUT" -vf "eq=contrast=1.1:brightness=0.02:saturation=1.15" -c:a copy "$OUTPUT.mp4"
ffmpeg -n -i "$INPUT" -vf "format=yuv420p" -c:v libx264 -crf 23 -c:a copy "$OUTPUT.mp4"
```

## Streaming and Packaging

Create HLS:

```bash
ffmpeg -i "$INPUT" -c:v libx264 -crf 23 -c:a aac -f hls -hls_time 6 -hls_playlist_type vod "$OUTPUT_DIR/index.m3u8"
```

HLS with independent segments:

```bash
ffmpeg -i "$INPUT" -c:v libx264 -c:a aac -hls_time 6 -hls_flags independent_segments -hls_segment_filename "$OUTPUT_DIR/seg_%03d.ts" "$OUTPUT_DIR/index.m3u8"
```

Create DASH:

```bash
ffmpeg -i "$INPUT" -map 0 -c:v libx264 -c:a aac -f dash "$OUTPUT_DIR/manifest.mpd"
```

RTMP push:

```bash
ffmpeg -re -i "$INPUT" -c:v libx264 -preset veryfast -b:v 3000k -c:a aac -f flv "$RTMP_URL"
```

Fragmented MP4 for streaming-like playback:

```bash
ffmpeg -n -i "$INPUT" -c copy -movflags +frag_keyframe+empty_moov "$OUTPUT.mp4"
```

## Screen and Device Capture

List devices first because syntax varies by platform:

```bash
ffmpeg -hide_banner -devices
ffmpeg -hide_banner -f avfoundation -list_devices true -i ""
```

macOS screen capture:

```bash
ffmpeg -f avfoundation -framerate 30 -i "1:none" "$OUTPUT.mp4"
```

macOS camera plus audio device uses the device indexes from the list command:

```bash
ffmpeg -f avfoundation -framerate 30 -i "0:0" -c:v h264_videotoolbox -c:a aac "$OUTPUT.mp4"
```

## Repair and Diagnostics

Regenerate timestamps:

```bash
ffmpeg -n -fflags +genpts -i "$INPUT" -map 0 -c copy "$OUTPUT"
```

Ignore corrupt packets where possible:

```bash
ffmpeg -n -err_detect ignore_err -i "$INPUT" -map 0 -c copy "$OUTPUT"
```

Check decode errors:

```bash
ffmpeg -v error -i "$INPUT" -f null -
```

Bitstream filters:

```bash
# H.264 in MP4/MOV to Annex B for MPEG-TS workflows.
ffmpeg -n -i "$INPUT.mp4" -c copy -bsf:v h264_mp4toannexb "$OUTPUT.ts"

# Convert AAC ADTS to ASC when remuxing raw AAC into MP4.
ffmpeg -n -i "$INPUT.aac" -c copy -bsf:a aac_adtstoasc "$OUTPUT.m4a"
```

Timestamp and sync nudges:

```bash
ffmpeg -n -itsoffset 0.5 -i "$AUDIO" -i "$VIDEO" -map 1:v -map 0:a -c copy "$OUTPUT"
ffmpeg -n -i "$INPUT" -async 1 -vsync 1 "$OUTPUT"
```

## Hardware Acceleration

Probe first:

```bash
ffmpeg -hide_banner -hwaccels
ffmpeg -hide_banner -encoders | rg 'videotoolbox|nvenc|qsv|vaapi|amf'
```

macOS VideoToolbox H.264:

```bash
ffmpeg -n -i "$INPUT" -c:v h264_videotoolbox -b:v 5000k -c:a aac -movflags +faststart "$OUTPUT.mp4"
```

NVIDIA NVENC H.264:

```bash
ffmpeg -n -i "$INPUT" -c:v h264_nvenc -preset p5 -cq 23 -c:a aac "$OUTPUT.mp4"
```

## Batch Helper

Use the bundled helper when a task repeats across a directory:

```bash
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py --help
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py inspect "$DIR" --json
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py extract-audio "$DIR" --pattern "*.mp4" --to mp3 --recursive --dry-run
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py remux "$DIR" --pattern "*.mkv" --to .mp4
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py transcode-video "$DIR" --pattern "*.mov" --scale 1280:-2 --crf 24
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py thumbnails "$DIR" --pattern "*.mp4" --timestamp 00:00:05 --scale 640:-1
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py normalize-audio "$DIR" --pattern "*.mp4" --to .mp4
python3 ~/.codex/skills/ffmpeg/scripts/ffmpeg_batch.py custom "$DIR" --pattern "*.mp4" --ext .mkv --template "-map 0 -c copy {output}" --dry-run
```

For pipelines with multiple helper calls, prefer separate `--output-dir` values or narrow patterns so output from one step does not become input to the next step.

## Batch Patterns

Preview commands before running:

```bash
find "$DIR" -type f -name "*.mp4" -print0 | while IFS= read -r -d '' f; do
  printf 'ffmpeg -n -i %q -vn -codec:a libmp3lame -q:a 2 %q\n' "$f" "${f%.mp4}.mp3"
done
```

Run safely:

```bash
find "$DIR" -type f -name "*.mp4" -print0 | while IFS= read -r -d '' f; do
  ffmpeg -n -i "$f" -vn -codec:a libmp3lame -q:a 2 "${f%.mp4}.mp3"
done
```
