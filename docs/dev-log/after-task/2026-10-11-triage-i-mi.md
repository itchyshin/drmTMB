# 2026-10-11: mi() quadrature and weights policy

Reader: an applied user who imputes a missing continuous or proportion
predictor, and Shinichi deciding whether case weights should multiply the
`mi()` prior.

## Task goal

Keep the missing-x marginal likelihood accurate for Gamma and Beta
predictor models, and pin the current unweighted continuous `mi()` prior
until #1459 is decided. `engine = "julia"` must not silently ignore
weights on an `mi()` model.

## What changed

Gamma `mi()` no longer integrates `t^{k-1} e^{-t}` on a frozen 20-node
Gauss-Laguerre grid. Nodes are 31 standard-normal Gauss-Hermite abscissae
placed by a lognormal proposal with the same mean and CV as the Gamma.
`log(1 + CV^2)` uses `drm_log1p_nonnegative()` from #1504. Each node is
reweighted by the Gamma density and the prior mass is renormalised to 1.

Beta and zero-one-Beta interior nodes use the same 31-node grid on the
logit scale, matched to the Beta mean and variance. Zero and one stay
exact atoms. The interior mass is renormalised to 1.

The continuous Gaussian `mi()` prior is still `nll -= dnorm(...)` with no
`weights(i)`. A classed warning records that. Weight 0 on a missing
covariate is a named error. Weight 0 on an observed-x row contributes 0
to the response (`drm_weight_times_logdens`) and still contributes the
unweighted prior. `engine = "julia"` plus `mi()` plus non-unit weights is
a classed refusal before Julia starts. `predict()` and `simulate()` refuse
an explicit `weights` argument on an `mi()` fit; they otherwise use the
fitted coefficients.

`src/drm_numeric.h` and `src/drm_response_kernels.h` were not edited.

## Files

- `src/drmTMB.cpp`
- `R/mi-weights.R`, `R/missing-data.R`, `R/julia-joint-call.R`,
  `R/julia-joint-missing.R`, `R/methods.R`
- `tests/testthat/helper-mi-quadrature-reference.R`,
  `test-mi-quadrature-1476-1477.R`, `test-mi-weights-1459.R`,
  `test-julia-mi-weights.R`, and the Gamma / Beta / zero-one-Beta /
  guard-branch manuals
- `docs/design/03-likelihoods.md`, `NEWS.md`, this report

R reviewer acceptance is pinned: `weights = 1` matches the
unweighted fit; weight 2 matches a duplicated row in the response only
(`nll` gap = one unweighted prior copy); weight 0 or `NA` on a missing
`mi()` covariate is `drmTMB_mi_zero_weight_missing`, not a drop;
`predict()` / `simulate()` honour fitted coefficients and refuse
`weights=`.

## Left

Full local `testthat` suite and C17 (`R/drmTMB.R` and `R/methods.R`
changed). Draft PR must land after #1504. Do not merge.

Refs #1477
Refs #1476
Refs #1459
