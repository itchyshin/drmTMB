# Implementation Map Slices 356-405

These slices close one fitted Gaussian spatial parity lane and then stop. Slices
356-380 are implementation and evidence for constant coordinate-spatial q=4
location-scale covariance. Slices 381-405 are planning only for non-Gaussian
structured dependence; they do not add Poisson, NB2, zero-inflation, hurdle,
ordinal, bounded-response, shape, or mixed-response structured likelihood code.

The applied-user purpose is practical. A user who has two Gaussian responses can
now ask whether nearby sites share latent location and scale deviations through
one constant spatial block. A count, hurdle, zero-inflated, ordinal, or bounded
response user still gets a clear fitted alternative and a design path, not an
untested structured-effect claim.

## Slice 356-370: Spatial q4 Fitted Parity

The fitted claim is narrow:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
    sigma1 = ~ z + spatial(1 | p | site, coords = coords),
    sigma2 = ~ z + spatial(1 | p | site, coords = coords),
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = dat
)
```

This fits one q=4 latent coordinate-spatial block with four endpoint SDs and six
latent correlations: location-location, four location-scale rows, and
scale-scale. The block is constant, intercept-only, and Gaussian bivariate. It
reuses the existing structured q4 backend and keeps residual `rho12` separate
from latent spatial correlation.

Required evidence:

- parser admission for matching labelled all-four `spatial()` terms;
- parser rejection for partial, unlabelled, mismatched, and slope q4 spatial
  requests;
- `sdpars$mu` labels for `mu1`, `mu2`, `sigma1`, and `sigma2` spatial endpoints;
- six `corpairs(level = "spatial")` rows and matching `summary()$covariance`
  rows;
- `profile_targets()` rows that mark q4 correlations as derived and not
  profile-ready;
- `check_drm()` row `biv_spatial_q4_covariance`;
- focused tests in `test-spatial-gaussian`.

Usefulness check: the feature is useful when a user can fit the same constant
site-level location-scale question for spatial coordinates that they can already
ask for phylogenetic, animal-model, or `relmat()` structure.

## Slice 371-380: Spatial q4 Evidence And Map Closeout

The fitted route should be visible without making spatial look broader than it
is. The public status surfaces should say that spatial q4 is fitted only for the
constant bivariate Gaussian all-four endpoint block. They should still keep these
routes planned:

- mesh or SPDE spatial fields;
- multiple spatial slopes and spatial slope correlations;
- standalone or partial spatial `sigma` terms outside the fitted all-four q4
  block;
- direct spatial SD surfaces;
- predictor-dependent spatial `corpair()` regressions;
- simultaneous `phylo()` plus `spatial()` layers;
- non-Gaussian spatial structured effects.

Usefulness check: a user should leave the map knowing both the exact spatial q4
syntax they can run and the nearest fitted alternative when their desired route
is still planned.

## Slice 381-388: Non-Gaussian Structured q1 Planning

The first post-#315 planning block closes the front half of the
non-Gaussian structured gate. It starts with issue state and user-route clarity,
then narrows the first real candidate to Poisson q1 phylogenetic `mu`.

| Slice | Result | Boundary kept closed |
| --- | --- | --- |
| 381 | Family inventory separates ordinary counts, zero-inflated counts, hurdle counts, bounded responses, ordinal responses, robust continuous responses, and mixed-response bivariate candidates. | Do not infer structured support for all non-Gaussian families from the Poisson q1 row. |
| 382 | Component inventory separates `mu`, `sigma`, `zi`, `hu`, shape or `nu`, future second shape `tau`, cutpoints, and residual coscale `rho12`. | Do not place structured random effects in `sigma`, `zi`, `hu`, shape, cutpoints, or `rho12` without a family-specific contract. |
| 383 | Layer inventory scores `phylo()`, `spatial()`, `animal()`, and `relmat()` separately before selecting a first fitted route. | Do not promote Gaussian spatial, animal, or `relmat()` evidence to count models. |
| 384 | Poisson q1 is the algebra gate: one non-zero-inflated Poisson response, `mu` only, one phylogenetic structured intercept. | No Poisson slopes, q2/q4 covariance, zero inflation, hurdle probability, or cross-parameter covariance. |
| 385 | NB2 q1 remains the first practical count target after Poisson, because overdispersion can compete with structured SD. | NB2 `phylo()`, `spatial()`, `animal()`, and `relmat()` remain planned until the Poisson grid is informative. |
| 386 | Zero-inflation stays fixed-effect-only until a separate probability-component use case, diagnostic, and prediction contract exists. | No structured `zi` random effects. |
| 387 | Hurdle probability stays fixed-effect-only until hurdle-specific recovery and interpretation are specified. | No structured `hu` random effects. |
| 388 | Correlated or structured count slopes wait until q1 intercept recovery is reliable. | No count slope covariance, no structured count slopes, and no q2/q4 count blocks. |

The candidate order is:

1. Non-zero-inflated Poisson q1 `mu` structured intercept as the algebra smoke.
2. NB2 q1 `mu` structured intercept as the first practical count target.
3. Only after those pass recovery and diagnostics, revisit slopes, q2/q4
   covariance, `zi`, `hu`, `sigma`, shape, ordinal, bounded-response, and
   mixed-response structural routes.

The planning table keeps components separate:

| Component | Current status | First planning question |
| --- | --- | --- |
| Poisson `mu` | Ordinary random intercepts and independent slopes are fitted; structured `mu` is planned. | Which one structured layer gives the safest q1 smoke? |
| NB2 `mu` | Ordinary random intercepts and independent slopes are fitted; structured `mu` is planned. | Does overdispersion separate from the structured SD across realistic group counts? |
| `zi` | Fixed effects only. | What user problem justifies a zero-inflation random effect before count `mu` structure is proven? |
| `hu` | Fixed effects only. | Does hurdle probability need a separate latent layer or a fixed-effect fallback first? |
| Non-Gaussian `sigma` or scale | Fixed effects where families support them. | Which scale is estimated, and how is it separated from the latent structured SD? |
| Shape, skewness, or ordinal cutpoints | Fixed effects or planned family-specific routes. | Can shape or cutpoint variation be identified separately from heteroscedasticity and structured location? |
| `animal()` and `relmat()` | Gaussian structured routes are fitted; non-Gaussian routes are planned. | Does the first count route use one known matrix and one q1 `mu` intercept only? |
| `spatial()` | Gaussian structured routes are fitted through q4; non-Gaussian routes are planned. | Does the count route need coordinate structure before ordinary count random effects are exhausted? |

Acceptance gates for the first fitted non-Gaussian structured route:

- one family, one distributional parameter, one dependence layer, and q=1;
- ordinary random-effect comparator when available;
- family-specific likelihood contract and scale reporting;
- extractor labels before tutorial claims;
- direct SD interval status or explicit unavailable status;
- `check_drm()` replication, boundary, Hessian, and family-specific diagnostics;
- ADEMP simulation sheet before broad Phase 18 admission;
- user-facing fallback text for nearby unsupported `zi`, `hu`, slope, q2, q4,
  scale, and shape requests.

The first ADEMP sheet is now
`docs/design/70-phase-18-poisson-structured-q1-ademp.md`. It names estimands,
data-generating parameters, sample-size and repeat grids, warning ledgers,
convergence criteria, interval-status expectations, and failure conditions for
the Poisson q1 phylogenetic `mu` route. That sheet is a simulation-admission
gate, not permission to add broad structured count likelihoods.

## Slice 389-405: Remaining Non-Gaussian Structured Gates

The remaining planned rows should stay design-first:

- non-Gaussian scale and shape gates;
- ordinal mixed-model gates;
- known-covariance versus latent-relatedness boundaries;
- extractor, diagnostic, simulation, and interval contracts;
- user-route fallback and error-message gates;
- one issue template per family-layer-component combination.

Usefulness check: the next implementation issue should be small enough that a
reviewer can say exactly which family, parameter, layer, q, extractor row,
diagnostic row, and user-facing fallback changed.
