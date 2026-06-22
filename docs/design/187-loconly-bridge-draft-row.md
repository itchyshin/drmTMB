# Location-Only Bridge Draft Row

This note supports S033 of the 100-slice finish run. It adds a gated bridge
draft row for the exact-Gaussian location-only phylogenetic REML diagnostic.

The machine-readable source is
`docs/dev-log/dashboard/loconly-bridge-draft.tsv`.

## Contract

The row is intentionally asymmetric:

- direct DRM.jl diagnostic status is covered by the clean implementation
  worktree;
- payload schema and provenance contracts are now named in mission control;
- native R reconstruction, R-via-Julia reconstruction, and parity status remain
  planned;
- bridge status remains planned.

This row exists so later serialization and reconstruction work has one concrete
target. It does not expose a public R bridge feature and does not promote an
AI-REML optimizer.

## Next Action

S034 should test payload serialization stability for the draft row before any
R reconstruction object is added.
