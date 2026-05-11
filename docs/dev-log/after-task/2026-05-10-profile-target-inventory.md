# After Task: Internal Profile Target Inventory

## Goal

Create the first internal inventory of profile-likelihood targets so a later
`confint.drmTMB(method = "profile")` implementation can start from fitted-object
names instead of inventing target grammar at the end.

## Implemented

- Added `drm_profile_targets()` as a private helper in `R/profile.R`.
- Added `tests/testthat/test-profile-targets.R` with self-contained fixtures for
  Gaussian location-scale, hurdle NB2, correlated random-effect blocks,
  modelled group scales, bivariate residual `rho12`, and ordinal cutpoints.
- Updated `docs/design/12-profile-likelihood-cis.md` to describe the current
  private helper, inventory columns, random-effect SD grammar, and raw
  `theta_ord` boundary.

## Mathematical Contract

The helper does not compute intervals. It maps fitted-object quantities to the
TMB parameters that can eventually be profiled:

- fixed-effect rows use `beta_<dpar>`, with public hurdle `hu` mapped to the
  internal `beta_zi` vector used by the hurdle likelihood;
- ordinary random-effect SD rows use `log_sd_mu` or `log_sd_sigma` and record
  an `exp` transformation;
- random-effect correlation rows use `eta_cor_mu` and record a `tanh`
  transformation;
- bivariate residual correlation coefficients use `beta_rho12`;
- ordinal rows are raw `theta_ord` parameters, not transformed cutpoint
  estimates;
- modelled group scales such as `sd(id) ~ gx` are marked as derived targets
  because their row-specific SDs are not single direct `tmbprofile()` targets.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-profile-target-inventory.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `git diff --check`
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O’Dea-style|Nakagawa" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-target-inventory.md ROADMAP.md README.md NEWS.md vignettes`
- `rg -n "tmb_parameter.*beta_hu|fixef:hu.*beta_hu|profile.*beta_hu" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-target-inventory.md`

The focused profile-target suite passed with 46 expectations, no warnings, and
no skips. The full package test suite passed with 1526 expectations, no
warnings, and no skips. The pkgdown site rebuilt successfully. The stale
wording and `beta_hu` target scans had no matches.

## Tests Of The Tests

The first filtered run failed before the test repair because the new test file
borrowed `new_corpairs_group_data()` and `new_corpairs_biv_data()` from another
test file. That made the test pass only when the full suite happened to source
other files first. The repaired tests define their own fixtures and now pass
under `devtools::test(filter = "profile-targets")`.

The initial six-row Gaussian location-scale fixture also produced an
`sdreport()` warning. It was replaced with a fixed-seed simulated fixture that
keeps the target rows stable without warning.

Noether's review exposed a real missed mapping for hurdle models: public `hu`
coefficients are stored in the internal `beta_zi` parameter vector. The new
hurdle test now locks this down.

## Consistency Audit

- The implementation remains internal; no roxygen, `NAMESPACE`, `_pkgdown.yml`,
  or `NEWS.md` update is required for a user-facing function.
- The profile-CI design document now names the private helper and explicitly
  says no public profile-likelihood interval API exists yet.
- The table uses `rho12` for residual bivariate correlation and keeps the
  public `sigma` convention unchanged.
- The ordinal wording now states that raw `theta_ord` rows are internal
  profiling parameters.

## What Did Not Go Smoothly

The first implementation was too eager about reusing test helpers across files,
which hid a filtered-test failure. It also used generic column names
(`internal`, `class`) that would have been poor seeds for a later public API.
Most importantly, the first fixed-effect mapping forgot that hurdle `hu` is a
public name backed by the same compiled `beta_zi` vector used for zero
inflation.

## Team Learning

Curie should always run or mentally simulate filtered test execution, not just
full-suite execution. Boole should review private table schemas early when they
are likely to become public grammar. Noether should keep checking public
distributional parameter names against the compiled TMB parameter vectors,
especially where two user-facing concepts share one internal route.

## Known Limitations

- `confint.drmTMB(method = "profile")` is still not implemented.
- `drm_profile_targets()` is private and may still change before any public
  profile API is exposed.
- Derived targets are inventoried but not profiled.
- Transformed ordinal cutpoint estimates are not yet separate profile targets.

## Next Actions

1. Add the constrained-profile engine for direct fixed-effect targets.
2. Add profile tests that compare direct fixed-effect intervals against a simple
   likelihood drop calculation.
3. Extend the same engine to direct random-effect SDs and correlations once
   boundary handling is explicit.
