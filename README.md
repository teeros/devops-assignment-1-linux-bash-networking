# Assignment 1 — Linux, Bash & Networking

A small Linux diagnostic toolkit written in Bash. It collects system
information, checks disk usage against a threshold, and performs basic
network connectivity checks.

## Structure

```
assignment-1/
├── README.md
├── system-info.sh      # System information report
├── disk-check.sh        # Disk usage threshold check
├── network-check.sh     # Host/port connectivity check
├── grade.sh              # Instructor-supplied local grader
└── logs/                 # Timestamped run logs (created at runtime)
    └── .gitkeep
```

## Requirements

- A Linux environment with Bash (developed/tested on Ubuntu 22.04).
- Standard coreutils (`df`, `free`, `uname`, `hostname`, `whoami`, `date`).
- `ping`, `ip` (or `ifconfig`), and ideally `getent`/`dig`/`host` for full
  network functionality (falls back gracefully if some tools are missing).

## Installation / Setup

```bash
git clone <your-repository-url>
cd assignment-1
chmod +x *.sh
```

No other setup is required — everything is plain Bash with no external
dependencies beyond standard Linux utilities.

## Usage

### system-info.sh

```bash
./system-info.sh
```

Displays hostname, current user, date/time, OS, kernel version, uptime,
CPU information, memory information, and the current working directory.
All values are read live from the system at runtime.

### disk-check.sh

```bash
./disk-check.sh <threshold> [path]
```

- `threshold` — integer from 1 to 100 (percent), **required**.
- `path` — filesystem path to check, defaults to `/`.

Exit codes:
| Code | Meaning                                   |
|------|--------------------------------------------|
| 0    | Usage is below the threshold                |
| 1    | Usage is at or above the threshold          |
| 2    | Invalid input (missing/out-of-range/non-numeric threshold, or bad path) |

Example:

```bash
./disk-check.sh 80 /
```

### network-check.sh

```bash
./network-check.sh <hostname-or-ip> [port]
```

- Validates the host argument.
- Resolves the host and prints the resolved address (via `getent`, `dig`,
  `host`, or a Python fallback, in that order).
- Performs a basic ICMP `ping` connectivity check.
- Displays network interface information (`ip addr` / `ifconfig`).
- If a port is supplied, performs a TCP connectivity check using Bash's
  `/dev/tcp` pseudo-device. Valid ports are 1–65535.

Exit codes:
| Code | Meaning                                              |
|------|--------------------------------------------------------|
| 0    | Host resolved and all requested checks succeeded         |
| 1    | Host resolved but a connectivity/port check failed (operational) |
| 2    | Invalid input (missing host, bad host format, invalid port) |

Examples:

```bash
./network-check.sh example.com
./network-check.sh 8.8.8.8 443
```

## Logging

All three scripts append timestamped entries to their own log file under
`logs/` (`system-info.log`, `disk-check.log`, `network-check.log`), e.g.:

```
[2026-09-24 20:32:01] disk-check.sh: Checked path=/ threshold=80% usage=7%
```

## Testing

Run the supplied grader after making scripts executable:

```bash
chmod +x grade.sh *.sh
./grade.sh
```

`grade.sh` verifies required files, Bash syntax, executable permissions,
`system-info.sh` output content, `disk-check.sh` argument validation,
`network-check.sh` validation, logging, and basic Git history.

Scripts were also manually exercised inside a clean `ubuntu:22.04`
container to confirm behavior on a real Linux target (not just macOS).

## Assumptions

- `disk-check.sh` defaults to checking `/` when no path is given, per spec.
- Network validation accepts hostnames, IPv4, and IPv6-style addresses
  (letters, digits, `.`, `:`, `-`, `_`).
- `ping` failing (e.g. ICMP blocked by a firewall) is treated as an
  operational failure (exit 1), not an invalid-input error (exit 2).
- No secrets, tokens, or machine-specific hardcoded values are used —
  all values are derived at runtime.

## Git Workflow

This repository's history includes at least 5 meaningful commits, a
non-main feature branch per script, and merges of those branches into
`main`. See `git log --graph --oneline --all` for the full history.
