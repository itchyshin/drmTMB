# After Task: Heterogeneous AR1 reader and reverify repair

## 1. Goal

Synchronize the public heterogeneous-AR1 interval guidance with the completed P3
implementation and repair a false immutable-artifact failure caused by later,
unrelated phylogenetic-OU source changes.

## 2. Files Changed

- `R/profile.R` and generated `man/confint.drmTMB.Rd` and
  `man/profile_targets.Rd` now state that heterogeneous AR1 supports
  mean-coefficient Wald intervals only.
- `R/parse-formula.R` gives all four admitted temporal structures in the two
  relevant recovery messages.
- `tools/temporal-hetar1-gates.R` verifies the runner copied from the artifact's
  recorded source commit, rather than comparing all current `R/` and `src/`
  changes to that historical commit.
- The native expectation matches the current unavailable-profile message, and a
  new gate-runner test checks source-bound artifact identity.

## 3. Checks Run

- `devtools::document(quiet = TRUE)` regenerated both Rd files.
- `testthat::test_file("tests/testthat/test-temporal-hetar1-gate-runner.R")` passed.
- `testthat::test_file("tests/testthat/test-temporal-hetar1-parser.R")` passed.
- `testthat::test_file("tests/testthat/test-temporal-hetar1-native.R")` passed
  after a fresh debug-library compile.
- `Rscript --vanilla tools/temporal-hetar1-gates.R T4-11 --reverify` returned
  `TEMPORAL_HETAR1_T4_11_PASS` without fitting a model.
- `git diff --check` passed before commit.

## 4. Consistency Audit

`?confint.drmTMB`, `?profile_targets`, the formula parser, the P3 vignette,
`check_drm()`, and the native test now agree: fixed `mu` Wald intervals are
available for a fit with positive-definite full observed information; profiles
and process-SD, persistence, residual-SD, bootstrap, forecast, and `newdata`
intervals remain unavailable. This is interval feasibility, not calibration.

## 5. Tests of the Tests

The gate-runner test reads the pilot's recorded commit and runner checksum,
reconstructs that exact historical runner with `git show`, checks its MD5, then
runs `T4-11 --reverify`. It would fail for a forged provenance checksum or a
missing recorded source, while unrelated later source changes do not invalidate
the historical artifact.

## 6. What Did Not Go Smoothly

The previous gate compared every changed R and C++ file from P3's source commit
to the current branch. The subsequent phylogenetic-OU arc necessarily changed
some shared files, so the P3 artifact reverify failed even though its frozen
runner and outputs matched. The revised check validates provenance at the
recorded source instead.

## 7. Team Learning

An immutable evidence receipt should bind its own source identity. It should not
interpret changes made later for a separate model as a reason to reject the old
receipt.

## 8. Design Documentation

No covariance mathematics or admission boundary changed. This task only
synchronizes the public description of the existing P3 Wald boundary.

## 9. Documentation and pkgdown

Roxygen regenerated the two affected reference pages. No vignette or pkgdown
render changed because the already-rendered P3 vignette was consistent.

## 10. GitHub Issues

`gh issue list --state open --search 'heterogeneous AR1 OR hetar1' --limit 20`
found no matching issue. No issue was opened, edited, or closed.

## 11. Known Limitations and Next Action

P3 retains its interval-feasibility boundary; it makes no coverage or
standard-error-calibration claim. After this commit, rerun `T4-14 --reverify`
from the clean tree. The P1 phylogeny-plus-independent-OU owner lane remains
separate and retains its failed G13 coverage evidence.
