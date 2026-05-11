# After Task: Newdata Profile Intervals

## Goal

Let users profile response-scale `sigma`, `sigma1`, `sigma2`, and `rho12`
values at specific predictor rows without manually transforming link-scale
coefficient intervals.

## Implemented

- Added a `newdata` argument to `confint.drmTMB()`.
- When `newdata` is supplied and `method` is omitted, `confint()` now uses the
  profile path because row-specific response-scale intervals are not Wald
  intervals.
- Added row-specific profile intervals for fitted `sigma`, `sigma1`, `sigma2`,
  and `rho12` values by profiling the fixed-effect linear predictor for each
  row and then applying `exp()` or `rho_response()`.
- Kept arbitrary multi-row contrasts, modelled group-SD profiles, ordinal
  transformations, and derived summaries out of scope.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`,
  and `man/confint.drmTMB.Rd`.

## Mathematical Contract

For a supplied row with design vector `x_sigma`,

```text
eta_sigma = x_sigma beta_sigma + offset_sigma
sigma = exp(eta_sigma)
```

`confint(fit, parm = "sigma", newdata = row)` profiles
`x_sigma beta_sigma` with `TMB::tmbprofile()`, adds the fixed offset, and
reports `[exp(L + offset), exp(U + offset)]`.

For bivariate residual correlation,

```text
eta_rho12 = x_rho12 beta_rho12 + offset_rho12
rho12 = rho_response(eta_rho12)
```

The same profile path reports
`[rho_response(L + offset), rho_response(U + offset)]`.

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

## Tests Of The Tests

The new `sigma` and `rho12` tests each compare `confint.drmTMB()` with an
independent `TMB::tmbprofile()` call using the same row-specific `lincomb`
vector. The tests also check response-scale transformation, row labels,
unsupported `newdata` targets, explicit Wald rejection, and the convenience path
where `newdata` implies `method = "profile"`.

## Consistency Audit

The source documentation and roadmap now say that constant short targets are
available through fitted-object target names, while predictor-dependent
response-scale values are generated from `newdata` rows at call time. The docs
still leave derived summaries, ordinal transformations, and custom contrasts as
planned work.

## What Did Not Go Smoothly

The first implementation made users specify `method = "profile"` even though
`newdata` has no Wald path. Pat's review made this feel unnecessarily fussy, so
the final API defaults to profile when `newdata` is supplied and the method is
omitted, while still rejecting explicit `method = "wald"`.

## Team Learning

- Ada: keep the slice narrow enough to verify with manual profile comparisons.
- Boole: `newdata` is a clearer API than inventing target names for every
  possible predictor row.
- Fisher: row-specific response-scale intervals are still direct
  one-dimensional profiles because the target is `X beta`.
- Pat: the common user call should work without knowing the internal target
  table.
- Rose: roadmap wording must now distinguish row-specific profiles from custom
  multi-row or derived contrasts.

## Known Limitations

- Each `newdata` row starts a separate profile and can be slow.
- The path profiles only fixed-effect row values for `sigma`, `sigma1`,
  `sigma2`, and `rho12`.
- Random-effect conditional row-specific intervals, ordinal response-scale
  transformations, modelled group-SD profiles, and derived summaries remain
  planned.

## Next Actions

- Add direct transformed intervals for other stable one-parameter quantities
  only after their response-scale interpretation is settled.
- Design derived profile intervals for repeatability, phylogenetic signal, and
  double-hierarchical correlation summaries separately from direct `X beta`
  profiles.
