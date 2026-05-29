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
| `vignettes/model-workflow.Rmd` | Post-fit workflow guide | guide, not tutorial | Shows `check_drm()`, ordinary `summary()` output for fixed-effect and random-intercept fits, response-scale random-effect SDs, derived repeatability, `profile_targets()`, `conf.status`, prediction, residuals, and simulation as a reusable workflow. | Keep as the post-fit checklist; link to it from worked examples when diagnostics or variance components appear. |
| `vignettes/location-scale.Rmd` | Gaussian location-scale tutorial | ready enough | Has model equations, syntax, a trait-named parrot beak-length parameter-definition block, growth example, `check_drm()`, `profile_targets(fit_growth)`, `summary(fit_growth)`, response-scale translation tables, curved-response example, and caveats. | Keep as the flagship tutorial; future edits should be smaller polish, not a second tutorial inside the same page. |
| `vignettes/which-scale.Rmd` | Scale vocabulary guide with runnable audit snippets | guide, not tutorial | Explains residual `sigma`, random-effect SD, `sd(group)`, likelihood weights, known sampling variance, and residual `rho12`. | Keep as the glossary; cross-link from Slice 90 rather than duplicating the whole scale taxonomy. |
| `vignettes/bivariate-coscale.Rmd` | Residual `rho12` and bivariate covariance tutorial | ready enough, Slice 98 polished | Has behaviour-coupling equations, fitted bivariate residual model, `check_drm()`, `summary()`, `rho12()` extraction, a residual-correlation plot, reporting guidance, and a fitted individual-difference `mu1`/`mu2` group-level covariance example with `corpairs()` and `summary(fit)$covariance` tables. | Keep residual and group-level correlation layers separate; future edits should not turn this page into the full random-slope or q=4 covariance tutorial. |
| `vignettes/meta-analysis.Rmd` | Known sampling covariance tutorial | ready enough, Slice 95 polished | Has restoration-effects example, fitted model, `summary()`, `sigma()` reporting table, categorical heterogeneous-heterogeneity parameter definitions, `check_drm()`, weights warning, future `meta_V()` boundary, and bivariate known-`V` extension. | Keep stable. Later work can add a smaller diagonal-versus-dense covariance decision graphic. |
| `vignettes/phylogenetic-spatial.Rmd` | Structural-dependence tutorial | split pressure, routed | Has a three-step phylogeny, spatial, and planned phylogeny-plus-spatial route, current-status table, model ladder, phylogenetic examples, q=4 covariance rows, predictor-dependent q=2 phylogenetic `corpair()`, profile-target discussion, coordinate spatial one-slope, q=2 bivariate, constant q=4 spatial status, and diagnostics. | Keep the route stable. Do not add runnable simultaneous `phylo()` plus `spatial()` syntax until the fitter supports multiple structural `mu` layers with identifiability checks. |
| `vignettes/robust-student.Rmd` | Robust continuous-response tutorial | ready enough for a secondary tutorial | Has Student-t equation and syntax, seedling example, `check_drm()`, coefficient interpretation, Gaussian comparison, and boundary text. | Keep as a secondary tutorial; future visualization work can add a residual or tail-weight display. |
| `vignettes/count-nbinom2.Rmd` | Count tutorial | needs random-effect follow-up example after Slice 245 | Has NB2 and zero-inflated NB2 equations, soil-invertebrate simulation, fitted `nbinom2()` and `zi ~ surface` models, `check_drm()`, `AIC()`, response-scale prediction tables, `sigma`/`theta` conversion, and updated boundary text that ordinary NB2 `mu` random effects, the first NB2 phylogenetic q=1 `mu` route, and the first ordinary NB2 log-`sigma` random intercept are now fitted. | Add biological NB2 `mu` and log-`sigma` random-intercept examples once smoke-runner and interval-coverage surfaces are in place; keep NB2 `sigma` slopes or structured effects, `zi` random effects, count paths beyond the ordinary Poisson/NB2 phylogenetic q=1 `mu` routes, and mixed-response models planned. |
| `vignettes/proportion-beta-binomial.Rmd` | Proportion tutorial | ready enough, Slice 1349-1358 synchronized | Has beta-binomial, strict beta, and zero-one beta equations; seed-germination and vegetation-cover simulations; fitted `beta_binomial()` and `beta()` models; `check_drm()`; response-scale prediction tables; `sigma`/`phi` conversion; and boundary text for exact 0/1 values. It now names ordinary `mu` random intercepts and independent numeric slopes as fitted first slices for both beta and beta-binomial, names fixed-effect `zero_one_beta()` for structural exact-boundary continuous proportions, and is linked from getting-started, model-map, pkgdown, and source-map routes. | Add a fuller reader-facing mixed-model worked example before broad bounded-response random-effect grids; beta-binomial zero inflation, phylogenetic/spatial bounded responses, and mixed-response models still need implementation and recovery evidence. |
| `vignettes/distribution-families.Rmd` | Family-choice guide | guide, not tutorial | Maps response types to families and explains family-specific public `sigma` meanings. | Keep as a guide. Future count/proportion tutorials should be separate worked examples, not appended here. |
| `vignettes/large-data.Rmd` | Large-data guide | guide, not tutorial | Explains implemented storage controls, `check_drm()` expectations, aggregation boundaries, and benchmark discipline. | Keep as a guide until Phase 14 adds benchmark-backed examples. |
| `vignettes/testing-likelihoods.Rmd` | Developer testing guide | guide, not tutorial | Explains comparator checks, simulation recovery, independent likelihood checks, and boundary tests. | Keep under Developer Notes; do not mix with applied tutorials. |

## Slice 529-538 Status: Animal, Student-T, And Skew Example Promises

Ada rechecked the example promise stack after the Ayumi and package-health
slices. The status is:

| Topic | Current example status | Safe reader action |
| --- | --- | --- |
| Animal and `relmat()` known matrices | The focused animal and `relmat()` articles now have runnable examples for univariate `animal(Ainv = Ainv)` / `relmat(Q = Q)` in `mu` and/or `sigma`, one-slope Gaussian `mu` routes, bivariate q=2 location covariance, and constant q=4 location-scale covariance, with `check_drm()`, `corpairs()`, and profile-target status in the reader path. Pedigree construction at scale, multiple slopes, residual-scale structured slopes, slope correlations, predictor-dependent `corpair()`, non-Gaussian relatedness effects, and direct-SD grammar remain planned. | Use the focused structural-dependence articles for precomputed relatedness-matrix examples; next add an ADEMP q=4 addendum before admitting broad animal/`relmat()` q=4 grids. |
| Student-t | `vignettes/robust-student.Rmd` is a worked secondary tutorial with model equation, fitted seedling example, `check_drm()`, coefficient interpretation, and Gaussian comparison. | Link users there for robust fixed-effect continuous responses with `mu`, `sigma`, and fixed-effect `nu`. |
| Skew-normal and skew-t | `vignettes/robust-student.Rmd`, `vignettes/model-map.Rmd`, and the distribution roadmap show planned syntax and boundaries, but no fitted skew-family likelihood exists. | Keep skew examples as design-only until fixed-effect skew-normal likelihood, normal-limit checks, positive/negative skew recovery, interval evidence, and false-positive heteroscedasticity tests pass. |

This is intentionally conservative. A planned marker example is useful because
it teaches the intended grammar and the nearest fitted alternative, but it must
not be written like a model a reader can run today.

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
- one numeric phylogenetic `mu` slope;
- planned phylogeny plus spatial as a third structural-dependence endpoint;
- mesh/SPDE, multiple structured slopes, and slope correlations as planned
  neighbours.

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
`meta_V(V = V)` is additive known covariance, top-level `weights = w` is
ordinary likelihood weighting, and the broader `meta_V()` umbrella remains
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
teach random effects, `sd(group) ~ ...`, `meta_V()`, `phylo()`,
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
`cbind(successes, failures)`, ordinary bounded-response `mu` random intercepts
and independent numeric slopes, fixed-effect univariate `beta()` for strict
continuous proportions, and fixed-effect univariate `zero_one_beta()` for
structural exact-boundary continuous proportions. The tutorial does not teach
correlated slopes, `sigma`/`zoi`/`coi` random effects, `sd(group) ~ ...`, known
covariance, structured effects, mixed responses, ordered beta, beta-binomial
zero inflation, or `successes / trials` denominator shorthand as runnable
syntax.

## Slice 1349-1358 Status: Non-Gaussian Tutorial Gate Follow-Through

Slices 1349-1358 close the reader-route follow-through after the fixed-effect
zero-one beta source and artifact lanes landed. The gate is deliberately a
documentation and source-map task, not a new likelihood task.

The count tutorial already carries the fitted fixed-effect NB2 and
zero-inflated NB2 route, with ordinary Poisson/NB2 `mu` random effects, NB2
log-`sigma` random intercepts, and ordinary Poisson/NB2 q=1 phylogenetic
`mu` routes named as fitted or first-slice neighbours rather than silently
inserted into the worked example. The proportion tutorial now carries the
three bounded-response choices in one place:

```text
successes out of known trials -> beta_binomial()
continuous proportions strictly inside (0, 1) -> beta()
continuous proportions on [0, 1] with structural exact boundaries -> zero_one_beta()
```

The reader path is synchronized through the getting-started learning table,
the model-map one-response row, the source-map implementation row, the pkgdown
article menu, and this inventory. The remaining bounded-response work is not a
tutorial wording problem: zero-one beta random effects, random slopes,
structured bounded responses, known covariance, denominator shorthand for
zero-one beta, ordered beta, beta-binomial zero inflation, and mixed
bounded-response models still need likelihood, recovery, diagnostics, and
Phase 18 evidence before they become runnable tutorial syntax.

## Slice 98 Status: Bivariate Group-Level Covariance Polish

Slice 98 kept `vignettes/bivariate-coscale.Rmd` as one article and filled the
thin group-level covariance part rather than creating a new page. The residual
`rho12` example remains the first lesson, but the article now also fits a
repeated-individual example:

```text
mu1 = activity ~ food + disturbance + (1 | p | ID)
mu2 = boldness ~ food + (1 | p | ID)
sigma1 = ~1
sigma2 = ~1
rho12 = ~1
```

The individual-difference section now teaches:

- residual `rho12` as within-observation activity-boldness coupling;
- the group-level `mu1`/`mu2` random-intercept correlation as
  among-individual covariance in average activity and average boldness;
- `check_drm()` rows for convergence, random-effect SDs, residual-correlation
  boundaries, and bivariate `mu` covariance replication;
- `corpairs(fit_group)` as the table that keeps residual and group-level rows
  separate;
- `summary(fit_group)$covariance` as the report-scale table with component
  SDs, correlation, covariance, and scale labels;
- `profile_targets(fit_group)` as the interval-readiness gate.

The example stays inside the implemented ordinary bivariate Gaussian
random-intercept surface. It does not teach the separate matching slope-only
`mu1`/`mu2` route, broader bivariate random slopes, random effects in `rho12`,
bivariate `meta_V()` plus random effects, mixed-response families, or
ordinary spatial group-level covariance as fitted syntax.

## Later Worked Tutorials

After Slices 90-91, the Slice 95 meta-analysis polish, the Slice 96 count NB2
tutorial, the Slice 97 proportion tutorial, and the Slice 98 bivariate
group-level covariance polish, the next candidates should be chosen one at a
time:

- a large-data benchmark article only after Phase 14 adds benchmark-backed
  evidence.

Do not add all of these at once. Each needs an implemented surface, a small data
story or transparent simulation, diagnostics, and clear unsupported-syntax
boundaries.
