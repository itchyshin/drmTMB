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
now passes for both the sigma-only and matched Gaussian sigma-phylo REML bridge
cells. With no `DRM_JL_PHYLO_PATH`, the same test skips cleanly rather than
failing.

The separate ML parity fixture in `tests/testthat/test-julia-tmb-parity.R`
now splits those two cells. The q1 sigma-only phylo ML row and the matched q1
`mu` plus `sigma` phylo ML row both match native R/TMB, direct DRM.jl, and
R-via-Julia on one repeated-species fixture. The matched row uses the coupled
DRM.jl bridge target and banks log-likelihood, fixed-effect, structured-SD,
and phylogenetic-correlation parity only; REML and intervals remain separate.

Outside the Ayumi phylo rows, the same test file now also banks q1 Gaussian
`spatial()`, `relmat()`, and `animal()` mean-side ML parity fixtures. The
spatial row converts coords to native drmTMB's fixed-range K target before
calling DRM.jl; the relmat and animal rows use supplied K and A matrices. Those
rows are structured-bridge evidence only; they do not promote mesh/SPDE,
precision-matrix (`Q`), pedigree, or `Ainv` bridge marshalling, REML,
intervals, sigma-side structured effects, q2/q4, or non-Gaussian support.

The count-phylo bridge test in `tests/testthat/test-julia-phylo-count.R` now
banks one q1 Poisson `phylo()` mean-side ML/Laplace parity fixture against
native dense TMB. It is deliberately recorded as non-Gaussian bridge evidence,
not REML, not NB2 parity, and not interval support.

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

`docs/dev-log/dashboard/bridge-parity-smoke-status.tsv` now keeps six
phylogenetic bridge balance rows separate:

- `ayumi_bridge_gaussian_phylo_mean_reml`: native R/TMB mean-side REML is
  covered, but R-via-Julia warns and fits ML; no bridge REML support.
- `q1_gaussian_sigma_phylo_ml`: sigma-only q1 Gaussian phylo ML parity is
  banked for one repeated-species fixture across native R/TMB, direct DRM.jl,
  and R-via-Julia.
- `q1_gaussian_mu_sigma_phylo_ml`: matched q1 Gaussian `mu` plus `sigma`
  phylo ML parity is banked for one repeated-species fixture across native
  R/TMB, direct DRM.jl, and R-via-Julia.
- `q1_poisson_mu_phylo_ml`: q1 Poisson `phylo()` mean-side ML/Laplace bridge
  parity is banked for one approximate native dense-TMB and R-via-Julia
  fixture, with no REML or interval wording.
- `ayumi_bridge_gaussian_sigma_phylo_reml`: sigma-side Gaussian phylo REML has
  live bridge admission evidence, but native TMB REML rejects scale-side phylo,
  so this remains experimental bridge evidence.
- `ayumi_bridge_gaussian_mu_sigma_phylo_reml`: the matched `mu` plus `sigma`
  live bridge smoke passed with the active DRM.jl worktree, but it remains
  bridge-only REML admission evidence rather than native REML parity.

The same bridge-smoke ledger also carries `q1_gaussian_mu_spatial_ml`,
`q1_gaussian_mu_relmat_ml`, and `q1_gaussian_mu_animal_ml` as non-phylogenetic
structured rows. They are listed there so the q1 bridge-parity wave can compare
all structured routes with the same native/direct/bridge evidence ladder, not
because the Ayumi phylogenetic answer has changed.

The q2 payload-boundary contract is now banked as mission-control evidence. It
records q2 `mu1`/`mu2` payload shape and coefficient ordering, but the current
R-via-Julia q2 route remains an intentional pre-JuliaCall error until a
q2-specific bridge route exists.

## Decision

The bridge wave is experimental and useful, not promoted. The honest Ayumi
answer after this wave is that native ML is balanced for univariate Gaussian
`phylo()` layouts, q1 sigma-only and matched q1 `mu` plus `sigma` phylo ML each
have one row-specific bridge parity fixture, native REML is mean-side-only, and
the Julia bridge can run selected sigma-phylo REML cells locally when a
compatible DRM.jl engine is configured. The adjacent q1 Poisson `phylo()` row
is ML/Laplace bridge evidence only, and the q2 payload-boundary row is not q2
bridge support. This does not solve bridge promotion, public optimizer controls,
interval coverage, q4 native REML, non-Gaussian REML, NB2 parity, or the
10,440-tip sigma-phylo interval blocker.
