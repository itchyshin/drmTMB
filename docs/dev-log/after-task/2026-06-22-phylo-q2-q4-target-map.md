# After Task: Phylo q2/q4 Target Map

## Goal

Bank S028 by linking q2 and q4 phylogenetic target evidence without collapsing
their support or uncertainty statuses.

## Implemented

Added `docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv` with seven rows for
native TMB q2 location ML, q2 corpair regression, unsupported native q2 REML,
native TMB full q4 ML, native TMB block-diagonal q2-plus-q2 ML, unsupported
native q4 REML, and experimental Julia q4 REML bridge evidence.

Added `docs/design/183-phylo-q2-q4-target-map.md` to define `q2`, `q4`, and
`q2_plus_q2` before the next extractor-status slice. Updated the dashboard
validator and start script so the map is checked and served.

## Checks Run

```sh
tools/validate-mission-control.py
git diff --check
```

Result: mission-control validation passed with the q2/q4 target map, and
`git diff --check` was clean.

## Consistency Audit

This is a target-map slice. It does not change model behavior, formula grammar,
REML support, bridge support, q4 support, interval coverage, non-Gaussian REML
wording, HSquared AI-REML status, or Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S029 to expose summary and extractor status fields without promoting Wald
or interval support.
