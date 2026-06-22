# After-Task Report: Capability Comparison Regeneration

## Task

Bank slice S038 by regenerating the Julia bridge capability and gate artifacts
from their source functions and recording that evidence in mission control.

## Changes

- Ran `tools/write-julia-capability-comparison.R`, which wrote 9 capability
  rows to both dashboard and `inst/extdata/` outputs.
- Ran `tools/write-julia-gate-registry.R`, which wrote 15 intentional-gate rows
  to both dashboard and `inst/extdata/` outputs.
- Added `docs/dev-log/dashboard/capability-regeneration-status.tsv` and
  `docs/design/192-capability-comparison-regeneration.md`.
- Extended mission-control validation and dashboard copying for the new
  regeneration-status table.

## Checks

```sh
Rscript tools/write-julia-capability-comparison.R
Rscript tools/write-julia-gate-registry.R
git diff -- docs/dev-log/dashboard/julia-capabilities.tsv inst/extdata/julia-capabilities.tsv docs/dev-log/dashboard/julia-gates.tsv inst/extdata/julia-gates.tsv
Rscript -e 'devtools::test(filter = "julia-gate-vs-engine", reporter = "summary")'
tools/validate-mission-control.py
git diff --check
```

## Result

The generated artifacts match the source registries and had no content diff
after regeneration.

## Claim Boundary

S038 records artifact regeneration only. It does not relax bridge gates,
promote any Julia route, change formula grammar, change REML support, add q4
interval coverage, claim non-Gaussian REML, expose public `engine_control`, or
touch Ayumi-facing text.
