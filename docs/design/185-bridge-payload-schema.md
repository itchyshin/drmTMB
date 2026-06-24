# Bridge Payload Schema

This note supports S031 of the 100-slice finish run. It defines row-specific
payload fields for the R-to-Julia bridge before any bridge gate is relaxed.

The machine-readable source is
`docs/dev-log/dashboard/bridge-payload-schema.tsv`.

## Contract

A bridge row can advance only when the same row has:

- native R/TMB target status, when the row requires a native comparator;
- direct DRM.jl target status;
- R-via-Julia reconstruction status;
- target estimator and effective estimator fields;
- inference/status fields;
- provenance fields for data, formulas, covariance objects, versions, and
  unsupported payloads.

The schema table is not a promotion table. It records what each route must carry
before parity is allowed to mean anything.

## Guarded Routes

The table separates:

- default Gaussian location-scale bridge payloads;
- Gaussian observed-response masks;
- exact-Gaussian location-only REML diagnostics;
- univariate sigma-phylo REML bridge payloads;
- bivariate q4 phylo REML bridge payloads;
- large-p phylogenetic count payloads;
- general covariance structured payloads;
- cross-family latent-rho payloads;
- intentional-error payloads that must remain rejected until a real schema
  exists.

## Boundary

S031 does not promote the bridge. It only names the fields that later slices
must preserve and test. `engine_control` remains reserved, q4 Patterson-
Thompson REML remains separate from HSquared AI-REML, and non-Gaussian routes
must not borrow REML wording.

## Next Action

S032 should add provenance fields for target estimator, effective estimator,
matrix source, data source, package versions, and dirty worktree state.
