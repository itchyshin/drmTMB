# Arc 1 Gaussian fixed-target profile feasibility

This retained packet promotes only two exact ML targets under the current-source
`n = 240` Gaussian location-scale fixture:

- `mc-0260::fixef:mu:x`
- `mc-0262::fixef:sigma:x`

Each target passed three Totoro seeds (`2026080222:2026080224`). Every receipt
binds source, runner, estimator, target type, immutable fixture, trace, and
interval hashes. The fail-closed reconciler parses the sidecars and requires a
finite ordered two-sided interval containing the estimate, convergence code
zero, `pdHess = TRUE`, no profile boundary, and no clamp. Adversarial mutation
tests cover estimator, fixture, runner, target, endpoint, trace status, duplicate
seed, and missing-seed failures.

The packet establishes `interval_feasible`, not coverage or calibration. It
does not widen to other coefficients, REML, `meta_V`, other families, or public
interval guidance.

