# Phase 18 Overnight Two-Lane Plan, Slices 1419-1618

This note is the Ada integration contract for the first larger two-team
overnight run after the Slices 1409-1418 pilot. It does not claim new fitted
support by itself. It records which work may proceed in parallel and which work
must stay behind a serial integration gate.

## Purpose

Use two teams to advance two distribution-family lanes efficiently without
weakening the package evidence standard. Accuracy and usability are the primary
criteria. Parallelism is allowed only where write scopes and fitted claims are
separable.

## Team A: Slices 1419-1518, Tweedie Fixed-Effect Admission

Team A owns the Tweedie lane. The safe target is a univariate fixed-effect
route only:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The statistical contract is:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
log(mu_i) = eta_mu_i
log(sigma_i) = eta_sigma_i
phi_i = sigma_i^2
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The first fitted slice, if it lands, must allow exact zeros and positive
continuous values, reject negative responses, return the unconditional response
mean from `fitted()`, and report public `sigma` rather than comparator
dispersion `phi`.

Team A may touch family-constructor, builder, TMB, method, test, simulation,
and Tweedie-specific design files after reading the current implementation
patterns. It must not open random effects, random slopes, labelled covariance,
`sd(group)` scale models, `meta_V(V = V)`, structured effects, bivariate or
mixed-response Tweedie, predictor-dependent `nu`, zero-inflation aliases, or
hurdle aliases.

If the Tweedie density implementation or comparator contract is not safe enough
for an overnight code slice, Team A should stop at the strongest honest subset:
family-helper and boundary scaffold, source-map implementation blocker, and
tests that prevent accidental fitted-support claims.

## Team B: Slices 1519-1618, Skew-Normal Shape-Family Admission

Team B owns the skew-normal admission lane. The first output should be a
source-map and design gate, not a second overnight TMB likelihood branch.

The safe first target is univariate, fixed-effect, residual or
observation-level skewness:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = skew_normal(),
  data = dat
)
```

That syntax is future syntax until the parameterization, likelihood, tests,
documentation, and provenance are accepted together. `nu` should mean the first
shape or asymmetry parameter, with a documented map to the chosen native
skew-normal parameterization. Latent-effect skewness such as
`skew(id) ~ x` or `nu(id) ~ x` is a different future programme and remains
closed until simulations show separability from residual skewness and
heteroscedasticity.

Team B may touch skew-normal design/source-map files and narrow unsupported-
boundary tests. It must not change shared family constructors, formula grammar,
TMB code, exported docs, or global status files unless Ada explicitly promotes
that work in a later serial gate.

## Serial Integration Gates

Ada, Grace, and Rose own these gates after both teams report:

1. Review each team's changed files and reject any fitted claim not backed by
   code, tests, docs, and evidence.
2. Keep shared-core files serial: formula grammar, family registry,
   likelihood design, family-link contract, exported documentation, Actions
   workflow, first-wave summary helpers, ROADMAP, NEWS, check-log, and
   after-task reports.
3. Run focused tests for every changed surface.
4. Run stale-claim searches before publishing.
5. Publish in the smallest reviewable PR possible. If Team A and Team B both
   produce substantial changes, prefer two PRs over one large mixed PR.

## Stop Conditions

Stop and ask rather than continue if:

- the Tweedie density requires porting nontrivial code without provenance;
- the Tweedie likelihood and comparator differ on the public scale;
- fixed-effect Tweedie recovery is unstable in the small tests;
- skew-normal parameterization choices conflict across sources;
- skewness, residual scale, and tail behaviour cannot be separated in the
  proposed tests;
- a team needs to edit the other team's owned files; or
- the branch accumulates multiple unrelated implementation commits.

## Overnight Success Definition

The overnight run succeeds if it produces one of these outcomes:

1. a small merged Tweedie fixed-effect PR plus a separate skew-normal design
   PR;
2. a safe Tweedie scaffold PR plus a skew-normal design PR; or
3. a documented stop with exact blockers, tests attempted, and next commands.

It does not succeed by claiming support for two new families without recovery
tests, documentation, and review.
