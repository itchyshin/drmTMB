# Check log: targeted SD priors for two random intercepts

**Date:** 2026-11-13
**R source:** `2a84bc0bbb4d2b81c14280e53efaa09fde620e16`
**Julia source:** `4cf237b9e98d2314016447bc47a32b803e07ada7`

## Change and claim

The `drm_prior_sd_gamma()` selector can target either or both of two distinct unlabelled mean random-intercept groups in the complete-data, unit-weight Gaussian ML route. Fixed-effect priors can be combined with these SD priors. The fit records the data likelihood and prior contributions separately. Bridge v3 carries the targets; fixed-only v1 and single-intercept SD v2 remain separate.

## Focused verification

The frozen fixtures in `tests/testthat/fixtures/two-ri-sd-prior-oracle/` contain 150 parameter points from a separately written dense Gaussian oracle. Tests compare normalized objectives, gradients and full Hessians, including SD/SD and residual-scale/SD cross terms. They exercise target order, malformed targets, response-unit rescaling, replay, fit diagnostics and prior-fit inference guards. All 20 oracle-referenced prior fits converged with code zero and no captured warnings; four ill-conditioned references are assessed by objective and score rather than parameter equality.

An independent reviewer reran this focused check on the pinned R and Julia commits with one thread and the live Julia bridge enabled:

```sh
Rscript --vanilla -e 'testthat::test_local(".", filter = "^two-ri-sd-priors$", reporter = "summary", stop_on_failure = TRUE)'
```

The run used `DRMTMB_JULIA_TESTS=true`, `DRM_TWO_RI_LIVE=1`, `DRMODELS_JL_PATH` set to the pinned Julia worktree, and `JULIA_HOME` set to the Julia 1.10.12 bin directory. It exited zero with one live bridge test and no skips. The live cases cover each SD target, both targets, mixed priors, reversed order, update replay, fixed-only v1 and one-intercept SD v2.

An independent bridge reviewer also ran the v2 contract and duplicate suites with the live v2 flag and frozen one-intercept oracle; seven live tests passed without skips. Seven deliberately wrong oracle objectives were detected. These checks do not establish a separate bridge-level fixed-point Hessian comparison.

## Remaining gates

Four full R repository shards passed on Totoro against `c489e08cdf324073fe5bdbf5a8d07ffa13e8a6ef`, using R 4.6.1 and `NOT_CRAN=true`. Each exited zero with one spelling-output NOTE. Their respective warning counts were 17, 32, 25 and 43, and skip counts were 367, 129, 123 and 89. The full logs retain those warnings and skips; live Julia checks were run separately as described above. The earlier `f90a7453` full run had three failures; the `c489e08c` tests and skip census address them.

Hosted R check shards on `f90a7453` stopped before package tests because the C17/C14 receipt pins an earlier `R/drmTMB.R` blob. Two isolated 12-fit reruns on `c489e08c` passed their fit checks and matched the historical summaries exactly. The protected receipt and manifest remain unchanged, so the hosted receipt gate is still unresolved. All four hosted coverage shards subsequently passed on `fe58d0a292a2ad865575205de2fdcbad321aa1ad` (run `43528354837`). The four hosted R CMD check shards on that same commit failed before package tests at the stale receipt gate (run `43528354676`).

The full Julia suite is pending separate approval for its expected runtime above three hours. Full checks on the final integrated source, CI, scope review and merge readiness remain open. No release is claimed.
