# Post-#1651 receipt refresh

## Problem and change

The merged documentation-pin correction changed the whole-file hash for
`R/drmTMB.R`, causing the bridge receipt check to fail. This refresh records a
new run against the combined main source and preserves the previous receipt.
The published 0.8.1 tags are unchanged.

## Validation

The 12-label, 72-row fixture passed eight checks on R commit `51f94e61a` and
Julia commit `0460f25ff`. The remote source-aware checker rejected all twelve
negative controls. Labels, rows, ordering, tree and group covariate matched the
previous fixture. The local CI-equivalent check passed for the R source and
runner; it could not verify Julia paths because that checkout is on Totoro.
The remote checker verified the source paths at run time.

## Limits

This is one Gaussian phylogenetic fixture. It does not establish broad R–Julia
parity, other model families, or uncertainty calibration.
