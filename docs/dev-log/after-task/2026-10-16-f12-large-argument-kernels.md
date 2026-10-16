# 2026-10-16: large-argument kernels (lane f12)

Reader: a package contributor who reviews `src/` changes, and an applied user whose Student-t, Gamma or Beta fit sits at large `nu`, small CV or large `phi`.

## Task goal

Remove the `eps * x log(x)` rounding from three response log-densities, so the compiled objective agrees with the exact density to 1e-12 per observation from 1e2 to 1e8, and sweep the rest of `src/drm_response_kernels.h` for the same pattern. Stacked on #1504, whose Student kernel it replaces.

## What changed

- `drm_student_log_density()`: `D(nu) = lgamma((nu+1)/2) - lgamma(nu/2) - log(nu/2)/2` is the exact difference below `nu = 100` and the series `-1/(4nu) + 1/(24nu^3) - 1/(20nu^5) + 17/(112nu^7) - 31/(36nu^9)` from 100 (residual 7.8e-22, checked in mpmath). The kernel factor uses `drm_log1p_pos(z^2/nu)`. #1504's switch at `nu = 1e4` left a direct lgamma difference with about 1e-11 error just below it.
- `drm_gamma_log_density()` (new): `log(s)/2 - log(2 pi)/2 - B(s) - s (e^w - 1 - w) - log y`, `s = 1/sigma^2`, `w = log y - eta`, `B` the Stirling remainder. Used by the `mi()` leaf and the main loop.
- `drm_beta_log_density()` (new): log-beta through three Stirling remainders; `u = y p / a - 1` formed with an exact product error (Dekker 1971) because `a u eps` is otherwise the surviving error. Used by the `mi()` leaf, the main loop and the zero-one-inflated block.
- bivariate Student: `drm_log1p_nonnegative` replaced by `drm_log1p_pos` (the old helper is plain `log(1 + x)` above 1e-5).
- `src/drm_numeric.h`: `drm_expm1_minus_x`, `drm_x_minus_log1p`, `drm_log1p_pos`, `drm_stirling_remainder`, `drm_two_prod_err`. TMB 1.9.10's CppAD has no `log1p` or `expm1` for AD types, so these are built from series, `logspace_add` and `exp`.

## Not changed, and why

- Beta-binomial: now covered here too (tracking issue #1548 asks for every copy). `drm_beta_binomial_log_density` and its helpers are byte-identical to #1514's, so the two PRs merge cleanly in either order; this PR also swaps the `mi()` leaf, the main loop and the two `mi()` beta-binomial prior copies (`src/drmTMB.cpp` about 1801 and 1825) that #1514 left. Measured against the exact `sum log(alpha + j)` it is within 1.1e-13 at phi 1e2 to 1e8; the 1e-12 ship test is in `test-large-argument-kernels.R`.
- NB2 (`src/drm_count_kernels.h`): per the C++ TMB reviewer, no code change. `log1p` is correct, but the `lgamma(y + 1/alpha) - lgamma(1/alpha)` branch (used when `alpha y >= 1e-2`) has the same pattern: 2.1e-9 at size 1e6 with mean 2e4 and 4.7e-8 at size 1e8 with mean 2e6. The series branch is 1.9e-12 at size 1e4, y = 99. Proposed fix: `drm_lgamma_ratio(1/alpha, y)` from #1514. R's `dnbinom()` is itself 2e-9 off at size 1e8, so NB2 tests must use an exact reference.
- `mi()` priors in `src/drmTMB.cpp` (Beta 1536-1735, beta-binomial 1801-1833, Gamma 2259-2309) and the `log_choose` terms for trials above about 1e5: same pattern, follow-up after #1513 round 5.

## Evidence

Per-observation errors against mpmath at 60 digits are in the PR body. The Beta figure through the model is bounded by one rounding of `plogis(eta)` upstream of the kernel (`phi |u| eps`, 8e-12 at phi = 1e8 for a 4-sd row); the kernel alone, given alpha and beta, is 2.3e-13.

Tests: `tests/testthat/test-large-argument-kernels.R` (Student vs `dt()` and the Gaussian limit, Gamma and Beta vs pinned mpmath values and vs `dgamma()` and `dbeta()`, NB2 at `alpha y < 1e-2`, AD gradient and Hessian either side of every branch switch).

## Open

- `summary()` on a false-convergence fit prints the bare convergence code with no "not converged" wording and no warning (`print()` and the fit-time warning do flag it). Left for the Issue writer to file; not changed here.
- The C17 model-15 receipt is recertified after the `src/drmTMB.cpp` hunks (see the commit that carries `tools/recertify-c17.py` output).
