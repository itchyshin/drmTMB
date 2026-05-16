# Worked-Example Inventory

Slice 89 records the current worked-example layer after the Phase 10-13
foundation PRs landed. It is a tutorial-planning artifact, not a new model
claim. The reader is an applied ecology, evolution, or environmental-science
user who can read a regression equation but needs the tutorial to connect the
biological question, model syntax, fitted output, diagnostics, and report-scale
interpretation.

## Inventory Rubric

Use the same contract as `docs/design/21-tutorial-style.md`. A worked tutorial
is ready when it has:

1. a biological or applied question;
2. the response, predictors, grouping factors, and any known covariance named;
3. symbolic equations paired with exact `drmTMB` syntax;
4. a fitted model object and printed output;
5. a plot or table that maps output back to the question;
6. plain-language interpretation of location, scale, shape, coscale, or
   covariance parameters;
7. diagnostics and a short unsupported-syntax boundary.

The inventory labels below are deliberately conservative:

- `ready enough`: the article can be linked as a worked tutorial today.
- `needs focused polish`: the article is usable but one tutorial contract item
  is thin.
- `guide, not tutorial`: the page should orient readers rather than carry a
  full analysis.
- `split pressure`: the page has enough material that a future slice should
  separate or strongly route subtopics before adding more examples.

## Current Tutorial Inventory

| Page | Current role | Inventory status | Main evidence | Next action |
| --- | --- | --- | --- | --- |
| `vignettes/drmTMB.Rmd` | Getting-started orientation | guide, not tutorial | Fits the first Gaussian location-scale model, runs `check_drm()`, and points readers to model guides and tutorials. | Keep short. Do not turn the front door into the main worked example. |
| `vignettes/model-map.Rmd` | Implemented-versus-planned guide | guide, not tutorial | Stable-core matrix separates fitted surfaces, planned neighbours, and diagnostic or interval status. | Keep as the status map; use it to route unsupported-syntax questions. |
| `vignettes/model-workflow.Rmd` | Post-fit workflow guide | guide, not tutorial | Shows `check_drm()`, `summary()`, `profile_targets()`, `conf.status`, prediction, residuals, and simulation as a reusable workflow. | Keep as the post-fit checklist; link to it from worked examples when diagnostics appear. |
| `vignettes/location-scale.Rmd` | Gaussian location-scale tutorial | ready enough | Has model equations, syntax, growth example, `check_drm()`, `profile_targets(fit_growth)`, `summary(fit_growth)`, response-scale translation tables, curved-response example, and caveats. | Keep as the flagship tutorial; future edits should be smaller polish, not a second tutorial inside the same page. |
| `vignettes/which-scale.Rmd` | Scale vocabulary guide with runnable audit snippets | guide, not tutorial | Explains residual `sigma`, random-effect SD, `sd(group)`, likelihood weights, known sampling variance, and residual `rho12`. | Keep as the glossary; cross-link from Slice 90 rather than duplicating the whole scale taxonomy. |
| `vignettes/bivariate-coscale.Rmd` | Residual `rho12` and bivariate covariance tutorial | ready enough, with a later group-covariance polish need | Has behaviour-coupling equations, fitted bivariate model, `check_drm()`, `summary()`, `rho12()` extraction, a residual-correlation plot, reporting guidance, and a group-level `corpairs()` section. | Leave for now unless Slice 90 frees time; a later polish can give group-level covariance the same response-scale display depth as residual `rho12`. |
| `vignettes/meta-analysis.Rmd` | Known sampling covariance tutorial | ready enough | Has restoration-effects example, fitted model, `summary()`, `sigma()` reporting table, `check_drm()`, weights warning, and bivariate known-`V` extension. | Keep stable. Later work can add a smaller diagonal-versus-dense covariance decision graphic. |
| `vignettes/phylogenetic-spatial.Rmd` | Structured-dependence tutorial | split pressure | Has current-status table, model ladder, phylogenetic examples, q=4 covariance rows, predictor-dependent q=2 phylogenetic `corpair()`, profile-target discussion, coordinate spatial one-slope example, and diagnostics. | Slice 91 should add a reader route through the page and isolate the coordinate-spatial example so the article does not become a single long mixed notebook. |
| `vignettes/robust-student.Rmd` | Robust continuous-response tutorial | ready enough for a secondary tutorial | Has Student-t equation and syntax, seedling example, `check_drm()`, coefficient interpretation, Gaussian comparison, and boundary text. | Keep as a secondary tutorial; future visualization work can add a residual or tail-weight display. |
| `vignettes/distribution-families.Rmd` | Family-choice guide | guide, not tutorial | Maps response types to families and explains family-specific public `sigma` meanings. | Keep as a guide. Future count/proportion tutorials should be separate worked examples, not appended here. |
| `vignettes/large-data.Rmd` | Large-data guide | guide, not tutorial | Explains implemented storage controls, `check_drm()` expectations, aggregation boundaries, and benchmark discipline. | Keep as a guide until Phase 14 adds benchmark-backed examples. |
| `vignettes/testing-likelihoods.Rmd` | Developer testing guide | guide, not tutorial | Explains comparator checks, simulation recovery, independent likelihood checks, and boundary tests. | Keep under Developer Notes; do not mix with applied tutorials. |

## Slice 90 Status: Flagship Location-Scale Tutorial

`vignettes/location-scale.Rmd` is the flagship worked example because it teaches
the core package idea: biological variation can be modelled instead of treated
as nuisance noise. Slice 90 kept the syntax surface unchanged and tightened the
existing growth example so the reader sees, in one place:

- the average mean response slope;
- the residual-scale slope as an SD ratio and, when useful, a variance ratio;
- the random-slope SD as among-group reaction-norm variation;
- the `sd(group)` slope as a group-level predictor of among-group SD;
- `check_drm()` and `profile_targets()` as the interpretation gate;
- the boundary that `sd(population) ~ habitat` targets an unlabelled random
  intercept, while coefficient-specific random-slope SD regression remains
  reserved.

Pat's test is whether an applied PhD student can explain the difference between
`sigma ~ temperature`, `(0 + temperature | population)`, and `sd(population) ~
habitat` without reading the design docs. After Slice 90, that test should pass
from the tutorial text itself.

## Slice 91 Candidate: Structured-Dependence Reader Route

The next-highest tutorial risk is `vignettes/phylogenetic-spatial.Rmd`. It is
valuable, but it now carries several distinct lessons:

- residual `rho12` versus phylogenetic `corpairs()`;
- univariate phylogenetic `mu` effects;
- bivariate phylogenetic `mu1`/`mu2` correlations;
- q=4 phylogenetic location-scale rows;
- predictor-dependent q=2 phylogenetic `corpair()`;
- coordinate spatial intercept and one numeric slope;
- mesh/SPDE and phylogenetic slopes as planned neighbours.

Slice 91 should add a reader route near the top and make the coordinate-spatial
section self-contained. It should not split the file unless the route still
feels too long after the top-level map is added.

## Later Worked Tutorials

After Slices 90-91, the next candidates should be chosen one at a time:

- a count-abundance example for NB2 or zero-inflated NB2;
- a beta or beta-binomial proportion example;
- a compact bivariate group-level covariance example that starts from an
  individual-difference biological question;
- a large-data benchmark article only after Phase 14 adds benchmark-backed
  evidence.

Do not add all of these at once. Each needs an implemented surface, a small data
story or transparent simulation, diagnostics, and clear unsupported-syntax
boundaries.
