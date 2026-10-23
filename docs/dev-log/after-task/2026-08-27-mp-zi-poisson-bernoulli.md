# After-task — `mp-zi-poisson-bernoulli`

**Date.** 2026-08-27
**Lane.** `cursor/lane-s6-zi-mi` @ `~/local-scratch/lanes/drmTMB-s6-zi-mi`
**Decision.** drmSEM D-23 / G0 option (b)

## What shipped

- C++ `has_mi` for `model_type == 8` inlines the ZIP mixture in the
  2-point sum. Does **not** call `drm_response_log_density` / Poisson
  leaf. `eta_zi` is observed-only.
- R: lift the blanket Poisson+zi refuse; keep `mi()` on `zi` and
  incomplete `zi` symbols refused. `split_tmb_parameters` returns
  `mi_*`. Finalize uses the ZIP mixture, not `dpois`.
- Tests: `test-missing-predictor-zi-poisson-response.R` **20 pass /
  0 fail**. Poisson-response boundary still **13 pass**.
- Ledger: `mp-zi-poisson-bernoulli` / `ev-mp-zi-poisson-bernoulli-g3`.

## Honest leftovers

Not FIML. Not `impute_joint`. Not k ≥ 2. Not `mi()` on `zi`.
Not `zi_nbinom2`. Not student. Capability stays **partial**.
Did not touch nbinom2-gaussian or student worktrees.
