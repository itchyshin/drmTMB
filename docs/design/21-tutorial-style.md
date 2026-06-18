# Tutorial Style Contract

`drmTMB` tutorials should teach models, not just syntax. Reference examples can
stay small and fast, but articles and tutorials should follow the style of the
Nakagawa group online supplements: scientific question, data preparation,
symbolic model, R syntax, output, interpretation, diagnostics, and limitations.

## Reader

The first reader is an applied ecology, evolution, or environmental-science
user who understands regression but may not yet know distributional regression.
The package should remain general, but the examples should often use biological
questions because that is where the first audience will come from.

## Required Shape For Worked Tutorials

Each major tutorial should include:

1. A biological or applied question stated before the model.
2. A short description of the response, predictors, grouping factors, and any
   known covariance matrix.
3. Symbolic equations paired with the exact `drmTMB` syntax.
4. A fitted model object and at least one printed output, such as
   `summary(fit)`, `fixef(fit)`, `sigma(fit)`, `rho12(fit)`, `corpairs(fit)`,
   or `check_drm(fit)`.
5. A plot or table that maps model output back to the scientific question.
6. A plain-language interpretation of the location, scale, shape, or coscale
   coefficients.
7. A short note on what the model does not estimate.

## Guide Versus Tutorial Split

The pkgdown site should keep orientation guides separate from worked
tutorials. A guide helps the reader decide what model surface is implemented,
which parameter name to use, and which article to read next. A tutorial fits a
model from data, prints output, and interprets the result.

The current top-level article groups are:

- Getting Started: installation, first model, and the learning path.
- Model Guides: status maps, parameter-scale vocabulary, family choice,
  post-fit workflow, and large-data advice.
- Tutorials: worked analyses for location-scale, robust continuous responses,
  bivariate residual `rho12`, meta-analysis, and structural dependence.
- Developer Notes: formula grammar, family implementation, likelihood testing,
  and source-map material.

This split keeps "Tutorials" from becoming a mixed drawer of status maps,
reference pages, and worked examples. When a page mostly answers "can I fit
this and what should I read next?", put it under Model Guides. When it answers
"how do I fit and interpret this analysis?", put it under Tutorials.

## Immediate Tutorial Priorities

- Location-scale Gaussian: variance as biological signal, not nuisance.
- Random-effect scale models: residual `sigma` versus `sd(group)`.
- Bivariate location-coscale: `rho12` as residual coupling after means and
  residual SDs are modelled.
- Meta-analysis: Gaussian regression with preferred `meta_V(V = V)`, including
  diagonal, block-diagonal, and dense row-paired covariance examples;
  deprecated `meta_known_V(V = V)` remains a compatibility alias.
- Phylogenetic location effects: ultrametric tree input, sparse A-inverse route,
  and the distinction between residual and structured correlations.

## Candidate Worked Tutorials

Future tutorials should start from a biological question and then write the
symbolic model with meaningful variable names. Do not add all of these at once.
Pick the next one only when the implemented surface, example data, diagnostics,
and interpretation can be kept concrete.

| Candidate | Biological question | Model sketch |
|---|---|---|
| Count abundance and extra zeros | Do restoration plots differ in expected species counts, and are some zeros from a separate absence process? | Implemented as `vignettes/count-nbinom2.Rmd` with `count ~ habitat + offset(log(effort))`, `sigma ~ habitat`, and optional `zi ~ surface` using `family = nbinom2()` |
| Positive counts after conditional sampling | When zeros are absent by design, do traps or survey units differ in positive abundance? | `count ~ habitat`, `sigma ~ habitat` with `family = truncated_nbinom2()`; add `hu ~ habitat` only for hurdle zeros |
| Continuous proportions | Does leaf damage proportion change with treatment, and does among-leaf variability also change? | Implemented in `vignettes/proportion-beta-binomial.Rmd` with `cover ~ grazing`, `sigma ~ grazing`, and `family = beta()` for values strictly between 0 and 1 |
| Successes out of trials | Does germination probability vary by treatment beyond binomial sampling error? | Implemented in `vignettes/proportion-beta-binomial.Rmd` with `cbind(germinated, failed) ~ treatment`, `sigma ~ treatment`, and `family = beta_binomial()` |
| Bivariate individual differences | Do individuals with higher average activity also tend to have higher average boldness after accounting for residual coupling? | Implemented in `vignettes/bivariate-coscale.Rmd` with matching `(1 \| p \| ID)` random intercepts in `mu1` and `mu2`, residual `rho12`, `corpairs()`, and `summary(fit)$covariance` |
| Ordered severity scores | Does disease severity shift along an ordered scale? | `severity ~ treatment` with `family = cumulative_logit()`; keep scale effects planned until implemented |

Each candidate needs the same teaching arc: question, data, symbolic equations,
matching R syntax, fitted output, a table or plot on the response scale,
diagnostics, and a short unsupported-syntax note.

## Style Lessons From Existing Tutorials

The location-scale meta-analysis, phylogenetic location-scale, ecology
location-scale, phylo-spatial, multinomial GLMM, phylogenetic simulation, and
`glmmTMB::equalto()` tutorial pages use the right pattern: load real data or a
transparent simulation, fit a sequence of increasingly rich models, print
model summaries, visualize estimates, and end each section by explaining what
the output says.

`drmTMB` should copy that teaching structure, not the exact code or wording.
When examples use simulated data because a feature is still young, the tutorial
should say that clearly and explain which real-data use case the simulation
stands in for.

These tutorials still need a deeper source-map pass before the first polished
`drmTMB` tutorial release. Jason should extract the section structure, data
flow, output displays, visual summaries, interpretation paragraphs, and
session/reproducibility conventions from each tutorial. Pat should then read
the drafted `drmTMB` tutorials as a first-time applied user and flag anything
that lacks output, interpretation, or recovery advice.

The Phase 6b source map in
`docs/design/32-phase-6b-tutorial-source-map.md` adds the required slope and
variance-component interpretation layer. Use it when a tutorial explains fixed
mean slopes, residual-scale slopes, mean random slopes, residual-scale random
slopes, `sd(group)` models, residual `rho12`, or `corpairs()` rows.

The Slice 89 worked-example inventory in
`docs/design/37-worked-example-inventory.md` records which current pages are
worked tutorials and which are guides. Use that inventory before adding another
example: the next tutorial should fill a named gap rather than lengthening a
page that is already doing a different job.

## Numerical Guards

Internal numerical guards should not dominate teaching tables. For example,
residual correlation is implemented as:

```text
rho12_i = 0.999999 * tanh(eta_rho12_i)
```

Tutorial prose should usually describe this as:

```text
rho12_i = tanh(eta_rho12_i)
```

with a note that the small multiplier keeps covariance matrices strictly
positive definite near the correlation boundaries. It is not a biological
scaling factor.
