# After Task: Slice 97 Proportion Source-Map Tutorial

## Goal

Add the next non-Gaussian worked example after Slice 96, using implemented
fixed-effect bounded-response paths only. The tutorial needed to separate
successes out of trials from strict continuous proportions, define denominator
and boundary rules before syntax, translate public `sigma` to beta precision
`phi`, and keep exact 0/1 continuous outcomes in planned status.

## Implemented

- Added `vignettes/proportion-beta-binomial.Rmd` as a new tutorial page.
- Added pkgdown navigation and article registration for "Proportions and
  success rates".
- Added a seed-germination beta-binomial simulation with treatment, moisture,
  known trial totals, successes, and failures.
- Fitted a fixed-effect beta-binomial model with
  `bf(cbind(germinated, failed) ~ treatment + moisture, sigma ~ treatment)`.
- Added a strict continuous vegetation-cover beta simulation and fitted
  `bf(cover ~ grazing + moisture, sigma ~ grazing)`.
- Defined `mu`, `sigma`, `phi`, trials, successes, failures, and strict beta
  boundaries before interpretation.
- Added beta-binomial and beta variance equations on the public `sigma` scale.
- Added `sigma` and precision ratios:
  `exp(gamma_1)` and `exp(-2 * gamma_1)`.
- Added response-scale prediction tables for expected germination probability,
  expected successes, `sigma`, `phi`, and proportion or cover SD.
- Linked the tutorial from Getting Started, the model map, the family guide,
  the implemented source map, the worked-example inventory, the tutorial-style
  contract, the pkgdown navigation, and the roadmap.
- Recorded the slice in `docs/dev-log/check-log.md`.

## Source Evidence Read

- `/Users/z3437171/Desktop/Methods Ecol Evol - 2025 - Nakagawa - Location scale models in ecology and evolution Heteroscedasticity in continuous .pdf`
- `pdfinfo` confirmed the paper metadata as Methods in Ecology and Evolution
  2026, volume 17, pages 554-566.
- Extracted source evidence with `pdftotext`.
- Source anchors used: discrete proportions as successes out of trials,
  seedling emergence, infection prevalence, continuous proportions such as
  leaf-area loss, percent cover, foraging-time fractions, beta-binomial
  overdispersion, beta regression for continuous `(0, 1)` rates, and exact
  0/1 values requiring explicit boundary processes.

## Checks Run

- `air format _pkgdown.yml ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-97-proportion-source-map.md vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/proportion-beta-binomial.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'devtools::test(filter = "beta|family-link-contract", reporter = "summary")'`:
  passed; ran the beta-binomial, beta-location-scale, and family-link-contract
  test files with no failures.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered
  `articles/proportion-beta-binomial.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- Source and rendered scans confirmed the tutorial route, scale conversion,
  strict beta wording, denominator syntax, and unsupported-boundary wording in
  `vignettes/proportion-beta-binomial.Rmd`,
  `pkgdown-site/articles/proportion-beta-binomial.html`, `_pkgdown.yml`, the
  article index, the family guide, Getting Started, the model map, the source
  map, the worked-example inventory, and the roadmap.
- Boundary scans confirmed that zero-one-inflated beta, ordered beta,
  beta-binomial zero inflation, known covariance, `phylo()`, `spatial()`, mixed
  beta-Gaussian families, and `successes / trials` denominator shorthand are
  all presented as planned or unsupported neighbours, not fitted syntax.
- Tracked-diff and new-file non-ASCII scans with
  `LC_ALL=C rg -n '[^\\x00-\\x7F]'`: returned no matches.

## Tests Of The Tests

This slice did not add new tests because it did not add implementation. Curie
treated the existing beta and beta-binomial tests as the implementation
guardrail and reran the focused beta, beta-binomial, and family-link-contract
tests.

The tutorial itself is also an executable check: `pkgdown::build_site()`
rendered the article, fitted both bounded-response examples, and printed clean
`check_drm()` rows before the slice was treated as ready.

## Consistency Audit

No formula grammar, family registry, likelihood parameterization, extractor, or
TMB code changed. The source map now points beta and beta-binomial rows to the
new tutorial, while the roadmap and worked-example inventory state that the
example is fixed-effect and univariate. Continuous exact 0/1 responses,
beta-binomial zero inflation, non-Gaussian random effects, structured bounded
responses, known covariance with bounded responses, mixed-response families,
and denominator shorthand remain planned.

## Standing Review Notes

- Ada: kept Slice 97 documentation-only; no formula grammar, family,
  likelihood, extractor, or TMB implementation changed.
- Gauss: the public `sigma` equation matches the implemented beta and
  beta-binomial paths: `phi = 1 / sigma^2`.
- Noether: the tutorial explicitly translates from native precision `phi` to
  public `sigma`, avoiding a direction reversal in interpretation.
- Darwin: the seed-germination and vegetation-cover examples separate
  denominator-aware success rates from continuous bounded cover.
- Pat: the route table appears before fitted code, so a new user can decide
  between `beta_binomial()` and `beta()` before seeing model syntax.
- Curie: focused beta, beta-binomial, and family-link-contract tests passed
  after the documentation edits.
- Grace: pkgdown build and pkgdown checks passed with the new article in the
  Tutorials menu.
- Rose: unsupported neighbours remain visible: exact 0/1 continuous beta
  outcomes, zero-one-inflated beta, ordered beta, beta-binomial zero inflation,
  non-Gaussian random effects, structured bounded responses, mixed-response
  models, known covariance, and denominator shorthand.

## What Did Not Go Smoothly

The first combined patch failed because one `model-map.Rmd` context line did
not match the current file. Splitting the edit into smaller patches fixed the
workflow without changing the scope. Validation itself was straightforward
after the smaller patches landed.

## Team Learning

Ada should keep bounded-response teaching tied to the measurement process
before showing syntax. Noether should continue forcing precision-like paper
parameters such as `phi` through the public `sigma` contract before prose is
finalized. Rose should check boundary wording early, because exact 0/1 values
are easy to accidentally imply as supported by strict beta syntax.

## Known Limitations

This slice does not make any new bounded-response model work. It teaches only
implemented fixed-effect univariate `beta_binomial()` and `beta()` paths.
Random effects, `sd(group) ~ ...`, phylogenetic or spatial bounded responses,
bivariate or mixed-response bounded models, known covariance with bounded
responses, zero-one-inflated beta, ordered beta, beta-binomial zero inflation,
and denominator shorthand remain planned until they have likelihood code,
simulation recovery, diagnostics, documentation, and source-map evidence.

## Next Actions

1. Open the Slice 97 PR and let GitHub Actions run.
2. If CI passes, merge the documentation-only slice.
3. Choose the next worked-example lane deliberately; the inventory now points
   to a compact bivariate group-level covariance example or a later
   benchmark-backed large-data article rather than another proportion example.
