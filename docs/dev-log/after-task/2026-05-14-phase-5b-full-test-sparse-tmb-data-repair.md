# After Task: Phase 5b Full-Test Sparse TMB Data Repair

## Goal

Repair the full test suite after Slice 45 added sparse fixed-effect declarations
to the global TMB data contract.

## Implemented

- Added a dummy `Matrix::sparseMatrix()` to `phylo_prior_tmb_data()`.
- Added `use_sparse_X_mu = 0L` and `X_mu_sparse = dummy_sparse` to the raw
  phylogenetic prior TMB data helper.
- Preserved the dense fixed-effect path used by the phylogenetic prior tests.

## Mathematical Contract

No fitted model changed. The raw TMB prior probes now provide the sparse
fixed-effect fields that the template declares, while explicitly setting
`use_sparse_X_mu = 0L` so the prior-only tests remain dense fixed-effect tests.

## Files Changed

- `tests/testthat/test-phylo-utils.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-14-phase-5b-full-test-sparse-tmb-data-repair.md`

## Checks Run

- Full `devtools::test(reporter = "summary")`: failed before the repair because
  raw `TMB::MakeADFun()` calls in `test-phylo-utils.R` lacked
  `use_sparse_X_mu`.
- Focused `devtools::test(filter = "phylo-utils", reporter = "summary")`:
  passed after the repair.
- Full `devtools::test(reporter = "summary")`: passed after the repair.
- `git diff --check`: passed after formatting the repair files.

## Tests Of The Tests

The failure came from direct TMB tests that bypass the ordinary R-side data
builder. Those tests are useful because they caught a real template-data
contract drift that targeted sparse fixed-effect tests did not exercise.

## Consistency Audit

The repair keeps sparse fixed-effect support limited to the documented
univariate Gaussian `mu` path. It does not change roadmap, vignette, NEWS, or
user-facing syntax.

## What Did Not Go Smoothly

Ada let the sparse TMB declaration land before checking every direct
`TMB::MakeADFun()` fixture. The package builder supplied the new fields, but
the prior-probe fixtures did not.

## Team Learning

- Ada should scan raw TMB fixtures whenever a template-level `DATA_*`
  declaration changes.
- Boole had no API change to review.
- Gauss should treat missing raw TMB fields as a template contract issue, not a
  likelihood issue.
- Noether should confirm direct algebra probes still test the same dense prior
  algebra after dummy data fields are added.
- Curie should keep raw TMB fixture coverage in the full-test gate.
- Fisher had no inference change to review.
- Pat should not see any new user-facing behaviour from this repair.
- Grace should keep full `devtools::test()` as the merge gate after template
  declarations change.
- Rose should record the failure before the fix so the branch history explains
  why a one-line-looking test data patch matters.

## Known Limitations

- Sparse fixed effects still reject phylogenetic, spatial, bivariate,
  random-effect, direct-SD, and non-Gaussian paths.
- This is a test-harness repair, not a new Phase 5b modeling feature.

## Next Actions

Commit the repair, push the Phase 5b branch, open the PR, and let GitHub
Actions confirm the cross-platform gate.
