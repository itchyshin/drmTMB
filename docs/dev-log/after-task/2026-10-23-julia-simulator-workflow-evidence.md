# After Task: Julia SD simulator workflow evidence

## 1. Goal

Bind focused Julia marginal-simulation and bootstrap workflow checks for Tweedie and ZeroOneBeta to their exact required capability rows. Preserve the full candidate universe and make no interval-calibration claim.

## 2. Implemented

Added two unreviewed workflow receipts. Each test passed 10/10 assertions. Both compare a seeded marginal response draw with an independently reconstructed draw and complete one bootstrap refit. The source manifest records the paired Julia candidate HEAD, all `src/*.jl` and project hashes, test snapshots, and stable before/after hashes across the rerun.

## 3a. Decisions and Rejected Alternatives

The tests were rerun after capturing source hashes so the manifest could bind the exact tested state. Only evidence artifacts in the native candidate were written; the paired Julia source and tests were not edited. The live `src/inference.jl` lease remains with its current owner pending coordination.

Assumptions made without asking: the paired Julia candidate remained the relevant engine checkout for these user-authorized workflow checks. A different intended candidate requires a new run and receipt.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-sim-integrity-20261023/`
- `docs/dev-log/check-log.d/2026-10-23-julia-simulator-workflow-evidence.md`
- `docs/dev-log/after-task/2026-10-23-julia-simulator-workflow-evidence.md`
- `docs/dev-log/after-task/2026-10-23-julia-simulator-workflow-evidence.assessment.json`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

No source or test code was changed in either repository.

## 5. Checks Run

- Julia 1.10.0 Tweedie simulator test: **10/10 passed in 35.5 seconds**.
- Julia 1.10.0 ZeroOneBeta simulator test: **10/10 passed in 14.6 seconds**.
- Combined process elapsed time: **56.6 seconds**. Hashes for all 93 Julia source, project, and test inputs remained stable before and after both runs.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: **PASS**, 19,118 candidate rows, 25 receipt records, 23 linked rows, and 19,095 unlinked rows.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: **11/11 passed**.
- The after-task structural check passed, but the full project check remains nonzero because the overall programme ledger has unmet gates.

## 6. Tests of the Tests

Both tests independently reconstruct the latent group effect and family-specific response draw using the same random seed, then compare the result with the simulator output. They check response bounds, reproducibility, fit convergence, and one successful bootstrap refit. The bootstrap count is one, so this tests workflow execution and target retention, not interval coverage or uncertainty calibration.

## 7a. Issue Ledger

No issue was created or changed. No implementation gap was closed by these receipts.

## 8. Consistency Audit

The receipts link to the Julia Tweedie and ZeroOneBeta ordinary mean-intercept rows. The source manifest binds the in-repository test snapshots to candidate HEAD `70dbf564eb670144c63c08f61ea099084d95add2`. The evidence summary still treats rows as obligations and does not promote direct support from test receipts. The current live inference-file ownership was left intact.

## 9. What Did Not Go Smoothly

The source file is under a live Julia lane lease, so the broader inference diff could not be edited during these checks. The main after-task check reports the expected programme-level unmet gates even though the evidence receipt and structural report checks pass.

## 10. Known Residuals

The receipts remain unreviewed and cover two Julia workflow rows only. They do not prove native TMB parity, additional effect types, calibrated intervals, or support across the 19,118-row universe. The shared inference file remains under an active owner lease pending coordination.

## 11. Team Learning

Hash the candidate source tree before and after short simulator runs when another lane owns the code. This catches concurrent changes without interrupting safe read-only verification.

Memory receipt: repository instructions and the current acceptance ledger shaped this work. `route.py` did not provide a LOAD-FIRST manifest for this worktree. Golden Set: not checked because no implementation bug was changed.

## 12. Cross-Product Coverage

Covers: Julia Tweedie and ZeroOneBeta mean-intercept marginal simulation and one bootstrap-refit workflow for the tested candidate routes.

does NOT cover: native TMB parity, random slopes, structured effects, other endpoints, broad distribution-family support, interval calibration, or programme completion.
