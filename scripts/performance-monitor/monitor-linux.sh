#!/bin/sh

# Generic Linux performance detector.
# Use -p to define one or more processes, or -a to explicitly select all processes.

set -u

INTERVAL=5
SAMPLES=1
OUTPUT_DIR="."
PROCESS_NAMES=""
ALL_PROCESSES=0
PROC_ROOT="/proc"
HOSTNAME_VALUE=$(hostname 2>/dev/null || uname -n)
HEADER='"timestamp","hostname","os","scope","target","metric_name","source_field","value","unit","status"'
PREVIOUS_CPU_TOTAL=""
PREVIOUS_CPU_IDLE=""

usage() {
    cat <<'EOF'
Usage: monitor-linux.sh [options]

  -p name1,name2  monitor exact process names
  -p name         may be repeated for additional processes
  -a              explicitly monitor all readable processes
  -i seconds      sampling interval, default 5
  -n samples      sample count, default 1; 0 means continuous
  -o directory    output directory, default .
  -r proc-root    alternate /proc root for tests
  -h              show this help
EOF
}

die() {
    printf '%s\n' "monitor-linux.sh: $1" >&2
    exit 2
}

csv_field() {
    printf '"%s"' "$(printf '%s' "$1" | sed 's/"/""/g')"
}

emit_metric() {
    {
        csv_field "$1"
        printf ','
        csv_field "$HOSTNAME_VALUE"
        printf ','
        csv_field "linux"
        printf ','
        csv_field "$2"
        printf ','
        csv_field "$3"
        printf ','
        csv_field "$4"
        printf ','
        csv_field "$5"
        printf ','
        csv_field "$6"
        printf ','
        csv_field "$7"
        printf ','
        csv_field "$8"
        printf '\n'
    } >>"$OUTPUT"
}

read_mem_kb() {
    awk -v key="$1:" '$1 == key {print $2; exit}' "$PROC_ROOT/meminfo" 2>/dev/null
}

read_status_value() {
    awk -v key="$2:" '$1 == key {print $2; exit}' "$PROC_ROOT/$1/status" 2>/dev/null
}

to_mb() {
    [ -n "$1" ] || return 1
    awk -v raw="$1" 'BEGIN {
        if (raw !~ /^[0-9]+([.][0-9]+)?$/) exit 1
        printf "%.2f", raw / 1024
    }'
}

emit_kb_metric() {
    scope=$1
    target=$2
    metric_name=$3
    source_field=$4
    raw_value=$5

    if [ -n "$raw_value" ]; then
        value=$(to_mb "$raw_value" 2>/dev/null) || value=""
        if [ -n "$value" ]; then
            emit_metric "$TIMESTAMP" "$scope" "$target" "$metric_name" "$source_field" "$value" "MB" "ok"
            return
        fi
    fi
    emit_metric "$TIMESTAMP" "$scope" "$target" "$metric_name" "$source_field" "" "MB" "读取失败"
}

process_matches() {
    process_name=$1
    [ "$ALL_PROCESSES" -eq 1 ] && return 0
    [ -n "$PROCESS_NAMES" ] || return 1

    saved_ifs=$IFS
    IFS=,
    for wanted_name in $PROCESS_NAMES; do
        if [ "$process_name" = "$wanted_name" ]; then
            IFS=$saved_ifs
            return 0
        fi
    done
    IFS=$saved_ifs
    return 1
}

collect_system_memory() {
    total_kb=$(read_mem_kb MemTotal)
    available_kb=$(read_mem_kb MemAvailable)

    if [ -z "$available_kb" ]; then
        free_kb=$(read_mem_kb MemFree)
        buffers_kb=$(read_mem_kb Buffers)
        cached_kb=$(read_mem_kb Cached)
        if [ -n "$free_kb" ] && [ -n "$buffers_kb" ] && [ -n "$cached_kb" ]; then
            available_kb=$((free_kb + buffers_kb + cached_kb))
        fi
    fi

    emit_kb_metric system "$HOSTNAME_VALUE" "系统总内存" "MemTotal" "$total_kb"
    emit_kb_metric system "$HOSTNAME_VALUE" "当前可用内存" "MemAvailable" "$available_kb"
    if [ -n "$total_kb" ] && [ -n "$available_kb" ]; then
        used_kb=$((total_kb - available_kb))
        [ "$used_kb" -ge 0 ] || used_kb=0
        emit_kb_metric system "$HOSTNAME_VALUE" "当前已用内存" "MemTotal-MemAvailable" "$used_kb"
    else
        emit_kb_metric system "$HOSTNAME_VALUE" "当前已用内存" "MemTotal-MemAvailable" ""
    fi

    emit_kb_metric system "$HOSTNAME_VALUE" "文件缓存内存" "Cached" "$(read_mem_kb Cached)"
    emit_kb_metric system "$HOSTNAME_VALUE" "内核对象缓存" "Slab" "$(read_mem_kb Slab)"
    emit_kb_metric system "$HOSTNAME_VALUE" "交换区总量" "SwapTotal" "$(read_mem_kb SwapTotal)"
    emit_kb_metric system "$HOSTNAME_VALUE" "交换区可用量" "SwapFree" "$(read_mem_kb SwapFree)"
}

collect_processes() {
    found=0

    for proc_dir in "$PROC_ROOT"/[0-9]*; do
        [ -d "$proc_dir" ] || continue
        pid=${proc_dir##*/}
        [ -r "$proc_dir/comm" ] || continue
        process_name=$(cat "$proc_dir/comm" 2>/dev/null)
        [ -n "$process_name" ] || continue
        process_matches "$process_name" || continue

        found=1
        target="${process_name}[${pid}]"
        emit_metric "$TIMESTAMP" process "$target" "进程 ID" "pid" "$pid" "个" "ok"
        emit_kb_metric process "$target" "当前虚拟内存" "VmSize" "$(read_status_value "$pid" VmSize)"
        emit_kb_metric process "$target" "历史最大虚拟内存" "VmPeak" "$(read_status_value "$pid" VmPeak)"
        emit_kb_metric process "$target" "当前实际内存" "VmRSS" "$(read_status_value "$pid" VmRSS)"
        emit_kb_metric process "$target" "历史最大实际内存" "VmHWM" "$(read_status_value "$pid" VmHWM)"

        threads=$(read_status_value "$pid" Threads)
        if [ -n "$threads" ]; then
            emit_metric "$TIMESTAMP" process "$target" "线程数量" "Threads" "$threads" "个" "ok"
        else
            emit_metric "$TIMESTAMP" process "$target" "线程数量" "Threads" "" "个" "读取失败"
        fi
    done

    if [ "$found" -eq 0 ]; then
        if [ "$ALL_PROCESSES" -eq 1 ]; then
            status="没有可读取的进程"
        elif [ -z "$PROCESS_NAMES" ]; then
            status="未配置进程名单"
        else
            status="未找到匹配进程"
        fi
        emit_metric "$TIMESTAMP" process "" "进程采集结果" "process-list" "" "" "$status"
    fi
}

read_cpu_stat() {
    awk '$1 == "cpu" {
        total = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10 + $11
        idle = $5 + $6
        printf "%.0f %.0f\n", total, idle
        exit
    }' "$PROC_ROOT/stat" 2>/dev/null
}

collect_cpu() {
    cpu_values=$(read_cpu_stat)
    current_total=${cpu_values%% *}
    current_idle=${cpu_values#* }

    if [ -z "$cpu_values" ] || [ "$current_total" = "$cpu_values" ]; then
        emit_metric "$TIMESTAMP" system "$HOSTNAME_VALUE" "处理器使用率" "/proc/stat" "" "%" "读取失败"
    elif [ -n "$PREVIOUS_CPU_TOTAL" ] && [ "$current_total" -gt "$PREVIOUS_CPU_TOTAL" ]; then
        cpu_value=$(awk -v total="$current_total" -v idle="$current_idle" \
            -v old_total="$PREVIOUS_CPU_TOTAL" -v old_idle="$PREVIOUS_CPU_IDLE" \
            'BEGIN {
                total_delta = total - old_total
                idle_delta = idle - old_idle
                if (total_delta <= 0) exit 1
                printf "%.2f", 100 * (total_delta - idle_delta) / total_delta
            }' 2>/dev/null) || cpu_value=""
        if [ -n "$cpu_value" ]; then
            emit_metric "$TIMESTAMP" system "$HOSTNAME_VALUE" "处理器使用率" "/proc/stat" "$cpu_value" "%" "ok"
        else
            emit_metric "$TIMESTAMP" system "$HOSTNAME_VALUE" "处理器使用率" "/proc/stat" "" "%" "计算失败"
        fi
    else
        emit_metric "$TIMESTAMP" system "$HOSTNAME_VALUE" "处理器使用率" "/proc/stat" "" "%" "需要下一次采样"
    fi

    PREVIOUS_CPU_TOTAL=$current_total
    PREVIOUS_CPU_IDLE=$current_idle
}

while getopts 'p:i:n:o:r:ah' option; do
    case "$option" in
        p)
            if [ -n "$PROCESS_NAMES" ]; then
                PROCESS_NAMES="$PROCESS_NAMES,$OPTARG"
            else
                PROCESS_NAMES=$OPTARG
            fi
            ;;
        i) INTERVAL=$OPTARG ;;
        n) SAMPLES=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        r) PROC_ROOT=$OPTARG ;;
        a) ALL_PROCESSES=1 ;;
        h)
            usage
            exit 0
            ;;
        \?)
            usage >&2
            exit 2
            ;;
    esac
done

case "$INTERVAL" in '' | *[!0-9]*) die "interval must be a positive integer" ;; esac
case "$SAMPLES" in '' | *[!0-9]*) die "samples must be a non-negative integer" ;; esac
[ "$INTERVAL" -ge 1 ] || die "interval must be at least 1 second"
[ "$ALL_PROCESSES" -eq 1 ] || [ -n "$PROCESS_NAMES" ] || die "process definition is required; use -p name1,name2 or -a"
[ "$ALL_PROCESSES" -eq 0 ] || [ -z "$PROCESS_NAMES" ] || die "use either -p or -a, not both"
if [ -n "$PROCESS_NAMES" ]; then
    case ",$PROCESS_NAMES," in *,,*) die "process names must not be empty" ;; esac
fi
[ -d "$PROC_ROOT" ] || die "proc root does not exist: $PROC_ROOT"
[ -r "$PROC_ROOT/meminfo" ] || die "cannot read $PROC_ROOT/meminfo"
[ -r "$PROC_ROOT/stat" ] || die "cannot read $PROC_ROOT/stat"

mkdir -p "$OUTPUT_DIR" || die "cannot create output directory: $OUTPUT_DIR"

if [ "$ALL_PROCESSES" -eq 1 ]; then
    process_label="all-processes"
else
    process_label=$(printf '%s' "$PROCESS_NAMES" | tr ',' '-')
    process_label=$(printf '%s' "$process_label" | sed -e 's/[^A-Za-z0-9._-]/-/g' -e 's/--*/-/g' -e 's/^-*//' -e 's/-*$//')
    [ -n "$process_label" ] || process_label="processes"
fi

file_timestamp=$(date -u '+%Y%m%d_%H%M%S')
file_stem="${process_label}_${file_timestamp}"
OUTPUT="$OUTPUT_DIR/${file_stem}.csv"
suffix=1
while [ -e "$OUTPUT" ]; do
    OUTPUT="$OUTPUT_DIR/${file_stem}_${suffix}.csv"
    suffix=$((suffix + 1))
done

printf '%s\n' "$HEADER" >"$OUTPUT" || die "cannot write output: $OUTPUT"

sample=0
while :; do
    TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    collect_system_memory
    collect_cpu
    collect_processes

    sample=$((sample + 1))
    if [ "$SAMPLES" -ne 0 ] && [ "$sample" -ge "$SAMPLES" ]; then
        break
    fi
    sleep "$INTERVAL"
done
