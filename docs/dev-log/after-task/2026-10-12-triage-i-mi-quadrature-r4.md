# 2026-10-12: Round 4 family-correct Newton and live abort (#1513)

Reader: Shinichi and the Code Reviewer who blocked Gaussian-only
Newton, the unused `drm_rethrow` helper, and the y=7 Gamma tests.

## Task goal

Round 4 on draft PR #1513. Recertify C17 after the pin-file edits.
Make `drmTMB_mi_quadrature_nonfinite` fire on a live `drmTMB()` fit.
Give Newton each family's own log-density gradient and Hessian so
Poisson times Gamma is correct. Move Gamma tests off y=7. Record the
CV `> 1` pole follow-up and the U-shaped Beta 0.54 case for #1531.
Refs only, never Fixes. Keep the PR draft.

## What changed

`drm_gamma_mi_newton_grad_hess()` now takes `model_type`. Gaussian
and Poisson use analytic `d log f / d eta` and the chain rule through
`eta = mu_base + beta_x * (x - x_base)`. Other leaves use a centred
finite difference of `drm_response_log_density`. Fifteen Newton steps
start at `log(mu)`; the Gaussian path blends toward the implied `x`
when that value is positive. A Hessian that is not strictly concave
skips the step and, after the loop, snaps to the prior mode with
prior curvature `-shape`. The R helper mirrors that. Gamma production
uses 51 probabilists' GH nodes. The R helper aborts only when the
log-sum is non-finite, so a few `-Inf` tail leaves do not kill a
finite Poisson `y = 0` row.

`drm_fit_spec()` wraps `MakeADFun` with `drm_rethrow_mi_quadrature_error`
for Gamma, Beta, and zero-one-Beta `mi()` only. After the tape is
built it probes `fn` and `gr` at the start and again at the fitted
parameter. A non-finite value raises `drmTMB_mi_quadrature_nonfinite`.
`obj$fn` / `obj$gr` are not replaced, so recoverable NaNs during
`nlminb` stay ordinary.

`src/drm_numeric.h` and `src/drm_response_kernels.h` were not edited.
The unweighted Gaussian priors at `src/drmTMB.cpp:1301`, `:1342`, and
`:4556` were not edited. `n_cpp` is 40L.

## Acceptance numbers

Before (reviewer receipt on `e30f255cb`, R helper, y away from 7):

- Poisson times Gamma, CV 1: `5.4e-4`
- Poisson times Gamma, CV 2, `y = 0`: classed abort
- Gamma pole `y = 2.05`, CV 2: `1.61` / `1.99`
- U-shaped Beta shapes `(0.13, 0.31)`, `y` near 0: `0.54`

After (51-node family-correct Newton, fine-split `integrate()`):

- Gamma pole `y = 2.05`: CV 0.05 `5.7e-14`; 0.5 `1.3e-8`; 1 `2.7e-5`
- Gamma tail `y = 12`: CV 0.05 `4.1e-12`; 0.5 `2.0e-14`; 1 `2.8e-14`
- Poisson times Gamma, CV 1: `5.17e-5`
- Poisson times Gamma, CV 2, `y = 0`: finite log-sum (`8.4e-2` vs
  `integrate()`, no abort)
- Gamma pole CV 2: `9.51e-2` (labelled skip; issue draft in
  `docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`)
- U-shaped Beta shapes `(0.13, 0.31)` with `y` near 0: about `0.54`
  (local scan `y = 0.10`, `sd_y = 0.05`, `beta_x = 0.5` is `0.57`).
  Recorded for #1531, which currently cites `1.6e-2`.

A live `drmTMB()` Gamma `mi()` fit with one missing-x row at
`y = 1e200` raises `drmTMB_mi_quadrature_nonfinite`.

## Checks run

Focused `testthat::test_file()` after `pkgbuild::compile_dll()`
(R 4.3.3, TMB 1.9.25): `test-mi-quadrature-1476-1477.R` (one
expected CV `> 1` pole skip), `test-guard-branch-continuity.R`
(`n_cpp = 40L`), `test-missing-predictor-{gamma,beta,zero-one-beta}.R`,
and `test-mi-weights-1459.R` reported 0 failures.

C17 and the full suite are recorded in `docs/dev-log/check-log.md`
after those steps finish.

## GitHub issues

#1476, #1477, and #1531 stay open. This PR uses Refs, not Fixes.
The CV `> 1` pole follow-up title and body are in
`docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`
for Shinichi to file. The 0.54 U-shaped number is for #1531.

## Known limitations

U-shaped Beta on the 15-node rule still mis-integrates the 0-pole
worst case at about `0.54` log units. Do not start adaptive Beta in
this PR. Gamma CV `> 1` near the pole is the separate follow-up
above.

## Next

Recertify C17, run the full suite, push, and leave #1513 draft.
