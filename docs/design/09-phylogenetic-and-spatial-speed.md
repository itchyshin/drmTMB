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

## Phylogenetic Dependence

Primary speed path:

- use the A-inverse trick for phylogenetic random effects;
- prefer sparse precision matrices when available;
- keep `gr()` as the low-level known-covariance term;
- expose `phylo(species)` as the high-level user-facing term.

Planned syntax:

```r
bf(
  y ~ x + phylo(species),
  sigma ~ x
)
```

and later:

```r
bf(
  mu1 = y1 ~ x + phylo(species),
  mu2 = y2 ~ x + phylo(species),
  sigma1 = ~ x,
  sigma2 = ~ x,
  rho12 = ~ x
)
```

### gllvmTMB Source Map

The first implementation should borrow concepts from `gllvmTMB`, not import
high-dimensional GLLVM API assumptions. Specific sister-package files to study:

| Purpose | gllvmTMB source | drmTMB translation |
| --- | --- | --- |
| Sparse phylogenetic A-inverse setup | `../gllvmTMB/R/fit-multi.R` around the `Ainv_phy_rr` construction | Build a small univariate `phylo(species)` data-preparation path first. |
| Sparse A-inverse TMB data contract | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` A-inverse data declarations | Define minimal sparse precision inputs for one random-effect term before bivariate use. |
| Sparse phylogenetic prior | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` sparse quadratic-form prior | Add a tested GMRF/prior block that can attach to `mu`, later `sigma`. |
| Phylogenetic tests | `../gllvmTMB/tests/testthat/test-phylo-hadfield.R` | Use sparse-vs-dense equivalence and parameter-recovery tests. |

## Spatial Dependence

Primary speed path:

- use SPDE/GMRF sparse precision structures;
- keep spatial fields modular so they can be added to `mu`, and later to
  `sigma` when identifiable;
- use `spatial()` as the user-facing placeholder.

Planned syntax:

```r
bf(
  y ~ depth + temp + spatial(x, y),
  sigma ~ temp
)
```

### gllvmTMB SPDE Source Map

| Purpose | gllvmTMB source | drmTMB translation |
| --- | --- | --- |
| Mesh construction | `../gllvmTMB/R/mesh.R` | Provide a small mesh helper or accept a prepared mesh object. |
| Mesh validation and TMB data | `../gllvmTMB/R/fit-multi.R` spatial mesh validation and data passing | Start with one location-field term for one response. |
| SPDE precision | `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` SPDE data contract and `Q_base` construction | Build a focused SPDE module before allowing scale fields. |
| SPDE tests | `../gllvmTMB/tests/testthat/test-stage4-spde.R` and `../gllvmTMB/tests/testthat/test-spatial-latent-recovery.R` | Use recovery tests for location fields before adding bivariate or scale models. |

Residual `rho12` remains conceptually separate from phylogenetic or spatial
correlation: `rho12 ~ predictors` models residual response coupling at the
observation level, whereas A-inverse and SPDE terms model structured dependence
among units or locations.

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
4. Add diagonal known covariance for meta-analysis.
5. Add sparse known covariance and A-inverse phylogenetic path.
6. Add SPDE spatial fields.
7. Combine bivariate `rho12` with phylogenetic or spatial structure only after
   simpler pieces pass recovery tests.
