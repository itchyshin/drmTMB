# After Task: NB2 Sigma Random-Effect SD Regression

## 1. Goal

Add a first native-TMB NB2 scale-endpoint slice for a group-predictor-dependent
standard deviation on one ordinary random intercept in the `sigma` linear
predictor.

## 2. Implemented

`bf(count ~ x, sigma ~ 1 + (1 | site), sd(site, dpar = "sigma") ~ habitat)`
now fits complete-data NB2 models when `mu` has fixed effects and the model has
no other random or structured effects and no zero inflation. The SD predictor
must be constant within site. R builds and validates the target-specific
design, start values, parameter map, and public coefficient output; the TMB
NB2 likelihood applies the predicted group SD to the latent effect on
`log(sigma)`.

The mathematical contract is: for site `g`, the latent log-overdispersion
effect is `a_g = exp(W_g alpha) u_g`, where `u_g ~ Normal(0, 1)`, and it is
added to the existing fixed-effect `log(sigma)` predictor. NB2 `sigma` retains
its existing meaning and link. This change does not add a residual scale
parameter or alter the NB2 likelihood parameterization.

## 3a. Decisions and Rejected Alternatives

The existing `sd(group, dpar = "sigma")` syntax and common random-scale
structures are reused. The slice stays limited to one ordinary sigma
intercept because other random-effect combinations lack tests here. The
predictor-dependent SD remains on the latent log-sigma effect; no new NB2
dispersion parameterization or family-specific formula syntax was introduced.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-nbinom2-sigma-sd-regression.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `vignettes/formula-grammar.Rmd`
- `README.md`
- `NEWS.md`
- `.unlazy/general-sd-regression/GATES.md`

## 5. Checks Run

- The new test first failed at the existing builder rejection, before any fit.
- The focused NB2 sigma-SD test passed after implementation. It checks seeded
  coefficient recovery, group-named SD predictions, the conditional `sigma`
  link contribution, finite coefficient covariance, constant-SD equivalence,
  and rejection of a predictor that varies within site.
- `Rscript -e 'parse("R/drmTMB.R")'` passed.
- The neighboring NB2 filter passed `hurdle-nbinom2-sd-regression`,
  `nbinom2-location-scale`, `nbinom2-sd-regression`,
  `truncated-nbinom2-sd-regression`, and `zi-nbinom2-sd-regression`.
  It also exposed one separate failure in
  `truncated-nbinom2-location-scale.R:366`: the test expected a `hu` formula
  with `truncated_nbinom2()` to error, but the call reached a fit and emitted a
  singular-convergence warning. This builder path does not use the new NB2
  sigma-SD route; the failure remains unresolved and is not counted as a pass.
- `pkgdown::check_pkgdown()` passed with no reported package problems.
- `pkgdown::build_site()` was stopped after a renderer reported
  `No space left on device`. The full site render is therefore unverified; the
  output also contained repeated existing Pandoc `--mathml` deprecation
  warnings.
- `git diff --check` passed for the feature and documentation paths.
- Open-issue searches for `NB2 sigma SD regression`, `sd_sigma NB2`, and
  `predictor-dependent random-effect SD NB2` found no matching issue. Issue
  #1463 is a broad historical test-sweep record with no feature-specific
  tracking; no issue was changed.

## 6. Tests of the Tests

The new test reproduced the unsupported-model error before the code change. Its
negative case uses a within-site-varying predictor and requires the builder to
reject it. The constant-SD case compares the fitted likelihood and SD with the
existing NB2 sigma-random-intercept model. The information-rich recovery fixture
uses independent synthetic data with 240 groups and 40 observations per group.

## 8. Consistency Audit

The design reference, formula-grammar reference, formula-grammar vignette,
README status, NEWS, roadmap, known-limitations page, and general-SD gate ledger
now describe the same narrow native slice and retain the open Julia and
uncertainty limits. The exact inventory search was:

```sh
rg -n 'NB2 sigma-endpoint|predictor-dependent SD for one ordinary `sigma`|complete-data slice fits a predictor-dependent SD for one ordinary' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

## 7a. Issue Ledger

Two focused open-issue searches returned no matching issue. The broad result
`#1463` records an unrelated October test sweep. No issue was created, closed,
or edited.

## 9. What Did Not Go Smoothly

The first synthetic fixture, with 72 groups and 25 observations per group,
produced weak coefficient recovery. A larger pilot showed that 240 groups with
40 observations per group gave a more informative design. A broad test-name
filter also included neighboring truncated-NB2 tests and surfaced the separate
`hu` expectation failure noted above. The full pkgdown build exhausted the
available write space and was stopped before completion.

## 11. Team Learning

For recovery tests of a random scale parameter in a discrete family, group
count and within-group replication both matter. Keep the fixed seed, retain the
failure case, and report this as point-fit evidence rather than interval
calibration. Use exact test-file selection when a package has overlapping
family-name filters.

## 10. Known Residuals

This is one complete-data native-TMB NB2 `sigma` random-intercept slice. It does
not cover Julia, other distributions, random slopes, correlated or structured
effects, simultaneous `mu` random effects, zero-inflated/truncated/hurdle scale
random effects, profile or bootstrap refits, or calibrated uncertainty. It
does not close any programme-wide gate.

## 12. Cross-Product Coverage

This slice does NOT cover Julia, any other response family, random slopes,
correlated or structured effects, simultaneous `mu` random effects,
zero-inflated/truncated/hurdle scale random effects, save/reload or profile and
bootstrap refits, or calibrated uncertainty. No R/Julia same-data parity claim
was tested. Next, map the slice to its exact frozen capability row, add the
equivalent Julia route and bridge check, and continue the remaining family and
effect inventory. Rerun the full site build after restoring sufficient write
space.
