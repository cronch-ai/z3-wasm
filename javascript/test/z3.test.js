import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { instantiate } from "../index.js";

const z3 = await instantiate(
	readFileSync(new URL("../z3.wasm", import.meta.url)),
);
const fixture = (name) =>
	readFileSync(new URL(`fixtures/${name}.smt2`, import.meta.url), "utf8");

// Kernel obligations: consecution of an invariant, as a query whose models are counterexamples.
test("finds no counterexample to an inductive invariant", () => {
	assert.equal(z3.check(fixture("echo-once-true")).result, "unsat");
	assert.equal(z3.check(fixture("counting-ge-0")).result, "unsat");
});

test("finds a counterexample to one that isn't inductive", () => {
	const checked = z3.check(fixture("counting-le-1"));
	assert.equal(checked.result, "sat");
	assert.match(checked.reply, /\|q:state\|/);
});

test("stays within a Worker's memory", () => {
	assert.ok(z3.memoryBytes() <= 96 * 1024 * 1024, `${z3.memoryBytes()} bytes`);
});

test("runs out of budget instead of running on", () => {
	const hard = `(declare-fun f (Int) Int)
(assert (forall ((x Int)) (> (f x) (f (+ x 1)))))
(assert (> (f 0) 0))
(check-sat)`;
	assert.equal(z3.check(hard, { rlimit: 1000 }).result, "unknown");
});

test("refuses options other than models, and bad budgets", () => {
	assert.equal(
		z3.check("(set-option :timeout 1)\n(check-sat)").result,
		"refused",
	);
	assert.equal(
		z3.check("(set-option  :rlimit 0)\n(check-sat)").result,
		"refused",
	);
	assert.equal(z3.check("(check-sat)", { rlimit: 0 }).result, "refused");
});

test("reports SMT-LIB errors without dying", () => {
	assert.equal(z3.check("(assert x)\n(check-sat)").result, "error");
	assert.equal(z3.check("(check-sat)").result, "sat");
});
