# 2026-10-22: Julia ZeroOneBeta SD marginal simulation integrity

The paired Julia candidate's marginal simulator now uses the freshly sampled random effect when calculating the ZeroOneBeta Beta-component mean. The focused synthetic test passed 10/10 checks, including an independent seeded draw oracle and one successful bootstrap refit. The neighboring ZeroOneBeta recovery, intercept-SD, and slope-SD tests passed 29/29 additional checks. This is one candidate workflow fix, not broad ZeroOneBeta parity or interval calibration.

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 /Users/z3437171/.juliaup/bin/julia --project=. test/test_zeroonebeta_sd_simulation_integrity.jl
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 /Users/z3437171/.juliaup/bin/julia --project=. -e 'for f in ["test/test_zeroonebeta.jl", "test/test_zeroonebeta_sd_regression.jl", "test/test_zeroonebeta_sd_slope.jl", "test/test_zeroonebeta_sd_simulation_integrity.jl"]; include(f); end'
```

Both commands ran in `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia` on branch `codex/general-sd-regression` at base `70dbf564e`, with pre-existing dirty candidate changes. The report is `docs/dev-log/after-task/2026-10-22-zeroonebeta-sd-marginal-simulation.md`.
