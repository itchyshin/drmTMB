# 2026-10-24: NB2 sigma random-effect SD regression

## Implementation

Added native-TMB support for a complete-data NB2 model with one ordinary
random intercept on `sigma` whose SD follows a fixed group-level design:
`sd(group, dpar = "sigma") ~ predictors`. The slice requires fixed-effect `mu`
and excludes other random/structured terms and zero inflation. The TMB effect is
`exp(W alpha) u`, added to `log(sigma)`; the fixed NB2 overdispersion parameter
and likelihood are unchanged.

## Validation

- Red-first: before the change, the focused test stopped at the builder's
  existing rejection of ordinary `sd()` formulas alongside random `sigma`.
- Green: `Rscript -e 'devtools::test(filter = "nbinom2-sigma-sd-regression", reporter = "summary", stop_on_failure = TRUE)'` passed.
- Neighbor check:
  `Rscript -e 'devtools::test(filter = "nbinom2-(location-scale|sd-regression)$", reporter = "summary", stop_on_failure = TRUE)'`
  passed the hurdle NB2 SD, NB2 location-scale, NB2 ordinary SD, truncated-NB2
  SD, and ZINB2 SD test files. The command exited 1 because
  `test-truncated-nbinom2-location-scale.R:366` expected an error for
  `hu ~ 1` with `truncated_nbinom2()` but instead reached a fit and emitted a
  singular-convergence warning. That failure is outside the edited builder
  path and remains open.
- R parse and scoped `git diff --check` passed.
- `pkgdown::check_pkgdown()` passed. The full site build was stopped after a
  `No space left on device` warning while rendering `capability-and-limits.Rmd`.
  The build emitted repeated Pandoc `--mathml` deprecation warnings.
- Focused open-issue search found no matching NB2 sigma-SD issue. No issue was
  changed.

## Documentation and Scope

Updated the formula grammar, random-effect scale reference, formula-grammar
vignette, README status, NEWS, roadmap, known limitations, and the unlazy G3/G4
evidence notes. These records describe one native point-fit slice only. The
paired Julia implementation, full family/effect inventory, storage/refit
workflows, and uncertainty calibration remain open; no programme gate is
closed by this slice.

Details: `docs/dev-log/after-task/2026-10-24-nbinom2-sigma-sd-regression.md`.
