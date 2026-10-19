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

 at the coordinator's request after it was already
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

`test-lane-c-convergence-inference.R` passes (77 expectations) on the
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

## R-reviewer round and rebase onto 4f151444f (2026-10-19)

The R reviewer blocked the branch on three test-hygiene points. All three are
fixed, and the branch is rebased onto main `4f151444f` (#1581).

- Live fits skip on CRAN. The 13 tests in
  `test-lane-c-convergence-inference.R` that fit a model now call
  `skip_on_cran()` first, including the two `R = 30` bootstrap `confint()`
  calls. The four pure-logic tests (clamp signature, Rd text, known-V rank,
  bootstrap endpoint arithmetic) still run on CRAN. The env-skip census gains
  one row, `test-lane-c-convergence-inference.R cran-lane environment runs 13`.
- `confint()` with `bootstrap_interval` and a non-bootstrap method aborts
  with `drmTMB_bootstrap_interval_method_error`. The test asserts the class
  for `method = "wald"` and `method = "profile"` instead of matching the
  message.
- The "not ready for direct profiling" abort carries
  `drmTMB_profile_reml_integrated_error` when the REML-integrated hint
  applies, in both `confint(method = "profile")` and
  `profile()`. Other not-ready targets keep the unclassed error. The test
  asserts the class from both entry points and keeps the check that the
  message names `REML = FALSE`.

### Rebase

The eight branch commits replayed onto `4f151444f`. The only conflict was the C17 ledger TSV in the intermediate recertification commit;
the branch side was kept and the final recertification below rewrote it.
#1581's `summary()` change auto-merged in `R/methods.R`.

### Receipts

- lss-tip-identity: `tools/ci-receipt-staleness.sh` named five stale R/
  hashes, all files this branch changes (`R/check.R`, `R/drmTMB.R`,
  `R/family.R`, `R/methods.R`, `R/profile.R`). `public-001.json` was
  regenerated with the unchanged runner, Julia 1.13.0 and DRModels.jl
  `da8b3f871`, one thread: PASS, 8 of 8 checks. Every result field except
  `runtime` is identical to the prior receipt, and `checker-001.log` is
  byte-identical. The prior receipt is kept under
  `historical-pre-1509-2026-10-19/`.
- C17: `python3 tools/recertify-c17.py --label pr1509-rebase-4f15144
  --tolerance 1e-10`, |change| 0 on mc-0568, mc-0569 and mc-0576. The
  2d2db519f folder was moved aside for the run and restored; `git diff` on it
  is empty. Only the receipt paths and `current_source_sha` changed.

### Checks on this Mac (R 4.6.0, TMB 1.9.21)

- `test-lane-c-convergence-inference.R`: 17 tests, 84 expectations, 0
  failures. Against the pre-round `R/profile.R`, both class tests error, so
  they discriminate. With `NOT_CRAN=false`, 13 tests skip and the 4
  pure-logic tests pass.
- `test-env-skip-census.R`: 3 tests, 0 failures.
- Every command of the CI "Validate generated capability ledger" step,
  including `capability_ledger.py --check` and
  `--check-c14-receipt-equivalence`: pass.
- Full testthat suite at `de082bee0` (`NOT_CRAN=true`, `pkgload::load_all()`,
  four `DRMTMB_TEST_SHARD` shards): 455 of 457 files ran to completion, with
  0 errors, 2 failing tests (3 expectations), 49,175 passing expectations
  and 95 skips. The two failures are `Bernoulli x Bernoulli association
  freezes margins and is symmetric` and `nbinom2 structured sigma recovers
  scale structure (0.4.0 routing fix)`; both fail by the same name and count
  on unmodified main `4f151444f`. `test-julia-tmb-parity.R` skips at file
  level (no live Julia). `test-numeric-kernel-oracle.R` stopped making
  progress in its tweedie kernel tests after 365 passing expectations, as
  #1581 recorded on this Mac with TMB 1.9.21; it was stopped after 11 minutes
  without output, and the 46 files after it in that shard were run
  separately.
- `devtools::document()`: rewrites the same 39 `man/` files as on main
  `4f151444f` (the #1571 drift). The one branch-specific span is in
  `confint.drmTMB.Rd`, where roxygen writes `\verb{(-1, 1)}` and the hand
  edit has `\code{(-1, 1)}`. Not committed.

### Not covered

`summary()` from #1581 keys on `opt$convergence` only, so a
#1469 fit that `convergence_status()` calls `"degenerate"` still prints as
converged there. Whether `summary()` should read the stored verdict is an
owner call. The nearby `newdata`-with-wrong-method aborts in `confint()` are
still unclassed; they were outside this review.
