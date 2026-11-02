# After Task: Julia Binomial Animal Pedigree plus IID Bridge

## 1. Goal

Add a direct synthetic bridge test for a Binomial model that combines an animal intercept built from pedigree input with an independent IID site intercept, each with its own SD regression.

## 2. Implemented

Added a logit fixture with crossed animal and site observations and fixed predictors that vary between their respective groups. The test confirms the Julia route admits the formula, marshals the pedigree into the expected labelled covariance, fits in native TMB and Julia, preserves separate SD target labels, agrees on likelihood and group-specific SD predictions, and simulates marginal binary outcomes. No model source changed.

## 3a. Decisions and Rejected Alternatives

The result is `focused_test` evidence for one candidate row. The fixture uses one link and one synthetic design. I did not claim broad provider-pair coverage or interval calibration.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-iid-nonlogit-sd-bridge.R`: added the pedigree plus IID logit fixture and bridge assertions.
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-pedigree-iid-bridge-20261029/`: retained the exact test snapshot, console, source manifest, and receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its reconciled summary: linked one exact Julia logit provider-pair row as unreviewed focused-test evidence.
- This report, its check-log entry, and the lane checkpoint.

Candidate heads: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

## 5. Checks Run

- The focused opt-in test file passed with two live Julia bridge tests, no failures or skips, and shell exit code 0. Julia 1.10.0 used one Julia thread and one BLAS/OMP thread.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 20,350 candidate rows, 210 linked rows, 20,140 unlinked rows, and 237 evidence records. The new row remains unreviewed; no status promotion occurred.

## 6. Tests of the Tests

The DGP constructs related animal effects from the pedigree-derived covariance and independent site effects from separate normal draws. The test asserts exact covariance payload ordering and checks both SD targets independently. It also verifies convergence, cross-engine likelihood and prediction agreement, and valid simulated binary outcomes.

## 7a. Issue Ledger

No issue search was performed for this bounded test slice.

## 8. Consistency Audit

The formula, DGP, test snapshot, receipt, and exact ledger row identify a logit Binomial provider pair with one pedigree animal intercept and one IID site intercept. This is candidate evidence only. Public support wording remains with the documentation and capability audit lane.

## 9. What Did Not Go Smoothly

The lane preflight flagged many unrelated active repository lanes. Its exact-file scan found no competing ref touching this test, and the required narrow lease was granted before the edit. I released the lease after recording and checking the result.

## 10. Known Residuals

This does not establish probit or cloglog support for the same provider pair, other structured plus IID combinations, all animal input representations, broad recovery, or interval coverage. The full Bernoulli provider ledger remains incomplete.

## 11. Team Learning

The existing A-based animal plus IID test did not prove that the pedigree form works when combined with an IID term. A small direct bridge fixture closes that specific input-combination gap without changing model code.

## 12. Cross-Product Coverage

**Covers:** one Julia and TMB logit Binomial model with a pedigree animal intercept plus an independent IID site intercept and separate SD predictors. **does NOT cover:** other links, random slopes, other structured-provider pairs, other response families, calibrated uncertainty, or interval coverage.

Memory receipt: I preserved the source-bound candidate evidence and narrow capability claim from the general-SD memory entry. `route.py` found no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this slice is outside registered repeated-mistake classes.

## Writing Assessment

**Style:** 2/10, medium confidence; the report names the model, input pairing, checks, and limits concretely. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** the exact snapshot and console are recorded; no repair needed. **Gates:** science = pass for this focused test claim; facts = pass against test output, source manifest, and evidence reconciliation; references = not applicable. **Provenance:** self-review, draft version 1, 2026-10-29.
