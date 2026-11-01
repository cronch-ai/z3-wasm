#!/usr/bin/env bash
# Install what building z3 needs, as pinned in versions.env: CMake (into /usr/local), Ninja,
# and the emscripten SDK.
# The dev container runs this on creation, and CI runs it before building.
#
# emsdk goes to $EMSDK_DIR (default ~/emsdk). Use it with: source "$EMSDK_DIR/emsdk_env.sh"
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=../versions.env
. ./versions.env

EMSDK_DIR="${EMSDK_DIR:-$HOME/emsdk}"

if ! command -v ninja >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq ninja-build
fi

if [ "$(cmake --version 2>/dev/null | head -1)" != "cmake version $CMAKE_VERSION" ]; then
  case "$(uname -m)" in
    x86_64) ARCH=x86_64 SHA256=$CMAKE_SHA256_X86_64 ;;
    aarch64 | arm64) ARCH=aarch64 SHA256=$CMAKE_SHA256_AARCH64 ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  NAME="cmake-$CMAKE_VERSION-linux-$ARCH"
  curl -fsSL -o "$TMP/cmake.tar.gz" \
    "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/$NAME.tar.gz"
  echo "$SHA256  $TMP/cmake.tar.gz" | sha256sum -c -
  tar -xzf "$TMP/cmake.tar.gz" -C "$TMP"
  sudo cp -r "$TMP/$NAME/bin" "$TMP/$NAME/share" /usr/local/
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
  echo "source \"$EMSDK_DIR/emsdk_env.sh\" >/dev/null 2>&1" >>"$HOME/.bashrc"
fi

cmake --version | head -1
"$EMSDK_DIR/upstream/emscripten/emcc" --version | head -1
