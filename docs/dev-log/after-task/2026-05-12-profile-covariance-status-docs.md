# After Task: Profile Covariance Status Docs

## Goal

Align the profile-likelihood and covariance-status documentation with the direct
profile interval support now covered by tests for the first univariate
`mu`/`sigma` and bivariate `mu1`/`mu2` random-intercept correlations.

## Implemented

Updated the profile-CI design note, double-hierarchical endpoint map, roadmap,
NEWS, and known-limitations file so they say:

- direct profile intervals are implemented for the first `corpars$mu_sigma` and
  bivariate `corpars$mu` covariance rows;
- `summary(conf.int = TRUE, method = "profile", ci_parm = ...)` can attach
  those direct intervals to `summary(fit)$parameters`;
- derived covariance summaries, custom contrasts, and future `corpairs()`
  interval columns remain planned;
- residual `rho12` remains a separate residual-correlation layer.

## Mathematical Contract

This task changed documentation only. It did not change likelihood code,
profile code, formula grammar, or covariance parameterization.

## Files Changed

- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-profile-covariance-status-docs.md`

## Checks Run

- `air format docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'summary|profile-targets')"`: passed
  with 274 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `rg -n 'summary profile intervals remain planned|Profile-likelihood intervals for covariance summaries \| Planned|covariance summaries \| Planned|profile.*covariance.*Planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  found only the intentional derived-summary interval limitation in
  `docs/design/12-profile-likelihood-cis.md`.
- `rg -n 'direct covariance profile intervals|corpars\$mu_sigma|eta_cor_mu_sigma|summary\(conf.int = TRUE|Profile-likelihood intervals for covariance summaries \| Partly implemented|first fitted group-level covariance rows|derived summary profile intervals remain planned' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md tests/testthat/test-summary.R tests/testthat/test-profile-targets.R`:
  confirmed implemented-status wording, target parameter names, summary profile
  path, and the remaining derived-summary boundary.
- `LC_ALL=C rg -n '[^\x00-\x7F]' docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md`:
  no matches.
- `git diff --check`: passed.

## Tests Of The Tests

This was a documentation-status slice, so the main test evidence comes from the
already-added `summary` and `profile-targets` regression checks. The combined
focused run verifies the direct `confint()` and `summary()` paths for the same
covariance rows named in the updated documents.

## Consistency Audit

The docs now distinguish three layers:

- implemented direct covariance profile intervals for first fitted
  `mu_sigma` and bivariate `mu` random-intercept correlations;
- planned derived covariance summaries and future `corpairs()` interval columns;
- residual `rho12` as a separate bivariate residual-correlation parameter.

The stale scan found only the intentional statement that derived summary
profile intervals remain planned.

## What Did Not Go Smoothly

Nothing blocking. The only nuance was wording the partial status carefully:
direct covariance rows are profile-ready, but complete double-hierarchical
derived inference is still planned.

## Team Learning

- Ada batched the five documentation slices so the next review can happen once
  rather than after each tiny edit.
- Rose kept the implemented-versus-planned boundary visible.
- Noether kept `mu_sigma`, bivariate group-level `mu`, and residual `rho12`
  separate.

## Known Limitations

- No rendered pkgdown articles were rebuilt in this slice.
- No full package test run was repeated; the focused `summary|profile-targets`
  run covers the changed claims.

## Next Actions

1. Review this documentation batch with the profile-target and summary test
   slices together.
2. If the batch reads cleanly, preserve a commit boundary before starting any
   new modelling behavior.
