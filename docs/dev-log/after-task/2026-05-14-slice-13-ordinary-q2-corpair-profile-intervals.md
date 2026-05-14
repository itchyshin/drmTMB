# After Task: Slice 13 Ordinary q2 corpair Profile Intervals

## Goal

Close the first ordinary `corpair()` inference loop by letting users profile the
response-scale latent correlation at chosen group-level predictor values.

## Implemented

`confint()` now accepts a fitted ordinary q=2 `corpair()` distributional
parameter when `newdata` is supplied:

```r
confint(
  fit,
  parm = 'corpair(id, level = "group", block = "p", from = "mu1", to = "mu2")',
  method = "profile",
  newdata = data.frame(ecology = 0)
)
```

The interval profiles the link-scale linear combination
\(\mathbf{x}_{new}^{\top}\beta_{cor}\) and reports bounds on the response
correlation scale after the guarded transform \(0.999999\tanh(\eta)\).

`corpairs(conf.int = TRUE)` still reports `newdata_required` for modelled
ordinary `corpair()` rows because that row is a summary over many fitted
group-level correlations. The user-facing path for a 95% interval is to choose
the group-level predictor row and call `confint(..., newdata = ...)`.

## Mathematical Contract

For the implemented q=2 route,

\[
\rho_g = 0.999999\tanh(\eta_g),
\qquad
\eta_g = \mathbf{x}_g^\top\beta_{cor}.
\]

Slice 13 profiles \(\mathbf{x}_{new}^{\top}\beta_{cor}\) while reoptimizing
nuisance parameters, then transforms the profile interval to the
correlation scale. It does not add a q=4 correlation-regression
parameterization.

## Files Changed

- `NEWS.md`
- `R/methods.R`
- `R/profile.R`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `man/confint.drmTMB.Rd`
- `man/predict.drmTMB.Rd`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-profile-targets.R`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `/opt/homebrew/bin/air format R/profile.R R/methods.R tests/testthat/test-biv-gaussian.R`: passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::document()'`: passed and refreshed `man/confint.drmTMB.Rd` and `man/predict.drmTMB.Rd`.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); devtools::test(filter = "biv-gaussian", reporter = "summary")'`: passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "profile-targets", reporter = "summary")'`: passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); devtools::test(filter = "biv-gaussian|profile-targets", reporter = "summary")'`: passed after roxygen regeneration.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE); pkgdown::build_reference()'`: passed and refreshed the local article plus affected reference pages.
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `rg -n 'scale and residual-correlation|row-specific response-scale `sigma`, `sigma1`, `sigma2`, and `rho12`|fitted_range_only|newdata_required|corpair\(\)' NEWS.md R man docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site/reference pkgdown-site/articles/phylogenetic-spatial.html tests`: reviewed; only intentional `corpair()`, `newdata_required`, and `fitted_range_only` hits remain.
- `git diff --check`: passed.

## Tests Of The Tests

The bivariate Gaussian test now fits the ordinary q=2 `corpair()` model, calls
`confint(..., newdata = data.frame(ecology = 0.15))`, checks that the interval
is reported on the response correlation scale with transformation
`random_effect_correlation_tanh`, and verifies that the fitted value lies
inside the profile interval. The same test checks that `corpairs(conf.int =
TRUE)` remains `newdata_required` and that `summary(fit)$parameters` points the
user to the newdata interval route.

The profile-targets test keeps the unsupported `newdata` error current now that
ordinary q2 `corpair()` has joined scale and residual-correlation parameters.

## Consistency Audit

The profile-CI design note, `confint()` reference page, `predict()` reference
page, NEWS, known limitations, and the phylogenetic-spatial article now agree:

- link-scale `corpair()` coefficients are profile-ready fixed effects;
- response-scale latent correlations need a supplied group-level predictor row;
- `corpairs()` reports fitted summaries, not row-specific intervals;
- q=4, phylogenetic, and spatial `corpair()` interval work remains later.

## What Did Not Go Smoothly

The shell PATH in this resumed turn omitted `/opt/homebrew/bin` and the R
framework path, so checks used absolute paths for `air` and `Rscript`. The test
surface itself was straightforward because the existing response-scale
`confint(newdata=...)` machinery already used `drm_dpar_link()`.

The first pkgdown article build failed because R could not find pandoc on the
minimal Codex shell `PATH`. Rerunning with `/opt/homebrew/bin` on `PATH` fixed
the environment problem and refreshed the local article/reference pages.

## Team Learning

- Ada: this is a good small slice after a likelihood slice because it improves
  output without expanding model scope.
- Boole: the fitted `corpair()` dpar string is long, but it is unambiguous and
  works consistently in `predict()` and `confint()`.
- Gauss: no TMB likelihood changes were needed; profiling a linear combination
  of `beta_cor_mu` is enough for the q=2 response-scale interval.
- Noether: the interval target is \(\mathbf{x}_{new}^{\top}\beta_{cor}\), not
  the mean of the fitted `corpairs()` row.
- Fisher: profile intervals are now available for scientifically chosen
  predictor values, which is more interpretable than a Wald interval on the
  bounded correlation scale.
- Pat: the docs need to show the exact `parm` string because users will not
  guess it from `corpairs()` alone.
- Emmy: summary rows can point to `use_confint_newdata` without changing the
  `corpairs()` table contract.
- Grace: absolute tool paths are acceptable when the Codex shell PATH is
  minimal, but the check log should record them exactly.
- Rose: keep `corpairs(conf.int = TRUE)` status honest; do not pretend a
  summary row has one natural profile interval.

## Known Limitations

- Only ordinary group-level q=2 `mu1`-`mu2` `corpair()` values can be profiled
  through `newdata`.
- There is still no interval for the mean, minimum, or maximum correlation
  reported by `corpairs()` for modelled rows.
- q=4, phylogenetic, and spatial predictor-dependent `corpair()` models remain
  planned.

## Next Actions

The next modelling slice can either design ordinary q2 location-scale and
scale-scale identifiability checks, or move back to the broader spatial lane if
we decide the ordinary q2 correlation-regression surface is sufficiently closed
for now.
