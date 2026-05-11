# After Task: Public Fixed-Effect Confidence Intervals

## Goal

Expose the first public confidence-interval method for `drmTMB` fits without
overclaiming profile support for variance, correlation, ordinal, or derived
summary targets.

## Implemented

- Added `confint.drmTMB()`.
- Made `confint(fit)` return fast Wald intervals for fixed-effect coefficients.
- Made `confint(fit, parm = "fixef:mu:x", method = "profile")` call the
  internal `TMB::tmbprofile()` path for explicit fixed-effect targets.
- Allowed compact fixed-effect labels such as `"mu:x"` as aliases for full
  target names such as `"fixef:mu:x"`.
- Added clear failures for unsupported profile target classes, unknown target
  names, invalid confidence levels, unused Wald `...`, and profile requests
  after fitting with `keep_tmb_object = FALSE`.

## Mathematical Contract

Wald intervals are computed on the fitted coefficient link scale as
`estimate +/- qnorm((1 + level) / 2) * SE`, using the fixed-effect covariance
matrix from `vcov(fit)`.

Profile intervals use `TMB::tmbprofile()` with a one-hot `lincomb` over the
optimized TMB parameter vector, so duplicated internal parameter names such as
`beta_mu` are selected by the profile target index. In this slice, profile
intervals are supported only for direct fixed-effect rows from
`drm_profile_targets()`.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NAMESPACE`
- `man/confint.drmTMB.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md NEWS.md _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::document()"`: passed and wrote `NAMESPACE` plus
  `man/confint.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: first run failed
  on vector names in the new Wald test; after tightening the expectation it
  passed with 0 failures, 0 warnings, 0 skips, and 67 passing expectations.
- `Rscript -e "devtools::test()"`: passed with 0 failures, 0 warnings, 0 skips,
  and 1547 passing expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/confint.drmTMB.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`: passed with
  0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.

## Tests Of The Tests

The new Wald test checks the full numeric formula against `vcov(fit)` and
`qnorm()`, not only object shape. The profile test checks the public method
against an independently constructed `TMB::tmbprofile()` call with the same
one-hot `lincomb`. The failure-path test covers unsupported random-effect SD
targets, missing profile target names, unknown target names, invalid confidence
levels, and a missing retained TMB object.

## Consistency Audit

- `rg -n 'not a public `confint\(\)`|no `confint\.drmTMB|confint\.drmTMB\(method = "profile"\).*not implemented|public `confint\(\)` API\s*closed' R tests/testthat docs/design vignettes README.md ROADMAP.md NEWS.md`:
  passed with no matches after updating the design note and roadmap.
- `rg -n "O.Dea/Nakagawa|O.Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md ROADMAP.md NEWS.md _pkgdown.yml man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html --glob '!pkgdown-site/search.json'`:
  passed with no matches.
- `rg -n "confint|profile-likelihood|profile likelihood" README.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/12-profile-likelihood-cis.md vignettes/model-workflow.Rmd vignettes/which-scale.Rmd NEWS.md`:
  confirmed `NEWS.md`, `ROADMAP.md`, and the profile design note now describe
  the same partial Phase 6 status.

## What Did Not Go Smoothly

The first test run compared data-frame columns to named vectors and failed even
though the numeric values were correct. The fix was to remove names from the
expected vector. Rose also caught stale roadmap/design wording that still
described the public profile method as unimplemented.

## Team Learning

Ada should treat public-method slices as status-inventory changes, not just code
changes. Rose's stale-status check belongs before, not after, the final check
run. Boole's alias concern was useful here: accepting both `fixef:mu:x` and
`mu:x` makes the method easier for users coming from `summary(fit)`.

## Known Limitations

- Profile intervals are fixed-effect only.
- Random-effect SDs, random-effect correlations, residual-scale parameters,
  transformed ordinal cutpoints, and derived summaries still need boundary-aware
  profile paths.
- Profile intervals require `fit$obj`, so they are unavailable after fitting
  with `drm_control(keep_tmb_object = FALSE)`.

## Next Actions

- Add profile intervals for direct SD and correlation targets with boundary
  flags.
- Decide how much of the target inventory should become user-visible.
- Add simulation coverage comparing Wald and profile intervals for small
  Gaussian location-scale examples.
