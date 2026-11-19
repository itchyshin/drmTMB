# After Task: adopted converged rule in drmTMB

## Goal

Implement Shinichi's adopted rule (SHINICHI-1753-1118) so `converged` means an
interior optimum with usable standard errors, with Heywood folded into
boundary.

## Implemented

- `not_converged` is a separate status. It covers optimiser failure, a
  non-finite log-likelihood and a Newton step above 1e-3 SE (`max_gradient` reports `max_i |(H^-1 g)_i| / SE_i`); it was part of
  `degenerate`.
- Boundary is tested before the Hessian and standard-error steps. A boundary
  fit with a flat Hessian now reads `boundary`, not `degenerate`.
- Random-effect SD cut-off is relative: identity-link location SDs are divided
  by the response SD, link-scale SDs keep scale 1 (#1751, partial: the cut-off
  only; the `logsigma_clamp` bias on a 1e-6-scale `y` is a fit-level issue and
  is not changed here).
- Heywood (collapsed residual SD in a temporal model) is boundary kind
  `heywood`; other temporal limits are kind `temporal`; also `re_sd`, `rho12`.
- New `convergence_info()` and extra `summary()` fields: `converged`,
  `boundary_params`, `pd_hessian`, `max_gradient`.
- `check_drm()` shows `boundary` and `not_converged` as warnings (boundary was
  a note). Julia-engine fits read a bridge `not_converged`/`boundary` string.

## Mathematical Contract

No likelihood, parameterisation or formula grammar changed.

## Files Changed

`R/check.R`, `R/methods.R`, `NAMESPACE`, `_pkgdown.yml`, `man/`,
`docs/design/278-twin-convergence-status.md`,
`docs/design/174-controls-and-convergence.md`, `NEWS.md`, tests in
`test-convergence-status-twin.R` and `test-temporal-boundary.R`.

## Moved test expectations (this rule only)

See the PR body for the full list.

## Checks Run

Narrow tests for every test file that mentions convergence, boundary,
degenerate or `check_drm`; results in the PR body.

## Consistency Audit

`rg "drm_inference_at_boundary"` finds no remaining use. The twin constants
are unchanged. The dispersion-at-limit boundary and a Julia unit-free SD cut
are not implemented (open questions in the PR body).

## Open Questions

1. Dispersion at its limit (NB2 to Poisson, Student nu to infinity) as a
   boundary kind: needs a threshold; still read via covariance steps (#1535).
2. (Closed 19 Nov 2026, CONV-GRADIENT-CUT) The gradient cut is the Newton step in SE units, <= 1e-3; the uncalibrated relative gradient is gone.
3. #1751 option 2 (rescale y internally) is not done.
