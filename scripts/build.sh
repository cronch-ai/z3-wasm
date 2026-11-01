#!/usr/bin/env bash
# Build z3 (versions.env) for WebAssembly, single-threaded, into javascript/: z3.mjs (the
# emscripten glue, an ES module), z3.wasm and z3.sha256. Needs emcc on PATH
# (scripts/install-toolchain.sh, then source "$EMSDK_DIR/emsdk_env.sh").
#
# Unlike z3's own WebAssembly build, which targets browsers:
# - no threads: Workers can't start them. z3's own threading is off (Z3_SINGLE_THREADED), and
#   timeouts poll instead of starting a timer thread (Z3_POLLING_TIMER).
# - memory starts small and grows to a maximum under a Worker's 128 MB, instead of a fixed 2 GiB.
# - only the synchronous calls the wrapper uses are exported.
# - native WebAssembly exceptions, which z3 needs internally.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=../versions.env
. ./versions.env

SRC=build/z3
OUT=javascript
FLAGS="-fwasm-exceptions"

if [ ! -d "$SRC" ]; then
  git clone -q --depth 1 --branch "$Z3_TAG" https://github.com/Z3Prover/z3.git "$SRC"
fi

emcmake cmake -S "$SRC" -B build/cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
  -DZ3_SINGLE_THREADED=ON \
  -DZ3_POLLING_TIMER=ON \
  -DZ3_BUILD_EXECUTABLE=OFF \
  -DZ3_BUILD_TEST_EXECUTABLES=OFF \
  -DZ3_INCLUDE_GIT_HASH=OFF \
  -DZ3_INCLUDE_GIT_DESCRIBE=OFF
cmake --build build/cmake --target libz3

EXPORTS='["_Z3_mk_config","_Z3_del_config","_Z3_mk_context","_Z3_del_context","_Z3_eval_smtlib2_string","_set_noop_error_handler"]'
em++ src/shim.cc build/cmake/libz3.a \
  -I "$SRC/src/api" -O3 $FLAGS \
  -sWASM_BIGINT \
  -sMODULARIZE -sEXPORT_ES6 -sEXPORT_NAME=initZ3 \
  -sENVIRONMENT=web \
  -sFILESYSTEM=0 \
  -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH -sMAXIMUM_MEMORY=96MB -sSTACK_SIZE=8MB \
  -sEXPORTED_FUNCTIONS="$EXPORTS" \
  -sEXPORTED_RUNTIME_METHODS='["ccall","HEAPU8"]' \
  -o "$OUT/z3.mjs"

(cd "$OUT" && sha256sum z3.wasm >z3.sha256)
ls -l "$OUT/z3.mjs" "$OUT/z3.wasm"
