# Phylogenetic and Spatial Common Math

This note records the shared mathematical spine for future phylogenetic and
spatial models in `drmTMB`. It is based on the local tutorial:

```text
/Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf
```

The key design decision is that phylogenetic and spatial dependence should not
be implemented as unrelated special cases. They are both structured Gaussian
random effects attached to one distributional parameter.

## One Structured-Effect Template

For any distributional parameter with linear predictor `eta_d`, write:

```text
eta_d = X_d beta_d + Z_d z
z ~ MVN(0, sigma_z^2 K)
```

where:

- `d` is a distributional parameter such as `mu`, `sigma`, `nu`, or later
  `rho12`;
- `X_d beta_d` is the fixed-effect part for that parameter;
- `Z_d z` maps the structured latent effect to observations;
- `K` is a known or constructed correlation/covariance matrix;
- `sigma_z` is the unknown marginal SD for that structured effect.

The same template gives:

```text
phylogenetic effect: z_phylo ~ MVN(0, sigma_phylo^2 A)
spatial effect:      z_space ~ MVN(0, sigma_space^2 M)
```

Here `A` is a phylogenetic correlation matrix derived from a tree, and `M` is a
spatial correlation matrix derived from geographic distances or a spatial
kernel.

## Distance To Correlation

The tutorial emphasizes that phylogenetic and spatial models differ mainly in
what distance means.

```text
phylogenetic distance: evolutionary separation or shared ancestry
spatial distance:      geographic separation
```

Both are converted to correlation through a kernel or evolutionary model:

| Dependence type | Common structure | Correlation form |
| --- | --- | --- |
| Phylogenetic Brownian motion | analogous to linear spatial decay | shared history, or linear decline on ultrametric trees |
| Spatial linear kernel | analogous to Brownian motion | `C(d) = max(0, 1 - d / range)` |
| Phylogenetic OU | analogous to exponential spatial decay | `C(t) = exp(-alpha * t)` |
| Spatial exponential kernel | analogous to OU | `C(d) = exp(-d / range)` |
| Spatial squared exponential | mainly spatial | `C(d) = exp(-d^2 / range^2)` |

For OU and exponential spatial models, the correspondence is:

```text
alpha = 1 / range
```

This matters for `drmTMB` because users should be able to learn one conceptual
grammar: define distance, choose a correlation model, then attach the resulting
structured effect to a distributional parameter.

## Precision-Matrix Computation

Dense covariance notation is useful for teaching, but TMB implementation should
prefer sparse precision whenever possible:

```text
z ~ MVN(0, sigma_z^2 K)
Q_z = K^{-1} / sigma_z^2
```

For phylogeny, the speed path is the A-inverse trick: build or accept a sparse
precision matrix proportional to `A^{-1}` and evaluate the Gaussian prior as a
sparse quadratic form.

For spatial dependence, the speed path is the SPDE/GMRF approximation: build a
sparse precision matrix from a mesh and spatial parameters rather than forming
a dense Gaussian-process covariance matrix.

So the implementation abstraction should be:

```text
structured_effect(
  term = "phylo" or "spatial",
  dpar = "mu" or "sigma" or later "rho12",
  Z = incidence or projection matrix,
  Q = sparse precision matrix,
  log_sd = unconstrained scale parameter
)
```

The public syntax can differ:

```r
phylo(1 | species, tree = tree)
spatial(1 | site, coords = coords)
```

but the TMB likelihood should see the same kind of structured-effect block.

The mature phylogenetic grammar should probably look like structured
random-effect syntax rather than a bare marker:

```r
phylo(1 | species, tree = tree)
phylo(1 + x | species, tree = tree)
```

Here `phylo(1 | species, tree = tree)` is a phylogenetic random intercept and
`phylo(1 + x | species, tree = tree)` is a phylogenetic random intercept plus a
phylogenetic random slope. Public `phylo()` should require an ultrametric tree
with branch lengths. Dense covariance matrices should be reserved for
lower-level structured-covariance or comparator pathways, not the main
phylogeny API.

The first parser should validate:

```text
tree has branch lengths
tree is ultrametric, within numerical tolerance
all observed species are represented by tree tip labels
species levels and tree tip labels can be matched unambiguously
```

The first internal validation scaffold now checks those conditions for a small
`phylo` object and can also build a dense Brownian-motion comparator for tests.
For a rooted ultrametric tree, let `d(v)` be the distance from the root to node
`v`, and let `mrca(a, b)` be the most recent common ancestor of tips `a` and
`b`. The Brownian shared-history covariance is:

```text
A_ab = d(mrca(a, b))
```

If the tree height is `H`, the corresponding correlation matrix is:

```text
R_ab = A_ab / H
```

This dense matrix is useful for exact tests on tiny trees and for teaching why
branch lengths matter. It is not the intended large-tree fitting path.

The second internal scaffold builds the sparse augmented precision that should
eventually feed the TMB likelihood. The root is fixed at zero and excluded from
the latent state. For every edge from parent `p` to child `c` with branch length
`l`, the Brownian increment contributes:

```text
(x_c - x_p)^2 / l
```

If `p` is not the root, this adds:

```text
Q_cc = Q_cc + 1 / l
Q_pp = Q_pp + 1 / l
Q_cp = Q_cp - 1 / l
Q_pc = Q_pc - 1 / l
```

If `p` is the root, `x_p = 0`, so only `Q_cc = Q_cc + 1 / l` is added. On the
correlation scale used by `z ~ MVN(0, sigma_phylo^2 A)`, the precision is:

```text
Q_A = H Q_raw
```

where `H` is the ultrametric tree height. Solving the augmented precision and
then selecting the tip rows gives the same dense tip matrix as the Brownian
comparator:

```text
solve(Q_A)[tips, tips] = R
```

For a structured-effect SD `sigma_phylo = exp(log_sd)`, the Gaussian prior
contribution for augmented latent vector `z` is:

```text
nll_phylo =
  0.5 * [
    n log(2 pi)
    + 2 n log_sd
    - logdet(Q_A)
    + exp(-2 log_sd) z' Q_A z
  ]
```

This is still internal algebra, not fitted model support. The next C++/TMB
block should reproduce this expression exactly. A hidden TMB test branch now
does this for parity testing only; it is not routed through `drmTMB()` model
fitting.

Accepted public forms:

```r
phylo(1 | species, tree = tree)         # build sparse A-inverse internally
phylo(1 + x | species, tree = tree)     # later structured slope path
```

The preferred tree path should follow the Hadfield and Nakagawa comparative
mixed-model construction: expand the phylogenetic covariance to include
internal nodes, form the sparse inverse of the expanded relationship matrix,
and treat ancestral states as latent Gaussian effects. The implementation can
then map the tip-level species effects to observations while evaluating the
prior with the sparse augmented precision. Dense tip-only covariance is useful
for teaching, small comparators, and fallback inputs, but it should not be the
large-tree computational path.

The same idea can later extend to spatial terms, but the first spatial
implementation should use mesh/projection objects rather than dense distance
matrices.

The spatial grammar should mirror the phylogenetic grammar:

```r
spatial(1 | site, coords = coords)
spatial(1 + depth | site, coords = coords)
spatial(1 | site, mesh = mesh)
```

Here `spatial(1 | site, coords = coords)` is a spatial random intercept.
`coords` supplies observed coordinates that the R layer can use to build or
validate a mesh/projection object. `mesh = mesh` is the planned route for users
who have already built an SPDE mesh. Structured spatial slopes should come
after intercept-only spatial fields are tested.

The sibling `gllvmTMB` implementation already follows this broad idea. The
files to study when implementation begins are:

- `../gllvmTMB/R/fit-multi.R` for R-side phylogenetic VCV, A-inverse, SPDE,
  TMB-input, and parameter-map preparation;
- `../gllvmTMB/inst/tmb/gllvmTMB_multi.cpp` for sparse phylogenetic penalties
  and SPDE precision blocks;
- `../gllvmTMB/R/mesh.R` and `../gllvmTMB/R/spde-keyword.R` for mesh helpers
  and Matérn/SPDE documentation;
- `../gllvmTMB/tests/testthat/test-phylo-hadfield.R` for sparse-versus-dense
  phylogenetic validation;
- `../gllvmTMB/tests/testthat/test-stage4-spde.R` for early SPDE tests.

Those sources should be used as a design and validation map, not as a reason to
import high-dimensional GLLVM assumptions into `drmTMB`.

## Meta-Analysis As The First Teaching Bridge

Meta-analysis makes the analogy especially clear because sampling error is also
known structure:

```text
y_i = eta_mu_i + u_study[j[i]] + s_i + e_i
e_i ~ Normal(0, v_i)
```

Phylogenetic meta-analysis adds:

```text
p_species ~ MVN(0, sigma_phylo^2 A)
q_species ~ MVN(0, sigma_species^2 I)
```

Spatial meta-analysis adds:

```text
l_location ~ MVN(0, sigma_space^2 M)
m_location ~ MVN(0, sigma_location^2 I)
```

The structured component (`A` or `M`) and the unstructured component (`I`) are
often both scientifically important. The tutorial warns that omitting the
unstructured species/location component can distort variance partitioning when
unstructured heterogeneity exists.

In `drmTMB`, the syntax should keep meta-analysis as Gaussian regression with
known sampling covariance:

```r
drmTMB(
  formula = drm_formula(
    mu = yi ~ x1 + meta_known_V(V = V) +
      phylo(1 | species, tree = tree) + (1 | study),
    sigma = ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

This is partly implemented. Current code supports dense known sampling
covariance through `meta_known_V(V = V)`, univariate Gaussian `mu` random
intercepts, independent numeric `mu` random slopes, one-slope correlated `mu`
blocks, and univariate Gaussian residual-scale random intercepts in `sigma`.
`phylo()` and `spatial()` structured-effect terms are still planned.

## Identifiability Rule

Every structured random effect adds a variance component and a correlation
structure. The model is only useful if the data can distinguish those
components from each other.

High-risk cases include:

- study, species, location, and effect-size IDs are nearly one-to-one;
- most species or locations have one effect size;
- spatial locations are all extremely close or all extremely far apart;
- phylogenetic and non-phylogenetic species effects are included with very weak
  replication;
- structured effects are added simultaneously to `mu`, `sigma`, and `rho12`
  before simpler components have been validated.

The package should therefore implement `check_drm()` diagnostics before complex
phylogenetic or spatial models are advertised as routine. These checks should
summarize replication by grouping level, matrix rank/conditioning, and whether
structured and unstructured effects are plausibly separable.

## Structured Slopes

Phylogenetic and spatial random slopes are mathematically natural but should be
introduced more slowly than ordinary grouped random slopes. The shared symbolic
form is:

```text
z_s ~ MVN(0, sigma_slope^2 K)
mu_i = X_mu[i, ] beta_mu + x_i z_s[index_i]
```

where `K` is a phylogenetic relationship matrix, a spatial covariance matrix,
or an implicit SPDE covariance. Each additional structured slope adds another
latent vector or field, and possibly cross-covariances with intercept fields in
later models.

Recommended staging:

- implement intercept-only structured effects first;
- then one structured slope in `mu`;
- delay interaction slopes until simulation studies show reliable recovery;
- delay structured slopes in `sigma` and `rho12` until the location model is
  stable;
- warn when the number of structured slopes is large relative to species,
  location, study, or within-group replication.

## Boundary With rho12

`rho12` is residual response-response correlation at the observation level:

```text
atanh(rho12_i) = X_rho12[i, ] beta_rho12
```

Phylogenetic and spatial correlation matrices describe dependence among
species, locations, studies, or latent fields. They do not replace residual
`rho12`.

In bivariate phylogenetic or spatial models, there may eventually be many
correlations:

- residual correlation `rho12`;
- phylogenetic mean-mean correlations;
- non-phylogenetic species or group-level mean-mean correlations;
- structured or unstructured scale-scale correlations;
- structured or unstructured mean-scale correlations;
- study, site, population, observer, or other grouped random-effect
  correlations;
- phylogenetic or spatial structured covariance among response-specific random
  effects.

The naming system should keep these separate. `rho12` should remain reserved
for residual response coupling unless a suffix explicitly names another level.
Future extractors should therefore use level-specific containers such as
`corpars$phylo`, `corpars$species`, `corpars$spatial`, or labelled group-level
blocks, rather than treating every cross-response correlation as residual
`rho12`.

## Implementation Order

1. Keep the current Gaussian location-scale and bivariate `rho12` MVP stable.
2. Extend `meta_known_V(V = V)` from dense known covariance to sparse storage.
3. Add one structured `mu` effect using a supplied sparse precision matrix.
4. Wrap that path as `phylo(1 | species, tree = tree)` using the Hadfield and
   Nakagawa A-inverse tree path.
5. Add spatial SPDE fields using the same structured-effect TMB block.
6. Only then allow structured effects in `sigma`.
7. Treat structured effects in `rho12` as experimental until simulation
   evidence shows identifiability.

## Next Implementation Gate

The next useful slice is deliberately small:

```r
drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = gaussian(),
  data = dat
)
```

Symbolically:

```text
y_i | a_species[i] ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 x_i + a_species[i]
log(sigma_i) = gamma_0 + gamma_1 z_i
a ~ MVN(0, sigma_phylo^2 A)
```

Computationally, the first tree-backed version should be equivalent to:

```text
a_aug ~ MVN(0, sigma_phylo^2 S)
Q_aug = S^{-1} / sigma_phylo^2
a_species = P_tip a_aug
```

where `S` is the expanded phylogenetic relationship matrix including internal
nodes, `Q_aug` is sparse, and `P_tip` selects or maps the observed tip species.
For internal comparator tests, the same model can be validated against a dense
tip covariance implied by the tree on small examples. That dense matrix should
not be the main public input for `phylo()`.

The first implementation should attach the structured effect only to
univariate Gaussian `mu`. It should not yet add bivariate covariance, structured
scale effects, structured `rho12`, or random slopes.

Testing should be staged:

- parser tests for `phylo(1 | species, tree = tree)` in `mu` and clear
  rejection in unsupported parameters such as `sigma` and `rho12`;
- deterministic algebra tests comparing sparse A-inverse prior calculations
  with a small dense covariance calculation;
- one CRAN-safe simulation recovery test with a hand-built positive-definite
  phylogenetic correlation matrix;
- optional long simulations for many species, near-zero phylogenetic SD,
  large residual noise, and simultaneous phylogenetic plus non-phylogenetic
  species effects.

The sibling `gllvmTMB` source map supports this order. Use it for design
lessons: tree input should prefer a sparse A-inverse path, dense VCV should be
a compatibility fallback, and SPDE should enter later through mesh/projection
objects. Do not import the high-dimensional GLLVM keyword grid or loading
machinery into this one- and two-response package.
