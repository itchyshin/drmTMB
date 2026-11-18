# Plan versus actual — phylogenetic-stable plus independent OU methods gate

## Planned

G7 would verify conditional modes, fitted values, residuals, fresh simulation, conditional simulation and component labels for the paired phylogenetic-stable plus independent OU model.

## Actual

The new 25-assertion test reconstructs fitted values and response residuals from fixed, phylogenetic and OU contributions. With fixed seeds it independently reproduces both conditional simulation and marginal fresh simulation, including the structured-then-temporal draw order. It checks nested random-effect labels and the intentional unavailability of OU Wald covariance and `newdata` prediction.

## Evidence

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G7` returned `PHYLO_TEMPORAL_OU_G7_PASS`. The paired parser, dense oracle, methods, temporal parser, temporal OU and gate-runner test files all passed; `git diff --check` passed.

## Variance

G8 remains responsible for independently coded fixed-mean profile endpoints. G9 onward remain open. No campaign, remote action, release or broader temporal model work occurred.
