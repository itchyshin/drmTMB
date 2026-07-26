# Arc 6 F3 F1 deterministic-tail stop receipt

**Status:** STOPPED before F3 smoke (2026-07-26). This receipt records the
authorized F1 fixture implementation and focused run for the fixed-effect,
complete-pair Bernoulli × ordinary-NB2 `association = ~ 1` candidate. It is
negative deterministic evidence, not a public-inference, recovery, interval,
or capability claim.

## Frozen run identity

| Item | Value |
| --- | --- |
| Source preparation SHA | `6f31e482` |
| R runtime | 4.6.0 |
| Numerical packages | `mvtnorm` 1.4.1; `numDeriv` 2016.8.1.1 |
| Focused command | `devtools::load_all(); testthat::test_file("tests/testthat/test-associate-pairs-staged-sandwich.R")` |
| Focused suite result | PASS, including explicit negative-tail blocked controls |

## Matrix result

The new fixture covers `alpha = 0`, `-0.35`, `+0.35`, `+4`, and `+7` as
validated numerical-oracle controls. They passed at the already frozen
probability/gradient/Hessian tolerances. It separately records the two negative
tail controls so their failure cannot be mistaken for validation.

| Link value | Production result | Pinned-oracle result | F1 disposition |
| --- | --- | --- | --- |
| `-4` | log probability `-323.376379095663`; stable derivative status `ok` | log probability `-323.285855234021`; numerical Hessian non-finite | **STOP**: neither numerical agreement nor production unavailability. |
| `-7` | log probability `NA`; derivative status `unavailable/nonfinite_derivative` | log probability `-Inf` | Allowed fail-closed near-boundary control, but does not repair `-4`. |

The `-4` log-probability gap is about `0.090524`, far beyond the frozen
probability tolerance. No tolerance, start value, clamp, seed, or derivative
control was changed.

## Oracle-contract discrepancy

The F0 preparation text described an explicit `pmvnorm()` call with
`GenzBretz()`, `keepAttr = TRUE`, and `seed = NULL`. The executed helper still
calls `pmvnorm()` with its current package defaults rather than spelling those
arguments out. The default package formals currently select `GenzBretz()`, but
the executed call is not the fully explicit pinned call described in F0. This
is a documentary/fixture-contract discrepancy and is retained as part of the
stop; it is not silently repaired here.

## Gate disposition

Noether, Fisher, and Rose independently agreed that F1 is not a full
deterministic validation. The `-4` row is a finite production result without a
validating oracle and therefore fails the predeclared F1 gate. The F3 smoke
runner, full refits, bootstrap, profile, public methods, capability ledger,
Totoro/DRAC work, and all F4/F5 work were not started.

The next decision is not a retry: a future owner must choose and review either
an independent stable negative-tail oracle or a fail-closed production contract
for that regime, then obtain fresh authorization for a revised F1 matrix before
any F3 smoke is reconsidered.

> Related: [F0–F2 preparation receipt](2026-07-26-arc6-association-f0-f2-preparation-receipt.md) ·
> [public-inference ultra-plan](2026-07-26-arc6-association-public-inference-ultra-plan.md)
