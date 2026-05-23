#!/data/data/com.termux/files/usr/bin/bash

set -euo pipefail

# Assemble Bundle Script for Cline v3.x Termux Edition
# Creates a distributable tarball with all dependencies

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# Verify build exists
test -f "sdk/apps/cli/dist/index.js" || {
	echo "ERROR: sdk/apps/cli/dist/index.js not found. Build first with: bash release/build-termux.sh" >&2
	exit 1
}

test -d "sdk/node_modules" || {
	echo "ERROR: sdk/node_modules not found. Run 'bun install' first." >&2
	exit 1
}

# Get version from CLI package.json
VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('sdk/apps/cli/package.json', 'utf8')).version)")
SOURCE_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
RELEASE_NAME="cline-termux-aarch64-v${VERSION}"
STAGE_DIR="$SCRIPT_DIR/staging/${RELEASE_NAME}"
DIST_DIR="$SCRIPT_DIR/dist"

echo "=== Assembling Cline Termux Edition v${VERSION} ==="

# Clean and create stage directory
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/dist" "$STAGE_DIR/runtime-files" "$DIST_DIR"

# Copy CLI build artifacts
echo "Copying CLI build..."
cp "sdk/apps/cli/dist/index.js" "$STAGE_DIR/dist/"
if [ -d "sdk/apps/cli/dist/extensions" ]; then
	cp -R "sdk/apps/cli/dist/extensions" "$STAGE_DIR/dist/"
fi

# Copy standalone runtime files if they exist
if [ -d "standalone/runtime-files" ]; then
	cp -R "standalone/runtime-files/." "$STAGE_DIR/runtime-files/"
fi

# Copy required node_modules packages
echo "Resolving runtime dependencies..."
mkdir -p "$STAGE_DIR/node_modules"

# Core packages that must be bundled
CORE_PACKAGES=(
	"@opentui/core"
	"@opentui/react"
	"@opentui-ui/dialog"
	"opentui-spinner"
	"react"
	"react/jsx-runtime"
	"react/jsx-dev-runtime"
	"react-devtools-core"
	"@cline/core"
	"@cline/llms"
	"@cline/sdk"
	"@cline/shared"
	"@cline/agents"
	"chalk"
	"commander"
	"pino"
	"pino-roll"
	"prompts"
	"nanoid"
	"ora"
	"aws4fetch"
)

for pkg in "${CORE_PACKAGES[@]}"; do
	if [ -d "sdk/node_modules/$pkg" ]; then
		echo "  Including $pkg"
		cp -R "sdk/node_modules/$pkg" "$STAGE_DIR/node_modules/"
	fi
done

# Copy vscode-ripgrep
if [ -d "sdk/node_modules/@vscode/ripgrep" ]; then
	cp -R "sdk/node_modules/@vscode/ripgrep" "$STAGE_DIR/node_modules/"
fi

# Create minimal package.json for the bundle
cat > "$STAGE_DIR/package.json" <<EOF
{
  "name": "cline-termux-edition",
  "version": "$VERSION",
  "type": "module",
  "bin": { "cline": "./dist/index.js" },
  "os": ["android"],
  "cpu": ["arm64"],
  "engines": { "node": ">=22" }
}
EOF

# Create VERSION file
cat > "$STAGE_DIR/VERSION" <<EOF
$VERSION
source-commit: $SOURCE_COMMIT
platform: termux-android
arch: aarch64
built: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Copy install script
cp "$SCRIPT_DIR/install-cline-termux.sh" "$STAGE_DIR/install.sh"
chmod +x "$STAGE_DIR/install.sh"

# Ensure CLI entry point is executable
chmod +x "$STAGE_DIR/dist/index.js"

# Create tarball
echo "Creating tarball..."
TARBALL="$DIST_DIR/${RELEASE_NAME}.tar.gz"
(
	cd "$SCRIPT_DIR/staging"
	tar czf "$TARBALL" "$RELEASE_NAME"
)

# Calculate checksum
(
	cd "$DIST_DIR"
	sha256sum "${RELEASE_NAME}.tar.gz" > "${RELEASE_NAME}.tar.gz.sha256"
)

echo
echo "Tarball:  $TARBALL"
echo "Checksum: $DIST_DIR/${RELEASE_NAME}.tar.gz.sha256"
echo "Done!"
