# After Task: Silent input drops (#1495, #1482, #1458)

## Goal

Stop three cases where drmTMB accepted a user choice and then silently
changed it. Applied users who set `contr.sum`, `gaussian(link = "log")`,
or `confint(method = "bootstrap")` should either get the requested
behaviour or a loud error or warning.

## Implemented

`#1495`. `drm_droplevels_fixed_predictors()` still drops unused levels of
plain fixed-effect factors, but it now restores a user-set `contrasts`
attribute when the level set is unchanged. When unused levels are
removed, the original contrast matrix no longer matches, so drmTMB warns
(`drmTMB_contrasts_unused_levels`) and uses default coding on the
remaining levels. A `contr.sum` Gaussian fit now names coefficients
`g1`/`g2` and matches `lm()` on the same data.

`#1482`. Implementing log or inverse Gaussian links would be a new
likelihood. The TMB Gaussian branch is identity-mean only, matching
`gllvmTMB`. `drm_family_type()` and the imputation-family classifier now
error on a non-identity Gaussian link, the same pattern Gamma and
Poisson already use. `lognormal()` remains the supported log-scale mean
for positive data.

`#1458`. Percentile intervals are still computed from successful refits
when at least two succeed. The status is no longer a clean
`"bootstrap"` when any requested replicate was dropped:
`bootstrap_conf_status()` returns `"bootstrap_incomplete"` and
`confint()` warns (`drmTMB_bootstrap_incomplete_warning`).
`bootstrap.n` and `bootstrap.failed` already recorded the split; the
status now matches that split. The same rule is applied to Julia-bridge
bootstrap rows.

## Mathematical Contract

No likelihood parameterization changed. Gaussian location remains
`mu = X_mu beta_mu` on the identity scale. Contrast coding changes only
the design-matrix columns for a factor, not the fitted mean surface.
Bootstrap percentiles are still the empirical quantiles of retained
refits; the new status says when that sample is a selected subset.

## Files Changed

- `R/drmTMB.R`: contrast-preserving droplevels; Gaussian identity-link guard.
- `R/missing-data.R`: same Gaussian link guard for imputation families.
- `R/profile.R`: `bootstrap_conf_status()`, incomplete warning, status
  vocabulary.
- `R/julia-bridge.R`: generated Julia status and R-side reconcile.
- `tests/testthat/test-silent-input-drops.R`: one regression block per issue.
- `tests/testthat/test-profile-targets.R`,
  `tests/testthat/test-julia-inference.R`,
  `tests/testthat/test-biv-lognormal.R`: accept the new status.
- `NEWS.md`, `man/confint.drmTMB.Rd`, `docs/design/03-likelihoods.md`,
  `docs/dev-log/check-log.md`, this report.

## Checks Run

This cloud VM had no R toolchain. Local verification used Ubuntu 24.04
R 4.3.3, TMB, and testthat installed for the run — not the package CI
image.

Targeted `pkgload::load_all()` + `testthat::test_file()`:

- `test-silent-input-drops.R`: 5 tests, 0 failed, 0 errors, 0 skipped
- `test-gamma-location-scale.R`: 7 tests, 0 failed, 0 errors, 0 skipped
- `test-biv-lognormal.R`: 6 tests, 0 failed, 0 errors, 0 skipped
- `test-dinnage-audit-wave1.R`: Md-E unused-level SE test passed; one
  pre-existing MSPL `%||%` error under `load_all()` (rlang not imported
  in NAMESPACE; not introduced here)
- `test-julia-inference.R`: the `#1458` mock path needs `{ape}`; after
  installing ape, remaining failures were the same pre-existing `%||%`
  lookup in `new_drmTMB_julia()`. The helper-level
  `bootstrap_conf_status()` / `bootstrap_reconcile_status()` tests
  passed in `test-silent-input-drops.R`.

`R CMD build --no-build-vignettes` produced `drmTMB_0.7.1.tar.gz`.

`R CMD check --as-cran --no-vignettes --no-manual --no-tests` with
`_R_CHECK_FORCE_SUGGESTS_=false`: **3 WARNINGs, 7 NOTEs, 0 ERRORs**.
Examples, including `--run-donttest`, passed. The WARNINGs are
environment/vignette-index issues (`checkbashisms`, `pandoc`,
`inst/doc` skipped because vignettes were not built). One NOTE named
`contrasts<-` on the first check; that call was replaced with
`attr(..., "contrasts") <-`. The remaining `%||%` NOTE is pre-existing.
The full testthat suite was not run under `R CMD check`; it is a
multi-hour shard on this package.

`tools::checkRd("man/confint.drmTMB.Rd")` was clean.

## Tests Of The Tests

The contrast test compares design-matrix names and `lm()` coefficients
on the issue's `contr.sum` repro, and it checks that unused-level
dropping still removes `gc` after a warning. The Gaussian-link tests
assert `drm_family_type()` and `drmTMB()` error on `log`/`inverse` while
`identity` still fits. The bootstrap tests assert the status helper and
a mocked `bootstrap_refit_one()` path that drops one of five refits.

## Consistency Audit

```sh
rg "gaussian\\(link = .log|identity link only|bootstrap_incomplete|contr.sum" NEWS.md docs/design/03-likelihoods.md R/drmTMB.R R/profile.R tests/testthat/test-silent-input-drops.R
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" NEWS.md docs/design/03-likelihoods.md R/drmTMB.R R/profile.R tests/testthat/test-silent-input-drops.R
```

`README.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
and `_pkgdown.yml` were not changed. No new family, formula grammar, or
pkgdown navigation.

## GitHub Issue Maintenance

Fixes `#1495`, `#1482`, and `#1458` in one pull request. The tracker
entries already existed; this task does not open duplicates.

## What Did Not Go Smoothly

This cloud environment had no R toolchain. R 4.3.3, TMB, and testthat
were installed locally to run the verification. That is not the
package's usual 4.6 CI image.

## Team Learning

Silent argument drops should fail like the existing Gamma/Poisson link
guards. A status column the user has to remember to read is not a
warning.

## Known Limitations

Gaussian log and inverse links remain unimplemented. Contrast matrices
are not subsetted when unused levels are dropped; the user must set
contrasts after dropping levels. Bootstrap still judges a refit by
`nlminb` code 0 only (`#1452`). Any failed replicate, including one of
many, is flagged incomplete.

## Next Actions

If a maintainer wants a failure-rate threshold instead of "any dropped
refit", change `bootstrap_conf_status()`. Implementing Gaussian log or
inverse links needs a likelihood design, TMB `link_code`, and
simulation tests.

## Twin notes (DRModels.jl not edited)

- `#1458`: [DRModels.jl#962](https://github.com/itchyshin/DRModels.jl/issues/962).
- `#1482`: no obvious DRModels.jl twin (`Gaussian()` has no stats-family
  link argument). Close sibling noted on the issue:
  GLLVModels.jl#760.
- `#1495`: neighbour [DRModels.jl#1000](https://github.com/itchyshin/DRModels.jl/issues/1000),
  not the same silent-treatment-coding path.
