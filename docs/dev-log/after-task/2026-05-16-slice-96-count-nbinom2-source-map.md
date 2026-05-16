# After Task: Slice 96 Count NB2 Source-Map Tutorial

## Goal

Add the first non-Gaussian worked count example after the `0.1.2` release gate,
using implemented fixed-effect NB2 and zero-inflated NB2 paths only. The
tutorial needed equation, exact syntax, parameter definitions, biological
interpretation, diagnostics, and unsupported-boundary text.

## Implemented

- Added `vignettes/count-nbinom2.Rmd` as a new tutorial page.
- Added pkgdown navigation and article registration for "Count abundance and
  extra zeros".
- Added a soil-invertebrate simulation with trap effort, habitat, moisture,
  surface type, extra-Poisson variation, and structural zeros.
- Fitted a fixed-effect NB2 baseline and a fixed-effect zero-inflated NB2 model
  using `zi ~ surface`.
- Defined `springtails`, `trap_nights`, `mu`, `sigma`, `size`, `theta`, `zi`,
  and the log-scale coefficients before interpretation.
- Added the NB2 variance equation,
  `Var(Y_i) = mu_i + sigma_i^2 * mu_i^2`, and the conversion
  `theta_i = 1 / sigma_i^2`.
- Added SD-scale, variance-scale, and theta-scale ratios:
  `exp(gamma_1)`, `exp(2 * gamma_1)`, and `exp(-2 * gamma_1)`.
- Added a zero-inflated NB2 equation and response-scale prediction table for
  conditional mean, `sigma`, structural-zero probability, unconditional mean,
  and unconditional variance.
- Linked the new tutorial from Getting Started, the model map, the family guide,
  the implemented source map, the worked-example inventory, and the roadmap.
- Recorded the slice in `docs/dev-log/check-log.md`.

## Source Evidence Read

- `/Users/z3437171/Desktop/Methods Ecol Evol - 2025 - Nakagawa - Location scale models in ecology and evolution Heteroscedasticity in continuous .pdf`
- Extracted source evidence with `pdftotext` because local `pdfplumber` was not
  installed.
- Source anchors used: count responses such as fledglings, insect colony size,
  parasites, and soil invertebrates; NB2 overdispersion; smaller native
  `theta` meaning more overdispersion; structural-zero examples in patchy soil
  invertebrate and parasite-count data; COM-Poisson kept for future
  underdispersion work.

## Checks Run

- `air format _pkgdown.yml ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md vignettes/count-nbinom2.Rmd vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'devtools::test(filter = "nbinom2|count-kernels|zi-poisson|poisson-mean")'`:
  passed with `FAIL 0 | WARN 0 | SKIP 0 | PASS 321`.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered
  `articles/count-nbinom2.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- Source and rendered scans confirmed the new tutorial route, `sigma`/`theta`
  conversion, structural-zero language, and unsupported-boundary text.

## Tests Of The Tests

This slice did not add new tests because it did not add implementation. Curie
treated the existing count tests as the implementation guardrail and reran the
NB2, count-kernel, zero-inflated Poisson, and Poisson mean tests that exercise
the fitted surfaces used by the tutorial.

The tutorial itself is an executable check: `pkgdown::build_site()` rendered
the article, fitted the NB2 and zero-inflated NB2 models, and printed clean
`check_drm()` rows before the slice was treated as ready for PR.

## Consistency Audit

No formula grammar, family registry, likelihood parameterization, extractor, or
TMB code changed. The source map still points NB2 and zero-inflated NB2 to the
existing implementation and tests. The roadmap and worked-example inventory now
state that the count example is fixed-effect and univariate, while
non-Gaussian random effects, structured count effects, mixed-response count
models, known covariance with counts, and COM-Poisson remain planned.

## Standing Review Notes

- Ada: kept Slice 96 documentation-only; no formula grammar, family,
  likelihood, extractor, or TMB implementation changed.
- Gauss: the public `sigma` equation matches the implemented NB2 path:
  `size = 1 / sigma^2` and `Var(Y) = mu + sigma^2 * mu^2`.
- Noether: the tutorial explicitly translates from native `theta` language to
  public `sigma` language, avoiding a sign reversal in interpretation.
- Darwin: the soil-invertebrate example gives a biological split between
  abundance, patchiness, and true absence.
- Pat: the parameter dictionary appears before fitted output, so a new user can
  read `mu`, `sigma`, and `zi` without guessing.
- Curie: targeted count tests passed and the transparent simulation yields
  clean `check_drm()` rows for both NB2 and zero-inflated NB2 fits.
- Grace: pkgdown build and pkgdown checks passed with the new article in the
  Tutorials menu.
- Rose: unsupported neighbours remain visible: non-Gaussian random effects,
  `sd(group) ~ ...`, known covariance with counts, structured count effects,
  bivariate or mixed-response count models, and COM-Poisson.

## What Did Not Go Smoothly

The local `pdfplumber` module was not installed, so Jason used `pdftotext` to
extract the count-section anchors from the uploaded paper. This was sufficient
for source grounding, but future paper-heavy slices should check extraction
tools before beginning.

## Team Learning

Ada should keep non-Gaussian examples tied to one fitted surface at a time.
Noether should continue forcing paper parameterizations such as `theta` through
the public `sigma` contract before prose is finalized. Rose should check the
unsupported-boundary paragraph early, because it prevents tutorial enthusiasm
from turning planned families into implied support.

## Known Limitations

This slice does not make any new count model work. It teaches only implemented
fixed-effect univariate NB2 and zero-inflated NB2 paths. Random effects,
phylogenetic/spatial count models, bivariate counts, mixed-response families,
known sampling covariance with counts, and COM-Poisson remain planned until
they have likelihood code, simulation recovery, diagnostics, documentation,
and source-map evidence.

## Next Actions

1. Open and merge the Slice 96 PR after CI passes.
2. Move to Slice 97: a proportion or beta-binomial example source map, using
   the same paper's count/proportion guidance and keeping 0/1 boundary cases
   visibly separate from implemented strict beta and beta-binomial paths.
