# VPSBench

Simple, fast and accurate VPS benchmarking script.

VPSBench helps you quickly evaluate **CPU, Disk, Network, and Virtualization performance** with clean and easy-to-read output.

> Unlike traditional scripts, VPSBench focuses on real-world performance with mixed IO workloads and clear output.

---

## Quick Start

### One-line run (recommended)

```bash
curl -fsSL https://vpsbench.com/vpsbench.sh | bash
```

> ⚠️ For security, you may review the script before running.

---

## Features

### CPU Benchmark

* Single-core and multi-core performance (sysbench)
* Short and consistent test duration

### Disk Benchmark (fio)

* Mixed workload (`randrw`, 50/50)
* Block sizes: 4K / 64K / 512K / 1M
* Outputs:

  * Read IOPS
  * Write IOPS
  * Total IOPS (real-world performance indicator)

### Network Benchmark

* Multiple global test nodes:

  * Cloudflare (CDN baseline)
  * Seoul / Tokyo / Singapore (Asia)
  * Los Angeles / New York (US)
  * Frankfurt (EU)
* Measures real-world download throughput

### System Information

* CPU model, cores, frequency
* Memory and disk usage
* AES-NI support

### Virtualization Detection

* Virtualization type (KVM, Docker, etc.)
* Hardware support (VM-x / AMD-V)
* Nested virtualization detection

---

## Example Output

```
============================================================
                VPSBench v1.0.0
============================================================
  Benchmarking CPU, Disk, Network & Virtualization
------------------------------------------------------------
  Project   : https://vpsbench.com
============================================================

# System Information
------------------------------------------------------------
  OS                : Ubuntu 22.04 LTS
  Kernel            : 5.15.0-91-generic
  CPU               : AMD EPYC 7B13 Processor
  Cores/Freq        : 2 cores @ 3199 MHz
  RAM               : 2.0Gi (Used: 382Mi)
  Disk (/)          : 6.6G / 20G (36%)
  Virtualization    : kvm
  AES-NI            : ✔ Enabled
  Virt Support      : ✔ Enabled (VM-x/AMD-V)
  Nested Virt       : ✔ Enabled
  Uptime            : up 2 hours, 14 minutes

# CPU Benchmark
------------------------------------------------------------
  Single Core       : 1452.37 eps
  Multi Core        : 2789.81 eps

  → Single Core : Web / database responsiveness
  → Multi Core  : Parallel workloads

# Disk Benchmark (fio)
------------------------------------------------------------
  Block    | Read IOPS   | Write IOPS  | Total IOPS
------------------------------------------------------------
  4K       | 18342       | 17788       | 36130
  64K      | 5241        | 4980        | 10221
  512K     | 832         | 801         | 1633
  1M       | 410         | 395         | 805

  → Total : Mixed IO (real-world workload)
  → 4K    : Database / system responsiveness
  → 64K   : Typical application workload
  → 512K+ : Large file throughput

# Network Benchmark
------------------------------------------------------------
  Location           | Speed (Mbps)
------------------------------------------------------------
  Cloudflare         | 946.12
  CacheFly           | 932.55
  Tokyo              | 915.33
  Singapore          | 802.14
  Los Angeles        | 628.77
  New York           | 517.92
  Frankfurt          | 482.66

  → Cloudflare : CDN baseline
  → Regions    : Real-world routing performance

# Summary
------------------------------------------------------------
  CPU        : 1452 / 2789 eps
  Disk (4K)  : 36K IOPS
  Network    : 946 Mbps (Cloudflare)
  Virt       : KVM / Nested ✔

Completed in 27s
```

---

## Why VPSBench?

* Clean and structured output
* Focus on real-world performance
* Includes Total IOPS for disk testing
* Detects virtualization capabilities properly
* No unnecessary or misleading metrics

---

## Comparison

| Feature               | VPSBench       | Typical Scripts |
| --------------------- | -------------- | --------------- |
| Total IOPS (fio)      | ✔              | ✘               |
| Mixed IO workload     | ✔              | ✘               |
| Nested virtualization | ✔              | ✘               |
| Clean output          | ✔              | ✘               |

---

## What's New

* Added support for the ARM 64-bit (aarch64) architecture, so the benchmark now runs on ARM-based servers as well.
* Added a Seoul zone to the network test nodes for more accurate throughput measurements in the Korean region.

---

## Roadmap

* JSON output (machine-readable results)
* Benchmark scoring system
* Result sharing

---

## License

MIT License

---

## Support

If you find this project useful, consider giving it a star.