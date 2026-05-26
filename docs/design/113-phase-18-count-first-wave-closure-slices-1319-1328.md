# Phase 18 Count First-Wave Closure, Slices 1319-1328

This note closes Slice C of the Phase 18 review sequence. Its reader is an
applied ecology, evolution, or environmental-science user who wants to know
which count models have first-wave evidence, and an R package contributor who
needs the next Phase 18 lane to stay narrow.

Slice C does not add a new likelihood family or formula grammar. It reconciles
the count evidence that already exists on `main`, revalidates the focused
count tests, and names the next Slice D choices without turning them into
implicit commitments.

## C1 - Count Artifact Inventory

The first-wave count story now has four separate evidence surfaces:

| Surface | Fitted model claim | Artifact status | Boundary |
| --- | --- | --- | --- |
| Paired Poisson/NB2 `mu` random effects | Ordinary non-zero-inflated Poisson and NB2 `mu` random intercepts plus independent numeric `mu` slopes | DGPs, summarisers, smoke runners, repeatable grid writer, first-wave summary inclusion, profile-target rows, failure ledgers, and focused tests | No zero-inflated or hurdle random effects, zero-truncated NB2 random effects, correlated count slopes, structured count effects, or labelled count covariance blocks |
| NB2 log-`sigma` random intercept | `bf(count ~ x, sigma ~ z + (1 | id))` for ordinary non-zero-inflated NB2 | ADEMP sheet, DGP, summariser, smoke runner, summary helper, grid writer, direct `log_sd_sigma` profile-target row, and focused tests | No NB2 `sigma` slopes, joint `mu`/`sigma` random effects, zero-inflated/truncated/hurdle NB2 scale random effects, structured NB2 `sigma`, or Poisson scale effects |
| Poisson q=1 phylogenetic `mu` intercept | `bf(count ~ x + phylo(1 | species, tree = tree))` for ordinary non-zero-inflated Poisson | Runner contract, DGP, summariser, smoke runner, grid writer, optional direct `log_sd_phylo` profile artifacts, formal-grid wrapper, manual Actions task, and focused tests | No phylogenetic count slopes, q=2/q=4 count covariance, zero-inflated count phylogeny, spatial/animal/`relmat()` count structure, or count cross-parameter covariance |
| NB2 q=1 phylogenetic `mu` intercept | `bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z)` for ordinary non-zero-inflated NB2 | ADEMP sheet, DGP, target-plus-grouped-comparator fitter, summariser, smoke runner, grid writer, formal-grid QA, local sentinel/audit note, sharded manual Actions dispatch, completed 16-shard audit, and focused tests | Keep status at `hold_smoke_only` after the merged 500-replicate shard audit because profile intervals and low-count fixed-`sigma` recovery remain weak |

These surfaces are intentionally not one broad count-parity claim. They are a
small count evidence bundle: ordinary count mixed models plus q=1
phylogenetic smoke/formal-admission routes.

## C2 - NB2 Log-Sigma Random-Intercept Lane

The NB2 log-`sigma` random-intercept lane is already implemented as a focused
ordinary-count scale gate. Its public model is:

```r
drmTMB(
  bf(count ~ x, sigma ~ z + (1 | id)),
  family = nbinom2(),
  data = dat
)
```

The symbolic contract is:

```text
a_j ~ Normal(0, sd_sigma_intercept^2)
eta_mu_jk = beta0 + beta1 * x_jk
mu_jk = exp(eta_mu_jk)
eta_sigma_jk = gamma0 + gamma1 * z_jk + a_j
sigma_jk = exp(eta_sigma_jk)
count_jk ~ NB2(mu_jk, size = 1 / sigma_jk^2)
```

The important user interpretation is that `sd:sigma:(1 | id)` measures
between-group heterogeneity in overdispersion on the log-`sigma` scale. It is
not evidence for count mean heterogeneity, zero-inflation heterogeneity,
structured NB2 scale effects, or a general non-Gaussian scale random-effect
policy.

## C3 - Poisson/NB2 q1 Phylogenetic Count Sync

The Poisson and NB2 q=1 phylogenetic count lanes are synchronized around the
same narrow idea: a single species-level structured random intercept in the
log-mean predictor.

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)

drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

Poisson q1 has formal-grid machinery, but formal recovery claims still depend
on running and reviewing its 500-replicate gate. NB2 q1 has the stronger
overdispersion-aware formal-admission lane, including a grouped-species
comparator. Slice D1 ran and audited the 16-shard 500-replicate NB2 q1 artifact
set, then kept the route at `hold_smoke_only` because direct `log_sd_phylo`
profile intervals are boundary-sensitive and low-count fixed-`sigma` recovery
remains unstable.

## C4 - First-Wave Revalidation Boundary

The reusable first-wave summary runner currently carries the baseline
first-wave surfaces: Gaussian location-scale, `meta_V(V = V)`, paired
Poisson/NB2 `mu` random effects, fixed-effect proportions, fixed-effect
positive-continuous families, fixed-effect ordinal models, Gaussian random
slopes, and coordinate-spatial Gaussian `mu` slopes. Slice C revalidates that
runner after Slice B rather than expanding it with the heavier q1 phylogenetic
formal lanes.

That boundary is deliberate. The NB2 log-`sigma` and Poisson/NB2 q1 phylo
count lanes have their own route-specific grid writers and formal gates. They
should enter broad public summaries only after their focused artifacts are
audited together, with warning rows, boundary rows, Hessian rows, profile
failures, and grouped-comparator rows still visible.

## Slice D Choices After C

Slice D should be a decision lane, not an automatic grab bag. The next owner
should choose one of these paths and keep the others out of the PR:

| Candidate D lane | Why it could be next | Gate before implementation |
| --- | --- | --- |
| D1: NB2 q1 formal shard execution and audit | Completed after Slice C | The merged 16-shard artifact set had all 288 formal condition cells and 500 manifest rows per global shard-cell, but the promotion decision remains `hold_smoke_only` |
| D2: Student-t formal-grid closeout versus skew-normal implementation gate | The core-family map says shape/skewness is the next family decision after common families | Decide whether Student-t has enough formal evidence for the first public shape story before adding skew-normal density code |
| D3: Zero-one bounded-response design gate | Chosen as the next low-compute bounded-response lane | Write the fixed-effect likelihood/design boundary first; do not combine `zoi`/`coi` with bounded random effects |
| D4: Tweedie fixed-effect design gate | Lognormal and Gamma now cover positive-continuous first-wave artifacts, leaving semicontinuous positive data as a clear next measurement process | Start fixed-effect only, with intercept-only power before predictor-dependent power models |
| D5: Additional count-family design gate | Conway-Maxwell-Poisson, generalized Poisson, and related count families may answer underdispersion or alternative overdispersion questions | Treat each as a normal new-family task: likelihood design, parameterization note, simulation tests, docs, and no random effects before fixed-effect recovery |

Slice D3 now records the zero-one bounded-response design gate in
`docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md`.
For now, Conway-Maxwell-Poisson is a later count-family candidate, not part of
Slice C or D3. It should wait until the project owner chooses count-family
expansion as the next family direction.
