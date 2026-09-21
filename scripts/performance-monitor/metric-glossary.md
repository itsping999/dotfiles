# 性能指标通俗名称词典

通用脚本把 `metric_name` 写成易懂的中文，把 `source_field` 保留为底层字段名。这样使用者先看懂指标，维护者仍能追溯到 Windows 属性或 Linux `/proc` 字段。

## Linux `/proc/<pid>/status`

| 原始字段 | 通俗名称 | 含义 | 常用单位 |
|---|---|---|---|
| `VmPeak` | 历史最大虚拟内存 | 进程运行以来曾经申请到的最大虚拟地址空间 | MB |
| `VmSize` | 当前虚拟内存 | 当前进程占用的虚拟地址空间总量 | MB |
| `VmHWM` | 历史最大实际内存 | 进程运行以来曾经达到的最大实际内存占用 | MB |
| `VmRSS` | 当前实际内存 | 当前真正驻留在物理内存中的进程内存 | MB |
| `Threads` | 线程数量 | 当前进程中的执行线程数 | 个 |

“历史最大”表示进程自启动以来的峰值，不是最近一次采样周期内的峰值。

## Linux `/proc/meminfo`

| 原始字段 | 通俗名称 | 含义 | 常用单位 |
|---|---|---|---|
| `MemTotal` | 系统总内存 | 系统可管理的物理内存总量 | MB |
| `MemAvailable` | 当前可用内存 | 估计不影响系统正常运行、可以分配给程序的内存 | MB |
| `MemTotal-MemAvailable` | 当前已用内存 | 总内存减去当前可用内存 | MB |
| `Cached` | 文件缓存内存 | 用于缓存文件内容、通常可回收的内存 | MB |
| `Slab` | 内核对象缓存 | Linux 内核保存对象和数据结构使用的缓存 | MB |
| `SwapTotal` | 交换区总量 | Swap 空间总容量 | MB |
| `SwapFree` | 交换区可用量 | 尚未使用的 Swap 空间 | MB |
| `/proc/stat` | 处理器使用率 | 根据相邻两次 CPU 累计计数计算出的使用比例 | % |

## Windows 进程与系统

| 原始字段或属性 | 通俗名称 | 含义 | 常用单位 |
|---|---|---|---|
| `TotalProcessorTime` | 处理器使用率 | 本采样间隔内进程消耗的 CPU 时间占比 | % |
| `WorkingSet64` | 当前实际内存 | 当前进程驻留在物理内存中的总量 | MB |
| `PrivateMemorySize64` | 当前独占内存 | 主要由该进程独占、不能与其他进程共享的内存 | MB |
| `VirtualMemorySize64` | 当前虚拟内存 | 当前进程占用的虚拟地址空间 | MB |
| `PeakWorkingSet64` | 历史最大实际内存 | 进程运行以来达到的最大物理内存占用 | MB |
| `PeakVirtualMemorySize64` | 历史最大虚拟内存 | 进程运行以来达到的最大虚拟地址空间占用 | MB |
| `Handles` | 句柄数量 | 进程打开的文件、线程、窗口等系统资源数量 | 个 |
| `Threads.Count` | 线程数量 | 当前进程中的执行线程数 | 个 |
| `TotalVisibleMemorySize` | 系统总内存 | Windows 可见的物理内存总量 | MB |
| `TotalVisibleMemorySize-FreePhysicalMemory` | 当前已用内存 | 系统总内存减去当前可用内存 | MB |
| `FreePhysicalMemory` | 当前可用内存 | 当前可直接使用的物理内存 | MB |
| `LoadPercentage` | 处理器使用率 | Windows 提供的当前处理器负载 | % |

## 旧版 Windows `typeperf` 字段

如果用户要求兼容历史 `monitor.bat`，使用下面的展示名称，不要把原始计数器名直接展示给非技术用户：

| 原始计数器 | 通俗名称 |
|---|---|
| `% Processor Time` | 处理器使用率 |
| `Working Set - Private` | 当前独占实际内存 |
| `IO Read Bytes/sec` | 读取数据速率 |
| `IO Write Bytes/sec` | 写入数据速率 |
| `Handle Count` | 句柄数量 |
| `Thread Count` | 线程数量 |
| `Bytes Total/sec` | 网络收发总速率 |
