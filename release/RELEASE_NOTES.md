# Cline Termux Edition v__VERSION__

Cline CLI running natively on Termux (Android `aarch64`).

## What's included

- Cline CLI v__VERSION__ bundled for Termux
- One-line installer for downloading or upgrading the latest release
- Prebuilt runtime payload so users do not need to compile on-device

## Source Baseline

- Upstream repo: `cline/cline`
- Downstream repo: `NeroBlackstone/cline-termux`
- Release source commit: `__SOURCE_COMMIT__`
- Upstream reference: `__UPSTREAM_COMMIT__`

## Install

One-liner:

```bash
curl -fsSL https://github.com/NeroBlackstone/cline-termux/releases/latest/download/install-cline-termux.sh | bash
```

## Uninstall

```bash
curl -fsSL https://github.com/NeroBlackstone/cline-termux/releases/latest/download/uninstall-cline-termux.sh | bash
```

## Requirements

- Termux on Android (`aarch64`)
- Bun (installed automatically by installer or via `pkg install bun`)
- ripgrep (installed automatically or via `pkg install ripgrep`)

## Verify

```bash
cline --version
```

## Data Locations

| Path | Purpose |
|------|---------|
| `~/.cline-termux/v__VERSION__/` | Runtime payload for this release |
| `~/.cline-termux/current` | Symlink to active version |
| `~/.cline/` | User data, settings, API keys |
| `$PREFIX/bin/cline` | Global launcher |