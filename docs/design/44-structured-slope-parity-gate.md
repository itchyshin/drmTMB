# Structured Slope Parity Gate

This note records the Slice 239 boundary, rechecked in Slice 272 and updated in
Slice 39 of the post-0.1.3 parity lane, before Phase 18 simulations include
structured random slopes broadly. The reader question is simple: can `drmTMB`
fit the same one-slope model for spatial, phylogenetic, animal, and
user-supplied relatedness effects? The current answer is yes for the first
univariate Gaussian `mu` path: each layer fits one numeric structured slope as
an independent intercept and slope field. Broader slope correlations, multiple
structured slopes, bivariate structured slopes, scale-parameter structured
slopes, and non-Gaussian structured dependence remain planned.

## Current Status

| Layer | Public syntax | Fitted now? | Phase 18 status |
| --- | --- | --- | --- |
| Coordinate spatial one-slope `mu` | `spatial(1 + x | site, coords = coords)` | Yes, for univariate Gaussian `mu` with independent intercept and slope fields | Can enter a focused Wave A structured-slope smoke grid |
| Phylogenetic one-slope `mu` | `phylo(1 + x | species, tree = tree)` | Yes, for univariate Gaussian `mu` with independent intercept and slope fields | Can enter a focused Wave A tree-size and slope-SD smoke grid |
| Animal one-slope `mu` | `animal(1 + x | id, pedigree = ped)`, `animal(1 + x | id, A = A)`, or `animal(1 + x | id, Ainv = Ainv)` | Yes, for univariate Gaussian `mu` with independent intercept and slope fields | Can enter a small dense-pedigree and known-matrix smoke grid; sparse large-pedigree precision construction remains planned |
| Generic relatedness one-slope `mu` | `relmat(1 + x | id, K = K)` or `relmat(1 + x | id, Q = Q)` | Yes, for univariate Gaussian `mu` with independent intercept and slope fields | Can enter a small known-matrix covariance/precision smoke grid |

The fitted surfaces now share the same first contract. Each slope path reports
separate SDs in `sdpars$mu`, term-specific random effects in `ranef()`, direct
`profile_targets()` rows for the intercept-field and slope-field SDs, and
structured-effect diagnostics in `check_drm()`. That evidence is still narrow:
it supports a single numeric univariate Gaussian `mu` slope, not a general
structured-slope covariance system.

## Common Model

For a structured random intercept and one structured random slope:

```text
eta_mu,ij = X_ij beta + z0_j + x_ij z1_j

z0 ~ MVN(0, sd0^2 K)
z1 ~ MVN(0, sd1^2 K)
cov(z0, z1) = 0 in the first fitted slope path
```

`K` is the known dependence matrix:

```text
K = M_coords   for coordinate spatial effects
K = A_phylo    for phylogenetic relatedness
K = A_ped      for animal-model additive relatedness
K = K_user     for user-supplied relatedness through relmat()
```

The first public path keeps intercept and slope fields independent. Correlated
structured intercept-slope fields should wait until independent one-slope
recovery is stable and the output has coefficient-aware `corpairs()` rows.

## Biological Examples

Animal models should lead with eco-evo questions, not matrix mechanics:

- additive genetic variation in mean body size:
  `animal(1 | animal_id, pedigree = ped)`;
- additive genetic variation in thermal plasticity:
  `animal(1 + temperature | animal_id, pedigree = ped)`;
- maternal or permanent-environment variation as an ordinary grouped effect
  beside the animal effect:
  `animal(1 | animal_id, pedigree = ped) + (1 | dam_id)`;
- experimental-line relatedness supplied by a genomic relationship matrix:
  `relmat(1 | line, K = G)`.

Phylogenetic examples should keep shared ancestry visible:

```r
bf(body_size ~ island_area + phylo(1 | species, tree = tree))
bf(body_size ~ temperature + phylo(1 + temperature | species, tree = tree))
```

The second example is now fitted for univariate Gaussian `mu`. It asks whether
related species share not only baseline trait values but also similar
environmental slopes.

Spatial examples can use the fitted one-slope path now:

```r
bf(abundance ~ depth + spatial(1 + depth | reef, coords = reef_xy))
```

This asks whether nearby reefs share both baseline abundance and a depth
response. In the current coordinate path, the intercept and slope fields are
independent; spatial slope correlations, spatial `sigma`, and bivariate
spatial covariance remain planned.

## Simulation Gate

The coordinate spatial, phylogenetic, animal-model, and `relmat()` one-slope
paths can enter focused Phase 18 Wave A smoke cells. Slice 241 adds the first
CRAN-safe smoke surface for spatial, and Slice 39 adds the fitted
phylo/animal/relmat sibling paths. Larger simulation cells should record:

- number of sites;
- observations per site;
- spatial range or covariance setting;
- intercept-field SD;
- slope-field SD;
- covariate spread within sites;
- convergence, Hessian status, boundary flags, and direct SD interval status.

These one-slope cells should stay small until the smoke evidence stabilizes.
They are fitted enough for targeted validation, but they are not yet broad
operating-characteristic tables. Before widening them, each structured layer
still needs:

- validated covariance or precision input with stable row-name matching;
- fitted SD summaries and `profile_targets()` rows;
- `check_drm()` diagnostics;
- recovery tests for the one-slope SD;
- reader-facing examples that name the biological question.

## Role Summary

Ada keeps the structured layers in one roadmap while avoiding over-generalized
claims. Darwin wants animal examples to start from additive genetic variation
and plasticity, because that is how evolutionary ecologists will search for the
feature. Fisher keeps simulations limited to fitted surfaces. Noether keeps the
equation, syntax, and fitted-status table aligned. Pat keeps unsupported
extensions, such as multiple slopes and slope correlations, visibly labelled as
planned. Rose keeps the phrase "structured-slope parity" tied to the narrow
univariate Gaussian one-slope contract.
