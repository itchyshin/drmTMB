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

The second post-#315 planning block closes the remaining non-Gaussian
structured gate without opening new code. It turns the rows after the Poisson q1
ADEMP sheet into route-specific contracts that future implementation issues can
copy without re-deciding the whole roadmap.

| Slice | Result | Boundary kept closed |
| --- | --- | --- |
| 389 | Non-Gaussian scale gate: count overdispersion, beta/BB precision, Gamma coefficient of variation, lognormal log-SD, and Student-t scale each need a family-specific structured-scale contract. | Do not treat a structured `mu` intercept as evidence for structured `sigma` or scale random effects. |
| 390 | Shape and ordinal gate: Student-t `nu`, future skewness/second-shape slots, ordinal cutpoints, and ordinal scale/discrimination remain separate from count `mu` structure. | Do not place random effects in shape, cutpoint, or ordinal-scale components until a family-specific likelihood and comparator exist. |
| 391 | Known-covariance boundary: `meta_V(V = V)` is known sampling covariance; `relmat()` is latent relatedness. | Do not reuse a known sampling-error matrix as a latent structured-effect route, or call latent relatedness a meta-analysis sampling covariance. |
| 392 | Extractor contract: every first slice must pre-name `sdpars`, `ranef()`, `profile_targets()`, `summary()`, and diagnostic labels before fitting. | Do not add a likelihood whose fitted quantities have no stable public names. |
| 393 | Diagnostic contract: require convergence, Hessian, replication, boundary, SD-ratio, family-specific, and malformed-neighbour checks. | Do not rely on optimizer return code alone. |
| 394 | Simulation contract: require ADEMP aims, DGP, estimands, methods, performance measures, ordinary comparator, failure ledger, MCSE reporting, and artifact manifest. | Do not admit broad Phase 18 grids from one smoke fit. |
| 395 | Interval contract: direct structured SD intervals may be first; derived correlations, response-scale summaries, and non-direct nonlinear functions must report unavailable status until validated. | Do not infer interval support from point-estimate extractors. |
| 396 | User-route fallback: each unsupported request should point to the nearest fitted fixed-effect, ordinary random-effect, or Gaussian structured alternative. | Do not leave applied users with only "planned" when a safer fit exists. |
| 397 | Error-message gate: unsupported `zi`, `hu`, slope, q2, q4, and cross-parameter structured requests must fail early with the family, component, layer, and nearest route named. | Do not let unsupported syntax reach TMB or fail as a generic parse error. |
| 398 | Formula grammar gate: non-Gaussian structured grammar remains closed unless the fitted scope and rejected neighbours are documented together. | Do not broaden `phylo()`, `spatial()`, `animal()`, or `relmat()` grammar implicitly from Gaussian support. |
| 399 | Documentation gate: implementation-map, model-map, family docs, NEWS, ROADMAP, check-log, and after-task report must move with any fitted-status change. | Do not let an implementation PR close with only tests or only prose. |
| 400 | Issue-template gate: create one issue per family, component, layer, q, and comparator combination. | Do not open a broad "non-Gaussian structured parity" issue as an implementation target. |
| 401 | Poisson first-issue outline: one non-zero-inflated Poisson `mu` q1 structured intercept, starting with phylogeny, with simulations, diagnostics, docs, and malformed neighbours. | No slopes, q2/q4, `zi`, `hu`, or cross-parameter covariance. |
| 402 | NB2 first-issue outline: one NB2 `mu` q1 structured intercept with fixed-effect `sigma`, overdispersion conditions, and ordinary NB2 comparator evidence. | No NB2 `sigma` structured effects, zero-inflated NB2 structure, or spatial/animal/`relmat()` parity until the first route recovers. |
| 403 | `zi`/`hu` future issue outline: probability-component random effects need a user problem, prediction semantics, diagnostics, and recovery evidence before fitting. | Fixed-effect `zi` and `hu` remain the recommended route for extra-zero questions. |
| 404 | Phase 18 admission note: non-Gaussian structured routes remain outside broad simulation until one narrow route passes recovery, diagnostics, intervals, and docs. | Do not roll the comprehensive simulation programme forward on planned status. |
| 405 | Closeout: stop with a map, issue-ready gates, and validation evidence. | Do not add untested likelihood code in the planning closeout. |

## Issue Template Fields For Future Implementation

Use this issue body shape for any route opened after these gates:

```text
Route:
- family:
- distributional parameter:
- structured layer:
- q:
- fitted formula:
- nearest fitted fallback:

Required implementation evidence:
- likelihood and parameter-scale contract:
- extractor names:
- profile/interval status:
- check_drm() rows:
- malformed-neighbour errors:
- ADEMP or recovery runner:
- user docs:
- stale-claim scan:
```

For the next code issue, the route should be:

```text
family: poisson(link = "log")
distributional parameter: mu
structured layer: phylo(tree = tree)
q: 1
formula: bf(count ~ x + phylo(1 | species, tree = tree))
fallback: ordinary Poisson/NB2 mu random effects when the grouping is exchangeable
```

The NB2 issue can use the same shape only after the Poisson q1 smoke/recovery
runner shows whether a structured count SD can be separated from count mean and
replication stress. The `zi` and `hu` issues should not start from syntax; they
should start from a biological probability-component question, such as whether a
structured absence process is identifiable apart from low expected abundance.

Usefulness check: the next implementation issue should be small enough that a
reviewer can say exactly which family, parameter, layer, q, extractor row,
diagnostic row, interval row, simulation artifact, and user fallback changed.
