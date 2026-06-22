# Ayumi Julia Bridge Balance Readiness

## Purpose

This note banks the Julia bridge wave for the Ayumi phylogenetic balance arc.
It keeps three routes separate: native R/TMB, direct DRM.jl, and R-via-Julia.
The bridge can be useful local evidence, but it is not a public support claim
until row-specific parity is explicit.

## Current R-Side Gate Evidence

The pure R gate tests in `tests/testthat/test-julia-sigma-phylo-reml.R` confirm
that Gaussian REML forwarding is selective:

- fixed-effect Gaussian location-scale models forward `method = "REML"`;
- Gaussian models with a `phylo()` term on `sigma` forward
  `method = "REML"`, including sigma-only and matched `mu` plus `sigma`
  formula layouts;
- mean-only Gaussian `phylo()` models warn and fit ML over the bridge, because
  that row is not a DRM.jl REML bridge cell;
- non-Gaussian phylogenetic bridge cells warn and fit ML rather than borrowing
  REML wording.

The configured live smoke, run with
`DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`,
passed for the matched Gaussian sigma-phylo REML bridge cell. With no
`DRM_JL_PHYLO_PATH`, the same test skips cleanly rather than failing.

## Direct DRM.jl Diagnostic Evidence

The direct DRM.jl helper `_loconly_reml_simulation_status()` reports four
diagnostic rows for the exact-Gaussian location-only REML experiment:
`stable_recovery`, `condition_grid`, `weak_signal_boundary_probe`, and
`larger_interior_stress`. The helper reports
`claim_status = :simulation_diagnostic`, `coverage_status = :not_evaluated`,
and `ai_reml_ready = false`.

That direct helper is useful for internal algorithm work, but it is not a
public DRM.jl route and not an R-via-Julia bridge promotion. The mean-only
bridge row therefore remains unsupported for REML even though native R/TMB has
an exact mean-side REML estimator and DRM.jl has internal location-only
diagnostics.

## Bridge Balance Matrix

`docs/dev-log/dashboard/bridge-parity-smoke-status.tsv` now includes three
Ayumi bridge balance rows:

- `ayumi_bridge_gaussian_phylo_mean_reml`: native R/TMB mean-side REML is
  covered, but R-via-Julia warns and fits ML; no bridge REML support.
- `ayumi_bridge_gaussian_sigma_phylo_reml`: sigma-side Gaussian phylo REML is
  admitted by the R gate, but native TMB REML rejects scale-side phylo, so this
  remains experimental bridge evidence.
- `ayumi_bridge_gaussian_mu_sigma_phylo_reml`: the matched `mu` plus `sigma`
  live bridge smoke passed with the active DRM.jl worktree, but parity remains
  blocked until native R, direct DRM.jl, and R-via-Julia evidence are a single
  row-specific contract.

## Decision

The bridge wave is experimental and useful, not promoted. The honest Ayumi
answer after this wave is that native ML is balanced for univariate Gaussian
`phylo()` layouts, native REML is mean-side-only, and the Julia bridge can run
selected sigma-phylo REML cells locally when a compatible DRM.jl engine is
configured. It does not solve bridge promotion, public optimizer controls,
interval coverage, q4 native REML, or the 10,440-tip sigma-phylo interval
blocker.
