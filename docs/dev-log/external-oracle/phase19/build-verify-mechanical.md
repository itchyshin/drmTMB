# Phase 19 Mechanical Verification Report

**Role**: Grace (MECHANICAL verification)  
**Date**: 2026-08-15  
**Branch**: claude/phase19-comparator-workflows  
**Commit**: (branch up-to-date with origin/main; local uncommitted changes only)

---

## 1. testthat::test_file() on test-comparators-phase19.R

**Command**:
```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-comparators-phase19.R", reporter = "summary")
```

**Output**:
```
comparators-phase19: .........................................

══ DONE ════════════════════════════════════════════════════════════════════════
```

**Status**: PASS (41 tests)

---

## 2. Reader Baseline Tests

### 2a. test-reader-public-schema.R

**Command**:
```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-reader-public-schema.R", reporter = "summary")
```

**Output**:
```
reader-public-schema: ..................................

══ DONE ════════════════════════════════════════════════════════════════════════
```

**Status**: PASS (34 tests)

### 2b. test-reader-journeys.R

**Command**:
```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-reader-journeys.R", reporter = "summary")
```

**Output**: (excerpt; full output includes detailed workflow table)
```
reader-journeys: 
Setting initial dates...
Fitting in progress...
...
Wrote /var/folders/7x/ytfpq14s0v18frbm9v_w9f4c0000gq/T//RtmpVxB6f4/fileb6bc5b9cd8f1.tsv
.....................................................

══ DONE ════════════════════════════════════════════════════════════════════════
```

**Status**: PASS (53 tests)

### 2c. test-reader-vignette-contracts.R

**Command**:
```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-reader-vignette-contracts.R", reporter = "summary")
```

**Output**:
```
reader-vignette-contracts: .....................

══ DONE ════════════════════════════════════════════════════════════════════════
```

**Status**: PASS (23 tests)

### 2d. test-comparators-external-oracle.R

**Command**:
```r
devtools::load_all(quiet = TRUE)
testthat::test_file("tests/testthat/test-comparators-external-oracle.R", reporter = "summary")
```

**Output**:
```
comparators-external-oracle: ............................

══ DONE ════════════════════════════════════════════════════════════════════════
```

**Status**: PASS (28 tests)

---

## 3. Rscript tools/check-reader-contracts.R

**Command**:
```bash
Rscript tools/check-reader-contracts.R
```

**Output**:
```
Reader vignette contract: OK
```

**Status**: PASS

---

## 4. Python Capability Ledger Checks

### 4a. python3 tools/capability_ledger.py --check

**Command**:
```bash
python3 tools/capability_ledger.py --check
```

**Output**:
```
capability-ledger: OK (31 generated outputs)
```

**Status**: PASS

### 4b. python3 -m unittest tools/tests/test_capability_ledger.py

**Command**:
```bash
python3 -m unittest tools/tests/test_capability_ledger.py
```

**Output**:
```
.............................................................F...........
======================================================================
FAIL: test_reader_navigation_redirect_and_public_language_contract (tools.tests.test_capability_ledger.CapabilityLedgerTests.test_reader_navigation_redirect_and_public_language_contract)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/phase19/tools/tests/test_capability_ledger.py", line 1206, in test_reader_navigation_redirect_and_public_language_contract
    self.assertIn(f"across {vignette_count} vignettes", design.splitlines()[0])
    ~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: 'across 38 vignettes' not found in '# 226 — One canonical reader learning path across 37 vignettes'

----------------------------------------------------------------------
Ran 73 tests in 2.058s

FAILED (failures=1)
C14 receipt equivalence: OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)
capability-ledger: OK (1 generated outputs)
```

**Status**: FAIL — 1 failure out of 73 tests

**Failure Details**:
- Test: `test_reader_navigation_redirect_and_public_language_contract`
- Expected: design file header to say "across 38 vignettes"
- Actual: design file header says "# 226 — One canonical reader learning path across 37 vignettes"
- Root cause: Design document line 1 has not been updated to reflect the new vignette count (38 vignettes, not 37)

---

## 5. pkgdown::check_pkgdown()

**Command**:
```r
pkgdown::check_pkgdown()
```

**Output**:
```
✔ No problems found.
```

**Status**: PASS

---

## 6. Git Diff: Receipt-Pinned Files

**Command**:
```bash
git diff R/methods.R R/drmTMB.R src/drmTMB.cpp tests/testthat/test-zero-one-beta.R tools/run-lane-c-c17c1-c14-model15-compatibility.R
```

**Output**: (no output)

**Status**: PASS — None of the five receipt-pinned files have changed.

**Note**: Branch is up-to-date with origin/main (no commits ahead).

---

## 7. Vignette, Articles, and Manifest Counts

### 7a. Vignette Count

**Command**:
```bash
ls vignettes/*.Rmd | wc -l
```

**Output**:
```
38
```

### 7b. Articles in _pkgdown.yml

**Command**:
```bash
awk '/^articles:/,/^$/' _pkgdown.yml | grep -E "^\s+-\s+" | grep -v "title:\|contents:" | wc -l
```

**Output**:
```
38
```

### 7c. Manifest Rows

**File**: `inst/reader-contracts/vignette-manifest.csv`

**Count**: 38 rows (data rows; line 40 is blank)

**Status**: All three counts match = 38

---

## 8. Vignette Knit Test

### New Vignette: comparing-with-other-packages.Rmd

**Command**:
```r
devtools::load_all(quiet = TRUE)
knitr::knit("vignettes/comparing-with-other-packages.Rmd", output = "/tmp/comparing-vignette-output.md")
```

**Output** (last 30 lines):
```
47/73 [comparison6-fe-check]        
48/73                               
49/73 [comparison6-drmtmb]          
50/73                               
51/73 [comparison6-comparator]      
52/73                               
53/73 [comparison6-loglik]          
54/73                               
55/73 [comparison7-drmtmb]          
56/73                               
57/73 [comparison7-comparator]      
58/73 [comparison7-mu-check]        
59/73 [comparison7-loglik]          
60/73 [comparison8-fe-check]        
61/73 [comparison8-clash]           
62/73 [comparison8-drmtmb]          
63/73 [comparison8-comparator]      
64/73 [comparison8-convert]         
65/73 [comparison8-loglik]          
66/73                               
67/73 [comparison8-clash]           
68/73 [comparison8-drmtmb]          
69/73 [comparison8-comparator]      
70/73 [comparison8-convert]         
71/73                               
72/73 [comparison8-clash]           
73/73                               
output file: /tmp/comparing-vignette-output.md

[1] "/tmp/comparing-vignette-output.md"
```

**Status**: PASS — Vignette knit completed successfully. All 73 chunks executed without error.

---

## Summary

| Check | Status | Notes |
|-------|--------|-------|
| test-comparators-phase19.R | PASS | 41 tests |
| test-reader-public-schema.R | PASS | 34 tests |
| test-reader-journeys.R | PASS | 53 tests |
| test-reader-vignette-contracts.R | PASS | 23 tests |
| test-comparators-external-oracle.R | PASS | 28 tests |
| tools/check-reader-contracts.R | PASS | |
| capability_ledger.py --check | PASS | 31 generated outputs |
| capability_ledger unittest | **FAIL** | 1 failure: design doc header mismatch (37 vs 38 vignettes) |
| pkgdown::check_pkgdown() | PASS | |
| receipt-pinned files (5) | PASS | No changes |
| vignettes/articles/manifest | PASS | All counts = 38 |
| comparing-with-other-packages.Rmd knit | PASS | All 73 chunks executed |

**Overall**: 7 PASS, 1 FAIL

**Critical Failure**: The design document `docs/design/226-*.md` (or similar) line 1 must be updated to say "across 38 vignettes" instead of "across 37 vignettes".
