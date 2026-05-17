# After Task: Slice 116 Bivariate Corpairs Plot

## Goal

Add the first fitted tutorial workflow where `corpairs()` feeds
`plot_corpairs(..., facet = "level")`. The reader is an applied ecology or
evolution user reading the bivariate-coscale tutorial and trying to separate
residual `rho12` from group-level correlation rows.

## Implemented

- Added a `plot_corpairs(pair_table, facet = "level")` chunk after the existing
  `corpairs(fit_group)` table in `vignettes/bivariate-coscale.Rmd`.
- Added prose explaining that the optional plotting helper consumes the explicit
  table and that faceting by `level` separates residual and group-level rows.
- Updated NEWS, ROADMAP, and `docs/design/39-visualization-grammar.md` to record
  the first fitted `plot_corpairs()` workflow.
- Cleaned the NEWS ordering so `plot_corpairs()` appears before
  `plot_parameter_surface()` in the function-specific bullets.

## Mathematical Contract

No likelihood, formula grammar, parameter transform, or interval method changed.
The tutorial already fits the repeated-individual bivariate Gaussian model with
matching labelled `mu1` and `mu2` random intercepts. This slice only displays
the existing `corpairs(fit_group)` table. The residual row remains `rho12`, and
the group row remains the `mu1`/`mu2` random-intercept correlation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `vignettes/bivariate-coscale.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-116-bivariate-corpairs-plot.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-181106-codex-checkpoint.md`

## Checks Run

- `air format NEWS.md vignettes/bivariate-coscale.Rmd ROADMAP.md docs/design/39-visualization-grammar.md`:
  passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "devtools::test(filter = 'plot-corpairs', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated bivariate-coscale article, ROADMAP, and NEWS.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'plot_corpairs\\(pair_table, facet = "level"\\)|Slice 116|bivariate-coscale tutorial|residual `rho12` from group-level|optional plotting helper consumes that explicit table|biological `plot_corpairs` workflow' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages include the fitted workflow and Slice 116
  notes.
- `rg -n 'plot_corpairs\\(\\).*computes|plot_corpairs\\(\\).*refit|plot_corpairs\\(\\).*profile|raw correlation.*same estimand|group-level.*rho12_i|future `plot_corpairs`|future plot_corpairs|only exported plotting helper|currently `plot_parameter_surface`|ggplot2.*Imports|posterior draw|credible interval' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html DESCRIPTION --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intentional guardrails about posterior/credible-interval wording
  and the raw-versus-residual correlation distinction.
- `Rscript tools/codex-checkpoint.R --goal "Slice 116 bivariate corpairs plot workflow" --next "stage, commit, push branch, and open PR against main"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-181106-codex-checkpoint.md`.

## Tests Of The Tests

No new test was needed because Slice 114 already tests `facet = "level"` on the
plot helper. This slice exercised the fitted tutorial workflow by rendering the
bivariate-coscale article directly and then rebuilding pkgdown.

## Consistency Audit

The source vignette, rendered article, NEWS, ROADMAP, and visualization grammar
now agree that the first fitted `plot_corpairs()` workflow exists. The tutorial
still states that raw activity-boldness correlation, residual `rho12`, and
group-level random-intercept correlation are different estimands.

## What Did Not Go Smoothly

Nothing blocked the slice. The main style choice was to insert the plot
immediately after the table it consumes, rather than adding a decorative figure
elsewhere in the article.

## Team Learning

- Ada: fitted plotting examples should be anchored to an already-stable tutorial
  model.
- Pat: the table-then-plot sequence is easier for applied readers than a plot
  appearing before the data contract is visible.
- Fisher: faceting helps separate correlation layers but does not change their
  inferential status.
- Boole: `plot_corpairs(pair_table, facet = "level")` keeps the API plain and
  explicit.
- Darwin: the individual-difference example now has a visible correlation-layer
  display tied to its biological question.
- Grace: rendering the vignette directly before pkgdown is the right check for
  tutorial workflow changes.
- Rose: stale "future workflow" language should be replaced once the fitted
  workflow exists.

## Known Limitations

- The plot displays the existing `corpairs()` table only.
- No interval computation, profile path, likelihood, formula grammar, TMB code,
  EMM, contrast, slope, or diagnostics plot changed.

## Next Actions

1. Revisit `emmeans` compatibility only after the reference-grid and link-scale
   contract is tested across implemented families.
