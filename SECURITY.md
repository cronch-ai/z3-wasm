# Security

Report a vulnerability privately, through GitHub: **Security > Report a vulnerability** on this repo. Please don't open a public issue for it.

## What counts

Cronch never trusts z3's answers: an `unsat` is never a verdict, and every counterexample z3 finds is checked by the kernel. So a wrong answer from z3 is a bug, not a vulnerability. What counts:

- Input that escapes the Worker z3 runs in, or reads memory it shouldn't.
- A script option the wrapper should refuse getting through.
- Input that makes a check outrun its `rlimit` budget without bound.

If you're not sure whether something counts, report it privately anyway.
