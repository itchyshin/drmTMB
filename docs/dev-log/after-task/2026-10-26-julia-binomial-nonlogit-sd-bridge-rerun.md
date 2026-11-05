# After-task: Current-source Binomial bridge rerun

## 1. Goal

Revalidate the ordinary Binomial random-intercept SD bridge checks for probit and complementary log-log links and make their live-test count reliable.

## 2. Implemented

The focused test now uses `drm_skip_live_julia()`, the shared opt-in guard and counter for live R-to-Julia tests. On the current candidate, the test passed 27 expectations and reported one live test block. That block performed two same-data TMB/Julia fits, one per link. The candidate ledger now points to these current-source receipts. Two earlier records with unavailable historical test bytes and mismatched current hashes were moved verbatim to a deferred archive.

## 3a. Decisions and Rejected Alternatives

I reran the existing ordinary q1 cases and left `R/julia-bridge.R` unchanged. This repairs the evidence and its test counter; it does not admit the still-blocked probit/cloglog phylogenetic route.

## 3. Model contract

For each link, the synthetic data use 144 groups, 25 observations per group, and `sd(id) ~ w` with a true log-SD slope of 0.45. The test compares TMB and Julia convergence, slope recovery, group-SD ordering, and predicted SD values.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd-links-bridge.R`: use the shared live-Julia test guard.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its generated summary: archive stale records and register current source-bound reruns plus the direct Julia q2 recovery evidence.
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-sd-bridge-20261026/`: test snapshots, source manifest, logs, and per-row receipts.
- `docs/dev-log/general-sd-regression/deferred/2026-10-26-superseded-direct-sd-receipts.tsv`: verbatim archive of the two superseded records.
- `docs/dev-log/check-log.md` and this report.

## 5. Checks Run

On the Mac Studio with R 4.6.0, Julia 1.10.0, and one Julia and BLAS thread, the focused filter passed 27 expectations. The live-test summary reported one live bridge test block, which exercised two fits. A 177-file R/TMB and Julia source manifest matched before and after the run. The general-SD evidence reconciler passed with 19,118 candidate rows, 86 records, 67 linked rows, and 19,051 unlinked rows. Linked-row counts are evidence counts, not completion percentages or support admissions.

## 6. Tests of the Tests

The first run produced passing assertions but the test summary said zero live tests because the test used `skip_if_not()` and bypassed the shared counter. After switching to `drm_skip_live_julia()`, the live test summary correctly reported one block. The exact run log and source hashes are retained under `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-sd-bridge-20261026/`.

## 7a. Issue Ledger

No external issue or pull request was created or changed. The two superseded ledger rows are preserved verbatim with a note explaining why they left the active reconciled table.

## 8. Consistency Audit

The R bridge implementation and Julia fitting source were not changed in this slice. The current test checks the same predictor-dependent SD model in TMB and Julia for both links. The receipts remain unreviewed and bound only the tested ordinary q1 cases.

## 9. What Did Not Go Smoothly

The first test command used `status`, a read-only zsh variable, for its exit code, so the wrapper ended without recording a code. Its test log is preserved as a diagnostic. The instrumented rerun used `rc`, wrote exit code 0, and is the authoritative test receipt.

## 10. Known Residuals

This evidence does NOT establish interval coverage, structured probit/cloglog bridge support, other Bernoulli random-effect types, or the broader response-family matrix. The ledger remains mostly unlinked, and linked rows remain unreviewed evidence.

## 11. Team Learning

Live bridge tests should use the shared test guard so opt-in fits appear in the bridge-run summary. A green assertion log alone can hide that a test never entered the engine.

## 12. Cross-Product Coverage

Covers: current-candidate TMB/Julia point-recovery and predicted-SD checks for an ordinary Binomial mean random intercept with a fixed-predictor SD slope, under probit and cloglog links.

Does NOT cover: structured non-logit bridge admission, interval calibration, correlated-block bridge parity, other response families, or goal completion.

## 13. Prose Assessment

The separate exact-draft assessment is recorded in `2026-10-26-julia-binomial-nonlogit-sd-bridge-rerun.assessment.json`.
