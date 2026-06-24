# After-Task: Ayumi Bivariate q4 Truth A051-A060

## Goal

Bank the bivariate q4 wave of the Ayumi phylogenetic balance ledger without
turning native ML point/status evidence into REML or interval support.

## Changes

- Added `docs/design/201-ayumi-bivariate-q4-truth.md`.
- Added `native_tmb_q4_profile_250tip_budget` to
  `docs/dev-log/dashboard/q4-target-inventory.tsv`.
- Updated `docs/design/181-q4-target-estimator-inventory.md` so the 250-tip
  profile-budget row appears in the q4 target inventory note.
- Marked A051-A060 as banked in
  `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`.

## Checks Run

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phylo-gaussian", reporter = "summary")'
```

Result: focused phylogenetic Gaussian tests passed. Those tests cover native
q4 ML fitting, all four endpoint SD rows, six derived q4 correlations,
q2-plus-q2 block-diagonal separation, partial q4 rejection, q4 extractor
status fields, and broad q4 recovery diagnostics.

## Evidence Split

- Native q4 ML point/status evidence: `tests/testthat/test-phylo-gaussian.R`.
- Native q4 REML rejection: `docs/dev-log/dashboard/q4-target-inventory.tsv`
  and `docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md`.
- Derived q4 correlation status:
  `docs/dev-log/dashboard/phylo-extractor-status.tsv`.
- Native q4 bootstrap plumbing and negative evidence:
  `docs/dev-log/dashboard/bootstrap-refit-accounting.tsv`.
- 250-tip endpoint profile budget status:
  `docs/dev-log/after-task/2026-06-15-endpoint-profile-budget-status.md`.

## Boundary

A051-A060 do not implement native q4 REML, do not turn q2-plus-q2 into full q4,
do not make derived q4 correlations profile-ready, do not claim bootstrap or
profile interval coverage, do not promote Julia q4 REML bridge support, do not
claim HSquared AI-REML, and do not claim 10,440-tip sigma-phylo intervals.

## Next

Proceed to A061-A070, the Ayumi-data wave. If the benchmark bundle is absent
or inaccessible, bank that explicitly and avoid real-data claims.
