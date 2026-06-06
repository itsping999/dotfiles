#!/usr/bin/env python3
"""Safe batch helpers for common FFmpeg and ffprobe workflows."""

from __future__ import annotations

import argparse
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


AUDIO_PRESETS = {
    "mp3": {"ext": ".mp3", "args": ["-vn", "-codec:a", "libmp3lame", "-q:a", "2"]},
    "m4a": {"ext": ".m4a", "args": ["-vn", "-codec:a", "aac", "-b:a", "160k"]},
    "aac-copy": {"ext": ".m4a", "args": ["-vn", "-c:a", "copy"]},
    "wav": {"ext": ".wav", "args": ["-vn", "-acodec", "pcm_s16le"]},
    "asr-wav": {"ext": ".wav", "args": ["-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1"]},
    "flac": {"ext": ".flac", "args": ["-vn", "-codec:a", "flac"]},
    "opus": {"ext": ".opus", "args": ["-vn", "-codec:a", "libopus", "-b:a", "96k"]},
}


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


def output_for(
    input_path: Path,
    root: Path,
    output_dir: Path | None,
    suffix: str,
    extension: str,
) -> Path:
    extension = extension if extension.startswith(".") else f".{extension}"
    if output_dir is None:
        parent = input_path.parent
    else:
        try:
            parent = output_dir.expanduser().resolve() / input_path.parent.relative_to(root)
        except ValueError:
            parent = output_dir.expanduser().resolve()
    return parent / f"{input_path.stem}{suffix}{extension}"


def collect_files(args: argparse.Namespace) -> tuple[Path, list[Path]]:
    root = args.directory.expanduser().resolve()
    if not root.is_dir():
        raise SystemExit(f"Not a directory: {root}")

    files = iter_files(root, args.pattern, args.recursive)
    if not files:
        print(f"No files matched {args.pattern!r} under {root}")
    return root, files


def run_batch(
    files: list[Path],
    build_command,
    dry_run: bool,
    stop_on_error: bool,
) -> int:
    failures = 0
    for input_path in files:
        command, output_path = build_command(input_path)
        if output_path is not None and not dry_run:
            output_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            run_command(command, dry_run)
        except subprocess.CalledProcessError as exc:
            failures += 1
            print(f"Failed: {input_path} ({exc.returncode})", file=sys.stderr)
            if stop_on_error:
                return exc.returncode
    return 1 if failures else 0


def overwrite_flag(args: argparse.Namespace) -> str:
    return "-y" if args.overwrite else "-n"


def command_prefix(args: argparse.Namespace) -> list[str]:
    return ["ffmpeg", overwrite_flag(args), "-hide_banner", "-loglevel", args.loglevel]


def inspect(args: argparse.Namespace) -> int:
    require_tool("ffprobe")
    root, files = collect_files(args)
    if not files:
        return 0

    def build_command(input_path: Path) -> tuple[list[str], None]:
        command = ["ffprobe", "-hide_banner"]
        if args.json:
            command = ["ffprobe", "-v", "error", "-show_format", "-show_streams", "-of", "json"]
        return command + [str(input_path)], None

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def extract_audio(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    preset = AUDIO_PRESETS[args.to]
    extension = args.ext or preset["ext"]
    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, extension)
        command = command_prefix(args) + ["-i", str(input_path)] + preset["args"] + [str(output_path)]
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def mp4_to_mp3(args: argparse.Namespace) -> int:
    args.to = "mp3"
    args.ext = ".mp3"
    args.suffix = ""
    return extract_audio(args)


def remux(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, args.to)
        command = command_prefix(args) + ["-i", str(input_path), "-map", "0", "-c", "copy"]
        if args.bitstream_filter:
            command += ["-bsf:v", args.bitstream_filter]
        command += [str(output_path)]
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def transcode_video(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, args.to)
        filters = []
        if args.scale:
            filters.append(f"scale={args.scale}")
        if args.fps:
            filters.append(f"fps={args.fps}")
        if args.filter:
            filters.append(args.filter)

        command = command_prefix(args) + ["-i", str(input_path), "-map", "0"]
        if filters:
            command += ["-vf", ",".join(filters)]
        command += [
            "-c:v",
            args.video_codec,
            "-preset",
            args.preset,
            "-crf",
            str(args.crf),
            "-pix_fmt",
            args.pix_fmt,
            "-c:a",
            args.audio_codec,
        ]
        if args.audio_bitrate:
            command += ["-b:a", args.audio_bitrate]
        if args.faststart:
            command += ["-movflags", "+faststart"]
        command += [str(output_path)]
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def thumbnails(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, args.ext)
        command = [
            "ffmpeg",
            overwrite_flag(args),
            "-hide_banner",
            "-loglevel",
            args.loglevel,
            "-ss",
            args.timestamp,
            "-i",
            str(input_path),
            "-frames:v",
            "1",
            "-update",
            "1",
        ]
        if args.scale:
            command += ["-vf", f"scale={args.scale}"]
        command += [str(output_path)]
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def normalize_audio(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, args.to)
        loudnorm = f"loudnorm=I={args.integrated}:TP={args.true_peak}:LRA={args.range}"
        command = (
            command_prefix(args)
            + ["-i", str(input_path), "-af", loudnorm, "-c:v", "copy", "-c:a", args.audio_codec]
        )
        if args.audio_bitrate:
            command += ["-b:a", args.audio_bitrate]
        command += [str(output_path)]
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def custom(args: argparse.Namespace) -> int:
    require_tool("ffmpeg")
    root, files = collect_files(args)
    if not files:
        return 0

    output_dir = args.output_dir

    def build_command(input_path: Path) -> tuple[list[str], Path]:
        output_path = output_for(input_path, root, output_dir, args.suffix, args.ext)
        values = {
            "input": str(input_path),
            "output": str(output_path),
            "stem": input_path.stem,
            "parent": str(input_path.parent),
        }
        template = args.template.format(**values)
        extra_args = shlex.split(template)
        if str(output_path) not in extra_args:
            raise SystemExit("Custom template must include {output}.")
        command = command_prefix(args) + ["-i", str(input_path)] + extra_args
        return command, output_path

    return run_batch(files, build_command, args.dry_run, args.stop_on_error)


def add_batch_args(parser: argparse.ArgumentParser, pattern: str) -> None:
    parser.add_argument("directory", type=Path, help="Directory containing input media.")
    parser.add_argument("--pattern", default=pattern, help=f"Glob pattern. Default: {pattern}")
    parser.add_argument("--recursive", action="store_true", help="Search subdirectories recursively.")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running them.")
    parser.add_argument("--stop-on-error", action="store_true", help="Stop at the first failed command.")


def add_output_args(
    parser: argparse.ArgumentParser,
    *,
    suffix: str,
    overwrite: bool = True,
) -> None:
    parser.add_argument("--output-dir", type=Path, help="Optional output directory.")
    parser.add_argument("--suffix", default=suffix, help=f"Output filename suffix. Default: {suffix}")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing outputs.")
    if overwrite:
        parser.add_argument("--no-overwrite", dest="overwrite", action="store_false")
        parser.set_defaults(overwrite=False)


def add_ffmpeg_log_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--loglevel",
        default="warning",
        help="FFmpeg log level. Default: warning",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Safe batch helpers for common FFmpeg and ffprobe workflows.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    probe = subparsers.add_parser("inspect", help="Run ffprobe on matching files.")
    add_batch_args(probe, "*")
    probe.add_argument("--json", action="store_true", help="Emit ffprobe JSON.")
    probe.set_defaults(func=inspect)

    audio = subparsers.add_parser("extract-audio", help="Extract or convert audio from media files.")
    add_batch_args(audio, "*.mp4")
    add_output_args(audio, suffix="")
    audio.add_argument("--to", choices=sorted(AUDIO_PRESETS), default="mp3", help="Audio preset.")
    audio.add_argument("--ext", help="Override output extension.")
    add_ffmpeg_log_args(audio)
    audio.set_defaults(func=extract_audio)

    mp3 = subparsers.add_parser("mp4-to-mp3", help="Compatibility alias for extract-audio --to mp3.")
    add_batch_args(mp3, "*.mp4")
    add_output_args(mp3, suffix="")
    add_ffmpeg_log_args(mp3)
    mp3.set_defaults(func=mp4_to_mp3)

    copy = subparsers.add_parser("remux", help="Change container while stream-copying all streams.")
    add_batch_args(copy, "*.mkv")
    add_output_args(copy, suffix="")
    copy.add_argument("--to", default=".mp4", help="Output extension/container. Default: .mp4")
    copy.add_argument("--bitstream-filter", help="Optional video bitstream filter, e.g. h264_mp4toannexb.")
    add_ffmpeg_log_args(copy)
    copy.set_defaults(func=remux)

    video = subparsers.add_parser("transcode-video", help="Batch transcode video with common quality options.")
    add_batch_args(video, "*")
    add_output_args(video, suffix=".transcoded")
    video.add_argument("--to", default=".mp4", help="Output extension/container. Default: .mp4")
    video.add_argument("--video-codec", default="libx264", help="Video encoder. Default: libx264")
    video.add_argument("--audio-codec", default="aac", help="Audio encoder. Default: aac")
    video.add_argument("--audio-bitrate", default="160k", help="Audio bitrate. Default: 160k")
    video.add_argument("--preset", default="medium", help="Encoder preset. Default: medium")
    video.add_argument("--crf", default="23", help="CRF/quality value. Default: 23")
    video.add_argument("--pix-fmt", default="yuv420p", help="Pixel format. Default: yuv420p")
    video.add_argument("--scale", help="Scale expression, e.g. 1280:-2.")
    video.add_argument("--fps", help="Output frame rate filter value.")
    video.add_argument("--filter", help="Additional video filter appended after scale/fps.")
    video.add_argument("--faststart", action="store_true", default=True, help="Add +faststart movflag.")
    video.add_argument("--no-faststart", dest="faststart", action="store_false")
    add_ffmpeg_log_args(video)
    video.set_defaults(func=transcode_video)

    thumbs = subparsers.add_parser("thumbnails", help="Generate one thumbnail per input file.")
    add_batch_args(thumbs, "*")
    add_output_args(thumbs, suffix=".thumb")
    thumbs.add_argument("--timestamp", default="00:00:05", help="Seek timestamp. Default: 00:00:05")
    thumbs.add_argument("--ext", default=".jpg", help="Output image extension. Default: .jpg")
    thumbs.add_argument("--scale", help="Scale expression, e.g. 640:-1.")
    add_ffmpeg_log_args(thumbs)
    thumbs.set_defaults(func=thumbnails)

    norm = subparsers.add_parser("normalize-audio", help="Apply loudnorm to audio while copying video.")
    add_batch_args(norm, "*")
    add_output_args(norm, suffix=".normalized")
    norm.add_argument("--to", default=".mp4", help="Output extension/container. Default: .mp4")
    norm.add_argument("--audio-codec", default="aac", help="Audio encoder. Default: aac")
    norm.add_argument("--audio-bitrate", default="160k", help="Audio bitrate. Default: 160k")
    norm.add_argument("--integrated", default="-16", help="Integrated loudness target. Default: -16")
    norm.add_argument("--true-peak", default="-1.5", help="True peak target. Default: -1.5")
    norm.add_argument("--range", default="11", help="Loudness range target. Default: 11")
    add_ffmpeg_log_args(norm)
    norm.set_defaults(func=normalize_audio)

    user = subparsers.add_parser("custom", help="Run a custom per-file FFmpeg output template.")
    add_batch_args(user, "*")
    add_output_args(user, suffix=".out")
    user.add_argument("--ext", required=True, help="Output extension, e.g. .mkv or .mp4.")
    user.add_argument(
        "--template",
        required=True,
        help="Arguments after input; supports {input}, {output}, {stem}, {parent}. Must include {output}.",
    )
    add_ffmpeg_log_args(user)
    user.set_defaults(func=custom)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
