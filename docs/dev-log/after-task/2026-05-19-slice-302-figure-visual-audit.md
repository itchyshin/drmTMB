# After Task: Slice 302 Figure Visual Audit

## Goal

Recheck the rendered figures after Florence, Pat, and Rose flagged that the
simulation graphics still looked inconsistent and under-polished.

## Implemented

- Rendered the current figure gallery, simulation plot grammar article, and
  Phase 18 count-pilot gallery to `/tmp/drmtmb-visual-audit`.
- Built and inspected full contact sheets covering 29 rendered PNGs: 21 figure
  gallery figures, 5 simulation grammar figures, and 3 count gallery figures.
- Shortened shape/inflation/rho12 facet labels so they no longer clip.
- Changed raincloud wording from replicate estimates to replicate errors and
  changed the bias axis to `Estimate minus truth` where replicate-level errors
  are shown.
- Standardized `Continuous` to `Gaussian location-scale` in the simulation
  grammar fixtures and wrapped that facet label.
- Redrew the count coverage display as horizontal empirical coverage panels,
  with term labels such as `z slope`, `x random-slope SD`, and `intercept SD`.
- Kept count bias and RMSE aggregate-only, while making their legends and
  captions explicit about MCSE bars and the absence of replicate-level clouds.
- Revised the empirical marginal `mu` gallery panel so it no longer appears as
  an under-finished point-only display: the plot now shows plug-in marginal
  means plus averaged row-wise Wald prediction limits, with the approximation
  named in the prose and caption.

## Files Changed

- `vignettes/figure-gallery.Rmd`
- `vignettes/simulation-plot-grammar.Rmd`
- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/reports/phase18-count-mu-gallery.Rmd vignettes/figure-gallery.Rmd vignettes/simulation-plot-grammar.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-visual-audit/current-figure', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-visual-audit/followup-figure', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "rmarkdown::render('vignettes/simulation-plot-grammar.Rmd', output_dir = '/tmp/drmtmb-visual-audit/current-sim', output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "devtools::load_all(quiet = TRUE); root <- normalizePath('.'); rmarkdown::render('inst/sim/reports/phase18-count-mu-gallery.Rmd', output_dir = '/tmp/drmtmb-visual-audit/count-fixed', params = list(aggregate_csv = file.path(root, 'inst/sim/results/slice-257-count-gallery-polished/gallery/count-mu-aggregate.csv'), coverage_csv = file.path(root, 'inst/sim/results/slice-257-count-gallery-polished/gallery/count-mu-coverage.csv'), manifest_csv = file.path(root, 'inst/sim/results/slice-257-count-gallery-polished/gallery/count-mu-manifest.csv'), failures_csv = file.path(root, 'inst/sim/results/slice-257-count-gallery-polished/gallery/count-mu-failures.csv'), notes = 'Slice 302 visual audit re-render'), output_options = list(self_contained = FALSE), quiet = TRUE)"
Rscript -e "devtools::test(filter = '^phase18-count-gallery')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

## Visual Evidence

The inspected contact sheets are local artifacts under
`/tmp/drmtmb-visual-audit/sheets-current-full/`:

- `figure-gallery-current-01.png`
- `figure-gallery-current-02.png`
- `figure-gallery-current-03.png`
- `simulation-plot-grammar-current.png`
- `count-gallery-current.png`

The final count coverage PNG was also inspected directly to confirm the
`sigma:z` term is labelled `z slope`.

The follow-up empirical marginal `mu` PNG was inspected directly to confirm
that the interval display is visible and labelled as an approximation rather
than formal marginal-mean uncertainty.

Focused count-gallery tests passed with 41 tests, 0 failures, 0 warnings, and
0 skips. `pkgdown::check_pkgdown()` passed with no problems.

## Team Learning

Ada kept the audit scoped to rendered figures and figure-source fixes. Florence
treated clipping, legend glyphs, facet labels, and uncertainty grammar as real
review gates. Fisher kept bias, RMSE, and coverage visually separate. Pat
checked whether a new reader could decode the labels without raw formula
strings. Grace kept all changed sources renderable. Rose caught the stale
wording and the misleading count coverage label before closeout. No spawned
subagents were used.

## Known Limitations

This slice does not add the replicate-level result artifacts needed for true
count-gallery rainclouds. The count gallery still reports aggregate bias and
RMSE until the issue #255 schema work supplies replicate-level errors.

The empirical marginal `mu` interval bars are averaged row-wise Wald prediction
limits. They are suitable as a gallery display of uncertainty, but they are not
a dedicated covariance estimator for empirical marginal means.
