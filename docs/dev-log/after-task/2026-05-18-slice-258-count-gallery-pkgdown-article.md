# Slice 258 Count Gallery Pkgdown Article

## Goal

Make the new count-pilot gallery discoverable on pkgdown and explain how to
interpret it without over-claiming final simulation evidence.

## Implemented

- Added `vignettes/phase18-count-gallery.Rmd`.
- Added the article to the Developer Notes navbar and pkgdown article index.
- Explained the paired Poisson/NB2 `mu` random-effect pilot scope, including
  what the gallery does not cover.
- Added a local rendering workflow for the ignored `inst/sim/results/` output
  folder.
- Explained the bias, RMSE, coverage, manifest, and warning/error-ledger panels
  from a reader-first perspective.
- Updated the visualization grammar, Phase 18 simulation blueprint, roadmap,
  NEWS, and check log.

## Files Changed

- `vignettes/phase18-count-gallery.Rmd`
- `_pkgdown.yml`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format vignettes/phase18-count-gallery.Rmd _pkgdown.yml docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md`
- `Rscript -e "rmarkdown::render('vignettes/phase18-count-gallery.Rmd', output_dir = tempfile('phase18-count-gallery-article-'), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Prose Review

Pat's reader is an applied ecology/evolution user or package contributor who
can read `drmTMB` syntax but should not need to know the `inst/sim/` internals.
Rose checked that the article says "pilot" where evidence is pilot-only and
does not advertise planned non-Gaussian, structured, shape, inflation, or
hurdle random-effect surfaces as fitted.

## Consistency Audit

The article uses stable terms: `mu`, `sigma`, `meta_V(V = V)` only when naming
future sibling surfaces, and ordinary grouped random effects for the count
pilot. It keeps planned surfaces in the failure-ledger pathway rather than
mixing them into ready simulation claims.

## Known Limitations

The article is developer-facing. It does not embed the generated local HTML
gallery, add alt text for every future figure, or render a large simulation
grid.

## Next Actions

After the count-gallery slices merge, build the pkgdown site and inspect the
article in context with the count tutorial and testing-likelihoods guide.
