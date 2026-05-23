#!/usr/bin/env bash

set -euo pipefail

# Assemble Bundle Script for Cline v3.x Termux Edition
# Creates a distributable tarball with minimal files needed for installation

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$REPO_ROOT/sdk"
CLI_DIR="$SDK_DIR/apps/cli"

cd "$REPO_ROOT"

# Verify build exists
test -f "$CLI_DIR/dist/index.js" || {
	echo "ERROR: $CLI_DIR/dist/index.js not found. Build first with: bash release/build-termux.sh" >&2
	exit 1
}

# Get version
VERSION=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CLI_DIR/package.json', 'utf8')).version)")
SOURCE_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
RELEASE_NAME="cline-termux-v${VERSION}"
STAGE_DIR="$SCRIPT_DIR/staging/${RELEASE_NAME}"
DIST_DIR="$SCRIPT_DIR/dist"

echo "=== Assembling Cline Termux Edition v${VERSION} ==="

# Clean and create stage directory
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/dist" "$STAGE_DIR/runtime-files" "$DIST_DIR"

# Copy CLI build artifacts
echo "Copying CLI build..."
cp "$CLI_DIR/dist/index.js" "$STAGE_DIR/dist/"
if [ -d "$CLI_DIR/dist/extensions" ]; then
	cp -R "$CLI_DIR/dist/extensions" "$STAGE_DIR/dist/"
fi

# Copy standalone runtime files if they exist
if [ -d "$REPO_ROOT/standalone/runtime-files" ]; then
	cp -R "$REPO_ROOT/standalone/runtime-files/." "$STAGE_DIR/runtime-files/"
fi

# Create minimal package.json with runtime dependencies only
echo "Creating package.json with runtime dependencies..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$CLI_DIR/package.json', 'utf8'));
const deps = {...(pkg.dependencies||{}), ...(pkg.peerDependencies||{})};
const minimal = {
  name: 'cline-termux',
  version: '$VERSION',
  type: 'module',
  dependencies: deps
};
fs.writeFileSync('$STAGE_DIR/package.json', JSON.stringify(minimal, null, 2));
"

# Create VERSION file
cat > "$STAGE_DIR/VERSION" <<EOF
$VERSION
source-commit: $SOURCE_COMMIT
platform: termux-android
arch: aarch64
built: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Note: install.sh and uninstall.sh are distributed separately via GitHub Releases
# The tarball only contains the runtime files needed for installation



# Ensure CLI entry point is executable
chmod +x "$STAGE_DIR/dist/index.js"

# Create tarball
echo "Creating tarball..."
TARBALL="$DIST_DIR/${RELEASE_NAME}.tar.gz"
(
	cd "$STAGE_DIR/.."
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
