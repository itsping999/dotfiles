#!/usr/bin/env python3
"""Fetch and download Tangdou shared videos by VID."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlparse
from urllib.request import Request, urlopen


API_URL = "https://api-h5.tangdou.com/sample/share/main"
REFERER = "https://www.tangdoucdn.com/"
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/101.0.4951.54 Safari/537.36"
)


def extract_vid(raw: str) -> str:
    value = raw.strip()
    if not value:
        raise SystemExit("Missing Tangdou VID.")

    parsed = urlparse(value)
    if parsed.query:
        query = parse_qs(parsed.query)
        for key in ("vid", "id", "video_id"):
            if query.get(key):
                return query[key][0].strip()

    match = re.search(r"(?:vid|id)[=/]([A-Za-z0-9_-]+)", value)
    if match:
        return match.group(1)

    return value


def request_headers(cookie: str | None) -> dict[str, str]:
    headers = {
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "zh,zh-CN;q=0.9",
        "Referer": REFERER,
        "User-Agent": USER_AGENT,
    }
    if cookie:
        headers["Cookie"] = cookie
    return headers


def fetch_json(vid: str, cookie: str | None, timeout: int) -> dict:
    url = f"{API_URL}?vid={vid}"
    request = Request(url, headers=request_headers(cookie))
    try:
        with urlopen(request, timeout=timeout) as response:
            raw = response.read()
    except HTTPError as exc:
        raise SystemExit(f"Tangdou API returned HTTP {exc.code}.") from exc
    except URLError as exc:
        raise SystemExit(f"Tangdou API request failed: {exc.reason}") from exc

    if not raw:
        raise SystemExit("Tangdou API returned an empty response.")

    try:
        return json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Tangdou API returned invalid JSON: {exc}") from exc


def first_string(data: dict, keys: tuple[str, ...]) -> str:
    for key in keys:
        value = data.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def extract_bracket_name(title: str) -> str:
    match = re.search(r"《([^》]+)》", title)
    if match:
        return match.group(1)
    return title


def sanitize_filename(value: str, fallback: str) -> str:
    name = value.strip() or fallback
    name = re.sub(r"[\x00-\x1f]", "", name)
    name = re.sub(r"""[/\\:*?"<>|]""", "_", name)
    name = re.sub(r"\s+", "_", name).strip("._ ")
    return (name or fallback)[:200]


def parse_metadata(payload: dict, vid: str) -> dict[str, str]:
    data = payload.get("data")
    if not isinstance(data, dict):
        data = {}

    title = first_string(data, ("title", "name", "share_title", "desc"))
    video_url = first_string(data, ("video_url", "play_url", "url", "download_url", "videoUrl", "playUrl"))
    raw_name = extract_bracket_name(title) if title else vid
    filename = f"{sanitize_filename(raw_name, vid)}.mp4"

    return {
        "vid": vid,
        "title": title,
        "raw_name": raw_name,
        "video_url": video_url,
        "filename": filename,
    }


def print_metadata(metadata: dict[str, str]) -> None:
    print(f"VID: {metadata['vid']}")
    print(f"Title: {metadata['title']}")
    print(f"Extracted name: {metadata['raw_name']}")
    print(f"Video URL: {metadata['video_url']}")
    print(f"Filename: {metadata['filename']}")


def save_json(path: Path, payload: dict) -> None:
    path.expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)
    path.expanduser().resolve().write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def curl_download(
    video_url: str,
    output_path: Path,
    cookie: str | None,
    overwrite: bool,
) -> None:
    if shutil.which("curl") is None:
        raise SystemExit("Missing required tool: curl")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    command = [
        "curl",
        "-L",
        "--fail",
        "--show-error",
        video_url,
        "-H",
        f"Referer: {REFERER}",
        "-H",
        f"User-Agent: {USER_AGENT}",
        "-o",
        str(output_path),
    ]
    if cookie:
        command.extend(["-H", f"Cookie: {cookie}"])

    if overwrite and output_path.exists():
        output_path.unlink()
    elif not overwrite:
        command[4:4] = ["--continue-at", "-"]

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as exc:
        raise SystemExit(f"Download failed with exit code {exc.returncode}.") from exc


def resolve_cookie(args: argparse.Namespace) -> str | None:
    return args.cookie or os.environ.get("TANGDOU_COOKIE")


def load(args: argparse.Namespace) -> tuple[dict, dict[str, str]]:
    vid = extract_vid(args.vid)
    cookie = resolve_cookie(args)
    payload = fetch_json(vid, cookie, args.timeout)
    if args.save_json:
        save_json(args.save_json, payload)
    metadata = parse_metadata(payload, vid)
    return payload, metadata


def info(args: argparse.Namespace) -> int:
    _payload, metadata = load(args)
    print_metadata(metadata)
    if not metadata["video_url"]:
        return 2
    return 0


def download(args: argparse.Namespace) -> int:
    _payload, metadata = load(args)
    print_metadata(metadata)
    if not metadata["video_url"]:
        print("Error: video URL missing in Tangdou API response.", file=sys.stderr)
        return 2

    output_dir = args.output_dir.expanduser().resolve()
    filename = args.filename or metadata["filename"]
    if not filename.lower().endswith(".mp4"):
        filename = f"{filename}.mp4"
    output_path = output_dir / sanitize_filename(filename[:-4], metadata["vid"])
    output_path = output_path.with_suffix(".mp4")

    print(f"Output file: {output_path}")
    if args.dry_run:
        return 0

    if output_path.exists() and not args.overwrite:
        print(f"Existing file found, attempting resume: {output_path}")

    curl_download(metadata["video_url"], output_path, resolve_cookie(args), args.overwrite)
    if not output_path.exists() or output_path.stat().st_size == 0:
        print(f"Error: output file is missing or empty: {output_path}", file=sys.stderr)
        return 1

    print(f"Download completed: {output_path}")
    return 0


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("vid", help="Tangdou VID or URL containing vid.")
    parser.add_argument("--cookie", help="One-off Cookie header value. Prefer TANGDOU_COOKIE.")
    parser.add_argument("--timeout", type=int, default=30, help="API timeout in seconds. Default: 30")
    parser.add_argument("--save-json", type=Path, help="Save Tangdou API JSON response.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Fetch and download Tangdou shared videos by VID.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect = subparsers.add_parser("info", help="Fetch and print Tangdou video metadata.")
    add_common_args(inspect)
    inspect.set_defaults(func=info)

    fetch = subparsers.add_parser("download", help="Download a Tangdou video as MP4.")
    add_common_args(fetch)
    fetch.add_argument("--output-dir", type=Path, default=Path.cwd(), help="Output directory.")
    fetch.add_argument("--filename", help="Override output filename.")
    fetch.add_argument("--overwrite", action="store_true", help="Overwrite existing output.")
    fetch.add_argument("--dry-run", action="store_true", help="Print planned output without downloading.")
    fetch.set_defaults(func=download)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
