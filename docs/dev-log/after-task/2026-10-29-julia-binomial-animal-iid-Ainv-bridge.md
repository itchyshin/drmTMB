# After Task: Julia Binomial Animal Ainv plus IID Bridge

## 1. Goal

Connect the existing Julia Binomial animal-plus-IID test to the candidate row for an animal covariance supplied through pedigree precision `Ainv`.

## 2. Implemented

No model or test source changed. The existing synthetic logit test fits animal plus IID SD regressions using both supplied covariance `A` and the equivalent precision `Ainv`, in TMB and Julia. The live run passed one Julia bridge test without failures or skips. Assertions include a dense joint-Laplace oracle, equivalence of `A` and `Ainv`, coefficient and likelihood comparisons, SD predictions, simulator component structure, and deterministic marginal simulation.

## 3a. Decisions and Rejected Alternatives

I linked this as `focused_test` evidence for one exact Julia `Ainv` provider-pair row. The existing covariance-form recovery record does not substitute for evidence on precision-input marshalling. This result is candidate-only and does not establish interval coverage.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-iid-Ainv-bridge-20261029/`: exact test snapshot, console, source manifest, and receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its reconciled summary: one exact Julia `Ainv` provider-pair row linked as unreviewed focused-test evidence.
- This report, its check-log entry, and the lane checkpoint.

Candidate heads: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

## 5. Checks Run

- The opt-in test passed with one live Julia bridge test and no failures or skips. Julia 1.10.0 used one Julia thread and one BLAS/OMP thread.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 20,350 candidate rows, 211 linked rows, 20,139 unlinked rows, and 238 evidence records. The new row remains unreviewed; no support status changed.

## 6. Tests of the Tests

The dense oracle computes the joint Laplace likelihood from the supplied covariance. The test also checks that using `Ainv = solve(A)` produces equivalent parameters, likelihood, predictions, and simulation behavior in both engines. This is one synthetic design.

## 7a. Issue Ledger

No issue search was performed for this evidence-only slice.

## 8. Consistency Audit

The test snapshot, receipt, and row key specify a logit Binomial animal-plus-IID model. The `Ainv` route is directly exercised, while the covariance route is separately recorded. Neither result promotes public capability status; the documentation and capability audit lane remains separate.

## 9. What Did Not Go Smoothly

The first test invocation skipped because `skip_on_cran()` was triggered with `NOT_CRAN` unset. I reran it with `NOT_CRAN=true`; the live Julia bridge then ran and passed.

## 10. Known Residuals

This does not establish probit or cloglog for the same provider pair, other structured-plus-IID pairs, broad recovery, or calibrated uncertainty. The full Bernoulli provider ledger remains incomplete.

## 11. Team Learning

A clean test exit is not sufficient when the bridge summary reports zero live tests. Read the bridge summary and confirm that the intended engine actually ran before recording a result.

## 12. Cross-Product Coverage

**Covers:** one Julia and TMB logit Binomial animal-plus-IID model with animal precision supplied through `Ainv`, including an equivalent `A` comparison and dense Laplace oracle. **does NOT cover:** other links, other provider pairs, other families, broad parity, calibrated uncertainty, or interval coverage.

Memory receipt: I preserved source-bound candidate evidence and the narrow scope claim from the general-SD memory entry. `route.py` found no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this slice is outside registered repeated-mistake classes.

## Writing Assessment

**Style:** 2/10, medium confidence; the report gives the route and evidence limits directly. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** test and source receipts are named; no repair needed. **Gates:** science = pass for focused route evidence; facts = pass against the saved console, source snapshot, manifest, and reconciliation; references = not applicable. **Provenance:** self-review, draft version 1, 2026-10-29.
