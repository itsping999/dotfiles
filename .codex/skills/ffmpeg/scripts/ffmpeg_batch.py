#!/usr/bin/env python3
"""Safe batch helpers for common FFmpeg workflows."""

from __future__ import annotations

import argparse
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


def require_tool(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"Missing required tool: {name}")


def iter_files(root: Path, pattern: str, recursive: bool) -> list[Path]:
    globber = root.rglob if recursive else root.glob
    return sorted(path for path in globber(pattern) if path.is_file())


def print_command(command: list[str]) -> None:
    print(" ".join(shlex.quote(part) for part in command))


def run_command(command: list[str], dry_run: bool) -> None:
    print_command(command)
    if dry_run:
        return
    subprocess.run(command, check=True)


def mp4_to_mp3(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    source_dir = args.directory.expanduser().resolve()
    if not source_dir.is_dir():
        raise SystemExit(f"Not a directory: {source_dir}")

    files = iter_files(source_dir, args.pattern, args.recursive)
    if not files:
        print(f"No files matched {args.pattern!r} under {source_dir}")
        return 0

    overwrite_flag = "-y" if args.overwrite else "-n"
    failures = 0
    for input_path in files:
        output_path = input_path.with_suffix(args.output_extension)
        if output_path.exists() and not args.overwrite:
            print(f"Skip existing output: {output_path}")
            continue

        command = [
            "ffmpeg",
            overwrite_flag,
            "-hide_banner",
            "-i",
            str(input_path),
            "-vn",
            "-codec:a",
            args.codec,
            "-q:a",
            str(args.quality),
            str(output_path),
        ]
        try:
            run_command(command, args.dry_run)
        except subprocess.CalledProcessError as exc:
            failures += 1
            print(f"Failed: {input_path} ({exc.returncode})", file=sys.stderr)
            if args.stop_on_error:
                return exc.returncode

    return 1 if failures else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Safe batch helpers for common FFmpeg workflows.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    mp3 = subparsers.add_parser(
        "mp4-to-mp3",
        help="Extract MP3 audio from MP4 files in a directory.",
    )
    mp3.add_argument("directory", type=Path, help="Directory containing MP4 files.")
    mp3.add_argument(
        "--pattern",
        default="*.mp4",
        help="Glob pattern to match. Default: *.mp4",
    )
    mp3.add_argument(
        "--recursive",
        action="store_true",
        help="Search subdirectories recursively.",
    )
    mp3.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing outputs.",
    )
    mp3.add_argument(
        "--dry-run",
        action="store_true",
        help="Print commands without running them.",
    )
    mp3.add_argument(
        "--stop-on-error",
        action="store_true",
        help="Stop at the first failed conversion.",
    )
    mp3.add_argument(
        "--codec",
        default="libmp3lame",
        help="Audio encoder. Default: libmp3lame",
    )
    mp3.add_argument(
        "--quality",
        default="2",
        help="Encoder quality for -q:a. Default: 2",
    )
    mp3.add_argument(
        "--output-extension",
        default=".mp3",
        help="Output file extension. Default: .mp3",
    )
    mp3.set_defaults(func=mp4_to_mp3)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
