# After Task: Slices 333-342 Interval Evidence And Examples

## Goal

Move the post-smoke interval lane from Wald-only summaries to an explicit
evidence ledger that can hold Wald, profile-likelihood, and private
parametric-bootstrap intervals for Student-t shape and bivariate residual
correlation simulations. At the same time, add reader-facing animal-model,
Student-t, and skew-normal examples without claiming that planned syntax is
fitted.

## Implemented

The shared Phase 18 interval helpers now distinguish `n_replicate` from
`n_interval` using `interval_status = "ok"` when that status column is present.
Failed, unavailable, and not-requested intervals remain visible rows and do not
silently inflate coverage. `phase18_profile_interval_columns()` records
profile endpoints, status, and messages beside replicate summaries.
`phase18_bootstrap_interval_columns()` adapts the private parametric-bootstrap
refit harness into the same column contract. `phase18_interval_evidence_table()`
then binds Wald, profile, and bootstrap rows into one evidence artifact, and
`phase18_interval_failures()` extracts the failure ledger.

The Student-t shape and bivariate `rho12` smoke summaries and grid writers now
accept optional profile and bootstrap arguments. Defaults keep ordinary smoke
runs light. Requested interval methods add profile, bootstrap, combined
evidence, coverage, and failure CSVs beside the existing aggregate, replicate,
manifest, failure, Wald interval, and Wald coverage artifacts.

The documentation examples now separate fitted and planned status. `animal()`
and `relmat()` remain planned structured-effect markers, with ordinary
Gaussian `(1 | individual)` or `(1 | line)` sensitivity fits as runnable
fallbacks. `student()` remains the fitted robust continuous route for `mu`,
`sigma`, and `nu`; `skew_normal()` remains planned-only syntax with
Gaussian/Student-t sensitivity guidance.

## Mathematical Contract

The interval evidence in this slice is on the formula-coefficient scale.
Student-t `nu` coefficients use the fitted link-scale shape predictor; the
response-scale transform remains `nu = 2 + exp(eta_nu)`. Bivariate `rho12`
coefficients are residual-correlation formula coefficients, not phylogenetic,
spatial, animal, or ordinary group-level covariance layers. Profile and
bootstrap rows are smoke evidence, not formal coverage evidence.

## Files Changed

- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/43-phase-18-interval-producer-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-19-animal-student-skew-examples.md`
- `docs/dev-log/after-task/2026-05-19-slices-333-342-interval-evidence-and-examples.md`
- `inst/sim/README.md`
- `inst/sim/R/sim_bootstrap.R`
- `inst/sim/R/sim_uncertainty.R`
- `inst/sim/fit/sim_summarise_biv_rho12.R`
- `inst/sim/fit/sim_summarise_student_shape.R`
- `inst/sim/run/sim_run_biv_rho12_smoke.R`
- `inst/sim/run/sim_run_student_shape_smoke.R`
- `inst/sim/run/sim_summary_biv_rho12_smoke.R`
- `inst/sim/run/sim_summary_student_shape_smoke.R`
- `inst/sim/run/sim_write_biv_rho12_grid.R`
- `inst/sim/run/sim_write_student_shape_grid.R`
- `tests/testthat/test-phase18-biv-rho12-*.R`
- `tests/testthat/test-phase18-sim-interval-evidence.R`
- `tests/testthat/test-phase18-student-shape-*.R`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/robust-student.Rmd`

## Checks Run

- `Rscript -e "testthat::test_file('tests/testthat/test-phase18-sim-interval-evidence.R')"`:
  passed with 19 expectations.
- `Rscript -e "devtools::load_all(quiet=TRUE); testthat::test_file('tests/testthat/test-phase18-student-shape-summary-smoke.R')"`:
  passed with 20 expectations.
- `Rscript -e "devtools::load_all(quiet=TRUE); testthat::test_file('tests/testthat/test-phase18-biv-rho12-summary-smoke.R')"`:
  passed with 19 expectations.
- `Rscript -e "devtools::test(filter = 'phase18-(sim-(interval-evidence|uncertainty|bootstrap)|student-shape|biv-rho12)')"`:
  passed with 197 expectations.
- `Rscript -e "devtools::test()"`: passed with 5,177 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- A tiny Student-t interval comparison grid was written under
  `inst/sim/results/slice-340-student-shape-interval-small-grid/` with 6
  replicate rows, 2 profile rows, 6 bootstrap rows, and 14 combined interval
  evidence rows. The `nu:(Intercept)` profile row was `ok`, the `nu:w` profile
  row was retained as a `failed` interval, and all 6 bootstrap rows were `ok`.
- A tiny bivariate `rho12` interval grid was written under
  `inst/sim/results/slice-338-biv-rho12-interval-small-grid/` with 10
  replicate rows, 1 profile row, 10 bootstrap rows, and 21 combined interval
  evidence rows. The requested `rho12:w` profile row and all 10 bootstrap rows
  were `ok`.

## Review Roles

Ada integrated the code, docs, and validation. Curie/Galileo supplied the
interval-evidence test that forced `interval_status` into the coverage
contract. Rose/Mencius reviewed stale and overconfident wording, especially
around Student-t shape status and planned `animal()` paths. Pat and
Florence/Wegener shaped the reader-facing examples so the fallback models are
usable and the uncertainty claims stay honest. Grace verified the focused test
cluster, full package test suite, pkgdown check, and whitespace check.

## Known Limitations And Next Actions

The profile and bootstrap rows in this slice are smoke evidence. They prove the
artifact path, status accounting, and refit plumbing, but they do not yet prove
formal interval coverage. The Student-t `nu:w` profile failure in the tiny grid
is useful evidence: shape slopes can have one-sided or nonfinite profile
behaviour even when intercept shape profiles and bootstrap rows are available.
The next simulation slices should increase replicates, separate profile
failure rates from coverage rates, and decide which response-scale `nu` targets
need profile or bootstrap intervals.

No fitted `animal()`, `relmat()`, `skew_normal()`, skew-t, shape random-effect,
or latent skewness model was implemented here. Those remain design or
failure-ledger entries until likelihoods, diagnostics, extractors, profile
targets, simulations, examples, and pkgdown reference pages exist.
