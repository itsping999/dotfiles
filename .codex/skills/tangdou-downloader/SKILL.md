---
name: "tangdou-downloader"
description: "Use when downloading or inspecting Tangdou (糖豆) shared videos by VID with the Tangdou H5 API, including fetching video metadata, deriving a safe filename from the title, and downloading the MP4 with safe credential handling."
---

# Tangdou Downloader Skill

## When to Use

Use this skill when the user wants to download or inspect a Tangdou (糖豆) shared video and has a Tangdou `vid` value or a URL containing `vid`.

## Workflow

1. Extract the `vid` from the user input. If they gave only a page URL, parse the `vid` query parameter or obvious numeric/id path segment.
2. Fetch metadata with `scripts/tangdou_downloader.py info VID`.
3. Confirm the derived title and output filename when the request is ambiguous or may overwrite an existing file.
4. Download with `scripts/tangdou_downloader.py download VID --output-dir DIR`.
5. Verify the output file exists and is non-empty. If FFmpeg is available, inspect it with `ffprobe`.

## Credential Handling

- Never store cookies, signed URLs, session IDs, or private headers in the skill.
- Prefer `TANGDOU_COOKIE` in the current shell environment when Tangdou requires a session cookie.
- Use `--cookie` only for a one-off local command when the user explicitly provides a cookie for this run.
- Do not copy the legacy `PHPSESSID` from old scripts into shared files.

## Helper

```bash
python3 ~/.codex/skills/tangdou-downloader/scripts/tangdou_downloader.py info VID
python3 ~/.codex/skills/tangdou-downloader/scripts/tangdou_downloader.py download VID --output-dir ~/Downloads
python3 ~/.codex/skills/tangdou-downloader/scripts/tangdou_downloader.py download VID --dry-run
```

Useful options:

- `--cookie COOKIE`: one-off cookie header value.
- `--save-json PATH`: save the API response for debugging.
- `--filename NAME`: override the derived output filename.
- `--overwrite`: replace an existing output instead of resuming/skipping.
- `--dry-run`: print metadata and planned output without downloading.

## Failure Handling

- Empty API response: report that the H5 API did not return data and suggest checking the `vid`.
- Missing video URL: save/inspect JSON if available; Tangdou may have changed fields or require authentication.
- HTTP download failure: keep partial files only if curl created them for resume; report the exact status.
- Existing output: skip or resume by default; use `--overwrite` only when requested.
