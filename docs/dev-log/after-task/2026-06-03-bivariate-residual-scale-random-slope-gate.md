# After Task: Bivariate Residual-Scale Random-Slope Pre-Code Gate

## Goal

Write the pre-code design gate for **bivariate residual-scale random slopes**
— the "q2 scale slope" stage in `docs/design/67-sdstar-p8-poisson-q1.md` and the
first prerequisite the `bivariate_gaussian_q8_endpoint` registry row names before
any q8 endpoint likelihood or status promotion. The gate should make the
eventual implementation slice small and reviewable without adding any fitted
support.

## Why a Design Gate (Not Code)

The honest next step toward the q8 individual-difference covariance endpoint is
the bivariate residual-scale random-slope likelihood. That is new TMB algebra,
and this environment cannot compile or test TMB (the network policy blocks the R
package repositories, so no dependencies are installed). Writing the likelihood
blind, with correctness resting only on slow CI iteration, is the wrong way to
land numerically delicate scale-slope code. A pre-code gate is the same pattern
the q8 endpoint used: record the contract first, implement against it later.

## Implemented

Added `docs/design/155-bivariate-residual-scale-random-slope-gate.md`. It
records:

- the current boundary, with the two implemented building blocks to reuse
  (univariate independent residual-scale slopes; bivariate residual-scale random
  intercepts) and the exact rejection site (`R/drmTMB.R:4963-4969`) and boundary
  tests (`tests/testthat/test-biv-gaussian.R:2837-2864`);
- the target q2 scale-slope model, keeping the group-level
  `cor(sigma1:x, sigma2:x | p | id)` separate from residual `rho12`;
- the future R syntax;
- a parameterization plan that extends the existing bivariate covariance
  assembler from intercept members to slope members rather than forking a new
  path, with the exact `sdpars$sigma` / `corpars$sigma` / `corpairs()` /
  `profile_targets()` / `check_drm()` label contract;
- the identifiability risk specific to scale slopes and how diagnostics should
  surface weak identification;
- an ADEMP simulation/test plan;
- admission rules (one endpoint class at a time; derived correlation stays
  interval-unavailable) and the fitted fallbacks users should try today.

The "q2 scale slope" row in `docs/design/67-sdstar-p8-poisson-q1.md` now points
at the gate, and `docs/dev-log/check-log.md` records the slice.

## Mathematical Contract

The latent group vector is the pair of log-`sigma` slopes:

```text
u_j = [a_sigma1_x_j, a_sigma2_x_j]' ~ MVN(0, D),
D = diag(s) R diag(s),  s = (sd_sigma1_x, sd_sigma2_x),
R = [[1, rho_s], [rho_s, 1]]
```

with `log(sigma_k_ij) = X_sigma_k beta_sigma_k + x_ij a_k_j` and residual
`rho12` kept as a separate row-level term. This is the slope-only analogue of
the implemented q2 scale-intercept block, so the q=2 TMB parameter layout
(`log_sd_sigma`, `eta_cor_sigma`) is unchanged in shape; only the per-member
design columns change from a constant to `x_ij`.

## Files Changed

- `docs/design/155-bivariate-residual-scale-random-slope-gate.md` (new)
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-03-bivariate-residual-scale-random-slope-gate.md` (this file)

## Checks Run

Design-only slice: no R code, tests, roxygen, or registry admission status
changed, so `devtools::test()`, `devtools::check()`, `pkgdown::*`, and
`devtools::document()` were not run. Local R is unavailable in this container
(the package repositories are blocked by the network policy). The gate adds no
fitted support and promotes no `q8`/`p8` or scale-slope status; the cited
rejection site and boundary tests are unchanged, so package behaviour is
identical.

## Known Limitations

This is a design gate only. Bivariate residual-scale random slopes remain
unfitted and explicitly rejected. The gate does not establish recovery,
coverage, power, intervals, or any q8/p8 endpoint support, and it deliberately
does not open the same-response location-scale slope block or random effects in
`rho12`.

## Next Actions

When local TMB build/test (or a deliberate CI-driven implementation) is
available, implement the single q2 scale-slope slice against this contract:
convert the matching `sigma1`/`sigma2` slope block from error to fit by feeding
slope design columns into the existing bivariate covariance assembler, add the
malformed-input and recovery tests, then add a Phase 18 recovery lane and the
registry row. Keep the same-response location-scale slope and q8 endpoint blocks
closed until this slice has recovery evidence.
