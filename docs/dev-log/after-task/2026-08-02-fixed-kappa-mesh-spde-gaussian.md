# After Task: Fixed-kappa mesh/SPDE Gaussian spatial capability

## Goal

Add a projection-aware mesh/SPDE spatial route without changing the existing
dense `coords =` model, and keep every claim at its earned evidence tier.

## Implemented

`spatial_coords()` converts longitude/latitude to an explicitly requested
projected CRS. `make_mesh()` constructs a validated `drmTMBmesh` with sparse
FEM matrices and observation projection `A_st`. The admitted model is exactly
univariate Gaussian ML `bf(y ~ spatial(1 | site, mesh = mesh), sigma ~ 1)`.
Its TMB contribution is `A_st %*% omega`; it never uses a mesh-node index.

## Mathematical Contract

With fixed positive `kappa`, the raw precision is
`Q = kappa^4 C0 + 2 kappa^2 C1 + C2` and
`omega ~ N(0, s^2 Q^-1)`. `s` is reported as a raw GMRF field scale; the
projected marginal SD is location dependent. `kappa` is fixed configuration,
not an estimated range. The independent dense Gaussian marginal likelihood
uses `V = sigma_e^2 I + s^2 A Q^-1 A^T`.

## Files Changed

The implementation adds `R/mesh.R`, mesh parser/fit/TMB plumbing, tests,
provenance, recovery receipts, and spatial documentation. Public reader paths
include the spatial, formula-grammar, structural-dependence,
phylogenetic-spatial, and model-map vignettes; pkgdown indexes both helpers.

## Checks Run

- `devtools::test(filter = "mesh")`: 50 expectations, zero failures.
- Dense marginal-objective comparator, row alignment, CRS, malformed mesh,
  non-Gaussian, labelled, mesh-plus-coordinates, REML, and missing-data
  boundaries are exercised by the mesh contracts.
- `pkgdown::build_article("spatial-models")` against a temporary install of
  the current source: passed; the rendered page shows 27 vertices, 4
  observations, zero projection-row error, projected values, and profile status.
- `pkgdown::check_pkgdown()`: passed after adding both new helpers to the
  reference index.
- Capability ledger and its 49 Python tests: passed after the final-source
  Totoro receipt was installed.
- Hosted R-CMD-check for source head `f7054884a`: in progress at report
  creation; its terminal result is deliberately not inferred here.

## Tests Of The Tests

The dense marginal likelihood is calculated outside the TMB random-effect
objective. Boundary tests directly reject routes that would widen the slice,
and the recovery receipt retains the clean-Hessian `n = 64` near-zero estimate
that makes the predeclared RMSE gate fail.

## Consistency Audit

`docs/dev-log/2026-08-02-mesh-spde-handover-reconciliation.md` records every
handover item as DONE, RETRACTED, PROTECTED, or OWED. Current reader surfaces
distinguish the exact mesh exception from wider mesh/SPDE work. The old dense
`coords =` route is separately documented and regression-protected. The article
is executable and uses `$projected` rather than calling mesh vertices sites.

## GitHub Issue Maintenance

Issue #881 remains open. A comment records that the complete Totoro ladder
withheld point-fit recovery; PR #893 remains draft until its final CI gate is
green.

## What Did Not Go Smoothly

The initial C17-C1 compatibility receipt predates a later `R/drmTMB.R`
missing-data rejection. The capability-ledger guard correctly failed CI. A
fresh final-source Totoro control retained all 12 attempts and passed, then the
manifest was refreshed. Final reviews also found stale public “mesh planned”
wording and one incorrectly labelled article invariant; both were repaired.

## Team Learning

For a new structured route, update every status inventory and execute its
public example before treating a focused implementation as ready. A source-wide
receipt guard is useful only when it is rerun after every relevant source edit.

## Known Limitations

The route is ML-only, fixed-kappa, univariate Gaussian `mu`, intercept-only,
and local-fit only. The recovery gate is **blocked** at `n = 64`; there are no
range, uniform marginal-SD, interval, coverage, slope, non-Gaussian, bivariate,
anisotropy, barrier, replicated, or spatiotemporal claims.

## Next Actions

Record the terminal hosted R-CMD-check result. Keep #881 open and retain the
local-fit boundary unless a separately approved recovery/design arc changes it.
