# Slices 406-450: `sd*()` Plan, p8/q8 Plan, and Poisson Phylogenetic q=1 Gate

This note records the first post-0.1.3 implementation map follow-through. It
keeps three ideas connected but separate:

1. generic `sd*()` direct-SD grammar is a naming and compatibility plan;
2. p8/q8 endpoint covariance has a first ordinary Gaussian q8 smoke/recovery/staged-start
   artifact lane, but no coverage or power evidence;
3. ordinary Poisson q=1 phylogenetic `mu` is the first fitted structured
   non-Gaussian slice.

The useful-user question is simple: can an applied user fit a model today, and
will the docs tell them what smaller fitted route to use when the richer model is
not ready?

## Standing Review

| Perspective | Decision for this slice |
| --- | --- |
| Ada | Keep code, maps, validation debt, source map, check log, and after-task report aligned. |
| Boole | Open no broad formula grammar silently; q=1 Poisson `phylo()` gets exact syntax and nearby planned routes get explicit errors. |
| Gauss | Treat the Poisson structured path as an algebra smoke gate, not proof that all count structured likelihoods are stable. |
| Noether | Match the equation, R syntax, TMB precision prior, and extractor labels exactly. |
| Darwin | Make the fitted count route biologically meaningful: phylogenetic species differences in expected counts. |
| Fisher | Separate fitted support from recovery, profile, and coverage evidence. |
| Pat | Tell users when to fit Poisson phylogenetic q=1 and when to fall back to ordinary Poisson/NB2 random effects. |
| Emmy | Keep `sdpars`, `ranef("phylo_mu")`, `profile_targets()`, and `check_drm()` coherent with fitted-object labels. |
| Grace | Keep pkgdown, roxygen, tests, and CI/deploy status visible. |
| Rose | Watch for old blanket non-Gaussian-structure wording after this narrow first slice lands. |

## Generic `sd*()` Direct-SD Plan

The public direction is generic direct-SD grammar with explicit dependence
levels:

```r
sd(species, level = "phylogenetic") ~ z_species
sd(site, level = "spatial") ~ z_site
sd(id, level = "animal") ~ z_id
sd(line, level = "relmat") ~ z_line
```

The current fitted `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` helpers remain
compatibility paths. They should not be silently removed or renamed, because
existing examples and tests use them and because the tree-scaled
`D_tip A_tip D_tip` contract is easy to confuse with ordinary independent
`sd(group)`.

Before parser work opens the generic route, the project needs:

| Gate | Requirement |
| --- | --- |
| Grammar | `sd(group)` continues to mean ordinary group-level direct SD by default; `level = ...` selects `phylogenetic`, `spatial`, `animal`, or `relmat`. |
| Compatibility | Existing `sd_phylo*()` routes remain aliases or documented compatibility helpers through a lifecycle decision. |
| Targeting | Coefficient-specific targets such as `coef = "x"` remain planned until slope-SD likelihoods have tests. |
| Extractors | `coef()`, `summary()`, `predict_parameters()`, `marginal_parameters()`, `profile_targets()`, and `check_drm()` must expose the same target labels. |
| Reference discoverability | The Reference index must surface the generic formula grammar even if it is parsed syntax rather than a normal exported modelling function. |
| User fallback | Each planned generic row must point to the currently fitted route: ordinary `sd(group) ~ x` or `sd_phylo*()` as applicable. |

## p8/q8 Endpoint Plan

p8/q8 refers to all-endpoint location-scale slope covariance. The first
ordinary Gaussian route is fitted when all four bivariate endpoint formulas use
the same labelled `(1 + x | p | id)` term. It now has diagnostic smoke and
recovery artifact tasks, but not coverage or power evidence. For two Gaussian
responses with one focal slope `x`, the full endpoint vector is:

```text
b = (
  mu1:(Intercept), mu1:x,
  mu2:(Intercept), mu2:x,
  sigma1:(Intercept), sigma1:x,
  sigma2:(Intercept), sigma2:x
)
```

That is 8 latent endpoints, 8 SDs, and 28 pairwise correlations. It is useful
for questions about individual differences in average response, plasticity,
predictability, and malleability, but it is also easy to overfit.

The current staged path is:

| Stage | Candidate syntax | Status |
| --- | --- | --- |
| q2 slope-only location | `(0 + x | p | id)` in both `mu1` and `mu2` | fitted first slice; slope1-slope2 row is direct |
| q4 location intercept+slope | `(1 + x | p | id)` in both `mu1` and `mu2` | fitted and smoke-artifact wired; q4 correlations are derived-unavailable for intervals |
| q2 scale slope | matching `sigma1`/`sigma2` slope-only labels | fitted first slice with smoke and recovery routing; gate and implementation contract in `docs/design/155-bivariate-residual-scale-random-slope-gate.md`; separate from residual `rho12` |
| q2 same-response location-scale slope | matching `mu1`/`sigma1` or `mu2`/`sigma2` slope labels | fitted first slice with smoke/recovery routing; high identifiability risk; 2026-06-06 formal audit is diagnostic only, with convergence/positive-Hessian rates 0.856 and 0.884, all-replicate fixed-effect Wald coverage 0.796-0.850, no rescue among 130 robust-refit weak replicates, interval-available fixed-effect coverage 0.930-0.972, and two clean endpoint-profile demonstrations |
| q8 all-endpoint block | all four dpars with intercept and slope endpoints | fitted first ordinary Gaussian slice with diagnostic smoke/recovery/staged-start artifacts; the 2026-06-07 local two-cell recovery audit is `hold_diagnostic`; q8 correlations are derived-unavailable until a validated interval method exists |

The Phase 18 structured workflow registry now carries this as the
`bivariate_gaussian_q8_endpoint` smoke row plus the
`bivariate_gaussian_q8_endpoint_recovery` diagnostic recovery row. The helper
`phase18_biv_gaussian_q8_endpoint_precode_gate()` names the eight endpoints and
28 correlations and confirms that the smoke row is `ready_grid` with the
`biv_gaussian_q8_endpoint` Actions task.

The first local multi-cell recovery audit ran on 2026-06-07 with two default
cells, 20 requested replicates per cell, and `se = FALSE`. It wrote artifacts
under
`inst/sim/results/actions/biv_gaussian_q8_endpoint_recovery_audit_20260607/`.
The result is a diagnostic hold: 38/40 manifests completed, model convergence
rates were 0.263 and 0.158, positive-Hessian rates were 0, two replicates
failed with non-positive leading minors, and no Wald intervals were usable.

Admission rules:

- Open one endpoint class at a time.
- Require malformed-input tests before likelihood work.
- Require `corpairs()` names that tell the reader which endpoint pair they are
  reading.
- Keep q4/q8 correlations at `derived_interval_unavailable` until direct
  profile, derived-profile, or bootstrap evidence exists.
- Prefer small, controlled simulation grids before real-data demonstrations
  become teaching examples.

## Poisson Phylogenetic q=1 `mu` Gate

The first structured non-Gaussian path is ordinary Poisson, one response, one
structured random intercept, and one distributional parameter:

```r
fit <- drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

The model is

```text
count_i | a ~ Poisson(mu_i)
log(mu_i) = offset_i + x_i beta + a_species[i]
a ~ Normal(0, sd_phylo^2 A)
```

where `A` is the phylogenetic covariance implied by `tree`; the TMB
implementation uses its sparse precision `Q`. This is a q=1 route, so there is
one structured SD and no latent correlation row.

| Surface | Current status |
| --- | --- |
| Ordinary Poisson `mu` fixed effects | fitted |
| Ordinary Poisson `mu` random intercepts and independent slopes | fitted |
| Ordinary Poisson `phylo(1 | species, tree = tree)` | fitted first slice |
| Poisson phylogenetic slopes | planned |
| Poisson labelled q=2/q=4 phylogenetic blocks | planned |
| Zero-inflated Poisson phylogenetic effects | planned |
| NB2 phylogenetic effects | ordinary q=1 `mu` intercept fitted as a first slice; slopes, `sigma`, `zi`, and q2/q4 blocks planned |
| Poisson/NB2 spatial, animal, or `relmat()` q=1 `mu` intercepts | source/diagnostic first slices; slopes, labels, and simultaneous layers planned |
| Count `sigma`, `zi`, `hu`, shape, or cross-parameter covariance | planned or blocked by family |

Extractor and diagnostic contract:

| Route | Expected output |
| --- | --- |
| `sdpars$mu` | row named like `phylo(1 | species)` |
| `ranef(fit, "phylo_mu")` | conditional species effects on the link scale |
| `profile_targets(fit)` | direct target for `log_sd_phylo` |
| `check_drm(fit)` | `phylo_mu_diagnostics` row with species count and SD ratio information |
| `corpairs(fit)` | no count row for q=1, because there is no pairwise latent correlation parameter |

This is useful for users who have count responses and a clear phylogenetic
dependence hypothesis. It is not useful as a shortcut for overdispersed counts,
zero-inflated structural zeros, spatial autocorrelation, individual animal
relatedness, or all non-Gaussian structural parity. Those routes need their own
likelihood, recovery, extractor, interval, and documentation evidence.

The simulation-admission sheet for this route is
`docs/design/70-phase-18-poisson-structured-q1-ademp.md`. That sheet must move
before any recovery runner or Phase 18 artifact claims broader than smoke-level
Poisson phylogenetic q1 support.
