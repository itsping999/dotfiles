# Performance Monitor Scripts

通用的 Windows 与 Linux 性能采集脚本。脚本按参数选择进程和采样方式，输出统一的长表 CSV；不会注册系统服务、任务计划或告警任务。

## Linux

```sh
./monitor-linux.sh -p nginx,sshd -i 5 -n 12 -o ./records
./monitor-linux.sh -a -i 10 -n 0 -o ./records
```

- `-p name1,name2`：按进程名精确匹配，可重复传入。
- `-a`：采集所有可读取进程，不能与 `-p` 同时使用。
- `-i seconds`：采样间隔，默认 5 秒。
- `-n samples`：采样次数，默认 1；`0` 表示持续运行。
- `-o directory`：输出目录，默认当前目录。
- `-r proc-root`：测试时替换 `/proc` 根目录。

## Windows

```powershell
.\monitor.bat -ProcessName s-series,explorer -IntervalSeconds 5 -Samples 12 -Output .\records
powershell.exe -NoProfile -File .\monitor-windows.ps1 -ProcessName s-series -IntervalSeconds 10 -Samples 0 -OutputDirectory .\records
```

- `-ProcessName name1,name2`：按进程名采集，可重复传入。
- `-IncludeAllProcesses`：采集所有可读取进程，不能与 `-ProcessName` 同时使用。
- `-IntervalSeconds`：采样间隔，默认 5 秒。
- `-Samples`：采样次数，默认 1；`0` 表示持续运行。
- `-OutputDirectory`：输出目录，默认当前目录；`-Output` 是兼容别名。

## 输出

每次启动都会创建新的 CSV 文件，文件名为 `进程1-进程2_yyyyMMdd_HHmmss.csv`。表头固定为：

```text
timestamp,hostname,os,scope,target,metric_name,source_field,value,unit,status
```

时间使用 UTC；内存统一使用 MB；无法读取的值留空并在 `status` 中说明原因。指标的底层字段和通俗名称见 [`metric-glossary.md`](metric-glossary.md)。

## 验证

Linux：

```sh
sh -n ./monitor-linux.sh
```

Windows 脚本需在 Windows 环境中执行 PowerShell 解析或一次采样验证。
