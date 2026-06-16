# After-task — Guard 4: log(sigma) clamp-active detector (Hao Qin review)

Date: 2026-06-16
Branch: `codex/honesty-guards`

## Origin

Hao Qin reviewed the TMB C++ and flagged that hard-coded truncations can cause
"artificial convergence and possibly lead to incorrect inference results." A
two-lane audit (math-consistency + inference) confirmed his read and ranked the
risks. Most of the ~21 truncations are inferentially harmless (smooth
reparameterizations onto natural ranges; numerical floors that bite only at
degeneracy). One is a genuine model restriction (`nu = 2 + exp(eta)` excludes
heavy tails `nu <= 2`; already surfaced by `check_student_nu`). The single REAL,
UNDETECTED gap was the **`log(sigma)` soft-clamp binding under a false
convergence**: when the clamp saturates but `nlminb` returns code 0, the gradient
is flat (so the gradient check passes) and nothing reported that the clamp was
active. This guard closes that gap.

## Mechanism the guard addresses

`drm_softclamp_log_sigma` is identity in `[lo, hi]` (default `[-12, 12]`) and
saturates to `[lo - margin, hi + margin]`. If the data drive the scale past the
band, the optimizer runs `log_sigma` into the saturated tail, where the objective
is flat: the gradient vanishes, `nlminb` can report convergence, and the Hessian
near the bound reflects the clamp rather than the data. Estimates and SEs there
are unreliable. For any normally scaled response the clamp is a no-op (identity
in band), so the warning does not fire on healthy fits.

## What changed

- `drm_logsigma_clamp_active(report, tmb_data)` (R/drmTMB.R): returns NULL when
  the clamp is disabled or the scale is inside the band, else the extreme
  `|log_sigma|` and the band. Scans every reported `log_sigma*` field, so
  univariate and bivariate scales are covered.
- `drm_warn_if_clamp_active(obj, tmb_data)`: warns at fit time (class
  `drmTMB_clamp_active_warning`) with the value reached, the band, and concrete
  remedies (rescale / widen band / replicate / penalized fit / `check_drm`).
  Wired into the fit path after the optimum is pinned.
- `inst/sim/R/sim_runner.R`: the harness warning filter now also drops
  `drmTMB_clamp_active_warning` (it tracks scale state separately), mirroring the
  convergence-warning filter, so simulation lanes do not double-count it.

## TDD and verification

- `tests/testthat/test-clamp-active-guard.R`: pure-helper unit tests (synthetic
  reports: disabled / healthy / saturated / bivariate / non-finite) plus a fit
  with a narrow band `c(-0.05, 0.05)` that forces the clamp active
  deterministically (no platform-dependent overshoot), and a clean-fit silence
  check. 11/11.
- An initial implementation flagged both clamp boundaries on every family
  (use_logsigma_clamp is a data default on all models). The full suite caught it:
  FAIL=0 but WARN jumped to 30 with false positives on meta-analysis (tau -> 0,
  lower boundary), phylo-gaussian, truncated/zi-nbinom2, tweedie. The fix scopes
  the detector to (a) Gaussian/biv-Gaussian models (where the clamp is actually
  applied) and (b) the upper boundary only (scale runaway; the lower boundary is
  the legitimate variance-zero case). After the fix the previously-flagged files
  are WARN=0 (meta 7->0, phylo 3->0, truncated 2->0, zi 1->0) and FAIL=0; full
  suite FAIL=0 is preserved by monotonicity (the fix only reduces firing).

## Still open from the audit (not this guard)

- The combined "convergence == 0 + parameter at a bound + bad Hessian/huge SE"
  single honest signal (deferred doc-170 measure) -- this guard delivers the
  clamp half; the fused signal across all bounds is future work.
- `check_drm()` does not flag univariate `(1 + x | p | id)` / mean-scale
  random-effect correlations at the tanh bound (the new boundary-aware `confint`
  does). 
- The residual `rho12` cap is `0.99999999` (eight 9s) while other correlations
  use `0.999999` (six 9s); harmless to interior fits, worth standardizing.
- Document the `nu > 2` (finite-variance) restriction prominently for Student-t.
