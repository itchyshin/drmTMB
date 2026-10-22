# After Task: Fit-free plot data validator tests

## 1. Goal

Characterise the input validators and data helpers used by `plot_corpairs()` and
`plot_parameter_surface()` without fitting a model or drawing a plot.

## 2. Implemented

The PR adds 124 expectations in one test file. The tests call internal helpers
with hand-built data frames and check both valid inputs and rejection paths.
The test file is unchanged by this closeout. A prior review corrected one test
title to match its actual assertions; it did not change an assertion or the
test-file hash.

## 3a. Decisions and Rejected Alternatives

No statistical model, likelihood, parameterisation, or public behaviour is
changed. The tests describe data-validation and plot-data helper behaviour only.

## 4. Files Touched

This closeout updates this report and the per-slice check-log record. The PR
adds the test file, which is unchanged by this closeout. The current PR head
(`7294ed7fa3dead693a8f03de3e21b6dbadec3bf8`) was rebased locally onto current
`main` (`f9bff01b5f3bbbc424402b73d67084dd446d9ff8`). Focused test results below
are from that local combined tree; they are not remote exact-head CI evidence.
The remote branch remains at the PR head until the refreshed branch is pushed.

## 5. Checks Run

On the local rebased tree at `245bb04cabc1fa16948c07e5dab3355e775aa6f3`,
`Rscript -e 'devtools::test(filter="plot-data-validators", reporter="summary")'`
completed with 124 expectations and no failures, warnings, or skips.
`Rscript -e 'devtools::test(filter="env-skip-census", reporter="summary")'`
completed with five expectations and no failures. These runs are local combined
tree evidence, not remote exact-head CI. `git diff --check` passed. I manually
checked the after-task sections against the repository protocol; no automated
report-structure checker is present in this clone. The prose check found no
issues. The full test suite, `R CMD check`, and live Julia engine were not run.

## 6. Tests of the Tests

The tests cover malformed inputs and boundary cases. Results from the local
combined tree are behaviour-characterisation evidence, not parameter-recovery
or model-validation evidence. They do not establish remote exact-head CI.

## 7a. Issue Ledger

No matching open issue was found for the plot-data validator tests. No issue
comment, issue creation, or issue closure was needed.

## 8. Consistency Audit

No production code, NEWS, package metadata, or skip-census entry changed. The
per-slice `.d` record and this report describe the same local combined source
and test results. The conflicting root `docs/dev-log/check-log.md` append was
removed; the `.d` record is retained as the per-slice evidence. No model or
documentation claim needs a status-inventory update.

## 9. What Did Not Go Smoothly

The closeout initially appended to the high-collision root check log. Rebasing
onto current main exposed the conflict; the root append was removed and its
per-slice `.d` record retained. The earlier local test snapshot used an older
main commit, so the focused tests are rerun on the current local combined tree.

## 10. Known Residuals

The `*_mapping()` helpers remain covered by existing plot tests. The focused
tests do not validate rendered plots, fitted-model behaviour, or the live
Julia bridge. The PR remains a test-only contribution. Full suite, `R CMD
check`, and remote PR branch synchronization remain open.

## 11. Team Learning

Keep closeout evidence in the per-slice `.d` record. Avoid appending to the
high-collision root chronological log when the repository's generated `.d`
records already provide the required history.

## 12. Cross-Product Coverage

This test-only task does NOT cover a model engine, R-to-Julia bridge behaviour,
rendered plot appearance, package-wide testing, or documentation-site output.
No Julia changes were made, and the live Julia engine was not exercised. No
design doc, NEWS, pkgdown page, or public API changed.
