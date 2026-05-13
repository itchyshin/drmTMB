# After Task: Bivariate Sigma Scale Covariance

## Goal

Add the first bivariate residual-scale random-effect covariance slice for
Gaussian models: matching labelled random intercepts in `sigma1` and `sigma2`
should estimate a group-level scale-scale correlation without opening a broader
multivariate random-effect grammar.

## Implemented

The bivariate Gaussian path now accepts formulas such as:

```r
drmTMB(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ z + (1 | p | id),
  sigma2 = ~ z + (1 | p | id),
  family = biv_gaussian(),
  data = dat
)
```

The accepted slice is deliberately narrow. Both `sigma1` and `sigma2` must
contain exactly one matching labelled intercept block with the same covariance
label and grouping variable. The fitted model now routes that block through the
bivariate R specification, TMB data, C++ likelihood, fitted-data prediction,
`sdpars$sigma`, `corpars$sigma`, `corpairs()`, `summary()`,
`profile_targets()`, and `check_drm()`.

Unsupported cases still fail early: a scale block in only one response,
unlabelled bivariate scale random effects, mismatched labels, mismatched
grouping variables, bivariate scale slopes, cross-parameter covariance blocks,
`rho12` random effects, and bivariate `meta_known_V(V = V)` combined with
random effects.

## Mathematical Contract

For group `g`, the new labelled scale block contributes to the log-scale linear
predictors:

```text
log(sigma1_i) = X_sigma1_i beta_sigma1 + b_sigma1[group_i]
log(sigma2_i) = X_sigma2_i beta_sigma2 + b_sigma2[group_i]
```

with a two-dimensional group-level distribution:

```text
(b_sigma1_g, b_sigma2_g)' ~ N(0, Sigma_sigma)

Sigma_sigma =
  [ sd_sigma1^2,
    rho_sigma * sd_sigma1 * sd_sigma2;
    rho_sigma * sd_sigma1 * sd_sigma2,
    sd_sigma2^2 ]
```

The unconstrained TMB parameter `eta_cor_sigma` is transformed with the same
bounded-tanh correlation transform used by the existing bivariate `mu1`/`mu2`
random-intercept block. This is a group-level scale correlation, not the
residual coscale parameter `rho12`.

## Files Changed

Implementation and methods:

- `R/drmTMB.R`
- `R/methods.R`
- `R/check.R`
- `src/drmTMB.cpp`

Tests:

- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phylo-utils.R`

Generated reference documentation:

- `man/check_drm.Rd`
- `man/corpairs.Rd`
- `man/drmTMB.Rd`
- `man/predict.drmTMB.Rd`

User and design documentation:

- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`

Recovery aid:

- `docs/dev-log/recovery-checkpoints/2026-05-12-171528-codex-checkpoint.md`

## Checks Run

- `air format R/drmTMB.R R/methods.R R/check.R tests/testthat/test-biv-gaussian.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with 182
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm')"`: passed
  with 282 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed; regenerated
  `man/check_drm.Rd`, `man/drmTMB.Rd`, `man/corpairs.Rd`, and
  `man/predict.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm|profile-targets|summary')"`:
  passed with 556 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- After PR #19 merged into `origin/main` as `98e9e31`, this branch was
  fast-forwarded over #19 and the bivariate `sigma1`/`sigma2` patch was
  reapplied. Conflicts were resolved in `R/drmTMB.R`, `README.md`,
  `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`,
  and `vignettes/which-scale.Rmd`.
- `air format R/drmTMB.R R/methods.R R/check.R tests/testthat/test-biv-gaussian.R`
  after rebasing over PR #19: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|gaussian-random-intercepts|check-drm|profile-targets|summary')"`
  after rebasing over PR #19: passed with 781 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"` after rebasing over PR #19: passed.
- `Rscript -e "pkgdown::check_pkgdown()"` after rebasing over PR #19: passed
  with no problems found.
- `git diff --check` after rebasing over PR #19: passed.
- Updated the remaining generic parser message that said bivariate
  random-effect syntax was planned, so it now names the implemented labelled
  bivariate `mu1`/`mu2` and `sigma1`/`sigma2` intercept paths.
- `rg -n "Bivariate random-effect syntax is planned|Use fixed-effect bivariate formulas|Future bivariate double-hierarchical" R tests README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes`:
  no current non-historical hits.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"` after the parser
  message cleanup: passed with 186 expectations, 0 failures, 0 warnings, and
  0 skips.
- Added a source-map section to
  `docs/design/20-coscale-correlation-pairs.md` connecting Martin's covariance
  reaction norm paper to `drmTMB`'s separate `sigma` and `rho12` formula
  surfaces, and connecting the EGA+GNM paper to the sister-package
  `gllvmTMB` boundary.
- `LC_ALL=C rg -n '[^\x00-\x7F]' docs/design/20-coscale-correlation-pairs.md`:
  no matches after the source-map addition.
- First full `Rscript -e "devtools::test()"` run failed in
  `tests/testthat/test-phylo-utils.R` because the hand-built direct
  `TMB::MakeADFun()` parameter list did not include the new global
  `eta_cor_sigma` parameter stub. Added `eta_cor_sigma = 0` to the fixture.
- `air format tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::test(filter = 'phylo-utils|biv-gaussian')"` after
  fixing the direct TMB fixture: passed with 231 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1965 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "devtools::check()"`: passed with 0 errors, 0 warnings, and
  1 note. The note was `checking for future file timestamps ... unable to
  verify current time`.

`pkgdown::build_site()` was not rerun in this slice.

## Tests Of The Tests

The initial recovered implementation failed on a live bivariate
`sigma1`/`sigma2` random-effect fit with `NA/NaN gradient evaluation`, so the
happy-path test was able to expose an actual wiring bug before the final fix.

The positive test now checks convergence, `pdHess`, broad fixed-effect
recovery, `sdpars$sigma`, `corpars$sigma`, conditional fitted-data
`predict(..., dpar = "sigma1"/"sigma2", type = "link")`, fixed-effect-only
`newdata` predictions, `stats::sigma()`, `corpairs()`, `summary()`,
`profile_targets()`, and the new `check_drm()` row.

The malformed-input tests cover one-sided scale random effects, unlabelled
scale random effects, mismatched scale covariance labels, and bivariate
`meta_known_V(V = V)` with random effects.

## Consistency Audit

The following stale-wording and scope scans were run and recorded in
`docs/dev-log/check-log.md`:

```sh
rg -n 'sigma1`/`sigma2` random effects|Bivariate random slopes, `sigma1`|residual-scale bivariate random effects|bivariate random slopes and residual-scale random effects|random effects in `sigma1`, `sigma2`, or `rho12`|bivariate `mu1`/`mu2` random-intercept correlation' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man tests/testthat/test-biv-gaussian.R
```

This found one intentional older `mu1`/`mu2` sentence in
`docs/design/12-profile-likelihood-cis.md`; the following line now adds the new
`sigma1`/`sigma2` profile-target surface.

```sh
rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R | head -n 220
```

This reviewed the high-density correlation and scale vocabulary touched by the
feature.

```sh
rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\([^V]' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R
```

The hits were expected design or tutorial warnings, not new formula grammar
drift.

```sh
rg -n 'biv_sigma_random_effect_covariance|eta_cor_sigma|corpars\$sigma|sdpars\$sigma|scale-scale' R src tests/testthat/test-biv-gaussian.R docs/design vignettes README.md ROADMAP.md NEWS.md
```

This checked the new implementation, reporting names, tests, and user-facing
status language.

## What Did Not Go Smoothly

The crash recovery patch had the right R-side idea but left the bivariate TMB
data branch sending `n_sigma_re_terms = 0L` while `random_names` included
`u_sigma`. That created an unused random vector and a zero random-effect
Hessian, which surfaced as `NA/NaN gradient evaluation`. The fix was to route
the bivariate `sigma1`/`sigma2` random-effect structure into `make_tmb_data()`.

One early local patch also drifted into unrelated dummy TMB-data branches for
other families. Those edits were backed out before validation; the final
feature slice is limited to the bivariate Gaussian path and shared reporting
methods.

After PR #19 merged, this branch had expected overlap with its independent
univariate `sigma` random-slope parser and documentation changes. The resolved
state keeps univariate `sigma ~ z + (0 + w | id)` support from #19 while still
rejecting bivariate `sigma1`/`sigma2` random slopes and allowing only matching
labelled bivariate scale intercepts.

The full test suite also exposed a small fixture-maintenance issue in the
manual phylogenetic TMB prior test. Adding the new global `eta_cor_sigma` stub
kept that direct TMB fixture aligned with the compiled parameter list without
changing phylogenetic likelihood behaviour.

## Team Learning

Ada should keep starting crashed-thread resumes with `git status`, `git diff`,
and a recovery checkpoint before adding new code. Gauss should treat every new
`random_names` entry as paired with a TMB data path that proves the random
vector is used. Curie's tests should keep combining a real fit, extractor
checks, and negative grammar checks for every new random-effect covariance
slice. Rose should keep recording exact stale-wording searches rather than a
generic "docs checked" note.

## Known Limitations

This is only the labelled bivariate scale-scale intercept covariance slice. It
does not implement bivariate scale random slopes, unlabelled bivariate scale
effects, cross-parameter covariance between location and scale across
responses, `rho12` random effects, or random effects with bivariate
`meta_known_V(V = V)`.

Profile support exposes `eta_cor_sigma` and `log_sd_sigma` targets, but derived
profile intervals for transformed scale-scale covariance summaries remain a
future reporting step.

`devtools::test()` and `devtools::check()` were rerun after this feature.
`devtools::check()` has one local time-verification note and no errors or
warnings.

## Next Actions

Run the full `devtools::test()` and `devtools::check()` before merging this
branch. If those pass, open a focused PR for the bivariate `sigma1`/`sigma2`
intercept-correlation lane. A later PR can decide whether bivariate scale
random slopes or transformed scale-scale covariance intervals belong in the
next narrow slice.
