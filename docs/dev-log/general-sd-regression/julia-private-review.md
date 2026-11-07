# Private Julia binomial SD-regression review

**Disposition:** private-module checkpoint passes. This review covers only `src/binomial_sd_regression.jl` and `test/test_binomial_sd_regression.jl` in the Julia worktree at `b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`. The module is not wired into shared `src/binomial.jl` or `src/DRModels.jl`; it therefore makes no public fit, prediction, bridge, or calibration claim.

## Independent verification

Before running the focused test, estimated approximately 60 seconds. Ran under a 90-second subprocess timeout with `JULIA_NUM_THREADS=2`, `OPENBLAS_NUM_THREADS=1`, and the existing project `/private/tmp/drmodels-sd-test.PtcJOP`:

```sh
julia --compiled-modules=no --project=/private/tmp/drmodels-sd-test.PtcJOP test/test_binomial_sd_regression.jl
```

Exit status was 0; runtime was about 48 seconds, including startup. The retained log reports 25/25 passing assertions: 12 for q1 fit/reduction, 4 for Bernoulli versus one-trial binomial, 4 for the independent fixed-parameter integral and quadrature-node stability, and 5 for explicit refusal cases. Log: `/private/tmp/drmtmb-general-sd-julia-reverified.log`.

SHA-256 at review time:

- `src/binomial_sd_regression.jl`: `1c2ad3433ec97fedbc3abc8a4bd47571e2be8363070c00bbd1b2d8d32f2621c2`
- `test/test_binomial_sd_regression.jl`: `72c076de6cbf61553f9fdaac4171b50f11570239ee0cdfbe3b67a9f16b3f508a`
- test log: `0888e869afc66b6bd6531d958e60f12890fcc6b09f09fc3f1668dcd480b5180c`

## Scientific and implementation review

The module implements a clear private target: logit-binomial observations with one ordinary scalar group intercept, `b_g ~ Normal(0, exp(2 Z_g alpha))`, where the SD design is compressed to one row per group. The existing `_sd_group_design` checks within-group constancy. The likelihood includes the binomial combinatorial term and integrates each group with the existing one-dimensional adaptive Gauss–Hermite routine. The independent `QuadGK` test integrates the same group likelihood against a standard-normal latent variable at fixed coefficients; the constant-SD test compares likelihood and coefficients against the existing binomial random-intercept route. The Bernoulli test checks equality with the one-trial binomial representation.

Input refusals are explicit for a mismatched grouping variable, random slopes, within-group-varying SD predictors, a nonconstant residual sigma formula, and a non-`:LA` marginal selector. The source also refuses structured inputs and phylogenetic SD terms. The module does not silently route those requests to a different likelihood.

## Exact boundary

This green result validates the private q1 helper and its focused source tests only. It does not establish that the user-facing Julia dispatcher calls this code, that the Julia public formula/parser/bridge preserves the intended request, or that prediction, extraction, intervals, simulation, save/reload, or documentation work end to end. The fit-recovery check uses one synthetic fixture and a loose coefficient-difference assertion; it is not a recovery campaign, uncertainty calibration, or general optimizer-health assessment. Shared Julia dispatcher changes remain a separate integration and review task.
