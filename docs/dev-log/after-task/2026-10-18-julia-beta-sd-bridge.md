# Julia Beta SD bridge parity

## Goal

Verify that a complete-data Beta ordinary-intercept SD formula reaches the new Julia fitter through the R bridge and agrees with native TMB on a shared synthetic dataset.

## Implemented

Added a live Julia bridge regression test. It compares the fitted SD coefficients with native TMB and checks groupwise and rowwise predictions plus save/reload.

## Files changed

- `tests/testthat/test-julia-beta-sd.R`: paired native TMB and Julia bridge test.
- `docs/design/01-formula-grammar.md`: records the narrow Julia Beta ordinary-intercept route.
- `docs/dev-log/known-limitations.md`: clarifies that this route is available while other family and effect combinations remain open.
- `news/julia-beta-sd-regression.md`: release fragment.
- `docs/dev-log/check-log.d/2026-10-18-julia-beta-sd-bridge.md`: test receipt.

## Checks run

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' Rscript -e 'devtools::test(filter = "julia-beta-sd")' passed all 11 assertions. Two warnings came from bridge internals invoking the deprecated `beta()` alias even though the test uses `beta_family()`. The first attempt skipped because no Julia path was configured; the live run with `DRM_JL_PATH` set exercised both engines. `Rscript -e 'pkgdown::check_pkgdown()'` reported no problems. `pkgdown::build_site()` could not finish: the environment could not resolve `cloud.r-project.org` while fetching the CRAN link; it also reported blocked cache writes outside the workspace.

## Tests of the tests

The test fits the same seeded response with native TMB and Julia, checks the sign and cross-engine agreement of the SD predictor, and verifies both group-level and row-level output. Save/reload checks that the public SD result is retained in the bridge object.

## Mathematical contract

The formula `sd(id) ~ z` models the log SD of the ordinary Beta mean intercept for each group. The test holds Beta precision fixed with `sigma ~ 1` and uses a group-constant predictor.

## Consistency audit

The test and documentation limit this route to one ordinary intercept and fixed sigma. The Julia fit itself has independent quadrature and recovery tests; this bridge check adds engine agreement and object workflow evidence. Neither test family establishes interval calibration.

## Documentation and design updates

The formula grammar, known-limitations inventory, native-family wave plan, and NEWS fragment now state that ordinary Beta intercept SD regression is available in both engines, with broader effect types and calibration still open. The inventory search was `rg -n -i 'beta.{0,40}sd|sd.{0,40}beta' README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md NEWS.md`; it found the relevant Beta rows and no remaining claim that the ordinary intercept route is unavailable. No pkgdown navigation changed.

## GitHub issue maintenance

A read-only `gh issue list --state open --search 'Beta random-effect SD' --limit 10` could not connect to api.github.com. No issue was changed; issue overlap remains unverified.

## What did not go smoothly

JuliaCall first failed because sandbox permissions blocked its normal package-usage log in the existing Julia depot. The rerun with normal depot access succeeded without installing packages. The live test emitted two nonfatal warnings from the bridge's deprecated alias probe.

## Team learning and process

For paired-engine work, set the Julia worktree path explicitly when invoking the R test filter. A test that skips on an unavailable bridge does not count as engine evidence.

## Known limitations and next action

This is point-recovery and public-workflow evidence only. Julia Beta slopes, structured effects, broader marginal methods, and interval calibration remain unimplemented or unvalidated. Run the R documentation build and keep this Beta row in the broader SD capability and calibration ledger.
