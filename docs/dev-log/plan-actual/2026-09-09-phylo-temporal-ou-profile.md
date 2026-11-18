# Plan versus actual — phylogenetic-stable plus independent OU profile gate

## Planned

G8 would compare fixed-mean profile endpoints against an independent dense reference, reject deferred targets and make irregular-Hessian behavior visible.

## Actual

The independent dense Cholesky likelihood re-optimized all five nuisance coordinates for each fixed `beta_mu:x` value and solved 90% likelihood-ratio crossings. It obtained lower/upper endpoints 0.17577 and 0.59428, compared with public endpoints 0.17544 and 0.59399. The suite also rejects decay and phylogenetic-SD profiles, bootstrap, `newdata`, and the scalar endpoint engine; a non-PD Hessian emits the documented warning while retaining a finite profile.

## Evidence

`Rscript --vanilla tools/phylo-temporal-ou-gates.R G8` returned `PHYLO_TEMPORAL_OU_G8_PASS`. The focused profile suite and surrounding paired/temporal regressions passed; `git diff --check` passed.

## Variance

Profile calibration and all claim-bearing simulation evidence remain later work. No campaign, remote action, release or wider temporal implementation occurred.
