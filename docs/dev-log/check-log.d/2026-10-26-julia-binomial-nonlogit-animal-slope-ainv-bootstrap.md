
## Paired Julia workflow check

- Scope: probit and complementary log-log Binomial animal numeric-slope SD fits supplied with `Ainv`; one bootstrap refit per link.
- Command: `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. test/test_binomial_nonlogit_animal_slope_sd_regression.jl` in the paired DRM.jl candidate worktree.
- Result: 40/40 assertions passed in 18.6 seconds, Julia 1.10.0. This checks workflow integrity and does not establish calibration or native parity.
- Evidence: `../../../../general-sd-julia/docs/dev-log/after-task/2026-10-26-julia-binomial-nonlogit-animal-slope-ainv-bootstrap.md`; receipt `julia-binomial-nonlogit-animal-slope-ainv-bootstrap-20261026` is unreviewed.
