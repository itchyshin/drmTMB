# Implementation Map Slices 326-340

This note turns the implementation-map roadmap into pre-code specifications.
It still does not add likelihood code. The goal is to make the next real
implementation slice small enough to review and useful enough for applied
users.

## Active Roles

Ada coordinates the roadmap, docs, PR state, and validation. Boole owns grammar
and reference discoverability. Pat checks whether a new applied user can choose
a fitted route. Darwin asks whether the next target answers a real ecological
or evolutionary question. Fisher owns simulation and identifiability gates.
Gauss and Noether keep q, covariance dimensions, and likelihood contracts
honest. Grace watches pkgdown and CI. Rose records stale-claim risks and team
learning.

No spawned subagents were running for this planning slice.

## Slice Table

| Slice | Lane | Status | User-facing result |
| --- | --- | --- | --- |
| 326 | Generic direct-SD issue spec | Completed as pre-code | Future `sd*()` work has an issue-ready grammar, compatibility, and reference-index checklist. |
| 327 | Direct-SD parser boundary matrix | Completed as pre-code | Ordinary `sd(group)`, current `sd_phylo*()`, and future level-targeted structured SD routes have separate parser outcomes. |
| 328 | Direct-SD tests and docs checklist | Completed as pre-code | The next direct-SD implementation must include malformed-input tests, examples, reference docs, and stale-name scans. |
| 329 | p8/q8 endpoint registry sketch | Completed as pre-code | Endpoint labels and block sizes are named before any q6/q8 syntax is opened. |
| 330 | p8/q8 staged implementation options | Completed as pre-code | q4 location-slope and constrained/block-diagonal routes are preferred before a full q8 unstructured block. |
| 331 | p8/q8 simulation gate | Completed as pre-code | p8/q8 cannot leave design until simulations vary group count, repeats, SD ratios, correlations, and boundary cases. |
| 332 | Spatial q4 pre-code checklist | Completed as pre-code | Spatial q4 is the first constant q4 parity candidate and needs a focused checklist before code. |
| 333 | Structured q4 diagnostics checklist | Completed as pre-code | q4 rows need Hessian, boundary, profile-target, and derived-interval status checks before teaching. |
| 334 | Poisson structured q1 smoke spec | Completed as pre-code | The first non-Gaussian structured candidate is a q1 Poisson `mu` structured intercept smoke, not a user-facing broad feature. |
| 335 | NB2 structured q1 practical spec | Completed as pre-code | NB2 `mu` structured intercept is the first practical count target after Poisson smoke. |
| 336 | Non-Gaussian structured ADEMP stub | Completed as pre-code | The candidate needs an ADEMP sheet before simulation code enters Phase 18. |
| 337 | User-route example expansion | Completed | The public map now gives more explicit fitted alternatives for planned direct-SD, q4, p8/q8, and non-Gaussian structured requests. |
| 338 | Stale-claim checklist | Completed | The validation scan now targets false fitted claims for generic `sd*()`, p8/q8, spatial q4, and non-Gaussian structured routes. |
| 339 | Roadmap and NEWS sync | Completed | Public and dev ledgers record these as pre-code slices. |
| 340 | After-task and validation | Completed locally | The after-task report and pkgdown checks close the slice set. |

## Slice 326-328: Generic Direct-SD Pre-Code Spec

Future generic direct-SD syntax should be issue-ready before parser work. The
minimum issue should answer:

| Question | Required decision before code |
| --- | --- |
| What does the formula target? | A random-effect SD surface, not residual `sigma` and not a latent correlation. |
| How is the dependence layer named? | Use an explicit level target, for example a future `level = "phylogenetic"` style, rather than guessing from the group name. |
| How do old names survive? | Existing `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` remain valid until a deliberate lifecycle decision. |
| How are bivariate endpoints named? | Endpoint naming must distinguish `mu1`, `mu2`, `sigma1`, and `sigma2` before examples are taught. |
| How does the reference index show it? | Ordinary `sd(group)` and structured direct-SD routes need separate discoverability text. |
| Which tests are mandatory? | Parser acceptance, unsupported sibling errors, prediction rows, profile-target status, and stale-name scans. |

That means the next direct-SD implementation should not begin by adding
`sd_spatial()`, `sd_animal()`, or `sd_relmat()` as parallel names. Those may be
compatibility aliases someday, but the primary design should be generic and
explicit.

## Slice 329-331: p8/q8 Pre-Code Spec

The p8/q8 language needs one registry before code:

| Registry class | Endpoints | Suggested implementation order |
| --- | --- | --- |
| q2 slope-only | `mu1:x`, `mu2:x` | Already fitted for ordinary bivariate Gaussian models. |
| q4 location slope | `mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, `mu2:x` | First future bivariate slope expansion candidate. |
| q6 partial location-scale | q4 location slope plus selected scale endpoints | Design only; use only if a clear biological question avoids all-eight covariance. |
| q8 all-endpoint slope | intercept and slope endpoints for `mu1`, `mu2`, `sigma1`, and `sigma2` | Highest risk; consider constrained or block-diagonal routes before unstructured q8. |

Simulation admission for any q4/q6/q8 slope endpoint must vary group count,
observations per group, slope SD, intercept SD, SD ratios, true correlations,
covariate spread, and boundary cases. The first tutorial should not teach q8
as routine; it should explain when a smaller q2 or q4 route answers the
scientific question.

## Slice 332-333: Spatial q4 Pre-Code Spec

Spatial q4 is the first constant structured q4 parity candidate because
phylogenetic, animal, and `relmat()` constant q4 routes are already fitted. The
spatial q4 issue should require:

- matching labelled `spatial()` terms across `mu1`, `mu2`, `sigma1`, and
  `sigma2`;
- clear separation from residual `rho12`;
- `sdpars`, `corpairs(level = "spatial")`, `summary()$covariance`,
  `profile_targets()`, and `check_drm()` rows;
- dense-comparator or deterministic covariance checks;
- explicit derived-unavailable q4 interval status unless an interval method
  is added;
- a small simulation smoke before user-facing tutorial claims.

This is a parity candidate, not an instruction to make spatial q4 routine or
to add spatial slopes, spatial `sigma` alone, or spatial `corpair()`
regressions at the same time.

## Slice 334-336: Non-Gaussian Structured Pre-Code Spec

The first non-Gaussian structured-dependence target should be one q1 `mu`
structured intercept. It should not include structured slopes, q4 covariance,
zero inflation, hurdle probability, or cross-parameter covariance.

| Target | Purpose | Required before user-facing claim |
| --- | --- | --- |
| Poisson `mu` q1 structured intercept | Algebra smoke for one non-Gaussian likelihood plus one structured random-effect precision | Likelihood, simulation recovery, extractor rows, `check_drm()`, direct SD target, malformed-input tests, and false-convergence diagnostics |
| NB2 `mu` q1 structured intercept | Practical overdispersed-count target | Everything in the Poisson smoke plus overdispersion-vs-structured-SD identifiability checks |

The first ADEMP sheet should be written before simulation code. It should name
estimands, data-generating parameters, sample-size and repeat grids, warning
ledgers, convergence criteria, interval-status expectations, and failure
conditions.

## Slice 337: User-Route Examples

| If a user asks for... | Fit now | Next planned gate |
| --- | --- | --- |
| spatial direct-SD regression | fitted spatial intercept/slope SDs and profile targets where available | generic direct-SD syntax design |
| animal or `relmat()` direct-SD regression | fitted intercept/slope SDs and `profile_targets()` | generic direct-SD syntax plus dense/sparse matrix scaling checks |
| p8/q8 individual-difference slopes | q2 slope-only `mu1`/`mu2`, ordinary Gaussian q > 2 `mu`, or univariate pieces | q4 location-slope registry and simulation gate |
| spatial q4 location-scale covariance | fitted q2 spatial location covariance, or fitted phylo/animal/relmat q4 if that layer matches the question | spatial q4 parity issue |
| phylogenetic or spatial count model | ordinary Poisson/NB2 `mu` random effects if a plain group is enough | Poisson q1 structured smoke, then NB2 q1 structured practical target |

## Slice 338-340: Maintenance Gate

After any future implementation in these lanes, update in one pass:

- `implementation-map`;
- `model-map`;
- README;
- ROADMAP;
- NEWS;
- family registry or formula grammar if syntax changes;
- check-log and after-task report;
- rendered pkgdown and stale-claim scans.

This is not clerical. It is how the package avoids teaching planned syntax as
if it were fitted.
