# Refresh the existing main-source receipt

## 1. Goal
Repair the stale evidence detected by the main guard while finishing the convergence documentation deployment.

## 2. Implemented
Regenerated the existing lss-tip-identity receipt on main aa33f1e9 using its unchanged runner, Julia 1.13.0 and the original pinned DRModels.jl checkout. No product source or checker changed.

## 3a. Decisions and Rejected Alternatives
Run the live native, bridge and direct fits rather than editing source hashes. Preserve the original receipt in git history and the task scratch records. Keep the documentation deployment already in progress.

## 4. Files Touched
The existing public-001.json receipt and these check-log and after-task fragments.

## 5. Checks Run
All eight live checks passed in 77.215 seconds on 72 rows and 12 labels. The receipt checker passed --current --self-test. The full staleness script verified 57 R/ and 95 backend source entries. PR CI and the subsequent main guard remain pending at commit time.

## 6. Tests of the Tests
All 12 self-test faults were rejected. The previous receipt and new receipt use identical data and labels. Every fitted coefficient and log likelihood matches exactly across native, bridge and direct fits. Only R/julia-bridge.R changed in the source manifest.

## 7a. Issue Ledger
The failure predates #1596: main guard runs 39330248969 and 39347992927 report the same mismatch. Bridge changes in #1586 and #1587 made the earlier receipt stale. This evidence-only repair supports the already authorized documentation closeout.

## 8. Consistency Audit
No formula, likelihood, default, optimizer, backend or numerical tolerance changed. The receipt retains its original scope. The separate convergence-table artifact was built successfully and its publishing job is queued. Current GitHub runs and recorded source hashes are the evidence; no memory-derived claim is needed. Golden Set is outside this repair.

## 9. What Did Not Go Smoothly
The main guard failed after the documentation merge because the receipt was already stale on the base. Source-only documentation CI does not establish receipt freshness, which the dedicated main guard checks separately.

## 10. Known Residuals
This fixture covers one labeled phylogenetic Gaussian location-scale workflow. PR CI, main validation and final publication are pending and must be read back before closeout.

## 11. Team Learning
A receipt mismatch requires a live rerun with its pinned backend. A documentation merge can expose a pre-existing red main guard without causing it.

## 12. Cross-Product Coverage
This refresh covers the existing label, covariance, likelihood, coefficient, row-order and convergence checks for that workflow. It does NOT cover other backend models, Ayumi's data, release validation or a general calibration campaign.
