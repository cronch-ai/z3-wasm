/** z3's answer to a query. Only `sat` carries information a caller should act on: a model. */
export type Checked =
	| { readonly result: "sat" | "unsat" | "unknown"; readonly reply: string }
	/** z3 reported an error before answering (`(error "...")`). */
	| { readonly result: "error"; readonly reply: string }
	/** The query or budget wasn't accepted; z3 never saw it. */
	| { readonly result: "refused"; readonly reason: string };

export interface Z3 {
	/**
	 * Run an SMT-LIB script and return z3's reply, synchronously. The budget is `rlimit`, z3's
	 * deterministic resource count. The script may set no options except
	 * `(set-option :produce-models true)`.
	 */
	check(text: string, options?: { readonly rlimit?: number }): Checked;
	/** The size of z3's WebAssembly memory now. */
	memoryBytes(): number;
}

/** Instantiate z3 from its bytes, or from a compiled module where bytes can't be compiled (a Worker). */
export function instantiate(
	source: BufferSource | WebAssembly.Module,
): Promise<Z3>;
