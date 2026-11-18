# After Task: Beta-binomial sigma random-slope SD bridge

## 1. Goal

Extend predictor-dependent random-effect SD regression to one identifiable Beta-binomial case: an independent random slope on the `sigma` predictor, with a fixed predictor modelling that slope's group SD. Coverage calibration stays deferred.

## 2. Implemented

The native builder admits the matching `sigma` slope and SD formula. The Julia bridge now admits this same narrow route and maps its selected coefficient to Julia's stable `sd` block label. The model is `log(sigma_ig) = X_sigma,ig gamma + x_ig u_g`, `u_g ~ Normal(0, tau_g^2)`, and `log(tau_g) = W_g alpha`. The beta-binomial precision convention remains `phi_i = exp(-2 log(sigma_i))`. The route requires complete responses, fixed-effect `mu`, one independent numeric slope, a matching coefficient selector, and group-constant SD predictors.

## 3a. Decisions and Rejected Alternatives

Reused the generic random-effect slope likelihood and the Julia bridge's existing `sd` naming convention. No new C++ likelihood or Julia source change was required in this slice. The bridge remains fenced against unmatched slopes and other coefficient/block targets. No interval-coverage claim is made.

## 4. Files Touched

Implementation and tests: `R/julia-bridge.R`, `tests/testthat/test-beta-binomial-sigma-sd-regression.R`, `tests/testthat/test-julia-beta-binomial-sigma-sd-bridge.R`.

Documentation: `NEWS.md`, `news/beta-binomial-sigma-sd-julia-bridge.md`, `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/general-sd-regression/inventory.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`.

Evidence and project record: `docs/dev-log/general-sd-regression/evidence/beta-binomial-sigma-slope-20261025/`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

The native focused filter passed 37 expectations, including signed recovery, group SD prediction, simulation/refit output checks, and constant-SD equivalence. The live bridge filter passed 35 expectations, including two live Julia fits, matching target labels, coefficient recovery, same-data point comparisons, and group SD prediction. JuliaCall used Julia 1.10.0. Source hashes for the R/TMB builder, bridge, and both tests were unchanged across the captured runs. The paired Julia implementation files were read and hash-recorded only. Scoped `git diff --check` passed. The predictor-dependent SD vignette rendered successfully earlier in this task from the candidate package loaded with `devtools::load_all()`; generated HTML is in `/private/tmp/drmtmb-predictor-dependent-random-sd-beta-slope.html`.

## 6. Tests of the Tests

The recovery assertions fail on wrong target labels and incorrect slope-to-SD mapping; the admission checks exercise rejection of unmatched routes. The recorded runs retained all test output. No deliberate corrupted implementation control was run in this focused slice.

## 7a. Issue Ledger

No new issue was opened. Deferred interval calibration and unimplemented family/effect/backend combinations remain tracked in the programme inventory and roadmap.

## 8. Consistency Audit

The formula example, bridge target mapping, tests, NEWS, family registry, and limitations describe the same independent `sigma` slope route. The Beta-binomial scale convention remains unchanged.

## 9. What Did Not Go Smoothly

The first bridge invocation did not locate Julia because the runtime path was absent from the shell environment. The captured live run explicitly set `PATH`, `JULIA_HOME`, and `DRM_JL_PATH`; it then ran two live fits.

## 10. Known Residuals

Console logs and source hashes are retained under `docs/dev-log/general-sd-regression/evidence/beta-binomial-sigma-slope-20261025/`. This is focused synthetic point-recovery and output evidence. It does not validate confidence-interval coverage, general Julia/TMB likelihood equivalence, or the full required capability universe. The inventory records candidate combinations and evidence links; linked records do not establish programme completion.

## 10a. User-Facing Documentation

Formula, family, SD design, limitation, roadmap, NEWS, and tutorial text now describe the narrow Beta-binomial intercept/slope support and explicitly bound the Julia evidence. The independent synthetic example uses `sd(id, dpar = "sigma", coef = "x") ~ z`.

## 10b. Ownership and Coordination

The native and R bridge changes are in the `codex/general-sd-regression` candidate worktree. The paired Julia worktree was read-only for this slice; its existing implementation and test hashes are recorded. No other lane's edits were reverted or staged.

## 10c. Remaining Work

Coverage calibration remains deferred by the user's scope decision. Other response families, random-effect types, endpoints, providers, and backend combinations remain open until separately implemented and evidenced. No commit, merge, release, or email was made.

## 10d. After-Task Review

The neighboring family and formula docs were updated to avoid implying blanket support. Constant-SD equivalence and matching-target refusal are exercised. Broader combinations remain visibly unsupported or unverified.

## 11. Team Learning

A live bridge check must explicitly set `DRM_JL_PATH` to the paired Julia candidate; otherwise it can silently run only source-level marshalling tests. The captured run confirms two live fits ran.

## 12. Cross-Product Coverage

This slice covers a complete-data Beta-binomial `sigma` random slope with a matching fixed-predictor SD regression on native TMB and the Julia bridge, plus point recovery, output identity, and constant-SD equivalence on the native route. It does NOT cover interval-coverage calibration or establish parity across all families, random-effect types, structured kernels, bivariate models, or providers. The general programme remains in progress.
