# 2026-11-11 — fix #1716 constructor-call hint (Code Reviewer revision)

## Scope

Revise draft PR #1723 (branch `cursor/fix-1716-foreign-zigamma-6219`) for
the remaining Code Reviewer items without editing the PR body and without
touching the C17 watchlist.

## Changes

- Deleted the untyped `expect_error` on `family = "Gamma"` and
  `family = stats::Gamma`. `R/family.R` has no supported-families
  condition class; those calls already error on main via unclassed
  `drm_family_type()`.
- String and uncalled `truncated_nbinom2` / `lognormal` now abort with
  class `drmTMB_family_constructor_call` and the hint
  `Call drmTMB::<name>()`, instead of `drmTMB_foreign_inflation_family`.
- Real `glmmTMB::ziGamma(link = "log")` labels as `glmmTMB::ziGamma` by
  recovering the package from the namespaced call expression, because
  the family object's closures live in stats.
- Merged `origin/main` (PR #1722) and kept both NEWS bullets (#1716 and
  #1703).

## Evidence

R 4.3.3, `pkgload::load_all()` from this branch. `{glmmTMB}` is not
installed, so the live constructor tests skip.

```text
python3 tools/capability_ledger.py --check
capability-ledger: OK (31 generated outputs)

python3 tools/capability_ledger.py --check-c14-receipt-equivalence
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)

C17 watchlist vs origin/main (git hash-object):
R/drmTMB.R                                              5be5ba5480117fd8527e28b1bba7670d4e09cbca IDENTICAL
R/methods.R                                             2b176cee67c1b216261a49b4bd048709ede5b9da IDENTICAL
src/drmTMB.cpp                                          908e355702a215476babcd754aeb4db632a29cbb IDENTICAL
tests/testthat/test-zero-one-beta.R                     5791bad2278c05be035f63308dbb3be0c86b29fe IDENTICAL
tools/run-lane-c-c17c1-c14-model15-compatibility.R      b0650851d2a7a2989d9622eed1f3ed68d9ef2a3d IDENTICAL

test-fix-1716-foreign-zigamma.R: 15 tests / 46 passed expectations / 0 fail / 2 skip
test-family-link-contract.R: 4 / 92 / 0 / 0
test-control-family-validators.R: 9 / 83 / 0 / 0
test-gamma-location-scale.R: 7 / 76 / 0 / 0
test-family-dpq.R: 5 / 23 / 0 / 0
test-family-dpq-batchA.R: 14 / 131 / 0 / 0
test-family-dpq-batchB.R: 6 / 63 / 0 / 2 skip
test-family-dpq-batchC.R: 12 / 122 / 0 / 2 skip
test-family-dpq-batchD.R: 12 / 74 / 0 / 3 skip
```
