# After Task: Julia Binomial Correlated q2 Bridge Across Links

## 1. Goal

Extend the existing ordinary correlated q2 Julia bridge recovery test to cover logit alongside probit and cloglog, then preserve the focused result in the source-bound evidence ledger.

## 2. Implemented

The live R-to-Julia bridge test now fits the correlated intercept-and-slope Binomial SD model under logit, probit, and cloglog. The run passed one live JuliaCall test with 50 expectations and no failures or skips. No model implementation changed.

## 3a. Decisions and Rejected Alternatives

The evidence grade is `focused_test`. This test does not replace the earlier seeded recovery receipts for probit and cloglog. It supplies live bridge evidence for all three links, including the previously missing logit random-slope target. No interval calibration was attempted.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-nonlogit-correlated-sd-bridge.R`: included logit in the fitted-link loop and generalized the test title.
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q2-all-links-bridge-20261029/`: retained the exact test snapshot, console, source manifest, and receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its reconciled summary: linked one exact logit q2 random-slope row as unreviewed focused-test evidence.
- This report, its check-log entry, and the lane checkpoint.

Candidate heads: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

## 5. Checks Run

- The opt-in focused test ran with Julia 1.10.0, one Julia thread, and one BLAS/OMP thread. The saved console ends with one live bridge test and `Julia exit`; the shell command exited 0.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 20,350 candidate rows, 209 linked rows, 20,141 unlinked rows, and 236 evidence records. The new evidence is unreviewed; no support status changed.

## 6. Tests of the Tests

The fixture checks both coefficient-specific SD targets, correlated-block fitting, convergence, broad signed point-recovery bounds, correlation estimates, TMB comparison, and group-level SD prediction agreement. The synthetic covariance construction uses correlated latent normals. This is one fixed-seed design per link.

## 7a. Issue Ledger

No issue search was performed for this test-only extension.

## 8. Consistency Audit

The formula, test, receipt, and exact required-row key describe a q2 ordinary correlated Binomial intercept-and-slope block. Candidate evidence is not public support approval. The documentation and capability audit remains separate.

## 9. What Did Not Go Smoothly

The first receipt reconciliation found that the source manifest named the active test path while the evidence row named its immutable snapshot. I updated the manifest to name the snapshot and reran reconciliation successfully.

## 10. Known Residuals

This result does not establish calibration or interval coverage, all correlated-block dimensions, all Bernoulli providers, save/reload, profile or bootstrap workflows, or broad Julia parity. Fifty required Julia Bernoulli rows remain unlinked in the current candidate ledger.

## 11. Team Learning

Evidence manifests must identify the exact immutable test snapshot referenced by the evidence row. The reconciliation script caught and localized this mismatch before closeout.

## 12. Cross-Product Coverage

**Covers:** one ordinary correlated q2 Binomial intercept-and-slope SD regression through the R-to-Julia bridge under logit, probit, and cloglog, with TMB comparison. **does NOT cover:** other block dimensions, structured providers, other response families, broad engine parity, calibrated uncertainty, or interval coverage.

Memory receipt: I preserved source-bound candidate evidence and narrow support claims from the general-SD memory entry. `route.py` found no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this slice is outside registered repeated-mistake classes.

## Writing Assessment

**Style:** 2/10, medium confidence; the report states the tested scope and limits directly. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** the exact source snapshot and reconciliation result are named; no repair needed. **Gates:** science = pass for the focused-test claim; facts = pass against the saved console, source manifest, and reconciliation output; references = not applicable. **Provenance:** self-review, draft version 1, 2026-10-29.
