# After Task: Arc 9 legacy Julia cross-family extractor repair

## Goal

Close #806's silent-`NULL` extractor defect for legacy `drmTMB_julia_xfam` objects.

## Implemented

The constructor now stores `u = 0` response means, response residuals,
point-estimate coefficient metadata, and ML information criteria. Subclass
methods provide `fitted()`, `residuals()`, `predict()`, `fixef()`, and a
point-only `summary()`; `vcov()` fails loudly rather than returning `NULL`.

## Mathematical Contract

For axis k, stored fitted values are `g_k^{-1}(X_k beta_k)` with shared latent
effect `u = 0`. They are not marginal means. Response residuals are
`y_k - fitted_k`. `rho_latent` remains the cross-family latent dependence and
is not native residual `rho12`. No coefficient covariance, SE, Wald interval,
or cross-family inference claim is made.

## Files Changed

`R/julia-bridge.R`, `tests/testthat/test-xfam-bridge.R`, generated Rd/NAMESPACE,
`README.md`, `NEWS.md`, `vignettes/capability-and-limits.Rmd`, `_pkgdown.yml`,
this plan/report, and the check log.

## Checks Run

Focused xfam tests, documentation generation, installed-package loading, and
pkgdown validation passed. Full `devtools::test()` completed with seven
pre-existing estimator-surface line-anchor failures reproduced on untouched
`origin/main`; Arc 9 tests passed. A live Julia attempt was blocked by an
external Julia package-extension incompatibility after isolated instantiation.

## Tests Of The Tests

Mocked bridge payloads cover both dispersionless and dispersion-covariate
axes, exact `u = 0` links/residuals, AIC/BIC identities, stored versus new-data
prediction, and the intended `vcov()`/Wald error path.

## Consistency Audit

The exact scan included `drmTMB_julia_xfam|Julia cross-family|cross-family.*NULL|rho_latent|rho12`
over README, NEWS, limits, design/vignette, R, tests, and pkgdown config. Docs
retain halted/deferred wording and direct readers to native TMB.

## GitHub Issue Maintenance

#806 remains open until this branch has a reviewed PR. No duplicate issue was opened.

## What Did Not Go Smoothly

The unconfigured live bridge initially skipped; an isolated, pinned DRM.jl
checkout then exposed a Julia dependency-extension incompatibility. Full-suite
conformance failures were baseline TSV line drift.

## Team Learning

An inherited S3 method that reads an optional list field is unsafe for a
subclass. Legacy bridge objects need subclass-specific methods or explicit
payload validation, never silent fall-through.

## Known Limitations

Cross-family Julia fitting remains deferred. Full covariance/Wald parity needs
a separately owned DRM.jl API that returns an exact named covariance/index map.

## Next Actions

Review the diff, commit, push, open a draft PR for #806, and merge only after
the PR is clean; retain the baseline conformance issue as separate debt.
