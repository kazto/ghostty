#!/usr/bin/env bash
# Builds ghostty for Windows inside an isolated Debian container, avoiding
# host glibc/gcc issues (e.g. Omarchy's bleeding-edge glibc emitting .sframe
# relocations that Zig 0.16.0's linker can't handle for native host tools).
#
# Usage: build-win.sh [path-to-ghostty-repo]
set -euo pipefail

REPO="${1:-$PWD}"
REPO="$(cd "$REPO" && pwd)"
IMAGE=ghostty-win-build
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build \
  --build-arg "UID=$(id -u)" \
  --build-arg "GID=$(id -g "$(id -un)")" \
  -t "$IMAGE" -f "$SCRIPT_DIR/Dockerfile.build-win" "$SCRIPT_DIR"

CACHE_DIR="$HOME/.cache/ghostty-docker-build/zig-cache"
mkdir -p "$CACHE_DIR"

docker run --rm \
  -v "$REPO:/src" \
  -v "$CACHE_DIR:/home/builder/.cache/zig" \
  -w /src \
  "$IMAGE" \
  zig build -Dtarget=x86_64-windows-gnu -Doptimize=ReleaseFast

TAG="nightly-$(date +%Y%m%d)"
ZIP="$REPO/ghostty-$TAG.zip"
rm -f "$ZIP"
zip -j "$ZIP" "$REPO/zig-out/bin/ghostty.exe" "$REPO/zig-out/bin/ghostty-vt.dll"
echo "Built: $ZIP"
