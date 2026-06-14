# After Task: Ayumi q4 REML Bridge Forwarding

## Goal

Repair the first `drmTMB#544` bridge-gate-drift finding behind Ayumi's latest
wall-time report: the R bridge admitted `REML = TRUE` for the bivariate
Gaussian q = 4 phylogenetic location-scale route, but the bivariate options
payload did not forward REML to DRM.jl.

## Implemented

- `drm_julia_bridge_options()` now returns `list(method = "REML")` for the
  bivariate phylogenetic route when the public `drmTMB(..., REML = TRUE)`
  switch is active.
- The same route still returns `list()` for ML, preserving the established q4
  optimizer-default parity path.
- The q4 bridge payload test now asserts that `method = "REML"` reaches the
  serialized options for `family_type = "biv_gaussian"`.
- The REML gate unit test now treats bivariate q4 phylo as a supported
  DRM.jl REML cell rather than a route that "never forwards REML".
- `vignettes/julia-engine.Rmd` and `NEWS.md` now explain the public API as
  top-level `REML = TRUE/FALSE`, with DRM.jl `method = :REML` kept as internal
  bridge plumbing.

## Mathematical Contract

This task does not add a new likelihood, estimator, or speed path. The handover
records that DRM.jl has q4 REML support for the two mean axes and the two
log-scale axes; this R-side task verifies only the bridge contract. If the
bridge gate admits the q4 bivariate phylogenetic cell under `REML = TRUE`, the
serialized bridge payload must carry `method = "REML"` to the Julia engine. If
`REML = FALSE`, the ML payload must remain the q4 default-option payload.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-bridge.R`
- `tests/testthat/test-julia-sigma-phylo-reml.R`
- `vignettes/julia-engine.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/julia-bridge.R tests/testthat/test-julia-bridge.R tests/testthat/test-julia-sigma-phylo-reml.R vignettes/julia-engine.Rmd`
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'`
  - Result: 85 passes, 0 failures, 0 warnings, 0 skips.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-sigma-phylo-reml.R")'`
  - Result: 17 passes, 0 failures, 0 warnings, 1 guarded live-engine skip.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-biv-confint.R")'`
  - Result: 31 passes, 0 failures, 0 warnings, 0 skips.
- `git diff --check -- NEWS.md R/julia-bridge.R tests/testthat/test-julia-bridge.R tests/testthat/test-julia-sigma-phylo-reml.R vignettes/julia-engine.Rmd`
- `git diff --check`
- `Rscript --vanilla -e 'tools::checkRd("man/drmTMB.Rd")'`
- Stale-wording scan:
  `rg -n 'never forwards REML|bivariate q4.*never|q4.*REML.*blocked|biv.*REML.*blocked|missing-data routes stay TMB-native|missing-data routes, imputation|missing = miss_control\(\.\.\.\)|REML not yet wired|REML.*not.*wired' NEWS.md README.md ROADMAP.md docs vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md'`

## Tests Of The Tests

The new `test-julia-bridge.R` expectation exercises the exact bridge payload
that previously drifted. Before this fix, the same `method = "REML"` q4
bivariate payload produced `options = list()` because the bivariate branch
returned early before appending the method.

## Consistency Audit

The public user-facing API is consistently `drmTMB(..., REML = TRUE/FALSE)`.
The Julia-engine vignette now names DRM.jl `method = :REML` only as bridge
implementation detail. The stale scan found no current public wording saying
that q4 bivariate phylo "never forwards REML" or that all missing-data routes
stay native-TMB. Historical after-task notes were left untouched.

## GitHub Issue Maintenance

This is the first narrow implementation slice for `drmTMB#544`. No GitHub
comment was posted from this worktree. The next issue update should link this
after-task report, the test commands above, and the follow-up benchmark slice
for Ayumi's wall-time report.

## What Did Not Go Smoothly

`air format` reformatted several neighbouring expressions in `R/julia-bridge.R`
and the REML test fixture. The behaviour change remains small, but reviewers
should expect some wrapping-only diff in the bridge file.

## Team Learning

Rose's bridge-drift warning was correct: relaxing the high-level R gate is not
enough. Every admitted engine cell needs a payload-level assertion that the
estimator, masks, family metadata, and interval request actually survive the
R-to-Julia handoff.

## Known Limitations

- This fix does not make native `engine = "tmb"` a REML fallback for Ayumi's
  bivariate q4 phylogenetic location-scale model.
- This fix does not make the full Ayumi workflow fast. The full workflow still
  combines point fitting, profile/bootstrap refits, multiple response pairs,
  and multiple trees.
- The full `devtools::test()`, `devtools::check()`, pkgdown build, and
  Ayumi-sized benchmark remain separate gates.

## Next Actions

1. Open a focused PR for the q4 REML bridge-forwarding fix.
2. Run a small one-pair Ayumi benchmark that separates Julia startup,
   single-fit time, profile refits, bootstrap refits, and tree/pair loops.
3. Continue the broader `drmTMB#544` gate-vs-engine audit so missing-response,
   family, and future `engine_control` gates get payload-level tests.
