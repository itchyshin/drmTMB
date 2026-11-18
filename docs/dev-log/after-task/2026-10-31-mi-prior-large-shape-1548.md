# 2026-10-31: stable Beta, zero-one Beta and Gamma mi() priors, and the R beta-binomial pmf (#1548)

Reader: a package contributor reviewing `src/` and `R/` numerics, and a user whose `mi()` predictor model is `beta_family()`, `zero_one_beta()` or `Gamma(link = "log")` with a very small sigma.

## Goal

Finish #1548. #1547 replaced the cancelling `lgamma()` forms in the Student, Gamma, Beta and beta-binomial response kernels and in the beta-binomial `mi()` prior. It left the Beta and Gamma `mi()` priors (row 13 of the #1548 swept list) for after #1513, which has since merged. This task swaps those copies for the stable kernels and fixes two R-side siblings found in the sweep.

## Implemented

- `src/drmTMB.cpp`, `mi_family == 4` (Beta prior): the observed-predictor term and both quadrature copies now call `drm_beta_log_density(x, alpha_i, beta_i)`.
- `src/drmTMB.cpp`, `mi_family == 10` (zero-one Beta prior): the same three interior copies now call `log_one_minus_zoi_mi + drm_beta_log_density(...)`. The 0 and 1 atoms are unchanged.
- `src/drmTMB.cpp`, `mi_family == 7` (Gamma prior): the observed-predictor term calls `drm_gamma_log_density(x_i, mi_eta(i), log_sigma_gamma_mi)`. Only the body of `drm_gamma_mi_log_integrand()` changes: it now uses the Stirling-remainder form `log(s)/2 - log(2 pi)/2 - B(s) - s (e^w - 1 - w) - u`, with `w = u - log(shape * scale)`. The Newton score and Hessian are unchanged because the prior derivative `shape - x / scale` is the same.
- `R/family-dpq.R`: new internal `drm_lgamma_ratio(x, m)`, the R twin of the C++ helper (direct difference below `x = 100`, differenced Stirling series above). `drm_beta_binomial_dpmf()`, which backs the `beta_binomial()` d/p/q closure (quantile residuals), uses it.
- `R/missing-data.R`: `drm_beta_binomial_missing_predictor_log_density()` uses it too. Its raw `phi` stays in the `trials` ratio, as before, so values are unchanged unless the 1e-8 shape floor is active.

## Files Changed

`src/drmTMB.cpp`, `R/family-dpq.R`, `R/missing-data.R`, `tests/testthat/test-large-argument-kernels.R`, `NEWS.md`, this report.

## Checks Run

- Red first: the new `mi()` tests on the unchanged `main` source failed 18 expectations. The Gamma prior was off by 8.6e-11, 1.4e-8 and 6.0e-7 (sum of eight rows) at shape 1e4, 1e6 and 1e8. The Beta prior was off by up to 3.9e-8 at phi 1e6. The ordinary-shape test passed on `main`.
- The old R beta-binomial form against the exact `sum log(a + j)` reference: worst row error 1.6e-11, 1.6e-9, 3.5e-7, 1.6e-5 and 4.7e-3 at phi 1e4, 1e6, 1e8, 1e10 and 1e12.
- Green: `test-large-argument-kernels.R` passes on this Mac (R 4.6, `devtools::load_all()`), with no failures, including the new `mi()` prior, missing-predictor integrand, ordinary-shape, R beta-binomial and switch-point gradient tests.
- Full suite on Totoro (one `Rscript` per file, 32 workers, `NOT_CRAN=true`, installed package): 520 files, 55,304 expectations, 3 failed, 1 error, 110 skipped. The failures are in `test-071-four-fixture-summary.R`, `test-phase18-structured-workflow-registry.R` and `test-profile-parallel.R`; `origin/main` (`b535bfbcc`, this branch's base), installed on the same machine, fails the same three tests with the same counts: two need a git checkout ("cannot resolve HEAD" in a tarball tree) and one is the parallel-cluster bootstrap comparison at lines 179-180. None reaches a changed density.

## Tests Of The Tests

The `mi()` tests reuse the mpmath references pinned for #1547's response kernels, because the priors evaluate the same densities with the same `beta_mi_eps` nudge. The tests went red on the old code by 10 to 10^5 times their bars, and the ordinary-shape test was green both before and after.

## Consistency Audit

`rg "lgamma" src R` after the change. The remaining hits are the Poisson `lgamma(x + 1)` normalisers, the `log_choose` terms, the NB2 branch in `drm_count_kernels.h`, and kernels already fixed in #1547.

## What Did Not Go Smoothly

The full serial suite on the loaded Mac would have taken hours. It ran on Totoro instead. The first upload failed to compile because macOS `tar` added `._*` resource files; `COPYFILE_DISABLE=1 tar --no-xattrs` fixed it.

## Team Learning

When a tracking issue lists "main-loop copies", also grep `R/` for the same expression: R-side mirrors of compiled densities can carry the same cancellation.

## Design-Doc Updates

None. The likelihood is mathematically unchanged; only its floating-point evaluation changes.

## pkgdown / Documentation Updates

NEWS bullet under Bug fixes.

## GitHub Issue Maintenance

The PR closes #1548. Not changed here, as #1548 and #1547 recorded: NB2 (row 12; the issue says test only) and `log_choose` for trials above about 1e5 (row 14).

## Known Limitations

- The Beta `mi()` quadrature still uses fixed nodes on (0, 1), so at large phi the missing-predictor marginal is limited by node placement (#1476, PR #1529), not by the density. The tests here cover the observed-predictor rows and the adaptive Gamma integrand only.
- `drm_gamma_mi_log_integrand()` forms the prior mean as `shape * scale`, which carries one rounding (relative eps). That is a 1e-16 perturbation of the model, not cancellation.

## Next Actions

Owner decision on NB2 and `log_choose` (see PR body).
