#!/usr/bin/env bash

set -euo pipefail

# Build Release Script for Cline v3.x Termux Edition
# This script is designed to run from a PC and build on a remote Termux device

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TERMUX_HOST="${TERMUX_HOST:-termux}"
TERMUX_REPO="${TERMUX_REPO:-~/workspace/cline-termux}"
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--termux-host)
			TERMUX_HOST="$2"
			shift 2
			;;
		--termux-repo)
			TERMUX_REPO="$2"
			shift 2
			;;
		--skip-build)
			SKIP_BUILD=true
			shift
			;;
		*)
			echo "Unknown option: $1" >&2
			exit 1
			;;
	esac
done

echo "=== Cline v3.x Termux Release Builder ==="
echo "Host: $TERMUX_HOST"
echo "Repo: $TERMUX_REPO"
echo

echo "Checking SSH connectivity to $TERMUX_HOST..."
ssh -o ConnectTimeout=5 "$TERMUX_HOST" "echo ok" >/dev/null

if [ "$SKIP_BUILD" = false ]; then
	echo "Building SDK and CLI on Termux..."
	# Build SDK first, then CLI
	ssh "$TERMUX_HOST" "cd $TERMUX_REPO/sdk && bun install && bun run build:sdk && bun -F @cline/cli build"
else
	echo "Skipping build. Verifying existing dist..."
	ssh "$TERMUX_HOST" "test -f $TERMUX_REPO/sdk/apps/cli/dist/index.js"
fi

echo "Assembling Termux bundle on device..."
ssh "$TERMUX_HOST" "cd $TERMUX_REPO && bash release/assemble-bundle-v3.sh"

VERSION=$(ssh "$TERMUX_HOST" "node -e \"console.log(JSON.parse(require('fs').readFileSync('$TERMUX_REPO/sdk/apps/cli/package.json', 'utf8')).version)\"")
RELEASE_NAME="cline-termux-aarch64-v${VERSION}"
LOCAL_DIST_DIR="$SCRIPT_DIR/dist"

mkdir -p "$LOCAL_DIST_DIR"

echo "Pulling release artifacts back to host..."
rsync -az "$TERMUX_HOST:$TERMUX_REPO/release/dist/${RELEASE_NAME}.tar.gz" "$LOCAL_DIST_DIR/"
rsync -az "$TERMUX_HOST:$TERMUX_REPO/release/dist/${RELEASE_NAME}.tar.gz.sha256" "$LOCAL_DIST_DIR/"

SOURCE_COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)
UPSTREAM_COMMIT=$(git -C "$REPO_ROOT" rev-parse --short cline/main 2>/dev/null || echo unknown)
NOTES_OUTPUT="$LOCAL_DIST_DIR/RELEASE_NOTES-v${VERSION}.md"

if [ -f "$SCRIPT_DIR/RELEASE_NOTES.md" ]; then
	node -e '
		const fs = require("fs")
		const [templatePath, outputPath, version, sourceCommit, upstreamCommit] = process.argv.slice(1)
		let text = fs.readFileSync(templatePath, "utf8")
		text = text.replaceAll("__VERSION__", version)
		text = text.replaceAll("__SOURCE_COMMIT__", sourceCommit)
		text = text.replaceAll("__UPSTREAM_COMMIT__", upstreamCommit)
		fs.writeFileSync(outputPath, text)
	' "$SCRIPT_DIR/RELEASE_NOTES.md" "$NOTES_OUTPUT" "$VERSION" "$SOURCE_COMMIT" "$UPSTREAM_COMMIT"
fi

echo
echo "Release bundle ready: $LOCAL_DIST_DIR/${RELEASE_NAME}.tar.gz"
echo "Checksum:             $LOCAL_DIST_DIR/${RELEASE_NAME}.tar.gz.sha256"
if [ -f "$NOTES_OUTPUT" ]; then
	echo "Release notes:        $NOTES_OUTPUT"
fi
echo
echo "Publish with:"
cat <<EOF
gh release create v${VERSION}-termux \
	$LOCAL_DIST_DIR/${RELEASE_NAME}.tar.gz \
	$LOCAL_DIST_DIR/${RELEASE_NAME}.tar.gz.sha256 \
	$SCRIPT_DIR/install-cline-termux.sh \
	--title "Cline Termux Edition v${VERSION}" \
	--notes-file $NOTES_OUTPUT
EOF
