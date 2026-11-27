#!/usr/bin/env bash
# Install what building z3 needs, as pinned in versions.env: CMake and Ninja (into $TOOLS_DIR,
# default ~/.local, so no root is needed), and the emscripten SDK.
# The dev container runs this on creation, and CI runs it before building.
#
# emsdk goes to $EMSDK_DIR (default ~/emsdk). Use it with: source "$EMSDK_DIR/emsdk_env.sh"
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=../versions.env
. ./versions.env

EMSDK_DIR="${EMSDK_DIR:-$HOME/emsdk}"

TOOLS_DIR="${TOOLS_DIR:-$HOME/.local}"
export PATH="$TOOLS_DIR/bin:$PATH"
# CI's later steps need them on PATH too.
if [ -n "${GITHUB_PATH:-}" ]; then echo "$TOOLS_DIR/bin" >>"$GITHUB_PATH"; fi

case "$(uname -m)" in
  x86_64) ARCH=x86_64 CMAKE_SHA256=$CMAKE_SHA256_X86_64 NINJA_ZIP=ninja-linux.zip NINJA_SHA256=$NINJA_SHA256_X86_64 ;;
  aarch64 | arm64) ARCH=aarch64 CMAKE_SHA256=$CMAKE_SHA256_AARCH64 NINJA_ZIP=ninja-linux-aarch64.zip NINJA_SHA256=$NINJA_SHA256_AARCH64 ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TOOLS_DIR/bin"

if [ "$(ninja --version 2>/dev/null)" != "$NINJA_VERSION" ]; then
  curl -fsSL -o "$TMP/ninja.zip" \
    "https://github.com/ninja-build/ninja/releases/download/v$NINJA_VERSION/$NINJA_ZIP"
  echo "$NINJA_SHA256  $TMP/ninja.zip" | sha256sum -c -
  python3 -m zipfile -e "$TMP/ninja.zip" "$TMP/ninja"
  install -m 755 "$TMP/ninja/ninja" "$TOOLS_DIR/bin/ninja"
fi

if [ "$(cmake --version 2>/dev/null | head -1)" != "cmake version $CMAKE_VERSION" ]; then
  NAME="cmake-$CMAKE_VERSION-linux-$ARCH"
  curl -fsSL -o "$TMP/cmake.tar.gz" \
    "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/$NAME.tar.gz"
  echo "$CMAKE_SHA256  $TMP/cmake.tar.gz" | sha256sum -c -
  tar -xzf "$TMP/cmake.tar.gz" -C "$TMP"
  cp -r "$TMP/$NAME/bin" "$TMP/$NAME/share" "$TOOLS_DIR/"
fi

if [ ! -d "$EMSDK_DIR" ]; then
  git clone -q https://github.com/emscripten-core/emsdk.git "$EMSDK_DIR"
fi
git -C "$EMSDK_DIR" fetch -q --tags
git -C "$EMSDK_DIR" checkout -q "$EMSDK_VERSION"
"$EMSDK_DIR/emsdk" install "$EMSDK_VERSION"
"$EMSDK_DIR/emsdk" activate "$EMSDK_VERSION" >/dev/null

# Interactive shells in the dev container get emcc on their PATH.
if [ -n "${REMOTE_CONTAINERS:-}${CODESPACES:-}" ] && ! grep -q emsdk_env "$HOME/.bashrc"; then
  echo "export PATH=\"$TOOLS_DIR/bin:\$PATH\"" >>"$HOME/.bashrc"
  echo "source \"$EMSDK_DIR/emsdk_env.sh\" >/dev/null 2>&1" >>"$HOME/.bashrc"
fi

cmake --version | head -1
ninja --version
"$EMSDK_DIR/upstream/emscripten/emcc" --version | head -1
