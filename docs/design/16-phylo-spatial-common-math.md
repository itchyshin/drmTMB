# Phylogenetic, Spatial, and Known-Relatedness Common Math

This note records the shared mathematical spine for phylogenetic, spatial,
animal-model, and user-supplied relatedness models in `drmTMB`. The
phylogenetic and spatial sections are based on the local tutorial:

```text
/Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf
```

The key design decision is that phylogenetic, spatial, animal-model, and
generic known-relatedness dependence should not be implemented as unrelated
special cases. They are structured Gaussian random effects attached to one
distributional parameter, with different sources for the known covariance or
precision matrix.

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
phylogenetic effect:      z_phylo  ~ MVN(0, sigma_phylo^2 A_phylo)
spatial effect:           z_space  ~ MVN(0, sigma_space^2 M)
animal-model effect:      z_animal ~ MVN(0, sigma_animal^2 A_ped)
user-relatedness effect:  z_rel    ~ MVN(0, sigma_rel^2 K_user)
```

Here `A_phylo` is a phylogenetic relatedness matrix derived from a tree or
supplied by the user, `M` is a spatial correlation matrix derived from
geographic distances or a spatial kernel, `A_ped` is additive pedigree
relatedness, and `K_user` is a validated user-supplied relatedness matrix.

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
  term = "animal" or "phylo" or "spatial" or "relmat",
  dpar = "mu" or "sigma" or later "rho12",
  Z = incidence or projection matrix,
  Q = sparse precision matrix,
  log_sd = unconstrained scale parameter
)
```

The public syntax can differ:

```r
animal(1 | id, pedigree = ped)
animal(1 | id, Ainv = Ainv_ped)
phylo(1 | species, tree = tree)
phylo(1 | species, A = A_phylo)
spatial(1 | site, coords = coords)
relmat(1 | id, K = K_user)
```

but the TMB likelihood should see the same kind of structured-effect block.
The documentation should lead with the scientific source of dependence:
pedigree or additive relatedness for `animal()`, shared evolutionary history
for `phylo()`, coordinates or meshes for `spatial()`, combined structural
layers when the question needs more than one source, and `relmat()` only when
the user already has a validated known-dependence matrix. The first fitted
phylogenetic instance is univariate Gaussian `mu` with
`phylo(1 | species, tree = tree)`. The first fitted spatial instances are
univariate Gaussian `mu` with `spatial(1 | site, coords = coords)` and one
numeric `spatial(1 + x | site, coords = coords)` slope, using a fixed
coordinate covariance as the small-data foundation before the scalable
mesh/SPDE route.

The mature phylogenetic grammar should probably look like structured
random-effect syntax rather than a bare marker:

```r
phylo(1 | species, tree = tree)
phylo(1 + x | species, tree = tree)
```

Here `phylo(1 | species, tree = tree)` is a phylogenetic random intercept and
`phylo(1 + x | species, tree = tree)` is a phylogenetic random intercept plus a
phylogenetic random slope. The implemented public `phylo()` path still requires
an ultrametric tree with branch lengths. A later matrix-input route can accept
`A` or `Ainv` from users who already have a validated phylogenetic relatedness
matrix or precision matrix. Aliases such as `vcv` or `corr` should only be
added if the scale contract is explicit; silent conversion between covariance,
correlation, and precision would make variance-component interpretation
fragile.

## Animal Models and User-Supplied Relatedness

Animal models use the same structured-effect template as phylogenetic mixed
models. The difference is the biological source of `K`: a pedigree or additive
relationship matrix rather than an evolutionary tree. This mirrors the
[MCMCglmm course-note framing](https://jarrodhadfield.github.io/MCMCglmm/course-notes/pedigree.html),
where pedigrees, phylogenies, and user-defined covariance structures are
treated as known structures that define correlations among random effects.

The public grammar should keep that biological source visible:

```r
animal(1 | id, pedigree = ped)
animal(1 | id, A = A_ped)
animal(1 | id, Ainv = Ainv_ped)
```

The lower-level escape hatch, if added, should avoid a vague name such as
`user()`. A name such as `relmat()` keeps the object of inference visible and
is clearer than teaching both `relmat()` and the older reserved `gr()` wording:

```r
relmat(1 | id, K = K_user)
relmat(1 | id, Q = Q_user)
```

These inputs are relatedness or precision matrices for latent random effects.
They are not known sampling covariances. Keep `V` reserved for the preferred
`meta_V(..., V = V)` design, where the matrix describes sampling error in
observations or effect-size estimates.

The first reader-facing animal-model examples should be ecological and
evolutionary, not matrix demonstrations. Good targets are:

- heritable trait means in a wild pedigree, such as body size, tarsus length,
  arrival date, or breeding timing;
- additive genetic variance in behavioural predictability or residual scale,
  connecting animal models to location-scale individual-difference questions;
- bivariate additive genetic covariance between two traits, with a clear
  link to evolvability, genetic correlation, or a simple G-matrix
  interpretation.

These examples should still respect `drmTMB` scope. The first tutorial should
not imply a full quantitative-genetics platform with dominance, maternal
effects, permanent environment, arbitrary multivariate responses, or breeding
programme workflows. It should show how a univariate or bivariate
distributional-regression model can attach one known additive relationship
structure to the fitted random-effect layer.

The first parser should validate:

```text
tree has branch lengths
tree is ultrametric, within numerical tolerance
all observed species are represented by tree tip labels
species levels and tree tip labels can be matched unambiguously
```

The internal validation scaffold checks those conditions for `phylo` objects
and can also build a dense Brownian-motion comparator for tests.
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

The sparse implementation builds the augmented precision that feeds the TMB
likelihood for the first fitted phylogenetic location model. The root is fixed
at zero and excluded from the latent state. For every edge from parent `p` to
child `c` with branch length `l`, the Brownian increment contributes:

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

The hidden TMB parity branch and the fitted univariate Gaussian `mu`
phylogenetic path both reproduce this expression. In the fitted path,
observation `i` receives the tip effect selected by the species mapping:

```text
eta_mu_i = X_mu[i, ] beta_mu + z_tip[species_i]
```

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

The same idea now extends to the first spatial term through a coordinate-based
foundation. This is intentionally narrower than the final mesh/projection
SPDE/GMRF route: it is a small-data implementation and recovery target that
keeps the public `spatial(1 | site, coords = coords)` API real while preserving
mesh work for the scalable path.

The spatial grammar should mirror the phylogenetic grammar:

```r
spatial(1 | site, coords = coords)
spatial(1 + depth | site, coords = coords)
spatial(1 | site, mesh = mesh)
```

Here `spatial(1 | site, coords = coords)` is a fitted spatial random intercept
for univariate Gaussian `mu`. `spatial(1 + depth | site, coords = coords)` is
also fitted for one numeric `mu` slope by estimating independent intercept and
slope fields with the same coordinate precision. `coords` supplies observed
coordinates with one row per site or one row per observation. `mesh = mesh` is
the planned route for users who have already built an SPDE mesh. Multiple
spatial slopes and spatial slope correlations remain planned.

The mesh is not the ecological object of inference. It is a numerical scaffold
for the sparse SPDE/GMRF approximation. The current coordinate covariance path
uses `coords` without a mesh and should be treated as a small-data foundation
rather than the main scalable path. The public API should therefore make
coordinates easy for ordinary users while preserving `mesh = mesh` for advanced
users who need control over boundaries, barriers, or reproducibility.

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
    mu = yi ~ x1 + meta_V(V = V) +
      phylo(1 | species, tree = tree) + (1 | study),
    sigma = ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

This is partly implemented. Current code supports dense known sampling
covariance through `meta_known_V(V = V)`; the preferred roadmap spelling is
`meta_V(V = V)` once the alias/rename slice is implemented. Current code also
supports univariate Gaussian `mu` random intercepts, independent numeric `mu`
random slopes, one-slope correlated `mu` blocks, univariate Gaussian
residual-scale random intercepts and independent random slopes in `sigma`, and
intercept-only `phylo(1 | species, tree = tree)` in `mu`. The
coordinate-spatial foundation now also fits
`spatial(1 | site, coords = coords)` and one numeric
`spatial(1 + x | site, coords = coords)` slope in univariate Gaussian `mu`.
Mesh/SPDE spatial fields, multiple spatial slopes, spatial slope correlations,
phylogenetic slopes, and phylogenetic or spatial effects in `sigma` are still
planned.

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

Current first-pass `check_drm()` support covers optimizer convergence, optimizer
evaluation counts, finite objective values, fixed-parameter gradients, Hessian
status, finite fixed-effect standard errors, dropped rows, positive residual
scale values, random-effect standard deviations near zero, `rho12` boundary
warnings, Student-t `nu` boundary behaviour, known sampling covariance summaries
including dense-matrix rank/conditioning, dense fixed-effect design size,
ordinary random-effect replication, ordinary random-slope design variation, and
phylogenetic species replication. For the first univariate `mu`/`sigma`
mean-scale covariance block, it also reports group replication and whether
either component SD is tiny on its interpretation scale. For the first
bivariate `mu1`/`mu2` random-intercept covariance block, it reports group
replication and whether either fitted group-level SD is tiny relative to the
matching residual scale. For the ordinary q=4 all-four bivariate
location-scale block, it reports group replication, location SDs relative to
residual scales, log-`sigma` SDs, and the maximum absolute latent correlation.
For the first fitted bivariate phylogenetic `mu1`/`mu2` location slice, it
reports whether `corpars$phylo` is near the correlation boundary and whether
either phylogenetic location SD is tiny relative to the matching residual scale.
Future structured-effect phases still need separability diagnostics for
phylogenetic plus non-phylogenetic species effects and spatial field plus site
or study effects.

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

Multiple random factors should be represented as separate additive blocks, not
as one automatically enlarged covariance matrix. For example, an ordinary
individual block, a phylogenetic species block, and a future spatial site block
can all appear in the linear predictor, but the first fitted models should keep
their variances and correlations block-specific. Cross-factor covariance is a
separate research problem.

Recommended staging:

- implement intercept-only structured effects first;
- then one structured slope in `mu`;
- allow at most two structured `mu` slopes as the near-term advanced path;
- delay interaction slopes until simulation studies show reliable recovery;
- delay structured slopes in `sigma` and `rho12` until the location model is
  stable;
- warn when the number of structured slopes is large relative to species,
  location, study, or within-group replication.

The first structured-slope path should treat the slope field as independent of
the intercept field, and should not estimate intercept-slope `corpair()` rows.
The fitted coordinate spatial one-slope path follows that rule: it estimates
`spatial(1 | site)` and `spatial(0 + x | site)` as independent fields with a
shared coordinate precision and separate SDs. Phylogenetic slopes, mesh/SPDE
slopes, multiple spatial slopes, and slope correlations remain later gates.
Slice 186 rechecked this boundary: `phylo(1 + x | species, tree = tree)` is
still rejected, while the coordinate-spatial one-slope path is fitted. This is
a deliberate validation gap, not a syntax synonym.
Slice 187 rechecked the fitted spatial side: the slope-field SD has direct
profile-interval coverage, while spatial `sigma`, bivariate spatial syntax,
and multiple spatial slopes remain outside the fitted surface.
For two-response models, the most interesting later slope correlation is a
response-1 slope versus response-2 slope for the same covariate, matching the
plasticity-syndrome idea in O'Dea, Noble, and Nakagawa (2021). That target needs
a coefficient-aware `corpair()` syntax and `corpairs()` labels before it can be
implemented safely.

## Boundary With rho12

`rho12` is residual response-response correlation at the observation level:

```text
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
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
2. Extend the known-sampling-covariance path from dense `V` to sparse storage,
   using the preferred `meta_V(V = V)` spelling once the alias/rename slice is
   implemented.
3. Keep the first `phylo(1 | species, tree = tree)` univariate Gaussian `mu`
   path under simulation and comparator tests.
4. Add matching bivariate `mu1`/`mu2` phylogenetic location effects with one
   mean-mean correlation.
5. Add the constant bivariate phylogenetic q=4 block spanning `mu1`, `mu2`,
   `sigma1`, and `sigma2`; this 35-slice route now precedes spatial.
6. Close the coordinate-spatial foundation:
   `spatial(1 | site, coords = coords)` and one numeric
   `spatial(1 + x | site, coords = coords)` slope in univariate Gaussian `mu`.
7. Reserve animal-model and user-supplied relatedness syntax as siblings of
   `phylo()` and `spatial()`, while keeping the fitted path blocked until the
   parser, matrix validation, diagnostics, profile-target labels, and recovery
   tests exist.
8. Add spatial SPDE/GMRF fields using the same structured-effect principle.
9. Add one phylogenetic structured slope in `mu`; then, only after recovery
   evidence, allow a maximum of two structured `mu` slopes. For spatial, the
   analogous multiple-slope and slope-correlation path starts after the
   coordinate foundation has stronger recovery evidence and after the mesh/SPDE
   route is designed.
10. Treat structured effects in `rho12` as experimental until simulation
   evidence shows identifiability.

## Current Implementation Gate

The first fitted univariate slice is deliberately small:

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

Computationally, the tree-backed version is equivalent to:

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

The first fitted bivariate slice uses the same sparse augmented precision for
matching intercept-only `phylo()` terms in `mu1` and `mu2`:

```text
[a_mu1, a_mu2] ~ MatrixNormal(0, Q_aug^{-1}, Sigma_phylo)
mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
```

This estimates `sd_phylo_mu1`, `sd_phylo_mu2`, and one phylogenetic mean-mean
correlation. This q=2 path does not by itself add the all-four q=4
phylogenetic `sigma1`/`sigma2` endpoints, structured `rho12`, or random slopes.

## Map Slice 14: Constant Bivariate Phylogenetic q=4 Design

The current phylogenetic PLSM target is a constant q=4 phylogenetic covariance
block spanning location and residual-scale predictors for two Gaussian
responses:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ z + phylo(1 | p | species, tree = tree),
    sigma2 = ~ z + phylo(1 | p | species, tree = tree),
    rho12 = ~ w
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

The labelled form is accepted by the formula parser and is also usable for the
bivariate phylogenetic `mu1`/`mu2` mean-mean path:

```r
phylo(1 | p | species, tree = tree)
```

The two-bar form remains valid for the mean-mean path and maps internally to
`block = "phylo"`. The three-bar form records the user-facing covariance-block
label, such as `p`, and all four distributional formulas must use the same
group, tree, and block. The fitted q=4 path allows exactly one intercept-only
phylogenetic block. Partial, unlabelled, mismatched, random-slope, multiple
phylogenetic-block, and structured `rho12` forms remain planned or rejected.

This section supersedes the older local ordering that placed spatial fields
before structured effects in `sigma`. The current 35-slice route implements
constant phylogenetic q=4 first because the tree-precision algebra is already
validated for univariate `mu` and bivariate `mu1`/`mu2`. Spatial remains the
parallel sibling lane, with the coordinate-spatial `mu` intercept and one-slope
foundation now fitted locally and mesh/SPDE, bivariate spatial, and richer
spatial covariance paths still planned. Spatial is not folded into residual
`rho12` and not treated as an afterthought.

Let

```text
U = [a_mu1, a_mu2, a_sigma1, a_sigma2]
```

be an `n_node` by `q` matrix of augmented-tree latent effects, with `q = 4`.
Rows follow the sparse augmented tree precision `Q_aug`, including tips and
internal nodes. Columns follow the endpoint order:

```text
1 mu1:(Intercept)
2 mu2:(Intercept)
3 sigma1:(Intercept)
4 sigma2:(Intercept)
```

The prior is a matrix-normal distribution:

```text
U ~ MatrixNormal(0, Q_aug^{-1}, Sigma_phylo)
```

where `Sigma_phylo = D R D`, `D = diag(sd_phylo_mu1, sd_phylo_mu2,
sd_phylo_sigma1, sd_phylo_sigma2)`, and `R` is a 4 by 4 positive-definite
correlation matrix. In expanded scalar form:

```text
vec(U) ~ MVN(0, Sigma_phylo %x% Q_aug^{-1})
```

using endpoint-major storage to match the existing bivariate `mu1`/`mu2`
`u_phylo` layout. The negative log prior is:

```text
nll_phylo_q4 =
  0.5 * [
    n_node * q * log(2*pi)
    + n_node * log|Sigma_phylo|
    - q * log|Q_aug|
    + tr(Sigma_phylo^{-1} U' Q_aug U)
  ].
```

This is the same algebra already exercised by the internal q-probe helper and
`drm_phylo_correlated_precision_nll()`: the tree precision controls dependence
among species, while `Sigma_phylo` controls covariance among distributional
endpoints.

The linear predictors use observed tip rows selected from `U`:

```text
mu1_i = X_mu1[i, ] beta_mu1 + U[node_i, mu1]
mu2_i = X_mu2[i, ] beta_mu2 + U[node_i, mu2]
log(sigma1_i) = X_sigma1[i, ] beta_sigma1 + U[node_i, sigma1]
log(sigma2_i) = X_sigma2[i, ] beta_sigma2 + U[node_i, sigma2]
rho12_i = tanh_guard(X_rho12[i, ] beta_rho12)
```

The residual correlation `rho12` remains a within-observation coscale
parameter. It is not part of `Sigma_phylo`.

Reporting should mirror ordinary q=4 blocks:

- four phylogenetic SDs, labelled by endpoint and group;
- six `corpairs(level = "phylogenetic")` rows;
- classes `mean-mean`, four `mean-scale` rows, and `scale-scale`, with
  `location-location` and `location-scale` accepted as filter aliases;
- `summary(fit)$covariance` rows that include the covariance estimate
  `sd_from * sd_to * correlation`;
- `check_drm()` diagnostics for near-boundary phylogenetic correlations, tiny
  phylogenetic endpoint SDs, low species replication, and simultaneous ordinary
  same-species covariance.

Implementation is staged:

1. extend structured-term parsing to preserve an optional phylogenetic block
   label while keeping `phylo(1 | species, tree = tree)` backward compatible;
2. detect the matched all-four phylogenetic block in `mu1`, `mu2`, `sigma1`,
   and `sigma2`, and reject partial `sigma1`/`sigma2` phylogenetic use before
   optimization;
3. add q=4 starts, maps, TMB data, and transformed reports for `log_sd_phylo`
   and the six unstructured-correlation parameters;
4. add the q=4 prior contribution using the matrix-normal expression above;
5. route prediction, `ranef()`, `sdpars`, `corpars`, `corpairs()`,
   `summary()`, `profile_targets()`, `simulate()`, and `check_drm()` through
   the same endpoint order.

The first implementation should not combine this Family A q=4 block with
Family B `sd_phylo()` direct-SD regression for the same species level.

Slice 15 added a hidden TMB parameterization probe for this contract. That
probe uses endpoint-major q=4 `u_phylo` storage, four `log_sd_phylo` values,
and six unstructured-correlation parameters, then compares the TMB
matrix-normal prior against the R algebra helper.

Slice 16 added the parser and R-boundary plumbing around this contract. It
preserves the optional `phylo()` covariance-block label, requires matching
labels for bivariate phylogenetic location terms, and rejects partial or
ambiguous phylogenetic scale endpoints before model-frame construction.

Slice 17 adds the first public all-four q=4 likelihood and reporting path. It
uses the same endpoint-major storage, reports four phylogenetic endpoint SDs and
six `corpairs(level = "phylogenetic")` rows, includes the six rows in
`summary(fit)$covariance`, routes scale-endpoint predictions through the fitted
phylogenetic effects, and lists the six q=4 correlations as derived
`theta_phylo` targets rather than direct profile-ready atanh targets.

Slice 18 adds the first CRAN-safe q=4 recovery and diagnostic evidence. The
test simulates `mu1`, `mu2`, `log(sigma1)`, and `log(sigma2)` tip effects from a
four-endpoint phylogenetic covariance, fits the public all-four syntax, checks
broad fixed-effect, endpoint-SD, residual `rho12`, and finite-gradient targets,
and verifies that `check_drm()` reports a q=4 phylogenetic covariance diagnostic
instead of reusing the older mean-mean q=2 wording.

## Predictor-Dependent q=2 Phylogenetic Corpair Contract

The planned formula

```r
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ ecology
```

uses a positive-definite loading contract rather than independent per-species
2 by 2 covariance matrices. Let `A` be the standardized tip correlation matrix
from the tree. Let `z1` and `z2` be two independent unit phylogenetic fields:

```text
z1 ~ MVN(0, A)
z2 ~ MVN(0, A).
```

For species `l`,

```text
rho_l = tanh_guard(W_l alpha)
c_l = sqrt((1 + rho_l) / 2)
d_l = sqrt((1 - rho_l) / 2).
```

The first q=2 location-location model defines

```text
a1_l = tau1 (c_l z1_l + d_l z2_l)
a2_l = tau2 (c_l z1_l - d_l z2_l).
```

The same statement in matrix form is

```text
[a1, a2]' = L(rho, tau1, tau2) [z1, z2]'
```

where each species row of `L` contains the loading vectors
`(c_l, d_l)` and `(c_l, -d_l)`. Because the base covariance of `[z1, z2]` is
block diagonal with `A` in both blocks, the induced covariance of `[a1, a2]` is
positive definite whenever `A` is positive definite, `tau1 > 0`, `tau2 > 0`,
and `|rho_l| < 1`.

This contract has three useful checks:

```text
Cor(a1_l, a2_l) = rho_l                 when A_ll = 1
Var(a1_l) = tau1^2, Var(a2_l) = tau2^2  when A_ll = 1
Cov(a1, a2) = tau1 tau2 rho A           when rho_l is constant
```

When `rho_l` varies across species, the model is nonstationary. The
between-species covariance is multiplied by dot products of species-specific
loading vectors, so the marginal within-trait covariance for each endpoint is
not exactly `tau^2 A` off the diagonal unless the correlation predictor is
constant. That is the price of a species-specific phylogenetic correlation that
stays positive definite.

The first TMB implementation uses two independent unit augmented-tree effects
and applies this loading transformation in the `mu1` and `mu2` linear
predictors at observed tip nodes. It starts with constant `tau1` and `tau2`,
requires the endpoint pair `from = "mu1", to = "mu2"`, and rejects q=4
location-scale endpoints, direct-SD mixtures, random slopes, and spatial
siblings. Predictor-dependent phylogenetic location-scale pairs and the
scale-scale pair are q=4 models because their latent state includes `mu1`,
`mu2`, `sigma1`, and `sigma2`; they need a separate positive-definite q=4
correlation-regression contract.

Family B structured direct-SD syntax such as `sd_phylo(species) ~ z_species`
uses a separate non-centred tip-scaling contract. Let `v_aug` follow the unit
augmented tree covariance implied by the sparse precision, and let the
species-level scale predictor define `tau_l = exp(W_l alpha)` for observed
tips. The location contribution is:

```text
a_l = tau_l v_tip,l
Cov(a_tip) = D_tip A_tip D_tip
```

Internal nodes remain part of the computational base tree effect `v_aug`, but
they do not receive user-facing SD predictors. The predictor lives at observed
tips and must be constant within species. This keeps `sd_phylo()` in the Box 1
Family B lane: it replaces the scalar `log_sd_phylo` target for a univariate
location `phylo()` effect rather than adding another layer to the q=4 Family A
location-scale covariance block. The univariate fitting and first recovery
tests are implemented; bivariate `sd_phylo1()` / `sd_phylo2()` is implemented
as the next location-only direct-SD slice, while spatial direct-SD siblings
remain planned.

The bivariate direct-SD extension keeps the same Family B lane. It
targets only the phylogenetic location effects in matching `mu1` and `mu2`
formulas:

```text
mu1_i = X1_i beta1 + a1_species[i]
mu2_i = X2_i beta2 + a2_species[i]
tau1_l = exp(W1_l alpha1)
tau2_l = exp(W2_l alpha2)
a1_l = tau1_l v1_tip,l
a2_l = tau2_l v2_tip,l
```

The base effects `v1_aug` and `v2_aug` use the shared augmented tree precision
and one constant phylogenetic location-location correlation. Therefore

```text
Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m
```

`sd_phylo1(species) ~ z1` and `sd_phylo2(species) ~ z2` replace endpoint
phylogenetic location SDs; they do not model `sigma1`, `sigma2`, location-scale
correlations, scale-scale correlations, or residual `rho12`. They must be
rejected with the all-four q=4 phylogenetic block for the same species level,
because that block is the Family A constant covariance model across location
and scale effects.

When a direct-SD surface is fitted, `summary(fit)$covariance` cannot report one
literal endpoint SD because the covariance is species-pair specific. The compact
summary row uses the median fitted species SD for each direct endpoint and
leaves species-specific SD surfaces available through `sdpars`, `coef()`, and
`predict()`.

Testing should be staged:

- parser and fitted-model tests for `phylo(1 | species, tree = tree)` in `mu`
  and matching bivariate `mu1`/`mu2`, plus clear rejection in unsupported
  parameters such as `sigma` and `rho12`;
- deterministic algebra tests comparing sparse A-inverse prior calculations
  with a small dense covariance calculation;
- CRAN-safe simulation recovery tests with hand-built ultrametric trees and
  their implied phylogenetic correlation matrices, including the first positive
  bivariate mean-mean phylogenetic correlation;
- diagnostics for simultaneous phylogenetic plus ordinary same-species
  covariance, because those two layers can be weakly separated in finite data;
- optional long simulations for many species, near-zero phylogenetic SD,
  large residual noise, and simultaneous phylogenetic plus non-phylogenetic
  species effects.

The sibling `gllvmTMB` source map supports this order. Use it for design
lessons: tree input should prefer a sparse A-inverse path, dense VCV should be
a compatibility fallback, and SPDE should enter later through mesh/projection
objects. Do not import the high-dimensional GLLVM keyword grid or loading
machinery into this one- and two-response package.
