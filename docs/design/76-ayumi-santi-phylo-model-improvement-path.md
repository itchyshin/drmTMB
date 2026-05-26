# Ayumi and Santi Phylogenetic Model Improvement Path

Reader: Ayumi, Santi, and package contributors deciding which phylogenetic
model improvements should happen next. The purpose is to turn the three local
protocol PDFs into a staged `drmTMB` path without pretending that every
pre-registered model is already a stable package surface.

Source protocols:

- `/Users/z3437171/Desktop/dis_reg_models/Avian_co_scale__protocol_.pdf`
- `/Users/z3437171/Desktop/dis_reg_models/Mammalian_location_co_scale_trade_offs_protocol.pdf`
- `/Users/z3437171/Desktop/dis_reg_models/Pre_registration_for_ecogeographic_rules.pdf`

In this note, location means the expected trait value, scale means the residual
standard deviation `sigma`, and coscale means the residual bivariate
correlation `rho12`. Phylogenetic and ordinary species-level covariance are
separate correlation layers and should be reported with `corpairs()` rows that
name their level, not folded into `rho12`.

## What The Protocols Need

The avian clutch-size protocol and the mammalian litter-size protocol share the
same three-step model ladder.

1. Objective 1 estimates a bivariate phylogenetic location model for two
   species-level traits, such as adult body mass with clutch size or litter
   size. The key estimands are the phylogenetic location-location correlation,
   the non-phylogenetic independent-species residual correlation, and
   trait-specific phylogenetic variance proportions.
2. Objective 2 extends the same two-trait model into a bivariate phylogenetic
   location-scale model. The four phylogenetic endpoints are `mu1`, `mu2`,
   `sigma1`, and `sigma2`; the scientific targets are the location-location,
   scale-scale, and location-scale phylogenetic correlations.
3. Objective 3 lets ecological classes change the covariance structure. For
   Santi's mammal model those classes are terrestrial, aquatic, and aerial
   lifestyles. For the avian clutch-size model they are nest-habitat groups.
   The reported SDs in this objective describe among-species variation within
   classes, not residual-scale heterogeneity around a fitted mean pattern.

The ecogeographic passerine preregistration adds a second, broader route. Its
primary species-level analyses are univariate phylogenetic location-scale
models for body mass, bill length, tarsus length, and plumage lightness, with
temperature, precipitation, and their quadratic terms in both `mu` and
`sigma`. It then treats selected bivariate PLSMs as exploratory pairwise
models and uses family-level meta-analytic slope summaries as complementary
evidence.

Across all three protocols, the operational requirements are the same:
complete species and tree matching, explicit tree-uncertainty sensitivity,
clear convergence diagnostics, honest fallback rules, and reports that keep
point estimates, Wald intervals, profiles, bootstraps, and failed intervals in
separate columns.

## Current `drmTMB` Fit

These pieces are already close enough to use as the first applied scaffolds:

- univariate Gaussian location-scale models with fixed predictors in `mu` and
  `sigma`;
- univariate phylogenetic `mu` and `sigma` intercepts, including the matching
  `mu`-`sigma` phylogenetic correlation;
- bivariate Gaussian residual `rho12`;
- bivariate phylogenetic q2 location-location covariance for matching
  `mu1`/`mu2` `phylo()` terms;
- constant bivariate phylogenetic q4 location-scale covariance for matching
  all-four `mu1`, `mu2`, `sigma1`, and `sigma2` `phylo()` terms;
- bivariate phylogenetic direct-SD surfaces for `mu1` and `mu2`, including the
  q2 `corpair(..., level = "phylogenetic")` combination;
- `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()`
  rows that name fitted structured correlation layers.

The most important caution is the Ayumi Mass + Beak evidence already in the
roadmap. The location-only q2 phylogenetic route is the current demonstration
path. The all-four q4 route can be optimized, but previous full-species runs
were boundary-heavy or false-converged, and q4 correlations remain
derived-only for intervals. That makes q4 a diagnostic and validation lane
before it becomes an applied showcase.

## Improvement Path

### Phase 0: isolate the current phylogenetic feature lane

Before running Ayumi or Santi applied fits, isolate or commit the current
direct-SD plus q2 phylogenetic `corpair()` work. The repository currently has
several unrelated NB2, pkgdown, and roadmap changes in the same dirty tree.
Applied model evidence should be traceable to one package state.

Done means a clean branch or clearly staged change set for the fitted
phylogenetic Gaussian surfaces, plus the existing full `devtools::check()`
evidence from the direct-SD/corpair lane.

### Phase 1: write a formula gallery for the three protocols

Create a no-fit protocol gallery that shows the exact `drmTMB` formulas for
each target and marks every row as fitted, diagnostic, or planned. This should
not be a public tutorial yet; it is a shared contract for Ayumi, Santi, and the
package team.

The Phase 1 gallery is now recorded in
`docs/design/77-ayumi-santi-protocol-formula-gallery.md`.

The immediate q2 Objective 1 analogue is:

```r
bf(
  mu1 = log_mass ~ 1 + phylo(1 | p | species, tree = tree),
  mu2 = log_clutch_or_litter ~ 1 + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1
)
```

For one-row-per-species data, `rho12` is the row-level independent-species
correlation after the phylogenetic effect and fixed effects. If repeated
source-level records are retained, a separate ordinary species layer may be
needed, but that is a different identifiability problem and must not be mixed
into the first Objective 1 validation run.

The immediate univariate ecogeographic PLSM analogue is:

```r
bf(
  trait ~ temp + precip + I(temp^2) + I(precip^2) +
    phylo(1 | p | species, tree = tree),
  sigma ~ temp + precip + I(temp^2) + I(precip^2) +
    phylo(1 | p | species, tree = tree)
)
```

Appendage traits add standardised body mass to both `mu` and `sigma`, matching
the preregistered allometric correction.

The q4 bivariate PLSM analogue is:

```r
bf(
  mu1 = trait1 ~ predictors1 + phylo(1 | p | species, tree = tree),
  mu2 = trait2 ~ predictors2 + phylo(1 | p | species, tree = tree),
  sigma1 = ~ scale_predictors1 + phylo(1 | p | species, tree = tree),
  sigma2 = ~ scale_predictors2 + phylo(1 | p | species, tree = tree),
  rho12 = ~ 1
)
```

This is fitted as a constant q4 phylogenetic covariance block, but it is not
yet promoted as routine applied inference.

### Phase 2: make Objective 1 dependable

The first applied validation slice should be the q2 bivariate phylogenetic
location model for body mass with clutch size or litter size. This is the
smallest model that directly answers Santi's first protocol objective and
gives Ayumi a stable phylogenetic trait-correlation scaffold.

Tasks:

- fit a small simulated q2 model with known phylogenetic correlation,
  residual `rho12`, and trait-specific SDs;
- fit the avian and mammalian Objective 1 analogues on a representative tree;
- repeat the same fit across a small tree set as a maximum-likelihood tree
  sensitivity analysis;
- report `corpairs(level = "phylogenetic")`, `rho12()`, `sdpars`, gradients,
  `pdHess`, boundary flags, and direct profile-target status;
- produce one compact applied table per dataset with the phylogenetic
  correlation and the independent-species residual correlation side by side.

Done means the q2 Objective 1 model has clean convergence on the representative
dataset or a documented fallback, plus a check-log entry that separates package
diagnostics from biological interpretation.

The developer-only runner for this slice is
`tools/ayumi-santi-q2-objective1-runner.R`. It accepts prepared data and a
tree, writes the exact formula and preflight table, then fits the q2
phylogenetic location model and exports `corpairs()`, `rho12()`, `sdpars`,
`profile_targets()`, `check_drm()`, fixed effects, covariance rows, conditions,
and a saved fit. Use `--dry-run true` first for each Ayumi or Santi dataset so
species matching, formula terms, and tree status are reviewable before long
fits begin.

The first simulated positive control for this runner is recorded in
`docs/design/78-ayumi-santi-q2-objective1-positive-control.md`, with generated
artifacts under
`docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/`.

The simulated-only finish for slices 1-5 is recorded in
`docs/design/79-ayumi-santi-no-real-data-sim-slices.md`. It adds a q2
mini-grid, an ecogeographic univariate PLSM positive control, a q4 bivariate
PLSM diagnostic positive control, a split-fit class-contrast smoke, and an
integration summary under `docs/dev-log/ayumi-santi/sim-slices/`.

### Phase 3: harden the univariate ecogeographic PLSM route

The ecogeographic preregistration treats univariate PLSMs as the primary
species-level analysis. This route should come before broad q4 promotion
because it is simpler, scientifically central, and already close to the fitted
surface.

Tasks:

- validate `mu` and `sigma` climate fixed effects with a phylogenetic
  `mu`-`sigma` intercept block;
- add a protocol-scale smoke run for body mass, one appendage trait, and
  plumage lightness;
- decide whether derived phylogenetic variance proportions and
  macro-evolvability are analysis-script summaries or exported helpers;
- keep scale interpretation as residual species-level heterogeneity around the
  fitted climate model, not within-population variance.

Done means the univariate PLSM has a repeatable applied report and a small
simulation or positive-control check that the `mu`-`sigma` phylogenetic
correlation is recoverable away from boundaries.

### Phase 4: keep q4 PLSM as validation before showcase

The q4 route is the bridge to the bivariate PLSMs in all three protocols, but
it is the highest-risk near-term model. It should move through a validation
ladder rather than a public tutorial jump.

Tasks:

- rerun the known Ayumi Mass + Beak q4 and block-diagonal fallback targets on
  the current code state;
- add a smaller positive-control q4 dataset where all six phylogenetic
  correlations are away from `-1` and `+1`;
- treat full q4 correlations as point-estimate rows with
  `derived_interval_unavailable` until a direct or derived interval method is
  designed;
- use bootstrap only as a labelled fallback and report refit success counts,
  not as a silent replacement for failed profiles.

Done means q4 has a clear "safe when / unsafe when" report for Ayumi and Santi,
not just a model that optimizes once.

### Phase 5: prototype lifestyle and nest-habitat covariance contrasts

Lifestyle-specific or nest-habitat-specific covariance is not just another
fixed effect. It changes the phylogenetic and non-phylogenetic covariance
matrices by class. The first useful analysis workflow is a split-fit
sensitivity: fit the q2 Objective 1 model separately within each class using
the class-pruned tree, then compare the correlations and SDs.

Only after split fits behave should package code add a single-model
class-specific covariance surface. That implementation needs log-SD and
Fisher-z parameterization, class-size diagnostics, and a positive-definite
matrix contract before it is exposed as formula syntax.

Done means terrestrial/aquatic/aerial and nest-habitat contrasts have a
documented split-fit report, with explicit warnings when a class has too few
species or the pruned tree is weakly informative.

### Phase 6: defer missing-response marginalization and Bayesian tree pooling

The protocols correctly say that species with one observed response could
contribute through a marginal likelihood where the implementation allows it.
The current bivariate `drmTMB` route uses complete cases across response and
predictor formulas. Marginalizing partially missing bivariate responses is a
separate likelihood feature and should not block the q2/q4 validation ladder.

Likewise, posterior pooling across many trees is a Bayesian workflow in the
protocols. In `drmTMB`, the near-term analogue should be a tree-loop
sensitivity table: fit the same maximum-likelihood model to a small tree set,
then summarize how the main estimates move. Do not describe this as posterior
pooling.

### Phase 7: keep family-level slope synthesis outside the core phylo lane

The ecogeographic family-level analyses use family-specific climate slopes as
effect sizes with known uncertainty. That belongs to the meta-analysis and
analysis-workflow lane, not the q4 phylogenetic covariance lane. Use existing
known-sampling-covariance grammar where it fits, and do not introduce
`meta_gaussian()` or `tau ~` syntax for these protocols.

## Near-Term Pull Request Order

1. Add the protocol formula gallery and applied validation checklist.
2. Run and document q2 Objective 1 fits for avian clutch size and mammalian
   litter size on representative trees.
3. Run and document univariate ecogeographic PLSM fits for the primary traits.
4. Rerun q4 Ayumi Mass + Beak and a small positive-control q4 model on the
   current code.
5. Add split-fit lifestyle and nest-habitat covariance reports.
6. Only then decide whether class-specific covariance or missing-response
   marginalization should become package features.

## Not This Lane

- Do not add q4 predictor-dependent phylogenetic `corpair()` regressions just
  because q4 constant covariance is needed. The protocols need constant q4
  covariance first and class-specific q2/q4 contrasts later.
- Do not add non-Gaussian phylogenetic location-scale covariance for these
  Gaussian trait protocols.
- Do not treat `rho12` as a phylogenetic correlation.
- Do not make q4 derived intervals look available until interval machinery
  exists.
- Do not promote lifestyle or nest-habitat contrasts from split-fit
  sensitivity to single-model inference without a class-size and
  positive-definiteness gate.
