# Generalized prior-table integration: after-task draft

## Goal

Give applied users a consistent prior-table interface for the supported coefficient, standard-deviation and correlation targets, while preserving data likelihoods and existing no-prior behavior. This report records the validated candidate. GitHub checks and review remain open.

## Changes

The drmTMB candidate updates `R/fixed-priors-workflow.R`, `R/julia-bridge.R`, related tests and the fixed-effect prior vignette. The DRModels.jl candidate combines its prior-table resolver, correlation and residual-SD densities, convergence diagnostics and versioned bridge routes. The existing gllvmTMB and GLLVModels.jl candidates remain in their separate proposals.

## Checks and tests of the tests

The source-pinned drmTMB run covered 925 test files across 24 shards, with every shard and the controller exiting zero. The live R-to-Julia run confirmed that its fixed-effect, random-intercept SD, correlation and residual-SD fixture groups executed; all three groups passed. Two generated cases emitted singular-Hessian warnings, so this evidence does not establish calibrated uncertainty.

The Julia focused tests checked normalized Student-t and residual-SD densities, correlation objectives against an independent dense calculation, bridge target coordinates, and skipped-standard-error convergence. Earlier suites exposed an omitted mixed bivariate coefficient penalty, a prior-table default, a rank-deficient REML diagnostic, and convergence regressions. Two previously tested repairs were absent from the combined Julia source and are being restored and checked together. Their focused checks passed after correction. The combined source now restores the scale-axis objective and score and preserves the optimizer objective when a LogNormal likelihood adds its constant Jacobian. Focused scale-axis, convergence-status and bivariate LogNormal tests passed together. The Julia package suite covered all 731 assigned files on the corrected production source: six original sections passed, and two sections passed exact-assignment replays after test-only corrections. The original two failures remain recorded. The reconciled receipt has SHA-256 `eede4bdb0a9f539a8520d0ba9194a336b788f1209a80981eb760d8e1005e4a69`. One near-boundary test now checks that both equivalent fits remain non-converged; its specific non-converged category can vary with numerical score noise.

## Consistency and documentation

The updated R prior article rendered successfully from source `d4531fd`; `pkgdown::check_pkgdown()` reported no problems. An R package build and check without tests or vignette builds completed with two warnings because the package archive did not contain built vignettes. The prior article was rendered separately; this is not a full vignette or release check. The Julia prior guide was rendered on production source `d8ccb719` as an isolated page with its executable examples. Its single-page build warned about omitted docstrings, the missing index, repository links and inventory; neither full documentation site was built. The guide explains that Gamma priors on SDs use the natural-SD measure and that bootstrap coverage for penalized fits has not been validated. For the status inventory I used `git grep -n -i -E 'prior.?table|fixed.effect prior|random.effect sd prior|correlation prior|residual.sd prior' d4531fd -- README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml` and `git grep -n -E 'fixed-effect-priors|prior' d4531fd -- _pkgdown.yml`. NEWS describes the candidate scope; the older NEWS entry describes its historical slice. The site navigation points to the prior article and reference functions.

## What did not go smoothly

Embedded Julia initially failed during startup with the system libunwind. The qualified live run used Julia's bundled libunwind and an isolated depot. Earlier red test runs and incomplete attempts are retained separately from passing evidence. Future integration should compare the accepted repair diff with the combined source before launching a full suite; this run found previously verified fixes missing after reconciliation. The team-improvements log records this check. An older live-test counter missed the newer fixture groups; the later run checked their execution explicitly. The current Julia suite runner has a malformed controller-summary print command. The shard exits, source snapshots and logs remain available for an independent terminal reconciliation.

## Design, issue and next actions

The existing convergence proposals #1781 and #1903 share ancestry; the combined proposal is #1954. The companion Julia proposal is #1631. PR #1651 was not changed. Open issue #1740 covers prior plus REML validation; #1459 concerns a separate imputation-prior weighting issue. Neither issue was changed. No issue or PR was closed, and no merge or release was performed. Review the two integration proposals and their queued GitHub checks. Keep prior plus REML and uncertainty calibration outside the validated claims.
