# Denominator-Aware Response Syntax

This note keeps beta-binomial response syntax explicit until the package has a
reviewed shorthand for counted successes out of known trial totals.

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
- The helper rejects non-integer, negative, missing, or impossible counts with a
  recovery hint that names `cbind(successes, failures)`.
- Tests compare the alias to the implemented `cbind(successes, failures)` path
  for log-likelihood, coefficients, `fitted()`, `sigma()`, and `simulate()`.
- The distribution-family tutorial teaches one canonical response syntax first
  and labels the alias as a convenience.
- The after-task report records why the alias cannot be confused with a
  continuous proportion.

Until those criteria are met, the canonical public syntax remains
`cbind(successes, failures)`.
