# After Task: Rendered Figure QA Slices 61-70

## Goal

Continue the rendered-figure QA sequence through slice 70 by adding a
case-appropriate figure to the `large-data` article. The article now has public
interval-route guidance, so it needs a visual that helps users compare profile
engines without pretending runtime measurements are uncertainty intervals.

## Implemented

Merged PR #311 after CI was green, then started
`codex/rendered-figure-qa-61-70` from updated `origin/main`.

The `large-data` article now has one rendered benchmark timing figure:

- `large-data-profile-benchmark-timing`

The figure compares elapsed seconds for successful direct scalar profile
benchmarks across full `TMB::tmbprofile()`, endpoint, and endpoint multicore
engines. It uses the existing
`docs/dev-log/benchmarks/profile-scalar-endpoint-v2.csv` artifact and shows
points only because those rows are local timing measurements, not repeated-run
uncertainty estimates.

The rendered article checklist now records one active `large-data` figure. The
visualization grammar now includes an explicit benchmark-runtime rule: timing
figures should show elapsed time, peak memory, object size, or speedup directly
and should not use Confidence Eyes or interval geometry unless repeated
benchmark uncertainty actually exists.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
the rendered figure; Fisher checked data grain and uncertainty provenance; Pat
checked reader placement; Grace checked rendering, alt text, and package-site
readiness; Rose checked the repeated pattern so benchmark plots do not inherit
one-size-fits-all estimate-uncertainty styling. These were role perspectives,
not running agents.

## Mathematical Contract

No likelihood, formula grammar, optimizer, extractor, interval method, or
exported plotting helper changed.

The new figure is a performance display:

- x values are elapsed seconds from a benchmark artifact;
- rows are target and data-size scenarios;
- colours and shapes identify profile engines;
- no interval bar, ribbon, density cloud, or Confidence Eye is drawn; and
- the caption states that the points are performance measurements, not
  confidence intervals.

## Files Changed

- `vignettes/large-data.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`
- `docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-61-70.md`
- `docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-61-70.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
git fetch origin --prune
git switch -c codex/rendered-figure-qa-61-70 origin/main
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('large-data', new_process = FALSE, quiet = TRUE)"
Rscript -e "html <- paste(readLines('pkgdown-site/articles/large-data.html', warn = FALSE), collapse = '\n'); m <- gregexpr('<img[^>]+src=\"large-data_files/figure-html/[^\"]+\"[^>]*>', html, perl = TRUE); imgs <- regmatches(html, m)[[1]]; if (identical(imgs, character(0))) imgs <- character(); missing <- imgs[!grepl('alt=\"[^\"]+', imgs)]; cat(length(imgs), 'article images,', length(missing), 'missing alt text\n')"
air format vignettes/large-data.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-61-70.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-61-70.md docs/dev-log/check-log.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
```

The `large-data` article rebuilt successfully. Article-image alt-text
inspection found 1 referenced article image and 0 missing alt attributes.
`git diff --check` was clean. `pkgdown::check_pkgdown()` reported no problems.
`devtools::build_vignettes()` completed successfully and rebuilt the
`large-data-profile-benchmark-timing` chunk under the ordinary vignette build.

## Consistency Audit

The case-by-case figure rule still holds:

- benchmark timing displays use points, not Confidence Eyes;
- profile interval displays can use interval or compatibility geometry when
  the plotted object is an interval;
- simulation operating-characteristic plots should show replicate or aggregate
  Monte Carlo evidence; and
- raw response data should not be overplotted on timing, `sigma`, SD, or
  correlation axes.

## Known Limitations

The figure is not a new benchmark run. It visualizes the existing
`profile-scalar-endpoint-v2.csv` development artifact so article readers can see
the scale of the speedup claim with its local-evidence boundary.

The figure supports claims only for successful direct scalar targets in that
artifact. It does not claim a general speedup for fixed-effect profiles,
`newdata` profiles, derived targets, bootstrap, non-Gaussian models, bivariate
models, or untested hardware.

## Next Actions

Continue the rendered-figure sweep with slices 71-80. The next candidate is
`simulation-plot-grammar`, because it has multiple rendered figures where
replicate grain, MCSE intervals, and missing/not-targeted cells must stay
visibly distinct.
