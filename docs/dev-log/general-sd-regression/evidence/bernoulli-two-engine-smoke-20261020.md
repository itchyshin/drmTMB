# Bernoulli SD regression checks, 20 October 2026

This note records focused local checks of the predictor-dependent random-effect SD route for Bernoulli outcomes in the Julia and native R/TMB engines. These are implementation and point-recovery checks. They do not assess repeated-sampling interval coverage.

## Julia

Command:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --startup-file=no test/test_binomial_sd_regression.jl
```

Result: exit code 0; all 105 assertions passed. The tests exercised correlated intercept-and-slope SD regressions, an independent 2-D integration oracle, constant-SD likelihood reduction, coefficient-specific targets, prediction, simulation, and one-refit bootstrap smoke checks. The test run completed in about 85 seconds on the local Mac with one Julia thread.

The separate public-entry-point check also passed:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --startup-file=no test/test_binomial_sd_public.jl
```

Result: exit code 0; 42 of 42 assertions passed in 44.4 seconds. This check covers the public `drm()` route, formula bridge, response-scale and link-scale SD predictions, profile and bootstrap wrapper smoke checks, save/reload, and a one-target random-slope route. The profile and bootstrap checks verify that those APIs run; they do not assess interval coverage.

## Native R/TMB

Command:

```sh
Rscript --vanilla -e 'devtools::test(filter = "binomial-sd-integration", reporter = "summary")'
```

Result: exit code 0 with no reported failures. The filter selected both `binomial-sd-integration` and `beta-binomial-sd-integration`, so this run was broader than the intended Bernoulli-only check. The final reporter stated that no live Julia bridge tests ran in this configuration.

## Scope and limits

The Julia suite provides a fixed-seed point-recovery example and independent likelihood check. The R/TMB run provides focused integration and output checks for the selected files. Neither run establishes interval calibration or general parity across all response families, random-effect types, or providers. No source code was changed during these checks.
