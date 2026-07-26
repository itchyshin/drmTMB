# Arc 6 F1D derivative-oracle receipt — STOPPED

**Date:** 2026-07-26
**Scope:** private fixed-effect complete-pair Bernoulli × ordinary-NB2 staged association kernel only.
**Base:** `5974b1ad` (K1 tail-orientation repair).

## Contract and matrix

The test-only independent route uses local log-CDF/log-survival NB2 endpoints,
latent-normal `z` integration, 256/512/1024-node fixed Gauss--Legendre
quadrature, and independently written centred full 4 × 4 Hessian stencils. It
does not call the production endpoint helper, CDF-scale rectangle integrator,
or production derivative helper.

The elementwise node contract is `abs(left - right) <= pmax(1e-8,
2e-10 * pmax(1, abs(left), abs(right)))` for the point, four gradient
coordinates, and sixteen Hessian coordinates.

| Row | Point log probability | 256→512 / 512→1024 max standardized drift | Test-only result |
| --- | ---: | ---: | --- |
| `a = 0.22`, `B = 1`, `NB2 = 3` | -2.8578885784056123 | 0.9094947 / 0.4547474 | `F1D_pass` |
| `a = -4`, `B = 1`, `NB2 = 3` | -323.28585523376535 | 3.637979 / 3.637979 | `independent_step_unstable` |
| `a = +4`, `B = 0`, `NB2 = 3` | -95.223207552410969 | 10.91394 / 1.238819 | `independent_step_unstable` |
| `a = -7`, `B = 1`, `NB2 = 3` | unavailable | n/a | retained existing unavailable control |

At `a = -4`, 256→512 fails at `lambda_b_lambda_b` (drift
`1.4551915e-07`; tolerance `5.439660e-08`) plus four `3.637979e-08` cross
coordinates with `1e-08` tolerance; 512→1024 repeats the
`lambda_b_lambda_b` failure plus two of those cross coordinates. At the
sign/outcome mirror, 256→512 fails at `a_a` (`7.275958e-08` versus
`6.754497e-08`), `lambda_b_lambda_b` (`7.275958e-08` versus
`5.873303e-08`), and `tau_n_tau_n` (`1.091394e-07` versus `1e-08`);
512→1024 retains the `lambda_b_lambda_b` failure. The focused test retains
every coordinate/difference/tolerance in its node-ladder diagnostics.

The explicit pinned Genz point check at `a = -4` is
`-323.285855234`, numerical error `1e-15`, message `Normal Completion`.
Point agreement does not certify derivatives. The legacy Genz-derived
numerical Hessian is non-finite and remains non-certifying.

## Environment and checks

- R 4.6.0; `mvtnorm` 1.4.1; `statmod` 1.5.2; `numDeriv` 2016.8.1.1.
- `test-associate-pairs-staged-sandwich.R`: 101 passing, 0 failures, 0 skips.
- `test-associate-pairs-bernoulli-nb2.R`: 113 passing, 0 failures, 0 skips.

The focused test retains the ordered taxonomy from protocol/input failure
through `independent_step_unstable` to `F1D_pass`.

## Decision and fence

**Status: STOPPED — F1 remains closed; F3 remains unauthorized.** At
`alpha = -4, y_B = 1` and the `alpha = +4, y_B = 0` mirror, the production
derivative ladder was finite, but the independent elementwise 256/512/1024-node
ladder returned `independent_step_unstable`. These rows are
**derivative-unqualified test-only evidence states**, not production
runtime-unavailable statuses and not validation passes.

No smoke, refit, F4/remote compute, public API/profile/interval work,
capability-ledger change, Arc D/F5 work, or direct `rho12` work occurred.
Noether approved this fail-closed conclusion; Fisher confirmed it supports no
claim beyond the locked F1D rows; Rose approved closeout after the test-only
status wording correction.
