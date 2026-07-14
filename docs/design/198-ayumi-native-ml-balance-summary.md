# Ayumi Native ML Phylo Balance Summary

This note summarizes the native TMB maximum-likelihood side of the Ayumi
phylo-balance question. It is a local evidence note, not an issue reply.

## What Native ML Supports

For univariate Gaussian models, native `engine = "tmb"` with `REML = FALSE`
supports three `phylo()` layouts:

- mean-side phylo only:
  `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`;
- scale-side phylo only:
  `bf(y ~ x, sigma ~ phylo(1 | species, tree = tree))`;
- matched mean-plus-scale phylo with the same source:
  `bf(y ~ x + phylo(1 | species, tree = tree),
  sigma ~ phylo(1 | species, tree = tree))`.

The focused tests in `tests/testthat/test-phylo-gaussian.R` now check that all
three layouts fit and expose direct `profile_targets()` rows. The matched
layout also exposes the direct mean-scale phylogenetic correlation target.

## What This Does Not Claim

Native ML balance is not native REML balance. Native REML now admits tested
mean-side, sigma-side, matched, q2, and q4 phylogenetic Gaussian rows at
row-specific tiers. Only the named mean-side q1 row has retained interval
evidence; the sigma-side, matched, q2, and q4 rows remain point-fit or recovery
only. The balanced native ML row therefore does not imply calibrated interval
coverage, q4 REML inference, or a 10,440-tip sigma-phylo interval claim.

The new bootstrap test is a plumbing smoke only. It checks that small mean-side
and scale-side univariate phylo targets carry requested refit counts,
successful refit counts, and per-refit diagnostics. It does not evaluate
coverage or Ayumi-scale runtime.

The new recovery tests are broad single-replicate smokes. They show that the
sigma-only and matched native ML routes recover a strong known-truth signal
within broad factor-scale tolerances. They are not a bias, RMSE, or MCSE grid.

## What Ayumi Can Try Today

If the scientific question is univariate and the goal is a native R/TMB point
fit with row-level diagnostics, the supported starting point is native ML with
one of the three univariate Gaussian `phylo()` layouts above. For a scale-side
phylogenetic field, `check_drm()` should be part of the workflow because
`pdHess = FALSE`, clamp-active warnings, and weak scale-side identifiability
need to be read as inference warnings, not as automatic point-fit deletion.

If the goal is native REML for scale-side, matched location-scale, q2, or q4
phylo, the honest answer is that point-fit or recovery routes exist but their
interval and coverage evidence is not ready. A 10,440-tip interval claim stays
outside the current native and experimental Julia/DRM.jl evidence.

## Evidence Rows

- `docs/dev-log/dashboard/phylo-balance-inventory.tsv`
- `docs/dev-log/dashboard/scale-phylo-diagnostics.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-balance-targets.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-bootstrap-accounting.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-recovery-smokes.md`
