# Cline Termux Edition - Release Procedure

## Overview

Cline v3.x uses a **Bun-based monorepo** structure. This document describes the updated build and release process for Termux.

## Key Differences from v2.x

| Component | v2.x (old) | v3.x (new) |
|-----------|------------|------------|
| Package Manager | npm | Bun |
| CLI Location | `cli/` | `sdk/apps/cli/` |
| Build System | esbuild | Bun + TypeScript |
| Entry Point | `dist/cli.mjs` | `dist/index.js` |
| Memory Limit | 2GB | 2GB (Android) |

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

### Option A: Full Build (Recommended first time)

```bash
cd ~/workspace/cline-termux
bash release/build-termux.sh
```

This will:
1. Install dependencies via `bun install`
2. Build SDK packages (`@cline/core`, `@cline/llms`, etc.)
3. Build CLI bundle to `sdk/apps/cli/dist/`

### Option B: Development Mode

```bash
cd sdk
bun install
bun run cli
```

## Install from Local Build

```bash
cd ~/workspace/cline-termux
bash release/install-from-built.sh
```

This will:
1. Copy the build to `~/.cline-termux/v<VERSION>/`
2. Create symlink at `~/.cline-termux/current`
3. Install launcher at `$PREFIX/bin/cline`

## Run

```bash
cline
# or
bun ~/.cline-termux/current/dist/index.js
```

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

```bash
cd release/dist
gh release create v<VERSION>-termux \
  cline-termux-aarch64-v<VERSION>.tar.gz \
  cline-termux-aarch64-v<VERSION>.tar.gz.sha256 \
  ../install-cline-termux.sh \
  --title "Cline Termux Edition v<VERSION>" \
  --notes-file RELEASE_NOTES-v<VERSION>.md
```

## End-User Install (from GitHub release)

```bash
curl -fsSL https://github.com/NeroBlackstone/cline-termux/releases/latest/download/install-cline-termux.sh | bash
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

### Build fails with native modules
```bash
# OpenTUI requires platform-specific binaries
# Install all variants:
bun install --os="*" --cpu="*" @opentui/core@<version>
```