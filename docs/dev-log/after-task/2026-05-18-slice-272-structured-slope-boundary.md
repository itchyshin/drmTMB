# After Task: Slice 272 Structured Slope Boundary Audit

## Goal

Clarify the structured random-slope boundary before Phase 18 simulations: spatial
one-slope Gaussian `mu` models are fitted, while phylogenetic, animal, and
`relmat()` one-slope paths remain planned unless they have likelihood,
diagnostic, interval, and recovery-test evidence.

## Implemented

- Added parser tests showing that `drm_formula()` captures one numeric
  `animal()` and `relmat()` slope marker, preserves the coefficient name, and
  rejects multiple structured slopes.
- Added Gaussian fit-time boundary tests confirming one-slope `animal()` and
  `relmat()` requests still error before fitting.
- Updated the formula grammar, formula-grammar article, structured-slope parity
  gate, cross-parameter correlation gate, readiness matrix, roadmap, and NEWS so
  parser support is not mistaken for a fitted likelihood.

## Mathematical Contract

The fitted coordinate-spatial one-slope path remains:

```text
eta_mu,ij = X_ij beta + z0_j + x_ij z1_j
z0 ~ MVN(0, sd0^2 K_coords)
z1 ~ MVN(0, sd1^2 K_coords)
cov(z0, z1) = 0
```

Slice 272 does not add the analogous phylogenetic, animal-model, or `relmat()`
likelihood. Those markers are parser-readable planned syntax only.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/44-structured-slope-parity-gate.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-272-structured-slope-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-191359-codex-checkpoint.md`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-package-skeleton.R`
- `vignettes/formula-grammar.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/44-structured-slope-parity-gate.md docs/design/45-cross-dpar-correlation-gate.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-272-structured-slope-boundary.md docs/dev-log/recovery-checkpoints/2026-05-18-191359-codex-checkpoint.md tests/testthat/test-package-skeleton.R tests/testthat/test-gaussian-location-scale.R vignettes/formula-grammar.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = 'package-skeleton|gaussian-location-scale|phylo-gaussian|spatial-gaussian', reporter = 'summary')"`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/formula-grammar.Rmd", output_dir = tempfile("formula-grammar-render-"), quiet = FALSE)'`:
  passed and rendered the article.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'Slice 272|animal\(1 \+ x|relmat\(1 \+ x|Structured random-slope boundaries|parser-boundary|parser checks|planned marker grammar|Coordinate spatial|multiple structured slopes' NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/44-structured-slope-parity-gate.md docs/design/45-cross-dpar-correlation-gate.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/formula-grammar.Rmd tests/testthat/test-package-skeleton.R tests/testthat/test-gaussian-location-scale.R`:
  confirmed source and test references for the Slice 272 contract.
- `rg -n 'animal.*one-slope.*implemented|relmat.*one-slope.*implemented|animal.*slope.*fitted|relmat.*slope.*fitted|phylogenetic.*slope.*fitted|spatial.*slope correlations.*implemented|structured.*slope correlations.*implemented' README.md ROADMAP.md NEWS.md docs/design vignettes tests/testthat --glob '!docs/dev-log/**'`:
  returned expected planned, contrast, or prior boundary rows; it did not find a
  fitted animal or `relmat()` slope claim.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 272 structured random-slope boundary" --next "append check-log and after-task report, then stage, commit, push, and open draft PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-18-191359-codex-checkpoint.md`.

## Tests Of The Tests

The new parser checks would fail if `animal()` or `relmat()` one-slope markers
lost their coefficient names, labels, structure kind, or object names. The
multi-slope error checks would fail if the parser accidentally accepted two
structured slopes. The Gaussian fit-time checks would fail if planned
`animal()` or `relmat()` marker syntax silently entered the fitted likelihood.

## Consistency Audit

Ada kept the slice scoped to boundary evidence rather than likelihood work.
Boole checked that the public formula grammar and parser tests say the same
thing. Fisher kept Phase 18 admission limited to fitted coordinate-spatial
one-slope models. Pat checked the formula-grammar article for a concrete "what
is still planned" path. Grace covered focused tests, article rendering,
pkgdown, and diff hygiene. Rose checked stale wording so parser support does not
become a false implementation claim.

## What Did Not Go Smoothly

One early shell scan used backticks inside a double-quoted pattern, so zsh tried
to execute `animal()` and `relmat()` as commands. I reran the scan with
single-quoted patterns and recorded the corrected command.

## Known Limitations

- No phylogenetic, animal, or `relmat()` one-slope likelihood was added.
- No structured slope correlation, predictor-dependent structured slope
  correlation, bivariate structured slope block, or spatial q=4 block was added.
- Future animal and `relmat()` work still needs row-name validation, covariance
  or precision scale decisions, diagnostics, profile targets, examples, and
  simulation recovery.

## Next Actions

Slice 273 should audit bivariate random-slope combinations by response and
location-scale pairing, keeping q=4 and block-diagonal gaps explicit before
Phase 18 admits bivariate slope grids.
