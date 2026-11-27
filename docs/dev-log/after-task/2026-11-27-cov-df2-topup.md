# After-task: Cov df2 topup (27 Nov 2026)

Pass 2 for `R/[d-f]*.R` coverage targets `R/drmTMB.R`, `R/family.R`, and `R/family-dpq.R`, complementing draft PR #1905 on `cursor/1127cov-drmTMB-df`.

## Delivered

- `tests/testthat/test-cov-1127-df2-topup.R` — seven `test_that()` blocks covering drmTMB entry gates (Julia/temporal/penalty/biv_student weights), `drm_eval_family_arg()` when `family` resolves to `base::beta`, internal start-override validators, `drm_recycle_scalar_arg()`, and tweedie DPQ power validation.

## Evidence

- `docs/dev-log/check-log.d/2026-11-27-cov-df2-topup.md`
- Local: `testthat::test_file("tests/testthat/test-cov-1127-df2-topup.R")` (20 expectations).

## PR

- Branch `cursor/1127cov-drmTMB-df2`, draft PR with **refs coverage** claim `cursor-cloud-1127cov` (text only).