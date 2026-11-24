# Check log — 2026-11-22 — merge main into the converged-rule branch

Reader: the next package contributor picking up draft PR #1781.

## Change

Merged `origin/main` (`a8c034388`, the #1810 identity-link guard in `drm_impute_family_type()`) into `claude/converged-rule-drm-20261118` with a merge commit. The merge had no conflicts. Main's three files (`R/missing-data.R`, `tests/testthat/test-fix-1749-impute-gaussian-link.R`, `docs/dev-log/check-log.d/2026-11-21-fix-1749-impute-gaussian-link.md`) came in unchanged.

`convergence_status()` already cuts on the stored fit gradient. `drmTMB()` stores `obj$gr(opt$par)` on `fit$gradient` (`R/drmTMB.R`). `drm_newton_step_se()` (`R/check.R`) computes `max_i |(H^-1 g)_i| / SE_i` from that vector and `sdr$cov.fixed`, and `drm_convergence_info()` returns `not_converged` when the step is above `1e-3` or non-finite. That is the 19 Nov CONV-GRADIENT-CUT. The exported help still described the abandoned relative-gradient test, so `R/check.R` and `man/convergence_status.Rd` now name the Newton step. No test expectation, ledger value, or receipt digit moved.

## Verification

R 4.6.2, TMB 1.9.25, testthat 3.3.2, `NOT_CRAN=true`. `testthat::test_dir()` filter `converg|temporal-review-fixes|phylo-temporal-ou-methods`, package `drmTMB` installed from this tree:

- 209 passed, 0 failed, 0 errors, 0 warnings, 2 skipped.
- Skips are the two live Julia tests in `test-julia-convergence-status-parity.R` (`DRModels.jl` engine not available). The R-side bridge test in that file passed. CI's R-CMD-check lane also has no Julia.

Files covered: `test-convergence-status-twin.R`, `test-temporal-review-fixes.R`, `test-phylo-temporal-ou-methods.R`, `test-fit-convergence-warning.R`, `test-julia-convergence-status-parity.R`, `test-optimizer-false-convergence-restart.R`, `test-optimizer-false-convergence-restart-gates.R`, `test-summary-nonconverged.R`.

```sh
python3 tools/capability_ledger.py --check
python3 tools/capability_ledger.py --check-c14-receipt-equivalence
python3 tools/qseries_v1_release_ledger.py --check
```

All three exited 0. C14 receipt equivalence reported `OK (3 eligible, 7 source-different retained receipts; C17 current-source compatibility PASS)`. mc-0568 receipt digits were not rewritten.
