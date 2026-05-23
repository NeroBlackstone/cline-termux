#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Install Cline from local build
# Run this after build-termux.sh completes

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$REPO_ROOT/sdk"
CLI_DIR="$SDK_DIR/apps/cli"
INSTALL_BASE="$HOME/.cline-termux"
LAUNCHER_PATH="$PREFIX/bin/cline"

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
die() { error "$@"; exit 1; }

info "Installing Cline from local build..."

# Check build exists
if [ ! -f "$CLI_DIR/dist/index.js" ]; then
	die "Build not found at $CLI_DIR/dist/index.js"
	die "Run ./release/build-termux.sh first"
fi

# Get version from package.json
VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CLI_DIR/package.json', 'utf8')).version)" 2>/dev/null || echo "unknown")

info "Cline version: $VERSION"

# Create install directory
TARGET_DIR="$INSTALL_BASE/v$VERSION"
if [ -d "$TARGET_DIR" ]; then
	warn "Replacing existing installation at $TARGET_DIR"
	rm -rf "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# Copy build artifacts
info "Copying build files..."
cp -R "$CLI_DIR/dist" "$TARGET_DIR/"

# Copy node_modules needed for runtime
info "Copying runtime dependencies..."

# Copy standalone runtime files
if [ -d "$REPO_ROOT/standalone/runtime-files" ]; then
	cp -R "$REPO_ROOT/standalone/runtime-files" "$TARGET_DIR/"
fi

# Copy node_modules from SDK (filtering to only runtime deps)
# For simplicity, we just copy the whole node_modules
# In production, you might want to prune dev dependencies
cp -R "$SDK_DIR/node_modules" "$TARGET_DIR/" 2>/dev/null || {
	warn "node_modules copy failed, trying alternative..."
	# Fallback: create minimal runtime environment
	mkdir -p "$TARGET_DIR/node_modules"
}

# Link ripgrep
mkdir -p "$TARGET_DIR/node_modules/@vscode/ripgrep/bin"
if command -v rg >/dev/null 2>&1; then
	ln -sf "$(command -v rg)" "$TARGET_DIR/node_modules/@vscode/ripgrep/bin/rg"
	ok "ripgrep linked"
else
	warn "ripgrep not found, installing..."
	pkg install -y ripgrep 2>/dev/null || true
	if command -v rg >/dev/null 2>&1; then
		mkdir -p "$TARGET_DIR/node_modules/@vscode/ripgrep/bin"
		ln -sf "$(command -v rg)" "$TARGET_DIR/node_modules/@vscode/ripgrep/bin/rg"
	fi
fi

# Update current symlink
rm -rf "$INSTALL_BASE/current"
ln -sf "$TARGET_DIR" "$INSTALL_BASE/current"

# Define CLINE_HOME for use in messages
CLINE_HOME="$INSTALL_BASE/current"

# Create launcher
info "Creating launcher at $LAUNCHER_PATH..."
mkdir -p "$PREFIX/bin"

cat > "$LAUNCHER_PATH" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash

CLINE_HOME="$HOME/.cline-termux/current"

if [ ! -f "$CLINE_HOME/dist/index.js" ]; then
	echo "Error: Cline not found at $CLINE_HOME" >&2
	echo "Run ./release/build-termux.sh first" >&2
	exit 1
fi

# Set memory limit for Android
export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=2048"

exec bun "$CLINE_HOME/dist/index.js" "$@"
LAUNCHER

chmod +x "$LAUNCHER_PATH"

# Create wrapper that uses bun directly
info "Note: Cline v3.x requires Bun to run"
info "Launcher configured to use: bun $CLINE_HOME/dist/index.js"

# Test installation
info "Testing installation..."
INSTALLED_VERSION=$("$LAUNCHER_PATH" --version 2>/dev/null || true)
if [ -n "$INSTALLED_VERSION" ]; then
	ok "cline --version -> $INSTALLED_VERSION"
else
	warn "Could not verify version. Try running: cline --version"
fi

ok "Cline v$VERSION installed successfully!"
ok "Run 'cline' to start"
