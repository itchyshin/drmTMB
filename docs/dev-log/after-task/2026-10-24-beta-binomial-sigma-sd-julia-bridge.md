# BetaBinomial sigma-SD Julia bridge follow-up

## 1. Goal

Allow the bounded BetaBinomial sigma-axis random-intercept model to pass through `drmTMB(engine = "julia")`, preserving the same target identity as the direct Julia formula and native TMB model.

## 2. Implemented

The bridge now admits one ordinary random intercept on `sigma`, requires a fixed-effect-only `mu` formula, and rejects sigma slopes, mismatched groups, structured effects, and combined mean random effects. It renders the R selector `sd(id, dpar = "sigma")` as Julia's `sd(id, sigma)`. The label payload omits the generic `resd` label for this route because the Julia fit exposes a target-specific `:sd` block instead.

## 3. Mathematical contract

This bridge route carries the same BetaBinomial model as the native TMB path: `log(sigma_ig) = X_sigma beta_sigma + b_g`, `b_g ~ Normal(0, tau_g^2)`, `log(tau_g) = W_g alpha`, and `phi_ig = exp(-2 log(sigma_ig))`. The mean model has fixed effects only. Julia integrates the group effects with its adaptive Gauss-Hermite route; native TMB uses its existing Laplace route. On one matched synthetic fit, the two coefficient estimates differed by 0.0058 and 0.00039, and the largest absolute group-SD difference was 0.0025; the test's predeclared bounds were 0.05 for coefficients and 0.02 for group SDs. The log-likelihoods differed by 0.286, consistent with the different integration approximations. This is one point-fit comparison, not broad numerical parity or interval calibration.

## 3a. Decisions and Rejected Alternatives

The bridge exception is restricted to the exact sigma-intercept shape already implemented in direct Julia. It does not admit simultaneous mean random effects, sigma slopes, structured effects, or other distributional endpoints. One same-data synthetic point-fit comparison now checks coefficient and group-SD agreement between native TMB and the Julia bridge. It does not establish broad engine parity or interval coverage.

## 4. Files Touched

- `R/julia-bridge.R`: narrow route admission, formula rendering, and target-specific coefficient labels.
- `tests/testthat/test-julia-beta-binomial-sigma-sd-bridge.R`: admission, refusal, formula-rendering, label, and matched TMB/Julia point-fit checks.
- `docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`: corrected bridge status and remaining limits.
- `news/beta-binomial-sigma-sd-julia-bridge.md`, this report, and `docs/dev-log/check-log.d/2026-10-24-beta-binomial-sigma-sd-julia-bridge.md`.
- Paired direct Julia implementation and tests are recorded in the DRM.jl worktree report `docs/dev-log/after-task/2026-10-24-julia-betabinomial-sigma-sd-regression.md`.

## 5. Checks Run

- Red-first route test failed because the sigma-axis admission helper did not exist.
- Formula gate, formula rendering, label, and refusal tests passed: 7 expectations.
- One matched synthetic TMB/Julia fit passed 11 expectations: convergence on both engines, coefficient names and agreement, synthetic recovery, group-name alignment and SD-prediction agreement, and finite likelihoods. Coefficient differences were 0.0058 and 0.00039; the maximum absolute group-SD difference was 0.0025; the log-likelihood difference was -0.2857. Julia used 1.10.0 and the paired local DRM.jl worktree.
- The paired native TMB route test completed with 22 expectations; its native implementation record is `docs/dev-log/after-task/2026-10-24-beta-binomial-sigma-sd-regression.md`.
- The paired direct Julia test passed 21 expectations in its own worktree. The current-source formula-grammar and predictor-dependent-SD vignettes rendered successfully to `/private/tmp/formula-grammar-beta-binomial-sigma-sd-final-20261024.html` and `/private/tmp/predictor-dependent-random-sd-beta-binomial-sigma-sd-source-loaded-20261024.html`; Pandoc emitted its existing `--mathjax` deprecation warning. The full package suites and full pkgdown site build were not run.
- `pkgdown::check_pkgdown()` found no problems; it emitted existing Pandoc `--mathml` deprecation warnings. This is a reference/navigation check, not a full site build.
- The after-task structure checker passed. It found 13 acceptance-ledger files but no runnable gate command, so the ledger state remains unknown rather than satisfied.

## 6. Tests of the Tests

The bridge test checks that the exact sigma target is admitted and rendered with Julia syntax, that coefficient labels name only `mu`, `sigma`, and `sd`, and that unsupported shapes remain refused. Its live synthetic data have 80 groups, 18 observations per group, and a nonzero group-level log-SD slope. Both engine fits must converge; estimates must recover the generating coefficients within a broad point-fit tolerance, and the TMB/Julia estimates and group-named SD predictions must agree within bounds chosen before the automated rerun. The test checks both likelihoods are finite, without requiring equality across their different integration approximations.

## 7. Issue Ledger

No GitHub issue or pull request was opened or updated.

## 7a. Issue Ledger

No issue was created, changed, or closed as part of this bridge follow-up.

## 8. Consistency Audit

The R target metadata, Julia formula selector, coefficient-label payload, and public prediction target now agree on the same sigma random intercept. The bridge suppresses the ordinary `resd` echo only for this exact BetaBinomial SD route. Documentation now records one matched point-fit comparison while keeping broad numerical parity and interval calibration open.

## 9. What Did Not Go Smoothly

The first live test used `se = FALSE` in a TMB-only control and correctly failed at the bridge control gate. After removing that setting, the live fit exposed an extra `resd` coefficient label that the Julia target-specific fit does not have. The bridge now avoids adding that label for this route. A separate attempt also showed that JuliaCall needed the Julia 1.10 executable directory on `PATH`; no installation was needed. The first vignette render attached an older installed checkout and failed on an obsolete selector restriction; explicitly loading this worktree before rendering fixed the source selection, and both edited vignettes then rendered.

## 10. Known Residuals

Broad R/TMB-versus-Julia numerical parity remains unmeasured because native TMB uses Laplace integration and Julia uses adaptive Gauss-Hermite quadrature. One matched point-fit comparison passed within the stated coefficient and group-SD bounds, while its log likelihood differed by 0.2857. Interval calibration, broad stress recovery, the full test suites, and the full pkgdown site build remain open. The route still requires complete responses, fixed-effect-only `mu`, one ordinary sigma random intercept, and group-constant SD predictors.

## 11. Team Learning

A bridge route needs an explicit audit of formula rendering and coefficient-label echo in addition to the family admission gate. A model can reach the Julia fitter and still fail before returning if the bridge sends a label for a block that the fitter does not expose.

## 12. Cross-Product Coverage

The native TMB model, direct Julia model, and one live `drmTMB(engine = "julia")` fit have focused point-fit evidence for this restricted target. One same-data fixture checks coefficient and group-SD agreement across engines, but does not establish broad numerical parity. This follow-up does NOT cover interval calibration, other random-effect types, or other response families.
