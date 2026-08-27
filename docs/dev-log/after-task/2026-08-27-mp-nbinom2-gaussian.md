# After Task: `mp-nbinom2-gaussian` (nbinom2 × Gaussian × k=1)

**Lane.** `cursor/lane-s6-nbinom2-gaussian` at
`~/local-scratch/lanes/drmTMB-s6-nbinom2-gaussian`, from `origin/main`
`4c34c9bbc` (after #1094). Family-gate worktree left untouched.

**What landed.** C++ `has_mi && mi_family == 0` inside `model_type == 7`
(FE-only; no group/struct). R lifts the nbinom2 binary-only abort for
`gaussian()` only; still refuses Poisson predictors, k=2, and grouped
impute. Tests: joint logLik identity, MCAR, MAR, fail-loud.
Ledger row `mp-nbinom2-gaussian` (G3 `point_fit_recovery`).

**Not this slice.** FIML; `impute_joint`; k=2; Poisson/binomial/beta ×
Gaussian; drmSEM consumer lift (sibling `cursor/lane-s6-a7-consumer`
holds `R/imputation.R`). Capability stays `partial` on the SEM side
until that consumer lands.

**Tests.** `test-missing-predictor-nbinom2-gaussian.R` 19 pass / 0 fail;
Bernoulli nbinom2-response 8 pass; missing-data-control 15 pass.
