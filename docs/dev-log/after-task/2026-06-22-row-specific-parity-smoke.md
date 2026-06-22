# After-Task Report: Row-Specific Parity Smoke

## Task

Bank slice S039 by recording same-target native TMB versus R-to-Julia bridge
parity smoke evidence for named Gaussian cells.

## Changes

- Added `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`.
- Added `docs/design/193-row-specific-parity-smoke.md`.
- Extended mission-control validation and dashboard copying for the new parity
  smoke table.

## Checks

```sh
DRM_JL_PHYLO_PATH="/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot" \
DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" \
JULIA_HOME="/Users/z3437171/.juliaup/bin" \
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "julia-tmb-parity", reporter = "summary")'

tools/validate-mission-control.py
git diff --check
```

## Result

The Route C and Route B parity assertions passed. Route A stayed skipped with
the existing all-node log-likelihood bug reason, so it remains a visible
blocked row rather than bridge-promotion evidence.

## Claim Boundary

S039 records row-specific parity smoke only. It does not relax bridge gates,
promote q4 or non-Gaussian routes, claim interval coverage, claim non-Gaussian
REML, expose public `engine_control`, or touch Ayumi-facing text.
