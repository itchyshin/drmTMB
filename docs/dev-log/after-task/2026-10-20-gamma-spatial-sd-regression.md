# After Task: Gamma coordinate-spatial direct-SD regression

## 1. Goal

Add and document one bounded native Gamma route where a site-level predictor changes the SD of a coordinate-spatial location intercept.

## 2. Implemented

`sd(site, level = "spatial") ~ z` now fits with `Gamma(link = "log")` for one q1 coordinate-spatial `mu` intercept. A seeded synthetic test checks the positive SD-trend recovery, site-keyed SD predictions, and equivalence of an explicit constant-SD formula with the existing scalar-SD spatial fit. The vignette includes a matching synthetic example generated from the model's exponential coordinate covariance, including the same median-distance range and diagonal jitter.

## 3a. Decisions and Rejected Alternatives

For site `i`, `log(tau_i) = alpha_0 + alpha_1 z_i`, with `z_i` constant within site. The latent field has covariance `D_tau K D_tau`, where `K` is the existing coordinate-spatial covariance and `D_tau = diag(tau_i)`. The implementation preserves the existing kernel scaling. Gamma `sigma` is fixed at `1`; the model does not add an SD effect to residual `sigma` or combine location and residual random effects.

## 4. Files Touched

- `R/parse-formula.R`
- `R/drmTMB.R`
- `tests/testthat/test-gamma-spatial-sd-regression.R`
- `tests/testthat/test-positive-continuous-structured-mu.R`
- `tests/testthat/test-sd-level-grammar.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/check-log.md`
- `.unlazy/general-sd-regression/GATES.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `NEWS.md`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "gamma-(phylo|relmat|animal|spatial)-sd-regression|sd-level-grammar|positive-continuous-structured-mu")'`: 266 passed, 0 failures, 1 warning, 0 skips in 11.9 seconds. The warning is the existing one-time `sd_phylo()` deprecation warning. The filter did not exercise a live Julia engine.
- `Rscript -e 'devtools::test(filter = "gamma-animal-pedigree-sd-regression")'`: 14 passed, 0 failures, 0 warnings, 0 skips in 16.5 seconds. No live Julia test ran.
- `devtools::load_all(".", quiet = TRUE)` followed by rendering `vignettes/predictor-dependent-random-sd.Rmd` to `/tmp/predictor-dependent-random-sd-gamma-spatial.html`: passed. Pandoc printed its existing deprecated `--mathjax` notice.
- `pkgdown::check_pkgdown()`: no problems found; Pandoc printed existing deprecated `--mathml` notices.
- Scoped `git diff --check`: passed for the slice files. A whole-worktree check reported a pre-existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R`, outside this slice.
- `pkgdown::check_pkgdown()`: no problems found; only Pandoc's existing deprecation notices.
- After-task structure validation and slop check: passed.

## 6. Tests of the Tests

The spatial regression test first failed when the formula was rejected as planned-but-unimplemented. It now fits the same coordinate covariance used by the simulator and checks the estimated trend against the seeded truth, prediction names against site levels, and equality of constant-SD and existing scalar-SD log likelihoods. The grammar test confirms that the generic spatial selector parses to the distinct `sd_spatial(id)` target. Neighbouring structured-provider rejection tests retain their Lognormal expectations while allowing the fitted Gamma route.

## 8. Consistency Audit

The test, formula grammar, family registry, random-effect-scale design, inventory, known limitations, roadmap, NEWS, vignette, and acceptance ledger now describe one native Gamma coordinate-spatial q1 direct-SD row. The example and test use site-constant predictors and preserve the existing spatial covariance scaling. Open-issue search found no issue specifically tracking this exact implementation slice; broader issue #59 tracks the package simulation programme and was not changed. No issue was opened or closed.

## 7a. Issue Ledger

Searched open drmTMB issues for `"sd regression"` and `"random-effect scale"`. No exact implementation issue matched this coordinate-spatial Gamma slice. Issue #59 concerns the broader simulation programme and remains unchanged. No GitHub comments, issues, or pull requests were changed.

## 9. What Did Not Go Smoothly

The prescribed repository-local `tools/lane_preflight.sh` is absent in this checkout. The active worktree has a broad pre-existing programme diff, so this slice stayed confined to its Gamma spatial selector/provider test and corresponding documentation. One documentation patch initially used a mismatched context and made no change; exact source text was then checked before applying targeted replacements.

## 11. Team Learning

A spatial SD recovery fixture must generate its latent field from the same coordinate covariance and range convention as the fitted model. Independent normal site effects would test a different data-generating model and weaken the meaning of the recovery check.

## 10. Known Residuals

This is one native point-fit route. It does not establish interval calibration, Julia parity, Gamma spatial slopes or correlated blocks, mesh/SPDE SD support, save/reload, simulation, profiles, or bootstrap-refit behavior. The general family/effect/provider/backend inventory remains incomplete. G3, G4, G6, G7, and G8 remain open; G5 coverage calibration remains deferred.

## 12. Cross-Product Coverage

This slice does NOT cover Julia, interval coverage, mesh/SPDE covariance, Gamma structured slopes, simulation or save/reload output behavior, profile/bootstrap refits, or other response families. It covers one native Gamma q1 coordinate-spatial `mu` intercept with complete responses, a site-constant SD predictor, and fixed `sigma ~ 1`. Continue with the next unevidenced row in the active direct-SD inventory; do not describe this as general Gamma or spatial SD support.
