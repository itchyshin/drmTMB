# Phylogenetic and Spatial Speed Plan

> **Status supersession (2026-07-14).** This document preserves a historical
> planning state. Any statement below that residual-scale structured slopes are
> wholly planned is superseded. Current 0.6.0 fits the exact Gaussian q1
> `sigma` one-slope routes for `phylo()`, `spatial()`, `animal()`, and
> `relmat()`; phylo, A-matrix animal, and K/Q relmat are inference-ready with
> caveats, while spatial remains point-fit/extractor only. NB2 q1 structured
> `sigma` intercept-plus-one-slope routes for the same four providers are also
> fitted at recovery grade. Multiple or labelled structured sigma slopes,
> spatial sigma-slope intervals, and broader non-Gaussian structured scale
> routes remain planned.


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
- use `relmat()` for lower-level known-relatedness matrices instead of reviving
  the deprecated `gr()` marker;
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
rho12_i = tanh(eta_rho12_i)
```

The current C++ bivariate Gaussian implementation uses a tiny internal boundary
guard around the hyperbolic-tangent transform so covariance matrices remain
strictly positive definite during optimization. User-facing mathematical
equations should show the clean statistical transform above and explain the
guard separately when implementation details matter.

This turns covariance homogeneity into a testable biological assumption.
For example, the body mass-litter size relationship in mammals can be asked at
three levels: phylogenetic correlation, non-phylogenetic among-species
correlation, and residual coscale `rho12 ~ lifestyle`.

The q=4 phylogenetic endpoint path evaluates the matrix-normal prior for
augmented phylogenetic effects across `mu1`, `mu2`, `sigma1`, and `sigma2` using
the existing sparse tree precision and a small dense Kronecker comparator in
tests. The first public fitted path now accepts matching labelled all-four
`phylo()` terms, reports the `mean-mean`, four `mean-scale`, and `scale-scale`
phylogenetic endpoint rows through `corpairs()`, and keeps these latent
correlations separate from residual `rho12`.

### Sparse Phylogenetic Source Map

The sparse phylogenetic route is no longer a blank implementation task.
`drmTMB` already builds an augmented Brownian-motion precision in
`R/phylo-utils.R` with `drm_phylo_augmented_precision()`, passes it to TMB as
`Q_phylo` through `make_tmb_data()`, and declares it in `src/drmTMB.cpp` as
`DATA_SPARSE_MATRIX(Q_phylo)`. The TMB likelihood branches then evaluate
quadratic forms such as `u' Q_phylo u` and use `log_det_Q_phylo` for Gaussian,
ordinary Poisson, ordinary NB2, and bivariate Gaussian structured-effect paths.
Tiny dense Brownian covariance matrices remain comparators in tests and teaching
docs; they are not the fitted large-tree path.

This matters for the GLLVM.jl transfer audit because the portable lesson is not
"add sparse phylogeny from scratch." The issue #431 benchmark and API gate now
documents the current tree-only contract and keeps future `phylo(A = ...)` or
`phylo(Ainv = ...)` routes out of `phylo()` unless a later design task reopens
the question. Do not add a `phylo_representation` switch, dense fallback, or new
matrix input until that later gate specifies scale, labels, diagnostics,
`profile_targets()`, `check_drm()`, validation evidence, and any copied-code
provenance in `inst/COPYRIGHTS`.

The 2026-05-30 issue #431 gate keeps the user-facing `phylo()` API tree-only
for now. Local smoke and row-pressure benchmarks show that the current sparse
tree path runs for the Gaussian location model at 100,000 rows and 1,000 species
on the macOS development machine. That row-pressure evidence covers the
benchmarked Gaussian mean-response path only; it does not extend the same scale
claim to every implemented likelihood branch. It also does not justify a
dense/sparse switch, `phylo(A = ...)`, `phylo(Ainv = ...)`, or a new
matrix-input route. Known precision or relationship-matrix inputs should
continue to route through `relmat()` unless a later design task reopens the API
question with labels, diagnostics, profile targets, and validation evidence.

Current local evidence:

| Surface | Current source | What it proves |
| --- | --- | --- |
| Tree validation and Brownian comparator | `R/phylo-utils.R` functions `validate_phylo_tree()` and `drm_phylo_tip_covariance()` | `phylo()` requires an ultrametric tree with branch lengths, can match observed species to tips, and can build a dense tip-level comparator for tiny tests. |
| Sparse augmented precision | `R/phylo-utils.R` function `drm_phylo_augmented_precision()` | The root is excluded, every non-root node enters the latent state, and branch increments contribute a sparse precision scaled to the Brownian correlation matrix. |
| TMB data contract | `R/drmTMB.R` functions `build_structured_mu_structure()` and `make_tmb_data()` | Structured terms hand TMB a sparse `Q_phylo`, `log_det_Q_phylo`, node indices, design values, endpoint labels, and block metadata. |
| TMB likelihood use | `src/drmTMB.cpp` `DATA_SPARSE_MATRIX(Q_phylo)` and the `has_phylo_mu` branches | Fitted phylogenetic effects use sparse matrix-vector products and log determinants for the structured Gaussian prior. |
| Dense parity checks | `tests/testthat/test-phylo-utils.R` and `tests/testthat/test-phylo-gaussian.R` | The augmented precision matches dense Brownian covariance on tiny trees, and fitted objectives match dense marginal likelihood comparators for selected Gaussian cases. |

GLLVM.jl and `gllvmTMB` remain useful for benchmarking and staged validation,
but they should be read as sister-package evidence, not as proof that `drmTMB`
needs to rewrite the implemented sparse precision path. Specific files to study:

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

First fitted coordinate syntax:

```r
bf(
  y ~ depth + temp + spatial(1 | site, coords = coords),
  sigma ~ temp
)
```

`coords` and `mesh` should be treated as two entry points to the same spatial
field, not as two biological model types. The first fitted coordinate path uses
pairwise site distances to build a fixed exponential covariance, then inverts
that covariance to a precision matrix. `mesh` remains the scalable SPDE/GMRF
path: it supplies an already-built finite-element scaffold plus projection
information needed to map mesh vertices back to observations. In both cases,
the fitted quantity is a structured spatial random effect; the mesh itself is a
computational support, not a response, predictor, or sampling level to
interpret biologically.

Mesh is therefore not required by the scientific idea of spatial dependence.
It is required by the scalable SPDE/GMRF approximation. The current
coordinate-covariance implementation is a small-data foundation and recovery
target; it forms dense matrices before converting to a precision and does not
yet share the large-data path with future sparse mesh work. The default user
experience should remain `coords = coords`; the R layer can later build or
validate a mesh-like object internally. The explicit `mesh = mesh` form is for
users who need reproducible control over boundaries, coastlines, barriers, or
highly uneven sampling.

Planned mesh-explicit syntax:

```r
bf(
  y ~ depth + temp + spatial(1 | site, mesh = mesh),
  sigma ~ temp
)
```

### Mesh/SPDE Implementation Gate

Do not turn `mesh = mesh` into fitted syntax until the mesh object contract is
explicit. The first acceptable contract should name:

- the mesh vertices and triangle topology;
- the observation-to-mesh projection matrix or enough information to build it;
- the spatial precision recipe, either a ready sparse precision matrix or the
  Matérn/SPDE ingredients needed to construct one;
- the coordinate reference system or a clear statement that coordinates are
  already projected into a distance-preserving working scale;
- the mapping from data rows to site levels and from site levels to projected
  mesh rows;
- the fitted parameters that belong to the spatial field, starting with one
  field SD and only then adding range, anisotropy, barriers, or replicate
  fields.

The first mesh implementation should still fit only a univariate Gaussian `mu`
random intercept. That keeps the comparator close to the current
`coords = coords` path: both estimate one structured spatial SD, but the mesh
route should use a sparse SPDE/GMRF precision and a projection matrix rather
than a dense coordinate covariance. Mesh-based residual-scale slopes,
direct-SD models, spatial `corpair()` regressions, and non-Gaussian mesh routes
should wait until the mesh intercept has recovery evidence and diagnostics.
That mesh boundary does not erase the exact fitted coordinate-covariance gates:
ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope, recovery-grade
NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial `zi`,
fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu`.

Dependency and citation decisions are part of the gate. If `drmTMB` accepts
`fmesher` objects or uses `fmesher` to build meshes, the package website,
article, and manuscript should tell users to cite `fmesher` in addition to the
SPDE method literature and `sdmTMB` precedent. If `fmesher` is optional, start
with `Suggests` and clear errors when it is missing; do not make it a hard
dependency until ordinary coordinate users need it. If any mesh helper, SPDE
matrix builder, projection code, or test fixture is copied or closely adapted
from another package, the same slice must update `inst/COPYRIGHTS`.

Grace's minimum check gate for `mesh = mesh` is:

- parser tests that unsupported mesh shapes fail with actionable messages;
- a sparse-vs-dense or small-mesh comparator for one `mu` field;
- a CRAN-safe recovery smoke test for the spatial SD;
- `ranef()`, `sdpars`, `profile_targets()`, and `check_drm()` rows that use
  spatial names, not phylogenetic names;
- pkgdown documentation that separates `coords`, mesh, residual `rho12`, and
  future spatial correlations.

The first coordinate spatial random slope follows the same coordinate-covariance
pattern:

```r
bf(
  y ~ depth + temp + spatial(1 + depth | site, coords = coords),
  sigma ~ temp
)
```

This fitted path estimates two independent spatial fields with the same
coordinate precision: `spatial(1 | site)` for site intercept deviations and
`spatial(0 + depth | site)` for site-specific depth slopes. It deliberately does
not estimate an intercept-slope correlation. Mesh/SPDE slopes should wait until
the mesh intercept path has its own recovery and diagnostics.

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

### Spatial Citation And Provenance Policy

If the first spatial implementation only follows the published SPDE/GMRF idea,
the user-facing docs should cite the methodological and software sources that
made the route practical. At minimum, cite Lindgren, Rue, and Lindstrom (2011)
for the SPDE link between Gaussian fields and GMRFs
(`doi:10.1111/j.1467-9868.2011.00777.x`), and cite the `sdmTMB`
[Journal of Statistical Software paper](https://www.jstatsoft.org/article/view/v115i02)
when explaining the ecological TMB-plus-SPDE precedent. If `drmTMB` asks users
to pass meshes or if it imports `fmesher`, also cite `fmesher` as software and
ask users to cite it via `citation("fmesher")`.

Citation and provenance have different jobs. Citations acknowledge method and
software debts. `inst/COPYRIGHTS` records copied or closely adapted code. If a
future slice ports mesh helpers, SPDE matrix construction, TMB template code, or
test fixtures from `sdmTMB`, `fmesher`, `INLA`, `gllvmTMB`, or another project,
the slice is not complete until `inst/COPYRIGHTS` names the source file, license,
and adaptation. If the implementation only uses the same published mathematical
idea and independent code, record citations in docs but do not imply code was
ported.

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
observation level, whereas A-inverse and SPDE terms model structural dependence
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

Multiple random factors are not unusual and should not be treated as a
scientific error. The conservative rule is to keep them as separate additive
blocks. For example, an ordinary individual block, a phylogenetic species block,
and a later spatial site block can coexist, but `drmTMB` should not collapse
them into one giant covariance matrix or estimate cross-factor `corpair()` rows
before the simpler block-specific models are stable.

Implementation has followed this order:

1. fit intercept-only phylogenetic and spatial structured effects in `mu`;
2. add one structured random slope in Gaussian `mu`, with focused recovery and
   diagnostics;
3. keep multiple structured `mu` slopes as an advanced planned path until
   diagnostics show enough replication and design variation;
4. treat interaction slopes as experimental design work with explicit warnings;
5. keep structured slopes in `sigma` or `rho12` behind separate design and
   recovery gates.

The number of possible slopes is not a hard mathematical limit, but the package
should impose conservative defaults and diagnostics. Three or more structured
slopes should remain a distant-future expert mode, not a near-term advertised
feature.

Slice 186 records the original parity audit. Coordinate spatial first completed
step 2 for one univariate Gaussian `mu` slope through
`spatial(1 + x | site, coords = coords)`, using independent intercept and
slope fields. Slice 39 of the post-0.1.3 parity lane then brought phylogeny to
the same first fitted one-slope contract through
`phylo(1 + x | species, tree = tree)`, with separate intercept-field and
slope-field SDs, direct profile targets, `ranef()` terms, and
`check_drm()` diagnostics. Multiple phylogenetic slopes and phylogenetic
slope correlations remain planned.

Slice 187 then rechecked the spatial side of that boundary. The fitted
coordinate-spatial slope SD is a direct profile target, including the
`spatial(0 + x | site)` slope-field SD. The later q=2 bivariate spatial slice
adds matching `mu1`/`mu2` coordinate-spatial intercept fields, and the later
constant q=4 slice adds all-four location-scale spatial intercepts, but neither
widens Gaussian slope covariance support: multiple or labelled spatial slopes,
mesh/SPDE slopes, and spatial slope correlations remain planned. Non-Gaussian
spatial effects outside the exact ordinary Poisson/NB2 q1 spatial `mu`
intercept-plus-one-slope, recovery-grade NB2 q1 spatial `sigma`, Student-t
spatial `mu`, Poisson spatial `zi`, fixed-`zi` Poisson spatial `mu`, and
fixed-`zi` NB2 spatial `mu` gates also
remain planned.

The first slope implementation should not estimate intercept-slope or
slope-slope correlations. Those correlations multiply quickly and are usually
less interpretable than the main structured location effect. A scientifically
interesting later exception is the bivariate slope1-slope2 correlation for the
same covariate across two responses, the kind of plasticity-syndrome question
discussed by O'Dea, Noble, and Nakagawa (2021). That future model would require a
coefficient-aware `corpair()` design, clear `corpairs()` labels, and recovery
tests before it is documented as fitted support.

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
