# After Task: Native Lognormal random-slope SD regression

## 1. Goal

Extend native Lognormal predictor-dependent random-effect SDs to one selected
independent numeric location-slope coefficient, with a seeded recovery check,
independent likelihood comparison, and matching user documentation.

## 2. Implemented

The Lognormal builder admits the ordinary independent location-slope SD target
and carries its group-specific SD design through the shared start, map,
likelihood, extraction, and prediction paths. The complete-data fit permits
fixed-effect `sigma`; this slice does not admit correlated or structured
effects or random effects on `sigma`.

## 3a. Decisions and Rejected Alternatives

The contract is `log(tau_g) = W_g alpha` for the SD of one independent
location-slope coefficient. For group `g`,
`log(y_g) = X_g beta + x_g b_g + epsilon_g`, where
`b_g ~ Normal(0, tau_g^2)` and
`epsilon_g ~ Normal(0, diag(sigma_gi^2))`. The marginal log-response covariance
is `tau_g^2 x_g x_g' + diag(sigma_gi^2)`, and the response likelihood includes
`-sum(log(y_g))`. Keep this as a narrow native slice; do not imply correlated,
structured, missing-response, or Julia support from it. Interval coverage is
deferred by the active programme decision and is not a completion criterion
for this slice.

## 4. Files Touched

`R/drmTMB.R`, `tests/testthat/test-lognormal-sd-slope-assembly.R`,
`docs/dev-log/general-sd-regression/lognormal-sd-contract.md`,
`docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`,
`docs/design/18-random-effect-scale-models.md`,
`docs/design/01-formula-grammar.md`,
`vignettes/predictor-dependent-random-sd.Rmd`, `NEWS.md`,
`docs/dev-log/check-log.md`,
`docs/dev-log/check-log.d/2026-10-21-lognormal-sd-slope.md`,
`.unlazy/general-sd-regression/gates/lognormal-slope-sd.md`, and this report
with its assessment JSON.

## 5. Checks Run

The focused `lognormal-sd-slope-assembly` test passed 17 expectations with no
failures, warnings, or skips. The current-source predictor-dependent-SD
vignette rendered successfully and `pkgdown::check_pkgdown()` reported no
problems. The slice ledger records all three checks as met. Pandoc emitted its
existing deprecated `--mathjax` and `--mathml` option warnings. `git diff
--check` passed on the code and documentation changes. The status-inventory
searches and their exact patterns are recorded in
`docs/dev-log/check-log.d/2026-10-21-lognormal-sd-slope.md`.

## 6. Tests of the Tests

The assembly test was run before the builder change and failed at the
intercept-only admission guard. After implementation, the fit test recovers a
seeded SD trend and compares the package log likelihood against an independent
groupwise Gaussian marginal-likelihood calculation with the response
Jacobian. The constant-SD and ordinary fits must both converge and have
positive-definite Hessians before their likelihoods are compared. The test
also checks simulation and group-level SD predictions.

## 7a. Issue Ledger

The open-issue search found no matching Lognormal SD-regression feature issue.
No issue was opened, edited, or closed.

## 8. Consistency Audit

The formula grammar table, scale-model design note, family adapter map,
Lognormal contract, tutorial, NEWS, and check log agree on the support
boundary. README, roadmap, known limitations, and pkgdown navigation needed no
additional edits for this slice. The rendered page includes executed
Lognormal fit and prediction output.

## 9. What Did Not Go Smoothly

The first direct `testthat::test_file()` attempt did not load the package and
failed because `bf()` and the internal builder were unavailable. The supported
`devtools::test()` path then passed. The first ledger run had two overly strict
output expectations even though both checks exited successfully; explicit
success markers fixed the ledger checks. The after-task report also needed its
headings aligned with the required report checker. The shared ownership-lease
registry required the approved exact-path access because it is outside the
workspace's default writable root.

## 10. Known Residuals

This slice establishes native fitting, point recovery, a likelihood oracle,
prediction, simulation, and constant-SD equivalence. It does not establish
interval calibration, Julia parity, correlated or structured SD regression,
missing-response support, or random effects on `sigma`.

## 11. Team Learning

Use the package-aware focused test runner for internal builder tests. Require
each gate check to print an explicit, stable success marker. When a required
lane lease is stored outside the source workspace, request only that exact
registry write and verify the lease before editing.

## 12. Cross-Product Coverage

Only the native R/TMB Lognormal route was changed and checked here. No Julia
source or bridge was changed. The scope is complete data with one selected
independent numeric location-slope SD and fixed-effect `sigma`. This slice
does NOT cover Julia, correlated or structured effects, missing responses, or
random effects on `sigma`. Interval coverage is deferred; this report makes no
calibrated-uncertainty claim.
