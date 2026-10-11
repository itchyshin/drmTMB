# Lane C: convergence and inference reporting

## Goal

The reader is a drmTMB maintainer deciding what to merge from the
2026-10-11 bug-fix campaign. Lane C was assigned eleven code-review and
test-sweep findings about whether `convergence_status()`, `is_converged()`,
`check_drm()`, and `confint()` tell users the truth about a fit. Six of them
(#1452, #1458, #1470, #1478, #1496, #1251) were already targeted by open
Cursor pull requests #1501, #1503, and #1505, so this lane did not duplicate
them. This branch fixes the other five.

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

**#1387, profile trace memory.** `drm_profile_trace_object()` stored the full
parameter vector for every objective evaluation. Entries now hold the
objective, any error, and a precomputed direct-SD `clamp_contact` flag; the
lowest-objective parameter vector is kept once as `best`, and the old trail is
available through `keep_par = TRUE`. `drm_profile_direct_sd_clamp_trace()`
reads the flag and falls back to `par` for hand-built traces.

## Files Changed

`R/check.R`, `R/drmTMB.R` (clamp helpers and fit-time warning only),
`R/profile.R`, `R/family.R` (skew-normal roxygen paragraph), the matching
hand-edited `man/convergence_status.Rd`, `man/confint.drmTMB.Rd`, and
`man/skew_normal.Rd`, design notes 174 and 274, the new
`tests/testthat/test-lane-c-convergence-inference.R`, and updated
`tests/testthat/test-arc-d-profile-trace.R`. The Rd files were edited by hand
to avoid roxygen-version churn, which lane G owns.

## Checks Run

The new and updated test files pass (39 and 28 expectations) on the branch
build and fail on main where they test changed behaviour. Twenty related files
(skew-normal, clamp, check_drm, convergence warning, start contract, REML,
bootstrap) pass with 0 failures. Full-suite totals are in the PR comment.

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
