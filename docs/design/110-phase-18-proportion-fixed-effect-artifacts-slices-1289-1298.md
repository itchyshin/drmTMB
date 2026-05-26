# Phase 18 Proportion Fixed-Effect Artifacts, Slices 1289-1298

This note records the first artifact lane for fitted bounded-response models.
The reader is an applied user asking whether `drmTMB` has simulation evidence
for ordinary proportions, and a package contributor deciding what still belongs
in the failure ledger.

## Implemented Claim

Slices 1289-1298 add a Phase 18 artifact path for fixed-effect `beta()` and
`beta_binomial()` models:

```r
drmTMB(
  bf(prop ~ x, sigma ~ z),
  family = beta(),
  data = dat
)

drmTMB(
  bf(cbind(success, failure) ~ x, sigma ~ z),
  family = beta_binomial(),
  data = dat
)
```

The fitted mean uses `logit(mu) = eta_mu`, the public scale uses
`log(sigma) = eta_sigma`, and the internal beta precision is
`phi = 1 / sigma^2`. Larger public `sigma` therefore means more variation
around the fitted mean, not more precision.

## Artifact Path

The new DGP generates one standardized mean predictor `x` and one standardized
scale predictor `z`, with optional correlation `rho_xz`. For strict continuous
proportions it draws:

```text
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

For denominator-aware data it draws a latent probability and then successes out
of known trials:

```text
p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
success_i ~ Binomial(trials_i, p_i)
failure_i = trials_i - success_i
```

The summariser records fixed `mu` and `sigma` coefficients on the modelled link
scale, convergence, Hessian status, elapsed time, warning counts, Wald
intervals, and Wald coverage. The grid writer saves aggregate, replicate,
manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage CSV
artifacts beside resumable per-replicate RDS results.

## Integration Boundary

This clean-branch salvage slice restores the core private artifact lane only:
DGP, summariser, smoke runner, summary helper, grid writer, focused tests, and
developer ledgers. It does not yet wire the surface into the first-wave summary
runner or the manual GitHub Actions task list.

This does not change the fitted likelihood surface. It gives the already-fitted
fixed-effect beta and beta-binomial routes the same local artifact discipline
that the count route already has, while keeping report-bundle and Actions
integration as separate review slices.

## Boundaries

This slice deliberately keeps the following outside the admitted surface:

- exact 0/1 boundary mass for strict beta responses;
- `zoi` and `coi` formulas;
- bounded-response random effects;
- phylogenetic, spatial, animal, or `relmat()` bounded-response effects;
- bounded-response `meta_V(V = V)`;
- bivariate or mixed-response bounded models.

Those neighbours remain failure-ledger or future-design surfaces until they
have separate likelihood, syntax, diagnostic, interval, and simulation gates.
