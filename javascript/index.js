import initZ3 from "./z3.mjs";

/** The only option a query may set itself: the kernel's obligations ask for models. */
const ALLOWED_OPTIONS = new Set(["(set-option :produce-models true)"]);
const OPTION = /\(\s*set-option\b[^)]*\)/g;

/** The default budget, in z3's resource units: deterministic, unlike a timeout. */
const DEFAULT_RLIMIT = 5_000_000;

/**
 * Instantiate z3 from its bytes, or from a compiled module where bytes can't be compiled (a
 * Worker, importing `@cronch/z3/z3.wasm`).
 */
export async function instantiate(source) {
	const em = await initZ3({
		instantiateWasm(imports, receive) {
			if (source instanceof WebAssembly.Module) {
				WebAssembly.instantiate(source, imports).then((instance) =>
					receive(instance, source),
				);
			} else {
				WebAssembly.instantiate(source, imports).then(({ instance, module }) =>
					receive(instance, module),
				);
			}
			return {};
		},
		print: () => {},
		printErr: () => {},
	});

	return {
		check(text, { rlimit = DEFAULT_RLIMIT } = {}) {
			if (!Number.isSafeInteger(rlimit) || rlimit <= 0) {
				return {
					result: "refused",
					reason: "rlimit must be a positive integer",
				};
			}
			for (const [option] of text.matchAll(OPTION)) {
				if (!ALLOWED_OPTIONS.has(option.replace(/\s+/g, " "))) {
					return { result: "refused", reason: `option not allowed: ${option}` };
				}
			}
			// Our options first. The smt tactic keeps z3 off tactics that start timers.
			const query = `(set-option :tactic.default_tactic smt)\n(set-option :rlimit ${rlimit})\n${text}`;
			const cfg = em._Z3_mk_config();
			const ctx = em._Z3_mk_context(cfg);
			em._Z3_del_config(cfg);
			em._set_noop_error_handler(ctx);
			try {
				const reply = em.ccall(
					"Z3_eval_smtlib2_string",
					"string",
					["number", "string"],
					[ctx, query],
				);
				return answer(reply);
			} finally {
				em._Z3_del_context(ctx);
			}
		},

		memoryBytes() {
			return em.HEAPU8.buffer.byteLength;
		},
	};
}

/** z3's verdict on the first `check-sat`, and everything it replied. */
function answer(reply) {
	const lines = reply.split("\n").map((line) => line.trim());
	const first = lines.find((line) => line !== "") ?? "";
	if (first === "sat" || first === "unsat" || first === "unknown") {
		return { result: first, reply };
	}
	return { result: "error", reply };
}
