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

## Immediate Tutorial Priorities

- Location-scale Gaussian: variance as biological signal, not nuisance.
- Random-effect scale models: residual `sigma` versus `sd(group)`.
- Bivariate location-coscale: `rho12` as residual coupling after means and
  residual SDs are modelled.
- Meta-analysis: Gaussian regression with `meta_known_V(V = V)`, including
  diagonal, block-diagonal, and dense row-paired covariance examples.
- Phylogenetic location effects: ultrametric tree input, sparse A-inverse route,
  and the distinction between residual and structured correlations.

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

## Numerical Guards

Internal numerical guards should not dominate teaching tables. For example,
residual correlation is implemented as:

```text
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

Tutorial prose should usually describe this as:

```text
rho12_i = tanh(eta_rho12_i)
```

with a note that the small multiplier keeps covariance matrices strictly
positive definite near the correlation boundaries. It is not a biological
scaling factor.
