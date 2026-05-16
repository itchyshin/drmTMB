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
| `vignettes/location-scale.Rmd` | Gaussian location-scale tutorial | ready enough | Has model equations, syntax, a trait-named parrot beak-length parameter-definition block, growth example, `check_drm()`, `profile_targets(fit_growth)`, `summary(fit_growth)`, response-scale translation tables, curved-response example, and caveats. | Keep as the flagship tutorial; future edits should be smaller polish, not a second tutorial inside the same page. |
| `vignettes/which-scale.Rmd` | Scale vocabulary guide with runnable audit snippets | guide, not tutorial | Explains residual `sigma`, random-effect SD, `sd(group)`, likelihood weights, known sampling variance, and residual `rho12`. | Keep as the glossary; cross-link from Slice 90 rather than duplicating the whole scale taxonomy. |
| `vignettes/bivariate-coscale.Rmd` | Residual `rho12` and bivariate covariance tutorial | ready enough, with a later group-covariance polish need | Has behaviour-coupling equations, fitted bivariate model, `check_drm()`, `summary()`, `rho12()` extraction, a residual-correlation plot, reporting guidance, and a group-level `corpairs()` section. | Leave for now unless Slice 90 frees time; a later polish can give group-level covariance the same response-scale display depth as residual `rho12`. |
| `vignettes/meta-analysis.Rmd` | Known sampling covariance tutorial | ready enough, Slice 95 polished | Has restoration-effects example, fitted model, `summary()`, `sigma()` reporting table, categorical heterogeneous-heterogeneity parameter definitions, `check_drm()`, weights warning, future `meta_V()` boundary, and bivariate known-`V` extension. | Keep stable. Later work can add a smaller diagonal-versus-dense covariance decision graphic. |
| `vignettes/phylogenetic-spatial.Rmd` | Structural-dependence tutorial | split pressure, routed | Has a three-step phylogeny, spatial, and planned phylogeny-plus-spatial route, current-status table, model ladder, phylogenetic examples, q=4 covariance rows, predictor-dependent q=2 phylogenetic `corpair()`, profile-target discussion, coordinate spatial one-slope example, and diagnostics. | Keep the route stable. Do not add runnable simultaneous `phylo()` plus `spatial()` syntax until the fitter supports multiple structural `mu` layers with identifiability checks. |
| `vignettes/robust-student.Rmd` | Robust continuous-response tutorial | ready enough for a secondary tutorial | Has Student-t equation and syntax, seedling example, `check_drm()`, coefficient interpretation, Gaussian comparison, and boundary text. | Keep as a secondary tutorial; future visualization work can add a residual or tail-weight display. |
| `vignettes/count-nbinom2.Rmd` | Fixed-effect count tutorial | ready enough, Slice 96 added | Has NB2 and zero-inflated NB2 equations, soil-invertebrate simulation, fitted `nbinom2()` and `zi ~ surface` models, `check_drm()`, `AIC()`, response-scale prediction tables, `sigma`/`theta` conversion, and unsupported-boundary text. | Keep fixed-effect and univariate until non-Gaussian random effects, phylogenetic/spatial count paths, and mixed-response models have implementation and recovery evidence. |
| `vignettes/proportion-beta-binomial.Rmd` | Fixed-effect proportion tutorial | ready enough, Slice 97 added | Has beta-binomial and strict beta equations, seed-germination and vegetation-cover simulations, fitted `beta_binomial()` and `beta()` models, `check_drm()`, response-scale prediction tables, `sigma`/`phi` conversion, and boundary text for exact 0/1 values. | Keep fixed-effect and univariate until non-Gaussian random effects, zero-one-inflated beta, beta-binomial zero inflation, phylogenetic/spatial bounded responses, and mixed-response models have implementation and recovery evidence. |
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

## Slice 91 Status: Structural-Dependence Reader Route

Slice 91 added a route through `vignettes/phylogenetic-spatial.Rmd`. The page
still carries several distinct lessons, but the top now tells readers to read
them as phylogeny first, coordinate spatial dependence second, and
phylogeny-plus-spatial as the planned third endpoint:

- residual `rho12` versus structural covariance summaries;
- univariate phylogenetic `mu` effects;
- bivariate phylogenetic `mu1`/`mu2` correlations;
- q=4 phylogenetic location-scale rows;
- predictor-dependent q=2 phylogenetic `corpair()`;
- coordinate spatial intercept and one numeric slope;
- planned phylogeny plus spatial as a third structural-dependence endpoint;
- mesh/SPDE and phylogenetic slopes as planned neighbours.

The third route remains marked planned until simultaneous `phylo()` plus
`spatial()` models have implementation and identifiability checks.

## Slice 95 Status: Meta-Analysis Source-Map Polish

Slice 95 kept meta-analysis as its own tutorial lane and did not change
formula grammar, likelihood code, or fitted examples. The useful change is
interpretive: the meta-analysis tutorial now defines `yi`, `vi`, `V`, `mu`,
`sigma`, `sd(study)`, and `weights = w` before asking readers to interpret a
model. It also gives the Rodriguez et al. categorical-moderator
parameterization directly:

```text
log(sigma_i) = gamma_0 + gamma_1 forest_i
sigma_forest / sigma_grassland = exp(gamma_1)
sigma_forest^2 / sigma_grassland^2 = exp(2 * gamma_1)
```

That keeps the tutorial aligned with the biological reading from Nakagawa et
al. (2025): average effects and heterogeneity can respond to different
moderators. It also keeps the unifying-model distinction visible: current
`meta_known_V(V = V)` is additive known covariance, top-level `weights = w`
is ordinary likelihood weighting, and the broader `meta_V()` umbrella remains
future design only.

## Slice 96 Status: Count NB2 Source-Map Tutorial

Slice 96 added `vignettes/count-nbinom2.Rmd` as the first non-Gaussian worked
count tutorial. It follows Nakagawa et al. (2026), which treats count
heteroscedasticity as a biological question and separates overdispersion from
structural-zero processes. The tutorial uses springtail counts from a
transparent soil-invertebrate simulation and teaches:

```text
Var(Y_i) = mu_i + sigma_i^2 * mu_i^2
size_i = theta_i = 1 / sigma_i^2
sigma_restored / sigma_degraded = exp(gamma_1)
theta_restored / theta_degraded = exp(-2 * gamma_1)
```

The fitted example deliberately stays inside the implemented surface:
fixed-effect univariate `nbinom2()` with optional `zi ~ surface`. It does not
teach random effects, `sd(group) ~ ...`, `meta_known_V()`, `phylo()`,
`spatial()`, bivariate counts, mixed-response families, or COM-Poisson as
runnable syntax.

## Slice 97 Status: Proportion Source-Map Tutorial

Slice 97 added `vignettes/proportion-beta-binomial.Rmd` as the bounded-response
worked tutorial. It follows Nakagawa et al. (2026), which separates discrete
successes out of trials from continuous proportions and warns that exact 0 or
1 values in continuous proportions need explicit boundary processes.

The beta-binomial example uses seed germination from a transparent restoration
simulation and teaches:

```text
phi_i = 1 / sigma_i^2
Var(Y_i / n_i) = mu_i * (1 - mu_i) * (1 + n_i * sigma_i^2) /
  (n_i * (1 + sigma_i^2))
sigma_sheltered / sigma_open = exp(gamma_1)
phi_sheltered / phi_open = exp(-2 * gamma_1)
```

The strict beta example uses vegetation cover values inside `(0, 1)` and keeps
the beta variance on the public `sigma` scale:

```text
Var(Y_i) = mu_i * (1 - mu_i) * sigma_i^2 / (1 + sigma_i^2)
```

The fitted examples deliberately stay inside the implemented surface:
fixed-effect univariate `beta_binomial()` with
`cbind(successes, failures)` and fixed-effect univariate `beta()` for strict
continuous proportions. The tutorial does not teach random effects,
`sd(group) ~ ...`, known covariance, structured effects, mixed responses,
zero-one-inflated beta, ordered beta, beta-binomial zero inflation, or
`successes / trials` denominator shorthand as runnable syntax.

## Later Worked Tutorials

After Slices 90-91, the Slice 95 meta-analysis polish, the Slice 96 count NB2
tutorial, and the Slice 97 proportion tutorial, the next candidates should be
chosen one at a time:

- a compact bivariate group-level covariance example that starts from an
  individual-difference biological question;
- a large-data benchmark article only after Phase 14 adds benchmark-backed
  evidence.

Do not add all of these at once. Each needs an implemented surface, a small data
story or transparent simulation, diagnostics, and clear unsupported-syntax
boundaries.
