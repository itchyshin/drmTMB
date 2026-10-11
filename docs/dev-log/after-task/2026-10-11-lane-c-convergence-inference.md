# Lane C: convergence and inference reporting

## Goal

The reader is a drmTMB maintainer deciding what to merge from the
2026-10-11 bug-fix campaign. Lane C was assigned eleven code-review and
test-sweep findings about whether `convergence_status()`, `is_converged()`,
`check_drm()`, and `confint()` tell users the truth about a fit. Six of them
(#1452, #1458, #1470, #1478, #1496, #1251) were already targeted by open
Cursor pull requests #1501, #1503, and #1505, so this lane did not duplicate
them. This branch fixes four of the remaining five (#1387 moved to another lane)
and two items the coordinator added: #802 and a `check_known_v()` tolerance
bug found under #710.

## Implemented

**#1469, diverging scale predictor reported as converged.** The n = 8
`sigma ~ x` fits from the edge grid reproduce on main: reps 29, 36, and 40 are
`"converged"` while their fitted `log(sigma)` spans 18 to 20 units and its
minimum sits below the lower clamp bound of -12. Restarting `nlminb` from the
returned optimum does not move the objective, so this is not an early stop.
The likelihood has no finite maximum (the location line passes through one
observation while its scale shrinks to zero), and the reported optimum is set
by the clamp band, which is why `y` and `y / sd(y)` disagree. New helpers
`drm_unbounded_scale_families()` and `drm_lower_clamp_unbounded()` in
`R/drmTMB.R` recognise this signature: a lower-clamp hit, a within-response
`log(sigma)` spread above `log(1e4)`, a continuous family (Gaussian,
lognormal, Student, skew-normal, Gamma, and their bivariate forms), and no
`meta_V()`. Such fits now warn at fit time (`drmTMB_clamp_active_warning`),
`convergence_status()` returns `"degenerate"`, and the `check_drm()`
`logsigma_clamp_active` row is a warning. A scale that is small everywhere, a
user-narrowed band, an NB2 Poisson limit, and a meta-analysis at tau = 0 keep
their earlier behaviour.

**#1317, REML Wald `confint()` returned NA.** Under `REML = TRUE` the mean
coefficients are TMB random effects, so the Wald branch's `cov.fixed` lookup
found nothing while `vcov()` and `summary()` read the full REML covariance.
`wald_reml_integrated_variances()` in `R/profile.R` now fills those variances
from `sdr$cov`, keyed by `names(sdr$value)`, the same source `vcov()` uses.
Profiling such a coefficient still cannot work; the abort now names
`method = "wald"`, `method = "bootstrap"`, and `REML = FALSE`.

**#1336, skew-normal `nu` Wald SEs near the Gaussian null.** New
`check_drm()` row `skew_normal_nu_wald` is a note when a fitted slant is
within 2 of zero or changes sign across observations, and `?skew_normal`
states the caveat with the audit's 0.24 type-I error. The numerics lane
supplied an equivalent untested draft; its threshold of 2 was adopted. Its
advice to use a likelihood-ratio test via `anova()` was replaced with
`logLik()`/`AIC()` because `anova.drmTMB()` aborts for every fit.

**#1315, percentile bootstrap doubles the ML bias.** Option (A) of
`docs/design/274-bootstrap-interval-bias.md`: a new "Bootstrap intervals on
biased targets" section of `?confint.drmTMB`. No code change; options (B)
and (C) add a public argument and are left for the owner.

**#802, `corpairs()` silently ignored `newdata`.** On main a `rho12 ~ x`
fit reports `conf.status = "derived_interval_unavailable"` and a supplied
`newdata` falls through `...` unused, while
`confint(fit, parm = "rho12", newdata = grid, method = "profile")` already
returns row-specific profile intervals. `corpairs()` now aborts
(`drmTMB_corpairs_newdata_unsupported`) and names that route and
`predict_parameters()`; `?corpairs` says the same. Expanding `corpairs()`
itself over `newdata` would be an API change and is left to the owner.

**#710 follow-up, `check_known_v()` rank tolerance.** Lane B found that the
tolerance `sqrt(eps) * max(abs(eig), 1)` had an absolute floor, so a
well-conditioned known `V` on a small numeric scale was reported as
singular. The floor is removed; the tolerance is now relative to the largest
eigenvalue.

**Owner decision 4 (#1469, #1273): flag-only `check_drm()` rows.** Two
rows were added to `R/check.R`. Each appears only when it fires, as a note,
and none changes an estimate:
- `beta_binomial_sigma_boundary` fires when the extra-binomial variance,
  `(trials - 1) * sigma^2 / (1 + sigma^2)`, is below 1e-3 on some rows. In
  #1273, log sigma was -8.3 in drmTMB and -4.2 in DRModels.jl on the same
  likelihood.
- `direct_sd_clamp_active` fires when a group-level log-SD from an
  `sd(group)` formula is outside the clamp band at the optimum.

The decision also asked for a residual-outlier row and a tighter
`is_converged()` (a Newton step in standard-error units). The outlier row is
#1335, which the convergence lane implements as
`check_response_residual_outliers()`; a version written here was removed to
avoid a duplicate row. Open PR #1503 already implements the gradient rule for
#1452 in the same functions, so it was not duplicated either.

**Review follow-up.** An independent review of this PR found two should-fix
items, both addressed. The #1469 verdict is now computed once at fit time and
stored as `fit$scale_clamp_unbounded`, so `convergence_status()` agrees with
the fit-time warning when `keep_tmb_object = FALSE`. `?drmTMB` no longer says
REML Wald rows are `NA`. The review also showed that the clamp-hit condition
depended on the units of `y`: a well-posed heteroscedastic fit rescaled by
1e-3 was flagged. The verdict now also requires the smallest-scale
observation to be fitted exactly (standardized residual below 1e-3). On the
#1469 fits that residual was 1e-5 to 1e-7; on the reviewer's well-posed
example it was about 0.2 on both unit scales.

**Owner decision 17 (#1315): opt-in basic and bias-corrected bootstrap.**
`confint(..., method = "bootstrap", bootstrap_interval = c("percentile",
"basic", "bc"))` keeps the percentile interval as the default. The basic and
BC intervals reuse the same draws. They are computed on the link scale for
known monotone transforms, so SD intervals stay positive and correlation
intervals stay inside (-1, 1). BCa is not implemented because it needs n
jackknife refits per target. Passing the argument with another method
aborts.

**#1387** was dropped from this branch at the coordinator's request after it
was already implemented here: the performance lane owns it, and it shipped
in #1510. The rebase onto current `main` keeps that merged profile-trace
API rather than replaying the older per-evaluation rewrite.

## Rebase onto current main (2026-10-11)

The five feature commits were replayed onto `6beb1f2a0`. `R/julia-bridge.R`
is unchanged versus `main`. `Rscript tools/write-env-skip-census.R` rewrote
`inst/extdata/env-skip-census.tsv` (873 skip call sites) and the artefact is
byte-identical to `main`. C17 was recertified as `pr-1509-rebase`
(`--tolerance 1e-10`, `|change| 0.000e+00` on mc-0568/0569/0576). The PR
Refs lines are trimmed to `#1317`, `#1336`, `#1315`, `#802`, and `#710`;
`#1469` stays implemented on the branch and is left for Shinichi.

## Files Changed

`R/check.R`, `R/drmTMB.R` (clamp helpers and fit-time warning only),
`R/profile.R`, `R/methods.R` (`corpairs.drmTMB()` and its roxygen only), `R/family.R` (skew-normal roxygen paragraph), the matching
hand-edited `man/convergence_status.Rd`, `man/confint.drmTMB.Rd`, and
`man/skew_normal.Rd`, and `man/corpairs.Rd`, design notes 174 and 274, and the new
`tests/testthat/test-lane-c-convergence-inference.R`. The Rd files were edited by hand
to avoid roxygen-version churn, which lane G owns.

## Checks Run

`test-lane-c-convergence-inference.R` passes (17 tests / 81 expectations)
on `pkgload::load_all()` under R 4.3.3. After the rebase, `test-env-skip-census.R`
(3 tests), `test-check-conditioning.R` (10 tests, 2 platform skips), and
`test-arc-d-profile-trace.R` (6 tests / 31 expectations, `export_all = TRUE`)
pass. One `test-dinnage-audit-wave1.R` error is the existing R 4.3.3 `%||%`
gap on `main`, not this branch.

## What Did Not Go Smoothly

The first #1469 criterion, a lower-clamp hit alone, also fired on an existing
test that narrows the band to `c(-0.1, 0.1)`. The within-response spread
condition was added so the flag tracks the unbounded-likelihood signature
rather than any clamp contact.

## Team Learning

Check the open pull request list before coding a campaign issue: three
existing drafts already covered more than half of this lane.

## Design-document Updates

`docs/design/174-controls-and-convergence.md` gains the clamp-degeneracy row,
the REML Wald note, and the bootstrap bias caveat;
`docs/design/274-bootstrap-interval-bias.md` records that option (A) shipped.

## GitHub Issue Maintenance

Issues stay open for the owner. The PR Refs lines are exactly `#1317`,
`#1336`, `#1315`, `#802`, and `#710`. `#1469` remains implemented and is
not listed in Refs.
