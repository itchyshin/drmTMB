# Q-Series q1 mu SR475 status-surface sync

## 1. Task

Replace stale q1 `mu:(Intercept)` n=5 smoke-only wording on the board with the
imported SR475 retained-denominator review evidence, without changing support
status.

## 2. Implemented

- Updated the four q1 `mu:(Intercept)` support-cell rows and Gaussian low-q
  audit rows to point at
  `structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`.
- Kept all four linked support cells at `point_fit/planned/planned`.
- Updated the compute queue and closure-triage text so q1 `mu` is now an SR475
  review lane, not a smoke-only lane.
- Updated `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R` to require the
  SR475 evidence link, the retained denominator language, and the animal
  finite-interval blocker.
- Bumped the dashboard build to `r172`.

## 3. Row State

- `qseries_phylo_q1_mu_intercept`: SR475 review candidate; 475/475 usable
  intervals, coverage `0.9832`, MCSE `0.005904`, lower/upper misses `4/4`.
- `qseries_spatial_q1_mu_intercept`: SR475 review candidate with miss-balance
  caveat; 475/475 usable intervals, coverage `0.9705`, MCSE `0.007760`,
  lower/upper misses `4/10`.
- `qseries_animal_q1_mu_intercept`: blocked; 473/475 usable intervals and
  retained `wald_at_boundary` infinite intervals at seeds `812407` and
  `812444`.
- `qseries_relmat_q1_mu_intercept`: SR475 review candidate with miss-balance
  caveat; 475/475 usable intervals, coverage `0.9789`, MCSE `0.006587`,
  lower/upper misses `3/7`.

## 4. Claim Boundary

This promotes exactly no Q-Series row. The sync does not claim
`interval_status`, `coverage_status`, `inference_ready`, `supported`, q1
`sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian interval evidence, REML,
AI-REML, bridge support, denominator-pass public support, or public support.

## 5. Next Gate

Run a Rose/Fisher/Grace promotion audit from these corrected SR475 surfaces for
phylo, spatial, and relmat. Keep animal blocked until the interval channel is
repaired or a blocker decision is written.

## 6. Checks

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Scoped `git diff --check` over the touched dashboard, validator, and focused
  test files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9563 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Dashboard JavaScript extracted from `docs/dev-log/dashboard/index.html` and
  checked with `node --check`: passed.
