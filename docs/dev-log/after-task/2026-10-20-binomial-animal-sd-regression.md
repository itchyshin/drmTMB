# After Task: Native Bernoulli animal-model SD regression

## 1. Goal

Add predictor-dependent SDs for one native Bernoulli animal-model intercept,
while retaining the full cross-family, cross-effect, two-engine programme as
the active goal.

## 2. Implemented

`sd(id, level = "animal") ~ z` now maps to the distinct public dpar
`sd_animal(id)`. The native Binomial builder admits one unlabelled q1
`animal(1 | id, A = A)` location intercept and reuses the existing structured
known-precision likelihood and SD design path.

## 3a. Decisions and Rejected Alternatives

For the supplied relationship matrix `A`, the structured latent covariance is
`D A D`, where `D` contains group-specific SDs `exp(W alpha)`. This retains the
existing matrix scale. Each right-hand predictor must be constant within the
retained animal ID. No Bernoulli residual `sigma` is introduced. I reused the
common structured known-precision SD machinery rather than adding an
animal-specific likelihood path. Pedigree and inverse-relatedness inputs
remain outside the checked slice.

## 4. Files Touched

- `R/parse-formula.R`, `R/drmTMB.R`, and `R/methods.R`
- `tests/testthat/test-binomial-animal-sd-regression.R` and
  `tests/testthat/test-sd-level-grammar.R`
- `R/random-effect-scale-formulas.R` and `man/random_effect_scale_formulas.Rd`
- `docs/design/01-formula-grammar.md` and
  `docs/design/18-random-effect-scale-models.md`
- `vignettes/predictor-dependent-random-sd.Rmd` and
  `vignettes/formula-grammar.Rmd`
- `NEWS.md`, `docs/dev-log/known-limitations.md`,
  `docs/dev-log/internal-roadmap.md`, and
  `docs/dev-log/general-sd-regression/inventory.md`
- `.unlazy/general-sd-regression/GATES.md`,
  `docs/dev-log/check-log.md`, its dated detail file, the recovery checkpoint,
  and this report

## 5. Checks Run

- The focused test failed first at the planned animal-level parser rejection.
  After implementation, the animal test passed all 12 assertions.
- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
  Rscript -e 'devtools::test(filter =
  "binomial-animal-sd-regression|sd-level-grammar|binomial-relmat-sd|binomial-phylo-sd-regression")'`:
  79 passed, 0 failed, 0 skipped, 1 warning. The warning is from the existing
  legacy `sd_phylo()` deprecation-throttle test.
- `Rscript -e 'devtools::document()'`: passed and regenerated the random-effect
  scale reference.
- Source-loaded render of
  `vignettes/predictor-dependent-random-sd.Rmd` to
  `/private/tmp/predictor-dependent-random-sd-20261020-animal.html`: output
  file created. Pandoc reported its existing deprecated `--mathjax` option.
- `Rscript -e 'pkgdown::check_pkgdown()'`: no problems found. Pandoc emitted
  existing `--mathml` deprecation warnings.
- Global `git diff --check` found a trailing blank line at EOF in the unrelated
  pre-existing dirty file `tests/testthat/test-binomial-sd-integration.R`.
  I left it untouched. A scoped check over this slice's tracked files passes.
- `slop_check.py` passed on the after-task report, detailed check log, NEWS,
  public vignette, and formula reference. The task-specific inventory scan
  found no stale animal-SD claim in README or pkgdown navigation.
- `graft build` refreshed the local graph: 29,636 nodes, 58,157 edges, and
  4,172 source cards.
- The after-task structure validator passed, then its global acceptance check
  returned 1 because the programme gates remain open. This slice is partial
  evidence within the active goal, not an overall closeout.

## 6. Tests of the Tests

The test-first red result reached the parser's explicit planned-feature error.
The passing test then exercised a fixed-seed nonzero SD slope, public target
names, profile-target metadata, save/reload, group-level predictions, marginal
binary simulation, and likelihood equivalence against the base constant-SD
fit. A negative case changes `z` for one observation within an animal ID and
checks that fitting rejects it.

## 8. Consistency Audit

The parser emits `sd_animal(id)`, the family builder matches it to an `animal`
provider, the common structured SD builder aligns design rows to provider
levels, and the public prediction and simulation checks pass. The docs describe
the same `D A D` model and distinguish this one cell from full animal or engine
parity. Inventory searches included:

```sh
rg -n 'animal.*(direct-SD|SD regression|scale formula|random-effect SD)|direct-SD.*animal|animal.*predictor-dependent SD|animal model.*SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

No README or pkgdown navigation entry matched; no navigation change was needed.

## 7a. Issue Ledger

A read-only search of open `itchyshin/drmTMB` issues returned no clearly
matching animal-model SD issue among the relevant results. No issue was
created, commented on, or closed.

## 9. What Did Not Go Smoothly

The first integrated run found a stale reverse-map variable in the legacy
phylogenetic selector error path. The grammar test exposed it; it now reads
from the current shared map. The focused suite still reports one warning from
the older lifecycle-throttle test, even though its assertions pass.

## 11. Team Learning

When extending a structured SD provider, preserve the provider name in the
public dpar while reusing common covariance assembly. Exercise parser aliases,
target extraction, prediction and simulation in the same synthetic test.

## 10. Known Residuals

Only one native Bernoulli q1 animal intercept with supplied `A` was fitted.
Pedigree and inverse-relatedness variants under predictor-dependent SDs,
animal slopes, other families, Julia parity, profile/bootstrap refitting,
calibrated intervals, and programme-wide support remain open. G3, G4, G6, G7,
and G8 remain partial or unmet.

## 12. Cross-Product Coverage

This verifies one native R/TMB Bernoulli q1 animal intercept with supplied `A`,
profile-target metadata, save/reload, public outputs, and a rendered synthetic
tutorial. It does NOT cover
Julia, pedigree or A-inverse variants, other responses or effect shapes,
profile/bootstrap refitting, calibrated intervals, or programme completion.

## 13. Prose Assessment

The report uses short, concrete claims. The model, tests, source state, and
documentation were checked against local evidence; no external citation is
needed for this implementation report. Formal style review: 2/10 perceived
AI-like style, medium confidence. Science, facts, and references were checked
against the local model contract and tests.

Next action: continue the required-family/provider/effect/backend ledger and
coordinate Julia animal work with its current source owner before editing the
paired DRM.jl files.
