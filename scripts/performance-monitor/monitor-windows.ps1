[CmdletBinding()]
param(
    [string[]]$ProcessName = @(),
    [int]$IntervalSeconds = 5,
    [int]$Samples = 1,
    [Alias("Output")]
    [string]$OutputDirectory = ".",
    [switch]$IncludeAllProcesses
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Continue"

if ($IntervalSeconds -lt 1) {
    throw "IntervalSeconds must be at least 1."
}
if ($Samples -lt 0) {
    throw "Samples must be zero or a positive integer."
}

$header = '"timestamp","hostname","os","scope","target","metric_name","source_field","value","unit","status"'
$hostNameValue = $env:COMPUTERNAME
if ([string]::IsNullOrWhiteSpace($hostNameValue)) {
    $hostNameValue = [Environment]::MachineName
}
$configuredProcessNames = @(
    $ProcessName |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
)

if ($configuredProcessNames.Count -eq 0 -and -not $IncludeAllProcesses) {
    throw "ProcessName is required; pass one or more process names, or use -IncludeAllProcesses."
}
if ($configuredProcessNames.Count -gt 0 -and $IncludeAllProcesses) {
    throw "Use ProcessName or IncludeAllProcesses, not both."
}

if ($IncludeAllProcesses) {
    $processLabel = "all-processes"
}
else {
    $processLabel = $configuredProcessNames -join "-"
    $processLabel = [regex]::Replace($processLabel, '[^A-Za-z0-9._-]', '-')
    $processLabel = [regex]::Replace($processLabel, '-+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($processLabel)) {
        $processLabel = "processes"
    }
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
$fileTimestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss", [System.Globalization.CultureInfo]::InvariantCulture)
$fileStem = "{0}_{1}" -f $processLabel, $fileTimestamp
$OutputFile = Join-Path -Path $OutputDirectory -ChildPath ("{0}.csv" -f $fileStem)
$suffix = 1
while (Test-Path -LiteralPath $OutputFile) {
    $OutputFile = Join-Path -Path $OutputDirectory -ChildPath ("{0}_{1}.csv" -f $fileStem, $suffix)
    $suffix++
}
$script:OutputInitialized = $false

function New-MetricRow {
    param(
        [string]$Timestamp,
        [string]$Scope,
        [string]$Target,
        [string]$MetricName,
        [string]$SourceField,
        [object]$Value,
        [string]$Unit,
        [string]$Status
    )

    $normalizedValue = $Value
    if ($null -ne $Value -and $Value -is [System.IFormattable]) {
        $normalizedValue = $Value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return [pscustomobject][ordered]@{
        timestamp    = $Timestamp
        hostname     = $hostNameValue
        os           = "windows"
        scope        = $Scope
        target       = $Target
        metric_name  = $MetricName
        source_field = $SourceField
        value        = $normalizedValue
        unit         = $Unit
        status       = $Status
    }
}

function Write-MetricRows {
    param([object[]]$Rows)

    if ($null -eq $Rows -or $Rows.Count -eq 0) {
        return
    }
    if ($script:OutputInitialized) {
        $Rows | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8 -Append
    }
    else {
        $Rows | Export-Csv -LiteralPath $OutputFile -NoTypeInformation -Encoding UTF8
        $script:OutputInitialized = $true
    }
}

function Convert-BytesToMb {
    param([object]$Value)
    return [math]::Round(([double]$Value / 1048576), 2)
}

function Convert-KbToMb {
    param([object]$Value)
    return [math]::Round(([double]$Value / 1024), 2)
}

function Get-TargetProcesses {
    $candidateProcesses = @()
    if ($IncludeAllProcesses) {
        $candidateProcesses = @(Get-Process -ErrorAction SilentlyContinue)
    }
    elseif ($configuredProcessNames.Count -gt 0) {
        foreach ($name in $configuredProcessNames) {
            $candidateProcesses += @(Get-Process -Name $name -ErrorAction SilentlyContinue)
        }
    }

    $uniqueProcesses = @{}
    foreach ($process in $candidateProcesses) {
        if ($null -ne $process -and -not $uniqueProcesses.ContainsKey([int]$process.Id)) {
            $uniqueProcesses[[int]$process.Id] = $process
        }
    }
    return @($uniqueProcesses.Values)
}

function Add-ProcessPropertyMetric {
    param(
        [System.Collections.IList]$Rows,
        [System.Diagnostics.Process]$Process,
        [string]$Timestamp,
        [string]$Target,
        [string]$MetricName,
        [string]$SourceField,
        [string]$Unit,
        [scriptblock]$Transform
    )

    try {
        $rawValue = $Process.$SourceField
        if ($null -eq $rawValue) {
            throw "value is unavailable"
        }
        $value = & $Transform $rawValue
        $Rows.Add((New-MetricRow $Timestamp "process" $Target $MetricName $SourceField $value $Unit "ok")) | Out-Null
    }
    catch {
        $Rows.Add((New-MetricRow $Timestamp "process" $Target $MetricName $SourceField $null $Unit "读取失败")) | Out-Null
    }
}

function Add-ProcessMetrics {
    param(
        [System.Collections.IList]$Rows,
        [System.Diagnostics.Process]$Process,
        [string]$Timestamp,
        [hashtable]$PreviousCpu
    )

    $target = "{0}[{1}]" -f $Process.ProcessName, $Process.Id
    $mb = { param($value) Convert-BytesToMb $value }
    $integer = { param($value) [int64]$value }

    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "当前实际内存" "WorkingSet64" "MB" $mb
    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "当前独占内存" "PrivateMemorySize64" "MB" $mb
    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "当前虚拟内存" "VirtualMemorySize64" "MB" $mb
    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "历史最大实际内存" "PeakWorkingSet64" "MB" $mb
    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "历史最大虚拟内存" "PeakVirtualMemorySize64" "MB" $mb
    Add-ProcessPropertyMetric $Rows $Process $Timestamp $target "句柄数量" "Handles" "个" $integer

    try {
        $Rows.Add((New-MetricRow $Timestamp "process" $target "线程数量" "Threads.Count" ([int64]$Process.Threads.Count) "个" "ok")) | Out-Null
    }
    catch {
        $Rows.Add((New-MetricRow $Timestamp "process" $target "线程数量" "Threads.Count" $null "个" "读取失败")) | Out-Null
    }

    try {
        $cpuSeconds = [double]$Process.TotalProcessorTime.TotalSeconds
        if ($PreviousCpu.ContainsKey([int]$Process.Id)) {
            $cpuPercent = (($cpuSeconds - [double]$PreviousCpu[[int]$Process.Id]) / $IntervalSeconds / [Environment]::ProcessorCount) * 100
            $cpuPercent = [math]::Round([math]::Max(0, $cpuPercent), 2)
            $Rows.Add((New-MetricRow $Timestamp "process" $target "处理器使用率" "TotalProcessorTime" $cpuPercent "%" "ok")) | Out-Null
        }
        else {
            $Rows.Add((New-MetricRow $Timestamp "process" $target "处理器使用率" "TotalProcessorTime" $null "%" "需要下一次采样")) | Out-Null
        }
        $PreviousCpu[[int]$Process.Id] = $cpuSeconds
    }
    catch {
        $Rows.Add((New-MetricRow $Timestamp "process" $target "处理器使用率" "TotalProcessorTime" $null "%" "读取失败")) | Out-Null
    }
}

function Add-SystemMetrics {
    param([System.Collections.IList]$Rows, [string]$Timestamp)

    try {
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $totalMb = Convert-KbToMb $operatingSystem.TotalVisibleMemorySize
        $availableMb = Convert-KbToMb $operatingSystem.FreePhysicalMemory
        $usedMb = [math]::Round($totalMb - $availableMb, 2)
        $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "系统总内存" "TotalVisibleMemorySize" $totalMb "MB" "ok")) | Out-Null
        $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "当前已用内存" "TotalVisibleMemorySize-FreePhysicalMemory" $usedMb "MB" "ok")) | Out-Null
        $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "当前可用内存" "FreePhysicalMemory" $availableMb "MB" "ok")) | Out-Null
    }
    catch {
        $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "系统内存" "Win32_OperatingSystem" $null "MB" "读取失败")) | Out-Null
    }

    try {
        $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Where-Object { $null -ne $_.LoadPercentage })
        if ($processors.Count -gt 0) {
            $load = ($processors | Measure-Object -Property LoadPercentage -Average).Average
            $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "处理器使用率" "LoadPercentage" ([math]::Round([double]$load, 2)) "%" "ok")) | Out-Null
        }
        else {
            throw "processor load is unavailable"
        }
    }
    catch {
        $Rows.Add((New-MetricRow $Timestamp "system" $hostNameValue "处理器使用率" "Win32_Processor.LoadPercentage" $null "%" "读取失败")) | Out-Null
    }
}

$previousCpu = @{}
$sample = 0
while ($Samples -eq 0 -or $sample -lt $Samples) {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)
    $rows = New-Object System.Collections.Generic.List[object]
    Add-SystemMetrics $rows $timestamp

    $processes = @(Get-TargetProcesses)
    if ($processes.Count -eq 0) {
        if ($configuredProcessNames.Count -eq 0 -and -not $IncludeAllProcesses) {
            $rows.Add((New-MetricRow $timestamp "process" "" "进程采集结果" "process-list" $null "" "未配置进程名单")) | Out-Null
        }
        else {
            $rows.Add((New-MetricRow $timestamp "process" "" "进程采集结果" "process-list" $null "" "未找到匹配进程")) | Out-Null
        }
    }
    else {
        foreach ($process in $processes) {
            Add-ProcessMetrics $rows $process $timestamp $previousCpu
        }
    }

    Write-MetricRows @($rows)
    $sample++
    if ($Samples -eq 0 -or $sample -lt $Samples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}
