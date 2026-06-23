# After-Task: SR128 q2 Direct DRM.jl Export Status

## Goal

Bank the q2 direct DRM.jl export/status contract before any q2 R-via-Julia
bridge parity work. The row must say what direct DRM.jl would need to expose
for `phylo()`, `spatial()`, `animal()`, and `relmat()` q2 location targets,
while keeping full q2 bridge parity unavailable.

## Changes

- Added internal DRM.jl helpers:
  `drm_bridge_q2_phylo()`,
  `_bridge_q2_point_export()`,
  `_bridge_q2_direct_export_schema()`,
  `_bridge_q2_direct_export_status()`, and
  `_bridge_q2_validate_direct_export_status()`.
- Added restricted direct q2 phylo point-export evidence for diagonal-residual
  coevolution fixtures through DRM.jl's general-q Gaussian coevolution engine.
- Added the private R diagnostic boundary
  `drm_julia_call_q2_phylo_point_export()` and a guarded live JuliaCall test.
- Added a focused DRM.jl test:
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_bridge_q2_direct_export.jl`.
- Added the mission-control sidecar:
  `docs/dev-log/dashboard/structured-re-q2-direct-drmjl-export.tsv`.
- Added validator rules for the q2 direct export sidecar.
- Updated the dashboard UI so q2 payload, q2 coefficient-order, and q2 direct
  export sidecars are rendered.

## Checks Run

```sh
julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_bridge_q2_direct_export.jl
DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-q2-phylo-point-export')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts|structured-re-bridge-fixtures')"
python3 tools/validate-mission-control.py
```

Result:

- `q2 direct export status contract` passed with 20 assertions.
- `restricted q2 phylo point export carries coevolution covariance` passed with
  19 assertions.
- `private q2 phylo bridge primitive returns restricted point export` passed
  with 12 assertions on the Julia side.
- The private R diagnostic bridge primitive passed with 11 assertions when
  pointed at the active DRM.jl worktree.
- The focused R dashboard/fixture guard passed with 639 assertions.
- `tools/validate-mission-control.py` passed with 4 q2 direct-DRM.jl export
  rows and the restricted phylo row separated from unavailable non-phylo rows.

## Boundary

This banks a restricted direct-Julia q2 phylo point export and a private R
diagnostic primitive only for diagonal-residual coevolution fixtures. It does
not implement the full bivariate q2 residual-correlation route,
spatial/animal/relmat q2 direct fits, public q2 R-via-Julia bridge support,
q2 REML, q4 support, interval coverage, public bridge support, a commit, a PR,
or an Ayumi-facing reply.

## Update 2026-06-23: Narrow q2 Phylo Same-Target Fixture

The q2 phylo lane now also has a complete-response exact-Gaussian ML
residual-correlation fixture across direct DRM.jl and R-via-Julia. The
restricted diagonal diagnostic remains retained as negative/boundary evidence,
but it is no longer the only q2 phylo direct-export evidence.

Additional checks:

```sh
julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot test/test_bridge_q2_direct_export.jl
Rscript --vanilla -e "devtools::test(filter = 'julia-bridge')"
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot Rscript --vanilla -e "devtools::test(filter = 'julia-tmb-parity')"
```

Results:

- The focused Julia q2 direct-export file passed 66 assertions, including the
  same-target residual-correlation phylo route, the restricted diagonal route,
  and the private bridge primitive.
- The focused R bridge gate passed 106 assertions.
- The live R q2 phylo parity fixture passed 82 assertions inside
  `julia-tmb-parity`.

This update banks only one q2 phylo ML same-target fixture. It does not promote
spatial/animal/relmat q2 direct fits, aggregate q2 bridge support, q2 REML, q4,
interval coverage, public bridge support, a commit, a PR, or an Ayumi-facing
reply.

## Update 2026-06-23: Known-Matrix Non-Phylo Direct Fixtures

DRM.jl now has a direct known-precision/known-covariance constructor for the
general-q exact-Gaussian coevolution block. The focused q2 direct-export test
adds relmat and animal known-covariance residual-correlation point exports and
a fixed-covariance spatial fixture. The spatial row is explicitly not a
range-estimating q2 spatial route.

Additional check:

```sh
julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot test/test_bridge_q2_direct_export.jl
```

Result: the focused Julia q2 direct-export file passed 102 assertions,
including q2 phylo residual-correlation, relmat and animal known-covariance
direct exports, fixed-covariance spatial direct evidence, the retained
restricted diagonal diagnostic, and the private q2 diagnostic primitive.

This update banks direct DRM.jl fixture evidence only. It does not promote
R-via-Julia q2 bridge support beyond the narrow phylo fixture, q2 REML, q4,
range-estimating q2 spatial support, interval reliability, interval coverage,
public bridge support, a commit, a PR, or an Ayumi-facing reply.
