#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Install Cline from GitHub Releases
# Downloads and installs the latest release

GITHUB_REPO="NeroBlackstone/cline-termux"
INSTALL_BASE="${HOME}/.cline-termux"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
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
die() { error "$@"; exit 1; }

info "Installing Cline from GitHub Releases..."

# Check bun is installed
command -v bun >/dev/null 2>&1 || die "Bun not found. Run: pkg install bun"

# Fetch latest release info
info "Fetching latest release from GitHub..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$GITHUB_REPO/releases/latest") \
	|| die "Failed to fetch release info from GitHub."

VERSION=$(echo "$RELEASE_JSON" | node -e '
	const data = JSON.parse(require("fs").readFileSync(0, "utf8"));
	const tag = data.tag_name || "";
	console.log(tag.replace(/^v/, ""));
' 2>/dev/null) || die "Failed to parse release version."

TARBALL_NAME="cline-termux-v${VERSION}.tar.gz"
TARBALL_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${TARBALL_NAME}"

info "Cline version: $VERSION"
info "Downloading $TARBALL_NAME..."

DOWNLOAD_DIR=$(mktemp -d)
curl -fSL -o "${DOWNLOAD_DIR}/${TARBALL_NAME}" "$TARBALL_URL" \
	|| die "Failed to download release bundle."

# Extract
info "Extracting..."
tar -xzf "${DOWNLOAD_DIR}/${TARBALL_NAME}" -C "$DOWNLOAD_DIR"

# Extract creates cline-termux-v${VERSION}/ directory
SOURCE_DIR="$DOWNLOAD_DIR/cline-termux-v${VERSION}"
[ -d "$SOURCE_DIR" ] || die "Could not find extracted bundle directory."

# Create install directory
TARGET_DIR="$INSTALL_BASE/v$VERSION"
if [ -d "$TARGET_DIR" ]; then
	warn "Replacing existing installation at $TARGET_DIR"
	rm -rf "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# Copy dist
info "Copying dist..."
cp -R "$SOURCE_DIR/dist" "$TARGET_DIR/"

# Copy package.json
if [ -f "$SOURCE_DIR/package.json" ]; then
	info "Copying package.json..."
	cp "$SOURCE_DIR/package.json" "$TARGET_DIR/"
fi

# Install dependencies with bun
info "Installing dependencies..."
cd "$TARGET_DIR"
bun install || {
	error "bun install failed"
	exit 1
}
cd - > /dev/null

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
		ok "ripgrep linked"
	fi
fi

# Update current symlink
rm -rf "$INSTALL_BASE/current"
ln -sf "$TARGET_DIR" "$INSTALL_BASE/current"

# Create launcher
info "Creating launcher at $LAUNCHER_PATH..."
mkdir -p "$PREFIX/bin"

cat > "$LAUNCHER_PATH" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash

CLINE_HOME="$HOME/.cline-termux/current"

if [ ! -f "$CLINE_HOME/dist/index.js" ]; then
	echo "Error: Cline not found at $CLINE_HOME" >&2
	echo "Run install-cline-termux.sh first" >&2
	exit 1
fi

# Set memory limit for Android
export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=2048"

exec bun "$CLINE_HOME/dist/index.js" "$@"
LAUNCHER

chmod +x "$LAUNCHER_PATH"

# Cleanup
rm -rf "$DOWNLOAD_DIR"

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
