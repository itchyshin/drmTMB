# After Task: Gamma Independent-Slope SD Regression

## Goal

Extend Gamma direct-SD regression from an ordinary random intercept to one independent numeric location slope in native TMB and the Julia engine, while preserving each route's fixed-effect `sigma` and complete-response limits.

## Implemented

The native Gamma adapter resolves a single independent `mu` slope as the target of `sd(group)`. The Gamma TMB branch reports the effective, soft-clamped group log-SD so existing clamp diagnostics can observe it. The Julia Gamma fitter and R bridge fit the same independent slope, and a same-data comparison passes within 0.2 on the log-SD coefficients.

## Mathematical Contract

For group (g), the coefficient SD follows `log(tau_g) = W_g alpha`. The observation-level slope loading remains `x_ig * tau_g * u_g`, with `u_g ~ Normal(0, 1)`. Correlated coefficients and additional random-effect terms remain unsupported.

## Files Changed

`R/drmTMB.R`, `src/drmTMB.cpp`, `tests/testthat/test-gamma-sd-regression.R`, `tests/testthat/test-gamma-sd-integration.R`, `tests/testthat/test-julia-gamma-sd.R`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `docs/design/18-random-effect-scale-models.md`, and `vignettes/formula-grammar.Rmd`.

## Checks Run

The focused assembly suite passed 17 assertions. The Gamma SD integration suite passed 23 assertions, including intercept recovery, constant-SD equivalence, the independent slope recovery check, prediction, simulation, and save/reload checks. The focused Julia package test passed 32/32 assertions. The live R bridge suite passed 26/26 assertions, including the same-data cross-engine slope comparison, with one non-fatal JuliaCall dependency-install warning. `pkgdown::check_pkgdown()` reported no problems, `git diff --check` passed, and the prose checker found no findings. No package-wide tests, site build, or calibration campaign ran.

## Tests Of The Tests

The new assembly case failed before the native code change with the expected intercept-only rejection. Recovery tests use independent synthetic data-generating processes and deterministic seeds. The native recovery's first sample-size setting narrowly missed the 2.5-SE criterion; increasing groups and repeats retained the same truth, seed, and criterion, after which it passed. The Julia slope test includes independent one-dimensional quadrature. The bridge compares the engines on identical generated data with a fixed 0.2 coefficient tolerance. Unsupported correlated/mixed slopes and inconsistent group-level SD predictors remain negative tests.

## Consistency Audit

The symbolic model, group-level SD design, TMB observation loading, and Julia observation loading agree for the admitted independent slope. The status-inventory search was:

```sh
rg -n -i 'Gamma.*(direct-SD|sd\(group\)|intercept-only|random-effect SD)|sd\(group\).*Gamma|slope-specific random-effect scale targets' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

NEWS, known limitations, formula grammar, family registry, and the vignette were updated; README and navigation had no matching claim to change. Broader programme status remains open.

## GitHub Issue Maintenance

No issue was inspected or changed. Issue reconciliation remains for programme closeout.

## What Did Not Go Smoothly

The first recovery sample was too weak for the fixed recovery rule. The larger deterministic synthetic sample passed without relaxing the rule.

## Team Learning

An adapter-level admission can be enough when the likelihood already consumes group-specific SD rows and observation-level random-effect loadings. Reporting the effective clamped SD is also necessary for family-specific clamp diagnostics.

## Known Limitations

Evidence covers one ordinary intercept or one independent numeric slope on both engines, complete responses, fixed `sigma`, and no structured or correlated terms. The R bridge comparison is one seeded agreement check; a broad cross-engine grid, interval calibration, broad recovery, and general cross-family support remain open.

## Next Actions

The after-task checker script is absent from this worktree, so structural validation by that script was unavailable. Continue the family/effect capability matrix and add the Gamma route to broader output and uncertainty validation. All programme gates remain open.
