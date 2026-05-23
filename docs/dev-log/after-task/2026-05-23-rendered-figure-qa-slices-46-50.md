# After Task: Rendered Figure QA Slices 46-50

## Goal

Continue the rendered-figure QA sequence by finishing PR #307, then improving
the focused `animal-models` and `relmat-known-matrices` articles with
case-specific rendered figures and current fitted-versus-planned wording.

## Implemented

Merged PR #307 after confirming all GitHub Actions checks were green, then
started `codex/rendered-figure-qa-46-50` from `origin/main`.

The animal-model page now has:

- current status wording for one numeric `mu` slope support and one-response
  residual-scale structured-intercept support;
- a rendered known additive-relatedness heatmap;
- a fitted residual-`sigma` versus animal-location-SD interval display; and
- a q=2 animal mean-mean Confidence Eye from `corpairs()`.

The `relmat()` page now has:

- current status wording for one numeric `mu` slope support and one-response
  residual-scale structured-intercept support;
- a rendered known relatedness heatmap;
- a fitted residual-`sigma` versus known-matrix-location-SD interval display;
  and
- a q=2 `relmat()` mean-mean Confidence Eye from `corpairs()`.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
the rendered figures; Fisher checked uncertainty provenance; Pat and Darwin
checked reader interpretation; Noether checked axes against estimands; Grace
checked rendering, alt text, tests, and pkgdown; Rose checked for stale planned
route wording and one-rule-fits-all drift.

## Mathematical Contract

No likelihood, formula grammar, extractor, plotting helper, or interval method
changed. The edits only affect article examples, plotting recipes, captions,
alt text, and status wording.

The matrix heatmaps are known structural inputs. The SD displays use existing
`confint(..., parm = "variance_components")` Wald intervals. The q=2
animal-model and `relmat()` correlation rows use existing `corpairs(...,
conf.int = TRUE)` profile intervals. The plots do not treat raw response
points as uncertainty for fitted SDs or latent correlations.

## Files Changed

- `vignettes/animal-models.Rmd`
- `vignettes/relmat-known-matrices.Rmd`
- `docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-46-50.md`
- `docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-46-50.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh run watch 26331495916 --exit-status
gh pr view 307 --json url,mergeStateStatus,headRefOid,isDraft,state,reviewDecision,statusCheckRollup
gh api -X PUT repos/itchyshin/drmTMB/pulls/307/merge -f merge_method=squash -f commit_title='Polish structural guide figure QA slices (#307)'
git push origin --delete codex/rendered-figure-qa-41-45
git fetch origin --prune
git switch -c codex/rendered-figure-qa-46-50 origin/main
air format vignettes/animal-models.Rmd vignettes/relmat-known-matrices.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); for (article in c('animal-models','relmat-known-matrices')) pkgdown::build_article(article, new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'animal-relmat-gaussian|plot-corpairs', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'standalone animal-model `sigma`|standalone relatedness `sigma`|Does the animal effect change a slope|Does the known-matrix layer change a slope|only `animal\(\)`|only `relmat\(\)`|Planned\. These routes' vignettes/animal-models.Rmd vignettes/relmat-known-matrices.Rmd docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-46-50.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-46-50.md
```

PR #307 was green on Ubuntu, macOS, and Windows before merge. The two target
articles rebuilt successfully. Article-image alt-text inspection found four
referenced article images in `animal-models`, four referenced article images
in `relmat-known-matrices`, and 0 missing alt attributes. The targeted
`animal-relmat-gaussian` and `plot-corpairs` test shards passed.
`git diff --check` was clean. `pkgdown::check_pkgdown()` reported no problems.
The stale-status scan returned only the intended current planned-boundary rows
for multiple slopes and predictor-dependent `corpair()` routes.

## Tests Of The Tests

This slice changes article plotting recipes and captions, so rendered-output
inspection is the primary validation. The targeted tests cover the fitted
animal/`relmat()` routes and the `plot_corpairs()` helper used by the
Confidence Eye displays.

## Consistency Audit

The case-by-case visual rule still holds:

- known additive and known-matrix heatmaps are raw structural-input displays;
- animal and `relmat()` SD figures use fitted model summaries with named Wald
  interval provenance;
- animal and `relmat()` q=2 latent correlations use Confidence Eyes because
  finite profile intervals are available;
- raw observations do not appear on SD or correlation axes;
- the status tables no longer describe one-slope `mu` or residual-scale
  structured-intercept routes as planned.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The first `relmat()` q=2 render produced a lone point even though the caption
claimed a Confidence Eye. Fisher caught that the profile interval columns were
`NA`; the example data were adjusted to a deterministic case with finite
profile bounds, and Florence reinspected the regenerated PNG.

## Team Learning

Confidence Eyes need interval provenance, not just a plot type. If a rendered
plot silently drops the eye, the caption and data grain must be checked before
the figure is accepted.

## Known Limitations

This slice does not add bootstrap or profile uncertainty for every animal or
`relmat()` route. It documents and visualizes only the article examples with
current supported interval sources.

## Next Actions

1. Open a PR and update issue #58 with the slice summary.
2. Continue the rendered-figure sweep with the next figure-light articles
   after this PR is green or deliberately queued.
