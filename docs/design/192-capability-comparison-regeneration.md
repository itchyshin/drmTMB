# Capability Comparison Regeneration

Slice S038 records regeneration evidence for the generated Julia bridge
registry artifacts. These artifacts are not hand-edited source-of-truth tables:

- `julia-capabilities.tsv` is generated from
  `drm_julia_capability_comparison()`;
- `julia-gates.tsv` is generated from `drm_julia_intentional_gates()`.

Both writers emit a dashboard copy and an `inst/extdata/` copy so tests can
compare installed-package artifacts when `docs/` is absent.

## Evidence

The regeneration status table is
`docs/dev-log/dashboard/capability-regeneration-status.tsv`. It records the
source function, writer script, dashboard output, installed-package output, row
counts, test status, and bridge boundary for each generated artifact.

## Boundary

Regeneration evidence is not capability promotion. A generated row remains
`supported`, `experimental`, `intentional_error`, `planned`, or `unsupported`
exactly as the source function states. This slice does not widen any bridge
route, expose optimizer controls, or change REML/AI-REML language.
