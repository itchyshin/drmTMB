# Bivariate Residual-Scale Random-Slope Gate

This note began as the pre-code design gate for **bivariate residual-scale
random slopes** — the "q2 scale slope" stage named in
`docs/design/67-sdstar-p8-poisson-q1.md` and the first prerequisite the
`bivariate_gaussian_q8_endpoint` registry row requires before any q8 endpoint
likelihood or status promotion. The matching `sigma1`/`sigma2` slope-only block
is now fitted as the first implementation slice. This note records the target
model, the parameterization, the identifiability risk, the extractor and
diagnostic contract, and the simulation/test evidence boundary.

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
| Bivariate residual-scale random **slope** covariance | Implemented first slice | `sigma1 = ~ x + (0 + x | p | id)`, `sigma2 = ~ x + (0 + x | p | id)` |

The bivariate intercept block has Phase 18 smoke and recovery lanes
(`biv_gaussian_q2_scale`, `biv_gaussian_q2_scale_recovery`) that recover the two
scale SDs in `sdpars$sigma` and the scale-scale intercept correlation in
`corpars$sigma`. The bivariate slope block has parallel smoke and recovery
lanes (`biv_gaussian_q2_scale_slope`,
`biv_gaussian_q2_scale_slope_recovery`) for the two scale-slope SDs, the
group-level scale-slope correlation, fixed scale slopes, and residual `rho12`.

What remains closed: q8 coverage/power evidence, q8 variants beyond the
matching one-slope ordinary Gaussian route, random effects in `rho12`,
non-Gaussian scale-slope covariance, and structured-dependence scale slopes.
The same-response q2 `mu`/`sigma` slope slice is a separate source-tested
route. The boundary is locked in by malformed-input tests in
`tests/testthat/test-biv-gaussian.R`.

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
rho12_ij = 0.999999 * tanh(X_rho12[ij, ] beta_rho12)
```

This is the q2 (intercept-free, slope-only) analogue of the implemented q2
scale-**intercept** block. The intercept-and-slope per response (q4 scale),
the same-response location-scale slope, and the full q8 endpoint block are
later, separately gated expansions.

## R Syntax

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

The two scale-slope SDs and their q2 correlation are direct profile targets.
The Phase 18 recovery lane reports Wald coverage only for fixed-effect
endpoints that carry standard errors; it does not promote q8 or same-response
location-scale intervals.

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
- **Methods.** `phase18_fit_biv_gaussian_q2_scale_slope()` mirrors
  `phase18_fit_biv_gaussian_q2_scale()` but uses `(0 + x | p | id)` in both
  scale formulas, behind registry rows distinct from the intercept lane.
- **Performance measures.** Convergence and `pdHess` rate first (smoke), then
  bias, empirical spread, RMSE, and Monte Carlo standard error. Fixed-effect
  Wald coverage is reported where standard errors exist.
- **Malformed-input tests.** Keep rejecting the same-response location-scale
  slope block, the q8 all-four slope block, labelled scale-slope blocks in
  non-Gaussian families, and random effects in `rho12`; only the matching
  `sigma1`/`sigma2` slope block is fitted.

## Admission Rules

- Open this one endpoint class only; do not let the slice also open the
  same-response location-scale slope or the q8 block.
- Add malformed-input tests and the parser conversion before likelihood algebra.
- Require `corpairs()` names that tell the reader the pair is `sigma1:x` versus
  `sigma2:x` at the group level, not a residual coupling.
- Keep q4/q8 derived correlations at `derived_interval_unavailable` until
  direct profile, derived-profile, or bootstrap evidence exists.
- Start with a small, controlled simulation grid; real-data teaching examples
  come after recovery and coverage evidence.

## What To Try Today

An applied user with a cross-response scale-slope question can now fit the
matching q2 route:

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ x + (0 + x | p | id),
  sigma2 = ~ x + (0 + x | p | id),
  rho12 = ~ 1
)
```

If the question is only about baseline residual variability, fit the
implemented bivariate scale-**intercept** block,
`sigma1 = ~ 1 + (1 | p | id)` with
`sigma2 = ~ 1 + (1 | p | id)`. If the question needs same-response
location-scale slopes, use the named q2 same-response route. If the question
needs p8 endpoint covariance, q8 variants beyond the first ordinary diagnostic
lane, or structured scale-slope covariance, that model remains planned and
should not be taught as current syntax.

## Cross-References To Keep Aligned

- `docs/design/67-sdstar-p8-poisson-q1.md` — the "q2 scale slope" staged row
  records this fitted first slice.
- `docs/design/28-double-hierarchical-endpoint.md` — implementation order step
  for residual-scale slopes.
- `docs/design/45-cross-dpar-correlation-gate.md` — the `sigma` and bivariate
  rows keep the fitted q2 scale-slope route separate from same-response and q8
  slopes.
- `docs/design/143-phase-18-structured-workflow-registry.md` — the fitted
  scale-slope smoke and recovery lanes are admitted registry rows; the q8
  endpoint smoke and recovery rows are admitted diagnostic registry rows without
  coverage or power promotion.
