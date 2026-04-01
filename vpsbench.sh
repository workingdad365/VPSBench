#!/usr/bin/env bash
# ================================================================
# VPSBench v1.0.0
# Simple VPS Benchmark Script (CPU / Disk / Network / Virtualization)
#
# Project : https://vpsbench.com
# Source  : https://github.com/pandanetx/VPSBench
# License : MIT
# ================================================================

set -euo pipefail

VERSION="1.0.0"
START_TIME=$(date +%s)

WORK_DIR="/tmp/vpsbench_$(date +%s)"
mkdir -p "$WORK_DIR"
trap "rm -rf $WORK_DIR" EXIT

# ---------- Colors ----------
if [[ -t 1 ]]; then
    C='\033[1;36m'; NC='\033[0m'
else
    C=''; NC=''
fi

line(){ printf "%s\n" "$(printf '%.0s-' {1..60})"; }
kv(){ printf "  %-18s : %s\n" "$1" "$2"; }
section(){
    printf "\n${C}# %-50s${NC}\n" "$1"
    line
}

# ---------- Flag Format ----------
flag(){
    if [ "$1" = "1" ] || [ "$1" = "Enabled" ]; then
        echo "✔ Enabled"
    else
        echo "✘ Disabled"
    fi
}

# ---------- Install ----------
install(){
    if command -v apt >/dev/null; then
        apt update -y >/dev/null 2>&1
        apt install -y curl fio sysbench jq >/dev/null 2>&1
    elif command -v yum >/dev/null; then
        yum install -y curl fio sysbench jq >/dev/null 2>&1
    fi
}

# ---------- System ----------
sysinfo(){
    section "System Information"

    OS=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)
    KERNEL=$(uname -r)
    CPU=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
    CORES=$(nproc)

    CPU_MHZ=$(awk -F: '/cpu MHz/{s+=$2;n++} END{if(n) printf "%.0f",s/n}' /proc/cpuinfo)

    AES_FLAG=$(grep -q aes /proc/cpuinfo && echo 1 || echo 0)

    RAM=$(free -h | awk '/Mem:/ {printf "%s (Used: %s)", $2, $3}')
    DISK=$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3,$2,$5}')
    UPTIME=$(uptime -p 2>/dev/null || uptime)

    VMTYPE=$(systemd-detect-virt 2>/dev/null || echo "Dedicated")

    # ---- 虚拟化增强 ----
    VIRT_EXT=$(egrep -c '(vmx|svm)' /proc/cpuinfo || true)
    VIRT_STATUS=$( [ "$VIRT_EXT" -gt 0 ] && echo 1 || echo 0 )

    NESTED=$(grep -q "hypervisor" /proc/cpuinfo && [ "$VIRT_EXT" -gt 0 ] && echo 1 || echo 0)

    kv "OS" "$OS"
    kv "Kernel" "$KERNEL"
    kv "CPU" "$CPU"
    kv "Cores/Freq" "$CORES cores @ ${CPU_MHZ:-N/A} MHz"
    kv "RAM" "$RAM"
    kv "Disk (/)" "$DISK"
    kv "Virtualization" "$VMTYPE"
	kv "AES-NI" "$(flag $AES_FLAG)"
    kv "Virt Support" "$(flag $VIRT_STATUS) (VM-x/AMD-V)"
    kv "Nested Virt" "$(flag $NESTED)"
    kv "Uptime" "$UPTIME"
}

# ---------- CPU ----------
cpu_test(){
    section "CPU Benchmark"

    SINGLE=$(sysbench cpu --threads=1 --time=5 run 2>/dev/null | awk '/events per second/{print $4}')
    MULTI=$(sysbench cpu --threads=$(nproc) --time=5 run 2>/dev/null | awk '/events per second/{print $4}')

    kv "Single Core" "$SINGLE eps"
    kv "Multi Core" "$MULTI eps"

    echo
    echo "  → Single Core : Web / database responsiveness"
    echo "  → Multi Core  : Parallel workloads"
}

# ---------- Disk ----------
disk_test(){
    section "Disk Benchmark (fio)"

    printf "  %-8s | %-12s | %-12s | %-12s\n" "Block" "Read IOPS" "Write IOPS" "Total IOPS"
    line

    run_fio(){
        local bs="$1"
        local out="$WORK_DIR/fio_${bs}.json"

        fio --name=bench --rw=randrw --rwmixread=50 \
            --bs="$bs" --size=256M --runtime=6 \
            --time_based --group_reporting \
            --output-format=json > "$out" 2>/dev/null || return

        local r w t
        r=$(jq '.jobs[0].read.iops' "$out" | cut -d. -f1)
        w=$(jq '.jobs[0].write.iops' "$out" | cut -d. -f1)
        t=$((r + w))

        printf "  %-8s | %-12s | %-12s | %-12s\n" "$bs" "$r" "$w" "$t"
    }

    run_fio 4k
    run_fio 64k
    run_fio 512k
    run_fio 1m

    echo
    echo "  → Total : Mixed IO (real-world workload)"
    echo "  → 4K    : Database / system responsiveness"
    echo "  → 64K   : Typical application workload"
    echo "  → 512K+ : Large file throughput"
}

# ---------- Network ----------
net_test(){
    section "Network Benchmark"

    printf "  %-18s | %-12s\n" "Location" "Speed (Mbps)"
    line

    TMP_NET="$WORK_DIR/net.txt"
    : > "$TMP_NET"

    test_node(){
        local name="$1"
        local url="$2"

        local speed mbps
        speed=$(curl -o /dev/null -s --max-time 15 -w "%{speed_download}" "$url" || echo 0)
        mbps=$(awk "BEGIN{printf \"%.2f\", $speed*8/1000000}")

        echo "$name|$mbps" >> "$TMP_NET"
    }

    test_node "Cloudflare" "https://speed.cloudflare.com/__down?bytes=20000000" &
    test_node "CacheFly" "http://cachefly.cachefly.net/100mb.test" &
    test_node "Tokyo" "https://speedtest.tokyo2.linode.com/100MB-tokyo.bin" &
    test_node "Singapore" "https://speedtest.singapore.linode.com/100MB-singapore.bin" &
    test_node "Los Angeles" "https://la.speedtest.clouvider.net/1g.bin" &
    test_node "New York" "https://nyc.speedtest.clouvider.net/1g.bin" &
    test_node "Frankfurt" "https://fra.speedtest.clouvider.net/1g.bin" &

    wait

    while IFS="|" read -r name val; do
        printf "  %-18s | %-12s\n" "$name" "$val"
    done < "$TMP_NET"

    echo
    echo "  → Cloudflare : CDN baseline"
    echo "  → Regions    : Real-world routing performance"
}

# ---------- Main ----------
clear
clear
echo "============================================================"
echo "                VPSBench v$VERSION"
echo "============================================================"
echo "  Benchmarking CPU, Disk, Network & Virtualization"
echo "------------------------------------------------------------"
echo "  Project   : https://vpsbench.com"
echo "============================================================"

install
sysinfo
cpu_test
disk_test
net_test

END_TIME=$(date +%s)
echo
echo "Completed in $((END_TIME - START_TIME))s"