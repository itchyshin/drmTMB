# After Task: Constant rho12 Profile Interval

## Goal

Give users a direct profile-likelihood interval for a constant residual
correlation in bivariate Gaussian models.

## Implemented

- Added a `rho12` profile target for bivariate Gaussian fits where
  `rho12 = ~ 1`.
- Mapped that target to `beta_rho12[1]` and transformed profile endpoints with
  the same `rho_response()` guard used by prediction.
- Kept predictor-dependent `rho12` response-scale intervals out of scope until
  there is a `newdata` or contrast API.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`,
  and `man/confint.drmTMB.Rd`.

## Mathematical Contract

For a constant residual-correlation model,

```text
eta_rho12 = beta_rho12[1]
rho12 = rho_response(eta_rho12)
```

`confint(fit, parm = "rho12", method = "profile")` profiles
`beta_rho12[1]` on the unconstrained scale and reports the interval after
applying `rho_response()` to both endpoints.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `man/confint.drmTMB.Rd`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`
- `git diff --unified=0 -- R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-constant-rho12-profile-interval.md man/confint.drmTMB.Rd | LC_ALL=C rg -n '^\+.*[^\x00-\x7F]'`
- `rg -n 'O.Dea/Nakagawa|O.Dea-style' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`
- `rg -n 'constant residual|parm = "rho12"|rho12_tanh|predictor-dependent .* response-scale' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

The new test compares `confint.drmTMB()` with an independent
`TMB::tmbprofile()` call on `beta_rho12[1]`, then checks that the interval is
transformed with `rho_response()`. A neighbouring inventory test confirms that
predictor-dependent `rho12` does not advertise the shortcut `rho12` target.

## Consistency Audit

Roxygen, generated Rd, pkgdown reference pages, `NEWS.md`, and the Phase 6
roadmap now describe the same implemented scope: constant residual `rho12`
profile intervals are ready; predictor-dependent response-scale `rho12`
profiles are planned.

## What Did Not Go Smoothly

The first targeted test run failed because the unsupported-ordinal-target test
matched old wording from the profile error message. The test now checks the
stable reason, `ordinal-cutpoint-internal`, rather than the full prose.

## Team Learning

- Boole: keep response-scale target names short only when the fitted model has a
  single unambiguous quantity.
- Fisher: compare every new interval path with a manual profile before trusting
  wrapper output.
- Rose: wording changes in shared error messages need targeted tests that
  assert stable meaning, not the whole sentence.

## Known Limitations

- Predictor-dependent `rho12` response-scale intervals still need a `newdata` or
  contrast API.
- Derived summaries such as residual covariance, repeatability, phylogenetic
  signal, and double-hierarchical correlation-pair summaries remain planned.

## Next Actions

1. Design `rho12` response-scale intervals at named covariate values.
2. Add direct residual-scale profile targets where the TMB parameter is already
   one-dimensional and interpretable.
3. Keep the profile target table synchronized with `corpairs()` as structured
   covariance layers arrive.
