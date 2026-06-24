# After Task: Ayumi Native ML Balance Targets

## 1. Goal

Bank A021-A025 by proving the native TMB ML univariate phylo balance cells have
explicit fit and profile-target status, and that malformed matched terms reject
early.

## 2. Implemented

Extended `tests/testthat/test-phylo-gaussian.R` so the existing native ML
univariate Gaussian phylo tests now assert direct profile-target status for:

- mean-only `phylo()` as `sd:mu:phylo(1 | species)`;
- sigma-only `phylo()` as `sd:sigma:phylo(1 | species)`;
- matched location-scale `phylo()` as `sd:mu:mu:phylo(1 | species)`,
  `sd:sigma:sigma:phylo(1 | species)`, and the mean-scale phylogenetic
  correlation target.

Added a fast malformed-input test showing that matched univariate
location-scale phylogenetic terms reject mismatched grouping variables, tree
objects, and covariance-block labels before fitting.

## 3a. Decisions and Rejected Alternatives

The slice records target readiness but does not run or claim interval coverage.
It also keeps native ML evidence separate from native REML and the R-to-Julia
bridge. Bootstrap and recovery rows remain queued until they have their own
evidence rather than borrowing this fit/target test.

## 4. Files Touched

- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/after-task/2026-06-22-ayumi-native-ml-balance-targets.md`

## 5. Checks Run

The focused phylogenetic Gaussian tests passed before and after formatting:

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
air format tests/testthat/test-phylo-gaussian.R
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
```

## 6. Tests of the Tests

The new malformed-input test exercises failure paths before optimization:
grouping-variable mismatch, tree-object mismatch, and covariance-block label
mismatch each produce an early error. The target checks would fail if
`profile_targets()` stopped exposing direct `mu`, `sigma`, or matched
mean-scale phylogenetic targets.

## 7a. Issue Ledger

No GitHub issue was edited. The slice supports the local Ayumi evidence map
behind `drmTMB#555` and the balance concern recorded from the user, but it does
not reply to Ayumi.

## 8. Consistency Audit

The new assertions sit beside existing native TMB ML tests rather than adding a
parallel fixture. The banked A021-A025 rows point to this report and keep
bootstrap, recovery, scale-clamp, and summary rows queued.

## 9. What Did Not Go Smoothly

Probing the current mismatch behavior by sourcing the test file executed all
tests in that file. It did not change repository state, but it was noisier than
using a smaller helper source would have been.

## 10. Known Residuals

A026-A030 remain unbanked. They need bootstrap plumbing, known-truth recovery,
clamp diagnostics, and a concise native ML summary before the native ML wave is
complete.

## 11. Team Learning

For Ayumi-facing balance, a supported fit is not enough. The fit needs a named
target row and the malformed neighbouring cells need clear early errors, or a
user cannot tell whether a model is supported, partial, or simply slipping
through accidentally.
