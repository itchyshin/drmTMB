# After Task: Q4 Calibrated Parity Probe

## Goal

Turn the q4 same-fixture blocker into a sharper route-specific result: find a
native-converged fixture, compare native R/TMB, direct DRM.jl, and R-via-Julia
point outputs, and move only calibrated point parity when the predeclared
tolerances pass.

## Implemented

- Fixed the DRM.jl q4 `phylocov` coefficient-name order so the names match the
  engine's column-major lower-triangle log-Cholesky packing.
- Added a Julia regression assertion for the q4 log-Cholesky label order.
- Added `structured-re-q4-calibrated-parity-probe.tsv` with two converged
  32-tip candidate fixtures.
- Added R fixture and dashboard contract tests for the calibrated probe.
- Added a private DRM.jl bridge passthrough for q4 diagnostic optimizer keys and
  tuned DRM.jl's q4 default tolerance from `1e-3` to `1e-4`; no R optimizer
  control surface was exposed.

## Mathematical Contract

The q4 among-axis covariance is `Sigma_a` over axes
`mu1, mu2, sigma1, sigma2`. DRM.jl packs its log-Cholesky vector in column-major
lower-triangle order:

`L11, L21, L31, L41, L22, L32, L42, L33, L43, L44`.

The R bridge reconstructs `Sigma_a = L L'` from those named entries and derives
the six q4 `corpairs()` correlations from `Sigma_a / outer(sd, sd)`.

## Evidence

Focused checks run:

```sh
julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_bridge_q4_direct_export.jl
DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-phylo-q4-corpairs')"
```

Result: the focused Julia q4 test passed 36/36 assertions, and the live R
q4 corpairs bridge test passed 28/28 assertions.

Calibration search found two native-converged q4 fixtures:

- `q4_balanced32_seed20260802_n4`: native, direct DRM.jl, and R-via-Julia all
  converged; after the DRM.jl q4 default tolerance change, native-vs-wrapper
  logLik delta was `3.40338728506e-05`, max fixed-effect delta was
  `0.002035353033554`, max SD delta was `0.000891728220382`, and max derived
  correlation delta was `0.00683683079288`.
- `q4_balanced32_seed31_n8`: all three routes converged; direct-vs-wrapper
  matched to floating precision; native-vs-wrapper logLik delta was
  `7.54770563276e-05`, max fixed-effect delta was `0.000701704920776`, max SD
  delta was `0.000599065985335`, and max derived correlation delta was
  `0.00197031823787`.

Diagnostic tuning separated tolerance from iteration budget. Increasing
`q4_iterations` alone did not move the log likelihood, while setting
`q4_g_tol = 1e-4` closed the native-vs-Julia gap on both calibrated fixtures.

## Tests Of The Tests

Before the label-order fix, direct DRM.jl's raw `q4_point_export$correlation`
and the R wrapper's `corpairs()` differed by up to about `1.96`, despite equal
direct and wrapped log likelihoods. After the fix, direct-vs-wrapper q4
correlations matched to floating precision.

## Consistency Audit

The new row keeps three outcomes separate:

- direct DRM.jl point matrix to R wrapper reconstruction: covered;
- native-vs-Julia same-fixture point parity: covered on the calibrated fixtures;
- interval reliability, interval coverage, q4 REML, and AI-REML: not promoted.

## GitHub Issue Maintenance

No GitHub issue, PR, or Ayumi reply was created. This is local mission-control
evidence only.

## What Did Not Go Smoothly

The first calibration script failed because `phylo(..., tree = sim$tree)` is
invalid formula grammar; `tree` must be a named object in the formula
environment. The next grid also reminded us that `ape::stree(type =
"balanced")` requires a power-of-two tip count. Both constraints are now part
of the fixture notes.

## Team Learning

Rose/Emmy: raw direct-payload rows are valuable because they can reveal wrapper
reconstruction bugs even when model fits are otherwise converged.

## Known Limitations

Q4 calibrated point parity is now covered only for the logged fixtures and
targets. This does not establish broad q4 bridge support, q4 REML support in
drmTMB, HSquared AI-REML, interval reliability, interval coverage, release
readiness, a commit, a PR, or an Ayumi-facing reply.

## Next Actions

Keep q4 interval reliability and coverage blocked until calibrated
finite-interval evidence with failed-fit denominators and MCSE exists.
