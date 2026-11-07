# 2026-10-27: native Gamma relatedness coefficient SDs

Native Gamma now fits separate SD formulas for the independent intercept and slope fields of one unlabelled `relmat(1 + x | id, K = K)` model, with K/Q equivalence. Corrected coefficient-specific conditional extraction also repairs the existing Gamma animal q2 predictor mismatch (pre-fix max link-scale error 1.341697 in the recorded probe).

Final focused command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter="gamma-relmat-q2-sd-regression|gamma-relmat-sd-regression|gamma-animal-slope-sd-regression|gamma-sd-regression|gamma-sigma-sd-regression", reporter="summary", stop_on_failure=TRUE)'`. Five files passed 108 expectations, zero failures/errors/warnings/skips, 44.864 seconds. The new file contributes 42 checks. Its independent dense Gamma Laplace oracle solves the latent mode independently. K/Q, formula ordering, constant SD, prediction and extraction, unused nodes and conditional simulation are covered. One older animal test assertion was updated to the current actionable coefficient-selector refusal.

Example `inst/examples/gamma-relmat-q2-sd.R` ran and converged. Read-only review found no remaining P0/P1 issue within the bounded patch. Receipt: `docs/dev-log/general-sd-regression/evidence/native-gamma-relmat-q2-sd-20261027/receipt.json`. Report: `docs/dev-log/after-task/2026-10-27-native-gamma-relmat-q2-sd.md`.

Public status-map synchronization and Julia parity remain with their separate lanes. No aggregate evidence-row admission, interval coverage, full package check, pkgdown build, commit, push or merge is claimed. Existing mixed worktree edits are preserved.
