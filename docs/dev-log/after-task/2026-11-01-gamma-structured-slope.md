# After-task report: Gamma slope-only structured SD regression (2026-11-01)

## What changed

Native engine only (TMB, no Julia). A Gamma `mu` model may now carry one
slope-only structured term, `phylo(0 + x | g, tree = tree)`,
`spatial(0 + x | g, coords = coords)`, `relmat(0 + x | g, K = K)` or
`relmat(0 + x | g, Q = Q)`, with or without a matching
`sd(g, level = ...) ~ z` formula. The C++ generic structured path
(`src/drmTMB.cpp`, the `has_phylo_mu` block) already handled a single field with
a per-level SD, so only the R guards in `R/drmTMB.R` changed:
`validate_positive_continuous_mu_structured_term`,
`validate_gamma_relmat_mu_structured_term`, the complete-response guard for tree
and coordinate slopes, and `validate_positive_continuous_structured_combinations`
(a slope-only relmat term no longer takes the early return, so an ordinary
random layer beside it is still refused). The animal slope-only route was
already admitted; this slice adds an `Ainv` check for it.

## Evidence

New file `tests/testthat/test-gamma-structured-slope-sd.R` (87 expectations).
Oracle: dense Laplace marginal likelihood written inside the test with the exact
Gamma log-link score and observed curvature, evaluated at the fitted parameters
(agreement within 1e-4 absolute). Fixtures use a non-unit-diagonal kernel
(relmat, diagonal 1.7; animal, 1.4), a tree covariance built from `ape::vcv`
(not a package helper), a raw coordinate kernel, shuffled level order, shuffled
tip labels and shuffled rows. Each route also checks the constant-SD fit against
the formula-free fit, K against Q, predicted group SDs against the fitted
formula, simulate, and an RDS round trip. Emulated bugs (SDs on reversed levels;
the SD predictor sign-flipped) move the oracle by more than 0.05, which is 500
times the oracle tolerance. Refusal checks with message patterns cover
two-slope slope-only blocks for all three providers, `1 + x + z0`, labelled
slope-only blocks, an ordinary `(1 | id)` beside the structured slope, response
`include`, a mesh slope, the lognormal family, and an SD predictor that varies
within a level.

Tolerance note: the first run missed the spatial recovery bound (0.6) by 0.0014
at 12 rows per site. The bound was not changed; the fixture was given 20 rows per
site instead (a design change), and it then passed.

## Stale pins swapped

- `test-gamma-phylo-q2-sd-regression.R`: `phylo(0 + x | id)` is now admitted, so
  the refusal check uses `phylo(0 + x + z0 | id)` (still refused, "intercept").
- `test-gamma-spatial-q2-sd-regression.R`: same swap with `spatial(...)`.
- `test-positive-continuous-structured-mu.R` (a third pin found by running the
  neighbours): for Gamma with phylo, `0 + x` is dropped from the refused list
  and `0 + x + site` added.

The `1 + x + z0` pins remain as they were.

## Neighbour tests (Totoro, one process, 4 cores or fewer)

Passed, failed, errors, skipped: new file 87/0/0/0; phylo-q2 48/0/0/0;
spatial-q2 47/0/0/0; positive-continuous-structured-mu 198/0/0/0;
relmat-sd 11/0/0/0; relmat-q2 42/0/0/0; iid-structured 114/0/0/0;
ordinary-sd-beside-structured 55/0/0/0; animal-slope 15/0/0/0; phylo-sd 15/0/0/0;
spatial-sd 11/0/0/1 (one pre-existing skip).

## Not covered

No calibration, coverage or parity claim, and no Julia route (the Julia bridge
guard is unchanged). Not covered: slope-only terms with `include` missing
responses, covariance labels, spatial mesh slopes, two or more slopes per
structured term, sigma-side structured slopes, and combining the structured
slope with an ordinary random layer. The tests use one seed per fixture; the SD
recovery checks are loose single-fit bounds, not simulation studies.
