# After Task: Constant Sigma Profile Intervals

## Goal

Give users response-scale profile-likelihood intervals for constant residual
scale parameters.

## Implemented

- Added short profile targets for constant `sigma`, `sigma1`, and `sigma2`.
- Mapped those targets to the corresponding `beta_sigma*` intercept on the
  log scale and transformed profile endpoints with `exp()`.
- Kept predictor-dependent response-scale `sigma` intervals out of scope until
  there is a `newdata` or contrast API.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`,
  and `man/confint.drmTMB.Rd`.

## Mathematical Contract

For a constant log-scale model,

```text
eta_sigma = beta_sigma[1]
sigma = exp(eta_sigma)
```

`confint(fit, parm = "sigma", method = "profile")` profiles
`beta_sigma[1]` on the log scale and reports `[exp(L), exp(U)]`. The bivariate
targets `sigma1` and `sigma2` follow the same contract with `beta_sigma1[1]`
and `beta_sigma2[1]`.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `man/confint.drmTMB.Rd`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `air format NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd`
- `rg -n 'O.Dea/Nakagawa|O.Dea-style' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`
- `rg -n 'constant .*sigma|parm = "sigma"|distributional-scale|sigma1|sigma2' R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/confint.drmTMB.Rd pkgdown-site/reference/confint.drmTMB.html pkgdown-site/reference/profile_targets.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

The new univariate test compares `confint.drmTMB()` with an independent
`TMB::tmbprofile()` call on `beta_sigma[1]` and checks the `exp()`
transformation. A neighbouring bivariate inventory check confirms that constant
`sigma1` and `sigma2` map to `beta_sigma1` and `beta_sigma2`.

## Consistency Audit

The source docs, generated Rd, generated pkgdown reference pages, `NEWS.md`, and
the Phase 6 roadmap now say the same thing: constant `sigma` targets are
implemented on the response scale; predictor-dependent response-scale
intervals are planned.

## What Did Not Go Smoothly

No test failure occurred in this slice. The main caution is API naming: short
names such as `sigma` are only safe when the fitted model contains one
constant, interpretable response-scale quantity.

## Team Learning

- Boole: short target aliases should be gated by unambiguous fitted structure.
- Fisher: response-scale interval wrappers still need manual profile checks.
- Pat: users should not have to transform a log-scale interval by hand for the
  common constant-scale model.

## Known Limitations

- Predictor-dependent `sigma`, `sigma1`, and `sigma2` response-scale intervals
  need an explicit `newdata` or contrast API.
- Other transformed direct targets such as constant `nu`, probabilities, and
  ordinal cutpoints remain planned.

## Next Actions

1. Design the `newdata`/contrast grammar for response-scale profile intervals.
2. Add other one-dimensional transformed direct targets only when the
   interpretation is unambiguous.
3. Keep sigma language aligned with public `sigma`, while documenting
   variance conversions only for variance-focused derived summaries.
