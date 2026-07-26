# Arc 6 F1E — private derivative-oracle receipt

**Status: READY FOR FRESH F1 REVIEW — F1 remains closed and F3 remains
unauthorized.** F1E is private/test-only deterministic evidence. It changes no
production runtime status or public inference surface. F1D remains retained
negative evidence.

## Scope and provenance

- Base SHA: `42596dd4bceea47eac1df86a6f73c2ec1e86ba52`.
- Changed implementation surface: only
  `tests/testthat/test-associate-pairs-staged-sandwich.R`.
- Candidate: fixed-effect, complete-pair Bernoulli x ordinary-NB2,
  `association = ~1`, staged alpha.
- Excluded: production kernel changes; reopening F1; F3 smoke/refits;
  simulation/bootstrap; F4/F5; Totoro/DRAC; `vcov()`, `confint()`, profiles,
  public documentation, capability-ledger work, Arc D/F5, other pair classes,
  slopes, random effects, missingness, and direct `biv_lognormal()` `rho12`.

## Independent route

The test-only oracle conditions on the bounded NB2 CDF interval and uses an
independent Gauss--Legendre node ladder (512, 1024, and 2048 nodes). It does
not call the production endpoint helper, production quadrature, or production
derivative ladder. Finite NB2 CDF endpoint derivatives are assembled from the
NB2 PMF sum and its analytic first and second derivatives; the zero-count
lower endpoint is retained at minus infinity.

The first- and second-order Leibniz moving-endpoint terms, including the
implicit-normal endpoint derivatives, are evaluated directly. A finite result
is qualified only when every point/gradient/Hessian coordinate passes both
adjacent node comparisons:

`abs(left - right) <= max(1e-8, 2e-10 * max(1, abs(left), abs(right)))`.

## Deterministic evidence

All results below are private test diagnostics. The production comparison used
the predeclared gradient tolerance `2e-3` and Hessian tolerance `3e-3`.

| Fixture | Point log probability | Largest production gradient difference | Largest production Hessian difference | 512/1024 ladder maximum | 1024/2048 ladder maximum | Verdict |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Interior (`a = 0.22`, `B = 1`, `Y = 3`) | -2.857888578405614 | 4.60e-11 | 2.21e-10 | 1.33e-07 standardized | 4.00e-07 standardized | pass |
| Negative tail (`a = -4`, `B = 1`, `Y = 3`) | -323.2858552337651 | 1.98e-07 | 1.53e-06 | 1.63e-01 standardized | 1.52e-01 standardized | pass |
| Positive-sign mirror (`a = 4`, `B = 0`, `Y = 3`) | -95.22320755241083 | 6.44e-08 | 1.19e-06 | 2.73e-03 standardized | 3.37e-03 standardized | pass |

For the negative tail, the analytic point agrees with the pinned Genz
`mvtnorm` oracle at `1e-10` (observed difference below `1e-12`; normal
completion and integration error at most `1e-12`). At `a = -7`, the production
derivative route stays `unavailable`, the direct production point is `NA`, and
the test-only log-probability oracle returns `-Inf`; it was not converted into
a pass. An extreme endpoint fixture retains
`endpoint_oracle_unresolved` as a test-only fail-closed outcome.

## Reviews and conclusion

- **Noether:** the symbolic integrand, implicit endpoint identities, and
  scaling are mathematically coherent; its readiness conclusion is limited to
  a fresh F1 review.
- **Fisher:** reviewed the all-attempt status assembly. The final test status
  keeps production non-finiteness/instability, independent unresolved/unstable
  derivatives, endpoint failure, and route disagreement distinct.
- **Rose:** scope review confirms a test-only delta and permits only the
  headline at the top of this receipt.

This receipt is not F1 certification and does not authorize F3. A fresh
Noether/Fisher/Rose F1 review plus the owner decision are required before the
stopped F1 deterministic matrix may be reconsidered; a separate F3 approval
would still be required after that.
