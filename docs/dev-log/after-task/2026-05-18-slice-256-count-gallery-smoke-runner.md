# Slice 256 Count Gallery Smoke Runner

## Goal

Prove the first paired count-pilot figure gallery can be generated end to end
from a tiny real pilot run.

## Implemented

- Added `inst/sim/run/sim_render_count_mu_gallery_smoke.R`.
- Added `phase18_render_count_mu_re_gallery_smoke()` to run a tiny paired
  Poisson/NB2 `mu` random-effect pilot, write plot-ready gallery inputs, render
  the HTML gallery, and return pilot plus artifact paths together.
- Extended the gallery render helper to normalize relative output paths before
  rendering, so local folders such as `inst/sim/results/...` work.
- Normalized empty failure ledgers before writing gallery CSVs, keeping the
  warning/error table readable when a pilot has no warnings or errors.
- Added an end-to-end render test that fits the tiny paired pilot and checks
  the rendered HTML contains the run notes and Florence checks.
- Generated an ignored local gallery artifact at
  `inst/sim/results/slice-256-count-gallery-smoke/gallery/phase18-count-mu-gallery.html`.

## Files Changed

- `inst/sim/run/sim_render_count_mu_gallery_smoke.R`
- `tests/testthat/test-phase18-count-gallery-smoke-runner.R`
- `inst/sim/R/sim_gallery.R`
- `tests/testthat/test-phase18-count-gallery-render-helper.R`
- `inst/sim/README.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/run/sim_render_count_mu_gallery_smoke.R tests/testthat/test-phase18-count-gallery-smoke-runner.R inst/sim/README.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-smoke-runner|phase18-count-gallery-render-helper', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-smoke-runner|phase18-count-gallery-template|phase18-count-mu-random-effect-pilot', reporter = 'summary')"`
- `Rscript -e 'devtools::load_all(\".\", quiet = TRUE); ...; out <- phase18_render_count_mu_re_gallery_smoke(output_dir = \"inst/sim/results/slice-256-count-gallery-smoke\", overwrite = TRUE, notes = \"Slice 256 local gallery smoke\", template = \"inst/sim/reports/phase18-count-mu-gallery.Rmd\"); cat(out$gallery$output_file, \"\\n\")'`
- `rg -n "Slice 256 local gallery smoke|Florence Checks|Bias|RMSE|Interval Coverage" inst/sim/results/slice-256-count-gallery-smoke/gallery/phase18-count-mu-gallery.html`
- `git diff --check`

## Tests Of The Tests

The new smoke-runner test uses the same tiny Poisson/NB2 conditions as the
paired pilot smoke test, then renders the gallery rather than stopping at the
pilot object. The manual local render uses a relative `inst/sim/results/...`
folder, which caught and fixed the path-normalization and empty-failure-ledger
issues.

## Consistency Audit

The rendered gallery remains clearly labelled as a pilot. It includes bias,
RMSE, interval coverage, manifest, warning/error ledger, and Florence checks,
but it does not claim final operating characteristics or publication-ready
figures.

## Team Learning

Ada kept the runner tied to the existing paired pilot rather than creating a
second simulation path. Florence now has an actual local gallery file to judge.
Fisher gets the same pilot object and rendered artifact for cross-checking.
Pat gets a reader-facing HTML report. Grace found the relative-path and empty
failure-ledger hazards through the manual render. Rose recorded the boundary:
this is end-to-end gallery plumbing, not the final gallery article.

## Known Limitations

The local HTML artifact is ignored output, not a committed pkgdown article. The
figures are still basic `ggplot2` panels and need Florence's publication-theme
polish before they should be treated as exemplary user-facing figures.

## Next Actions

Polish the count gallery aesthetics and captions, then decide whether to make
the next Florence slice a pkgdown gallery article or broader simulation-figure
theme helper.
