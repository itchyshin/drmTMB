# Tweedie Family Design Gate

## Purpose

Tweedie models belong on the future real-data wish list because eco-evo datasets
often include exact zeros and positive continuous measurements in the same
response: biomass, percent cover, catch-per-unit-effort indices, activity
indices, and similar field summaries. This note records what must be decided
before `drmTMB` adds a `tweedie()` family.

This is a design gate, not an implementation note. `drmTMB` does not currently
fit Tweedie models.

## First User Story

An applied user has a non-negative response with many exact zeros and positive
continuous values:

```r
fit <- drmTMB(
  bf(biomass ~ habitat + season, sigma ~ habitat, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The intended interpretation would be:

- `mu`: the response mean, using a log link;
- `sigma`: the scale or dispersion parameter, after the project decides the
  public mapping;
- `nu`: the Tweedie power parameter constrained to `1 < nu < 2`.

The `nu ~ 1` formula in this user story is future syntax. It should not appear
in examples as runnable code until the family is implemented and tested.

## Candidate Statistical Contract

The likely response-level variance contract is:

```text
E[y_i] = mu_i
Var[y_i] = phi_i * mu_i^nu_i
1 < nu_i < 2
```

The unresolved public-interface decision is how `sigma` maps to `phi`.

| Option | Public meaning | Variance expression | Trade-off |
| --- | --- | --- | --- |
| `sigma = phi` | dispersion | `Var[y] = sigma * mu^nu` | closest to software that names the Tweedie dispersion directly, but `sigma` is no longer standard-deviation-like. |
| `sigma = sqrt(phi)` | scale | `Var[y] = sigma^2 * mu^nu` | closer to existing `drmTMB` scale language, but comparator tests need an explicit square-root transform. |

The current working recommendation is `sigma = sqrt(phi)`, pending owner
confirmation before likelihood code lands. That gives:

```text
Var[y_i] = sigma_i^2 * mu_i^nu_i
```

This keeps `sigma ~ x` scale-like across `drmTMB`: larger `sigma` means more
residual variation, and exponentiated scale coefficients remain multiplicative
scale ratios. Comparator tests against software that reports Tweedie dispersion
`phi` should compare `sigma^2` with `phi` and name that transform explicitly.

Do not write comparator tests or user-facing runnable examples until this
mapping is confirmed. The design should prefer the mapping that gives applied
users the clearest interpretation while keeping `sigma` consistent with the
rest of `drmTMB`.

## Comparator Sources

The first comparator should be `glmmTMB::tweedie(link = "log")`, because
glmmTMB's current family documentation lists Tweedie support, writes the
variance as `V = phi * mu^power`, and restricts the power parameter to
`1 < power < 2`. Its `family_params()` documentation also treats Tweedie power
as an additional family-specific parameter.

Comparator tests should check:

- coefficient agreement on the chosen `sigma` scale, with any `phi` transform
  written in the test name;
- likelihood agreement on small simulated data;
- `fitted()` as the response mean, not the conditional positive mean;
- `sigma()` and future family-parameter extraction on documented scales;
- simulations preserving both exact zeros and positive continuous values.

## Implementation Gates

The first implementation should be fixed-effect, univariate, and non-spatial:

- log-linked `mu`;
- fixed-effect `sigma`;
- intercept-only `nu ~ 1` first, with predictor-dependent `nu` deferred until
  the mean, scale, zero-mass, and power trade-offs are better understood;
- no random effects in `sigma` or `nu`;
- no bivariate Tweedie, no `rho12`, no `meta_known_V(V = V)`, and no
  phylogenetic or spatial structured effects in the first slice.

Before code lands, add:

- density equations in `docs/design/03-likelihoods.md`;
- family registry entry with the chosen `sigma` mapping;
- simulation tests with known parameter recovery;
- comparator tests against glmmTMB on the documented scale;
- malformed-input tests for negative responses and unsupported formula terms;
- provenance notes in `inst/COPYRIGHTS` if any implementation is ported from
  another package.

## Open Questions

- After the intercept-only `nu` path is stable, what diagnostics are needed
  before allowing predictor-dependent `nu ~ predictors`?
- Should `sigma()` return public `sigma`, while a separate extractor reports
  Tweedie `phi` when `sigma = sqrt(phi)`?
- Can starting values be made reliable enough without depending on another
  package at runtime?
- Which real dataset should become the teaching example once the simulated
  tests pass?
