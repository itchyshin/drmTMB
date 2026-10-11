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

**#1387 was dropped** at the coordinator's request after it was already
implemented here: the performance lane owns it. The tested patch was handed
to that lane and removed from this branch.

## Files Changed

`R/check.R`, `R/drmTMB.R` (clamp helpers and fit-time warning only),
`R/profile.R`, `R/methods.R` (`corpairs.drmTMB()` and its roxygen only), `R/family.R` (skew-normal roxygen paragraph), the matching
hand-edited `man/convergence_status.Rd`, `man/confint.drmTMB.Rd`, and
`man/skew_normal.Rd`, and `man/corpairs.Rd`, design notes 174 and 274, and the new
`tests/testthat/test-lane-c-convergence-inference.R`. The Rd files were edited by hand
to avoid roxygen-version churn, which lane G owns.

## Checks Run

`test-lane-c-convergence-inference.R` passes (47 expectations) on the
branch build, and its new expectations fail on main. Twenty-eight related
files (skew-normal, clamp, check_drm, convergence warning, start contract,
REML, bootstrap, corpairs, meta-analysis known V, profile trace) pass with 0
failures. Full-suite totals are in the PR comment.

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

Issues stay open for the owner. The PR uses `Refs #N`.
