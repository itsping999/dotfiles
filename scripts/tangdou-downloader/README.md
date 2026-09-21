# Tangdou Downloader

通过 Tangdou H5 API 按 VID 查询分享视频信息，并下载 MP4 文件。脚本只处理当前命令的 Cookie，不把 Cookie、签名 URL 或会话信息写入仓库。

```bash
python3 ./scripts/tangdou-downloader/tangdou_downloader.py info VID
python3 ./scripts/tangdou-downloader/tangdou_downloader.py download VID --output-dir ~/Downloads
python3 ./scripts/tangdou-downloader/tangdou_downloader.py download VID --dry-run
```

- 输入可以是 VID，也可以是包含 `vid` 的分享 URL。
- 需要 Cookie 时，优先使用当前 shell 的 `TANGDOU_COOKIE` 环境变量；`--cookie` 只用于一次性命令。
- 默认不覆盖已有文件，会尝试续传；明确需要替换时再使用 `--overwrite`。
- 使用 `--save-json PATH` 保存接口响应，便于排查接口字段变化。
- 下载后检查输出文件存在且非空；需要进一步确认媒体格式时可使用 `ffprobe`。
