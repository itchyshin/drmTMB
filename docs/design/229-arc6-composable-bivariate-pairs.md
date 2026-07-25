# Arc 6 composable bivariate-pair architecture

## Status

**Historical design exploration — not an implementation authority.** The
reviewed Arc 6 authorities are now the first-slice
[`Ultra Plan`](../dev-log/2026-07-23-arc6-margin-first-latent-normal-ultra-plan.md)
and the [`bivariate-series overview`](230-arc6-bivariate-series-overview.md).
They replace this document's proposed one-call `biv_pair(..., joint = ...)`
architecture with a margin-first post-fit association object for the general
mixed-family route. This document remains a useful record of why every direct
joint construction needs its own estimand and likelihood.

The earlier DIBP-first packet is likewise historical feasibility evidence, not
an implementation authority. Diagonal-inflated Poisson is not the intended
general solution for overdispersed count distributional regression.

Arc 6's product goal is a scalable two-response architecture: preserve the
existing Gaussian route, admit one carefully chosen first pair, and make every
later pair name an exact joint construction rather than borrowing Gaussian
`rho12` language.

## API decision

The reviewed public API is:

```r
biv_pair(marginal1, marginal2, joint = <registered joint constructor>)
```

For example, a future fixed-effect shared-Gamma NB2 pair would be written:

```r
drmTMB(
  bf(
    mu1 = count_1 ~ treatment,
    sigma1 = ~ habitat,
    mu2 = count_2 ~ treatment,
    sigma2 = ~ habitat,
    association = ~ 1
  ),
  family = biv_pair(
    marginal1 = nbinom2(),
    marginal2 = nbinom2(),
    joint = shared_gamma()
  ),
  data = dat
)
```

`shared_gamma()` is a package-owned constructor that resolves to a scalar
registered joint ID and version; it is not a user-supplied likelihood closure.
The fitted object stores that resolved ID/version only. A future paired
Bernoulli model would use `joint = odds_ratio()`, with the same `association =`
formula spelling but a different exact likelihood and estimand.

This decision rejects `pair_family()`, a separate model-level `joint =`
argument, `family = c(...), joint = ...`, a generic `dependence =` argument,
and a growing set of `biv_*()` constructors. The first two hide the fact that
the joint is part of the family contract; the latter two misleadingly suggest
that arbitrary margins can share one interchangeable correlation mechanism.

## Product contract

The future-facing API is one compositional constructor:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x,
    sigma1 = ~ z,
    mu2 = y2 ~ x,
    sigma2 = ~ z,
    association = ~ 1
  ),
  family = biv_pair(
    marginal1 = <family 1>,
    marginal2 = <family 2>,
    joint = <registered joint constructor>
  ),
  data = dat
)
```

`joint` is mandatory. Two marginal family names alone do **not** define a
joint likelihood. It is a package-owned constructor or registry key, never an
arbitrary user-supplied function. Its contract declares:

- the exact joint density or pmf and its parameterization;
- which endpoint distributional parameters it admits and their links;
- the association estimand, scale, link, and valid parameter domain;
- fitted-value, variance, covariance, and joint-simulation meanings;
- response-pattern support (for the first non-Gaussian slice: complete pairs
  only); and
- which of random effects, offsets, weights, missingness, `meta_V()`, REML,
  profiling, and distributional-output methods it supports.

The API deliberately does **not** promise a universal correlation parameter.
The first generic joint formula slot is `association = ~ ...`; its meaning is
read from the named joint construction. A Gaussian residual correlation remains
`rho12`, not an alias for `association`.

## Compatibility contract

All established Gaussian spellings retain their exact current meaning and TMB
backend:

```r
biv_gaussian()
c(gaussian(), gaussian())
list(gaussian(), gaussian())
```

They resolve internally to the registry descriptor
`gaussian_residual/v1`, retain `model_type = "biv_gaussian"` and TMB model type
2, and continue to use `rho12 = 0.999999 * tanh(eta)`. No existing fitted
object is reinterpreted. `biv_gaussian()` remains a supported compatibility
constructor; it is not the template from which non-Gaussian pairs inherit.

## Pair registry

At fit time, `biv_pair()` resolves an immutable descriptor. Saved objects store
metadata, not R closures:

```r
list(
  pair_id = "<stable registry id>",
  pair_version = 1L,
  margins = c("<margin 1>", "<margin 2>"),
  dpars = c("mu1", "sigma1", "mu2", "sigma2", "association"),
  joint_id = "<named exact construction>",
  association = list(
    name = "<estimand>",
    scale = "<parameter or derived response scale>",
    is_correlation = FALSE
  ),
  response_patterns = "complete_pairs_only",
  capabilities = list(...)
)
```

An internal registry resolves the descriptor to package functions for the
specification builder, TMB data/parameter splitter, likelihood branch,
prediction, fitted values, simulation, association extraction, and
diagnostics. A changed likelihood is a new pair ID or version, never a silent
reinterpretation of an old fit.

## Method semantics

`coef()`, `vcov()`, `predict()`, and `predict_parameters()` become
descriptor-driven where their existing generic structure suffices. The
following methods remain pair-capability-gated:

| Method | Gaussian residual pair | First non-Gaussian pair |
| --- | --- | --- |
| `rho12()` | Gaussian residual correlation | Clear unsupported-method error |
| `association()` | Optional derived summary; not a replacement for `rho12()` | Required pair-specific estimand and any derived covariance/correlation |
| `fitted()` | Endpoint conditional Gaussian means | Declared endpoint marginal means |
| `simulate()` | Correlated Gaussian pairs | Exact joint-pair simulation |
| `sigma()` / covariance matrix | Existing Gaussian semantics | Only if the joint declares a valid response-scale equivalent |
| profiles, intervals, `emmeans`, DPQ outputs, residual diagnostics | Existing Gaussian support | Explicitly unsupported until separately validated |

For Bernoulli pairs, for example, association could be a conditional odds
ratio and a Pearson correlation would be derived and covariate-dependent. For
count pairs, association might be a shared intensity, a latent-factor loading,
or a copula parameter. None should be represented as Gaussian `rho12`.

## `rho12`, `association`, `sd()`, and `corpair()` are separate layers

These names must remain distinct as pair support expands:

| Name | What it describes | Generalization policy |
| --- | --- | --- |
| `rho12` | Gaussian residual correlation between the two observed response values | Retain for the existing Gaussian residual pair only. |
| `association` | The dependence parameter declared by a named joint kernel | Required for every new pair, with pair-specific semantics and link. |
| `sd(group)` | A standard deviation of a latent group-level random effect | May be admitted per margin only after that pair's random-effect likelihood is validated. It is not count dispersion. |
| `corpair()` | Correlation between named latent Gaussian random-effect members | Potentially general across margins, but only when the named pair declares a compatible Gaussian latent-effect block. It is not an observed-pair association parameter. |

For a future pair with latent site effects, `corpair()` may describe
`cor(b1_site, b2_site)` while `association` still describes the within-row
joint count or binary construction. The first fixed-effect pair declares no
latent random-effect blocks and therefore rejects both `sd()` and `corpair()`.

## Why composition requires a joint declaration

With Gaussian margins, means, standard deviations, and a correlation determine
a valid bivariate Gaussian distribution. For binary margins, the admissible
correlation range changes with the two event probabilities. For count margins,
different joint constructions can share the same negative-binomial margins but
have different tail dependence, conditional predictions, and association
meanings. A review of the Poisson-lognormal ecological framework makes the
same general point: there is no generic multivariate count distribution; the
joint model is created by a specified latent structure plus conditional count
model ([Chiquet, Mariadassou, and Robin 2021](https://www.frontiersin.org/journals/ecology-and-evolution/articles/10.3389/fevo.2021.588292/full)).

## First-pair decision gate

The intended scientific demand is **overdispersed paired counts**, not DIBP's
narrow low-count exact-agreement mechanism. However, the current package has
`nbinom2()` but not `nbinom1()`; therefore a purported NB1 pair cannot be
implemented honestly until its univariate marginal contract has been designed
and implemented or an already supported marginal family is selected.

Before implementation, choose exactly one of these explicitly different paths:

1. Add univariate NB1 first, then choose and freeze a joint NB1 construction
   that preserves the declared marginal mean/dispersion parameters.
2. Use existing NB2 margins for the first pair, but only after freezing an
   exact joint NB2 construction and its association estimand.
3. Make paired Bernoulli the architecture proof-of-concept, using its exact
   four-cell marginal-logit/odds-ratio likelihood, and schedule the
   overdispersed-count pair as the next Arc 6 subarc.

A shared-gamma proposal is not presumed valid merely because it sounds like a
negative-binomial model: the algebra must prove which marginal dispersion
parameters it permits and whether it can retain independently modeled endpoint
dispersions. The symbolic review and independent R oracle are mandatory before
code.

## First implementation fences

Regardless of selected pair, its initial slice is fixed-effect and
complete-pair only. It rejects random/structured effects, `mi()`, `meta_V()`,
REML, weights, offsets, partial responses, and `rho12`. No interval, coverage,
capability-tier, or generic co-occurrence claim follows from implementation.

## Reusable future joint-construction families

The pair registry is intended to admit several **named** construction families,
not a generic correlation switch:

| Construction | Pattern | Association meaning | Arc 6 status |
| --- | --- | --- | --- |
| Direct joint | `joint = shared_gamma()` for compatible count margins | Shared latent-rate component; derived positive covariance | Candidate first kernel |
| Four-cell joint | `joint = odds_ratio()` for literal Bernoulli margins | Conditional log odds ratio; derived row-specific correlation | Candidate later exact pair |
| Latent factor | `joint = latent_factor(rank = 1)` | Correlation/covariance of shared Gaussian linear-predictor factors | Later: needs integration, identification, and a random-effect evidence arc |
| Copula | `joint = gaussian_copula()` or another explicitly named copula | Latent copula parameter, not generally observed-scale correlation | Later: discrete rectangle likelihood and identification review required |
| Directed conditional | `joint = conditional(<direction>)` | Directional conditional-regression parameter | Later: only if both marginal meanings are explicitly retained |

The latent-factor row borrows the general GLLVM strategy: each response has
its own likelihood and linear predictor, conditional independence is restored
given shared latent Gaussian variables, and cross-response structure is
reported on the latent-predictor layer. It is not interchangeable with the
direct joint's response-scale association. A multi-trait latent model can
stack traits and dispatch their marginal families per row, then integrate the
shared latent block; for two responses that is a possible future backend, not
an automatic extension of the first fixed-effect direct-joint kernel.

A copula joins marginal CDFs through a named function
`C(F1(y1), F2(y2); theta)`. For continuous margins it supplies a joint density
after multiplying by the two marginal densities. For discrete margins the
joint mass is a four-corner CDF rectangle difference, so it requires careful
numerical evaluation and `theta` is a latent copula parameter rather than a
freely interpretable Pearson correlation. It must therefore be a later named
kernel with its own oracle, not a generic shortcut for all pairs.

## Implementation sequence after the first-pair decision

1. Add `biv_pair()` and the immutable internal registry, then normalize only
   the three existing Gaussian spellings through `gaussian_residual/v1` without
   changing their likelihood or public output.
2. Add descriptor accessors and replace only the switches touched by the first
   pair; do not conduct a wholesale family-system rewrite.
3. Implement the frozen first joint model, independent R oracle, exact pair
   simulator, `association()` extractor, targeted errors, documentation, and
   ecological example.
4. Obtain formula/math/architecture review, then owner approval before any
   smoke; obtain separate owner approval before any Totoro or DRAC recovery
   campaign.

## Evidence and review

- Formula review: `biv_pair(..., joint = ...)` with `association = ~ ...` is
  the recommended grammar; `rho12` remains Gaussian-only.
- Architecture review: the current `drm_family_type()` correctly rejects mixed
  pairs but collapses the only supported composed pair to `biv_gaussian`; the
  registry is the smallest safe extensibility seam.
- Prior art: diagonal-inflated bivariate Poisson is a real distinct model, not
  a generic negative-binomial or co-occurrence solution ([Karlis and Ntzoufras
  2005](https://www.jstatsoft.org/article/view/v014i10)). A marginal-logit
  bivariate binary model with an odds-ratio association is likewise a distinct
  exact construction ([Zelig bivariate logistic documentation](https://zeligproject.org/docs/articles/zeligchoice_blogit)).
