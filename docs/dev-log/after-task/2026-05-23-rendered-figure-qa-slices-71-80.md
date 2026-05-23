# After Task: Rendered Figure QA Slices 71-80

## Goal

Continue the rendered-figure QA sequence through slice 80 by auditing and
repairing the `simulation-plot-grammar` article. This page is where future
simulation reports learn their visual grammar, so the work focused on keeping
replicate grain, aggregate Monte Carlo uncertainty, readiness summaries, and
failure ledgers visually distinct.

## Implemented

Started `codex/rendered-figure-qa-71-80` from updated `origin/main`.

The article now references six rendered figures:

- `bias-display`
- `rmse-display`
- `coverage-power-display`
- `fit-status-display`
- `runtime-display`
- `failure-ledger-display`

The previous combined accuracy chunk now has a hidden fixture-data chunk plus
separate bias and RMSE plots. This gives each rendered image its own caption
and alt text. Bias remains a replicate-level signed-error display with
mean-bias MCSE intervals; RMSE remains an aggregate point-and-MCSE display.

The previous mixed readiness figure now becomes two plots. Fit-status
proportions use a 0-1 axis with a dotted 1.0 reference line. Runtime summaries
use a seconds axis for median and 90th percentile elapsed time. Coverage/power
and failure-ledger figures kept their previous case-appropriate grammar.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
the rendered PNGs; Fisher checked uncertainty provenance and data grain; Curie
checked simulation-report semantics; Pat checked whether an applied reader can
decode the figures; Grace checked rendering and alt text; Rose checked for
one-rule-fits-all drift. These were role perspectives, not running agents.

## Mathematical Contract

No likelihood, formula grammar, optimizer, simulation runner, extractor,
interval method, or exported plotting helper changed.

The figure grammar is:

- bias: sampled replicate-level signed errors plus aggregate mean and 95% MCSE;
- RMSE: aggregate root-mean-square error plus 95% RMSE MCSE;
- coverage and power: replicate-block proportions plus aggregate binomial MCSE;
- fit status: convergence and `pdHess` proportions without uncertainty
  geometry;
- runtime: median and high-quantile elapsed seconds without uncertainty
  geometry; and
- failure ledger: status counts as the data.

## Files Changed

- `vignettes/simulation-plot-grammar.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`
- `docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-71-80.md`
- `docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-71-80.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
git switch -c codex/rendered-figure-qa-71-80 origin/main
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('simulation-plot-grammar', new_process = FALSE, quiet = TRUE)"
Rscript -e "html <- paste(readLines('pkgdown-site/articles/simulation-plot-grammar.html', warn = FALSE), collapse = '\n'); m <- gregexpr('<img[^>]+src=\"simulation-plot-grammar_files/figure-html/[^\"]+\"[^>]*>', html, perl = TRUE); imgs <- regmatches(html, m)[[1]]; if (identical(imgs, character(0))) imgs <- character(); missing <- imgs[!grepl('alt=\"[^\"]+', imgs)]; cat(length(imgs), 'article images,', length(missing), 'missing alt text\n')"
air format vignettes/simulation-plot-grammar.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-71-80.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-71-80.md docs/dev-log/check-log.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
```

The `simulation-plot-grammar` article rebuilt successfully. Article-image
alt-text inspection found 6 referenced article images and 0 missing alt
attributes. The six referenced PNGs were inspected directly. `git diff --check`
was clean. `pkgdown::check_pkgdown()` reported no problems.
`devtools::build_vignettes()` completed successfully and rebuilt the edited
article under the ordinary vignette build.

## Consistency Audit

The case-by-case figure rule still holds. Simulation operating-characteristic
plots are not Confidence Eyes. They show replicate or replicate-block evidence
where available, aggregate summaries where that is the estimand, and named
Monte Carlo uncertainty only when the fixture provides it. Readiness and
failure figures do not invent intervals.

## Known Limitations

The article is still a fixture-backed display contract. It does not claim that
the Phase 18 simulation engine already emits every column shown here, and it
does not export a simulation plotting helper. Helper extraction should wait
until production result schemas stabilize.

## Next Actions

Continue the rendered-figure sweep beyond slice 80. The next set should return
to article pages that still have rendered figures but no per-figure audit note,
or to prose-only pages whose current visual burden is zero but whose status
claims can drift.
