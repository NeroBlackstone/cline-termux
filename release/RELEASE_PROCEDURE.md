# Cline Termux Edition - Release Procedure

## Overview

Cline Termux Edition is built using a **Bun-based monorepo**. This document describes the build and release process.

## Prerequisites

### Termux Environment
```bash
pkg update && pkg upgrade
pkg install bun ripgrep
```

### Clone this repository on Termux
```bash
cd ~/workspace
git clone https://github.com/NeroBlackstone/cline-termux.git
cd cline-termux
```

## Build (Local on Termux)

### Full Build

```bash
cd ~/workspace/cline-termux
bash release/build-termux.sh
```

This will:
1. Install dependencies via `bun install`
2. Build SDK packages (`@cline/core`, `@cline/llms`, etc.)
3. Build CLI bundle to `sdk/apps/cli/dist/`

## Assemble Release Package

```bash
cd ~/workspace/cline-termux
bash release/assemble-bundle.sh
```

This creates `release/dist/cline-termux-v<VERSION>.tar.gz`.

## Full Release Build and Distribution (PC)

For building distributable `.tar.gz` packages on a PC (requires Termux environment):

```bash
cd /path/to/cline-termux

# Sync with upstream cline
git fetch cline
git rebase cline/main

# Build on Termux device via SSH
bash release/build-release.sh --termux-host termux-device --termux-repo ~/workspace/cline-termux

# The release tarball will be in release/dist/
```

## Publish to GitHub

Upload these files to GitHub Release:

```
cline-termux-v<VERSION>.tar.gz
install-cline-termux.sh
uninstall-cline-termux.sh
```

## End-User Install (from GitHub release)

```bash
curl -fsSL https://github.com/NeroBlackstone/cline-termux/releases/latest/download/install-cline-termux.sh | bash
```

## Uninstall

```bash
curl -fsSL https://github.com/NeroBlackstone/cline-termux/releases/latest/download/uninstall-cline-termux.sh | bash
```

## Run

```bash
cline
```

## Install Layout

| Path | Purpose |
|------|---------|
| `~/.cline-termux/v<VERSION>/` | Versioned runtime payload |
| `~/.cline-termux/current` | Symlink to active version |
| `$PREFIX/bin/cline` | Global launcher (runs via Bun) |
| `~/.cline/` | User data preserved across upgrades |

## Troubleshooting

### Out of Memory
```bash
export TERMUX_MAX_OLD_SPACE_SIZE=1024  # Reduce if experiencing OOM
bash release/build-termux.sh
```

### Bun not found
```bash
pkg install bun
```

### ripgrep not found
```bash
pkg install ripgrep
```