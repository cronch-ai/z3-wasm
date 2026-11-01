# z3-wasm

[z3](https://github.com/Z3Prover/z3) built for Cloudflare Workers, as the npm package `@cronch/z3`. The [cronch platform](https://github.com/cronch-ai/platform) uses it to search for counterexamples to the kernel's induction obligations. z3's `unsat` is never taken as a verdict there; every counterexample z3 finds is checked by the kernel.

z3's own WebAssembly build targets browsers: it needs threads and reserves a fixed 2 GiB of memory, so it can't run in a Worker. This build differs:

- **Single-threaded:** `Z3_SINGLE_THREADED`, and timeouts poll instead of starting a timer thread (`Z3_POLLING_TIMER`).
- **Small, growable memory:** it starts at 32 MB and grows to at most 96 MB, under a Worker's 128 MB.
- **Synchronous:** it exports only the synchronous calls the wrapper uses, and an error handler that reports errors instead of exiting.
- **Budgeted by `rlimit`:** a Worker freezes its clock during synchronous work, so `:timeout` can't stop a solve. `rlimit`, z3's deterministic resource count, can.

## Use

```js
import { instantiate } from "@cronch/z3";
import wasm from "@cronch/z3/z3.wasm"; // a compiled module in a Worker; bytes in Node

const z3 = await instantiate(wasm);
z3.check(text, { rlimit: 5_000_000 }); // { result: "sat" | "unsat" | "unknown" | "error", reply } or { result: "refused", reason }
```

A script may set no options except `(set-option :produce-models true)`, which the kernel's obligations use. Any other option, such as `:timeout`, is refused.

## Development

The dev container installs everything the build needs: CMake, Ninja and the emscripten SDK, at the versions pinned in `versions.env` (see `scripts/install-toolchain.sh`).

```sh
source ~/emsdk/emsdk_env.sh
npm run build   # javascript/z3.mjs, z3.wasm, z3.sha256 (slow: it compiles z3)
npm test
npm run lint
```

CI caches the build until `versions.env`, `scripts/build.sh` or `src/` changes. A push to `main` that changes `javascript/package.json`'s version publishes a GitHub release with the npm tarball, `z3.wasm` and `z3.sha256`.
