# After Task: BetaBinomial sigma-SD cross-engine oracle

## 1. Goal

Strengthen the synthetic same-data check for a BetaBinomial random intercept on `sigma` whose group SD depends on a fixed predictor. The check should distinguish a model error from the different integration methods used by native TMB and Julia.

## 2. Implemented

The bridge test now computes the marginal log likelihood independently for each fitted model. It integrates each group’s scalar standard-normal effect with R’s adaptive integration and the BetaBinomial probability mass formula. The Julia fit uses 11-node adaptive Gauss–Hermite quadrature; native TMB places the random effect in `MakeADFun()`’s random block and uses the Laplace approximation.

## 3a. Decisions and Rejected Alternatives

An initial test required the two fitted log likelihoods to differ by less than 0.25. It failed at a difference of 0.286. I rejected simply widening that cross-engine bound because it would mix model agreement with approximation error. The test instead checks each engine against the independent integral, with separate tolerances for Julia quadrature and native TMB Laplace integration.

## 4. Files Touched

- `tests/testthat/test-julia-beta-binomial-sigma-sd-bridge.R`: independent marginal-likelihood oracle and engine-specific checks. SHA-256: `fa803784011804c95df599e02a3410000e5372e2a2dc858d5f2fe78d333af1d2`.
- `.unlazy/general-sd-regression/GATES.md`: moved the deferred G5 label after the gate ID colon so the ledger parser can read it. No gate status changed.
- `docs/dev-log/check-log.d/2026-10-24-beta-binomial-sigma-sd-cross-engine-oracle.md`: focused check receipt.
- `docs/dev-log/after-task/2026-10-24-beta-binomial-sigma-sd-cross-engine-oracle.assessment.json`: exact-draft prose assessment.

## 5. Checks Run

- `devtools::test(filter = "julia-beta-binomial-sigma-sd-bridge", reporter = "summary", stop_on_failure = TRUE)`: exit code 0; the bridge ran one live Julia test and the independent integral checks passed for both fits.
- `Rscript -e 'parse(file = "tests/testthat/test-julia-beta-binomial-sigma-sd-bridge.R")'`: passed.
- Trailing-whitespace scan of the changed test file: no trailing whitespace.
- Julia source review confirmed `_AGHQRule(1, nAGQ)` in the BetaBinomial sigma-SD likelihood; native fit construction passes `spec$tmb_random_names` to `TMB::MakeADFun()`.
- After-task structure validation passed. The full check exits 1 because the programme and leaf ledgers remain open. The standalone gate checker exits 2 because `gates/tweedie-julia-ordinary-sd.md` has zero live gates.

## 6. Tests of the Tests

The original 0.25 cross-engine likelihood assertion failed by 0.036. Replacing it with independent one-dimensional integration produced a passing check for both engines. The test still compares SD coefficients and group predictions on identical synthetic data; finite likelihood checks remain, while exact likelihood equality is not assumed across Laplace and adaptive quadrature.

## 7a. Issue Ledger

I searched open GitHub issues for “beta-binomial sigma random effect SD”. The results contained no issue for this tested route, so I did not comment, open, or close an issue.

## 8. Consistency Audit

The targeted search `rg -n "beta_binomial_sigma_sd|BetaBinomial sigma SD|sigma-SD" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml` found one internal-roadmap mention. This test adds no public syntax or fitting behavior, so I did not change user documentation, design grammar, NEWS, or pkgdown navigation. The full family/effect capability inventory still needs reconciliation.

The shared `docs/dev-log/check-log.md` has work on 440 refs, according to path preflight, so I left that file untouched and recorded the focused receipt in `check-log.d/` instead.

## 9. What Did Not Go Smoothly

The first package-test attempt failed before tests started because `pkgload` could not copy the compiled library while the temporary filesystem was full. After space became available, the focused test ran. A later strict cross-engine likelihood bound also failed, correctly exposing that likelihoods from different integration approximations should not be compared as though they were the same numerical method.

The after-task validator first could not parse the deferred G5 label. I corrected the ID/colon order without changing its deferred status. This exposed the broader state: the programme and per-slice ledgers are still open, and one Tweedie sidecar has no live gate for the standalone checker.

## 10. Known Residuals

This is one complete-data synthetic fixture with fixed `mu`, a `sigma` random intercept, and a group-level SD predictor. The test does not establish interval coverage. The tolerances are fixture-specific numerical checks, not broad recovery or calibration criteria. The general SD programme remains open.

## 11. Team Learning

For cross-engine latent-effect tests, compare each engine against an independent oracle when their integration methods differ. Keep coefficient and prediction parity checks, but do not turn a small likelihood discrepancy into an arbitrary tolerance change.

## 12. Cross-Product Coverage

This slice checks one BetaBinomial `sigma` endpoint, one ordinary random intercept, one fixed SD predictor, complete responses, and a same-data TMB/Julia fit. It does NOT cover other response families, other endpoints, random slopes, correlated or structured effects, multiple providers, bivariate models, simulation or refit workflows, uncertainty coverage, or programme-wide documentation and regression gates. No programme gate advanced.
