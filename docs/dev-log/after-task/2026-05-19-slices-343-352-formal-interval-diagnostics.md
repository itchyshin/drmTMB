# After Task: Slices 343-352 Formal Interval Diagnostics

## Goal

Move the Student-t shape and bivariate residual `rho12` interval lane from
raw evidence rows to an interpretable diagnostics table that separates method
availability from coverage.

## Implemented

`phase18_summarise_interval_evidence()` now combines coverage and status
summaries for standard Phase 18 interval rows. It reports usable intervals,
covered intervals, usable misses, unusable rows, status counts, success rates,
failure rates, and MCSEs under `artifact_grain = "interval_diagnostics"`.
This keeps a failed profile interval separate from a finite interval that
missed truth.

The Student-t shape and bivariate residual `rho12` summaries now return
`interval_diagnostics`, grouped by the existing summary keys plus
`interval_method`. Their grid writers add
`student-shape-interval-diagnostics.csv` and
`biv-rho12-interval-diagnostics.csv` beside the existing aggregate,
replicate, manifest, interval-evidence, and interval-failure artifacts.

## Mathematical Contract

The diagnostics summarize interval rows on the scale already reported by each
producer. In these pilots that means formula-coefficient Wald, profile, and
private parametric-bootstrap intervals for Student-t `mu`, `sigma`, and `nu`
coefficients, plus bivariate Gaussian `mu1`, `mu2`, `sigma1`, `sigma2`, and
residual-correlation `rho12` coefficients. The diagnostics do not translate
Student-t `nu` to response scale and do not mix residual `rho12` with
phylogenetic, spatial, animal, or ordinary group-level correlations.

## Files Changed

- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/43-phase-18-interval-producer-contract.md`
- `docs/dev-log/after-task/2026-05-19-slices-343-352-formal-interval-diagnostics.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/R/sim_uncertainty.R`
- `inst/sim/run/sim_summary_biv_rho12_smoke.R`
- `inst/sim/run/sim_summary_student_shape_smoke.R`
- `inst/sim/run/sim_write_biv_rho12_grid.R`
- `inst/sim/run/sim_write_student_shape_grid.R`
- `tests/testthat/test-phase18-biv-rho12-summary-smoke.R`
- `tests/testthat/test-phase18-sim-interval-evidence.R`
- `tests/testthat/test-phase18-student-shape-summary-smoke.R`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phase18-(sim-(interval-evidence|uncertainty|bootstrap)|student-shape|biv-rho12)')"`:
  passed with 214 expectations.
- `Rscript -e "devtools::test()"`: passed with 5,194 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n "interval diagnostics|interval-diagnostics|interval_diagnostics|formal coverage|coverage evidence|not formal coverage" docs/design inst/sim vignettes README.md ROADMAP.md NEWS.md`:
  confirmed that the new diagnostics wording appears in the simulation README,
  interval producer contract, and Phase 18 programme, while the coverage
  language stays bounded.

## Pilot Grid Evidence

The Student-t pilot was written under
`inst/sim/results/slice-347-student-shape-formal-interval-grid/` with 2 cells,
6 replicates per cell, 72 replicate-parameter rows, 168 interval-evidence
rows, and 13 interval-failure rows. The diagnostics show that Student-t `nu`
profile intervals remain the fragile lane: `nu:(Intercept)` profile intervals
had 2 unusable rows in one cell and 3 unusable rows in the other; `nu:w`
profile intervals had 3 unusable rows in each cell. Bootstrap rows were
available for all requested Student-t parameters, but small-pilot coverage
varied by parameter.

The bivariate residual `rho12` pilot was written under
`inst/sim/results/slice-348-biv-rho12-formal-interval-grid/` with 2 cells,
6 replicates per cell, 120 replicate-parameter rows, 264 interval-evidence
rows, and no interval-failure rows. The requested `rho12:(Intercept)` and
`rho12:w` profile rows were all usable in this pilot. Coverage/miss counts
still vary across methods and parameters, so these rows are diagnostics pilot
evidence rather than final coverage evidence.

## Tests Of The Tests

The new interval-diagnostics regression test constructs one profile group with
one covered interval, one finite miss, and one failed interval, plus one
bootstrap finite miss. It checks `n_interval`, `n_covered`,
`n_interval_missed`, `n_interval_unusable`, status counts, success rates, and
coverage. The first focused run exposed a data-frame indexing warning in the
diagnostics merge path; fixing that warning made the focused and full suites
clean.

## Consistency Audit

The Phase 18 programme now records slices 343-352 explicitly. The interval
producer contract says a failed profile is method-status evidence, not a
coverage miss. The simulation README lists the new diagnostics artifacts.
No roxygen, exported user-facing function, formula grammar, family registry,
or likelihood parameterization changed, so `devtools::document()` and NEWS were
not needed for this internal simulation-infrastructure slice.

## What Did Not Go Smoothly

The initial diagnostics merge used row-style data-frame indexing with
`drop = FALSE`, which produced warnings in the grid-writer tests. The warning
was useful because it showed that grid writers were exercising the new
diagnostics path, not just the direct helper test.

## Team Learning

Ada should keep reporting interval diagnostics as a two-axis result:
method-status reliability first, then coverage among requested replicate rows.
Curie should preserve a small constructed test that contains all three cases:
covered, finite miss, and failed. Fisher should continue treating
six-replicate pilots as plumbing and diagnostics evidence only. Grace should
keep pkgdown in the loop even for internal simulation docs because the figure
gallery and tutorials read from the same language. Rose should keep queued
promises visible after slice work so convergence stress tests and reference
audits do not get buried under the next feature.

## Known Limitations

The pilot grids are still too small for final Monte Carlo conclusions.
Student-t shape profile intervals can fail in successful fits, especially for
`nu` slopes. The private bootstrap path is simulation infrastructure only and
does not implement public bootstrap confidence intervals. The diagnostics
summarize formula-coefficient intervals; response-scale `nu` targets, fitted
value intervals, and user-facing profile or bootstrap APIs remain separate
future work.

## Next Actions

The next large jobs are a convergence stress test on Ayumi's local data under
the full bivariate location-scale and residual-correlation model, a pkgdown
and reference-page audit for every exported function and article path, and a
memory/dev-log audit of promised work that has not yet been closed. The
convergence job should run early because it tests whether the newly supported
model surface behaves on real data, not only on controlled simulation pilots.
