# After Task: Slice 102 Empirical Prediction-Grid Example

## Goal

Add the first reader-facing empirical-grid workflow for Phase 17. The model
workflow article should show the difference between a conditioned prediction
grid and an empirical grid that can be reduced with
`marginal_parameters(..., by = "temperature")`.

## Implemented

- Kept the conditioned reef `temperature_grid` example for direct
  `predict_parameters()` rows.
- Added `temperature_empirical <- prediction_grid(..., margin = "empirical")`.
- Added `marginal_parameters(fit, newdata = temperature_empirical, by = "temperature")`
  so the article averages over the fitted-row covariate distribution at each
  focal temperature.
- Updated `ROADMAP.md` and `docs/design/39-visualization-grammar.md` to record
  Slice 102 and move the near-term list toward interval provenance.
- Updated `NEWS.md` with the article-level workflow change.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-131655-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, formula grammar, TMB code, parameter transformation, or fitted
object structure changed. The article now distinguishes two post-fit estimands:
fixed-effect predictions at a conditioned habitat value, and empirical
marginal summaries over the fitted-row covariate distribution.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-102-empirical-grid-example.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-131655-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e "devtools::test(filter = 'prediction-grid|marginal-parameters', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `articles/model-workflow.html`, `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'temperature_empirical|margin = "empirical"|fitted-row covariate distribution|by = "temperature"|Slice 102|empirical-grid' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered wording for the empirical-grid example.
- `rg -n 'plotting support|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|EM means|prediction_grid.*plot' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary matches.
- `git diff -U0 -- NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 102 empirical prediction-grid example" --next "append check-log and after-task report, then stage, commit, push, and open PR"`:
  passed and wrote the recovery checkpoint.

## Tests Of The Tests

No package code changed, so no new testthat file was added. The standalone
vignette render exercised the new article chunks, and the focused
`prediction-grid|marginal-parameters` suite covered the helper path used by the
article.

## Consistency Audit

The source article, rendered article, NEWS, ROADMAP, and visualization-grammar
design note now describe the same Slice 102 contract:

- direct predictions can use a conditioned `prediction_grid()`;
- empirical summaries should use a separate `margin = "empirical"` grid;
- `marginal_parameters(..., by = "temperature")` reduces the empirical grid by
  the focal term;
- the package still has no plotting helper, interval provenance columns, EMM
  contrasts, slope helper, or new visualization dependency.

## What Did Not Go Smoothly

Nothing material. The main judgement call was not to change package code or add
new tests for a docs-only example; the article render plus focused existing
tests are the right-sized validation for this slice.

## Team Learning

- Ada: keep Phase 17 slices small by separating example coverage from new API
  behavior.
- Pat: the article is clearer when it shows conditioned prediction rows and
  empirical marginal summaries as different questions.
- Fisher: the example should keep weighting and interval claims out of the
  interpretation until those contracts exist.
- Rose: rendered-site scans are useful here because the changed behaviour is a
  reader-facing article path, not a hidden code path.

## Known Limitations

- `weights` remains metadata only and is not used in the article.
- The example does not add intervals to prediction or marginal tables.
- No plotting helper, EMM method, slope helper, or external visualization
  dependency was added.

## Next Actions

1. Add interval provenance to prediction and marginal tables when the source can
   be computed honestly.
2. Decide whether later helpers should read `drm_prediction_grid` metadata for
   default grouping, labels, and captions.
3. Add one narrow plotting helper only after the table and interval contracts
   are stable.
