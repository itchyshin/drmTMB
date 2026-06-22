# Structured Random-Effect Bridge Readiness

## Purpose

This note banks SR071-SR080 for the structured random-effect balance arc. It
keeps native R/TMB, direct DRM.jl, and R-via-Julia bridge evidence separate.

Direct Julia evidence can guide the bridge. It does not make a public R bridge
row supported.

## Direct DRM.jl Map

The active DRM.jl implementation worktree has direct q4 and location-only REML
diagnostic evidence. The important local facts are:

- q4 profile/bootstrap code exists for direct DRM.jl;
- the direct q4 bootstrap study found severe scale-axis SD undercoverage at
  nominal 90% coverage;
- the exact-Gaussian location-only REML diagnostic rows report
  `coverage_status = not_evaluated` and `ai_reml_ready = false`;
- q4 Patterson-Thompson REML and HSquared AI-REML remain different claims.

The R dashboard records those facts as design input, not bridge support.

## Payload And Provenance

`docs/dev-log/dashboard/bridge-payload-schema.tsv` records the payload fields
that each route must carry before parity can be claimed. Structured routes need
matrix provenance: tree Newick or covariance digest, positive-semidefinite
status, name alignment, levels, estimator tuple, target identity, runtime
versions, and missingness policy.

`docs/dev-log/dashboard/bridge-provenance-fields.tsv` names the provenance
groups that must survive reconstruction. In particular, requested estimator and
effective estimator must both be visible so an R request for REML cannot be
silently reported as a REML fit when the effective bridge row used ML.

## Parity And Rejections

`docs/dev-log/dashboard/bridge-parity-smoke-status.tsv` records row-specific
smoke evidence. It includes covered base Gaussian rows, a blocked phylogenetic
mean row, and experimental sigma-phylo/q4 rows. None of those rows is broad
bridge support.

`docs/dev-log/dashboard/bridge-rejection-messages.tsv` records early
pre-JuliaCall errors for unsupported payloads. Structured bridge rows currently
gate unsupported families, sigma predictors, precision-matrix `Q` slots, and
partial q4 axes before JuliaCall setup. Those early errors are part of the
bridge contract: unsupported rows should fail visibly rather than become
accidental partial support.

`docs/dev-log/dashboard/julia-home-smoke.tsv` records helper-level environment
tests. These show `DRM_JL_JULIA_HOME`/`JULIA_HOME` wiring only. They are not
capability support.

## Live Unblock Attempt

On 2026-06-22 the guarded live bridge files were run against the active DRM.jl
worktree:

- `test-julia-sigma-phylo-reml.R`: 52 pass;
- `test-julia-structured.R`: 47 pass;
- `test-julia-phylo-q4-corpairs.R`: 27 pass.

This is useful smoke evidence for the gate, finite-and-sane bridge routes, and
q4 `corpairs()` reconstruction. It does not bank SR073-SR075 because those rows
ask for bridge parity: native R/TMB, direct DRM.jl, and R-via-Julia must agree
on the row-specific target before support can be promoted.

## Decision

SR071-SR080 are banked as bridge-readiness rows. The current state is:

- native R/TMB support is row-specific;
- direct DRM.jl evidence is useful but separate;
- R-via-Julia bridge rows remain experimental, planned, or intentionally
  rejected unless a row has native R, direct DRM.jl, and R-via-Julia parity;
- no public optimizer or `engine_control` surface is promoted.
