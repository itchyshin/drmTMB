# Structured Slope Parity Gate

This note records the Slice 239 boundary, rechecked in Slice 272, before Phase
18 simulations include structured random slopes. The reader question is simple:
can `drmTMB` fit the same one-slope model for spatial, phylogenetic, animal, and
user-supplied relatedness effects? The current answer is no. The parser can read
the intended one-slope syntax, but the fitted surfaces are at different stages.

## Current Status

| Layer | Public syntax | Fitted now? | Phase 18 status |
| --- | --- | --- | --- |
| Coordinate spatial one-slope `mu` | `spatial(1 + x | site, coords = coords)` | Yes, for univariate Gaussian `mu` with independent intercept and slope fields | Can enter a focused Wave A structured-slope smoke grid |
| Phylogenetic one-slope `mu` | `phylo(1 + x | species, tree = tree)` | No, rejected with an explicit planned-status message | Keep out of simulation until implementation, SD/profile targets, diagnostics, and recovery tests exist |
| Animal one-slope `mu` | `animal(1 + x | id, Ainv = Ainv)` | No. `animal(1 | id, pedigree = pedigree)`, `animal(1 | id, A = A)`, and `animal(1 | id, Ainv = Ainv)` now fit Gaussian `mu` intercepts, but structured animal slopes and sparse large-pedigree construction remain planned. | Keep one-slope animal models out of simulation until slope SD/profile targets, diagnostics, and recovery tests exist |
| Generic relatedness one-slope `mu` | `relmat(1 + x | id, K = K)` or `relmat(1 + x | id, Q = Q)` | No. `relmat(1 | id, K = K)` and `relmat(1 | id, Q = Q)` now fit Gaussian `mu` intercepts, but structured relatedness slopes remain planned. | Keep one-slope `relmat()` models out of simulation until slope orientation, covariance/precision scale, sparse precision, and recovery tests are implemented |

This asymmetry is intentional. Spatial one-slope support came from the
coordinate-spatial Gaussian path. Phylogenetic, animal, and `relmat()` slope
support should share the same structured-effect abstraction, but each public
surface still needs validation before it becomes a simulation cell.

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

The second example is planned, not fitted. It asks whether related species
share not only baseline trait values but also similar environmental slopes.

Spatial examples can use the fitted one-slope path now:

```r
bf(abundance ~ depth + spatial(1 + depth | reef, coords = reef_xy))
```

This asks whether nearby reefs share both baseline abundance and a depth
response. In the current coordinate path, the intercept and slope fields are
independent; spatial slope correlations, spatial `sigma`, and bivariate
spatial covariance remain planned.

## Simulation Gate

Only the coordinate spatial one-slope path can enter Phase 18 Wave A today.
Slice 241 adds the first CRAN-safe smoke surface for that path. Larger
simulation cells should record:

- number of sites;
- observations per site;
- spatial range or covariance setting;
- intercept-field SD;
- slope-field SD;
- covariate spread within sites;
- convergence, Hessian status, boundary flags, and direct SD interval status.

Phylogenetic, animal, and `relmat()` one-slope cells should appear in the
failure ledger as planned surfaces. Slice 272 confirms parser validation for
intercept and one numeric slope and rejection of multiple structured slopes.
The later animal/`relmat()` known-matrix intercept slice is fitting evidence
only for `animal(1 | id, A/Ainv = ...)` and `relmat(1 | id, K/Q = ...)`, not
for slope parity. These one-slope cells stay out of operating-characteristic
tables until they also have:

- validated covariance or precision input with stable row-name matching;
- fitted SD summaries and `profile_targets()` rows;
- `check_drm()` diagnostics;
- recovery tests for the one-slope SD;
- reader-facing examples that name the biological question.

## Role Summary

Ada keeps the structured layers in one roadmap while avoiding false parity.
Darwin wants animal examples to start from additive genetic variation and
plasticity, because that is how evolutionary ecologists will search for the
feature. Fisher keeps simulations limited to fitted surfaces. Noether keeps the
equation, syntax, and fitted-status table aligned. Pat keeps the unsupported
phylogenetic/animal/relmat slope examples visibly labelled as planned. Rose
keeps the phrase "spatial parity" from drifting into an unsupported claim.
