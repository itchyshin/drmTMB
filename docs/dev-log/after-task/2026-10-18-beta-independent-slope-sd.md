# After Task: Beta ordinary random-slope SD regression

## 1. Goal

Add a scoped direct-SD route for complete-data Beta models, covering one ordinary location intercept or one independent numeric location slope in native TMB and Julia.

## 2. Implemented

The native builder admits a coefficient-selected SD target for one independent numeric `(0 + x | group)` location slope. The Julia fitter accepts `sd(group, coef(x)) ~ predictor`, checks target identity and finite numeric loadings, then applies the row-level slope loading inside its groupwise adaptive quadrature likelihood. Existing intercept support remains. The shared tested subset uses complete responses and fixed `sigma ~ 1`.

For group `g` and row `i`, the model is `b_g = tau_g u_g`, `u_g ~ Normal(0, 1)`, `log(tau_g) = w_g' alpha`, and `eta_i = x_i' beta + r_i b_g`, where `r_i` is 1 for an intercept or the observed numeric slope value for a slope. The Beta mean and precision links are unchanged. The new SD describes the random coefficient; its row contribution is multiplied by `r_i`.

## 3a. Decisions and Rejected Alternatives

The common claim is restricted to `sigma ~ 1`, although the native builder admits a broader fixed-sigma design. Julia currently requires `sigma ~ 1`, so claiming the wider native boundary as cross-engine parity would be inaccurate. Correlated and structured routes remain separate work because this slice changes neither their covariance construction nor their extraction paths.

Assumption: one ordinary intercept or one independent numeric slope is a useful bounded next family slice. If the intended slice must include correlated or structured Beta effects, those need separate likelihood and validation work.

## 4. Files Touched

Native worktree: `R/drmTMB.R`, `tests/testthat/test-beta-sd-regression.R`, `tests/testthat/test-beta-sd-slope-integration.R`, `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/check-log.d/2026-10-18-beta-independent-slope-sd.md`, and this report. Julia worktree: `src/beta.jl`, `test/test_beta_sd_regression.jl`, `docs/src/capabilities.md`, `docs/src/families.md`, `news/beta-sd-regression.md`, and `docs/dev-log/check-log.d/2026-10-18-julia-beta-sd-regression.md`.

## 5. Checks Run

The anchored native command `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^beta-sd-(regression|integration|slope-integration)$", reporter = "summary")'` passed all three selected Beta SD test files. The Julia focused suite passed 41 assertions. A temporary same-data comparison converged in both engines; the maximum absolute SD-coefficient difference was `0.0008974259`, and the maximum absolute predicted group-SD difference was `0.0004349469`. `pkgdown::check_pkgdown()` and `git diff --check` passed. The report structure check passed. The command-line validator then started a repo-wide acceptance-ledger reverification, which I stopped after about 90 seconds without a verdict. `pkgdown::build_site()` stopped when the homepage attempted to reach `cloud.r-project.org`; network DNS was unavailable and the process also could not write to the user-level R cache.

## 6. Tests of the Tests

The native test-first run failed at the previous intercept-only target guard. The assembly test then checked selector identity, SD design rows, and row-to-group mapping. The recovery test uses a fixed synthetic DGP with a varying slope loading and group SD predictor; a constant-SD comparison checks reduction to the existing slope model. Julia's slope test also compares its likelihood with an independent standard-normal quadrature calculation. The engine comparison uses separate implementations but only one fixture.

## 7a. Issue Ledger

Read-only GitHub search for open `Beta SD` issues found no match for this ordinary intercept/slope slice. Issue #1284 concerns structured `relmat()` Beta support and is separate. No issue was opened, edited, commented on, or closed.

## 8. Consistency Audit

The formula grammar, family registry, vignette, and known-limitations page now describe the tested Beta intercept/slope boundary and keep it separate from the phylogenetic direct-SD evidence. The Julia capability table and family page add the numeric-slope selector and scope. `_pkgdown.yml` needs no navigation change. The package site configuration passes; rendered pages remain unverified because the site build could not resolve the CRAN host.

The status inventory search was `rg -n -i 'beta.{0,80}(sd|slope)|sd.{0,80}beta' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md vignettes/formula-grammar.Rmd _pkgdown.yml`. It found no README or pkgdown navigation claim to change; the roadmap wording referred to the separate Beta phylogenetic route and was preserved. The exact search output and locations are in the session check record.

## 9. What Did Not Go Smoothly

The first recovery design had too few groups and within-group observations to estimate the SD slope reliably, so the synthetic design was enlarged. A broad filter selected an unrelated zero-one Beta test and was interrupted. The later anchored command ran only the three intended files and passed. A direct `testthat::test_file()` call did not load the package and therefore did not provide valid evidence; the package-aware `devtools::test()` command did. The site builder stopped after a network request failed and the user-level R cache could not be written.

## 10. Known Residuals

The native slope test lacks its own independent marginal-likelihood oracle and direct slope simulation check. The Julia bootstrap check uses one refit and checks successful routing/accounting rather than the simulated slope variance. This work does not establish interval calibration. The cross-engine claim is limited to complete responses, one ordinary intercept or one independent numeric slope, and fixed `sigma ~ 1`. Correlated blocks, structured effects, multiple simultaneous targets, nonconstant sigma parity, other marginal routes, full package suites, and rendered documentation remain open.

## 11. Team Learning

An SD formula describes the latent coefficient scale. For a random slope, the row-level covariate must multiply that coefficient inside the integrated likelihood. Recovery and engine agreement are useful checks, but an independent likelihood oracle and slope-specific marginal simulation check would strengthen the native evidence.

## 12. Cross-Product Coverage

Covers: native TMB and Julia fitting for the stated Beta intercept/slope subset; native target assembly and recovery; Julia independent quadrature and coefficient-SD prediction; and one matched-data fit comparison.

Does NOT cover: calibrated uncertainty, validated interval coverage, a native independent likelihood oracle, a slope-specific marginal simulation check, correlated or structured Beta effects, nonconstant-sigma cross-engine parity, other distributions or random-effect types, full R/Julia package checks, or rendered site validation.
