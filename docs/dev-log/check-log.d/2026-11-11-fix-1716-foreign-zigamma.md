# 2026-11-11 — fix #1716 foreign ziGamma refusal (review revision)

## Scope

Foreign zero-inflated, hurdle, and truncated stats `family` objects are
refused with class `drmTMB_foreign_inflation_family` before
`drm_family_type()` can route them to a plain non-inflation family.
The guard lives in `R/family.R` and wraps `drm_family_type()` after
`R/drmTMB.R` is sourced, so `R/drmTMB.R` stays byte-identical to `main`
(C17 watchlist).

## Evidence

R 4.3.3, installed drmTMB 0.8.1 from this branch. `{glmmTMB}` is not
installed on this VM; those two tests skip as designed.

```text
python3 tools/capability_ledger.py --check
capability-ledger: OK (31 generated outputs)

python3 tools/capability_ledger.py --check-c14-receipt-equivalence
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)

git hash-object R/drmTMB.R
git rev-parse origin/main:R/drmTMB.R
5be5ba5480117fd8527e28b1bba7670d4e09cbca
5be5ba5480117fd8527e28b1bba7670d4e09cbca

Rscript tools/write-env-skip-census.R
wrote inst/extdata/env-skip-census.tsv (2014 skip call sites)
test-fix-1716-foreign-zigamma.R	suggests-package	environment	runs	2

Rscript -e 'library(testthat); library(drmTMB); test_file("tests/testthat/test-fix-1716-foreign-zigamma.R")'
fix-1716-foreign-zigamma: .....S..S
PASS 4 tests / 8 expectations; SKIP 2 tests (glmmTMB not installed)

Rscript -e 'library(testthat); library(drmTMB); test_file("tests/testthat/test-env-skip-census.R")'
env-skip-census: .....
PASS 3 tests / 5 expectations

test-family-link-contract.R 4 tests / 92 expectations, 0 fail
test-control-family-validators.R 9 tests / 83 expectations, 0 fail
test-gamma-location-scale.R 7 tests / 76 expectations, 0 fail
```

Same test file against origin/main `3f45ade61` (separate library):

```text
6 tests: 2 failed, 1 error, 2 skipped, 3 passed expectations
hand-built ziGamma name: rlang_error "Currently supported families..."
hand-built Gamma + ziformula initialize: drm_family_type() returns "gamma" (the silent misfit)
```
