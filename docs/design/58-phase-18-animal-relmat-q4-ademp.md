# Phase 18 Animal/Relmat Q4 Addendum

This addendum admits only the focused constant all-four Gaussian q=4
`animal()` and `relmat()` smoke lane. It extends the known-matrix q=2 ADEMP
sheet without changing the public q4 boundary: sparse large-pedigree
construction, predictor-dependent `corpair()` regressions, direct-SD grammar,
and non-Gaussian animal/relmat q4 covariance remain planned. Exact q1
non-Gaussian provider gates are separate and are not evidence from this sheet.

## Aim

The q=4 lane asks whether one known relatedness matrix can explain coupled
variation in four bivariate Gaussian endpoints:

```text
mu1, mu2, log(sigma1), log(sigma2)
```

The useful applied question is not just whether the model optimizes. The smoke
artifact must also show whether q=4 latent animal or relatedness correlations
are point estimates only, direct profile targets, or derived targets without
interval support.

## Data-Generating Mechanism

For group levels `g = 1, ..., n_level`, generate a known positive-definite
matrix `K_group` and its precision `Q_group`. The `animal()` route may receive
`pedigree`, `A`, or `Ainv`; the `relmat()` route may receive `K` or `Q`.

The latent group effect is four-dimensional:

```text
u_g = [u_mu1,g, u_mu2,g, u_sigma1,g, u_sigma2,g]'
u ~ MVN(0, S x K_group)
```

where `S` is a 4 by 4 endpoint covariance matrix with endpoint SDs
`sd_mu1`, `sd_mu2`, `sd_sigma1`, and `sd_sigma2`, plus the six endpoint
correlations:

```text
mu1-mu2, mu1-sigma1, mu1-sigma2,
mu2-sigma1, mu2-sigma2, sigma1-sigma2
```

The response model keeps residual coscale separate:

```text
mu1_i = beta10 + beta11 x_i + u_mu1,g[i]
mu2_i = beta20 + beta21 x_i + u_mu2,g[i]
log(sigma1_i) = alpha10 + alpha11 z_i + u_sigma1,g[i]
log(sigma2_i) = alpha20 + alpha21 z_i + u_sigma2,g[i]
Omega12_i = rho12 * sigma1_i * sigma2_i
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
```

`rho12` is still the within-observation residual correlation. It is not the
animal or `relmat()` latent correlation.

## Estimands And Interval Status

| Row family | Truth | Estimate | First interval status |
| --- | --- | --- | --- |
| Fixed `mu1`, `mu2`, `sigma1`, `sigma2` coefficients | DGP coefficients | `coef(fit, dpar = ...)` | Wald only when standard errors are requested and finite |
| q=4 structured SDs | four endpoint SDs in `S` | `sdpars$mu` rows | Direct profile target can be requested later, but the smoke defaults to point estimates |
| q=4 structured correlations | six endpoint correlations in `S` | `corpars$animal`, `corpars$relmat`, `corpairs()` | Derived unstructured-correlation targets; direct profile intervals are unavailable |
| Residual coscale | `rho12` | `rho12(fit)` | Direct profile target only when explicitly requested |
| `K`, `Q`, `A`, `Ainv`, or pedigree | supplied input | no estimator | no interval row |

The default q=4 smoke uses `se = FALSE` and therefore writes no Wald rows.
This is deliberate: q=4 is a structural-dependence evidence lane first, not a
coverage claim. If standard-error calculation is enabled later, fixed-effect
Wald rows may be added without changing the derived-correlation policy.

## Artifact Contract

The q=4 smoke lane now has the same reusable artifact shape as the q=2 lane:

- `phase18_dgp_animal_relmat_q4()` creates seeded DGPs with the full endpoint
  covariance truth attached.
- `phase18_run_animal_relmat_q4_smoke()` fits matching all-four `animal()` or
  `relmat()` formulas and writes resumable replicate RDS files.
- `phase18_summarise_animal_relmat_q4_smoke()` returns aggregate, replicate,
  manifest, failure, profile-status, interval-evidence, diagnostic, and
  interval-failure tables.
- `phase18_write_animal_relmat_q4_grid_outputs()` writes the same tables as
  CSV artifacts for scheduled or local smoke grids.

The grid writer may be used for small smoke evidence. A broad q=4 operating
characteristic report still needs larger replicate counts, figure review, and
an explicit interpretation plan for near-boundary endpoint correlations.

## Failure Ledger

Keep these rows outside the q=4 smoke claim:

- structured animal, `relmat()`, phylogenetic, or spatial slopes;
- sparse large-pedigree precision construction;
- standalone univariate `sigma ~ animal(...)` or `sigma ~ relmat(...)`;
- predictor-dependent `corpair()` regressions for `animal()` or `relmat()`;
- direct-SD grammar such as future `sd_animal()` or `sd_relmat()`;
- non-Gaussian structured effects.

These boundaries are useful to applied users because they prevent a fitted
point-estimate route from being mistaken for a complete inferential route.
