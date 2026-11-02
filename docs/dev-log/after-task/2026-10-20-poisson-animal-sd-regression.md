# After Task: Native Poisson animal-model SD regression

## 1. Goal

Implement one general-SD programme row: a native non-inflated Poisson animal-model location intercept with a predictor-dependent SD.

## 2. Implemented

The formula `sd(id, level = "animal") ~ z` now fits with one complete-data q1 `animal(1 | id, A = A)` term and returns the canonical target `sd_animal(id)`. The existing structured known-relatedness likelihood handles the fit.

### Mathematical Contract

For animal effects `b`, the model uses `b ~ Normal(0, D A D)`, with `D = diag(exp(W alpha))`. The supplied relationship matrix and its scaling are preserved. Each SD predictor must be constant within animal ID. This Poisson route adds no extra residual-scale parameter.

## 3a. Decisions and Rejected Alternatives

The existing known-relatedness likelihood already provides the needed non-centered scaling, so the slice reuses it. The supplied relationship matrix keeps its existing scale. A reversed dimname order was rejected as an alignment test because this stationary covariance is invariant to reversal; the test now uses an interleaved permutation. No C++ likelihood change was needed.

## 4. Files Touched

- `R/drmTMB.R` admits `sd_animal()` in the Poisson builder and lists the animal selector in its structured-SD hint.
- `tests/testthat/test-poisson-animal-sd-regression.R` adds the synthetic recovery and workflow test.
- `R/random-effect-scale-formulas.R` and `man/random_effect_scale_formulas.Rd` describe the formula.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, and `docs/dev-log/general-sd-regression/inventory.md` record the narrow support boundary.
- `vignettes/predictor-dependent-random-sd.Rmd` adds the synthetic example with a non-invariant interleaved covariance order; `vignettes/formula-grammar.Rmd` updates the animal-model row.
- `.unlazy/general-sd-regression/GATES.md`, `docs/dev-log/check-log.md`, `docs/dev-log/check-log.d/2026-10-20-poisson-animal-sd-regression.md`, `LOOP/lanes/general-sd-regression/checkpoint.md`, and this report record progress.

## 5. Checks Run

- Test-first red: the new test reached the expected error that Poisson did not support `sd_animal(id)`.
- Final focused test: 11 assertions passed with no warnings, failures, or skips.
- Combined test command `devtools::test(filter = "poisson-animal-sd-regression|binomial-animal-sd-regression|poisson-relmat-sd-regression|sd-level-grammar")`: 74 passed, 0 failed, 0 skipped, 1 existing warning from the `sd_phylo()` deprecation-throttle test. The live Julia engine did not run.
- `devtools::document()`: passed.
- Source-loaded render of `vignettes/predictor-dependent-random-sd.Rmd`: passed at `/private/tmp/predictor-dependent-random-sd-20261020-poisson-animal-review.html`; Pandoc reported its existing `--mathjax` deprecation.
- `pkgdown::check_pkgdown()`: no problems found; existing Pandoc `--mathml` warnings remain.
- `pkgdown::build_site()` could not fetch CRAN metadata and lacked permission to write the user-level Sass cache. The documentation assertions themselves passed.
- `graft build`: refreshed the local graph after the review repair, with 29,638 nodes and 58,161 edges.
- Scoped `git diff --check` passed. The new test file has no trailing whitespace and ends with a newline. The prose check reported zero em dashes for the after-task report, check-log entry, formula guide, model design guide, inventory, vignette, and NEWS; legacy style-pattern hits remain elsewhere in those long files.
- The required numbered report structure passed. The full after-task checker returned nonzero because the shared general-SD acceptance ledger still has 11 open gates across other families and engine routes; this partial Poisson cell does not close them.

## 6. Tests of the Tests

The unsupported-parameter red run showed the test reached the intended missing builder admission. The first 64-group simulation did not recover its modest slope; the final fixed-seed design uses 192 groups and 24 observations per group, retaining the slope of 0.35 and the 0.25 absolute-error threshold. The test uses an interleaved permutation that changes the covariance matrix numerically, so it exercises dimname alignment. It also checks group-SD predictions, simulation, save/reload, and constant-SD likelihood equivalence.

## 7a. Issue Ledger

A read-only GitHub search found no matching open issue for animal-model SD regression. No issue was created, commented on, or closed.

## 8. Consistency Audit

The public target is consistently `sd_animal(id)`, and the documented covariance is `D A D`. The formula requires complete, non-inflated Poisson data, supplied `A`, and one q1 intercept. Independent math review found no equation-to-code mismatch; it identified the reversal-invariant test permutation, which has now been replaced. The Poisson missing-predictor hint now refers to structured SD regression. The exact inventory command was:

```sh
rg -n 'animal.*(direct-SD|SD regression|scale formula|random-effect SD)|direct-SD.*animal|animal.*predictor-dependent SD|animal model.*SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The separate Poisson scan was `rg -n 'Poisson.*(animal|structured)|animal.*Poisson' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml`. README and pkgdown navigation had no applicable entry to update.

## 9. What Did Not Go Smoothly

The first render loaded an installed package from another worktree and failed on its older Bernoulli support. Loading the current source checkout explicitly fixed that. The full site build remained blocked by the unavailable CRAN DNS lookup and user-level cache permission.

## 10. Known Residuals

This report covers the supplied-`A` Poisson animal q1 point-recovery cell. A separate after-task report now records the `Ainv` precision-input test. Neither cell establishes pedigree-built inputs, animal slopes or blocks, other families, Julia parity, interval calibration, or general structured-effect support. Programme gates G3, G4, G6, G7, and G8 remain open or partial; coverage calibration remains deferred by the approved goal.

## 11. Team Learning

Structured-provider extensions should test covariance name alignment independently of row order. A low-information recovery fixture should be sized up while retaining the planned parameter value, instead of making the simulated effect stronger to pass.

## 12. Cross-Product Coverage

This implementation exercises native R/TMB Poisson with standard Laplace fitting and complete predictor data. It does NOT cover Julia, cross-engine parity, REML, penalized fits, missing-predictor handling, pedigree-built inputs, other animal providers, interval calibration, or broader family coverage. The separate DRM.jl source owner still controls that checkout. Continue with the next required row in the ledger; the general-SD goal remains active.
