# After Task: Phase 18 Count Structured q1 Smoke Artifacts

## Goal

Add opt-in Phase 18 smoke artifacts for the ordinary Poisson/NB2 q=1
`spatial()`, `animal()`, and `relmat()` `mu` intercepts that merged in PR #366.

## Implemented

The slice adds a generic count structured q1 simulation lane:

- `inst/sim/dgp/sim_dgp_count_structured_q1.R`;
- `inst/sim/fit/sim_summarise_count_structured_q1.R`;
- `inst/sim/run/sim_run_count_structured_q1_smoke.R`;
- `inst/sim/run/sim_summary_count_structured_q1_smoke.R`;
- `inst/sim/run/sim_write_count_structured_q1_grid.R`; and
- `tests/testthat/test-phase18-count-structured-q1.R`.

The DGP covers ordinary non-zero-inflated `poisson(link = "log")` and
`nbinom2()` models with one q=1 structured `mu` intercept. The structured
route can be `spatial(1 | site, coords = coords)`,
`animal(1 | id, Ainv = Q)`, or `relmat(1 | id, Q = Q)`. NB2 cells include
fixed-effect `sigma ~ z`.

## Mathematical Contract

For each observation, the location predictor is

```text
eta_mu_i = beta0 + beta1 * x_i + b_g[i]
mu_i = exp(eta_mu_i)
```

where `b_g` is a Gaussian structured effect with public SD
`sd_structured`. NB2 cells add

```text
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
```

The summariser records `beta0`, `beta1`, `gamma0`, `gamma1` when present, and
`fit$sdpars$mu["<marker>(1 | <group>)"]`. It records direct
`log_sd_phylo` profile-target status for the structured SD, matching the
current fitted implementation.

## Files Changed

- Added the count structured q1 DGP, fit summariser, smoke runner, summary
  helper, grid writer, and tests.
- Updated `inst/sim/README.md`,
  `docs/design/41-phase-18-simulation-programme.md`, `ROADMAP.md`,
  `NEWS.md`, and
  `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`.
- Updated this check log and after-task report.

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_count_structured_q1.R inst/sim/fit/sim_summarise_count_structured_q1.R inst/sim/run/sim_run_count_structured_q1_smoke.R inst/sim/run/sim_summary_count_structured_q1_smoke.R inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-count-structured-q1|count-structured-mu|phase18-poisson-phylo-q1|phase18-nbinom2-phylo-q1)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
git diff --check
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "devtools::check()"
```

The focused test file passed after fixing the Poisson empty-`sigma` parameter
name bug. The adjacent count structured source-gate and phylogenetic q1
artifact tests passed. `pkgdown::check_pkgdown()`, full `devtools::test()`,
`git diff --check`, `pkgdown::build_site(preview = FALSE)`, and
`devtools::check()` also passed. `devtools::check()` reported 0 errors,
0 warnings, and 0 notes in 6 minutes 31.1 seconds.

## Tests Of The Tests

The first focused test run failed because Poisson cells have no fixed `sigma`
coefficients, and `paste0("sigma:", NULL)` created a fourth parameter label for
three estimates. The failure appeared in the smoke-runner manifest as one
errored replicate. The summariser now constructs `sigma_parameter` as
`character()` when no `sigma` coefficients exist, and the same test passed.

The tests also cover malformed DGP inputs, malformed cell inputs, grid
overwrite protection, artifact paths, profile-target rows, diagnostic rows,
manifest rows, and interval-evidence row counts.

## Consistency Audit

The design note, simulation README, Phase 18 programme, ROADMAP, and NEWS now
describe the lane as opt-in smoke artifacts for an already-fitted q=1 count
structured source gate. The prose does not claim formal recovery, coverage
evidence, zero-inflated structure, structured slopes, labelled count
covariance, structured NB2 `sigma`, or manual Actions dispatch.

Stale-claim scans over source docs and rendered pkgdown output returned the
intended new NEWS/ROADMAP/rendered-news boundary wording and an existing
formula-grammar boundary row, not an expanded support claim.

## GitHub Issue Maintenance

No issue action was taken in this slice. The work follows the focused source
gate that merged in PR #366 and only adds opt-in artifact infrastructure.

## What Did Not Go Smoothly

The Poisson summariser initially treated the absent `sigma` coefficient block
as a labelled row. The smoke-runner failure ledger exposed the mismatch before
any docs were finalized.

## Team Learning

Curie should keep mixed Poisson/NB2 artifact tests in the same smoke runner
because absent distributional parameters are easy to mishandle. Rose should
check empty optional parameter blocks explicitly when a generic summariser spans
families.

## Known Limitations

This is not a formal recovery grid. The lane does not add zero-inflated or
hurdle structured count effects, structured count slopes, labelled q=2/q=4
count covariance, simultaneous structured count types, structured NB2
`sigma`, or manual GitHub Actions dispatch.

## Next Actions

Run the focused tests with the adjacent fitted source tests, then decide
whether this opt-in grid should be wired into a manual Actions task or kept as
local-only infrastructure until more count structured diagnostics accumulate.
