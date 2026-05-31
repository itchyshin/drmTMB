# After Task: Phase 6c Bivariate Slope-Only Evidence Gate

## Goal

Close #440 by recording whether the current bivariate Gaussian matching
slope-only `mu1`/`mu2` route is promoted, held, or diagnostic-only before the
larger #446 power, accuracy, and coverage plan.

## Implemented

This slice records the gate as artifact-ready and held from recovery, coverage,
and power claims. The fitted route remains the matching slope-only bivariate
Gaussian model:

```r
bf(
  mu1 = y1 ~ x + (0 + x | p | id),
  mu2 = y2 ~ x + (0 + x | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

The route has extractor, profile-target, diagnostic, Phase 18 smoke helper,
artifact-writer, manual Actions, and one small pilot-artifact handle. It is not
yet a recovery, coverage, power, multicore, bootstrap, or broad p8/q8 claim.

## Mathematical Contract

For each grouping level, the model estimates two ordinary group-level slope
coefficients, one for `mu1:x` and one for `mu2:x`, and a constant group-level
slope-slope correlation:

```text
(b_1, b_2)' ~ Normal(0, Sigma_slope)
Sigma_slope[1, 2] = rho_slope * sd_1 * sd_2
```

Residual `rho12` remains the observation-level residual correlation in the
bivariate Gaussian likelihood. It is reported by `rho12()` and residual
`corpairs()` rows, not by the group-level slope-slope covariance row.

## Files Changed

- `ROADMAP.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/145-phase6c-bivariate-slope-evidence-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-bivariate-slope-evidence-gate.md`

No parser, likelihood, TMB, extractor, simulation-runner, formula-grammar,
NEWS, pkgdown navigation, or missing-data files changed.

## Checks Run

```sh
air format ROADMAP.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/145-phase6c-bivariate-slope-evidence-gate.md docs/dev-log/after-task/2026-05-31-phase6c-bivariate-slope-evidence-gate.md docs/dev-log/check-log.md
Rscript --vanilla -e "devtools::test(filter = 'biv-gaussian|phase18-biv-gaussian-mu-slope|phase18-actions-runner|phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n 'Bivariate Slope-Only Evidence Gate|artifact-ready|held from recovery, coverage, and power|random_correlation|residual_rho12|biv_gaussian_mu_slope|#440|#446' ROADMAP.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/145-phase6c-bivariate-slope-evidence-gate.md docs/dev-log/after-task/2026-05-31-phase6c-bivariate-slope-evidence-gate.md inst/sim tests/testthat pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'biv_gaussian_mu_slope.*coverage claim|biv_gaussian_mu_slope.*power claim|biv_gaussian_mu_slope.*recovery claim|bivariate Gaussian slope-only.*coverage claim|bivariate Gaussian slope-only.*power claim|random effects in `rho12` (are )?(fitted|implemented)|intercept-plus-slope q4 (location )?blocks (are )?(fitted|implemented)|residual-scale slope blocks (are )?(fitted|implemented)|p8/q8 endpoints (are )?(fitted|implemented)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes inst/sim tests/testthat pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'
git diff --check
```

Formatting passed. Focused bivariate Gaussian, Phase 18 bivariate slope,
Actions runner, and structured workflow registry tests passed.
`pkgdown::check_pkgdown()` reported no problems, and
`pkgdown::build_site(lazy = TRUE, preview = FALSE)` rebuilt the rendered site.
The positive source/rendered scan found the gate decision and evidence handles.
The stale-claim scan returned no matches for accidental recovery, coverage,
power, random-`rho12`, q4, residual-scale slope, or p8/q8 fitted claims.
`git diff --check` passed.

## Tests Of The Tests

Existing tests already exercise the behaviour needed for this gate. The
bivariate Gaussian source test fits the matching slope-only route and checks
the slope-slope extractor row, covariance-block registry, profile target, and
`check_drm()` diagnostic. The Phase 18 test covers the seeded DGP, smoke
runner, aggregate and replicate tables, manifest, failure ledger, overwrite
protection, and malformed-input errors.

## Consistency Audit

The new design note and ROADMAP entry keep three layers separate:

- fitted and extractor-ready matching slope-only `mu1`/`mu2` covariance;
- residual `rho12`, reported separately as residual correlation;
- broader q4, residual-scale, random-`rho12`, p8/q8, and mixed-response
  neighbours, which remain closed until separate evidence exists.

## GitHub Issue Maintenance

#440 is the direct issue for this gate. No new extractor, simulation-runner, or
Actions-routing issue is needed because the current route has source tests,
Phase 18 helper tests, artifact-writer tests, manual Actions routing, and a
pilot artifact. #446 remains open for the formal simulation plan, and #59
remains open for the comprehensive Phase 18 simulation programme.

## What Did Not Go Smoothly

The current repository already had enough implementation and artifact evidence,
but the status was spread across tests, the registry, workflow docs, ROADMAP
slices, and issue comments. The missing piece was not code; it was a clear gate
decision that future simulation work can trust.

## Team Learning

Rose: a small evidence gate is useful when code is already present but the
claim level is still ambiguous. Fisher: one clean artifact pilot is not a
coverage or power result. Grace: Actions routing can be ready while the task
stays manual-only.

## Known Limitations

The current gate does not fit intercept-plus-slope q4 location blocks,
same-response location-scale slope covariance, residual-scale slope blocks,
random effects in `rho12`, all-four p8/q8 endpoints, predictor-dependent slope
`corpair()` regressions, or mixed-response bivariate random-slope models.

## Next Actions

Use #446 to decide the first recovery, accuracy, coverage, power, convergence,
and reporting grid for `biv_gaussian_mu_slope` before any broad simulation
claim is made.
