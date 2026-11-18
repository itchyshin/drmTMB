# After Task: Non-logit Binomial intercept-plus-slope SD bridge

## 1. Goal

Extend the development Julia bridge for Binomial probit and complementary log-log models from a single ordinary random coefficient to one independent random intercept and one independent numeric slope on the same group, with a separate matching SD formula for each.

## 2. Implemented

The bridge admission predicate now accepts either one ordinary intercept, one independent numeric slope, or their same-group pair. For the pair, both SD formulas must select their matching coefficient explicitly. The slope predictor must be numeric when data are supplied. The gate rejects missing or mismatched SD targets, different groups, correlated blocks, and other random-effect shapes.

The paired synthetic test fits both probit and complementary log-log data using native TMB and the paired DRM.jl candidate. It checks convergence, target labels, positive recovery of both SD-predictor slopes, and group-SD prediction agreement. The Formula grammar and Julia-engine guide now describe this exact candidate route and its limits.

## 3a. Decisions and Rejected Alternatives

- Kept the route to independent random coefficients represented as separate terms. This does not admit a correlated `(1 + x | id)` block.
- Required separate coefficient selectors for both SD formulas in the two-coefficient case so target matching is explicit.
- Kept the public documentation limited to the development Julia checkout. This does not add shared/released DRM.jl support.
- Treated the cross-engine test as point-recovery and output evidence; TMB Laplace and Julia adaptive quadrature do not establish likelihood equality or interval calibration.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-nonlogit-intercept-slope-sd-bridge.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-25-julia-binomial-nonlogit-intercept-slope-bridge.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-25-julia-binomial-nonlogit-intercept-slope-bridge.md`

## 5. Checks Run

- Test-first admission control: the new pair formula failed before the predicate change. Afterward, the focused fit-free test passed three checks, including partial-target and wrong-group refusals.
- Live paired probit/cloglog intercept-plus-slope test: passed across native TMB and Julia fits, including convergence, both SD-predictor slopes, target labels, and named group-SD predictions.
- Follow-up paired test: passed through Julia bootstrap target dispatch with two requested refits; at least one refit returned a finite interval. `profile_targets()` also lists both SD-predictor coefficients. This smoke check covers routing and result shape; interval calibration remains unmeasured.
- Adjacent probit/cloglog slope-only bridge test: passed 27 expectations after the Juliaup binary was exposed through `PATH` and `JULIA_HOME`.
- The Julia-engine guide rendered to a temporary HTML file. Pandoc emitted its existing `--mathjax` deprecation warning.
- The Formula grammar vignette rendered to a temporary HTML file with the same existing Pandoc warning.
- Scoped `git diff --check`: PASS.
- No profile confidence interval or interval-coverage calibration was run. The two-refit bootstrap smoke checks target routing and result columns only; it does not assess interval quality.

## 6. Tests of the Tests

The new admission test reproduced the old rejection before implementation and passed afterward. The live synthetic test has one data-generating design per link and checks both independent random coefficients. Its two-refit bootstrap smoke confirms that a selector-qualified SD coefficient survives Julia refitting. Repeated-sampling behavior and interval calibration remain unmeasured.

## 7a. Issue Ledger

- Fixed: the Julia bridge rejected a non-logit Binomial intercept-plus-independent-slope SD model even though the paired Julia fitter supports independent coefficient SD regressions.
- Deferred: correlated non-logit blocks, structured effects, other non-logit formula shapes, shared/released DRM.jl support, and interval-coverage calibration.
- The older slope-only fixture initially failed before Julia started because its command did not expose the Juliaup binary on `PATH`. Rerunning with `PATH` and `JULIA_HOME` set passed.

## 8. Consistency Audit

The route matches the formula `mu` design `(1 | id) + (0 + x | id)` with two separate `sd()` targets. Both engines fit the same synthetic data; the test compares SD coefficients and group predictions under a smoke tolerance rather than comparing approximate marginal likelihoods. The error message, NEWS, formula grammar, known-limitations note, Julia-engine example, and engine table state the same intercept/slope boundary.

## 9. What Did Not Go Smoothly

The first live pair run reached model fitting but stopped at an unsupported `info` argument in the test assertion; the assertion was corrected and the full two-link test then passed. The first bootstrap smoke call included native-only arguments that the Julia method rejects; removing them let the supported Julia bootstrap route run. The adjacent older slope-only fixture required explicit Juliaup path configuration for the local rerun.

## 10. Known Residuals

This is one ordinary same-group intercept-plus-slope candidate route for two non-logit links. It does not establish calibration, full numerical parity, correlated or structured blocks, released Julia support, or any broader Bernoulli/general-family completion. The repository contains concurrent dirty work; no unrelated changes were reverted, and nothing was committed, merged, or pushed.

## 11. Team Learning

The bridge's SD-label machinery already supports multiple selector-qualified targets; the missing piece was the family-specific admission predicate. The existing paired Julia fitter was checked before expanding the interface. No durable memory note was added.

## 12. Cross-Product Coverage

Covers: R/TMB and the paired DRM.jl candidate for complete-data probit and complementary log-log Binomial models with one independent ordinary mean intercept and one independent numeric slope on the same group, each with a matching predictor-dependent SD formula.

Does NOT cover: logit changes, correlated blocks, structured effects, random effects on other parameters, missing responses, profile confidence intervals for this pair, substantive bootstrap inference validation, interval coverage, shared/released Julia support, full package checks, or programme completion.
