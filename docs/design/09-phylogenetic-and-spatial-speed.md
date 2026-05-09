# Phylogenetic and Spatial Speed Plan

Phylogenetic and spatial dependence are important from the first design phase,
but they should enter through focused, tested modules after the Gaussian
fixed-effect path is reliable.

## Principle

`drmTMB` can borrow proven speed ideas from `gllvmTMB`, `sdmTMB`, and related
TMB packages, but the package identity stays distributional:

- one or two responses;
- one formula per estimated parameter;
- location, scale, shape, known covariance, and residual `rho12`.

The common mathematical object is a structured Gaussian effect:

```text
eta_d = X_d beta_d + Z_d z
z ~ MVN(0, sigma_z^2 K)
```

For phylogeny, `K = A`, the phylogenetic correlation matrix. For spatial
dependence, `K = M`, the spatial correlation matrix. The dense covariance
notation is the teaching layer; the implementation should use sparse precision
matrices whenever possible.

See `docs/design/16-phylo-spatial-common-math.md` for the full mathematical
bridge between phylogenetic and spatial models.

## Phylogenetic Dependence

Primary speed path:

- use the Hadfield and Nakagawa A-inverse trick for phylogenetic random
  effects;
- prefer sparse precision matrices when available;
- keep `gr()` as the low-level known-covariance term;
- expose structured random-effect syntax such as
  `phylo(1 | species, tree = tree)` as the high-level user-facing term.
  Public `phylo()` should require an ultrametric tree with branch lengths; a
  dense covariance matrix is useful for small internal comparators but should
  not be the main user-facing phylogeny input.

Implemented univariate phylogenetic syntax:

```r
bf(
  y ~ x1 + phylo(1 | species, tree = tree),
  sigma ~ x1
)
```

Planned bivariate and distributional extensions:

```r
bf(
  mu1 = y1 ~ x1 + phylo(1 | species, tree = tree),
  mu2 = y2 ~ x1 + phylo(1 | species, tree = tree),
  sigma1 = ~ x1,
  sigma2 = ~ x1,
  rho12 = ~ x1
)
```

The biological target is the phylogenetic location-scale model of Nakagawa et
al. (2025), extended in `drmTMB` with residual coscale regression. In the MEE
PLSM framing, means and log residual SDs are treated as parallel evolutionary
responses, with phylogenetic random effects and covariance among location and
scale components. The `drmTMB` extension adds a residual-correlation predictor:

```text
log(sigma1_i) = W1[i, ] gamma1
log(sigma2_i) = W2[i, ] gamma2
eta_rho12_i = R[i, ] delta
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

This turns covariance homogeneity into a testable biological assumption.
For example, the body mass-litter size relationship in mammals can be asked at
three levels: phylogenetic correlation, non-phylogenetic among-species
correlation, and residual coscale `rho12 ~ lifestyle`.

### gllvmTMB Source Map

The first implementation should borrow concepts from `gllvmTMB`, not import
high-dimensional GLLVM API assumptions. Specific sister-package files to study:

| Purpose | gllvmTMB source | drmTMB translation |
| --- | --- | --- |
| Keyword grammar and desugaring | `../gllvmTMB/R/brms-sugar.R` terms such as `phylo_scalar()`, `phylo_unique()`, `spatial_scalar()`, and `spatial_unique()` | Use as precedent for readable aliases, but avoid importing the full 3 by 5 multivariate keyword grid. |
| Public tree/VCV inputs | `../gllvmTMB/R/gllvmTMB.R` arguments such as `phylo_tree`, `phylo_vcv`, and `mesh` | Document tree-versus-VCV and mesh inputs, tied to one- or two-response distributional formulas. |
| Formula AST parsing | `../gllvmTMB/R/parse-multi-formula.R` functions `parse_multi_formula()`, `parse_covstruct_call()`, and `parse_re_int_call()` | Split fixed terms, ordinary random effects, and structured effects before building TMB data. |
| Sparse phylogenetic A-inverse setup | `../gllvmTMB/R/fit-multi.R` around the `Ainv_phy_rr` construction | Build a small univariate `phylo(1 | species, tree = tree)` data-preparation path first. |
| TMB data and maps | `../gllvmTMB/R/fit-multi.R` sections on phylogenetic VCV preparation, SPDE preparation, TMB inputs, and maps | Keep structured-effect variants explicit in R-side data and parameter maps. |
| Sparse A-inverse TMB data contract | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` A-inverse data declarations | Define minimal sparse precision inputs for one random-effect term before bivariate use. |
| Sparse phylogenetic prior | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` Stage-35/Stage-40 phylogenetic blocks | Add a tested GMRF/prior block that can attach to `mu`, later `sigma`. |
| Phylogenetic tests | `../gllvmTMB/tests/testthat/test-phylo-hadfield.R` | Use sparse-vs-dense equivalence and parameter-recovery tests. |

## Spatial Dependence

Primary speed path:

- use SPDE/GMRF sparse precision structures;
- keep spatial fields modular so they can be added to `mu`, and later to
  `sigma` when identifiable;
- use structured random-effect syntax such as
  `spatial(1 | site, coords = coords)` or `spatial(1 | site, mesh = mesh)`.

Planned syntax:

```r
bf(
  y ~ depth + temp + spatial(1 | site, coords = coords),
  sigma ~ temp
)
```

`coords` and `mesh` should be treated as two entry points to the same spatial
field, not as two biological model types. `coords` identifies the observation
or site coordinates used to build a mesh. `mesh` supplies an already-built
finite-element scaffold plus the projection information needed to map mesh
vertices back to observations. In both cases, the fitted quantity is a
structured spatial random effect; the mesh itself is a computational support,
not a response, predictor, or sampling level to interpret biologically.

Planned mesh-explicit syntax:

```r
bf(
  y ~ depth + temp + spatial(1 | site, mesh = mesh),
  sigma ~ temp
)
```

Later spatial random slopes should follow the same pattern:

```r
bf(
  y ~ depth + temp + spatial(1 + depth | site, coords = coords),
  sigma ~ temp
)
```

### gllvmTMB SPDE Source Map

| Purpose | gllvmTMB source | drmTMB translation |
| --- | --- | --- |
| Mesh construction | `../gllvmTMB/R/mesh.R` | Provide a small mesh helper or accept a prepared mesh object. |
| SPDE keyword documentation | `../gllvmTMB/R/spde-keyword.R` | Reuse the teaching structure for Matérn/SPDE parameters without importing gllvmTMB's latent-factor API. |
| Mesh validation and TMB data | `../gllvmTMB/R/fit-multi.R` spatial mesh validation and data passing | Start with one location-field term for one response. |
| SPDE precision | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` SPDE data contract, `Q_base` construction, and spatial projected fields | Build a focused SPDE module before allowing scale fields. |
| SPDE tests | `../gllvmTMB/tests/testthat/test-stage4-spde.R` and `../gllvmTMB/tests/testthat/test-spatial-latent-recovery.R` | Use recovery tests for location fields before adding bivariate or scale models. |
| API keyword grid | `../gllvmTMB/vignettes/articles/api-keyword-grid.Rmd` | Read for semantics, then simplify for `drmTMB`'s univariate/bivariate scope. |

The most useful implementation abstraction is a structured random-effect block
with a sparse precision and a design/projection map. Phylogeny supplies
`K = A_phy` and the fast path evaluates with sparse `A_phy^{-1}`. Space makes
`K` implicit through `Q_spde`, with mesh-node fields projected to observations.
The public terms can be different, but the TMB block should be shared.

For phylogeny, the large-tree implementation should work with the expanded
tree precision described by Hadfield and Nakagawa: include internal nodes,
build the sparse inverse of the expanded relationship matrix, and project the
tip-level species effects back to observations. Dense tip covariance should
remain a teaching and comparator route, not the main speed route.

For Matérn/SPDE documentation, keep this parameterization on the design radar:

```text
Q = kappa^4 M0 + 2 kappa^2 M1 + M2
practical_range = sqrt(8) / kappa
```

This is a later implementation detail, but documenting it now prevents the
spatial path from drifting away from the sister-package math.

Residual `rho12` remains conceptually separate from phylogenetic or spatial
correlation: `rho12 ~ predictors` models residual response coupling at the
observation level, whereas A-inverse and SPDE terms model structured dependence
among units or locations.

The tutorial on phylogenetic and spatial meta-analysis makes this separation
particularly clear: phylogenetic random effects are distributed as
`MVN(0, sigma_phylo^2 A)`, spatial random effects as
`MVN(0, sigma_space^2 M)`, while sampling errors enter through known variances
or covariance matrix `V`. These are structured sources of dependence, not
residual response-response correlation.

Later phylogenetic coscale models may also allow phylogenetic structure in
scale and coscale predictors, for example phylogenetic effects in
`log(sigma1)`, `log(sigma2)`, or the `rho12` linear predictor. These should be
later phases with strong simulation evidence because they are much harder to
identify than fixed-effect `rho12 ~ predictors`.

## Structured Random-Slope Policy

Ordinary grouped random slopes can be more permissive than phylogenetic and
spatial random slopes. A term such as `(0 + x | id)` adds one independent
group-level coefficient per group. A phylogenetic or spatial slope adds another
structured latent vector or field, which is harder to separate from ordinary
random effects, residual scale, and fixed effects.

Implementation should therefore proceed in this order:

1. intercept-only phylogenetic or spatial structured effects in `mu`;
2. one structured random slope in `mu`, with strong simulation recovery;
3. at most a small number of structured slopes after diagnostics show the data
   have enough replication and design variation;
4. interaction slopes only as experimental models with explicit warnings;
5. structured slopes in `sigma` or `rho12` only after the `mu` path is stable.

The number of possible slopes is not a hard mathematical limit, but the package
should impose conservative defaults and diagnostics. For spatially varying
coefficients or phylogenetic slope variation, the user-facing syntax can be
generous later; the first implementation should be sparse, staged, and easy to
validate.

## Reuse Policy

`drmTMB` is a sister package to `gllvmTMB`, not a fork. Reuse should be
selective and traceable:

- prefer design ideas and small, isolated GPL-compatible modules;
- document provenance in `inst/COPYRIGHTS` before ported code is merged;
- add simulation or equivalence tests around ported numerical code;
- avoid importing high-dimensional GLLVM assumptions into the `drmTMB` API.

No `gllvmTMB` code has been ported into `drmTMB` at this stage; the paths above
are source maps for later design and review.

## Implementation Order

1. Define formula markers and design docs.
2. Implement fixed-effect Gaussian location-scale.
3. Add random intercepts.
4. Add dense known covariance for meta-analysis.
5. Add and harden the A-inverse phylogenetic path for intercept-only
   univariate Gaussian `mu`.
6. Add SPDE spatial fields.
7. Combine bivariate `rho12` with phylogenetic or spatial structure only after
   simpler pieces pass recovery tests.
