# Bivariate Residual-Scale Random-Slope Pre-Code Gate

This note is the pre-code design gate for **bivariate residual-scale random
slopes** — the "q2 scale slope" stage named in
`docs/design/67-sdstar-p8-poisson-q1.md` and the first prerequisite the
`bivariate_gaussian_q8_endpoint` registry row requires before any q8 endpoint
likelihood or status promotion. It does not add fitted support. It records the
target model, the parameterization plan, the identifiability risk, the
extractor and diagnostic contract, and the simulation/test plan so the eventual
implementation slice is small, reviewable, and evidence-backed.

The reader is an applied ecology, evolution, or environmental-science user who
wants to ask whether two responses share *individual differences in how
residual variability changes with a predictor* (a coupled-plasticity-of-
predictability question), and the package contributor who must implement the
likelihood without blurring residual `rho12` into a group-level scale
correlation.

## Purpose And Scope

This gate covers exactly one expansion: a shared labelled residual-scale
**slope** block across `sigma1` and `sigma2`, producing one latent correlation
`cor(sigma1:x, sigma2:x | p | id)`. It deliberately excludes the same-response
location-scale slope block (`mu1`/`sigma1`), the q8 all-endpoint block, random
effects in `rho12`, and any non-Gaussian or structured-dependence scale slope.
Those remain closed and are tracked separately in
`docs/design/28-double-hierarchical-endpoint.md` and
`docs/design/45-cross-dpar-correlation-gate.md`.

## Current Boundary

Two building blocks already exist and should be reused rather than rewritten:

| Building block | Status | Fitted syntax |
|---|---|---|
| Univariate independent residual-scale slope | Implemented | `sigma ~ z + (0 + x | id)` |
| Bivariate residual-scale random **intercept** covariance | Implemented | `sigma1 = ~ 1 + (1 | p | id)`, `sigma2 = ~ 1 + (1 | p | id)` |

The bivariate intercept block has a Phase 18 smoke/artifact lane
(`biv_gaussian_q2_scale`) that recovers the two scale SDs in `sdpars$sigma` and
the scale-scale intercept correlation in `corpars$sigma`.

What is closed today: any random-**slope** term in a bivariate scale formula.
`parse_random_sigma_term()` accepts only an intercept LHS when the
distributional parameter is `sigma1` or `sigma2`, and otherwise aborts
(`R/drmTMB.R:4963-4969`):

```
Only bivariate residual-scale random intercepts are implemented for `sigma1`.
i Residual-scale random slopes in bivariate models remain planned.
```

The boundary is locked in by tests at
`tests/testthat/test-biv-gaussian.R:2837-2864`, covering both the shared-label
form `(0 + x | p | id)` and the mixed-with-location form. That test is the
contract the implementation slice must convert from "errors" to "fits with
recovery evidence".

## Target Model

For two Gaussian responses measured repeatedly on a grouping factor `id`, with
one focal scale predictor `x`, the q2 scale-slope model is:

```text
y1_ij ~ Normal(mu1_ij, sigma1_ij^2)
y2_ij ~ Normal(mu2_ij, sigma2_ij^2),  corr(resid1, resid2) = rho12_ij

log(sigma1_ij) = X_sigma1[ij, ] beta_sigma1 + x_ij a_1j
log(sigma2_ij) = X_sigma2[ij, ] beta_sigma2 + x_ij a_2j

u_j = [a_1j, a_2j]'
u_j ~ MVN(0, D),  D = diag(s) R diag(s),
s = (sd_sigma1_x, sd_sigma2_x),  R = [[1, rho_s], [rho_s, 1]]
```

`rho_s = cor(sigma1:x, sigma2:x | p | id)` is a **group-level** correlation
between how each response's residual variability changes with `x`. It is not
`rho12`, which stays a separate row-level residual term:

```text
rho12_ij = 0.99999999 * tanh(X_rho12[ij, ] beta_rho12)
```

This is the q2 (intercept-free, slope-only) analogue of the implemented q2
scale-**intercept** block. The intercept-and-slope per response (q4 scale),
the same-response location-scale slope, and the full q8 endpoint block are
later, separately gated expansions.

## Future R Syntax

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ x + (0 + x | p | id),
  sigma2 = ~ x + (0 + x | p | id),
  rho12 = ~ 1
)
```

The shared label `p` declares one scale-slope covariance block across the two
responses. The fixed `x` in each `sigma` formula keeps the mean log-scale trend
separate from the random scale-slope deviations, exactly as the univariate
independent-slope route already does.

## Parameterization Plan

The slice should extend the existing bivariate covariance assembler from
intercept-only members to slope members; it should not introduce a parallel
code path.

1. **Member design columns.** The univariate independent-slope route already
   builds the per-observation slope design column for `(0 + x | id)`. Reuse that
   column construction for each `sigma1`/`sigma2` slope member, so the latent
   contribution is `x_ij * a_kj` rather than `a_kj`.
2. **Covariance block.** Feed those two slope members into the same bivariate
   parameter random-structure builder that currently assembles the intercept
   block (`build_biv_sigma_random_structure` →
   `build_biv_parameter_random_structure`). The block stays q=2 with one
   correlation, so the `eta_cor_sigma` / `log_sd_sigma` TMB parameter layout
   does not change shape; only the design columns feeding the latent vector
   change.
3. **Labels.** SD labels follow the existing
   `paste0(term_dpar, ":", member_label)` rule, giving
   `sigma1:(0 + x | p | id)` and `sigma2:(0 + x | p | id)` in `sdpars$sigma`.
   The correlation label follows `format_biv_sigma_cor_label()` with
   `coef_name = "x"`, giving exactly
   `cor(sigma1:x,sigma2:x | p | id)` in `corpars$sigma`.
4. **No new transform.** The non-centred `sqrt_cov_scale()` / `tanh`
   correlation transform used by the intercept block is sufficient; the slice
   adds no new parameter transform.

## Extractor And Diagnostic Contract

| Surface | Expected output |
|---|---|
| `sdpars$sigma` | `sigma1:(0 + x | p | id)`, `sigma2:(0 + x | p | id)` |
| `corpars$sigma` | one entry named `cor(sigma1:x,sigma2:x | p | id)` |
| `corpairs(fit, class = "scale-scale")` | one group-level row with `from_coef = "x"`, `to_coef = "x"`, `from_dpar = "sigma1"`, `to_dpar = "sigma2"`, distinct from the residual `rho12` row |
| `summary(fit)$parameters` | `sd:sigma:sigma1:(0 + x | p | id)`, `sd:sigma:sigma2:(0 + x | p | id)`, and `cor:sigma:cor(sigma1:x,sigma2:x | p | id)` |
| `profile_targets(fit)` | direct `log_sd_sigma` targets for the two slope SDs and an `eta_cor_sigma` target for the correlation, matching the intercept block's target classes |
| `check_drm(fit)` | a `biv_sigma_random_effect_covariance` row reporting group count, minimum group size, and a singleton-group note |

The scale-slope correlation should be reported as a direct profile target only
if profiling behaves; otherwise it stays `derived_interval_unavailable`, the
same conservative rule the q4/q8 endpoints use.

## Identifiability Risk

Residual-scale slopes are the most weakly identified effect in this family: the
data must show that the *spread* of residuals changes with `x` differently
across groups, and then that those changes covary across two responses. The
implementation and its simulation grid should respect that:

- require many observations per group, with adequate within-group spread in
  `x`, before claiming recovery;
- expect the scale-slope SDs and `rho_s` to need larger samples than the
  intercept block did;
- treat near-zero scale-slope SD as a poorly-identified correlation and surface
  it through `check_drm()`, not as a confident estimate;
- keep the focal `x` for the scale slope on a centred, modest range to avoid
  `exp()` overflow in `log(sigma)`.

## Simulation And Test Plan (ADEMP)

- **Aim.** Show that the bivariate scale-slope block recovers the two
  scale-slope SDs and the scale-slope correlation without contaminating
  residual `rho12`.
- **Data-generating model.** The target model above: correlated log-sigma
  slopes per group, separate residual `rho12`. A natural extension of the
  `biv_gaussian_q2_scale` DGP, adding the `x`-driven random scale slope.
- **Estimands.** `sd_sigma1_x`, `sd_sigma2_x`, `cor(sigma1:x,sigma2:x | p | id)`,
  the fixed `sigma` slopes, and `rho12`, kept as separate rows.
- **Methods.** A single new fit function mirroring
  `phase18_fit_biv_gaussian_q2_scale` but with `(0 + x | p | id)` in both scale
  formulas, behind a new registry row distinct from the intercept lane.
- **Performance measures.** Convergence and `pdHess` rate first (smoke), then
  bias, empirical coverage, and Monte Carlo standard error before any recovery
  claim.
- **Malformed-input tests.** Keep rejecting the same-response location-scale
  slope block, the q8 all-four slope block, labelled scale-slope blocks in
  non-Gaussian families, and random effects in `rho12`; convert only the
  matching `sigma1`/`sigma2` slope block from error to fit.

## Admission Rules

- Open this one endpoint class only; do not let the slice also open the
  same-response location-scale slope or the q8 block.
- Add malformed-input tests and the parser conversion before likelihood algebra.
- Require `corpairs()` names that tell the reader the pair is `sigma1:x` versus
  `sigma2:x` at the group level, not a residual coupling.
- Keep the derived correlation at `derived_interval_unavailable` until direct
  profile, derived-profile, or bootstrap evidence exists.
- Start with a small, controlled simulation grid; real-data teaching examples
  come after recovery and coverage evidence.

## What To Try Today

Until this slice lands, an applied user with a scale-slope question should:

- fit each response separately with a univariate independent scale slope,
  `sigma ~ x + (0 + x | id)`, accepting that the cross-response scale-slope
  correlation is not estimated; or
- fit the implemented bivariate scale-**intercept** block,
  `sigma1 = ~ 1 + (1 | p | id)`, `sigma2 = ~ 1 + (1 | p | id)`, when the
  question is about baseline residual variability rather than its change with a
  predictor.

The error message at `R/drmTMB.R:4963-4969` should keep pointing users to these
fitted fallbacks.

## Cross-References To Keep Aligned

- `docs/design/67-sdstar-p8-poisson-q1.md` — the "q2 scale slope" staged row
  should point to this gate.
- `docs/design/28-double-hierarchical-endpoint.md` — implementation order step
  for residual-scale slopes.
- `docs/design/45-cross-dpar-correlation-gate.md` — the `sigma` and bivariate
  rows that list correlated residual-scale slope blocks as not-in-Wave-A.
- `docs/design/143-phase-18-structured-workflow-registry.md` — when a fitted
  scale-slope lane is admitted, add its registry row; until then the
  `bivariate_gaussian_q8_endpoint` row keeps this listed as a prerequisite.
