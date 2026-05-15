# After Task: Slice 82 Count Likelihood Kernel Audit

## Goal

Remove avoidable observed-count loops from NB2 likelihood routes without
changing the public family contract, formula grammar, or fitted
parameterization.

## Implemented

- Added shared internal helpers for the NB2 count product, NB2 log density, and
  NB2 zero mass in `src/drmTMB.cpp`.
- Routed ordinary NB2, zero-inflated NB2, zero-truncated NB2, and hurdle NB2
  through the shared helpers.
- Kept `mu = exp(eta_mu)`, `sigma = exp(eta_sigma)`, and
  `alpha = sigma^2`; no user-facing syntax changed.
- Added deterministic high-count objective tests in
  `tests/testthat/test-count-kernels.R`.
- Updated the likelihood design doc, source map, validation-debt register,
  ROADMAP, NEWS, and generated pkgdown pages.

## Mathematical Contract

For NB2 models the internal overdispersion parameter remains

```text
alpha_i = sigma_i^2.
```

The log mass is evaluated as

```text
log f(y_i) =
  y_i eta_mu_i - log Gamma(y_i + 1)
  + C(y_i, alpha_i)
  - y_i log(1 + alpha_i mu_i)
  - log(1 + alpha_i mu_i) / alpha_i,
```

where

```text
C(y_i, alpha_i) =
  sum_{j = 0}^{y_i - 1} log(1 + alpha_i j).
```

The template no longer evaluates that expression with an observed-count loop.
For ordinary count and overdispersion values it uses

```text
C(y_i, alpha_i) =
  log Gamma(y_i + 1 / alpha_i) -
  log Gamma(1 / alpha_i) +
  y_i log(alpha_i).
```

For very small `alpha_i y_i`, it uses a matching power-sum series so the
Poisson limit remains stable. Zero-truncated and hurdle NB2 routes use the same
NB2 zero mass helper for the truncation probability, and zero-inflated NB2 uses
the same density helper inside the mixture.

## Files Changed

- `src/drmTMB.cpp`
- `tests/testthat/test-count-kernels.R`
- `docs/design/03-likelihoods.md`
- `docs/design/34-validation-debt-register.md`
- `vignettes/source-map.Rmd`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format src/drmTMB.cpp tests/testthat/test-count-kernels.R`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "count-kernels|nbinom2|truncated-nbinom2|hurdle-nbinom2|zi-nbinom2", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "count-kernels|poisson|nbinom2|truncated-nbinom2|hurdle-nbinom2|family-link-contract|comparators", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered scans for the new count-kernel helper, count-loop
  wording, and stale observed-count loop claims.

All tests and checks passed. `devtools::check()` passed with 0 errors, 0
warnings, and 0 notes in 2m 22.2s.

## Tests Of The Tests

The new tests compare the optimized TMB objective directly with independent R
calculations based on `stats::dnbinom()` for high-count ordinary NB2,
zero-truncated NB2, hurdle NB2, and zero-inflated NB2. A separate high-count
near-Poisson zero-inflated NB2 test checks that the small-overdispersion branch
matches the corresponding zero-inflated Poisson calculation and remains finite.

## Consistency Audit

The source map now identifies the shared NB2 count-kernel helper for ordinary,
zero-inflated, zero-truncated, and hurdle NB2 rows. The likelihood design doc
matches the implemented helper structure. ROADMAP and NEWS describe this as
internal kernel hardening, not a new family or syntax surface. Stale-wording
scans did not find a remaining C++ observed-count loop for NB2 likelihood
evaluation.

## What Did Not Go Smoothly

The first helper used a parameter-dependent C++ `if (asDouble(alpha) < ...)`
near the Poisson limit. TMB tapes that branch at construction time, so the
near-Poisson high-count zero-inflated NB2 test failed badly. The helper now
uses `CppAD::CondExpLt()` with a small-`alpha y` series branch, and the focused
count tests pass.

## Team Learning

- Ada kept the slice bounded to likelihood-kernel hardening.
- Gauss and Noether insisted that the helper preserve the NB2
  parameterization and the Poisson limit rather than replacing the stable
  product term blindly.
- Curie added deterministic objective-level tests instead of slow stochastic
  simulations.
- Grace ran the full test, pkgdown, and package-check gates.
- Pat kept the public docs framed as implementation evidence, not new syntax.
- Rose recorded the branch-selection mistake so future TMB helper work avoids
  parameter-dependent C++ branching.

## Known Limitations

- This slice does not add a new approximation method or change the optimizer.
- Count-kernel tests are deterministic objective comparisons, not large
  performance benchmarks.
- GitHub Actions remains the PR-side gate after push.

## Next Actions

- Continue to Slice 83: write the C++ modularization source map without moving
  code yet.
- Keep any larger count-family performance benchmark as a separate slice with a
  clear timing protocol.
