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

## Bridge-cell movement: Rose + Fisher verdict -- 0 promotions

An adversarial Rose + Fisher pass (both independently) held EVERY bridge cell.
The parity evidence is real, but the existing statuses are already correctly
conservative -- any promotion would cross a claim boundary:

- `base_gaussian_location_scale` (Route C): parity proven (point + logLik + coef
  `<= 1e-6`), but the cell is already `partial`; the only step up is `covered`,
  which the matrix vocabulary defines as requiring interval/CI evidence. The
  bridge has point+logLik parity only (no profile/bootstrap bridge interval
  parity), so `covered` is not earned. Hold at `partial`.
- Bivariate residual `rho12` bridge cell: Route B's parity fits `rho12 ~ 1`
  (intercept-only) and asserts only a scalar logLik invariant -- coefficient
  parity is deliberately NOT asserted because the two engines order the
  correlation block differently -- whereas the row claims the predictor-dependent
  `rho12 ~ x` lead novelty. Promoting would overclaim on both formula scope and
  asserted-quantity scope. Hold at `planned`.
- `R-Julia bridge gate` aggregate row: spans Route A (tracked garbage-logLik
  bug), q4/q8, structured covariance, and cross-family routes; two narrow green
  routes cannot promote the aggregate. Hold.
- All other capability/gate cells: no same-route parity. Hold.

### Exact path to actually promote (for the maintainer)

- Route C `base_gaussian_location_scale` -> `covered`: add a bridge **interval**
  parity test (native vs `engine="julia"` profile and/or bootstrap CI endpoints
  to a stated tolerance) for the Gaussian location-scale cell.
- Route B / `rho12`: add a predictor-dependent `rho12 ~ x` bridge parity test
  that asserts **coefficient** parity (not just the logLik invariant), and add a
  dedicated non-phylo bivariate-`rho12` bridge capability row -- none exists
  today, so Route B currently has no exact cell to land on.

Net: the bridge is healthy and the supported-route (B/C) parity is banked, but
no cell promotion is warranted today without crossing a claim boundary. This is
the rigorous outcome, not a shortfall -- the conservative statuses are correct.

## Update (2026-06-20, later): Route C interval parity earns a scoped promotion

The promote-path above ("add a bridge interval parity test ... CI endpoints to a
stated tolerance ... for the Gaussian location-scale cell") is now satisfied.
`tests/testthat/test-julia-tmb-parity.R` gained a committed, callr-isolated
**"Route C interval parity"** test: for `bf(y ~ x, sigma ~ x)`, `engine="julia"`
and `engine="tmb"` agree on the **Wald CI endpoints** of all four location-scale
fixed-effect coefficients to an asserted `<= 1e-4` (measured max |delta endpoint|
~5.6e-6; full suite 12 PASS / 0 FAIL / 1 SKIP, the skip being Route A). Native
Wald variances come from the TMB `sdreport` covariance (`sdr$cov.fixed`); Julia
Wald variances come from the DRM.jl-marshalled `object$vcov`. The two covariance
sources are independent, so endpoint agreement verifies **covariance transport**
across the bridge -- the step beyond the earlier point + logLik + coefficient
parity.

A fresh Rose + Fisher adversarial pass (both traced the two covariance code paths
in source) verified **promote**, scoped:

- `base_gaussian_location_scale` (`julia-capabilities.tsv`): `partial -> covered`,
  scoped to **Wald CI parity** (engine-vs-engine agreement, **not** interval
  coverage/calibration). The **asserted** `<= 1e-4` bound is the guarantee;
  `5.6e-6` is the measured value.
- **Still held** (unchanged): profile/bootstrap **fixed-effect** bridge intervals
  (the Julia bridge profile/bootstrap path supports only phylogenetic SD targets),
  Route A (tracked bug), q4/q8, non-phylo binomial bridge, `engine_control`, and
  the **aggregate `R-Julia bridge gate` row** (still spans the Route A bug and the
  gated routes).
- Route B / `rho12 ~ x` still needs a coefficient-parity test plus a dedicated
  non-phylo bivariate-`rho12` bridge capability row (none exists yet).

Net: one scoped, defended bridge-cell promotion; the rest of the conservative
statuses remain correct.
