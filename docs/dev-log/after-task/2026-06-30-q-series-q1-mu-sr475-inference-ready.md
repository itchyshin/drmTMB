# Q-Series q1 mu SR475 inference-ready promotion

## 1. Task

Promote only the q1 `mu:(Intercept)` rows that Rose, Fisher, and Grace accepted
from the corrected Nibi SR475 retained-denominator surface.

## 2. Implemented

- Promoted `qseries_phylo_q1_mu_intercept`,
  `qseries_spatial_q1_mu_intercept`, and
  `qseries_relmat_q1_mu_intercept` to interval+coverage `inference_ready`.
- Kept `qseries_animal_q1_mu_intercept` at `point_fit/planned/planned` because
  seeds `812407` and `812444` retain `wald_at_boundary` infinite intervals.
- Added three inference-evidence summary rows under
  `default_location_bias_t_wald_direct_sd`.
- Moved the live closure/queue accounting from 5 to 8 inference-ready rows and
  from 23 to 20 Gaussian low-q gate-required rows.
- Removed the promoted rows from the Gaussian low-q audit and active low-q
  row-selection gate; animal remains as the q1 `mu` blocker.
- Bumped the dashboard build to `r173`.

## 3. Row State

- `qseries_phylo_q1_mu_intercept`: 475/475 usable intervals, coverage `0.9832`,
  MCSE `0.005904`, lower/upper misses `4/4`.
- `qseries_spatial_q1_mu_intercept`: 475/475 usable intervals, coverage
  `0.9705`, MCSE `0.007760`, lower/upper misses `4/10`; fixed-covariance
  spatial evidence only.
- `qseries_animal_q1_mu_intercept`: not promoted; 473/475 usable intervals and
  retained infinite intervals at seeds `812407` and `812444`.
- `qseries_relmat_q1_mu_intercept`: 475/475 usable intervals, coverage
  `0.9789`, MCSE `0.006587`, lower/upper misses `3/7`; K-matrix relmat
  evidence only.

## 4. Claim Boundary

This promotes exactly the phylo, spatial, and relmat Gaussian low-q q1
`mu:(Intercept)` rows under the default location-axis bias-corrected small-sample-t Wald direct-SD interval channel.
The promotion does not claim `supported`, animal q1 `mu`, q1 `sigma`, matched
`mu+sigma`, q2, q4/q8, non-Gaussian interval evidence, REML, AI-REML, broad
bridge support, denominator-pass public support, or public support.

## 5. Checks

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 8 inference-evidence summary rows, 32 Gaussian
  low-q audit rows, and 20 Gaussian low-q row-selection rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9594 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Scoped `git diff --check` over the touched dashboard, validator, test,
  check-log, and after-task files: passed.
- Dashboard JavaScript extracted from `docs/dev-log/dashboard/index.html` and
  checked with `node --check`: passed.
