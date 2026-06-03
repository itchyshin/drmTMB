# After Task: Bivariate q6 Location Smoke Artifact Lane

## Goal

Add the Phase 18 smoke/artifact lane for the matching q6 bivariate Gaussian
location block:

```r
bf(
  mu1 = y1 ~ x + z + (1 + x + z | p | id),
  mu2 = y2 ~ x + z + (1 + x + z | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

This task should make q6 location artifact-routed without claiming formal
recovery, coverage, power, residual-scale slopes, same-response location-scale
slope covariance, random `rho12`, or p8/q8 endpoint covariance.

## Implemented

The new `biv_gaussian_q6_location` lane has a seeded DGP, fit summariser, smoke
runner, smoke-summary helper, and repeatable grid writer under `inst/sim/`.
The lane is wired into the manual Phase 18 Actions dispatcher and the structured
workflow registry as an opt-in task with seed `20260624`, excluded from
`task = "all"`.

Focused tests now cover the seeded DGP, the one-replicate smoke summary, grid
artifact writing, malformed inputs, Actions dry-run and dispatch plumbing, and
the random-slope workflow plan. The status docs and vignette sources now say
q4/q6 location blocks have smoke artifact routing, while q8 and broader
location-scale slope covariance remain design-only.

## Mathematical Contract

The latent ordinary group vector is:

```text
(b_mu1_intercept, b_mu1_x, b_mu1_z,
 b_mu2_intercept, b_mu2_x, b_mu2_z)
```

The six location SDs are direct `log_sd_re_cov` targets exposed through
`sdpars$mu` and the q6 location DGP truth. The 15 latent q6 location
correlations are derived group-correlation rows in `corpars$re_cov`,
`corpairs()`, and `summary(fit)$covariance`; they stay point/status rows for
direct interval purposes. Residual `rho12` is a separate residual coscale row,
not a group-level correlation.

## Files Changed

- `inst/sim/dgp/sim_dgp_biv_gaussian_q6_location.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q6_location.R`
- `inst/sim/run/sim_run_biv_gaussian_q6_location_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q6_location_smoke.R`
- `inst/sim/run/sim_write_biv_gaussian_q6_location_grid.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-biv-gaussian-q6-location.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `README.md`, `NEWS.md`, `ROADMAP.md`, `docs/dev-log/known-limitations.md`
- Phase 6c/Phase 18 design notes, formula/source-map docs, and simulation docs
  that describe q4/q6 location status and q8 boundaries.

## Checks Run

- `air format inst/sim/dgp/sim_dgp_biv_gaussian_q6_location.R inst/sim/fit/sim_summarise_biv_gaussian_q6_location.R inst/sim/run/sim_run_biv_gaussian_q6_location_smoke.R inst/sim/run/sim_summary_biv_gaussian_q6_location_smoke.R inst/sim/run/sim_write_biv_gaussian_q6_location_grid.R inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-biv-gaussian-q6-location.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-structured-workflow-registry.R`
  completed without errors.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-q6-location')"`
  returned 45 passes, no failures, warnings, or skips.
- `Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-structured-workflow-registry')"`
  returned 477 passes, no failures, warnings, or skips.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"` returned 956 passes,
  no failures, warnings, or skips.
- `Rscript -e "devtools::test()"` returned 9,385 passes, no failures, warnings,
  or skips in 626.4s.
- `Rscript -e "pkgdown::build_site()"` completed and wrote `pkgdown-site`. It
  emitted the local-library warning that `glmmTMB` was built with TMB 1.9.17
  while the current TMB was 1.9.21.
- `Rscript -e "pkgdown::check_pkgdown()"` returned no problems found.
- `Rscript -e "devtools::check(error_on = 'never')"` completed in 8m37.2s with
  0 errors, 0 warnings, and 1 NOTE: unable to verify current time.
- `git diff --check` passed.

`devtools::document()` was not run because no roxygen comments changed.

## Tests Of The Tests

The first q6 smoke test failed before tuning because the expected summary row
count was wrong and the initial smoke cell produced a weak fit with
`NaNs produced`, non-convergence, and `pdHess = FALSE`. The final test expects
30 rows: six fixed `mu` coefficients, two residual `sigma` rows, six direct
location SD rows, 15 derived location-correlation rows, and one residual
`rho12` row.

The malformed-input tests reject invalid group counts, boundary residual
correlations, wrong-length `sd_mu`, and incomplete condition rows. The dispatch
tests stub the q6 grid writer so the Actions route is tested without rerunning
the model.

## Consistency Audit

The source stale scan:

```sh
rg -n 'q6 location remains source|q6 artifact routing|source-only boundary|q6 source-only|q4 location.*no Phase 18 artifact lane|q4.*source-tested but.*no artifact|source-tested.*q=6|q=6.*source-tested|source-tested matching q=4/q=6|source-tested q=4/q=6|source gates for matching q=4 and q=6|q=4 and q=6.*source-tested|q6 bivariate location artifacts' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md inst/sim tests/testthat .github/workflows vignettes -g '!docs/dev-log/after-task/**'
```

returned no current-source matches after updating the model-map,
implementation-map, formula-grammar, source-map, and validation-debt wording.
The same scan over `pkgdown-site -g '!search.json'` returned no generated-site
matches after rebuilding the site.

The unsupported-claim scan:

```sh
rg -n 'p8/q8.*(is|are) (fitted|implemented|supported)|random effects in `rho12` (are )?(fitted|implemented)|residual-scale bivariate slope.*(is|are )?(fitted|implemented)|same-response location-scale slope covariance.*(is|are )?(fitted|implemented)|recovery, coverage, and power.*(are )?(supported|ready|implemented)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md inst/sim tests/testthat -g '!docs/dev-log/after-task/**'
```

returned only planned-boundary rows in the readiness matrix. The same scan over
`pkgdown-site -g '!search.json'` returned no generated-site matches.

## GitHub Issue Maintenance

PR #445 had already been merged at the previous head, so the q6 follow-up was
pushed to the same branch and opened as PR #477:
<https://github.com/itchyshin/drmTMB/pull/477>.

Issue and PR comments:

- #33 Phase 6c status comment:
  <https://github.com/itchyshin/drmTMB/issues/33#issuecomment-4611028757>.
- #59 Phase 18 smoke/artifact-routing comment:
  <https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4611028987>.
- PR #477 verification and boundary comment:
  <https://github.com/itchyshin/drmTMB/pull/477#issuecomment-4611029250>.

#33 and #59 remain open. The q6 lane is smoke-artifact-routed only; formal
recovery, coverage, power, q8/p8, residual-scale slope covariance,
same-response location-scale slope covariance, and random `rho12` remain open.

## What Did Not Go Smoothly

The first smoke cell was too ambitious for a fast, deterministic local test.
Reducing the q6 SD and correlation magnitudes and using `n_id = 72`,
`n_each = 5`, and seed `20260624` produced a stable smoke fit.

The rendered pkgdown scan caught stale vignette/source-map wording after the
first docs pass. That was useful: the source-only scan had not included all
rendered reader paths, and the source-map still treated q6 artifact routing as
future work.

## Team Learning

For bivariate q > 2 location lanes, treat the rendered model-map,
implementation-map, formula-grammar, and source-map pages as part of the status
contract. A source-only status scan is not enough when README/NEWS/vignettes
change.

## Known Limitations

This is a smoke/artifact lane only. It does not establish recovery, coverage,
power, timing, formal Monte Carlo operating characteristics, direct intervals
for q6 derived correlations, residual-scale slope covariance,
same-response location-scale slope covariance, random `rho12`, non-Gaussian
correlated slopes, or all-four p8/q8 endpoint covariance.

## Next Actions

Let GitHub CI validate PR #477. If CI passes, merge the q6 smoke/artifact lane
without closing #33 or #59.
