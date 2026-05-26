# After Task: Phase 18 Wrapper Forwarding Slices 679-688

## Goal

Validate that the first grid and count-gallery wrappers forward bounded
replicate-runner settings and keep bootstrap-layer settings separate where
interval-heavy surfaces need them.

## Implemented

Added `docs/design/87-phase-18-wrapper-forwarding-slices-679-688.md` to record
the current source and focused-test evidence. No likelihood, formula grammar,
public API, roxygen topic, pkgdown navigation, or rendered site output changed.

## Mathematical Contract

No model changed. The checked contract is execution plumbing: `cores` and
`backend` belong to the replicate layer, while `bootstrap_cores` and
`bootstrap_backend` belong only to the private parametric-bootstrap layer for
Student-t shape and bivariate residual `rho12` simulation artifacts.

## Files Changed

- `docs/design/87-phase-18-wrapper-forwarding-slices-679-688.md`
- `docs/dev-log/after-task/2026-05-24-phase18-wrapper-forwarding-slices-679-688.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/run/sim_write_gaussian_ls_grid.R | sed -n '1,120p'
nl -ba inst/sim/run/sim_write_student_shape_grid.R | sed -n '1,120p'
nl -ba inst/sim/run/sim_write_biv_rho12_grid.R | sed -n '1,120p'
nl -ba inst/sim/run/sim_write_count_mu_random_effect_grid.R | sed -n '1,140p'
nl -ba inst/sim/run/sim_render_count_mu_gallery_smoke.R | sed -n '1,120p'
nl -ba tests/testthat/test-phase18-gaussian-ls-grid-writer.R | sed -n '1,140p'
nl -ba tests/testthat/test-phase18-student-shape-grid-writer.R | sed -n '1,170p'
nl -ba tests/testthat/test-phase18-biv-rho12-grid-writer.R | sed -n '1,170p'
nl -ba tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R | sed -n '1,130p'
nl -ba tests/testthat/test-phase18-count-gallery-smoke-runner.R | sed -n '1,140p'
Rscript -e "devtools::test(filter = 'phase18-(gaussian-ls-grid-writer|student-shape-grid-writer|biv-rho12-grid-writer|count-mu-random-effect-grid-writer|count-gallery-smoke-runner|count-gallery-render-helper|sim-bootstrap|sim-runner)', reporter = 'summary')"
```

Results:

- The source audit found existing wrapper forwarding for Gaussian
  location-scale, paired Poisson/NB2 `mu`, Student-t shape, bivariate residual
  `rho12`, and the count-gallery smoke wrapper.
- The focused wrapper-forwarding bundle completed with exit code 0.
- Student-t shape and bivariate residual `rho12` tests still exercise the bad
  `bootstrap_backend = "psock"` path, confirming that backend choices reach the
  shared planner boundary.
- No files were staged or committed.

## Tests Of The Tests

The focused tests check table artifact creation, requested-versus-actual worker
metadata, overwrite protection, bootstrap-backend validation, count-gallery
rendering, shared runner planning, bootstrap planning, and unsupported PSOCK
errors.

## Consistency Audit

The report does not add PSOCK, public bootstrap interval expansion, nested
parallelism, formula grammar, likelihood code, or user-facing API. The
Student-t shape lane remains fixed-effect `nu`; random effects in shape remain
unsupported.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

No implementation blocker appeared. The main caution is that this slice is a
current-state validation pass because the broad dirty tree already contains the
wrapper-forwarding implementation.

## Team Learning

For execution plumbing, validation notes should name both the outer replicate
layer and any inner bootstrap layer so future agents do not accidentally
parallelize both.

## Known Limitations

This block did not rerun full package tests or package checks. The next code or
broader report-rendering block should choose checks proportional to its changes.

## Next Actions

Continue with Slices 689-698 by validating or documenting the nested-parallel
guard for Student-t shape and bivariate residual `rho12` bootstrap smokes.
