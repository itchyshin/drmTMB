# After Task: Bernoulli Timing Capsule

## 1. Goal

Add a source-pinned, timing-only route to the 97.5% Bernoulli profile harness so a fresh 45-row design can be prepared, run with bounded workers, and summarized without presenting timing results as calibration.

## 2. Implemented

`prepare-0975.R` now accepts only the exact clean 45-row timing manifest in timing mode. The Python supervisor rejects subsets, pins the timing seed, profile level, and worker limits, and writes `calibration_claim=false` in its receipt. The worker verifies the full manifest and planned index set. The summary script retains every planned attempt and reports runtime and fit-health counts only. The model contract remains `y ~ x + (1 | id)` with `sd(id) ~ w`; `w` predicts the log standard deviation of the latent intercept. This adds no estimator or inferential claim. Timing results are not recovery, bias, false-positive-rate, or interval-coverage evidence.

## 3a. Decisions and Rejected Alternatives

The separate source-bound Totoro timing report already records 45 completed fits and a runtime projection. I did not repeat those fits. The new mode remains available for future timing runs whose source or design differs materially from that retained receipt.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration/prepare-0975.R`
- `tools/general-sd-regression/native-calibration/run-0975.py`
- `tools/general-sd-regression/native-calibration/worker-0975.R`
- `tools/general-sd-regression/native-calibration/summarize-timing-0975.R`
- `tools/general-sd-regression/native-calibration/test-timing-0975.py`
- `tools/general-sd-regression/native-calibration/test-summarize-timing-0975.R`

## 5. Checks Run

- `python3 tools/general-sd-regression/native-calibration/test-timing-0975.py`: 4 tests passed.
- `python3 -m py_compile tools/general-sd-regression/native-calibration/run-0975.py`: passed.
- R parsing of `prepare-0975.R` and `worker-0975.R`: passed.
- `Rscript tools/general-sd-regression/native-calibration/test-clean-manifests.R`: passed.
- `Rscript tools/general-sd-regression/native-calibration/test-summarize-timing-0975.R`: passed, including malformed-hash and missing-profile cases.
- No model fits were launched in this task.

The separate source-bound Totoro timing report at `docs/dev-log/after-task/2026-10-19-bernoulli-timing-pre-run.md` records 45 completed timing fits and a 98 to 127 minute projection for its 9,000-row stage-two stream. Those fits are timing evidence only and were not repeated here.

## 6. Tests of the Tests

The runner test was observed red before implementation and green afterward. It rejects changed seeds, wrong modes, missing or reordered rows, subsets, and worker counts above the cap. The summary fixture retains all 45 attempts when results are incomplete and fails after a pinned result is altered.

## 7a. Issue Ledger

The read-only open-issue search for “Bernoulli timing 97.5 random effect SD” returned no matches. No issue was opened, changed, or closed.

## 8. Consistency Audit

No model formula, estimator, public API, family admission, example, vignette, or pkgdown page changed. The separate Totoro timing record was read and treated as non-calibration evidence. The shared `docs/dev-log/check-log.md` has an earlier sentence saying a timing run is still needed, followed by a later entry documenting its completion. I left that dirty shared file untouched pending ownership reconciliation; this checkpoint is recorded in `docs/dev-log/check-log.d/2026-10-19-bernoulli-timing-capsule.md`.

## 9. What Did Not Go Smoothly

The preparer initially named a different summary-script path than the actual file. Integration review found and corrected the registry entry and its test before any run. The existing Totoro timing report also appeared during this work, so the proposed local timing run was cancelled to avoid duplicating fit work.

## 10. Known Residuals

This task does not complete Bernoulli recovery or uncertainty calibration, Julia parity, other response families, or the programme gates. The general-SD goal remains active. NotebookLM authentication and methods review also remain unverified.

## 11. Team Learning

Before launching any timing run, reconcile active worktrees and existing timing receipts. A different seed manifest does not justify repeating a timing run unless it answers a source or design question the retained receipt cannot answer.

## 12. Cross-Product Coverage

This closes only the native timing-runner tooling slice. It does NOT cover the corrected 97.5% first-look decision gate, Bernoulli recovery or uncertainty calibration, Julia parity, family breadth, or programme gates G0-G8. The next step is to reconcile the corrected first-look decision gate and lane ownership, then continue from the frozen acceptance ledger. Do not reuse timing fits as inferential evidence.
