# After Task: Slice 107 Summary Reading Guide

## Goal

Make the ordinary `summary()` output easier to read for applied users by
adding a compact map from each summary component to its interpretation task and
to the extractor that should be used next.

## Implemented

- Added a reader-facing table to `vignettes/model-workflow.Rmd` under
  "Read the ordinary summary first".
- Mapped `summary(fit)$coefficients`, `summary(fit)$parameters`,
  `summary(fit)$covariance`, `summary(fit)$derived`, and
  `summary(fit)$confint` to the questions they answer.
- Pointed readers from the ordinary summary to `fixef()`, `sigma()`,
  `rho12()`, `ranef()`, `corpairs()`, and `profile_targets()` when they need
  the full object behind a printed row.
- Tightened the compact post-fit checklist so `profile_targets()` appears
  before profile-likelihood interval requests on fitted SD or correlation
  targets.
- Updated NEWS and ROADMAP to record the reader-facing summary closure.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-107-summary-reading-guide.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-153143-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md vignettes/model-workflow.Rmd`: passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::clean_site(); pkgdown::build_site(preview = FALSE)"`:
  passed and rendered the updated model-workflow article, NEWS, and ROADMAP.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n "Read the printed summary as a map|Summary component|coefficients.*parameters.*covariance|sd:mu:\\(1 \\| group\\)|The printed summary is meant to answer|profile_targets\\(fit\\).*before asking" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html NEWS.md ROADMAP.md`:
  confirmed the source and rendered article contain the new summary map.
- `rg -n "credible interval|credible intervals|95% credible|Bayesian credible|posterior|not Bayesian credible|confidence intervals, not Bayesian credible" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html NEWS.md ROADMAP.md`:
  found only the intended frequentist confidence-interval wording.
- `Rscript tools/codex-checkpoint.R --goal "Slice 107 summary reading guide" --next "stage, commit, push, open PR, monitor CI, merge, then start Slice 108 pkgdown reference and plotting inventory"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-153143-codex-checkpoint.md`.

## What Did Not Change

- No R API, formula grammar, likelihood, TMB code, or tests changed.
- No new plotting helper was added.
- No new interval method was added.
- No claim was added that derived repeatability, covariance products, or fitted
  ranges have validated intervals.

## Team Learning

- Ada: Slice 107 was a reader-path closure, not another implementation slice.
- Pat: applied users need a table that tells them where to look in the
  ordinary summary before they learn the specialized extractors.
- Darwin: the site random-intercept example now connects SD, variance
  component, and repeatability without making the biological example heavier.
- Emmy: the prose now names actual `summary.drmTMB` components rather than
  generic "model output".
- Boole: the guide keeps `summary()` as the first habit while preserving the
  existing extractor API.
- Fisher: confidence intervals remain confidence intervals, and the text still
  distinguishes quick local standard errors from profile-likelihood intervals.
- Grace: the rendered pkgdown article and reference index remain clean.
- Rose: stale scans found only the intended no-Bayesian wording.
- Gauss and Noether stayed watch-only because no likelihood or equation changed.

## Known Limitations

- This slice improves interpretation prose but does not add examples for
  bivariate, phylogenetic, spatial, shape, or zero-inflation summaries.
- `summary(fit)$covariance` still reports covariance products without standard
  errors.
- Derived variance-ratio intervals remain unavailable.

## Next Actions

1. Use Slice 108 to audit whether exported plotting functions and post-fit
   helpers are correctly grouped in pkgdown reference pages.
2. Use Slice 109 to turn the visualization-landscape research into
   drmTMB-specific example rules without adding Bayesian language or
   unsupported uncertainty displays.
