# Q-Series phylo_interaction provider-boundary contract

## 1. Goal

Close the review-pending state for `qseries_phylo_interaction_q1_mu` by making
the current claim boundary explicit: this row has native Gaussian q1
`phylo_interaction()` point/extractor evidence, but no banked interval route,
no calibrated denominator, no coverage evidence, and no bridge support.

## 2. Implemented

- Updated the Q-Series support-cell row to point at the special-target
  contract instead of only the parser/extractor test.
- Updated the Gaussian low-q status audit, special-target contract,
  row-selection generator, generated row-selection TSV, and mirror artifact.
- Changed the row-selection status to
  `phylo_interaction_provider_boundary_no_interval_route` with
  `run_mode = no_compute_provider_boundary_hold`.
- Added Boole/Fisher/Rose wording that `phylo_interaction()` is not ordinary q1,
  not `phylo(1 | species)`, not q2/q4 endpoint covariance, and not eligible to
  inherit the single-tree `phylo()` interval route because it pairs two clades
  and has no single structured group count.
- Updated mission-control and focused R tests to enforce this boundary.
- Bumped the dashboard widget build to `r150`.

## 3a. Decisions and Rejected Alternatives

- Rejected sharing the ordinary or single-tree `phylo()` q1 `mu` interval route.
  Boole noted that the formula grammar and parser define `phylo_interaction()`
  as a q1 pair-level Kronecker field with `tree1`, `tree2`, and a pair grouping
  term. The small-sample correction and group-count logic do not transfer.
- Rejected treating the row as recovery-only. Fisher confirmed the Gaussian row
  has parser/extractor identity evidence, not recovery, interval, profile, or
  coverage evidence.
- Rejected transfer from Poisson/NB2 `phylo_interaction()` rows. Those are
  separate non-Gaussian recovery-only cells and do not support Gaussian
  intervals.
- Kept `fit_status = point_fit`, `extractor_status = extractor_ready`,
  `bridge_status = unsupported`, `interval_status = planned`, and
  `coverage_status = planned`.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-special-target-contract.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`

## 5. Checks Run

- `ssh -o BatchMode=yes -o ConnectTimeout=8 totoro 'hostname; whoami; pwd; getconf _NPROCESSORS_ONLN'`:
  failed with publickey/password denial.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 nibi 'hostname; whoami; pwd'`:
  passed.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 rorqual 'hostname; whoami; pwd'`:
  passed.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 fiia 'hostname; whoami; pwd'`:
  failed because the alias did not resolve.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells and
  the updated `phylo_interaction()` special-target contract.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8617 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 8. Consistency Audit

The support cell, low-q audit row, special-target contract, generated
row-selection TSV, artifact mirror, mission-control validator, and focused test
now agree that `qseries_phylo_interaction_q1_mu` is point/extractor-only with a
provider-boundary no-interval-route contract.

## 10. Known Residuals

- `qseries_phylo_interaction_q1_mu` is not interval-ready, coverage-ready,
  `inference_ready`, `supported`, bridge-supported, REML, AI-REML, q2/q4, or
  public-support evidence.
- Any future interval work must start with a row-specific Gaussian q1
  `phylo_interaction()` interval design naming the target, denominator,
  one-sided misses, bridge exclusion, and blocked neighbours.
- Totoro/FIIA smoke remains operationally unavailable from this checkout;
  Nibi/Rorqual are reachable but remain inappropriate for this row before a
  reviewed interval design exists.

## 11. Team Learning

Provider names are not interchangeable interval channels. A q1 structured
effect can be fit-stable and extractor-ready while still lacking the group-count
and bridge assumptions needed by a neighbouring interval route.
