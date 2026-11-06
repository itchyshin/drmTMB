# After Task: Julia cumulative-logit SD evidence

## 1. Goal

Record a hash-bound focused test result for predictor-dependent random-effect SDs in Julia cumulative-logit models. Link the ordinary q1 random-intercept and independent numeric-slope rows without changing model code or promoting these rows to general support.

## 2. Implemented

Added two unreviewed focused-test receipts against the exact Julia cumulative-logit intercept and slope capability rows. The rerun passed 39 assertions: 14 for the intercept route and 25 for the slope route. The receipt stores a byte-identical test snapshot, the Julia candidate HEAD, hashes for all Julia `src/*.jl` files and the project file, and the console summary. The evidence summary was regenerated from the 19,118-row inventory.

## 3a. Decisions and Rejected Alternatives

The existing Julia test was rerun and snapshotted because the evidence reconciler requires source files inside the native candidate root. The test and model sources in the paired Julia worktree were not edited. This receipt carries focused-test status. Calibration and broad support claims require separate evidence.

Assumptions made without asking: the paired Julia candidate worktree remained the intended test target, as established by the active goal's paired-engine workflow. A different intended candidate would require a new run and receipt.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-cumlogit-sd-20261023/`
- `docs/dev-log/check-log.d/2026-10-23-julia-cumlogit-sd-evidence.md`
- `docs/dev-log/after-task/2026-10-23-julia-cumulative-logit-sd-evidence.md`
- `docs/dev-log/after-task/2026-10-23-julia-cumulative-logit-sd-evidence.assessment.json`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

No Julia source or test file was changed. The byte-identical test snapshot is an evidence artifact.

## 5. Checks Run

- In the paired Julia candidate at HEAD `70dbf564eb670144c63c08f61ea099084d95add2`, Julia 1.10.0: `JULIA_DEPOT_PATH=/tmp/drmTMB-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project test/test_cumlogit_sd_regression.jl`: **39/39 passed in 51.4 seconds**. Intercept: 14/14. Slope: 25/25.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: **PASS**, 19,118 candidate rows, 23 receipt records, 22 linked rows, 19,096 unlinked rows.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: **11/11 passed**.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R <absolute report path>`: structural check passed; overall exit was nonzero because the programme acceptance ledger still has 12 unmet gates. This subtask receipt does not close them.
- `git diff --check` equivalent whitespace scan over all files created or changed for this receipt: passed.

## 6. Tests of the Tests

The intercept and slope tests check positive recovery direction, finite fitted likelihood, public SD extraction and prediction, simulation, and equivalence to the corresponding constant-SD fit. The slope test also compares the fitted likelihood with an independent numerical integration oracle and exercises one bootstrap refit. Malformed-input assertions check rejection of unsupported or inconsistent specifications. No deliberate mutant was introduced, so this does not establish mutation-test sensitivity.

## 7a. Issue Ledger

No issue was created or edited. This evidence-only change does not resolve implementation gaps.

## 8. Consistency Audit

The two row keys match the frozen Julia cumulative-logit q1 iid-intercept and independent numeric-slope rows. The source manifest binds the test snapshot hash and records all Julia source hashes. The evidence summary continues to state that receipts do not prove general support, identifiability, or calibrated coverage. The broader inventory and user-facing formula documentation were not changed.

## 9. What Did Not Go Smoothly

The first lease command used an unsupported option, and the initial lease attempt could not write the shared registry under the sandbox. A corrected command under the approved elevated tool path obtained the lease before repository edits. The central closeout wrapper resolves the brain repository as its root, so its combined gate could not validate this candidate report. The direct structural after-task checker passes the report below; the candidate-specific evidence reconciler is run separately.

## 10. Known Residuals

Both receipts remain unreviewed and apply only to the tested Julia cumulative-logit routes. They do not establish native TMB parity, structured effects, other response families, other endpoints, broad public-method consistency, or interval coverage. The full programme remains open. A separate native-slice review identified NB2 sigma-endpoint SD regression as a likely gap, but ownership of shared builder and likelihood files must be resolved before implementation.

## 11. Team Learning

For paired-engine test evidence, snapshot the executed test inside the evidence repository and bind it to the candidate HEAD plus source hashes. Keep the test result separate from support and calibration decisions.

Memory receipt: used the repository instructions and current goal ledger. `route.py` did not provide a LOAD-FIRST manifest for this worktree. Golden Set: not checked because this task records test evidence and does not change a known implementation bug.

## 12. Cross-Product Coverage

Covers: Julia cumulative-logit mean endpoint, ordinary q1 random intercept, and independent numeric random slope for the focused test workflows.

does NOT cover: native TMB parity, structured or correlated effects, other families or endpoints, full required-row support, interval-coverage calibration, or programme completion.
