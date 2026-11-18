# After Task: Current-Source Julia Binomial Correlated q3 Logit

## 1. Goal

Verify the current candidate's Julia bridge for a correlated q3 Binomial logit SD model and link the result to its three random-coefficient targets.

## 2. Implemented

No model source changed. The existing independent synthetic fixture with 160 groups and 32 observations per group passed through native TMB and Julia. The test checks convergence, all three SD slopes against truth, cross-engine coefficient and correlation agreement, group-specific SD predictions, and marginal binary simulation. The result is linked to the Julia logit q3 intercept and two slope rows as unreviewed recovery evidence.

## 3a. Decisions and Rejected Alternatives

The earlier attempt to add logit to the smaller q3 probit test exceeded its four-minute estimate before producing a fit result. I stopped it and reverted that test edit, verifying the original test hash. I then ran the existing dedicated high-information q3 logit fixture against the current source. Its 7:56 completion is evidence for this source pin only.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-logit-current-20261029/`: exact test snapshot, console, source manifest, and receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and reconciled summary: linked three exact Julia logit q3 target rows as unreviewed recovery evidence.
- This report, its check-log entry, and the lane checkpoint.

The test file was not changed. Candidate heads: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

## 5. Checks Run

- The focused test passed one live Julia bridge test with no failures or skips in 7 minutes 56 seconds. Julia 1.10.0 used one Julia thread and one BLAS/OMP thread.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 20,350 candidate rows, 214 linked rows, 20,136 unlinked rows, and 241 evidence records. The three new rows remain unreviewed; no support status changed.

## 6. Tests of the Tests

The fixture uses an independent correlated-normal construction with three coefficient-specific SD regressions and predeclared truth values. It checks all three slopes against truth, compares TMB and Julia coefficients and correlations, compares group SD predictions, and simulates binary responses. One fixture does not establish low-information stability.

## 7a. Issue Ledger

No issue search was performed for this evidence-only slice.

## 8. Consistency Audit

The test snapshot, source manifest, receipt, and three row keys identify one ordinary correlated q3 Binomial logit model with intercept, x1 slope, and x2 slope SD targets. The run used current candidate files; the October 26 bridge-source hash differs. Evidence remains candidate-only; public capability wording remains with the separate audit lane.

## 9. What Did Not Go Smoothly

The smaller q3 test exceeded its first runtime estimate. I interrupted it, discarded its non-result, and restored the exact source hash. A dedicated high-information fixture then completed successfully in 7:56.

## 10. Known Residuals

This is one high-information logit design. It does not establish low-information stability, probit or cloglog q3 bridge recovery, interval calibration, or broad Bernoulli coverage. The full required-row ledger remains incomplete.

## 11. Team Learning

For correlated q3 discrete models, prefer an existing high-information fixture with explicit slope-recovery checks over enlarging a weak small-group fixture during a live run.

## 12. Cross-Product Coverage

**Covers:** current-source R-to-Julia and TMB fitting, recovery, SD prediction, correlation output, and marginal simulation for one q3 correlated Binomial logit model. **does NOT cover:** low-information stability, other q3 links, other providers, other families, calibrated uncertainty, or interval coverage.

Memory receipt: I kept the evidence scoped to the candidate source hash and preserved the distinction between a focused recovery test and calibrated uncertainty. `route.py` found no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this slice is outside registered repeated-mistake classes.

## Writing Assessment

**Style:** 2/10, medium confidence; the report distinguishes the stopped run from the completed run and names the tested scope. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** the saved current-source console and reverted source hash are recorded; no repair needed. **Gates:** science = pass for the focused recovery claim; facts = pass against the log, source snapshot, manifest, and reconciled ledger; references = not applicable. **Provenance:** self-review, draft version 1, 2026-10-29.
