# After task: review fixes on the silent-input branch

Reader: a package contributor checking that `is_converged()` means the
reported optimum is stationary on a scale that does not change when a
predictor is multiplied by a constant.

## Purpose

Code Reviewer blocked draft PR #1503 on the #1452 verdict only. An absolute
cutoff of `1e-8` on the raw gradient flags a rescaled predictor, an
uncentred year, and every `newton_polish = FALSE` fit. This pass replaces
that verdict, records the new status in the Phase 18 runner, rejects factor
and date columns that `cbind()` would otherwise turn into numbers, and
stops the QQ envelope from borrowing one simulation's theoretical quantiles.

## Convergence verdict

`DRM_NEWTON_GRAD_TOL` (`1e-8`) is only the target inside `drm_newton_polish()`.
`convergence_status()` returns `"gradient"`, and `is_converged()` is `FALSE`,
when the Newton step in standard-error units exceeds `DRM_GRADIENT_STEP_TOL`
(`1e-3`):

```text
max |sdr$cov.fixed %*% gradient| / sqrt(diag(sdr$cov.fixed)) > 1e-3
```

`sdr$cov.fixed` is the fixed-effect covariance already stored by
`TMB::sdreport()`, so that product is the Newton step. The check uses the
matrix only when `pdHess` is true. Otherwise the cutoff is `1e-3` on the
largest absolute gradient component. A missing `gradient` field is still not
a failure. A non-finite gradient still is. Coefficients are unchanged.

The fit-time warning (`drmTMB_gradient_warning`) uses the same rule, and it
runs after `sdreport()` so the covariance is available.

## Phase 18

`phase18_run_replicate()` still muffles `drmTMB_gradient_warning`. It now
adds `convergence_status` to the replicate summary when that summary is a
non-empty data frame. A fit that is not a `drmTMB` object stores `NA`.

Left unchanged, and named as follow-ups: the other files under `inst/sim`
that still set `converged` from optimiser code 0, and
`bootstrap_refit_one()` in `R/profile.R`, which still accepts a refit when
`opt$convergence == 0`.

## Factor and date columns inside cbind()

`cbind()` converts a factor to integer level codes before
`prepare_binomial_response()` runs. `drm_reject_cbind_response_columns()`
evaluates each argument of the formula's `cbind()` call in `data` and
rejects a factor, ordered factor, `Date`, or `POSIXt` column. The binomial
builder, the beta-binomial builder, the Julia bridge, and the cross-family
Julia axis all call it. A single-column `Date` or `POSIXt` response is
rejected by `drm_reject_date_response()`. `cumulative_logit()` still accepts
an ordered factor.

## QQ envelope

Each realization already has its own theoretical quantiles,
`qnorm(ppoints(m))` on its finite residuals. When those lengths differ,
`drm_adequacy_envelope()` interpolates every realization onto the shortest
realization's theoretical grid. That grid sits inside the longer
realizations, so the ribbon does not pair unequal ranks or copy the first
simulation's quantiles. Equal lengths still use the per-rank range.

## Ledger and tests

`python3 tools/recertify-c17.py --label triage-d --tolerance 1e-10` reproduced
`mean_tau_relative_error` exactly (`|change|` 0 on mc-0568, mc-0569, and
mc-0576). The model-15 source fingerprint did not move. Receipt:
`docs/dev-log/implementation-recovery/2026-10-08-triage-d-c17c2-c14-final-source-compatibility`.
`python3 tools/capability_ledger.py --check` passed.

`test-fit-convergence-warning.R` 52 passed, `test-factor-response.R` 31
passed, `test-quantile-residual-nonfinite.R` 24 passed,
`test-phase18-sim-runner.R` 76 passed, `test-binomial-response.R` 60
passed, `test-adequacy.R` 23 passed. None failed.

## What this does not change

The likelihood, the Newton update, and the plotted finite residuals are the
same. Julia `is_converged()` still reads optimiser code 0 (#1483).
`check_fixed_gradient()` still uses a live gradient at `1e-3`.
