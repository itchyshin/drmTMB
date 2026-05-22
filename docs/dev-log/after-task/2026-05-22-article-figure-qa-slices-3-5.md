# After Task: Article Figure QA Slices 3-5

## Purpose

Finish the first five-slice figure QA pass by merging the previous Confidence
Eye PR, starting from a fresh branch, and polishing captions plus reference
lines in `model-workflow`, `bivariate-coscale`, and
`simulation-plot-grammar`.

## Team Review

- Ada reset the branch surface after PR #297 merged and kept this slice focused
  on the next three article pages.
- Florence checked the rendered PNGs rather than relying on source changes
  alone.
- Fisher checked that captions name the right uncertainty source: Wald bands,
  90% or 95% Wald intervals, profile Confidence Eyes, Monte Carlo
  standard-error intervals, binomial MCSE intervals, or no interval where none
  is present.
- Pat checked whether a new applied reader can tell raw data, fitted parameter
  surfaces, correlation Confidence Eyes, simulation replicates, and
  operating-status counts apart.
- Darwin protected raw-data and simulation displays from being converted into
  Confidence Eyes when the biological or simulation grain is the main evidence.
- Grace rebuilt the articles, ran browser QA over a local static server, and
  checked pkgdown.
- Rose recorded the case-by-case rule so the team does not drift back into a
  universal Confidence Eye rule.

No spawned subagents ran.

## Changes

- Added five `model-workflow` captions for fitted `mu`/`sigma` surfaces, a
  habitat contrast, raw growth observations, and response-scale parameter
  ribbons.
- Added two `bivariate-coscale` captions, changed the `rho12` zero reference
  from dashed to dotted in both ggplot and base plotting paths, and changed the
  grouped `corpairs()` display from point-only to profile Confidence Eyes.
- Added the `confint(..., newdata = ...)` interval path for the intercept-only
  modelled `corpair()` row before plotting the grouped correlation display.
- Added four `simulation-plot-grammar` captions covering five rendered figures,
  including the two-output bias/RMSE chunk.
- Changed simulation bias and coverage/power reference lines from dashed to
  dotted where zero or target values are the visual anchor.
- Added the audit note at
  `docs/dev-log/audits/2026-05-22-article-figure-qa-slices-3-5.md`.

## Validation

```sh
air format vignettes/model-workflow.Rmd vignettes/bivariate-coscale.Rmd vignettes/simulation-plot-grammar.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); for (article in c('model-workflow','bivariate-coscale','simulation-plot-grammar')) pkgdown::build_article(article, new_process = FALSE, quiet = TRUE)"
python3 -m http.server 8473 --bind 127.0.0.1 -d pkgdown-site
gh issue list --search "figure caption pkgdown visualization" --limit 20
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Browser QA over `http://127.0.0.1:8473/` found:

| Article | Content images | Missing alt text | Captions |
| --- | ---: | ---: | ---: |
| `model-workflow` | 5 | 0 | 5 |
| `bivariate-coscale` | 2 | 0 | 2 |
| `simulation-plot-grammar` | 5 | 0 | 5 |

Florence visually inspected all 12 content PNGs for these three articles. The
figures were readable at the rendered size, the `rho12`, bias, coverage, and
power reference lines were dotted, the grouped `corpairs()` plot showed 95%
profile Confidence Eyes, and the simulation status plots were judged
appropriate as status/count displays rather than interval displays.
`pkgdown::check_pkgdown()` reported no problems and `git diff --check` was
clean.

## Consistency Audit

The edits are vignette-level figure captions and reference-line styles only.
They do not change formula grammar, likelihood parameterization, exported API,
or model scope. `rho12`, `sigma`, `mu`, and `corpairs()` terminology stayed
unchanged.

## Tests Of The Tests

This slice did not add tests. The validation target was rendered evidence:
article rebuilds, browser checks for captions and alt text, and direct PNG
inspection.

## What Did Not Go Smoothly

The rendered figure directories contain stale unnamed PNGs from previous
article builds. Browser QA counted images actually embedded in the article
HTML, so stale files on disk were not treated as content-image evidence.

## Team Learning And Process Improvements

The useful rule is not "all uncertainty should be a Confidence Eye." The rule
is to identify the evidence grain first: raw observations, fitted model
estimates, row-wise correlation estimates, simulation replicates, aggregate
operating characteristics, or status counts. Uncertainty should then match that
grain.

## Design Docs And Documentation

No design doc, NEWS, README, or pkgdown navigation update was needed. The
changed user-facing documentation is limited to rendered article captions and
reference-line styling.

## GitHub Issue Maintenance

`gh issue list --search "figure caption pkgdown visualization" --limit 20`
returned no matching open issues. No issue comment, new issue, or closure was
needed.

## Known Limitations And Next Actions

This closes the agreed first five figure-QA steps. Remaining figure work should
continue through the next rendered article/reference-page slices and should use
the same case-by-case grammar before any broad style change is made.
