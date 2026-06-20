# R-Julia bridge parity verification (Ada, 2026-06-20)

Verifies the R-to-Julia bridge (`engine = "julia"`, drmTMB -> JuliaCall ->
DRM.jl) on the current state, and records the parity evidence that gates any
bridge-cell promotion. Branch `shannon/overnight-audit-gaps-20260619`; the DRM.jl
engine is the clean direct-main worktree (`DRM.jl-direct-main`, `f46035d`).
Pushes held.

## How the bridge is exercised

The parity tests isolate each `engine = "julia"` fit in a fresh `callr`
subprocess with `pkgload` + JuliaCall pointed at the DRM.jl checkout via
`DRM_JL_PHYLO_PATH` and `JULIA_HOME` (see `tests/testthat/helper-julia-bridge-path.R`).
An in-process `engine = "julia"` call after `load_all()` fails on a JuliaCall
loading conflict; the callr isolation is what makes the bridge reliable, so any
bridge artifact must use it.

## Evidence (verified this session)

Invocation:
`DRM_JL_PHYLO_PATH=.../DRM.jl-direct-main JULIA_HOME=.../.juliaup/bin Rscript -e 'devtools::test(filter = "julia-gate-vs-engine|julia-tmb-parity")'`

- **Gate registry (`julia-gate-vs-engine`)**: all 113 checks pass -- the
  intentional R-side rejections (unsupported `engine = "julia"` cells) fire
  exactly as registered.
- **Route C - Gaussian location-scale** (`bf(y ~ x, sigma ~ x)`): `engine="julia"`
  == `engine="tmb"` for coefficients and logLik to **<= 1e-6**. PASS.
- **Route B - bivariate Gaussian residual `rho12`** (validates the lead-novelty
  bridge path): `engine="julia"` == `engine="tmb"` to **<= 1e-6**. PASS.
- **Route A - Gaussian phylo-mean** (`sigma ~ 1`): SKIPPED, tracked bug --
  `engine="julia"` returns a garbage logLik and false-converged on some data
  (repro `/tmp/routeA_diag.R`). Not parity-eligible until fixed.
- **Direct DRM.jl lane**: full `test/runtests.jl` green (228 testsets, 0
  failures) + Aqua 10/10 on `f46035d` (separate after-task note).

So for Routes B and C the three lanes agree: native R/TMB == R-to-Julia bridge
(<= 1e-6) and the direct DRM.jl engine is independently green. That is the
3-lane parity the bridge-promotion gate requires for those exact cells.

## Boundary

This is parity evidence for **Route C (Gaussian location-scale)** and **Route B
(bivariate residual `rho12`)** only, both using the default DRM.jl fitting path
with no Julia-side `engine_control` surface. It does NOT establish: Route A
(Gaussian phylo-mean, tracked bug), q4/q8 bridge parity, plain non-phylo
binomial bridge, profile/bootstrap bridge intervals, or any selectable Julia
optimizer control. Those stay `experimental`/`planned`/`unsupported`.

## Recommended bridge-cell movement (owner/Rose to confirm)

The parity gate is met for the two cells above. Promoting the crown-jewel bridge
claims is the most boundary-sensitive change in the project, so the specific
cell edits are taken through an adversarial Rose+Fisher pass and applied only
where unanimous, with pushes held for owner review.
