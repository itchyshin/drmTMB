# After Task: Ayumi Native ML Recovery Smokes

## 1. Goal

Bank A027-A028 by adding broad known-truth recovery smokes for native TMB ML
univariate scale-side and matched location-scale phylogenetic Gaussian cells.

## 2. Implemented

Added a `new_sigma_only_phylo_gaussian_data()` fixture and two focused tests in
`tests/testthat/test-phylo-gaussian.R`:

- a sigma-only phylogenetic ML fit that recovers the scale-side phylogenetic SD
  within a broad factor-of-two tolerance;
- a matched mean-plus-scale phylogenetic ML fit that recovers both SDs within a
  broad factor-of-three tolerance and keeps the simulated positive mean-scale
  correlation positive.

## 3a. Decisions and Rejected Alternatives

The tests use broad known-truth gates because they are smokes, not replicated
simulation studies. They check the direction and rough scale of the native ML
balance signal without claiming interval coverage, unbiased recovery, or
Ayumi-scale performance.

## 4. Files Touched

- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-recovery-smokes.md`

## 5. Checks Run

```sh
air format tests/testthat/test-phylo-gaussian.R
git diff --check
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
```

The focused phylogenetic Gaussian tests passed.

## 6. Tests of the Tests

The sigma-only test would fail if the scale-side phylogenetic SD collapsed
outside a broad recovery band. The matched test would fail if either SD moved
outside its broad band or if the simulated positive mean-scale phylogenetic
correlation was recovered with the wrong sign.

## 7a. Issue Ledger

No GitHub issue was edited. These rows support the local Ayumi balance ledger
and keep the native ML evidence separate from `drmTMB#570` beak rescue and
`DRM.jl#291` q4 REML acceleration.

## 8. Consistency Audit

The ledger marks A027-A028 as broad smoke evidence only. Bootstrap plumbing,
scale-clamp diagnostics, and the native ML summary stay separate from these
known-truth checks.

## 9. What Did Not Go Smoothly

The recovery tests needed probing to find tolerances that were honest about
small-sample variability without becoming toothless. The final tests use
factor-scale tolerances because variance-component estimates are naturally
multiplicative.

## 10. Known Residuals

There is no replicated simulation grid, RMSE/MCSE ledger, coverage evaluation,
or Ayumi-data recovery claim. The beak full-data failure remains unresolved.

## 11. Team Learning

Variance-component recovery should be judged against known truth with explicit
tolerances. For small smoke fixtures, factor-scale tolerances are clearer than
pretending a single replicate gives a calibrated bias estimate.
