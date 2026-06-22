# After-Task: Ayumi Julia Bridge Readiness A041-A050

## Goal

Bank the Julia bridge wave for the Ayumi phylogenetic balance arc while keeping
native R/TMB, direct DRM.jl, and R-via-Julia evidence separate.

## Changes

- Added `docs/design/200-ayumi-julia-bridge-balance-readiness.md`.
- Added three Ayumi bridge-balance rows to
  `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`:
  mean-only phylo REML, sigma-side phylo REML, and matched `mu` plus `sigma`
  phylo REML.
- Clarified the R bridge comments in `R/julia-bridge.R`: Gaussian REML is
  forwarded for fixed-effect Gaussian location-scale models and for Gaussian
  cells with a `phylo()` term on `sigma`, with or without a matching mean-side
  `phylo()` term.
- Added a pure R support-matrix assertion for the Gaussian sigma-only
  phylo-REML bridge predicate in `tests/testthat/test-julia-sigma-phylo-reml.R`.
- Marked A041-A050 banked in the Ayumi 100-slice ledger.

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-sigma-phylo-reml", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-gate-vs-engine", reporter = "summary")'
DRM_JL_PHYLO_PATH='/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot' /usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-sigma-phylo-reml", reporter = "summary")'
/Users/z3437171/.juliaup/bin/julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot -e 'using DRM; st = DRM._loconly_reml_simulation_status(); println(st)'
air format R/julia-bridge.R tests/testthat/test-julia-sigma-phylo-reml.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-inference", reporter = "summary")'
```

Result: pure R sigma-phylo REML gate tests passed; Julia gate-vs-engine tests
passed; the live matched sigma-phylo REML bridge smoke passed when
`DRM_JL_PHYLO_PATH` pointed to the active DRM.jl worktree. With no
`DRM_JL_PHYLO_PATH`, the same live smoke skipped cleanly as unavailable. The
direct DRM.jl location-only diagnostic helper reported four diagnostic rows,
`coverage_status = :not_evaluated`, and `ai_reml_ready = false`.

## Boundary

A041-A050 do not promote the R-to-Julia bridge. Mean-only phylo REML remains a
native R/TMB exact-Gaussian row and not an R-via-Julia REML row. Sigma-side and
matched sigma-phylo REML bridge cells remain experimental because native TMB
REML rejects scale-side phylo and the row-specific direct/native/bridge parity
contract is not complete. No public `engine_control` surface, q4 native REML
claim, interval coverage claim, non-Gaussian REML claim, or Ayumi reply was
added.

## Next

Proceed to the bivariate q4 wave A051-A060. Keep q4 ML diagnostic point/status
evidence separate from q4 native REML and from experimental Julia bridge REML.
