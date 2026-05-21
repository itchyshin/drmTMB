# After Task: Animal/Relmat Q2 Interval Artifacts

## Goal

Turn the animal/`relmat()` q=2 interval-status plan into repeatable simulation
artifacts while keeping fixed-effect Wald coverage, structured-effect profile
status, residual `rho12`, and known matrices separate.

## Implemented

The animal/`relmat()` q=2 smoke and grid writer now accept
`profile_parameters`, `profile_level`, and `profile_args`. The default grid
writes formula-coefficient Wald interval and coverage CSVs only for rows with
finite fixed-effect standard errors. It also writes profile interval, profile
coverage, combined interval-evidence, interval-diagnostics, and
interval-failure CSVs. With no profile request, residual `sigma1`/`sigma2`,
structured SDs, structured correlations, and residual `rho12` are visible as
`not_requested`.

The opt-in smoke requests `animal:sd1`, `animal:cor`, and `rho12` through a
small display-label to profile-target map. The simulation tables keep the
shorter reader-facing labels while `confint()` receives fitted-model target
names such as `sd:mu:mu1:animal(1 | p | id)`.

## Mathematical Contract

Fixed-effect rows are formula coefficients and receive Wald intervals on the
coefficient scale. Structured SDs, structured correlations, and residual
`rho12` are response-scale profile targets when requested. Known relatedness
matrices `A`, `Ainv`, `K`, and `Q` remain supplied data, so they do not receive
interval rows.

## Files Changed

- `inst/sim/R/sim_uncertainty.R`
- `inst/sim/fit/sim_summarise_animal_relmat_q2.R`
- `inst/sim/run/sim_run_animal_relmat_q2_smoke.R`
- `inst/sim/run/sim_summary_animal_relmat_q2_smoke.R`
- `inst/sim/run/sim_write_animal_relmat_q2_grid.R`
- `tests/testthat/test-phase18-animal-relmat-q2-grid-writer.R`
- `tests/testthat/test-phase18-animal-relmat-q2-smoke.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/R/sim_uncertainty.R inst/sim/fit/sim_summarise_animal_relmat_q2.R inst/sim/run/sim_run_animal_relmat_q2_smoke.R inst/sim/run/sim_summary_animal_relmat_q2_smoke.R inst/sim/run/sim_write_animal_relmat_q2_grid.R tests/testthat/test-phase18-animal-relmat-q2-grid-writer.R
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q2-grid-writer', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q2', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phase18-sim-uncertainty', reporter = 'summary')"
air format tests/testthat/test-phase18-animal-relmat-q2-smoke.R
Rscript -e "devtools::test(filter = 'phase18-animal-relmat-q2', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'interval coverage waits|interval artifact code remains|interval-status plan|waits for opt-in profile evidence and interval-status artifacts|first q=2 DGP/smoke/grid-writer artifacts' docs/design inst/sim/README.md README.md ROADMAP.md NEWS.md vignettes
git diff --check
Rscript -e "devtools::check()"
```

`pkgdown::check_pkgdown()` reported no problems, `git diff --check` was clean,
and `devtools::check()` passed in 4m03s with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The first broader `phase18-animal-relmat-q2` run failed because the smoke test
sourced the animal/`relmat()` summariser without sourcing the shared interval
helper file. That failure proved the new summariser dependency was exercised by
the existing resume-path test. After adding `sim_uncertainty.R` to the smoke
test source list, the combined smoke and grid-writer test passed.

## Consistency Audit

`docs/design/55-phase-18-animal-relmat-q2-interval-status.md` now records the
implemented artifact contract. `docs/design/41-phase-18-simulation-programme.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`,
`docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`, and
`inst/sim/README.md` now say that fixed-effect Wald coverage is present, while
structured SD, structured correlation, and residual `rho12` profile coverage
require explicit profile requests.

## GitHub Issue Maintenance

No issue was updated in this slice. Issue #147 was already updated after the
preceding animal/`relmat()` parity PRs; this slice should be mentioned in the
next PR or overnight status comment after CI passes.

## What Did Not Go Smoothly

The first implementation assumed the smoke test already sourced the shared
interval helper because the grid-writer test did. The broader focused test
caught that hidden dependency quickly.

## Team Learning

Ada should treat any simulation summariser that starts using a shared helper as
a source-list audit task. Rose should check both the direct grid-writer tests
and the lower-level runner tests before calling a simulation artifact slice
closed.

## Known Limitations

This is not formal coverage evidence for structured SDs, structured
correlations, residual `rho12`, residual `sigma1`/`sigma2`, pedigree
construction, structured slopes, `sigma` structured effects, q=4
location-scale animal/`relmat()` blocks, predictor-dependent `corpair()`
regressions, direct-SD grammar, or non-Gaussian structured effects.

## Next Actions

Run pkgdown and package checks for the PR. The next modelling slice should
choose either a pedigree-to-`Ainv` audit/design pass or a structured-slope
parity audit before implementation.
