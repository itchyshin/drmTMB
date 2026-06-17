# After-task — Wave 2: ML robustness

Date: 2026-06-16
Branch: `codex/honesty-guards`

## Why this wave

The four-lane capability audit (and Hao Qin's C++ review) found the ML estimator
robust for interior fits but fragile at the edges: the `log(sigma)` overflow
clamp existed only for the Gaussian likelihood, leaving every other family's
dispersion `exp(log_sigma)` unprotected; a non-finite objective could be returned
silently; and a strong scale-heterogeneity model was handed a flat
intercept-only `sigma`-slope start. Wave 2 closes these.

## Slices (each its own commit)

- **2a — clamp all scale families** (`e96cbe53`). The `use_logsigma_clamp`-gated
  `drm_softclamp_log_sigma` now wraps `log_sigma` before exponentiation in the
  Student, skew-normal, lognormal, gamma, Tweedie, beta, zero-one-beta,
  beta-binomial, and negative-binomial (NB2 / truncated / hurdle / zero-inflated)
  branches, plus the Gaussian row-aggregation path. Identity in band, so every
  in-band fit is bit-identical to the unclamped fit. `test-clamp-extension.R`
  verifies per family: in-band identity (default band == no clamp) and that a
  biting band changes the fit (the clamp is actually wired in). The `*_mi`
  imputation sub-models and the `model_type == 96` covariance prelude are left
  unwrapped (documented in doc 170).
- **2b — extend the clamp-active detector** (`cb8d2430`). Broadened the Guard-4
  detector to all clamp-guarded families (`drm_clamped_scale_families()`, kept in
  sync with the C++ sites) and switched to exact main-scale REPORT names
  (`log_sigma`/`log_sigma1`/`log_sigma2`) so the unclamped `log_sigma_*_mi`
  imputation scales can never trip it.
- **2c — non-finite-objective guard** (`2a3cb493`).
  `drm_warn_if_nonfinite_objective()` warns at fit time if `opt$objective` is
  `NaN`/`Inf` (class `drmTMB_nonfinite_objective_warning`), filtered by the
  simulation harness. Defensive guard for the audit's F7 gap.
- **2d — robust sigma-slope start** (`9dcaf609`). `gaussian_sigma_fixed_start`
  shrinks an over-large scale-slope start toward zero (bounded, direction
  preserved) instead of discarding all slopes (audit F5). Start-only change, so
  converged fits are unchanged.

## Verification

Per slice: targeted TDD test + family-test sweep. 2a: all 20 family test files
FAIL=0; bit-identity proves no in-band distortion. 2b: family tests FAIL=0 with
no spurious clamp-active warnings; `_mi` exclusion unit-tested; non-Gaussian
(gamma) upper-clamp warning integration-tested. 2c/2d: pure-helper + behavioural
tests; gaussian/biv location-scale suites FAIL=0.

Wave-level suite (full set minus the four phase18 Rmd-render tests, which
exercise report generation, not the estimator, and run in the end-to-end gate):
FAIL=0, ERROR=0, PASS=11132 across 183 test files.

## Honesty / scope

- The clamp is a numerical guard, not an identifiability fix: in band it is the
  identity, so it never changes a well-posed fit; out of band it converts an
  overflow into a finite, clamp-flagged fit (the clamp-active warning makes that
  visible). The band is configurable (`drm_control(logsigma_clamp = )`).
- Not covered (documented, not silent): the missing-predictor imputation
  sub-models (`*_mi`) and the `model_type == 96` covariance prelude scale.

## Feeds later waves

The clamp-active + non-finite-objective signals are inputs to Wave 3 (optimizer
escalation): the retry ladder should escalate when these fire, not only on a
thrown error.
