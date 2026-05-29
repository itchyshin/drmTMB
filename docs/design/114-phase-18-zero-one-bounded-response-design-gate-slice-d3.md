# Phase 18 Zero-One Bounded-Response Design Gate, Slice D3

This note records the Slice D3 bounded-response decision. Its reader is an
applied ecology, evolution, or environmental-science user with proportions that
can be exactly 0 or 1, and an R package contributor deciding what can be opened
without turning one bounded-response problem into a broad non-Gaussian parity
claim.

Slice D3 does not add a likelihood, formula grammar, TMB code, or user-facing
family constructor. It chooses the next bounded-response implementation
direction: fixed-effect zero-one beta should be designed before any
zero-one-inflation random effects, correlated or broader bounded-response
random slopes, structured bounded-response effects, or mixed-response bounded
models.

## Current Bounded-Response Routes

`drmTMB` currently has two fitted bounded-response routes. Strict continuous
proportions use `beta()`:

```r
drmTMB(
  bf(prop ~ x, sigma ~ z),
  family = beta(),
  data = dat
)
```

The mean is `logit(mu_i) = eta_mu_i`, the public scale is
`log(sigma_i) = eta_sigma_i`, and the internal beta precision is
`phi_i = 1 / sigma_i^2`. The likelihood is only for interior responses:

```text
0 < prop_i < 1
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

Counted successes out of known trials use `beta_binomial()`:

```r
drmTMB(
  bf(cbind(success, failure) ~ x, sigma ~ z),
  family = beta_binomial(),
  data = dat
)
```

Here `success_i = 0` or `success_i = trials_i` can be an ordinary sampling
outcome. It is not evidence for structural zero-one inflation unless a future
model explicitly adds that process.

Ordinary unlabelled `mu` random intercepts and independent numeric slopes are
fitted for both families as source-level first slices. They do not open
correlated bounded-response random slopes, labelled covariance blocks, `sigma`
random effects, exact boundary mass, structured effects, known covariance, or
mixed bounded-response models.

## Future Fixed-Effect Zero-One Beta Contract

The next bounded-response likelihood should target continuous responses on
`[0, 1]` where exact 0 and exact 1 values are scientifically meaningful, such as
absence or complete cover. The design assumption for the first fixed-effect
slice is:

```text
zoi_i = Pr(prop_i is exactly 0 or 1)
coi_i = Pr(prop_i = 1 | prop_i is exactly 0 or 1)
Pr(prop_i = 0) = zoi_i * (1 - coi_i)
Pr(prop_i = 1) = zoi_i * coi_i
Pr(0 < prop_i < 1) = 1 - zoi_i
prop_i | 0 < prop_i < 1 ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

The modelled predictors should start fixed-effect only:

```text
logit(mu_i) = eta_mu_i
log(sigma_i) = eta_sigma_i
logit(zoi_i) = eta_zoi_i
logit(coi_i) = eta_coi_i
```

`zoi` and `coi` are already reserved component names in the formula grammar, but
this note does not make them runnable. The implementation issue should decide
the public family constructor name, document how it differs from strict
`beta()` and denominator-aware `beta_binomial()`, and then update
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
roxygen2 documentation, tutorials, tests, and pkgdown navigation in the same
pull request.

## Admission Gate Before Code

The first implementation slice should be fixed-effect only and should close
these checks before the family is advertised as fitted:

- likelihood and simulation tests for pure interior data, zero-only boundary
  mass, one-only boundary mass, and mixed zero-one boundary mass;
- false-positive checks where the true `zoi` is near zero and the fitted route
  should not invent boundary mass;
- recovery checks for `mu`, `sigma`, `zoi`, and `coi` coefficients on their
  modelled link scales;
- malformed-input tests that keep strict `beta()` errors clear for exact 0/1
  data and keep `beta_binomial()` denominator errors separate;
- prediction and fitted-value rules that state whether the returned response
  mean includes the boundary masses;
- interval/status rows for fixed-effect coefficients before any direct
  response-scale interval claim;
- reader-facing examples that tell users when to choose strict `beta()`,
  `beta_binomial()`, or the zero-one beta route.

No random effects should enter `zoi` or `coi` in the first slice. No covariance
among `mu`, `sigma`, `zoi`, and `coi` should be opened until each marginal
fixed-effect path has likelihood, simulation, prediction, extractor, interval,
and diagnostic evidence.

## Boundary After Slice D3

The completed Slice D3 claim is:

> `drmTMB` has fitted strict beta and beta-binomial bounded-response routes,
> first ordinary `mu` random-intercept source-test slices for those routes, and a
> fixed-effect design contract for the zero-one beta likelihood.

It is not:

> `drmTMB` fits ordered beta, bounded-response zero-one random effects, or
> bounded-response covariance blocks.

The later fixed-effect source slice implements only the zero-one beta
likelihood with simulation tests. Tweedie, skew-normal, COM-Poisson,
generalized Poisson, correlated or broader bounded-response random slopes, and structured
bounded-response effects remain separate Slice D choices.
