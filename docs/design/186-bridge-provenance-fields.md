# Bridge Provenance Fields

This note supports S032 of the 100-slice finish run. It names provenance fields
that bridge payloads must preserve before serialization, reconstruction, or
parity evidence can carry a capability claim.

The machine-readable source is
`docs/dev-log/dashboard/bridge-provenance-fields.tsv`.

## Required Provenance

Bridge payloads need at least these provenance groups:

- estimator: requested estimator, effective estimator, REML requested/effective
  flags, and the reason for any mismatch;
- target: target id, model scope, family tag, distributional axes, structured
  source, and target parameter;
- data: observation counts, complete-row counts, response masks, predictor
  policy, and row-order digest;
- formula: formula terms, distributional parameters, links, unsupported terms,
  and any guard id;
- matrix: tree Newick or covariance digest, PSD status, name alignment, and
  tip/group levels;
- runtime: package versions, Julia/R versions, threads, BLAS/OpenMP state, and
  dirty worktree flags;
- inference: point, Wald, profile, bootstrap, and failure-reason statuses;
- reconstruction: maps for coefficients, covariance, profile targets,
  `corpairs()`, and summary status fields;
- unsupported payloads: guard id, message pattern, payload absence, and review
  due date.

## Boundary

S032 does not serialize a payload or relax a bridge gate. It prevents later
parity rows from comparing unnamed or estimator-ambiguous objects. Native TMB,
direct DRM.jl, and R-via-Julia rows still need row-specific evidence before a
bridge claim can advance.

## Next Action

S033 can add a gated location-only bridge draft row, but that row must remain
planned or experimental until the provenance tuple and reconstruction object
exist.
