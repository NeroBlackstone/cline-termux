#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Cline Termux Build Script
# Run this once on Termux to build Cline locally

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Increase Node memory limit for Android
export TERMUX_MAX_OLD_SPACE_SIZE=${TERMUX_MAX_OLD_SPACE_SIZE:-2048}
export NODE_OPTIONS="--max-old-space-size=$TERMUX_MAX_OLD_SPACE_SIZE"

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

cd "$REPO_ROOT/sdk"

# Check Bun is installed
if ! command -v bun >/dev/null 2>&1; then
	error "Bun not found. Install with: pkg install bun"
	exit 1
fi

info "Building Cline v3.x for Termux..."
info "NODE_OPTIONS=$NODE_OPTIONS"

# Clean previous build
if [ -d "node_modules" ]; then
	info "Skipping install (node_modules exists)..."
else
	info "Installing dependencies..."
	bun install
fi

info "Building SDK packages..."
bun run build:sdk

info "Building CLI..."
bun -F @cline/cli build

ok "Build complete!"
info "Run with: bun ./apps/cli/src/index.ts"
info "Or install with: ./release/install-from-built.sh"
