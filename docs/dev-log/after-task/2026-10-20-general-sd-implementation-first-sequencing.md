# After Task: General SD implementation-first sequencing

## 1. Goal

Stage implementation and light correctness checks before formal confidence-
interval coverage validation, while retaining calibrated uncertainty in the
full completion target.

## 2. Implemented

The programme marks the NotebookLM synthesis complete on 2026-10-20. The first
delivery now includes Bernoulli fitting on both engines, targeted numerical
and constant-SD checks, a small independent synthetic recovery smoke, public
outputs, and documentation. Formal coverage calibration follows the
implementation breadth. The active Codex task title also names this sequence.

## 3a. Decisions and Rejected Alternatives

The user chose implementation first and formal confidence-interval coverage
later. Calibration now follows the implementation waves and remains part of
the full completion requirement. The smoke is limited to catching coding or
gross-recovery errors; it does not measure nominal 95% interval coverage.

## 4. Files Touched

- `LOOP/lanes/general-sd-regression/ultra-plan.md`
- `LOOP/lanes/general-sd-regression/ultra-plan.assessment.json`
- `docs/dev-log/check-log.d/2026-10-20-general-sd-implementation-first-sequencing.md`
- `docs/dev-log/check-log.d/2026-10-20-general-sd-implementation-first-sequencing.assessment.json`
- This after-task report.
- Its exact-draft assessment record.

## 5. Checks Run

- Scoped `git diff --check` on the plan, check-log, and report: passed.
- `slop_check.py` on all three files: zero findings.
- Native TMB command `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression")'`: 12/12 assertions passed in 5.3 seconds. It fits one synthetic 36-tip by 30-observation design and checks SD-slope recovery, scale prediction, and constant-SD equivalence.
- Julia command `JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project -e 'include("test/test_binomial_sd_formula_design.jl")'`: 5/5 assertions passed in 4.1 seconds. It checks factor and interaction coding plus rejection of a within-group-varying predictor; it does not fit a model.
- The three exact-draft assessment checks passed. The after-task structure check
  passed; its full check exits nonzero while the programme ledger has unmet gates.
- The status-inventory search recorded in the matching check-log fragment found
  that the Bernoulli vignette already says its examples do not establish
  interval coverage.
- No model code or tests changed. A full-tree
  `git diff --check` reported a pre-existing blank line at EOF in
  `tests/testthat/test-binomial-sd-integration.R`; that file was left untouched.

## 6. Tests of the Tests

No tests were added or modified. The native test checks the predictor-dependent
phylogenetic SD, constant-SD reduction, and predicted scale on one seeded data
set; it cannot estimate repeated-sample recovery or interval coverage. The
Julia test exercises the formula-design helper and malformed-input path, not
model fitting or inference.

## 7a. Issue Ledger

No issue was changed. The open-issue search returned #682 on profile-interval
methods and #59 on the simulation framework; neither tracks this
programme-sequencing decision, so both were left unchanged.

## 8. Consistency Audit

The plan retains calibrated uncertainty as the full-program finish requirement
and makes it a later phase. It points to the completed methods synthesis. The
user-facing Bernoulli vignette already marks interval coverage as unvalidated.
The new Julia check is fit-free, so it adds no live-engine parity evidence. The
unlazy ledger still requires calibrated intervals in G2; its active lease
prevents this lane from editing it, so the acceptance ledger and plan remain
inconsistent pending owner reconciliation.

## 9. What Did Not Go Smoothly

The goal record has no in-place objective-edit control. The plan file and task
title now record the user-approved sequencing change. The active G2 ledger lease
also prevents updating that acceptance file in this turn.

## 10. Known Residuals

The 1-2 week Bernoulli milestone and 4-8 month full implementation estimate are
provisional. They need re-estimation after the live capability inventory and
existing work are reconciled. No coverage claim is supported by this planning
change.

## 11. Team Learning

Separate feature implementation and basic recovery checks from repeated-sample
interval calibration, and keep the latter visible as an outstanding finish gate.

## 12. Cross-Product Coverage

This checkpoint covers programme sequencing, one native Bernoulli phylogenetic fit/recovery smoke, and one fit-free Julia formula-design check. The checkpoint does NOT cover live Julia fitting, cross-engine parity, interval calibration, or the remaining family/effect/backend rows. The general SD-regression goal remains active.
