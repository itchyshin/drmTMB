# Mesh/SPDE handover reconciliation

This reconciles the 2026-08-01 planning handover, current `origin/main`, open
PR #893, and issue #881. Status names describe the exact first slice; they do
not broaden it.

| Requested item | Status | Current evidence / boundary |
| --- | --- | --- |
| Five-row symbolic R-to-TMB alignment and fixed-kappa decision | DONE | `2026-08-02-mesh-spde-symbolic-alignment.md`; raw GMRF scale, not range or uniform field SD. |
| Exact gllvmTMB #886 provenance | DONE | `inst/COPYRIGHTS` records PR #886, merge `01a3b1103e1b3fe5fdf5d27826349d5bc6f4f040`, GPL-3, and adapted paths. |
| Explicit longitude/latitude to declared projected CRS | DONE | `spatial_coords()` requires `crs_out`; raw degrees are rejected by mesh construction. |
| `drmTMBmesh` helper with FEM and `A_st` alignment | DONE | `make_mesh()` plus helper and malformed-input tests. |
| Gaussian `mu` intercept with `A_st %*% omega` | DONE | ML-only univariate route; independent dense marginal objective comparator passes. |
| Existing dense planar `coords =` route | PROTECTED | It remains a distinct dense exponential-covariance route with regression tests. |
| Point-fit recovery promotion | RETRACTED | Complete Totoro ladder failed its frozen `n=64` RMSE gate; retain local fit. |
| Range estimation, mesh slopes, non-Gaussian/bivariate fields, anisotropy, barriers, replicated and spatiotemporal fields | PROTECTED | Parser and public surface reject or omit them; each needs a separate symbolic and recovery gate. |
| Intervals and coverage | PROTECTED | `profile_targets()` declares the mesh field-scale target unready; no inference claim. |
| Full PR closeout (cross-platform CI, complete package check, after-task report) | DONE | Exact implementation head `0407ee370` passed hosted PR Linux run 30753455095 and independent Windows/macOS/Ubuntu run 30753479753; the structurally validated after-task report records the evidence and retained boundaries. |
