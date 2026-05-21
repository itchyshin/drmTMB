# After Task: Animal/Relmat Runnable Known-Matrix Examples

## Goal

Give applied users runnable examples for the fitted animal/`relmat()`
known-matrix routes, including the post-`0.1.3` matching bivariate q=2
location-covariance slice.

## Implemented

- Extended the structural-dependence article's simulated animal-model data so
  it has two measured traits, correlated known-matrix animal effects, correlated
  lower-level line effects, and residual `rho12`.
- Kept the existing univariate `animal(1 | individual, Ainv = Ainv)` example.
- Added a runnable matching labelled bivariate `animal(1 | p | individual,
  Ainv = Ainv)` example with `corpairs(level = "animal")` and filtered
  `check_drm()` output.
- Added a runnable matching labelled bivariate `relmat(1 | p | breeding_line,
  Q = Ginv)` example with `corpairs(level = "relmat")` and direct
  `profile_targets()` output.
- Updated the worked-example inventory and Phase 18 simulation programme to
  say examples exist and ADEMP sheets are now the next admission gate.

## Mathematical Contract

The runnable q=2 examples estimate latent location-location covariance from a
known matrix. The animal example uses individual additive relatedness through
`Ainv`; the `relmat()` example uses a lower-level line precision matrix `Ginv`.
Both examples keep residual `rho12` as a separate within-observation residual
correlation and keep `meta_V(V = V)` reserved for observation-level known
sampling covariance.

## Files Changed

- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/41-phase-18-simulation-programme.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian', reporter = 'summary')"
Rscript -e "devtools::check()"
git diff --check
```

The source-tree vignette render passed, `pkgdown::check_pkgdown()` reported no
problems, the focused `animal-relmat-gaussian` test passed, `git diff --check`
was clean, and `devtools::check()` finished with 0 errors, 0 warnings, and 0
notes.

## Tests Of The Tests

This slice is documentation-first, so the key test was rendering the actual
structural-dependence vignette against the source tree after adding executable
chunks. The focused `animal-relmat-gaussian` test still covers likelihood,
extractor, `corpairs()`, `summary()`, `profile_targets()`, and diagnostic
contracts for the same fitted surface.

## Consistency Audit

Rose scanned current example/status surfaces with:

```sh
rg -n 'Add small runnable animal|fitted example, diagnostics|known-matrix bivariate animal example|Planned relatedness siblings|relmat\(1 \| p \| line, Q = Ginv\).*not fitted|example.*next' docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md vignettes/phylogenetic-spatial.Rmd README.md ROADMAP.md NEWS.md
```

The remaining hits are historical roadmap rows or non-blocking prose that does
not claim the fitted examples are missing.

## GitHub Issue Maintenance

Issue #147 remains open. This slice improves the user-facing examples for
known-matrix animal/`relmat()` routes, but it does not close pedigree-to-Ainv
construction, structured slopes, `sigma`, q=4 location-scale blocks,
predictor-dependent `corpair()` regression, direct-SD grammar, or simulation
admission.

## What Did Not Go Smoothly

A first standalone render used the installed package instead of the source
tree and therefore saw old marker support. Grace reran the render through
`devtools::load_all()`, which is the right local evidence for an uninstalled
branch.

## Team Learning

- Ada: example slices should close the user's copy-paste path before starting
  the next modelling lane.
- Pat and Darwin: the article is more useful when `animal()`, `relmat()`,
  residual `rho12`, and `meta_V(V = V)` are separated in the same small story.
- Boole: matching label `p` is visible enough in a runnable example to teach
  the q=2 covariance grammar.
- Curie and Fisher: examples should show the evidence functions users need
  next, not just the model call.
- Grace: source-tree rendering plus R CMD check catches the important vignette
  risks for this slice.
- Rose: once examples exist, the simulation programme should point to ADEMP
  rather than asking for examples again.

These were role perspectives, not spawned agents.

## Known Limitations

The examples still require precomputed matrices. Pedigree-to-Ainv construction,
structured slopes, `sigma`, q=4 location-scale blocks, predictor-dependent
`corpair()` regression, and direct-SD grammar remain planned. The examples are
small tutorials, not speed or formal simulation evidence.

## Next Actions

1. Add ADEMP sheets for known-matrix animal and `relmat()` q=2 bivariate grids.
2. Decide whether pedigree-to-Ainv or structured slopes should be the next
   fitted implementation lane.
3. Keep gallery figures in mind: the correlation-layer figure still needs
   spatial/animal/`relmat()` rows now that the fitted subsets exist.
