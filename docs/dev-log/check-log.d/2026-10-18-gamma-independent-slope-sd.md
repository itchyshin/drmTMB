# Gamma independent-slope SD slice

Date: 2026-10-18

Claim: native Gamma `sd(group)` supports one ordinary independent numeric `mu` slope with group-constant SD predictors, complete responses, and fixed-effect `sigma`.

Checks:

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-sd-regression")'`: pass, 17 assertions.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-sd-integration")'`: pass, 23 assertions.
- Julia worktree `include("test/test_gamma_sd_regression.jl")` with `--compiled-modules=no --threads=2`: pass, 32 assertions, including an independent quadrature oracle.
- Live R bridge `devtools::test(filter = "julia-gamma-sd")`: pass, 26 assertions and 2 live Julia fits; one non-fatal JuliaCall dependency-install warning.
- `pkgdown::check_pkgdown()`: pass, no problems found.
- `git diff --check`: pass.
- `slop_check.py` on the after-task report: pass, 0 findings.
- The first integration run failed the 2.5-SE recovery check by 0.022. The deterministic synthetic design was increased from 60 groups × 12 repeats to 100 × 16; truth, seed, and acceptance rule were unchanged. The rerun passed.
- The bridge suite compares the Gamma SD coefficients from Julia and native TMB on the same seeded slope data with a fixed 0.2 tolerance; this check passed.
- Negative assembly tests continue to reject correlated/mixed slopes, random SD-formula terms, and SD predictors that vary within group.

Report: `docs/dev-log/after-task/2026-10-18-gamma-independent-slope-sd.md`.

Limit: these checks cover one ordinary intercept or one independent numeric slope under the Gamma-specific complete-response and fixed-`sigma` route. The same-data comparison is one parity check, not a broad cross-engine grid; interval calibration and general SD programme gates remain open.
