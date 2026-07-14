# Ayumi Bivariate q4 Truth

## Purpose

This note banks the bivariate q4 wave for the Ayumi phylogenetic balance arc.
It separates native TMB ML point/status evidence, native TMB REML recovery,
experimental Julia bridge REML, q2-plus-q2 block-diagonal fits, and interval
status evidence.

## Native q4 ML

`tests/testthat/test-phylo-gaussian.R` fits the constant bivariate
phylogenetic q4 location-scale block:

```r
bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ z + phylo(1 | p | species, tree = tree),
  sigma2 = ~ z + phylo(1 | p | species, tree = tree),
  rho12 = ~ 1
)
```

The fitted object reports four endpoint SDs and six phylogenetic endpoint
correlations. `corpairs()` and `summary(fit)$covariance` expose point/status
rows. `profile_targets()` marks the six q4 correlations as derived
unstructured correlations, not direct profile-ready targets. This is diagnostic
native ML support, not interval coverage.

## q2, q2-Plus-q2, And Partial q4

The same focused test keeps lower-dimensional evidence separated:

- matching `mu1`/`mu2` phylogenetic terms are q2 location-location evidence;
- two labels, one for `mu1`/`mu2` and one for `sigma1`/`sigma2`, are
  block-diagonal q2-plus-q2 evidence, not full q4 unstructured covariance;
- partial all-four q4 blocks reject early, including missing axes, missing
  labels, and mismatched covariance-block labels.

## Inference Status

The q4 inference evidence is intentionally status-first:

- `docs/dev-log/dashboard/q4-target-inventory.tsv` records native q4 ML as
  partial point/Wald/profile/bootstrap evidence and native q4 REML as
  recovery-only,
  Julia q4 REML as experimental, and profile-target reconstruction as a target
  inventory only.
- `docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv` keeps q2, q2-plus-q2,
  full q4, native REML recovery, and Julia bridge rows distinct.
- `docs/dev-log/dashboard/phylo-extractor-status.tsv` records the q4
  `corpairs()`, `summary()$covariance`, and `profile_targets()` status fields.
- `docs/dev-log/dashboard/bootstrap-refit-accounting.tsv` records 30-tip native
  q4 bootstrap plumbing success (`B = 2`, 2/2 refits) and 100-tip native q4
  bootstrap failures under careful and robust presets.
- `docs/dev-log/after-task/2026-06-15-endpoint-profile-budget-status.md`
  records a 250-tip profile-budget smoke that returns a row-level
  `profile_failed` status instead of hanging or implying an interval.

## Decision

The q4 truth for the Ayumi reply is: native TMB ML can fit the q4 block and
report point/status evidence, and native TMB REML has tested block-diagonal and
dense recovery evidence. The six q4 correlations still lack calibrated
intervals. Bootstrap and profile rows are diagnostics, not calibrated
uncertainty. Julia q4 REML bridge rows remain experimental and do not establish
same-target parity, HSquared AI-REML, or a 10,440-tip interval claim.
