# Denominator-Aware Response Syntax

This note keeps denominator-aware response syntax explicit until the package has
reviewed shorthand for counted successes out of known trial totals. It covers
the implemented `beta_binomial()` overdispersion route and the planned plain
`stats::binomial()` response route in `drmTMB#569`.

## Implemented Contract

The implemented `beta_binomial()` path uses base-R binomial response syntax:

```r
drmTMB(
  bf(cbind(successes, failures) ~ treatment, sigma ~ treatment),
  family = beta_binomial(),
  data = dat
)
```

The first column is the number of successes and the second column is the number
of failures. The trial total is computed row-wise as:

```text
n_i = successes_i + failures_i
```

This mirrors the `glm(..., family = binomial())` convention and avoids a silent
successes/trials ambiguity.

## Planned Plain Binomial Contract

The planned first primary Bernoulli/binomial response route reuses the same
base-R response encoding but removes the extra-binomial scale:

```r
drmTMB(
  bf(y01 ~ treatment),
  family = stats::binomial(link = "logit"),
  data = dat
)

drmTMB(
  bf(cbind(successes, failures) ~ treatment),
  family = stats::binomial(link = "logit"),
  data = dat
)
```

For the 0/1 route, `trials_i = 1`. For the two-column route,
`trials_i = successes_i + failures_i`. The fitted `mu_i` is the event
probability and the first public claim is parity with `stats::glm()` for
fixed-effect logit models.

This route is not `beta_binomial()`: it has no `sigma` and no extra-binomial
variation. It is also not a continuous-proportion model; use `beta()` or
`zero_one_beta()` when the response is a measured proportion rather than a
counted event out of known trials.

## Avoided Ambiguities

`cbind(successes, trials)` should not be accepted as a beta-binomial response,
because base R interprets the second column of a two-column binomial response as
failures, not trial totals. Accepting both meanings would make the same printed
formula mean two different likelihoods.

`successes / trials ~ x` should not become the preferred grammar. In R formulae,
`/` already expands nested terms on the right-hand side, and a slash response
can look like an arithmetic proportion while losing the binomial denominator in
ordinary model-frame handling.

Continuous proportions created as `successes / trials` are still valid data for
`beta()`, but they no longer carry the binomial denominator. Use
`beta_binomial()` when the number of trials is part of the sampling process.
Use the planned `stats::binomial()` response route only when ordinary binomial
sampling variation is the intended model; use `beta_binomial()` when the data
need extra-binomial variation.

Top-level `weights` remain likelihood weights. They are not trial totals for
either `stats::binomial()` or `beta_binomial()`.

## Candidate Future Alias

A future alias should make the denominator role unambiguous, for example a
response helper with two named quantities:

```r
bf(trials(successes, total = trials) ~ treatment, sigma ~ treatment)
```

This is not implemented. Before adding it, Boole should review parseability,
Pat should check whether applied users read the helper correctly, and Curie
should add tests showing that the helper is exactly equivalent to
`cbind(successes, trials - successes)` after validation.

## Acceptance Criteria Before Coding An Alias

- `docs/design/01-formula-grammar.md` defines the response helper grammar.
- The helper rejects non-integer, negative, missing, or invalid counts with a
  recovery hint that names `cbind(successes, failures)`.
- Tests compare the alias to the implemented `cbind(successes, failures)` path
  for log-likelihood, coefficients, `fitted()`, `sigma()`, and `simulate()`.
- The distribution-family tutorial teaches one canonical response syntax first
  and labels the alias as a convenience.
- The after-task report records why the alias cannot be confused with a
  continuous proportion.

Until those criteria are met, the canonical public syntax remains
`cbind(successes, failures)`.
