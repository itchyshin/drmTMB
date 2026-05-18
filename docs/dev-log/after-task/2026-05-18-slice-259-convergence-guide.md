# After Task: Slice 259 Convergence Guide And Figure Gallery Routing

## Goal

Give users a clear pkgdown page for what to do when the default optimizer
settings are not enough for complex `drmTMB` models, and repair the pkgdown
figure-gallery route so it matches the user's intended meaning.

## Implemented

- Added `vignettes/convergence.Rmd` as a Model Guides article.
- Added the article to the pkgdown navbar and article index as "Improving
  convergence".
- Added `vignettes/figure-gallery.Rmd` as a Tutorials article showing raw data,
  fitted model slopes, 95% confidence bands, parameter surfaces, `emmeans`
  displays, categorical-by-continuous, categorical-by-categorical, and
  continuous-by-continuous interaction plots, correlation summaries, and
  illustrative simulation operating characteristics.
- Added a dedicated "Simulation & Comparison" pkgdown section and moved
  `testing-likelihoods` there so future power, bias, coverage, runtime,
  convergence, failure-ledger, and comparator articles have a natural home.
- Removed the narrow `vignettes/phase18-count-gallery.Rmd` page from public
  pkgdown. Count pilot diagnostics remain internal simulation infrastructure
  until broader simulation-result article design is ready.
- Recorded a team-improvement rule that public page names must be reader-facing
  and that general figure galleries are distinct from specialised simulation
  diagnostics reports.
- Added a NEWS bullet for the new guide.

## Mathematical Contract

This slice does not change likelihoods, parameter transformations, formula
grammar, optimizers, standard-error computation, or diagnostics. It documents
the existing `nlminb()` optimizer path, `drm_control(optimizer = ...)`,
`drm_control(se = FALSE)`, `check_drm()`, `TMB::sdreport()`, `pdHess`, and
profile-likelihood workflow.

## Files Changed

- `vignettes/convergence.Rmd`
- `vignettes/figure-gallery.Rmd`
- `vignettes/phase18-count-gallery.Rmd` (removed)
- `_pkgdown.yml`
- `NEWS.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/after-task/2026-05-18-slice-259-convergence-guide.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

- `air format vignettes/convergence.Rmd _pkgdown.yml NEWS.md`
- `Rscript -e "rmarkdown::render('vignettes/convergence.Rmd', output_dir = tempfile('convergence-article-'), quiet = TRUE)"`
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = tempfile('figure-gallery-article-'), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Improving convergence|convergence\\.html|optimizer budget|optimizer_convergence|pdHess|se = FALSE|default optimizer|drm_control\\(optimizer" vignettes/convergence.Rmd _pkgdown.yml NEWS.md README.md vignettes/model-workflow.Rmd vignettes/large-data.Rmd R/check.R R/control.R docs/design/35-optimizer-start-map-multistart.md`
- `rg -n "Figure gallery|figure-gallery|Improving convergence|convergence\\.html|Simulation & Comparison|testing-likelihoods|phase18-count-gallery" _pkgdown.yml vignettes NEWS.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/team-improvements.md`
- `rg -n "Florence Figure-Gallery Slice Map|Slice 260|Simulation & Comparison|figure-gallery|convergence" ROADMAP.md docs/design/39-visualization-grammar.md _pkgdown.yml vignettes`
- `git diff --check`

## Tests Of The Tests

The convergence article uses non-evaluated example chunks because it teaches
analysis workflow and control settings rather than a new fitted code path. The
figure gallery renders evaluated example chunks, including a small
location-scale fit, `predict_parameters()` confidence bands,
`plot_parameter_surface()`, `plot_corpairs()`, an `emmeans` display when
`emmeans` is installed, categorical-by-categorical and continuous-by-continuous
interaction plots, and illustrative simulation operating-characteristic plots.
`pkgdown::check_pkgdown()` confirms the articles are listed in the site
configuration.

## Consistency Audit

The convergence article keeps current implementation boundaries visible:
`nlminb()` is the only fitted optimizer, alternative optimizers and warm starts
remain planned, `se = FALSE` skips `TMB::sdreport()` but does not make Wald
inference available, and `pdHess = FALSE` is treated as an inference warning
rather than automatic model failure. The figure gallery keeps the count pilot
out of the public gallery route and describes future simulation-result articles
as cross-data-type work rather than count-only work. The stale-wording scans
confirmed the new page, navbar entries, NEWS bullets, and existing
`drm_control()`/`check_drm()` docs use consistent terminology.

## What Did Not Go Smoothly

Two naming issues surfaced. First, the convergence draft did not say strongly
enough that defaults are for ordinary models and quick everyday fitting, not
necessarily for large bivariate, phylogenetic, spatial, location-scale, shape,
inflation, or random-slope models. Second, the previous "Phase 18 count
simulation gallery" label used internal language and described a narrow
simulation diagnostics report, not the broad Florence-led figure gallery the
user wanted. Both were corrected.

## Team Learning

- Ada narrowed the convergence guide but allowed a small navigation correction
  when the user clarified the figure-gallery meaning.
- Fisher separated optimizer failure, weak identifiability, and Wald-inference
  failure.
- Gauss kept `pdHess = FALSE` tied to the Hessian used by `TMB::sdreport()`
  without implying that point estimates are always useless.
- Pat missed the first public-facing gallery name and should have caught the
  "Phase 18" leak before the user did. The correction now routes the gallery by
  reader task.
- Florence clarified that a true figure gallery should showcase model-object
  plots, raw data with fitted slopes and 95% confidence bands, `emmeans`
  displays, categorical and continuous interaction figures, correlation
  figures, and simulation operating-characteristic figures.
- Grace required explicit pkgdown navigation and render checks.
- Rose checked that planned tools such as fallback optimizers, starts, and
  multi-start were not described as implemented, and recorded the page-naming
  process lesson.

## Known Limitations

- The page is documentation only. It does not add fallback optimizers, warm
  starts, Hessian eigenvector culprit reporting, or automatic simplification
  advice.
- The figure gallery is a first showcased set, not a final publication atlas.
  It does not yet include every family, every tutorial, bootstrap intervals,
  full simulation power curves, or real comprehensive Phase 18 results.
- The roadmap slice map is a planning scaffold. Slice numbers after 259 can
  still be revised if convergence hardening or pre-simulation blockers become
  more urgent.
- Full `pkgdown::build_site()` was not run locally to avoid generated-site
  churn; `pkgdown::check_pkgdown()` passed and the GitHub pkgdown workflow is
  the deployment gate after merge.

## Next Actions

1. Add a `check_drm()` convergence-advice layer or a small
   `convergence_advice()` helper that translates diagnostic rows into next
   actions.
2. Add richer Hessian/culprit diagnostics where feasible.
3. Design the warm-start/refit helper before adding alternative optimizers.
4. Extend the figure gallery with real tutorial examples and, later, separate
   Simulation & Comparison articles for power, bias, coverage, runtime,
   convergence, and failure patterns across continuous, proportion, count, and
   other surfaces.
