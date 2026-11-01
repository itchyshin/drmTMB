# 2026-10-12: restore 15-node Beta and adaptive Gamma GH (#1513)

Reader: Shinichi and the Code Reviewer who blocked the prior-centred
IS rule because it was not an `integrate()` match.

## Task goal

Do the approved #1513 quadrature fix. Restore the old 15-node Beta
rule, including the zero-one-Beta atoms. Make Gamma adaptive with
posterior-mode Gauss-Hermite. Meet checks (a)–(h). Never loosen a
tolerance. Keep #1476 and #1477 open (Refs, not Fixes).

## What changed

`drm_beta_mi_quadrature()` is again the frozen 15-node Gauss-Legendre
table on `(0, 1)`. `drm_zero_one_beta_mi_quadrature()` is
`c(0, beta$nodes, 1)` with weights `c(1, beta$weights, 1)`. The C++
Beta and ZOB missing-x loops score `log(w) + log_density + log_y`
without `log_mass`. Observed-x still does
`nll -= weights(i) * log_density`. Weight 0 on a missing row still
uses `if (asDouble(weights(i)) > 0)`.

Gamma missing-x rows call `drm_gamma_mi_adaptive_quadrature()`. The
integrand is on `u = log(x)`: log Gamma density plus
`drm_response_log_density` plus the `dx/du` Jacobian. Five Newton
steps start at `log(mu)`. The Gaussian path uses an analytic score
and Hessian so `obj$gr()` matches a finite-difference gradient.
CondExp clamps the Newton step and floors `-H`. Nodes are
`mode + z / sqrt(-H)`. The log-sum is unnormalised. A non-finite
marginal calls `error("drmTMB_mi_quadrature_nonfinite: ...")`. The R
helper `drm_gamma_mi_adaptive_nodes()` throws
`drmTMB_mi_quadrature_nonfinite`.

`src/drm_numeric.h` and `src/drm_response_kernels.h` were not edited.
The unweighted Gaussian priors at `src/drmTMB.cpp:1301`, `:1342`, and
`:4556` were not edited. `R/drmTMB.R` and `R/methods.R` were not
edited, so C17 was not recertified. `n_cpp` is 35L.

## Acceptance numbers

Beta mid-range versus `integrate()` (tolerance `2.6e-5`, not loosened):

- `mu = 0.5`, `sigma = 0.5`, `sd_y = 0.1`, `beta_x = 1`: `9.87e-7`
- `mu = 0.10`, `sigma = 0.2`, `sd_y = 0.1`, `beta_x = 1`: `9.10e-6`

U-shaped Beta, `sigma = 1`, leftover above `2.6e-5`:

- `mu = 0.02`, `y = 1`, `sd_y = 0.1`, `beta_x = 2`: `1.638e-2`
- `mu = 0.10`, `y = 1`, `sd_y = 0.1`, `beta_x = 2`: `1.659e-2`

Gamma versus log-x `integrate()`, `y = 7`, `mu_y = 2`, `sd_y = 0.1`,
`beta_x = 0.5`, `mu = 10` (tolerance `1e-4`, not loosened):

- CV 0.05: `3.83e-15`
- CV 0.10: `2.19e-15`
- CV 0.50: `1.55e-15`
- CV 1: `5.77e-15`
- CV 2: `1.33e-15`

Poisson response times Gamma `mi()` on the R helper: `2.87e-13`.
`obj$gr` versus central FD (`h = 1e-5`) at CV 0.05, 1, and 2 is
below `1e-5`. The CV > 1 test passed, so it is not a labelled skip.
The classed abort fires on `drm_abort_mi_quadrature_nonfinite()` and
on `drm_gamma_mi_adaptive_nodes()` with `y = NaN`.

## Checks run

Focused `testthat::test_dir()` after `pkgbuild::compile_dll()`
(R 4.3.3, TMB 1.9.25):
`test-mi-quadrature-1476-1477.R`,
`test-guard-branch-continuity.R` (`n_cpp = 35L`),
`test-missing-predictor-beta.R`,
`test-missing-predictor-gamma.R`,
`test-missing-predictor-zero-one-beta.R`,
`test-mi-weights-1459.R` (including the `y = 1e200` pin),
and `test-dinnage-audit-m1-families.R` all reported 0 failures.

Full `testthat::test_dir()` at `d8d9a41b2`: progress-char parse
PASS 47785, WARN 58, SKIP 122. The reporter listed 9 failures. Two
were the in-PR env-skip census (this rewrite added a second
`skip_on_cran()` and a CV>1 runtime skip site).
`Rscript tools/write-env-skip-census.R` refreshed
`inst/extdata/env-skip-census.tsv`; `test-env-skip-census.R` then
passed. The other seven are this VM: missing `{JuliaCall}` on the
Julia fence/bridge/joint tests, the sparse `crossprod` in
`test-missing-predictor-prediction.R`, and a REML phylo
non-convergence. Live Julia: 0 ran, 69 skipped.

Stale-wording scan:

```sh
rg "logit-normal|lognormal proposal|renormalised to mass 1|31-node logit" NEWS.md docs/design/03-likelihoods.md docs/dev-log/known-limitations.md
rg "meta_gaussian|tau ~|rho ~" NEWS.md docs/design/03-likelihoods.md
```

The only leftover IS sentences sit in older check-log and after-task
entries from 2026-10-11, which describe that earlier slice.

## GitHub issues

#1476 and #1477 stay open. This PR uses Refs, not Fixes. GitHub
`issue_write` returned 403 (`Resource not accessible by personal
access token`), so the U-shaped Beta follow-up that refs #1476 could
not be opened from this run. The measured errors are in the table
above; file that follow-up from a token that can create issues.
No CV > 1 follow-up is needed because that test passed.

## Known limitations

U-shaped Beta on the 15-node rule still mis-integrates the tails.
Do not start adaptive Beta in this PR. A later tanh-map or
two-mode rule should beat `1.64e-2` without moving the mid-range
`2.6e-5` pin.

## Next

Run the full suite, push the tested SHA, and leave #1513 draft.
