# Julia optimizer-control bridge

## 1. Scope

Rebased the existing narrow Julia-control implementation on current drmTMB and
made its public contract explicit.

## 2. Change

The base `engine = "julia"` bridge now accepts
`drm_control(optimizer = list(g_tol = ..., algorithm = ...))` and merges these
options after each route's existing defaults.

## 3. Preserved behaviour

Default payloads retain their current route-specific settings. Cross-family and
general-covariance bridge routes keep their existing default-control gate.

## 4. Refusals

TMB-only storage, sparse, aggregation, preset and iteration-budget controls
error before JuliaCall rather than being silently ignored.

## 5. Tests

`test-julia-optimizer-controls.R`, `test-julia-gate-vs-engine.R`,
`test-julia-bridge.R`, and `test-julia-sigma-phylo-reml.R` passed locally; its
one live Julia fit was intentionally skipped on the CRAN lane.

## 6. Documentation

The Julia vignette and `drm_control()` help now describe the narrow control
surface. Capability and gate TSV artifacts were regenerated from their source
registries.

## 7. Evidence limit

These are R-side translation and route-option tests. They do not establish
optimizer equivalence with TMB, performance gains, profile/bootstrap
calibration, or a production-tree result.

## 8. Review finding

The historical control branch was 1,809 commits behind main. Its only rebase
conflict was resolved by keeping current route defaults and merging explicit
user overrides last.

## 9. Risk

The supported solver list must remain synchronized with DRM.jl's public bridge
algorithms. Unsupported controls remain deliberately narrow.

## 10. Next step

Push this branch and let CI test the rebased R bridge; a live Julia smoke can
then verify transfer for the admitted base route.

## 11. Ownership

`R/julia-bridge.R`, the focused tests, generated Julia registries, and the
Julia vignette were owned by this isolated branch.
