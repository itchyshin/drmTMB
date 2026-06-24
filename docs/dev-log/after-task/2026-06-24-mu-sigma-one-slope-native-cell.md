# After Task: Matched Mu Sigma One-Slope Native Cells

## Goal

Open the exact Gaussian structured matched `mu+sigma` one-slope native
point-fit/extractor cells that the readiness gate defined. The fitted endpoint
members are:

```text
mu:(Intercept)
mu:x
sigma:(Intercept)
sigma:x
```

This is a runtime and extractor slice only. It does not promote bridge,
interval, coverage, REML, AI-REML, public optimizer, DRAC, SR150, or
Ayumi-facing claims.

## Implemented

- Allowed matched unlabelled one-slope structured terms in univariate Gaussian
  `mu` and `sigma` when both formulas use the same `1 + x` provider term.
- Built the four endpoint members in the structured design metadata:
  `mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, and `sigma:x`.
- Filled duplicate slope columns in the structured model matrix so each endpoint
  member receives the predictor values.
- Kept the covariance layout scalar/independent for the matched one-slope cell;
  labelled structured slope covariance remains closed.
- Avoided adding unused q > 2 structured covariance probe parameters for this
  scalar matched-slope route.
- Added provider source tests for:
  `phylo(1 + x | species, tree = tree)`,
  fixed-covariance `spatial(1 + x | site, coords = coords)`,
  A-matrix `animal(1 + x | id, A = A)`, and
  K/Q `relmat(1 + x | id, K/Q = ...)`.
- Refreshed the q-series support-cell TSV, matched readiness sidecar, mission
  validator, README, ROADMAP, formula grammar, likelihood/design status docs,
  and dashboard README to make the new native point-fit/extractor boundary
  explicit.

## Checks Run

```sh
air format R/drmTMB.R R/methods.R tests/testthat/test-structured-effects.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Results:

- `structured-effects` passed with 337 assertions.
- `phylo-gaussian` passed with 306 assertions.
- `spatial-gaussian` passed with 180 assertions.
- `animal-relmat-gaussian` passed with 281 assertions.
- `structured-re-conversion-contracts` passed with 1535 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured
  RE `mu+sigma` slope-readiness rows.
- `git diff --check` passed.

## Boundary

These rows are native point-fit/extractor evidence for the exact matched
one-slope cells named above. They do not imply broad bridge support,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, labelled structured slope covariance, interval reliability,
coverage, REML, AI-REML, DRAC execution, SR150 evidence, PR undrafting or
merging, or an Ayumi-facing reply.

## Next Actions

1. Add same-target bridge fixtures for the matched `mu+sigma` one-slope cells.
2. Keep interval and coverage work blocked until the bridge fixtures and
   calibrated denominator evidence exist.
3. Leave multiple slopes, labelled structured slope covariance, structured q8,
   and non-Gaussian structured slope cells planned for later tranches.
