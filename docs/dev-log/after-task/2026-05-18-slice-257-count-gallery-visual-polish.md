# Slice 257 Count Gallery Visual Polish

## Goal

Give the first count-pilot gallery a Florence visual-polish pass so it reads
like an intentional simulation figure gallery rather than raw default output.

## Implemented

- Added shared gallery palette and theme helpers inside
  `inst/sim/reports/phase18-count-mu-gallery.Rmd`.
- Reworked bias and RMSE panels to use horizontal estimand labels, consistent
  family colours, parameter-class shapes, and captions that keep manifest and
  warning/error checks visible.
- Reworked coverage panels to use the same visual grammar and display
  approximate 95% Monte Carlo uncertainty ranges when `coverage_mcse` is
  available.
- Updated template tests to assert the visual-polish helpers and MCSE caption
  are present.
- Generated an ignored polished local gallery artifact at
  `inst/sim/results/slice-257-count-gallery-polished/gallery/phase18-count-mu-gallery.html`.
- Updated the visualization grammar, Phase 18 simulation blueprint, roadmap,
  NEWS, and check log.

## Files Changed

- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `tests/testthat/test-phase18-count-gallery-template.R`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/reports/phase18-count-mu-gallery.Rmd tests/testthat/test-phase18-count-gallery-template.R`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-template|phase18-count-gallery-smoke-runner|phase18-count-gallery-render-helper', reporter = 'summary')"`
- `Rscript -e 'devtools::load_all(\".\", quiet = TRUE); ...; out <- phase18_render_count_mu_re_gallery_smoke(output_dir = \"inst/sim/results/slice-257-count-gallery-polished\", overwrite = TRUE, notes = \"Slice 257 polished local gallery smoke\", template = \"inst/sim/reports/phase18-count-mu-gallery.Rmd\"); cat(out$gallery$output_file, \"\\n\")'`
- `rg -n "Slice 257 polished local gallery smoke|Root-mean-square error by estimand|Florence Checks" inst/sim/results/slice-257-count-gallery-polished/gallery/phase18-count-mu-gallery.html`
- `git diff --check`

## Tests Of The Tests

The render tests still build HTML from CSV inputs and from a tiny real paired
count pilot. The reader-facing template test now also checks that the
Florence-specific theme helper and MCSE language remain in the report.

## Consistency Audit

The gallery remains explicitly labelled as pilot evidence. The visual polish
improves readability but does not claim that the one-replicate smoke panels are
publication-ready operating-characteristic figures.

## Team Learning

Florence moved the template away from default diagnostic styling. Pat gets
readable horizontal labels. Fisher gets coverage MCSE ranges when available.
Grace kept the render path covered. Rose kept the pilot-versus-final boundary
in the captions and after-task note.

## Known Limitations

This slice improves the count-pilot gallery template but does not add a
pkgdown article, alt text, standalone exported image files, or a visual
snapshot test.

## Next Actions

Use the polished gallery on a larger count pilot once PRs 243-256 are merged,
then decide whether to promote the gallery into a pkgdown article.
