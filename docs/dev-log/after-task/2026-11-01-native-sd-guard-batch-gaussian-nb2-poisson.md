## 1. Goal

Admit four bounded native slices found by read-only probes: Gaussian unlabelled correlated q2 with coefficient SD formulas, Gaussian relmat and coordinate-spatial intercept SD (animal slope-only already worked), NB2 relmat and coordinate-spatial intercept SD, and Poisson coordinate-spatial SD. Interval coverage remains deferred.

## 2. Implemented

Guard edits in `R/drmTMB.R` only; no C++ change (SD scaling is provider-generic):
- Gaussian `mu` call: `allow_correlated_q2 = TRUE`. The Gaussian SD-entry detector now includes `sd_relmat(` and `sd_spatial(`.
- NB2: detector includes `sd_relmat(` and `sd_spatial(`; the structured-type check admits `relmat` and `spatial`; the refusal message names all four providers.
- Poisson: detector includes `sd_spatial(`.

Each probe test was red for the stated guard before the edit.

## 3a. Decisions

Source edited by one writer only; four probe agents wrote one new test file each and touched no source. One finding beyond the probes: with the Gaussian q2 flag, an SD formula on the slope alone (constant intercept SD) is now admitted. It was untested, so I added an exact-oracle test for it before relying on it.

## 4. Files Touched

- `R/drmTMB.R`
- New tests: `test-gaussian-correlated-q2-sd.R`, `test-gaussian-structured-direct-sd-providers.R`, `test-nbinom2-relmat-spatial-intercept-sd-regression.R`, `test-poisson-spatial-sd-regression.R`
- Edited test: `test-gaussian-sd-slope-regression.R` (its refusal assertion for correlated q2 now asserts the fit succeeds and keeps the slope SD target)

The worktree has extensive other in-flight changes in `R/drmTMB.R`; this report does not claim them.

## 5. Checks Run

- New tests pass: Gaussian q2 17 (exact per-group MVN oracle, tolerance 1e-8 for both-coefficient case and 1e-6 for slope-only; constant-SD equivalence), Gaussian providers 49 (dense oracle plus independent dense optimum, relmat, spatial, animal slope), NB2 26 (Laplace oracle at fitted values), Poisson spatial 32 (no exact oracle; constant-SD equivalence to the scalar `spatial()` fit and prediction identity only).
- 25-file neighbour run: passing except the failures below.
- Not run: Julia parity, `devtools::document()`, package check, vignettes.

## 5b. Failures NOT caused by these edits (stale fences in the shared dirty tree)

Each says the spec now builds where the test expects an error, on routes these edits do not touch (Poisson correlated q2, Binomial slope-only, Poisson with `zi`). Left unchanged:
- `test-poisson-sd-assembly.R:138`
- `test-poisson-slope-sd-assembly.R:32`, `:37`, `:40`
- `test-phylo-gaussian.R:1927`: message mismatch ("scale formulas with structured slopes" expected; got "Structured random-effect scale formulas currently require one structured coefficient"). My edits do not touch `sd_phylo(`, but I did not compare against a clean baseline.

## 6. Not Claimed

No Julia parity, no calibration, no receipts, no ledger rows promoted, nothing committed. Recovery is single fixtures with loose bands. Poisson spatial has no exact oracle.
