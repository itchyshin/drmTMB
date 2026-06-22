# After Task: Bridge Payload Schema

## Goal

Bank S031 by defining row-specific R-to-Julia bridge payload fields without
promoting bridge support.

## Implemented

Added `docs/dev-log/dashboard/bridge-payload-schema.tsv` with rows for default
Gaussian location-scale payloads, Gaussian observed-response masks, location-only
exact-Gaussian REML diagnostics, univariate sigma-phylo REML, bivariate q4
phylo REML, large-p phylogenetic count models, general covariance structured
models, cross-family latent-rho models, and intentional-error payloads.

Added `docs/design/185-bridge-payload-schema.md`, then extended the
mission-control validator and start script so the schema table is checked and
served.

## Checks Run

```sh
tools/validate-mission-control.py
git diff --check
```

Result: mission-control validation passed with the bridge payload schema table,
and `git diff --check` was clean.

## Consistency Audit

This is a bridge-schema slice. It does not relax any bridge gate, change model
behavior, formula grammar, REML support, q4 support, interval coverage,
non-Gaussian REML wording, HSquared AI-REML status, public `engine_control`
status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S032 to add bridge provenance fields before any serialization or parity
smoke.
