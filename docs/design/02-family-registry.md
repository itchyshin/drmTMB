# Family Registry

Each family should be represented by a small structured object.

## Required Fields

- `name`
- `n_response`
- `dpars`
- `links`
- `inverse_links`
- `bounds`
- `density_id`
- `simulate`
- `starting_values`
- `check_data`
- `native_parameter_meaning`
- `fitted_response_rule`
- `variance_rule`

## Link and Response-Scale Contract

Distributional parameter names do not determine links by themselves. For
Gaussian and Student-t models, `mu` currently uses an identity link and
`fitted()` returns `mu`. For lognormal models, `mu` is still identity-link on
the modelled parameter, but the modelled parameter is the mean of `log(y)`;
`fitted()` returns `exp(mu + sigma^2 / 2)` instead.

Families must declare both the native parameter scale and the fitted response
rule. The implemented Gamma mean-CV family uses `log(mu)` and `log(sigma)`,
with `sigma` interpreted as a coefficient of variation. The implemented
Poisson mean family uses `log(mu)` and has no fitted `sigma` distributional
parameter. The implemented zero-inflated Poisson extension uses the same
Poisson route with `logit(zi)` and `fitted()` returning `(1 - zi) * mu`. The
implemented negative-binomial 2 family uses `log(mu)` and `log(sigma)`, with
`sigma` interpreted as an overdispersion scale; its zero-inflated extension
adds `logit(zi)` and the same fitted-response rule `(1 - zi) * mu`. Beta and
beta-binomial models use `logit(mu)` and `log(sigma)`, with `sigma` mapped to
internal precision through `phi = 1 / sigma^2`. The plain binomial first slice
uses `logit(mu)` for a fixed-effect event probability and has no public
`sigma`. The first cumulative-logit ordinal path uses an identity-link latent
`mu`, ordered cutpoints, and `fitted()` returning the expected ordered-category
score.

The detailed contract is in `docs/design/19-family-link-contract.md`. Treat it
as a prerequisite before implementing additional count, ordinal-scale,
denominator-aware, or positive-continuous families.

## Slice 283 Current Family and Evidence Map

This map is an audit of current package scope, not new grammar. The
random-effect column lists only syntax that is fitted now. A row marked
fixed-effect only can still have distributional-parameter formulas such as
`sigma ~ x`, `nu ~ x`, `zi ~ x`, or `hu ~ x`; it cannot include bar terms in
that parameter until the row has likelihood, extractor, interval, diagnostic,
and recovery evidence.

| Public route | Distributional parameters and links | Shape or coscale slot | Random-effect allowance now | Evidence state |
| --- | --- | --- | --- | --- |
| `gaussian()` | `mu` identity; `sigma` log | none | Fixed effects; ordinary `mu` random intercepts, independent slopes, q > 2 numeric slope blocks, selected labelled intercept covariance; Gaussian `sigma` random intercepts, independent slopes, and unlabelled correlated intercept-slope or multi-slope blocks; selected `sd(group)` SD-surface formulas; Gaussian-only `meta_V()`, `phylo()`, and `spatial()` routes are separate rows in the readiness matrix. | Covered by Gaussian location-scale, random-effect, profile, `check_drm()`, meta-analysis, phylogenetic, and spatial tests. |
| `student()` | `mu` identity; `sigma` log; `nu` logm2 | `nu = 2 + exp(eta_nu)` is tail shape or degrees of freedom | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric `mu` slopes. One unlabelled `spatial()` intercept or one-slope route on `mu` is recovery grade, and one `phylo()` intercept on `nu` is diagnostic grade, one endpoint at a time. Correlated Student-t slopes, labelled covariance, `sigma` random effects, other `nu` random effects, other structured providers, known covariance, and bivariate Student-t models remain planned. | `tests/testthat/test-student-location-scale.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; `tests/testthat/test-nongaussian-scale-boundary.R`; random-effect recovery and shape-boundary tests. |
| `skew_normal()` | `mu` identity; `sigma` log; `nu` identity | `nu` is residual slant/asymmetry on the public moment parameterization | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric slopes at recovery grade. Random effects in `sigma` or `nu`, correlated/labelled `mu` slopes, structured effects, known covariance, bivariate skew-normal models, `rho12`, latent `skew(id)`, and aliases such as `skew ~ x` remain planned or blocked. | `tests/testthat/test-skew-normal-location-scale.R`; `tests/testthat/test-skew-normal-density-contract.R`; `tests/testthat/test-arc2a-mu-random-intercept.R`; `tests/testthat/test-arc2b-mu-random-slope.R`; source-level recovery, normal-limit, sign-orientation, false-positive, density, simulation, diagnostic, and artifact tests. |
| `lognormal()` | `mu` identity on `log(y)`; `sigma` log | none | Fixed effects plus separate ordinary gates for `mu` random intercepts/independent numeric slopes or one `sigma` random intercept. The exact sigma-intercept ledger domain is inference-ready with caveats. Combining `mu` and `sigma` random effects, `sigma` slopes, labels, structured effects, and bivariate or mixed lognormal models remain unsupported or planned. | `tests/testthat/test-lognormal-location-scale.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; `tests/testthat/test-arc2c-sigma-random-intercept.R`; `tests/testthat/test-family-link-contract.R`; random-effect recovery and Arc 4a coverage evidence. |
| `Gamma(link = "log")` | `mu` log; `sigma` log | no public `nu`; internal shape is `1 / sigma^2` | Fixed effects plus separate ordinary gates for `mu` random intercepts/independent numeric slopes or one `sigma` random intercept at recovery grade; one unlabelled `relmat()` intercept or one-slope route on `mu` is also recovery grade; non-log Gamma links remain unsupported. Combining `mu` and `sigma` random effects, `sigma` slopes, labels, other structured providers, and bivariate or mixed Gamma models remain unsupported or planned. | `tests/testthat/test-gamma-location-scale.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; `tests/testthat/test-arc2c-sigma-random-intercept.R`; `tests/testthat/test-family-link-contract.R`; random-effect recovery tests. |
| `tweedie()` | `mu` log; `sigma` log; `nu` logit12 | `nu = 1 + plogis(eta_nu)` is the Tweedie power; internal dispersion is `phi = sigma^2` | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric slopes at recovery grade, with intercept-only `nu ~ 1`. Predictor-dependent `nu`, `sigma` random effects, correlated/labelled `mu` slopes, structured effects, bivariate Tweedie, mixed-response models, zero-inflation aliases, and hurdle aliases remain planned. | `tests/testthat/test-tweedie-location-scale.R`; `tests/testthat/test-arc2a-mu-random-intercept.R`; `tests/testthat/test-arc2b-mu-random-slope.R`; high-zero and low-zero recovery, random-effect recovery, fitted-response, simulation, and malformed-neighbour tests. |
| `beta()` | `mu` logit; `sigma` log | no public `nu`; internal precision is `phi = 1 / sigma^2` | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric `mu` slopes for strict `(0, 1)` responses. One unlabelled `animal()` intercept or one-slope route on `mu`, or one intercept on `sigma`, is fitted at recovery grade, one endpoint at a time. Correlated beta slopes, labelled covariance, ordinary `sigma` random effects, exact 0/1 boundary mass, `zoi`/`coi`, other structured providers, and bivariate or mixed bounded-response models remain planned. | `tests/testthat/test-beta-location-scale.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; `tests/testthat/test-family-link-contract.R`; bounded-response boundary tests; fixed-effect Wald interval row checks; random-effect recovery tests. |
| `zero_one_beta()` | `mu` logit; `sigma` log; `zoi` logit; `coi` logit | no public `nu`; interior precision is `phi = 1 / sigma^2`; `zoi`/`coi` describe exact-boundary mass | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric slopes at recovery grade for continuous `[0, 1]` responses with exact structural zeroes or ones. Correlated or labelled `mu` slopes, `sigma`/`zoi`/`coi` random effects, structured effects, known covariance, denominator syntax, and bivariate or mixed bounded-response models remain planned. | `tests/testthat/test-zero-one-beta.R`; `tests/testthat/test-family-link-contract.R`; `tests/testthat/test-arc2a-mu-random-intercept.R`; `tests/testthat/test-arc2b-mu-random-slope.R`; `tests/testthat/test-phase18-zero-one-beta-fixed-effect.R`; independent mixture-likelihood, recovery, fitted-response, simulation, one-sided-boundary, malformed-neighbour, and Phase 18 artifact-helper tests. |
| `stats::binomial(link = "logit")` | `mu` logit | no public `sigma`; no extra-binomial variation | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric slopes for 0/1 Bernoulli and two-column `cbind(successes, failures)` responses. Only the exact `mc-0061` independent-slope domain is inference-ready with caveats. Correlated or labelled slopes, structured effects, bivariate or mixed responses, non-logit links, factor responses, proportions plus `weights`, and `weights = trials` remain unsupported. | `tests/testthat/test-binomial-response.R`; `tests/testthat/test-arc2b-mu-random-slope.R`; fixed-path `stats::glm()` parity, recovery tests, and corrected Arc 4a coverage evidence. |
| `beta_binomial()` | `mu` logit; `sigma` log | no public `nu`; internal precision is `phi = 1 / sigma^2` with row trials | Fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric `mu` slopes for two-column `cbind(successes, failures)` responses. Correlated beta-binomial slopes, labelled covariance, `sigma` random effects, `zoi`/`coi`, structured effects, and bivariate or mixed bounded-response models remain planned. | `tests/testthat/test-beta-binomial.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; `tests/testthat/test-family-link-contract.R`; scale and bounded-response boundary tests; fixed-effect Wald interval row checks; random-effect recovery tests. |
| `poisson(link = "log")` | `mu` log | none; no modelled `sigma` | Non-zero-inflated Poisson fits fixed effects plus ordinary unlabelled `mu` random intercepts, independent numeric `mu` slopes, one q=1 structured `mu` intercept from `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, and one unlabelled intercept-plus-one-slope term from `phylo()`, `spatial()`, `animal()`, or `relmat()`. Correlated slopes, labelled covariance, pure or multiple structured count slopes, and simultaneous structured types remain planned. | `tests/testthat/test-poisson-mean.R`; `tests/testthat/test-count-structured-mu.R`; `tests/testthat/test-nongaussian-structured-boundary.R`; `tests/testthat/test-phase18-poisson-mu-random-effect.R`; comparator, profile-target, extractor, diagnostic, and opt-in smoke-runner checks. |
| `poisson(link = "log")` with `zi ~ ...` | `mu` log; `zi` logit | `zi` is structural-zero probability, not shape | Fixed-effect `mu` and `zi` plus one exact diagnostic-only q1 `zi ~ spatial(1 | id, coords = coords)` intercept. Count-side random effects and every other `zi` random-effect route remain blocked. | `tests/testthat/test-zi-poisson.R`; `tests/testthat/test-nongaussian-structured-boundary.R`; focused local-fit/extractor and fail-closed neighbour tests. |
| `nbinom2()` | `mu` log; `sigma` log | no public `nu`; internal size is `1 / sigma^2` | Non-zero-inflated NB2 fits fixed `sigma` formulas plus ordinary unlabelled `mu` random intercepts, independent numeric `mu` slopes, the first ordinary log-`sigma` random intercept, one q=1 structured `mu` intercept from `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, one unlabelled intercept-plus-one-slope `mu` term from `phylo()`, `spatial()`, `animal()`, or `relmat()`, and exact q1 structured `sigma` intercept-plus-one-slope routes for those same four providers at recovery grade. Correlated ordinary slopes, labelled covariance, joint `mu`/`sigma` random effects, pure or multiple structured count slopes, zero-inflated NB2 structure, ordinary NB2 `sigma` slopes, richer structured sigma blocks, and structured-sigma intervals/coverage remain planned. | `tests/testthat/test-nbinom2-location-scale.R`; `tests/testthat/test-count-structured-mu.R`; `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`; scale-boundary, profile-target, NB2 `sigma` random-intercept, phylogenetic q=1 smoke, extractor, and diagnostic checks. |
| `nbinom2()` with `zi ~ ...` | `mu` log; `sigma` log; `zi` logit | `zi` is structural-zero probability | Fixed-effect `mu`, `sigma`, and `zi` plus one exact local-fit q1 `mu ~ spatial(1 | id, coords = coords)` route with fixed `zi`. Other count-side, `sigma`, and `zi` random effects are blocked. | `tests/testthat/test-zi-nbinom2.R`; focused local-fit/extractor, inflation, and scale-boundary tests. |
| `truncated_nbinom2()` | `mu` log; `sigma` log | no public `nu`; internal size is `1 / sigma^2` | Positive-count data support fixed effects plus ordinary unlabelled `mu` random intercepts and independent numeric `mu` slopes. Hurdle NB2 also fits one diagnostic-only q=1 `hu ~ relmat(1 | id, K/Q = ...)` intercept. Correlated zero-truncated slopes, labelled covariance, `sigma` random effects, other structured effects, and hurdle random effects beyond that exact intercept remain planned. | `tests/testthat/test-truncated-nbinom2-location-scale.R`; `tests/testthat/test-nongaussian-mu-random-slopes.R`; count-kernel, random-effect, extractor, diagnostic, and scale-boundary tests. |
| `truncated_nbinom2()` with `hu ~ ...` | `mu` log; `sigma` log; `hu` logit | `hu` is hurdle-zero probability | Fixed-effect `mu`, `sigma`, and `hu` plus one exact diagnostic-only q1 `hu ~ relmat(1 | id, K/Q = ...)` intercept. Positive-count random effects and every other hurdle-side structured route remain blocked. | `tests/testthat/test-hurdle-nbinom2.R`; focused local-fit/extractor and fail-closed neighbour tests. |
| `cumulative_logit()` | `mu` identity plus ordered cutpoints | cutpoints are ordered thresholds; no fitted `sigma` | Fixed-effect location plus ordinary unlabelled `mu` random intercepts and independent numeric slopes at recovery grade, and one exact unlabelled q1 `mu ~ phylo(1 | id, tree = tree)` intercept with local point-fit/extractor evidence. Other structured providers, scale, discrimination, and interval/coverage promotion for the phylogenetic gate remain blocked or planned. | `tests/testthat/test-cumulative-logit.R`; `tests/testthat/test-arc2a-mu-random-intercept.R`; `tests/testthat/test-arc2b-mu-random-slope.R`; ordinal recovery, profile-target, and boundary checks. |
| `c(gaussian(), gaussian())`, `list(gaussian(), gaussian())`, `biv_gaussian()` | `mu1`, `mu2` identity; `sigma1`, `sigma2` log; `rho12` guarded atanh | `rho12` is residual coscale or correlation, not group, phylogenetic, or spatial covariance | Fixed effects; selected matching labelled random-intercept covariance blocks; matching slope-only ordinary `mu1`/`mu2`, `sigma1`/`sigma2`, and same-response `mu`/`sigma` covariance; q4/q6 location blocks; the first all-four q8 endpoint diagnostic block; selected phylogenetic location and location-scale blocks; constant coordinate-spatial q=2 `mu1`/`mu2` location covariance; constant coordinate-spatial q=4 location-scale covariance as extractor/diagnostic smoke. Broader q8 endpoint variants, q8 coverage/power, and mixed-response bivariate families remain planned. | `tests/testthat/test-biv-gaussian.R`; `tests/testthat/test-corpairs.R`; `tests/testthat/test-spatial-gaussian.R`; `tests/testthat/test-phase18-biv-gaussian-q2-scale-slope.R`; bivariate profile, summary, phylogenetic, spatial, and Phase 18 q2 scale-slope tests. |

Planned family rows stay out of fitted examples until they have the same
evidence pattern. `skew_normal()` is now a fitted first slice rather than a
planned example: use it only for univariate fixed-effect residual asymmetry
with public `mu = E[y]`, public `sigma = SD[y]`, and `nu` as the residual slant.
Skew-t models, latent `skew(id)` grammar, bivariate skew-normal models, random
effects, structured effects, known covariance, and aliases such as `skew ~ x`
remain planned or design-only.
The first Tweedie row now uses public `sigma = sqrt(phi)`; comparator tests
against software that reports Tweedie dispersion `phi` must name the square
transform explicitly.

The plain binomial row is intentionally not `beta_binomial()`. Use
`stats::binomial(link = "logit")` when the modelled target is an event
probability with binomial sampling variation only. Use `beta_binomial()` when
the data are success counts with extra-binomial variation. Use `beta()` or
`zero_one_beta()` for continuous proportions. The binary `impute_model(...,
family = binomial())` route belongs to missing-predictor integration and is not
the primary response-family path documented in this row.

## Distributional Parameter Naming

Use the GAMLSS convention from Rigby and Stasinopoulos (2005) as the default
parameter vocabulary:

- `mu`: location or mean-like parameter;
- `sigma`: residual scale, dispersion, or standard-deviation-like parameter;
- `nu`: first shape parameter;
- `tau`: second shape parameter.

For bivariate Gaussian models, residual `rho12` is the current coscale
parameter: it models residual correlation after `mu1`, `mu2`, `sigma1`, and
`sigma2` are accounted for. Do not use coscale for phylogenetic, spatial, or
ordinary group-level correlations unless the text explicitly names those as
separate non-residual covariance layers.

The interpretation of `nu` and `tau` is family specific. In a skew-normal-like
family, `nu` can be the skewness/shape parameter. In a Student-t-like family,
`nu` may instead be tail shape or degrees of freedom. In a skew-t family, the
preferred direction is `mu`, `sigma`, `nu`, and `tau`, with documentation
explaining which shape controls asymmetry and which controls tails.

For the implemented Tweedie family, `nu` is the power parameter constrained
between 1 and 2. `sigma` is the public scale with internal dispersion
`phi = sigma^2`, so Tweedie variance is reported to users as
`Var[y] = sigma^2 * mu^nu`. Comparator tests against software that reports
Tweedie `phi` should square public `sigma` explicitly.

Human-readable aliases such as `skew` or `df` can be considered later, but the
canonical internal and documented names should stay consistent unless there is a
strong reason not to.

## Slice 286 Continuous Shape Boundary

Continuous shape work has one fitted path and several planned neighbours:

| Surface | Fitted state | Boundary before simulation |
| --- | --- | --- |
| Student-t `nu ~ ...` | Implemented for fixed-effect univariate `student()` models as `nu = 2 + exp(eta_nu)`; ordinary `mu` random intercepts and independent slopes are separate first-slice location paths; the exact `nu ~ phylo(1 | id, tree = tree)` gate has diagnostic-grade point-fit evidence. | Keep other `nu` random effects, known sampling covariance, other structured shape paths, and bivariate Student-t paths out of simulation grids until each has likelihood, extractor, diagnostic, interval, and recovery evidence. |
| Skew-normal `nu ~ ...` | Implemented as a fixed-effect univariate `skew_normal()` first slice with public `mu = E[y]`, public `sigma = SD[y]`, and `nu` as the slant/shape parameter; ordinary unlabelled `mu` random intercepts and independent numeric slopes are recovery-grade. | Keep `sigma`/`nu` random effects, correlated or labelled `mu` slopes, known sampling covariance, structured effects, bivariate skew-normal models, latent `skew(id)`, and alias grammar out of simulation grids until each has likelihood, extractor, diagnostic, interval, comparator, and recovery evidence. |
| Skew-t `nu ~ ...`, future `tau ~ ...` | Planned after the skew-normal gate. | Choose and document which parameter controls asymmetry and which controls tails before adding syntax, examples, or simulations. |
| Future `skew(id) ~ ...` | Design-only latent-effect skewness grammar. | Do not treat this as an alias for residual `nu ~ ...`; require simulations separating residual skewness, heteroscedasticity, ordinary random effects, and latent-effect skewness. |

There are two skewness levels, and they should not be mixed in one
implementation slice. The implemented `skew_normal()` path models residual or
observation-level skewness through a family shape formula such as `nu ~ x`,
where the conditional residual distribution is asymmetric. Latent group-level
skewness would need a separate future grammar such as `skew(id) ~ x`, analogous
to `sd(id) ~ x` but targeting the distribution of the `id` random effects.
`drmTMB` should harden residual shape/skewness first, then add latent-effect
skewness only after simulations show it can be distinguished from residual
skewness, heteroscedasticity, and ordinary random-effect variation.

## Slice 190-192 Non-Gaussian Random-Effect Gate

The first non-Gaussian random-effect expansion was ordinary Poisson `mu` random
intercepts plus independent numeric slopes, not scale, shape, zero-inflation,
hurdle, ordinal, or broad structured random effects. The current structured
front gate opens one ordinary Poisson/NB2 q=1 structured `mu` intercept at a
time for `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or
`relmat()`, and one unlabelled intercept-plus-one-slope term at a time for
`phylo()`, `spatial()`, `animal()`, or `relmat()`.
The decision remains intentionally narrow:

> Historical slice record: the Slice 192-197 status language below records the
> state when those slices landed. It is superseded by the live family table
> above and the capability ledger. In particular, ordinary `mu` random effects
> now span every fitted univariate family, and the exact row-specific
> Poisson-`zi`, hurdle-`hu`, cumulative-logit-phylo, Student-t, Gamma, and beta
> structured gates are fitted only at their recorded point/recovery tiers.

| Priority | Family surface | Slice 192 status |
|---|---|---|
| 1 | Poisson `mu` | Implemented for ordinary `(1 | group)` and independent numeric `(0 + x | group)` terms in non-zero-inflated models, plus one q=1 structured `mu` intercept or unlabelled intercept-plus-one-slope route. One separate exact q1 `zi ~ spatial()` intercept is diagnostic-only; other zero-inflated Poisson random effects, correlated/labelled slopes, pure or multiple structured count slopes, simultaneous structured types, and cross-parameter covariance remain planned. |
| 2 | NB2 and zero-truncated NB2 `mu` | NB2 ordinary `mu` random intercepts, independent numeric slopes, the first ordinary log-`sigma` random intercept, one q=1 structured `mu` intercept from `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, and one unlabelled intercept-plus-one-slope term from `phylo()`, `spatial()`, `animal()`, or `relmat()` are fitted; ordinary zero-truncated NB2 `mu` random intercepts and independent numeric slopes are fitted as narrow positive-count slices. Correlated zero-truncated slopes and richer dispersion-side random effects remain later gates. |
| 3 | Lognormal, Gamma, Student-t, and beta `mu` | Ordinary random intercepts and independent numeric slopes are fitted as narrow source-test slices. Correlated slopes, labelled covariance blocks, richer scale or shape combinations, and structured effects need their own recovery grids. |
| 4 | Beta-binomial `mu` | Implemented as ordinary unlabelled `mu` random intercepts and independent numeric slopes for counted successes out of known trials; correlated slopes, labelled covariance, `sigma` random effects, `zoi`/`coi`, and structured routes need separate recovery checks. |
| 5 | Zero-inflation, one-inflation, hurdle, ordinal, shape, and structured non-Gaussian paths | Historical boundary, superseded by the narrow fitted gates in the live table: Poisson-spatial `zi`, hurdle-relatedness `hu`, ordinal-phylo `mu`, Student-t-phylo `nu`, and Student-t intercept-only spatial `mu` are diagnostic-only; the Student-t spatial one-slope, Gamma-relatedness `mu`, and beta-animal `mu`/`sigma` routes retain recovery evidence. Unsupported neighbours still require focused evidence. |

Slice 195 keeps `zi`, `hu`, `zoi`, and `coi` random effects out of the fitted
surface, but gives them explicit unsupported messages. Fixed-effect
zero-inflation and hurdle formulas are implemented where listed above;
random effects in those formulas, count-side random effects in zero-inflated
or hurdle routes, and covariance among `mu`, `sigma`, shape, and
inflation/hurdle random effects need separate likelihood, extractor,
interval, and simulation-recovery evidence. For bounded responses with exact
0 or 1 values, fixed-effect `zoi`/`coi` likelihoods now exist only in
`zero_one_beta()`; zero-one-inflation random-effect or cross-parameter
covariance blocks still need a separate task.

Unsupported formula messages should say that non-Gaussian random effects are
planned and should not silently fall through as generic formula failures.

## Slice 193 Non-Gaussian Scale Boundary

Student-t, beta, beta-binomial, truncated NB2, and hurdle NB2 `sigma` formulas
remain fixed-effect scale models in this release. Ordinary non-zero-inflated
NB2, lognormal, and Gamma have separate independent grouped
`sigma ~ z + (1 | id)` random-intercept gates on their family-specific log-scale.
The lognormal and Gamma scale gates cannot be combined with their `mu` random
effects. Other random-effect bar terms in non-Gaussian `sigma` formulas receive a
scale-specific unsupported message rather than the earlier generic
non-Gaussian `mu` wording.

This is a design boundary, not a claim that scale random effects are
unimportant. Each family needs its own likelihood contribution, random-effect
extraction, `sdpars`/`random_effects`/`profile_targets()` surface, weak-SD and
boundary recovery tests, and reader-facing scale interpretation before
`sigma ~ z + (1 | id)` is advertised outside Gaussian models or the narrow
ordinary NB2/lognormal/Gamma intercept gates.

## Implemented: Gaussian Location-Scale

The first implementation accepts `stats::gaussian()` and maps it internally to:

```r
drm_family(
  name = "gaussian",
  n_response = 1,
  dpars = c("mu", "sigma"),
  links = c(mu = "identity", sigma = "log")
)
```

This is implemented for fixed-effect models, univariate Gaussian `mu` random
intercepts, independent numeric `mu` random slopes, one-slope correlated `mu`
random intercept-slope blocks with optional covariance-block labels,
univariate Gaussian residual-scale random intercepts and independent random
slopes in `sigma`, and optional
known sampling covariance through `meta_V(V = V)`, with
deprecated `meta_known_V(V = V)` retained as a compatibility alias.
Random-effect scale formulae such as `sd(id) ~ x_group` and
`sd(site) ~ site_type` are implemented for distinct unlabelled Gaussian `mu`
random intercepts. Sparse known covariance, labelled residual-scale slope
blocks, cross-formula residual-scale slope covariance, slope-specific or
labelled random-effect scale formulae, and additional families are later
phases. Unlabelled ordinary correlated residual-scale intercept-slope and
multi-slope blocks are fitted.

## Implemented: Student-t Location-Scale-Shape

The first robust continuous family is univariate. It supports fixed effects
plus ordinary unlabelled `mu` random intercepts and independent numeric `mu`
slopes:

```r
student <- function() {
  drm_family(
    name = "student",
    n_response = 1,
    dpars = c("mu", "sigma", "nu"),
    links = c(mu = "identity", sigma = "log", nu = "logm2")
  )
}
```

The response-scale degrees of freedom are
`nu_i = 2 + exp(eta_nu_i)`. This keeps the model in the finite-variance region
and makes Student-t a robust continuous extension of the Gaussian
location-scale MVP. The ordinary `mu` intercept and independent-slope paths are
source-tested, but the current Phase 18 Student-t artifact lane is
random-intercept focused. Correlated Student-t slopes, labelled covariance,
`sigma` random effects, `nu` random effects, known sampling covariance,
phylogenetic terms, and bivariate Student-t models are later phases.

## Implemented: Skew-Normal Location-Scale-Shape

The first skew-normal family is a univariate fixed-effect path:

```r
skew_normal <- function() {
  drm_family(
    name = "skew_normal",
    n_response = 1,
    dpars = c("mu", "sigma", "nu"),
    links = c(mu = "identity", sigma = "log", nu = "identity")
  )
}
```

This contract treats `mu` as the arithmetic response mean, `sigma` as the
response standard deviation, and `nu` as the unrestricted slant or asymmetry
shape used in the density in `docs/design/03-likelihoods.md`. The TMB
likelihood transforms internally to native Azzalini location `xi`, scale
`omega`, and slant `alpha = nu`, but `fitted()` and `sigma()` remain on the
public moment scale. Positive `nu` means right-skewed residuals, `nu = 0`
reduces to the Gaussian location-scale likelihood, and negative `nu` means
left-skewed residuals. Source tests check the sign orientation, density
normalization, Gaussian limit, weak and strong skew recovery, and a Gaussian
false-positive boundary. The Phase 18 `skew_normal_fixed_effect` artifact lane
adds a stochastic DGP, fit summariser, resumable runner, grid writer, manual
Actions task, and focused smoke/grid tests for the same fixed-effect surface;
the default grid uses `n = 720` and `1440` because stochastic skewness recovery
is sample-size dependent.

Ordinary unlabelled `mu` random intercepts and independent numeric slopes are
recovery-grade. Random effects in `sigma` or `nu`, correlated or labelled `mu`
slopes, known sampling covariance, phylogenetic or spatial terms, bivariate
skew-normal models, `rho12`, and aliases such as `skew ~ x` are later phases.
Examples and reference documentation should teach canonical `nu ~ x` before
any alias is added. ID-level skewness syntax such as `skew(id) ~ x` is not an
alias for this residual shape formula; it is a later latent-effect model.

Reader-facing examples may use the fixed-effect syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = skew_normal(),
  data = dat
)
```

The current path rejects random effects in `mu`, `sigma`, or `nu`; `sd(group)`;
known sampling covariance; structured terms; bivariate responses; `rho12`;
latent `skew(id)` syntax; and `skew` aliases. Gaussian location-scale and
Student-t location-scale-shape models remain useful sensitivity comparisons,
but they do not answer a residual-skewness question.

## Implemented: Lognormal Location-Scale

The first positive continuous family is univariate. It supports fixed effects
plus ordinary unlabelled `mu` random intercepts and independent numeric `mu`
slopes:

```r
lognormal <- function() {
  drm_family(
    name = "lognormal",
    n_response = 1,
    dpars = c("mu", "sigma"),
    links = c(mu = "identity", sigma = "log")
  )
}
```

The fitted distribution is Gaussian on the log-response scale:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
```

Here `mu` is the mean of `log(y)`, not the arithmetic mean of `y`. The
response-scale mean is `exp(mu_i + sigma_i^2 / 2)`, which is what `fitted()`
returns for lognormal fits. Ordinary repeated-measure grouping can be written
as `bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)`. The independent `mu` slope
path is source-tested, while the current Phase 18 positive-continuous artifact
lane is random-intercept focused. A separate ordinary `sigma` random-intercept
gate is recovery-grade and inference-ready only over its exact live-ledger
domain. Correlated slopes, labelled covariance, combined `mu`/`sigma` random
effects, `sigma` slopes, known sampling covariance, phylogenetic terms, and
bivariate or mixed lognormal models are later phases.

## Implemented: Gamma Mean-CV

The first Gamma path uses the existing R family constructor rather than
exporting `gamma()`, which would mask `base::gamma()`:

```r
family = Gamma(link = "log")
```

The implemented model is univariate and positive-response only, with fixed
effects plus ordinary unlabelled `mu` random intercepts and independent
numeric slopes:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
```

Here `mu` is the expected response. `sigma` is the coefficient of variation,
not the residual standard deviation; the residual standard deviation is
`mu_i * sigma_i`. Ordinary repeated-measure grouping can be written as
`bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)`. The independent `mu` slope
path is source-tested, while the current Phase 18 positive-continuous artifact
lane is random-intercept focused. Non-log `Gamma()` links, correlated slopes,
labelled covariance, `sigma` random effects, known sampling covariance,
phylogenetic terms, and bivariate or mixed Gamma models are later phases.

## Implemented: Beta Mean-Scale

`beta()` is the first strict-proportion family:

```r
family = beta()
```

The implemented model is univariate, supports fixed effects plus ordinary
unlabelled `mu` random intercepts and independent numeric `mu` slopes, and
requires response values strictly inside `(0, 1)`:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

Here `mu` is the mean proportion. `sigma` is the public scale parameter, not
beta precision. Internally, `phi = 1 / sigma^2`, so larger `sigma` means more
variation around the mean. Boundary responses equal to 0 or 1 should use
`zero_one_beta()` when they are structural outcomes. The independent `mu` slope
path is source-tested, while the current Phase 18 bounded-response artifact lane
is random-intercept focused. Correlated beta slopes, labelled covariance,
`sigma` random effects, known sampling covariance, phylogenetic terms, and
bivariate or mixed beta models are later phases.

## Implemented: Zero-One Beta Mean-Scale-Boundary

`zero_one_beta()` fits continuous proportions on `[0, 1]` when exact zeroes or
ones are structural outcomes. Its fixed-effect formulas can be combined with
ordinary recovery-grade `mu` random intercepts or independent numeric slopes:

```r
family = zero_one_beta()
```

The implemented model is univariate, with ordinary `mu` random intercepts and
independent numeric slopes available as first mixed-model slices:

```text
Pr(y_i = 0) = zoi_i (1 - coi_i)
Pr(y_i = 1) = zoi_i coi_i
Pr(0 < y_i < 1) = 1 - zoi_i
logit(mu_i) = X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(zoi_i) = X_zoi[i, ] beta_zoi
logit(coi_i) = X_coi[i, ] beta_coi
phi_i = 1 / sigma_i^2
E[y_i] = (1 - zoi_i) mu_i + zoi_i coi_i
```

Here `mu` and `sigma` describe the interior beta component, `zoi` is the
probability of an exact-boundary outcome, and `coi` is the probability that a
boundary outcome is exactly one. The response must contain at least one
interior value after missing-row filtering so the beta component is identified.
Correlated or labelled `mu` slopes, `sigma`/`zoi`/`coi` random effects,
structured effects, known sampling covariance, denominator syntax, and
bivariate or mixed bounded-response models are later phases.

## Implemented: Beta-Binomial Mean-Overdispersion

`beta_binomial()` keeps denominators inside the likelihood for counted
successes and failures:

```r
family = beta_binomial()
```

The implemented model is univariate and supports fixed effects plus ordinary
unlabelled `mu` random intercepts and independent numeric `mu` slopes:

```text
y_i | n_i, p_i ~ Binomial(n_i, p_i)
p_i | mu_i, sigma_i ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
E[y_i / n_i] = mu_i
Var(y_i / n_i) =
  mu_i (1 - mu_i) (1 + n_i sigma_i^2) /
  (n_i (1 + sigma_i^2))
```

The response syntax is `cbind(successes, failures) ~ predictors`; `n_i` is the
row total. Counts must be finite non-negative integers and each row must have
positive trials. `fitted()` returns the success probability `mu`,
`sigma(fit)` returns the public extra-binomial variation scale, and
`simulate()` returns success counts for the fitted trial totals. Ordinary
repeated-measure grouping can be written as
`bf(cbind(successes, failures) ~ x + (1 | id) + (0 + x | id), sigma ~ z)`.
The independent `mu` slope path is source-tested, while the current Phase 18
bounded-response artifact lane is random-intercept focused. Correlated slopes,
labelled covariance, `sigma` random effects, known sampling covariance,
phylogenetic terms, bivariate or mixed beta-binomial models, and a possible
successes/trials response alias are later phases. The alias design guardrails
are in
`docs/design/24-denominator-response-syntax.md`.

## Implemented: Cumulative-Logit Ordinal Location

`cumulative_logit()` is the first ordinal family:

```r
family = cumulative_logit()
```

The implemented model is fixed-effect, univariate, and location-only:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The response must be an ordered factor or finite integer category scores
`1, ..., K`, and every category must appear after missing-row filtering. The
location intercept is dropped internally because a free intercept and free
cutpoints are not jointly identifiable. With ordinary treatment contrasts,
factor predictors keep their contrast columns after the intercept is removed.

Here `mu` is a latent ordinal location, not an arithmetic response mean.
`fitted()` returns the expected ordered-category score
`sum_k k * Pr(y_i = k)`, and `simulate()` returns ordered factors with the
fitted category labels. `sigma(fit)` returns a fixed unit vector because this
MVP has no fitted ordinal scale parameter. Ordinal scale or discrimination
formulas, structured effects beyond the exact q1 phylogenetic intercept, known
sampling covariance, bivariate ordinal models, and mixed-response ordinal
models are later phases. Ordinary `mu` random intercepts and independent
slopes are now fitted at recovery grade.
The scale/discrimination direction is recorded in
`docs/design/25-ordinal-scale-discrimination.md`.

Historical Slice 196 kept ordinal random effects out of the fitted surface and
named an ordinary random intercept as its first future target. That target and
an independent numeric slope are now fitted at recovery grade. The remaining
boundary is provider-specific structure beyond the exact q1 phylogenetic
intercept, scale/discrimination, richer covariance, interval/coverage
promotion, and comparator evidence.

Historical Slice 197 kept structured non-Gaussian random effects out of the
fitted surface. That Gaussian-only boundary is superseded by the narrow exact
non-Gaussian routes in the live table above; it does not authorize their
neighbours. The first animal/`relmat()` slice fit pedigree or known-matrix
Gaussian `mu` and `sigma` intercepts, matching univariate `mu`/`sigma`
correlations, matching labelled bivariate q=2 `mu1`/`mu2` location covariance,
matching all-four q=4 location-scale covariance, and the first A/K/Q
sigma-only plus matched `mu+sigma` one-slope native point-fit/extractor cells;
sparse large-pedigree construction, labelled structured slope covariance,
bridge/inference for matched slope cells, predictor-dependent `corpair()`
regression, and direct-SD grammar remain planned. Broader count, bounded,
ordinal, shape, inflation, hurdle, and one-inflation structured effects still
need family- and endpoint-specific recovery, interval, extractor, and
diagnostic evidence.

## Implemented: Poisson Mean

The first count path uses the existing R family constructor:

```r
family = poisson(link = "log")
```

The implemented ordinary Poisson model is univariate. It supports fixed
effects, ordinary unlabelled `mu` random intercepts, and independent numeric
`mu` random slopes for non-zero-inflated models:

```text
y_i | mu_i ~ Poisson(mu_i)
b_g ~ Normal(0, sd_mu^2)
log(mu_i) = o_i + X_mu[i, ] beta_mu + b_{g[i]}
E[y_i] = Var[y_i] = mu_i
```

For an independent random-slope term such as `(0 + x | group)`, the mean
predictor adds `x_i b_{x,g[i]}` with its own fitted `sd_mu`.

For exposure models, `o_i` is a known offset from standard R syntax such as
`offset(log(trap_nights))`; otherwise `o_i = 0`.

This path is mostly a baseline count-regression model and a comparator for
later overdispersed count families. It deliberately has no fitted `sigma`
distributional parameter. `sigma(fit)` returns a fixed unit dispersion vector
for base-R method compatibility, not a modelled residual scale. Correlated
random-slope blocks, labelled random-effect covariance blocks, zero-inflated
Poisson random effects beyond the exact q1 `zi ~ spatial()` intercept, known
sampling covariance, overdispersion, structured routes beyond those named in
the live table, and bivariate or mixed Poisson models remain later phases.

The same Poisson route also supports fixed-effect structural-zero regression by
adding a `zi` formula:

```r
family = poisson(link = "log")
drm_formula(count ~ habitat + offset(log(trap_nights)), zi ~ treatment)
```

Here `mu` is the conditional Poisson mean and `zi` is the structural-zero
probability:

```text
log(mu_i) = o_i + X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
logit(zi_i) = X_zi[i, ] beta_zi
E[y_i] = (1 - zi_i) mu_i
```

There is intentionally no exported `zi_poisson()` constructor at this stage;
zero inflation is a distributional parameter of the existing Poisson family.

## Implemented: Negative Binomial 2 Mean-Dispersion

`nbinom2()` is the first overdispersed count family:

```r
family = nbinom2()
```

The implemented model is univariate and can include ordinary `mu` random
intercepts, independent numeric `mu` slopes, or an ordinary `sigma` random
intercept:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = o_i + X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
log(sigma_i) = X_sigma[i, ] beta_sigma + Z_sigma[i, ] b_sigma
b_mu ~ Normal(0, diag(sd_mu^2)) for independent mu random-effect terms
b_sigma ~ Normal(0, diag(sd_sigma^2)) for independent sigma random-intercept terms
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

Here `sigma` is an extra-Poisson scale, not a residual standard deviation and
not the native NB size or precision parameter. Larger `sigma` means greater
overdispersion. This direction is deliberate so `sigma` continues to mean
"more scale" across `drmTMB` families.

Adding `zi ~ predictors` fits the implemented zero-inflated NB2 extension:

```text
log(mu_i) = o_i + X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(zi_i) = X_zi[i, ] beta_zi
E[y_i] = (1 - zi_i) mu_i
```

The `sigma` random-effect gate is intercept-only and cannot be combined with
NB2 `mu` random effects in this first slice. Correlated NB2 slope blocks,
labelled covariance blocks, NB2 `sigma` slopes, joint `mu`/`sigma` random
effects, zero-inflated NB2 random effects, known sampling covariance,
structured `sigma` terms, and bivariate or mixed negative-binomial models are
later phases.

## Implemented: Zero-Truncated Negative Binomial 2 Mean-Dispersion

`truncated_nbinom2()` handles positive counts where zero is absent by design:

```r
family = truncated_nbinom2()
```

The implemented model is univariate and supports fixed effects plus ordinary
unlabelled `mu` random intercepts and independent numeric `mu` slopes:

```text
y_i | y_i > 0, mu_i, sigma_i ~ NB2(mu_i, size_i) truncated at zero
log(mu_i) = X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
b_mu ~ Normal(0, diag(sd_mu^2)) for independent mu random-effect terms
size_i = 1 / sigma_i^2
Pr(y_i = k | y_i > 0) = Pr_NB2(y_i = k) / (1 - Pr_NB2(0))
E[y_i | y_i > 0] = mu_i / (1 - Pr_NB2(0))
```

Here `mu` and `sigma` describe the untruncated NB2 component. This keeps the
count-scale `sigma` interpretation aligned with `nbinom2()`, while `fitted()`
returns the observed positive-count mean. The independent `mu` slope path is
source-tested, while the current Phase 18 zero-truncated NB2 artifact lane is
random-intercept focused. Correlated zero-truncated slopes, labelled covariance,
`sigma` random effects, structured effects, and hurdle random effects need
separate recovery evidence.

Adding `hu ~ predictors` fits the implemented hurdle NB2 extension:

```text
logit(hu_i) = X_hu[i, ] beta_hu
Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) =
  (1 - hu_i) Pr_NB2(y_i = k | y_i > 0, mu_i, sigma_i)
E[y_i] = (1 - hu_i) mu_i / (1 - Pr_NB2(0))
```

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

Use `hu` when zeros are generated by a separate hurdle process and all nonzero
counts are positive-count observations. Use `zi` when the count distribution
can itself still generate sampling zeros and the model adds extra structural
zeros.

## Implemented: Bivariate Gaussian Location-Coscale

The stable public direction for two-response models is composed response
families:

```r
family = c(gaussian(), gaussian())
family = list(gaussian(), gaussian())
```

Mixed ecological responses such as body mass plus fecundity counts remain a
planned use case. A composed family must still declare a coherent joint
likelihood and state what `rho12` means: observed residual correlation, latent
residual correlation, a copula parameter, or unsupported. The all-Gaussian
composed case is implemented for both `c()` and `list()` spellings and routes
to the same likelihood as `biv_gaussian()`. The `biv_gaussian()` object remains
a convenience and internal testing target, not a commitment to one named family
for every response combination.

```r
biv_gaussian <- function() {
  drm_family(
    name = "biv_gaussian",
    n_response = 2,
    dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
    links = c(
      mu1 = "identity",
      mu2 = "identity",
      sigma1 = "log",
      sigma2 = "log",
      rho12 = "atanh_guarded"
    )
  )
}
```

This family is implemented for fixed-effect models with separate location,
scale, and residual-correlation formulas:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

`rho12` uses a guarded atanh-style link internally:
`rho12 = 0.999999 * tanh(eta_rho12)` on the response scale.
`mvbind(y1, y2) ~ x` is implemented as shorthand for identical `mu1` and
`mu2` location formulas. Selected matching labelled random-intercept
covariance blocks are implemented for all-Gaussian bivariate fits; bivariate
random slopes, mixed-response bivariate families, and broad q=4/q=8 endpoint
blocks remain planned.

## Slice 288 Mixed-Response Boundary

Mixed-response bivariate families remain planned, not partially fitted:

| Candidate surface | Current status | Gate before fitting |
| --- | --- | --- |
| `family = c(gaussian(), gaussian())` or `list(gaussian(), gaussian())` | Implemented and routed to the bivariate Gaussian likelihood. | Continue using explicit `mu1`/`mu2` formulas for different location predictors; keep `mvbind()` as identical-location shorthand only. |
| Gaussian-count, Gaussian-proportion, count-proportion, ordinal mixed, or other two-response combinations | Rejected before fitting for both `c()` and `list()` composed-family spellings. | Choose a joint likelihood or copula/latent-variable contract, define what any residual association parameter means, add prediction/simulation/extractor methods, and add comparator or independent-likelihood tests. |
| Three or more response families | Rejected before fitting. | Out of `drmTMB` scope; higher-dimensional multivariate models belong to `gllvmTMB`. |

## Design Principle

Do not expose a large distribution zoo before the fitting, prediction,
simulation, and diagnostic machinery is stable.
