#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Uninstall Cline from Termux

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_BASE="${HOME}/.cline-termux"
LAUNCHER_PATH="${PREFIX}/bin/cline"

# Colors
if [ -t 1 ]; then
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	NC='\033[0m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	NC=''
fi

info() { echo -e "${BLUE}[info]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }

info "Uninstalling Cline..."

# Remove installation directory
if [ -d "$INSTALL_BASE" ]; then
	info "Removing $INSTALL_BASE"
	rm -rf "$INSTALL_BASE"
	ok "Removed $INSTALL_BASE"
else
	warn "$INSTALL_BASE not found"
fi

# Remove launcher
if [ -f "$LAUNCHER_PATH" ]; then
	info "Removing launcher $LAUNCHER_PATH"
	rm -f "$LAUNCHER_PATH"
	ok "Removed $LAUNCHER_PATH"
else
	warn "$LAUNCHER_PATH not found"
fi

ok "Cline uninstalled successfully!"
info "Run 'pkg cleanup' to free up disk space"
