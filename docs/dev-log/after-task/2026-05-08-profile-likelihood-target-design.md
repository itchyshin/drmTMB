# After Task: Profile-Likelihood Target Design

## Goal

Clarify how future profile-likelihood confidence intervals should name targets,
handle boundary cases, and distinguish direct TMB parameters from derived
quantities without implying that the API is already implemented.

## Implemented

- Added a current-status section to
  `docs/design/12-profile-likelihood-cis.md` stating that
  `confint.drmTMB(method = "profile")` is planned but not implemented.
- Defined public target examples such as `fixef:mu:x`,
  `sd:mu:(1 | id)`, `cor:mu:cor((Intercept),x | id)`, and
  `fixef:rho12:(Intercept)`.
- Replaced the stale `confint(fit, parm = "sd_id", method = "profile")`
  example with the fitted-object target grammar.
- Added boundary-result fields, one-sided interval control flow, correlation
  guards near `-1` and `1`, and implementation-stage tests.
- Updated `NEWS.md` and `ROADMAP.md` so the design status is discoverable from
  the main project files.

## Mathematical Contract

For a parameter `theta`, the profile-likelihood interval is based on

```text
D(theta_0) = 2 * (logLik_hat - logLik_profile(theta_0))
```

where `logLik_profile(theta_0)` fixes the target and re-optimizes all nuisance
parameters. For a 95% interval, the accepted set is

```text
logLik_hat - logLik_profile(theta) <= qchisq(0.95, 1) / 2
```

For correlations, response-scale candidates must stay in the open interval
`(-1, 1)` and internal profiling can use unconstrained transformed parameters
such as `eta_cor_mu` or the `rho12` linear predictor.

## Files Changed

- `docs/design/12-profile-likelihood-cis.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-profile-likelihood-target-design.md`

## Checks Run

- `git diff --check`
- `rg -n 'sd_id|dpar:rho12|two threshold crossings|confint\\(fit, parm = "sd_id"|O.Dea-style|O.De[aA]-style|biological data' docs/design/12-profile-likelihood-cis.md NEWS.md ROADMAP.md README.md docs vignettes`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: clean.
- Source-map render: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.
- Stale-pattern scan: no active stale profile-CI examples in the profile design,
  NEWS, roadmap, README, or current vignettes; remaining hits were historical
  logs or intentional symbolic notation in
  `docs/design/18-random-effect-scale-models.md`.

## Tests Of The Tests

No implementation tests were added because this task is a design clarification.
The design now names the test suite that must exist before implementation is
complete: direct SD profiles, phylogenetic SD profiles, group-level correlation
profiles, boundary SDs, unsupported-target errors, and a diagnostic grid check
against `uniroot()` bounds.

## Consistency Audit

- `rho12` remains the residual bivariate correlation parameter.
- Residual-correlation formula coefficients now use the fixed-effect namespace:
  `fixef:rho12:(Intercept)`.
- `phylo()` target labels use fitted-object labels, while the design still says
  model syntax must provide `tree = tree`.
- Boundary flags are now part of the planned return object rather than hidden
  warnings.

## What Did Not Go Smoothly

The first draft mixed `dpar:` and `fixef:` namespaces and kept a stale `sd_id`
example. Fermat caught both before the design hardened into public API wording.

## Team Learning

Profile-CI design needs three names for every quantity: user-facing target,
fitted-object label, and internal TMB parameter. Future design notes should
write all three before discussing implementation machinery.

## Known Limitations

- `confint.drmTMB(method = "profile")` is still planned, not implemented.
- Nonlinear derived profiles for ICCs, repeatability, phylogenetic signal, and
  covariance-matrix correlations still require fix-and-refit machinery.
- Parametric bootstrap fallback remains a later phase.

## Next Actions

- Add central model-type documentation for `model_type = 1`, `2`, `3`, and the
  hidden phylogenetic helper branch.
- Clean any stale location-scale prose now that `sd(group) ~ x_group` is
  implemented.
- Only begin profile-CI code after fitted-object target inventories are stable.
