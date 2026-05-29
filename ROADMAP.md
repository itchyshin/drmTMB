# drmTMB Roadmap

`drmTMB` is a focused R package for fast univariate and bivariate
distributional regression models using TMB.

## Version 0.1.3 Preview Release

- Current preview version: `0.1.3`.
- Meaning of `0.1.3`: a preview that keeps the `0.1.2` profile-inference,
  tutorial, and roadmap hardening, then adds the first fitted known-relatedness
  Gaussian `mu` slice and the first coordinate-spatial bivariate q=2
  `mu1`/`mu2` location covariance slice. It is not the final
  double-hierarchical individual-difference endpoint.
- Release boundary: Phase 9 is closed at the implemented ordinal and
  denominator-aware MVPs. The first Phase 11 bivariate `mu1`/`mu2`
  random-intercept covariance slice is now implemented. Phase 17 now records the
  visualization and marginal-effects layer because the later simulation and
  comparator phases need stable plotting/data helpers from the start. Phase 18
  is the comprehensive simulation, power, accuracy, and coverage evidence layer,
  but the Slice 202 gate keeps broad Phase 18 closed until the post-202 Phase
  17 return block, especially meta-analysis hardening, is complete. A narrow
  Poisson random-effect pilot simulation may start earlier as a scoped
  operating-characteristics grid. Phase 19 is the one-off comparator
  demonstration layer; Phase 20 is CRAN and paper preparation. Richer bivariate
  random slopes, residual-scale slope covariance, structured covariance, and the
  full double-hierarchical endpoint remain roadmap work for later releases.
- Completed before tagging the version:
  - `devtools::check()` passes with 0 errors and 0 warnings;
  - `devtools::test()` and `pkgdown::check_pkgdown()` pass;
  - pkgdown deploys with the short landing page and current family reference
    pages;
  - implemented families have simulation, independent-likelihood, or
    comparator coverage plus malformed-input tests;
  - `docs/dev-log/known-limitations.md`, `NEWS.md`, `README.md`, and the
    roadmap agree about what is implemented versus planned;
  - paper examples for individual-difference location-scale models are
    presented as a replication roadmap unless the matching drmTMB model class
    is actually implemented and tested.

## Phase 0: Project Infrastructure

- R package scaffold with `DESCRIPTION`, `R/`, `src/`, `tests/`, and
  vignettes.
- Design documents for formula grammar, families, likelihoods, random effects,
  testing, distribution priorities, and the reference/paper programme.
- Codex-native project instructions, agents, and skills.
- Continuous integration for R CMD check.

## Phase 1: Gaussian Location-Scale MVP

- Status: initial MVP implemented.
- `bf()` and `drmTMB()` support Gaussian location-scale models with fixed
  effects, `mu` random intercepts, simple numeric `mu` random slopes, and
  residual-scale random intercepts plus independent random slopes in `sigma`.
- Supported syntax:
  `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x2 + (1 | id) + (0 + w | id))`.
- Keep parser support for `sd(group) ~`, known sampling covariance
  (`meta_V(V = V)` preferred, deprecated `meta_known_V(V = V)` as a
  compatibility alias), `phylo()`, and `spatial()` terms from the start.
- Prediction for `mu` and `sigma` is implemented.
- Simulation and parameter-recovery tests are implemented for the first
  Gaussian case.

## Phase 2: Meta-Analytic Gaussian Regression

- Status: diagonal and dense full known sampling covariance implemented.
- Treat meta-analysis as `family = gaussian()` plus known sampling covariance.
  The preferred implemented spelling is `meta_V(V = V)`, with vectors accepted
  for diagonal sampling variances and matrices accepted for dense sampling
  covariance. Deprecated `meta_known_V(V = V)` remains a compatibility alias
  for the same additive known-covariance likelihood path.
- Support known sampling covariance through vectors, columns, diagonal matrices,
  dense block-diagonal matrices, or dense full matrices.
- Reserve, but do not fully implement for `0.1.3`, a `meta_V()` umbrella that
  can unify additive known covariance `meta_V(V = V)` with proportional
  sampling-variance models such as
  `meta_V(w = w, scale = "proportional")`.
- The implemented known-covariance Gaussian path is now tested with ordinary
  `mu` random intercepts and random-effect scale formulae such as
  `sd(id) ~ x_group` using independent dense marginal-likelihood comparators.
- Add sparse known covariance after dense covariance tests pass.
- Use `sigma ~ x1` for heterogeneous heterogeneity, even when papers
  describe the same unknown SD as `tau`.
- Tests based on fixed known sampling variance and known extra heterogeneity
  are implemented.

## Phase 2b: Likelihood Weights

- Status: implemented for ordinary row likelihood weights.
- A top-level `weights =` argument to `drmTMB()` now supplies ordinary
  likelihood weights, matching the broad convention in mixed-model packages.
- Keep likelihood weights separate from known sampling covariance: weights
  multiply observation log-likelihood contributions, whereas `meta_V(V = V)`
  supplies known sampling covariance. Deprecated `meta_known_V(V = V)` remains
  a compatibility alias for the same additive path.
- Coexistence rule: diagonal/vector known `V` may be combined with ordinary
  likelihood weights, but those weights do not create proportional sampling
  variance. Full dense matrix-`V` fits reject non-unit top-level weights until
  joint-block weighting is designed; proportional sampling variance through a
  future `meta_V(..., scale = "proportional")` is also not ordinary likelihood
  weighting.
- Implemented design rule: univariate models use one non-negative finite
  weight per observation; bivariate models use one weight per complete response
  pair.
- Do not add response-specific bivariate weights until the likelihood and
  interpretation are documented.
- Full dense `meta_V(V = V)` covariance paths reject non-unit `weights =`
  until a joint-block weighting design is documented.

## Phase 3: Bivariate Gaussian Coscale

- Status: fixed-effect bivariate Gaussian implemented and closure-audited;
  matched labelled `mu1`/`mu2` random-intercept covariance blocks are
  implemented as the first bivariate group-level covariance slice.
- Support separate formulas for `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...`.
- `mvbind(y1, y2) ~ x` is implemented as shorthand for identical location
  formulas and expands internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
- Added `sigma1`, `sigma2`, and constant `rho12`.
- Added predictor-dependent `rho12 ~ x` using an unconstrained correlation
  predictor with a tanh response transform.
- Added simulation tests for positive, near-zero, negative, and
  predictor-dependent residual correlations.
- Added tests and documentation for `rho12()`, `corpairs()`, `fitted()`,
  `sigma()`, `simulate()`, whitened Pearson residuals, and coefficient-level
  `vcov()` names.
- Added complete-row bivariate Gaussian known sampling covariance through
  `meta_V(V = V)` and `meta_vcov_bivariate()`, with an independent base R MVN
  likelihood comparator and tests that residual `rho12` stays distinct from
  known sampling correlation.
- Added row likelihood weights for independent bivariate rows; dense known-`V`
  bivariate fits reject non-unit weights until a joint-block weighting design is
  documented.
- Public bivariate family grammar accepts `family = c(gaussian(), gaussian())`
  or `family = list(gaussian(), gaussian())` for the implemented all-Gaussian
  likelihood. Mixed composed families such as `family = c(gaussian(), poisson())`
  remain future work where the joint likelihood is defined.
- Matching labelled random intercepts in `mu1`/`mu2` and `sigma1`/`sigma2`,
  such as `(1 | p | id)` in both same-parameter formulas, now fit group-level
  covariance blocks. The group-level SDs are reported in `sdpars$mu` or
  `sdpars$sigma`, the group-level correlations are reported in `corpars$mu` or
  `corpars$sigma` and `corpairs()`, and residual `rho12` remains separate.
  Targeted simulation coverage now fits both bivariate group-level covariance
  blocks in the same model with predictor-dependent residual `rho12 ~ x`; the
  same regression now checks that `summary(fit)$covariance` reports the two
  group-level covariance rows and omits residual `rho12`.
- One or more same-response bivariate `mu`/`sigma` random-intercept covariance
  blocks are implemented, such as matching `(1 | p | id)` terms in `mu1` and
  `sigma1` plus matching `(1 | q | id)` terms in `mu2` and `sigma2`.
- Matching labelled random intercepts across all four bivariate location-scale
  parameters, `mu1`, `mu2`, `sigma1`, and `sigma2`, now fit one all-four
  intercept block and report six `corpairs()` rows: one `mu1`-`mu2` row, four
  mean-scale rows (`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and
  `mu2`-`sigma2`), and one `sigma1`-`sigma2` row. This is still
  random-intercept support, not bivariate random slopes or the full
  double-hierarchical endpoint.
- Bivariate random slopes, random effects in `rho12`, bivariate known-`V` plus
  random effects, multi-term cross-parameter bivariate covariance, and
  structured bivariate covariance beyond the fitted q=2 phylogenetic, spatial,
  animal, and `relmat()` location slices remain future work and are rejected
  before optimization.

## Phase 4: Mixed and Double-Hierarchical Models

- Status: random intercepts, independent numeric random slopes written as
  `(0 + x | id)`, and ordinary correlated intercept-slope blocks written as
  `(1 + x | id)` or `(1 + x | p | id)` are implemented for the univariate
  Gaussian location formula. Random intercepts in the residual `sigma` formula
  and independent residual-scale random slopes written as `(0 + x | id)` are
  also implemented, and matching labelled `mu`/`sigma` random intercepts now
  fit one or more independent univariate mean-scale covariance blocks.
  Random-effect scale formulae are implemented for one or more distinct
  unlabelled Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and
  `sd(site) ~ site_type`.
  The bivariate Gaussian path now fits matched labelled `mu1`/`mu2`,
  `sigma1`/`sigma2`, one or more same-response `mu`/`sigma` random-intercept
  covariance blocks.
- The R-side labelled covariance block registry now records the implemented
  two-member `mu`, `sigma`, and `mu`/`sigma` bridges without changing accepted
  syntax or fitted behaviour. It also carries a dormant TMB-shaped block data
  contract for those bridges. `corpairs()` now derives covered group-level
  rows from the registry, with legacy label parsing as a compatibility
  fallback, and `check_drm()` derives covered covariance diagnostics from
  registry members while preserving current diagnostic rows. `profile_targets()`
  derives covered random-effect correlation targets from registry pairs while
  preserving target names and indices. The design contract remains
  `docs/design/30-labelled-covariance-block-assembler.md`; the two-member
  dormant contract now crosses the C++ boundary as a no-op visibility check.
  The registry can internally enumerate all pair rows for a guarded
  three-member block, but marks that scaffold unimplemented and still blocks
  TMB export for `q > 2`. Larger shared labels still need simulation recovery
  and a positive-definite `q > 2` likelihood path before exposure. Internal TMB
  probes now confirm that `UNSTRUCTURED_CORR_t` plus `VECSCALE_t` can produce a
  positive-definite q=3 correlation, finite objective/gradient, a non-centered
  `sqrt_cov_scale()` transform, a hidden registry-shaped member/group
  contribution map using a dormant TMB parameter, an internal Laplace
  random-effect boundary for that probe parameter, a hidden Gaussian likelihood
  prototype that routes q=3 member contributions into `mu` and `log_sigma`, and
  a hidden Laplace version of that likelihood prototype. A deterministic
  hidden simulation-style check now verifies that this path can recover the
  simulated q=3 predictor signal better than a no-random-effect baseline. The
  first ordinary bivariate q=4 random-intercept block now routes
  `mu1`/`mu2`/`sigma1`/`sigma2` member contributions through the fitted
  bivariate Gaussian path. It reports all six endpoint rows through
  `corpairs()` and `summary(fit)$covariance`: one `mu1`-`mu2` row, four
  mean-scale rows (`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and
  `mu2`-`sigma2`), and one `sigma1`-`sigma2` row. `profile_targets()` can
  format the matching six endpoint correlation targets, while q=4 intervals
  remain direct-correlation or derived-row work rather than a closed
  double-hierarchical endpoint. Dormant q=3 scaffolds, q > 4 blocks, and q=6 or
  q=8 random-slope endpoint blocks remain invisible to ordinary
  extractor/profile output. The corresponding constant phylogenetic q=4 state
  is now fitted for matching labelled all-four `phylo()` terms, including the
  two-label block-diagonal fallback that separates `mu1`/`mu2` and
  `sigma1`/`sigma2` tree blocks. The next phylogenetic work is recovery
  evidence, diagnostics, and tutorial hardening. q=6 and q=8 random-slope
  endpoint blocks can wait.
- Use `docs/design/18-random-effect-scale-models.md` as the design contract:
  the implemented MVP targets one or more distinct unlabelled univariate
  Gaussian `mu` random intercepts, with group-level predictors, simulation
  recovery tests, and an `lme4` overlap test.
- Extend random-effect scale models beyond unlabelled intercept targets, such
  as slope-specific, labelled-block, bivariate, and non-Gaussian targets.
- Respect labelled correlated group syntax such as `(1 + x | p | id)` when
  scale and bivariate random-effect paths are added.
- Ordinary grouped random-slope boundary: the univariate Gaussian `mu` path now
  accepts blocks such as `(1 + x1 + x2 | id)` as unstructured covariance blocks
  with SD/correlation summaries, profile targets for the SDs, recovery tests
  for the q=3 path, and explicit derived-unavailable status for q > 2 direct
  correlation profile intervals. This is the ordinary location-model
  compatibility boundary with `lme4`/`glmmTMB` syntax. Larger q blocks remain
  advanced and sample-size hungry until Phase 18 quantifies convergence,
  boundary, bias, and interval failure rates. With `q` coefficients in a block,
  the fitted surface has `q` SDs and `q * (q - 1) / 2` constant correlations.
- One-slope baseline policy: every random-effect layer that `drmTMB` supports
  should eventually accept at least one numeric random slope, or report an
  explicit unsupported status and fallback. During the first expansion,
  slope-related random-effect correlations are constant block hyperparameters,
  not modelled formulae. This cap does not remove the separate
  predictor-dependent `corpair()` lane for intercept-level group,
  phylogenetic, or future spatial correlations when those likelihoods and
  recovery tests are implemented.
- Cross-distributional-parameter correlation gate: keep residual `rho12`,
  ordinary group-level covariance, structured covariance, and known sampling
  covariance `V` as separate layers. Current fitted correlation surfaces are
  Gaussian-heavy and mostly constant block correlations, with special
  predictor-dependent routes for residual `rho12` and q=2 intercept-level
  `corpair()` models. Random effects in `rho12`, non-Gaussian covariance among
  `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`, or `nu`, slope-level
  cross-parameter covariance, and mixed-distribution bivariate covariance stay
  outside Phase 18 Wave A until their focused gates close.
- Add variance-component correlation summaries when identifiable.

## Phase 5: Animal, Phylogenetic, Spatial, and Known-Dependence Effects

- Status: first univariate Gaussian phylogenetic, coordinate-spatial,
  animal-model, and `relmat()` structured intercepts are implemented for `mu`
  and `sigma`, including matching univariate `mu`/`sigma` latent structured
  correlations. First matching bivariate `mu1`/`mu2` phylogenetic, spatial,
  animal, and `relmat()` location slices and constant q=4 location-scale
  covariance blocks are fitted where documented. Sparse large-pedigree
  construction, residual-scale structured slopes, predictor-dependent
  structured `corpair()` regressions, and generic direct-SD grammar remain
  planned.
- Teach structural dependence in the biological order readers are likely to
  ask for it: animal models first, then phylogenetic dependence, then spatial
  dependence, then combined phylogenetic-spatial layers, with lower-level
  `relmat()` reserved for other validated known-dependence matrices. The common
  mathematical module is `z ~ MVN(0, sigma_z^2 K)`, with `K = A_ped` for
  additive pedigree or animal relatedness, `K = A_phylo` for phylogeny, `K = M`
  for spatial dependence, and `K = K_user` for a validated user-supplied
  relatedness matrix.
- Add sparse known-covariance infrastructure beyond the current phylogenetic
  A-inverse path, especially for large known sampling covariance, spatial
  precision matrices, and combined phylogenetic-spatial meta-analysis.
- Reserve animal-model and generic known-relatedness syntax as siblings of
  `phylo()` and `spatial()`, not as new response families:
  `animal(1 | id, pedigree = ped)`, `animal(1 | id, A = A)`,
  `animal(1 | id, Ainv = Ainv)`, and a lower-level
  `relmat(1 | id, K = K)` or `relmat(1 | id, Q = Q)` escape hatch. Treat
  `relmat()` as the public replacement for deprecated `gr()`-style low-level
  wording rather than teaching both names. Keep `V` for known
  sampling covariance in the preferred `meta_V(V = V)` design; do not
  reuse `V` for additive genetic or phylogenetic relatedness.
- Keep animal-model examples grounded in eco-evo questions rather than
  matrix-only demonstrations: heritable trait means in a wild pedigree,
  additive genetic variance in behavioural predictability or residual scale,
  and bivariate genetic covariance/evolvability examples are higher-value
  teaching targets than an abstract `A` matrix smoke test.
- Implemented `phylo(1 | species, tree = tree)` for univariate Gaussian `mu`
  using an ultrametric branch-length tree, the sparse augmented A-inverse path,
  one CRAN-safe simulation recovery test, and dense marginal likelihood
  comparator tests.
- Implemented matching intercept-only `phylo(1 | species, tree = tree)` terms
  in bivariate Gaussian `mu1` and `mu2`, estimating two phylogenetic location
  SDs and one phylogenetic mean-mean correlation while leaving `sigma1`,
  `sigma2`, and residual `rho12` as ordinary fixed-effect distributional
  parameters. `corpairs()` reports that first fitted phylogenetic mean-mean
  row, `summary(fit)$covariance` reports the matching variance and covariance
  point summaries, and `check_drm()` reports near-boundary `corpars$phylo`,
  weak phylogenetic-SD diagnostics, and ordinary same-species covariance
  overlap for that fitted slice. A CRAN-safe deterministic simulation now
  recovers a positive bivariate phylogenetic mean-mean correlation.
- Full-species Ayumi stress tests keep the bivariate q2 phylogenetic path in a
  cautious lane. The aggregate all-species q2 phylogenetic source fit
  converges, but row-capped all-species q2 targets still false-converge with
  residual `rho12` at the boundary under default starts, source-fit starts, and
  modest covariance jitter. Treat those runs as convergence and identifiability
  evidence, not as tutorial-ready biological inference. Larger data helps only
  when it adds information that separates residual covariance from structured
  species covariance.
- The corrected Ayumi Issue #1 Mass + Beak PV2 rerun is the real-data anchor:
  `Mass_z` is response 1 and `Mass_cov_z` is the fixed allometric covariate for
  Beak. The q2 location-only phylogenetic model converges cleanly on 6,196
  species with residual `rho12 = -0.789` and phylogenetic `mu1`-`mu2 = -0.841`.
  The prereg phylogenetic fallback now fits as separate q2 location and scale
  blocks, but the Ayumi Mass + Beak fit is still false-converged with
  `pdHess = FALSE`; its scale-scale phylogenetic correlation is essentially
  `-1`. A 10-core developer bootstrap smoke (`B = 10`) refitted all replicates
  but retained convergence code 1 in every replicate, so the fallback remains
  diagnostic rather than tutorial-ready inference. The all-four q4 PV2-main
  model can be optimized with `se = FALSE`, but it remains boundary-heavy and
  false-converged, so it belongs in the diagnostic ledger until restart,
  simplification, or bootstrap evidence stabilizes it. A developer-only
  parallel bootstrap prototype now supports serial, `multicore`, and `psock`
  refits for this Mass + Beak target and clamps requested cores to at most 10.
  A first fallback simplification that removed climate predictors from
  `sigma1` and `sigma2` still false-converged with `pdHess = FALSE`, worse AIC,
  and scale-scale phylogenetic correlation near `-1`, so the boundary is not
  solved by intercept-only scale formulas. The positive-control
  `PV2_locphylo` bootstrap using the same 10-core diagnostic script refitted all
  ten replicates with convergence 0 and small gradients, so the clean
  location-only phylogenetic model remains the demonstration path.
- The first spatial fitted paths are now `spatial(1 | site, coords = coords)`
  and `spatial(1 + x | site, coords = coords)` in univariate Gaussian `mu`.
  They use a fixed exponential coordinate covariance as a small-data foundation.
  The one-slope path estimates independent intercept and slope fields that share
  the coordinate precision, with separate SDs and no intercept-slope
  correlation. `sdpars$mu`, `ranef("spatial_mu")`, `profile_targets()`, and
  `check_drm()` expose those fields with spatial names. Phase 18 now has a
  smoke surface for the coordinate spatial one-slope path, covering seeded DGP,
  fit, parameter summaries, aggregate output, manifest, and failure ledger.
  Matching bivariate q=2 spatial location and constant q=4 spatial
  location-scale blocks now use the same coordinate foundation and report through
  `corpairs(level = "spatial")`. Ordinary Poisson/NB2 now also fit q=1
  spatial `mu` intercepts. Mesh/SPDE, multiple spatial slopes, spatial slope
  correlations, standalone spatial `sd(...)`, spatial `corpair()`
  regressions, count spatial slopes, and zero-inflated spatial effects remain
  planned.
- For bivariate structured models, estimate and report level-specific
  correlations separately: residual `rho12`, phylogenetic correlations,
  non-phylogenetic species correlations, spatial field correlations, and
  ordinary grouped random-effect correlations should not share one namespace.
- The first fitted phylogenetic q=4 location-scale block now shares the same
  matrix-normal prior algebra used by the hidden q=4 scaffold: `mu1`, `mu2`,
  `sigma1`, and `sigma2` effects are stored endpoint-major, with four
  phylogenetic SDs and six unstructured latent correlations. `corpairs()` and
  `summary(fit)$covariance` report all six phylogenetic endpoint rows, while
  `profile_targets()` marks those q=4 correlations as derived `theta_phylo`
  targets rather than direct profile-ready atanh targets. A CRAN-safe recovery
  test now checks broad fixed-effect, SD, residual-correlation, finite-gradient,
  and q=4 diagnostic behavior. The block-diagonal q=4 fallback uses the same
  endpoint-major latent vector but a block-diagonal covariance, so `corpairs()`
  reports only the `mu1`-`mu2` and `sigma1`-`sigma2` phylogenetic rows and
  `profile_targets()` treats those two correlations as direct tanh targets.
  Direct means "can be attempted," not "interval-proven" for every dataset: a
  full-species Ayumi bounded profile for the fallback mean-mean phylogenetic
  correlation took about 512 seconds and still failed to extract a 95% interval.
- The univariate Family B `sd_phylo(species) ~ x_species` path is implemented:
  it uses a non-centred unit tree effect, multiplies only observed tip
  contributions by species-level `tau_l = exp(W_l alpha)`, and interprets the
  marginal tip covariance as `D_tip A_tip D_tip`. `check_drm()` now reports
  direct-SD diagnostic rows covering species replication and the fitted
  species-level SD surface range. The bivariate design target is
  now implemented as response-specific location-only direct-SD regression:
  `sd_phylo1()` for the `mu1` phylogenetic location effect, `sd_phylo2()` for
  the `mu2` effect, a constant latent phylogenetic location-location
  correlation, and no mixing with all-four q=4 phylogenetic location-scale
  blocks. `check_drm()` now reports the fitted direct-SD surface range and
  species replication for each univariate or bivariate `sd_phylo*()` endpoint.
- Use the correlation-pair design in
  `docs/design/20-coscale-correlation-pairs.md` before implementing bivariate
  double-hierarchical covariance blocks; pair outputs should identify the
  level, group, block, distributional parameters, responses, and coefficients.
- The first `corpairs()` extractor is implemented for currently fitted
  correlations only: residual `rho12`, ordinary group-level `mu` random-effect
  correlations, the univariate `mu`/`sigma` mean-scale random-intercept
  correlation, and the bivariate `mu1`/`mu2` and `sigma1`/`sigma2`
  random-intercept correlations, plus the fitted bivariate phylogenetic
  mean-mean correlation and all six fitted phylogenetic q=4 endpoint
  correlations when that block is present.
  Extend this table as new correlation likelihoods are added.
- Stage structured phylogenetic and spatial slopes conservatively:
  intercept-only structured effects first, then one `mu` slope, then at most two
  structured `mu` slopes as an advanced path after simulation recovery. Multiple
  random factors should enter as separate additive blocks. Intercept-slope
  `corpair()` rows are distant-future; the more biologically interesting later
  target is a bivariate slope1-slope2 correlation for the same covariate, a
  plasticity-syndrome style model.
- Structured-dependence random-slope boundary: do not claim phylogenetic/spatial
  slope parity until each structured layer has at least one fitted Gaussian
  `mu` random slope with SD summaries, direct profile targets, diagnostics, and
  simulation recovery. The coordinate spatial path has this first one-slope
  baseline; the phylogenetic path does not yet.
- Keep structured-effect correlations constant during the one-slope baseline.
  Do not add predictor-dependent phylogenetic or spatial slope correlations
  until the fixed-correlation one-slope paths recover reliably. This does not
  block predictor-dependent intercept-level structured correlations that
  already have their own `corpair()` design.
- Continue adding identifiability diagnostics for replication by study,
  species, location, and effect-size levels before complex structured models
  are promoted. The first spatial `mu` diagnostic is implemented for the
  coordinate path; mesh/SPDE diagnostics remain tied to the future mesh gate.
- Selectively reuse GPL-compatible ideas or modules from `gllvmTMB` with
  provenance notes and tests.

Phase 5 closure boundary:

| Layer | Implemented before spatial expansion | Still planned |
| --- | --- | --- |
| univariate phylogenetic | `phylo(1 | species, tree = tree)` in Gaussian `mu` and/or `sigma`, matching `mu`/`sigma` structured correlation, one numeric `mu` slope, `sd_phylo(species) ~ z`, profile targets and diagnostics | multiple phylogenetic slopes, residual-scale structured slopes, slope correlations, direct-SD formulas combined with structured `sigma`, and richer tree-shape recovery grids |
| bivariate phylogenetic | matching `mu1`/`mu2` phylogenetic location correlation, constant full and block-diagonal q=4 location-scale blocks, q=2 predictor-dependent `corpair(..., level = "phylogenetic") ~ w`, bivariate `sd_phylo1()` / `sd_phylo2()`, and Ayumi q2/q4 stress artifacts | q=4 predictor-dependent location-scale and scale-scale `corpair()` regressions; broader predictor-dependent structured scale-scale covariance is not a near-term priority |
| coordinate spatial | `spatial(1 | site, coords = coords)` in univariate Gaussian `mu` and/or `sigma`, matching univariate `mu`/`sigma` structured correlation, one numeric `mu` slope, matching bivariate `mu1`/`mu2` q=2 covariance, constant all-four q=4 location-scale covariance with `corpairs(level = "spatial")`, and ordinary Poisson/NB2 q=1 `mu` intercepts; `sdpars`, marker-specific `ranef()` blocks, profile targets, and `check_drm()` rows expose the fitted fields | mesh/SPDE, multiple spatial slopes, residual-scale structured slopes, spatial slope correlations, spatial direct-SD, spatial `corpair()`, count spatial slopes, and zero-inflated spatial effects |
| animal and user-supplied relatedness | Gaussian `mu` and `sigma` intercepts for `animal(1 | id, pedigree/A/Ainv = ...)` and `relmat(1 | id, K/Q = ...)`, matching univariate `mu`/`sigma` structured correlations, one numeric `mu` slope, matching labelled `mu1`/`mu2` q=2 location covariance, constant all-four q=4 location-scale covariance, and ordinary Poisson/NB2 q=1 `mu` intercepts with `corpairs()`, `summary()$covariance`, profile-target status, diagnostics, and dense-likelihood tests where relevant | sparse large-pedigree construction, multiple structured slopes, residual-scale structured slopes, slope correlations, predictor-dependent `corpair()` regressions, optional `phylo(..., A/Ainv = ...)` input, animal/`relmat()` count slopes or labels, and generic direct-SD naming design |
| inference/output | fixed-effect SEs, direct profile-ready targets where implemented, `corpairs(conf.int = TRUE)` with explicit interval status | derived-profile intervals for q=4 correlations and richer marginal-effect/visualization helpers |

Spatial parity now has its own ladder. The smallest missing phylogenetic
sibling has landed for the constant q=2 location layer:
coordinate-spatial bivariate location covariance for `mu1` and `mu2`, with
`corpairs(level = "spatial")`, direct profile-target labels, recovery evidence,
and a dense covariance comparator. Constant all-four spatial q=4 location-scale
blocks have since landed as fitted extractor/diagnostic smoke, with derived
q=4 correlation intervals explicitly unavailable. Mesh/SPDE, multiple spatial
slopes, residual-scale structured slopes, spatial direct-SD surfaces, spatial
`corpair()` regression, count spatial slopes or labels, and zero-inflated
spatial effects remain behind their own evidence gates.

## Phase 5b: Large-Data Memory Strategy

- Status: first storage controls and benchmark harness implemented; Phase 5b
  now hardens those controls for newer structured-effect surfaces. The first
  sparse fixed-effect path is implemented, and the first opt-in Gaussian
  aggregation path is fitted for repeated univariate Gaussian fixed-effect
  rows. Broader sparse matrices, broader aggregation, and repeated
  million-row benchmarks remain planned.
- `drm_control()` now supports optimizer settings plus the first memory-light
  fitted-object controls: `keep_data = FALSE`,
  `keep_model_frame = FALSE`, and `keep_tmb_object = FALSE`.
- `keep_model_frame = FALSE` now also drops nested direct-SD and fitted
  `corpair()` model-frame caches after their model matrices and group metadata
  have been retained.
- `check_drm()` now reports the density of the largest retained fixed-effect
  design block, giving users a concrete sparse-design signal before
  `sparse_fixed` is implemented.
- Internal dense-versus-sparse fixed-effect matrix parity helpers now compare
  `stats::model.matrix()` with `Matrix::sparse.model.matrix()` before any
  sparse fit path is exposed.
- `drm_control(sparse_fixed = TRUE)` now fits the first sparse fixed-effect
  path for univariate Gaussian `mu` fixed effects with intercept-only `sigma`,
  no random effects, no structured effects, and no known covariance.
- The optional large-data benchmark now records the largest fixed-effect design
  block, column count, nonzero count, and density.
- The same benchmark harness now records `structured` and `sparse_fixed`
  settings and can run a non-phylogenetic sparse fixed-effect smoke scenario
  with `--structured none --factor-heavy true --sparse-fixed true`.
- `drm_control(aggregate_gaussian = TRUE)` now fits the first
  sufficient-statistic aggregation path for univariate Gaussian fixed-effect
  models with repeated processed `mu` and `sigma` design rows. Random effects,
  direct-SD formulas, structured effects, known sampling covariance, bivariate
  models, non-Gaussian families, non-unit weights, and combined sparse fixed
  effects remain planned.
- The benchmark harness can run a non-phylogenetic repeated-cell aggregation
  smoke scenario with
  `--structured none --aggregate-gaussian true --aggregation-cells 100`.
- Extend memory-light fit controls for large phylogenetic and spatial
  datasets with broader method-matrix coverage, sparse fixed-effect matrices,
  aggregation, and repeated large-row benchmarks.
- Extend sparse fixed-effect matrix support beyond the first univariate
  Gaussian `mu` path before claiming million-row readiness.
- Use `docs/design/26-sparse-fixed-effect-matrices.md` as the implementation
  contract for sparse fixed-effect matrices.
- Extend aggregation or sufficient-statistic paths beyond the first univariate
  Gaussian fixed-effect route where repeated rows can be collapsed without
  changing the likelihood.
- An initial non-CRAN benchmark harness exists at
  `bench/large-phylo-location.R`; use it to record 100k, 500k, 1M, and 5M
  observation-row runs with 1k-10k species as the implementation matures.
- Treat the sparse A-inverse phylogenetic path and large-row memory path as
  separate scaling problems.

## Phase 6: Profile-Likelihood Inference

- Status: closure-audited for the scoped direct-profile inference surfaces.
- Tracking issue: [#30](https://github.com/itchyshin/drmTMB/issues/30).
- `profile_targets(fit)` lists the current target names and readiness notes for
  confidence-interval and profile-likelihood work, including the first
  bivariate phylogenetic `mu1`/`mu2` SD and correlation targets.
- The target inventory uses a controlled namespace for `target_type`,
  `profile_ready`, `profile_note`, and `transformation`. A row is
  `profile_ready` only when it is direct and the fitted object retained the TMB
  object; memory-light fits report `profile_note = "tmb_object_required"`.
- `confint(fit)` now returns Wald fixed-effect intervals, and
  `confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit
  direct fixed-effect, constant `sigma`/`sigma1`/`sigma2`, ordinary
  random-effect SD, ordinary random-effect correlation, phylogenetic `mu` SD,
  bivariate phylogenetic `mu1`/`mu2` correlation, and constant residual `rho12`
  targets.
- `confint(fit, parm = "sigma", method = "profile", newdata = grid)` and
  `confint(fit, parm = "rho12", method = "profile", newdata = grid)` profile
  row-specific response-scale `sigma` and residual-correlation values by
  profiling the fixed-effect linear predictor for each supplied row. The same
  row-specific route is now covered for `sigma1`, `sigma2`, and fitted q=2
  ordinary or phylogenetic `corpair()` values; ambiguous `newdata` requests are
  rejected before profile optimization.
- The model-workflow article now shows the profile-example boundary directly:
  constant `sigma` uses a fitted-object target, predictor-dependent `sigma`,
  `sigma1`, `sigma2`, and `rho12` use supplied `newdata` rows, and
  random-effect SD/correlation examples copy exact target names from
  `profile_targets()`.
- Direct covariance profile intervals are implemented for the first univariate
  `mu`/`sigma` random-intercept correlation target, the first bivariate
  `mu1`/`mu2` random-intercept correlation target, and the first bivariate
  phylogenetic `mu1`/`mu2` mean-mean correlation target. These intervals are
  available through both `confint(..., method = "profile")` and
  `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`.
- Direct profile calls now wrap `TMB::tmbprofile()` failures with the
  `profile_targets()` target name and block attempts to override the internal
  `obj`, `name`, `lincomb`, or `trace` arguments through `...`.
- The interval-readiness gate now keeps q4 derived correlations and covariance
  products explicitly unavailable for intervals, rejects unsupported bootstrap
  interval method requests before interval work begins, and checks that returned
  interval status/source values stay inside the current shared vocabulary.
- Extend profile-likelihood confidence intervals to additional direct TMB
  parameters such as other residual-scale parameters, ordinal cutpoints, and
  multi-row or custom contrasts beyond one `newdata` row at a time.
- Use user-facing target names from the fitted object, for example
  `sd:mu:(1 | id)`, `sd:mu:phylo(1 | species)`,
  `sd:mu:mu1:phylo(1 | species)`,
  `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`,
  `cor:mu:cor((Intercept),x | id)`,
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`,
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`,
  `fixef:rho12:(Intercept)`, and `sigma` or `rho12`.
- Prefer `TMB::tmbprofile()` plus `uniroot()` for one-dimensional intervals,
  because it warm-starts constrained optimizations and avoids wasteful grids.
- Support linear combinations through TMB's `lincomb` machinery where possible.
- Treat nonlinear derived quantities, such as ICCs, repeatability,
  phylogenetic signal, and variance-component correlations, as a later
  fix-and-refit problem with boundary and convergence flags.
- Keep parametric bootstrap as a fallback for boundary, non-monotone, or failed
  inner-optimization cases.

Phase 6 should now be closed through small inference slices rather than one
large confidence-interval rewrite:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 51 | Profile issue and target audit | Create the Phase 6 tracking issue, audit fitted `profile_targets()`, `confint()`, `summary(conf.int = TRUE)`, and `corpairs(conf.int = TRUE)` support, and record direct versus derived boundaries. | GitHub issue, design note, check-log, and after-task note agree. |
| 52 | Target namespace cleanup | Stabilize user-facing target names, transformations, `target_type`, `profile_ready`, and unavailable-status wording. | Target inventory tests cover representative fitted classes. |
| 53 | Direct profile robustness | Harden direct `TMB::tmbprofile()` wrappers, one-target-only errors, and failed-profile messages. | Direct profile tests cover success and clear failure paths. |
| 54 | Response-scale row profiles | Extend and test `newdata` profile intervals for `sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q2 `corpair()` rows. | Done: row-specific intervals transform back to response scales and ambiguous inputs are rejected. |
| 55 | Random-effect SD and correlation intervals | Stabilize direct profile intervals for currently fitted ordinary, phylogenetic, and spatial random-effect SD/correlation targets. | Done: `summary()` and `corpairs()` attach intervals only to profile-ready rows, while modelled and q4 derived rows keep explicit unavailable statuses. |
| 56 | Derived-target status | Make q4 correlations, ICCs, repeatability, phylogenetic signal, and other nonlinear summaries explicit point-estimate or unavailable-CI targets. | Done: simple Gaussian repeatability and phylogenetic-signal rows are reported as derived variance-ratio targets, and unsupported derived intervals fail or report unavailable status before expensive profiling. |
| 57 | Output integration | Align interval columns and status values across `summary()`, `corpairs()`, `confint()`, and `profile_targets()`. | Done: `conf.status` is now part of successful `confint()` rows and interval-aware `summary()` tables, with contract tests for returned and printed parameter tables. |
| 58 | Inference diagnostics | Add diagnostics for boundary, near-correlation-limit, non-monotone, and failed inner-optimization profiles. | Done: profile interval rows carry `profile.boundary` and `profile.message`, and failed profile errors name boundary, one-sided, non-monotone, and failed-inner-optimization possibilities. |
| 59 | Profile inference docs | Update profile-CI design, known limitations, tutorials, and NEWS for any user-facing behavior changes. | Done: README, known limitations, model workflow, model map, bivariate, phylogenetic-spatial, and profile-CI design prose teach `conf.status`, `profile.boundary`, and `profile.message` without claiming derived q4 intervals. |
| 60 | Phase 6 gate | Run focused tests, full package tests when practical, pkgdown checks, after-phase audit, PR, and GitHub Actions. | Done when this gate PR has green local checks, an after-phase report, pkgdown evidence, and GitHub Actions. |

## Phase 6b: Tutorial Quality Upgrade

- Tracking issue: [#31](https://github.com/itchyshin/drmTMB/issues/31).
- Use `docs/design/21-tutorial-style.md` as the tutorial contract.
- Jason should source-map the tutorial examples the project owner provided,
  including location-scale meta-analysis, phylogenetic location-scale, ecology
  location-scale, phylo-spatial, multinomial GLMM, phylogenetic simulation, and
  `glmmTMB::equalto()` examples.
- Pat should user-test each major `drmTMB` tutorial for a concrete question,
  real or transparent simulated data, symbolic equations, model output,
  plots or tables, interpretation, diagnostics, and recovery advice.
- Add more symbolic maths and detailed biological interpretation to each major
  tutorial before calling the tutorial layer mature. The reader should see the
  model equation, the `drmTMB` syntax, the fitted output, and the biological
  meaning together.
- Upgrade the first tutorials in this order: Gaussian location-scale,
  bivariate location-coscale, meta-analysis, phylogenetic location effects,
  and random-effect scale models.

Phase 6b should turn the implemented surfaces into a coherent reader path:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 61 | Tutorial issue and source map | Create the Phase 6b tracking issue and compare current tutorials with `docs/design/21-tutorial-style.md` and project-owner example priorities. | Done: `docs/design/32-phase-6b-tutorial-source-map.md` maps the tutorial fixes and adds the biological and mathematical interpretation contract for slopes, variance components, `sd(group)`, `rho12`, and `corpairs()` rows. |
| 62 | Tutorial landing path | Improve pkgdown navigation from scientific question to tutorial to reference page. | Done: Getting Started and the model map now share a question-first path from scientific phrase to tutorial, guide, or reference workflow. |
| 63 | Gaussian location-scale polish | Tighten the question, equation, runnable model, fitted output, interpretation, diagnostics, and plot/table guidance. | Done: the Gaussian tutorial now separates fixed mean slopes, fixed residual-scale slopes, random-slope SDs, residual-scale random-slope SDs, and random-effect scale slopes. |
| 64 | Bivariate coscale polish | Make residual `rho12`, `sigma1`/`sigma2`, response-scale interpretation, and intervals easier to read. | Done: the bivariate tutorial now reads `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` slopes as separate biological claims and keeps residual `rho12` distinct from group-level `corpairs()` rows. |
| 65 | Meta-analysis polish | Clarify `meta_known_V(V = V)`, ordinary weights, residual `sigma`, and unsupported combinations. | Done: the meta-analysis tutorial now names known sampling variance, fitted extra heterogeneity SD, heterogeneity variance, and total observation variance as different report scales. |
| 66 | Structural-dependence polish | Refine phylogenetic and spatial examples, mesh/coords guidance, citation notes, and fitted-versus-planned status. | Done: the structural-dependence tutorial now gives a six-row q=4 phylogenetic interpretation table and keeps mesh/SPDE, multiple spatial slopes, q=4 extensions, and derived intervals visibly planned. |
| 67 | Random-effect scale and covariance tutorial | Explain `sd(group)`, `sd(..., level = ...)`, Family A versus Family B, `corpairs()`, and invalid mixed formulations. | Done: the scale guide now explains Family A versus Family B, current `sd_phylo()` naming, the future `sd(..., level = ...)` idea, and invalid mixed formulations. |
| 68 | Phase 6b gate | Run Pat/Rose tutorial audit, pkgdown build/check, stale-wording scan, NEWS/roadmap updates, PR, and GitHub Actions. | Done locally: pkgdown build/check and stale-claim scans passed; GitHub Actions remains the PR-side gate after push. |

## Phase 6c: Random Slopes and Structured-Slope Examples

- Tracking issue: [#33](https://github.com/itchyshin/drmTMB/issues/33).
- Treat Phase 6c as the random-slope bridge between the Phase 6 inference work,
  the Phase 6b tutorial layer, and the later Phase 10-12 structural-dependence
  programmes. It does not replace the later bivariate covariance programme; it
  records the slope policy and should implement only the first slope paths that
  have simulation recovery and readable output.
- Start with one structured `mu` slope for each relevant dependence layer:
  ordinary grouped effects as the baseline, then phylogenetic effects, then
  spatial effects. Design for up to two structured `mu` slopes as an advanced
  path if diagnostics and recovery remain stable.
- Keep three or more structured slopes outside the advertised near-term path.
  The covariance dimension grows quickly, so these models should remain
  distant-future expert use.
- Do not estimate intercept-slope correlations in the first slope path.
  Intercept-slope correlations should still be part of the Phase 6c inference
  roadmap as an advanced, diagnostic-heavy path once the one-slope point
  estimates and recovery tests are stable.
- Include profile-likelihood CI planning for slope quantities. The first
  interval targets should be random-slope SDs and any slope-related
  correlations that are direct, identifiable TMB targets. Derived or weakly
  identified slope correlations should report explicit unavailable-status rows
  in `profile_targets()` or `corpairs()` until a supported interval method
  exists.
- A later high-value biological target is the bivariate slope1-slope2
  correlation for the same environmental covariate, such as a plasticity
  syndrome across species or individuals. This should eventually include both
  point estimates and profile-likelihood intervals where the target is direct
  and recovery evidence is good.
- Phase 6c examples should include symbolic maths, `drmTMB` syntax, output
  interpretation, and biological examples. Good first examples include thermal
  tolerance plasticity along temperature, desiccation tolerance along humidity,
  or behavioural reaction norms along disturbance.
- Core ordinary grouped status: the random-intercept, one-slope, and q > 2
  ordinary Gaussian `mu` baseline is
  now recorded in `docs/design/33-phase-6c-core-random-effects.md`. The fitted
  core covers ordinary Gaussian `mu` random intercepts, independent `mu`
  random slopes, ordinary correlated intercept-slope blocks, ordinary
  unstructured numeric multi-slope `mu` blocks, residual-scale random
  intercepts and independent residual-scale slopes, matching labelled
  `mu`/`sigma` random-intercept covariance, and direct `sd(group)` models for
  unlabelled Gaussian `mu` random intercepts. The first coordinate spatial
  slope is now implemented in Phase 10; phylogenetic slopes and richer
  structured-slope paths remain later work for Phases 10 and 12.
- Closure boundary: Phase 6c now includes the ordinary grouped q > 2 Gaussian
  `mu` block path, with q=3 recovery and extractor coverage. Larger ordinary
  blocks remain advanced, sample-size hungry fits. Structured random slopes
  are handed to Phases 10 and 12; `spatial(1 + x | site, coords = coords)` now
  fits the first coordinate spatial one-slope `mu` path, but
  `phylo(1 + x | species, tree = tree)` still does not fit.

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 69 | Random-slope issue and math contract | Create/maintain the Phase 6c issue, write the ordinary/phylogenetic/spatial one-slope equations, and fix coefficient naming rules. | Done for the ordinary grouped core: `docs/design/33-phase-6c-core-random-effects.md` records the symbolic equations, syntax, output rows, and stable/planned boundary. |
| 70 | Ordinary one-slope baseline | Stabilize ordinary grouped `mu` one-slope syntax, extractor labels, `corpairs()` coefficient columns, and profile-target names. | Done for the ordinary core: tests cover independent and correlated one-slope `mu` blocks, labelled `(1 + x | p | ID)` names, the `mean-slope` `corpairs()` row, and direct profile-target names. |
| 71 | Phylogenetic one-slope design and fit | Extend `phylo()` from intercept-only `mu` to one structured `mu` slope after the algebra and storage order are explicit. | Superseded by Slices 39-82: `phylo(1 + x | species, tree = tree)` is fitted for univariate Gaussian `mu` with independent intercept and slope fields, direct SD targets, diagnostics, and focused recovery evidence. |
| 72 | Spatial one-slope design and fit | Extend `spatial()` from intercept-only `mu` to one structured `mu` slope after coordinate/mesh diagnostics are clear. | Done for the coordinate path: Phase 10 fits `spatial(1 + x | site, coords = coords)` as independent intercept and slope fields with separate SDs, direct profile targets, `ranef()` terms, and simulation evidence. Mesh slopes remain planned. |
| 73 | One-slope diagnostics and inference | Add replication, weak-SD, boundary, profile-target, and profile-likelihood CI diagnostics for fitted one-slope paths. | Done for the ordinary core, first coordinate-spatial slope, and first phylogenetic/animal/relmat one-slope routes: tests cover weak random-slope design, boundary SDs, ordinary random-slope SD targets, intercept-slope correlation targets where fitted, and structured one-slope direct SD targets. |
| 74 | Slope-correlation advanced gate | Design two-slope models, intercept-slope correlations, and bivariate slope1-slope2 correlations without advertising them as routine. | Done for the ordinary core: the source map names the required coefficient-aware `corpair()` syntax, `corpairs()` rows, direct-target interval status, and recovery evidence before bivariate slope correlations are fitted or taught. |
| 75 | Biological examples | Add tutorial examples for reaction norms and bivariate plasticity-syndrome questions, including how to read slope SDs, slope correlations, and interval/status columns. | Done for the ordinary core: the location-scale tutorial now gives a thermal reaction-norm example with fixed slope, random-intercept SD, random-slope SD, group-level intercept-slope correlation, and `profile_targets()` interpretation. Full structured-slope examples wait until Phases 10-13 settle. |
| 76 | Phase 6c gate | Run focused tests, pkgdown checks, after-phase audit, PR, and GitHub Actions. | Done locally for the Phase 6c core: focused tests, pkgdown build/check, stale-claim scans, check-log entry, and after-phase report are complete. GitHub Actions remains the PR-side gate. |

## Phase 6d: Stable-Core Validation and Engine Hardening

- Tracking issue: [#38](https://github.com/itchyshin/drmTMB/issues/38).
- Local closure: Phase 6d is locally closed as of 2026-05-15 with focused
  tests, full package tests, pkgdown build/check, `R CMD check`, stale-claim
  scans, check-log evidence, and the after-phase report
  `docs/dev-log/after-phase/2026-05-15-phase-6d-stable-core-hardening-closure.md`.
  GitHub Actions remains the PR-side gate.
- Treat Phase 6d as the audit-response lane. It should not distract from the
  current profile-CI slices, but it records the cross-cutting work needed before
  `drmTMB` expands too far into new families, broad spatial claims, or
  high-dimensional random-effect structures.
- Add a stable-core matrix for the README, model-map, and pkgdown site. The
  table should make clear which surfaces are stable, which are fitted first
  slices, which are opt-in controls, which are parsed but rejected, which are
  documentation-only roadmap items, and which have profile-likelihood interval
  support.
- Maintain a validation-debt register that links each advertised model surface
  to simulation recovery, malformed-input tests, diagnostics, profile/CI status,
  documentation, and check-log evidence.
- Add failure-safe standard-error handling. A future `se = FALSE` or equivalent
  control should let a useful fit exist without forcing `TMB::sdreport()`, and
  failed standard-error calculations should store an `sdr_error` rather than
  making the whole object unusable.
- Design optimizer controls before importing multi-start behavior. The first
  contract should expose starts, maps or fixed parameters, optimizer controls,
  and a fallback optimizer. Any multi-start implementation must pin
  `report()`, `sdreport()`, summaries, profiles, and extractors to the winning
  `opt$par` rather than the TMB object's last evaluated parameter state.
- Add diagnostics and wording guards for dense known covariance, large-data
  claims, and spatial routes. Dense known covariance should be labelled
  small-to-moderate unless sparse or block-sparse evidence exists.
- Audit count likelihood kernels for avoidable loops over observed counts and
  replace them with stable closed-form `lgamma` expressions where appropriate.
- Plan C++ likelihood modularization before the single TMB template grows much
  further. The first action should be a source map and refactor plan, not a
  broad rewrite during fragile inference work.
- Make `check_drm()` diagnostic status more visible in summaries, tutorials, or
  workflow docs, so users see convergence, Hessian, boundary, and
  near-correlation-limit warnings before interpreting complex fits.

Phase 6d should be closed as small hardening slices:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 77 | Stable-core feature matrix | Add a README/model-map/pkgdown table for fixed effects, random effects, `sigma`, known covariance, phylogeny, spatial, bivariate `rho12`, latent `corpair()`, profile-CI support, and status. | Done: README and model-map now carry a stable-core matrix that separates stable surfaces, first slices, opt-in controls, and planned or rejected neighbours, with profile/diagnostic status attached to each row. |
| 78 | Validation-debt register | Create a design note or issue-backed register linking each stable, first-slice, or opt-in surface to recovery tests, diagnostics, interval status, docs, and check-log evidence. | Done: `docs/design/34-validation-debt-register.md` maps each stable-core row to evidence, diagnostics, interval status, docs, and explicit debt, with README, model-map, and source-map pointers. |
| 79 | Standard-error and `sdreport()` controls | Design and implement failure-safe uncertainty controls, including `se = FALSE` behavior if compatible with current APIs. | Done: `drm_control(se = FALSE)` skips `TMB::sdreport()` while keeping optimized fits usable for non-Wald post-fit methods, and skipped or failed uncertainty states are explicit in `fit$uncertainty`, `summary()`, `vcov()`, and `check_drm()`. |
| 80 | Optimizer, start, map, and multi-start design | Add the public contract for starts, fixed or mapped parameters, fallback optimizers, and cautious future multi-start support. | Done: `docs/design/35-optimizer-start-map-multistart.md` records the contract, future control names are reserved, and profile callbacks re-pin the TMB object to the selected `opt$par` before profiling. |
| 81 | Dense covariance and large-data guards | Add diagnostics and wording for dense known covariance, sparse/block-sparse expectations, and large-data claim boundaries. | Done: dense `meta_known_V(V = V)` fits now appear as `check_drm()` notes with dense storage, dimension, density, size, rank, and conditioning, and the meta-analysis, large-data, and validation-debt docs label dense known covariance as small-to-moderate until sparse or block-sparse evidence exists. |
| 82 | Count likelihood kernel audit | Review count likelihood sections and replace slow count loops with closed-form expressions where practical. | Done: NB2, zero-inflated NB2, zero-truncated NB2, and hurdle NB2 now share an internal count-kernel helper that avoids observed-count loops with a closed-form `lgamma` ratio and a small-`alpha y` series guard; deterministic high-count tests confirm unchanged likelihood values. |
| 83 | C++ modularization source map | Write the refactor plan for splitting likelihood families, covariance blocks, structured effects, and numerical helpers without changing behavior. | Done: `docs/design/36-cpp-modularization-source-map.md` names the header-only split plan, hidden branch inventory, public branch gates, test gates, and pieces that must not move in the first pass. |
| 84 | Phase 6d gate | Run targeted tests, pkgdown checks, Rose audit, Grace CI gate, and update NEWS/check-log/roadmap. | Done locally: focused tests, full tests, pkgdown build/check, `R CMD check`, stale-claim scans, check-log entry, and after-phase report are complete; GitHub Actions remains the PR-side gate. |

## Phase 6e: Worked-Example Maturation

- Status: started after PR #46 merged the Phase 10-13 foundations into `main`.
- Tracking anchor: continue from Phase 6b issue
  [#31](https://github.com/itchyshin/drmTMB/issues/31) unless a separate
  teaching issue becomes useful.
- Treat Phase 6e as a tutorial-quality follow-through lane. It should not add
  formula grammar, likelihood code, or new model claims.
- Keep guides and tutorials distinct. `model-map`, `which-scale`,
  `distribution-families`, `model-workflow`, `large-data`, and
  `testing-likelihoods` are guides unless a future slice deliberately turns a
  section into a full worked analysis.
- Use `docs/design/37-worked-example-inventory.md` before adding a new example.
  The next tutorial should fill a named gap in question, equation, syntax,
  output, plot/table, interpretation, diagnostics, or unsupported-boundary
  advice.

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 89 | Worked-example inventory | Audit the current tutorials and guides against the tutorial contract, then name the next highest-value tutorial slices. | Done: `docs/design/37-worked-example-inventory.md` records which pages are worked tutorials versus guides, names the major gaps, and prioritizes Slice 90 for the flagship location-scale tutorial and Slice 91 for the structural-dependence reader route. |
| 90 | Flagship location-scale tutorial | Deepen `vignettes/location-scale.Rmd` with a compact response-scale table or figure linking mean slopes, residual-scale slopes, random-slope SDs, `sd(group)`, diagnostics, and report-scale interpretation. | Done: the location-scale tutorial now has a response-scale interpretation table, trait-named parrot beak-length equations with parameter definitions, `profile_targets(fit_growth)` gate, fitted growth translation table, and hierarchical interpretation checklist distinguishing `sigma ~ temperature`, `(0 + temperature | population)`, and `sd(population) ~ habitat`. |
| 91 | Structural-dependence reader route | Add a phylogeny, spatial, and planned phylogeny-plus-spatial route through `vignettes/phylogenetic-spatial.Rmd` and make the coordinate-spatial example self-contained without widening structural-effect claims. | Done: the tutorial and navigation now use "Structural dependence", the article starts with a phylogeny/spatial/planned-combined route, and simultaneous `phylo()` plus `spatial()` remains visibly planned until multiple structural `mu` layers have identifiability checks. |
| 92 | Tutorial maturation gate | Run pkgdown build/check, stale-status scans, Rose audit, and after-phase notes for the Phase 6e tutorial follow-through. | Done locally: source and rendered pages agree on implemented surfaces, planned neighbours, diagnostics, and next examples; stale Slice 91 future wording and old pre-Slice-91 dependence labels were cleaned up. |
| 93 | `0.1.2` release gate | Align the active public preview surface with `0.1.2` and create the release checklist and after-task report without changing APIs, likelihoods, or tutorials. | Done: PR #53 bumped active preview docs to `0.1.2`, passed local tests, pkgdown, `R CMD check`, and PR CI, then merged to `main`. |
| 94 | `0.1.2` release evidence | Tag `v0.1.2`, watch tag CI, run install smoke, and record release evidence. | Done: `v0.1.2` points to the Slice 93 merge commit, tag CI and pkgdown deploy passed, `tools/install-smoke.R v0.1.2 0.1.2` passed, and PR #54 recorded the evidence. |
| 95 | Meta-analysis source-map polish | Return to examples with the meta-analysis lane: equations, exact syntax, parameter definitions, categorical heterogeneous-heterogeneity interpretation, and future `meta_V()` boundaries. | Done locally: the meta-analysis tutorial now defines `yi`, `vi`, `V`, `mu`, `sigma`, `sd(study)`, and `weights = w`; design docs record the Nakagawa et al., Yang and Nakagawa, Rodriguez et al., and unifying-model anchors. |
| 96 | Count NB2 source-map tutorial | Add the first non-Gaussian count worked example using fixed-effect `nbinom2()` and optional `zi ~` syntax, with source-grounded equations, parameter definitions, biological interpretation, diagnostics, and unsupported-boundary text. | Done locally: `vignettes/count-nbinom2.Rmd` now works through a soil-invertebrate count example, links `sigma` to NB2 `size = 1 / sigma^2`, fits NB2 and zero-inflated NB2 models, and keeps non-Gaussian random effects, structured count effects, mixed-response families, and COM-Poisson planned. |
| 97 | Proportion source-map tutorial | Add a bounded-response worked example using fixed-effect `beta_binomial()` and `beta()` syntax, with source-grounded equations, denominator/boundary guidance, response-scale interpretation, diagnostics, and unsupported-boundary text. | Done locally: `vignettes/proportion-beta-binomial.Rmd` now works through seed-germination successes out of trials and strict continuous vegetation-cover proportions, links public `sigma` to beta precision `phi = 1 / sigma^2`, and keeps exact 0/1 continuous boundaries, non-Gaussian random effects beyond the supported first slices, structured bounded responses, and mixed-response families planned. |
| 98 | Bivariate group-level covariance polish | Deepen `vignettes/bivariate-coscale.Rmd` with a compact repeated-individual example that fits matching labelled `mu1`/`mu2` random intercepts, separates group-level covariance from residual `rho12`, and reports `corpairs()` plus `summary(fit)$covariance`. | Done locally: the bivariate tutorial now fits an activity-boldness individual-difference model with `(1 | p | ID)` in both location formulas, shows the covariance diagnostic row, reads residual and group-level rows through `corpairs()`, and keeps bivariate random slopes, `rho12` random effects, mixed-response models, and ordinary spatial covariance planned. |

## Phase 7: Robust and Positive Continuous Families

- Status: fixed-effect univariate Student-t location-scale-shape, Tweedie
  mean-scale-power, and beta mean-scale models are implemented. Lognormal
  location-scale and Gamma mean-CV models are implemented with fixed effects
  plus ordinary unlabelled `mu` random intercepts and independent numeric
  slopes. Student-t also has ordinary unlabelled `mu` random intercept and
  independent numeric slope first slices with fixed-effect `sigma` and `nu`.
- Harden and extend Student-t, lognormal, Gamma, beta, Poisson, and
  negative-binomial models before adding skew-normal and skew-t families.
- Use `lognormal()` for positive continuous responses where `mu` and `sigma`
  are defined on the log-response scale and `fitted()` returns the arithmetic
  response mean.
- Use `Gamma(link = "log")` for positive continuous responses where `mu` is
  the response mean and `sigma` is the coefficient of variation.
- Use `beta()` for strict continuous proportions where `mu` is the mean
  proportion and public `sigma` maps internally to `phi = 1 / sigma^2`.
  Ordinary `mu` random intercepts for `beta()` and `beta_binomial()` now have a
  bounded-response Phase 18 artifact lane, and independent numeric slopes have
  focused source tests; correlated slopes, labelled covariance, `sigma` random
  effects, and zero-one beta random effects remain later gates.
- Use `tweedie()` for non-negative semicontinuous ecological responses such as
  biomass, cover, or abundance indices with exact zeros and positive continuous
  values. The first fitted route is fixed-effect and univariate:
  `bf(y ~ x, sigma ~ z, nu ~ 1)`. Public `sigma = sqrt(phi)`, so `sigma`
  remains scale-like while comparator checks can square it to compare against
  Tweedie dispersion `phi`; the optional `glmmTMB` comparator now checks both
  low-zero and high-zero deterministic cells. `nu` is the power parameter
  constrained between 1 and 2. Predictor-dependent `nu`, Tweedie random
  effects, structured effects, and bivariate or mixed-response Tweedie models
  remain planned.
- Extend the implemented family-link helper table before adding ordinal scale,
  denominator-aware, or additional positive-continuous likelihoods, so
  `predict()` and `fitted()` handle non-identity `mu` links consistently.
- Add formulae for shape and tail parameters where stable.
- Add strict starting-value and boundary diagnostics.

## Phase 8: Counts, Proportions, Percentages, and Ordinal Models

- Status: `poisson(link = "log")` is implemented as a fixed-effect baseline
  count model, including optional `zi ~ predictors` for zero-inflated Poisson
  models and standard R `offset(log(exposure))` terms in the `mu` formula.
  `nbinom2()` is implemented as a fixed-effect `mu`/`sigma`
  overdispersed count model with `Var(y) = mu + sigma^2 * mu^2`, including
  standard R `offset(log(exposure))` terms in the `mu` formula and optional
  `zi ~ predictors` for zero-inflated NB2 models.
  `truncated_nbinom2()` is implemented for positive counts where `mu` and
  `sigma` describe the untruncated NB2 component and `fitted()` returns the
  conditional positive-count mean. Adding `hu ~ predictors` to the same family
  route fits the implemented fixed-effect hurdle NB2 model. `beta()` is
  implemented for strict continuous proportions with public `sigma`.
  `beta_binomial()` is implemented for counted successes out of known trial
  totals with public extra-binomial `sigma`. `zero_one_beta()` is implemented
  for fixed-effect continuous proportions on `[0, 1]` with structural exact 0
  or 1 values through `zoi` and `coi`.
  `cumulative_logit()` is implemented for fixed-effect univariate ordinal
  location models with ordered cutpoints and fixed latent logistic scale.
- Ordinal random effects remain planned as a separate non-Gaussian mixed-model
  lane. The first ordinal target is `(1 | id)` in `mu`; ordinary grouped
  multi-slope covariance belongs to the Phase 4/6c boundary, not to the ordinal
  MVP itself.
- Next family sequence: ordered beta and ordinal scale or discrimination
  formulas after their direction is documented; zero-one beta random effects
  and richer bounded-response covariance remain separate gates after the
  fixed-effect `zoi`/`coi` route and the beta/beta-binomial ordinary `mu`
  random-intercept artifact lane.
- Add ordered logit/probit extensions, COM-Poisson, generalized Poisson, and
  related families according to the distribution roadmap after their
  parameter-link and comparator contracts are documented.

The recent location-scale modelling paper and companion tutorial listed in
`docs/design/11-reference-programme.md` are concrete replication targets for
this phase series. The current package should first reproduce the Gaussian
fixed-effect and Gaussian location-random-effect examples, then add comparator
tests for count and bounded-response examples as the required likelihood and
random-effect features land. The optional local command
`Rscript tools/replicate-location-scale-gaussian.R` writes the current
Gaussian overlap table and records which richer individual-difference examples
remain blocked by future covariance or non-Gaussian random-effect work.

## Phase 9: Ordinal and Denominator-Aware Models

- Status: partially implemented. The location-only `cumulative_logit()` MVP is
  implemented for one ordered response, fixed effects, ordered cutpoints, and
  fixed latent logistic scale. The first `beta_binomial()` path is implemented
  for `cbind(successes, failures)` responses, fixed effects, known trial
  totals, and extra-binomial `sigma`.
- Historical `0.1.0` release decision: Phase 9 closed at this MVP boundary.
  Ordinal scale or discrimination formulae, denominator aliases beyond
  `cbind(successes, failures)`, ordered beta, and zero-one beta random effects
  remain post-preview work unless they are implemented with tests before the
  version bump. The fixed-effect `zero_one_beta()` family is now implemented
  separately for structural exact-boundary continuous proportions.
- Decide whether the next ordinal scale formula is exposed as `sigma ~ ...` or
  a family-specific discrimination parameter before coding starts; the
  direction of interpretation must be unambiguous. The current design note
  prefers `sigma ~ ...` with discrimination reported as derived
  `zeta = 1 / sigma`.
- Keep `cbind(successes, failures)` as the canonical beta-binomial response
  until the denominator-helper design note is implemented with tests.
- Add ordered beta or richer zero-one beta mixed-model/covariance routes for
  continuous bounded responses with exact 0 or 1 values.
- Keep these models univariate until their parameter recovery, boundary
  behaviour, and tutorial interpretation are reliable.

## Phase 10: Spatial Structured Effects

- Status: coordinate-based univariate Gaussian `mu` intercepts, one numeric
  spatial slope, and constant bivariate q=2 `mu1`/`mu2` spatial covariance are
  implemented; mesh/SPDE, multiple slopes, slope correlations, spatial scale,
  q=4 spatial covariance, and spatial `corpair()` regression remain planned.
- Local coordinate-spatial foundation closure:
  `docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`
  records the local gate for the coordinate intercept plus one numeric slope
  path. The later q=2 bivariate spatial slice closes the first spatial
  location-location covariance gate, but not mesh/SPDE, spatial scale, q=4, or
  spatial `corpair()` regression.
- The first fitted spatial models are univariate Gaussian `mu` structured
  effects, parallel to the implemented phylogenetic path:
  `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`. The slope path uses two independent
  spatial fields, one for the intercept and one for the slope, with no fitted
  intercept-slope correlation.
- Support `spatial(1 | site, mesh = mesh)` only after the coded mesh object
  schema, projection path, and recovery tests are implemented. The design
  contract and provenance policy are recorded in
  `docs/design/09-phylogenetic-and-spatial-speed.md`. `coords` identify
  observation or site locations, while `mesh` is the SPDE/GMRF computational
  scaffold.
- Treat `coords` as the friendly public input and `mesh` as optional expert
  control. A dense coordinate-only Gaussian-process path would not require a
  mesh, but it is not the scalable route. The planned SPDE/GMRF route needs a
  mesh-like finite-element scaffold internally, even if `drmTMB` builds it from
  coordinates for the user.
- Cite the SPDE/GMRF method literature and any software used for mesh or
  precision construction. If code is ported or closely adapted from `sdmTMB`,
  `fmesher`, INLA-related sources, `gllvmTMB`, or another project, record
  provenance in `inst/COPYRIGHTS` before calling the spatial slice complete.
- Use a small comparator or simulation recovery test before exposing spatial
  effects beyond univariate `mu` or beyond one numeric slope.
- Do not add spatial terms in `sigma`, `rho12`, bivariate structured covariance
  blocks, or spatial slope correlations until the one-slope path is stable.

## Phase 11: Bivariate Random Effects and Correlation Pairs

- Status: ordinary bivariate random-intercept and `corpairs()` foundation
  locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-11-bivariate-corpairs-foundation-closure.md`.
- Matching labelled random intercepts in bivariate `mu1`/`mu2`,
  `sigma1`/`sigma2`, and one or more same-response `mu`/`sigma` pairs are
  implemented after the fixed-effect bivariate Gaussian location-coscale model
  stabilized.
  The ordinary q=4 all-four intercept block reports all six fitted
  `corpairs()` rows as derived summaries. Random slopes, full cross-parameter
  slope covariance, direct q=4 profile intervals, `rho12` random effects, and
  structured spatial covariance remain planned.
- Use labelled group-level covariance blocks so residual `rho12`, ordinary
  group-level correlations, phylogenetic correlations, spatial field
  correlations, and mean-scale correlations stay in separate namespaces.
- Keep the first individual-difference covariance target focused on ordinary
  grouped personality and plasticity terms before adding structured
  phylogenetic or non-phylogenetic species correlation layers.
- For future random slopes, start with one slope and allow at most two slopes in
  the near-term advanced path. Do not estimate intercept-slope correlations at
  first. A later coefficient-aware `corpair()` design can target the bivariate
  slope1-slope2 plasticity-syndrome case, but that belongs after intercept-only
  covariance blocks and current `corpair()` rows are stable.
- Extend `corpairs()` before adding complex covariance blocks, so users can see
  the level, group, block, responses, distributional parameters, coefficients,
  estimates, and uncertainty source.
- Start with small ordinary grouped models before adding phylogenetic or spatial
  bivariate covariance structures.
- Use `docs/design/28-double-hierarchical-endpoint.md` as the endpoint map for
  full individual-difference location-scale covariance models. Use
  `docs/design/29-mammal-location-coscale-route.md` as the concrete mammal
  body mass-litter size route for the phylogenetic bivariate covariance
  endpoint. The first
  double-hierarchical slices should add one covariance block at a time, with
  `corpairs()` output and simulation recovery before the next block is added.

## Phase 12: Phylogenetic Location-Scale Extensions

- Status: phylogenetic correlation foundation locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-12-phylogenetic-correlation-foundation-closure.md`.
- The fitted foundation covers bivariate `mu1`/`mu2` phylogenetic
  location-location covariance, q=2 predictor-dependent phylogenetic
  `corpair()` regression, bivariate `sd_phylo1()` / `sd_phylo2()` direct-SD
  surfaces, and the first constant all-four q=4 phylogenetic
  location-scale block. These are intercept-level phylogenetic correlation
  paths, not phylogenetic random slopes.
- Extend the implemented `phylo(1 | species, tree = tree)` Gaussian `mu` path to
  one structured `mu` slope, then only later to at most two structured `mu`
  slopes. Three or more structured slopes, intercept-slope correlations, and
  slope-slope `corpair()` regression are distant-future research targets.
- Add phylogenetic terms in `sigma` only after the location path has larger
  simulation evidence and clear identifiability diagnostics.
- Keep phylogenetic location-scale-shape models as a research target, not an
  early production feature.
- Add long optional simulations for many species, near-zero phylogenetic SD,
  high residual noise, and combined phylogenetic plus non-phylogenetic species
  effects.
- For future two-response or two-trait structured models, estimate and report
  phylogenetic correlation, non-phylogenetic species correlation, and residual
  `rho12` as separate layers. The first bivariate phylogenetic mean-mean
  correlation is implemented; residual `rho12` is not a substitute for
  phylogenetic or species-level covariance. Ordinary species covariance can be
  combined with the fitted bivariate phylogenetic mean layer, but
  `check_drm()` notes the identifiability risk when both layers use the same
  grouping factor.
- Predictor-dependent phylogenetic `corpair(species, level = "phylogenetic",
  ...) ~ w` is implemented for the q=2 `mu1`-`mu2` location-location endpoint
  pair. The design uses two independent unit phylogenetic fields and
  species-specific loadings, giving a positive-definite nonstationary covariance
  that reduces to the existing constant bivariate phylogenetic covariance when
  the correlation predictor is constant. A CRAN-safe broad-trend recovery test
  checks that a positive species-level predictor recovers the fitted
  phylogenetic correlation ordering without hitting the correlation guard.
  Phylogenetic location-scale and scale-scale correlation regressions require a
  q=4 contract and remain deferred; spatial siblings remain planned.

## Phase 13: Double-Hierarchical Derived Inference

- Status: derived-summary and interval-status foundation locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-13-derived-inference-foundation-closure.md`.
- Build on Phase 6 direct-parameter profile intervals, including the first
  covariance-row profile intervals, and Phase 11 correlation-pair models.
- Add uncertainty for derived quantities that matter in complete
  individual-difference location-scale models: repeatability, phylogenetic
  signal, total variance, and correlations among individual differences in
  average response, mean-model slopes, residual scale, and scale-model slopes.
- Started the derived-summary path with an internal registry-backed table that
  transforms fitted random-effect SDs and correlations into variance and
  covariance point estimates on the fitted random-effect scale.
- The internal derived-summary table can also attach direct profile intervals
  for its component SD and correlation targets, while leaving derived covariance
  intervals unfilled until a valid nonlinear interval method is implemented.
- `summary(fit)$covariance` now provides the first public surface for the
  currently fitted registry-backed variance and covariance point summaries,
  plus the first bivariate phylogenetic `mu1`/`mu2` mean-mean row, without
  exposing q > 2 syntax or derived covariance intervals. Its covariance interval
  columns also include an explicit status so unavailable derived intervals are
  not mistaken for silently omitted support.
- Use fix-and-refit profiles or carefully parameterized direct targets for
  nonlinear quantities; do not treat Wald intervals as the default for boundary
  variance components or correlations.
- Report these intervals through the same `corpairs()` and derived-summary
  namespaces used for point estimates, with explicit boundary, convergence,
  and near-correlation-limit flags.

## Phase 14: Large-Data Engine

- Status: planned; Slice 209 adds the ADEMP-style entry blueprint in
  `docs/design/41-phase-18-simulation-programme.md`.
- Extend memory-light fitted objects for large ecological, evolutionary, and
  environmental datasets beyond the current post-fit storage controls.
- Add sparse fixed-effect matrices before claiming million-row readiness.
- Extend Gaussian aggregation or sufficient-statistic paths beyond the first
  fixed-effect route where repeated rows can be collapsed without changing the
  likelihood.
- Add non-CRAN benchmarks for 100k, 500k, 1M, and 5M rows with 1k-10k species.
- Treat sparse phylogenetic A-inverse scaling, sparse known sampling covariance,
  and large-row model-frame memory as separate engineering problems.

## Phase 15: Mixed-Response Bivariate Families

- Status: planned.
- Design mixed composed families such as `family = c(gaussian(), poisson())` only
  after the joint likelihood and interpretation of cross-response dependence are
  explicit.
- Decide whether mixed-response dependence is residual `rho12`, a latent
  Gaussian copula, a shared random effect, or another likelihood-specific
  construction before coding.
- Keep higher-dimensional response matrices out of scope; they belong to
  `gllvmTMB`.

## Phase 16: Shape and Asymmetry Models

- Status: planned.
- Add skew-normal and skew-t only after Student-t, Gaussian phylogenetic
  location-scale, and the core family-link contract are stable. The first
  asymmetry slice should be fixed-effect and univariate, not a random-effect or
  structured-dependence endpoint.
- Use GAMLSS-style names: `nu` for the first shape parameter and `tau` for the
  second when needed. For `skew_normal()`, `nu` should be the asymmetry or
  skewness parameter. The first fitted lane should use public moment
  parameters, with `mu = E[y]`, `sigma = SD[y]`, and an explicit transform to
  native skew-normal `xi`, `omega`, and `alpha` before implementation. For
  `skew_t()`, `nu` should remain the asymmetry parameter and `tau` should
  control tail thickness or degrees of freedom, so the Student-t `nu`
  convention does not silently change meaning.
- Current research anchors: `sn` provides the classic skew-normal density with
  location `xi`, scale `omega`, and slant `alpha`;
  `gamlss.dist::SN2()` uses `mu`, `sigma`, and `nu`; GAMLSS exposes several
  skew-t variants, so `drmTMB` must choose and document one parameterization;
  `brms::skew_normal()` uses `mu`, `sigma`, and `alpha`; `RTMBdist` exposes
  AD-compatible skew-normal and skew-t densities that are useful comparator and
  implementation references. The `RTMBdist` skew-t warning about not
  initializing skew exactly at zero should be treated as a numerical-starting
  guard for any TMB implementation.
- Start with fixed-effect shape formulae and clear warnings about
  identifiability among location, residual scale, skewness, tail shape,
  outliers, and unmodelled heteroscedasticity. Shape random effects are a later
  evidence-gated lane, not the first skew-normal or skew-t slice.
- Preserve the two scale logics when skew families arrive: `sigma ~ ...`
  models residual or distributional scale, while `sd(group) ~ ...` models the
  SD of a latent group-level effect. The first skew-family slice should not add
  `sigma` random effects, `nu` random effects, `sd(group)` scale models, or
  `phylo()`/`spatial()` terms until fixed-effect likelihood recovery, normal or
  Student-t limit behaviour, and false-positive heteroscedasticity checks pass.
- Treat phylogenetic location-scale-shape and skewness/kurtosis evolution as a
  later methods programme, not a first implementation target.

## Phase 17: Visualization, Marginal Effects, and Reader-Facing Inference

- Status: planned; initial long-format prediction surfaces exist through
  `prediction_grid()`, `predict_parameters()`, and `marginal_parameters()`.
- Slice 100 research note:
  `docs/design/39-visualization-grammar.md` records the external lessons from
  `ggplot2`, `tidybayes`, `ggdist`, `emmeans`, `ggeffects`,
  `marginaleffects`, diagnostic plotting packages, and figure-composition
  tools. It does not add dependencies or claim plotting support; it sharpens
  the data-first contract for future helpers.
- Build a coherent visualization layer across all implemented `drmTMB` model
  families rather than one-off plotting functions. The target reader is an
  applied ecology, evolution, or environmental-science user who needs to see
  fitted location, scale, shape, coscale, random-effect SD, and latent
  correlation patterns without rebuilding prediction grids by hand.
- Start with data helpers before plotting helpers:
  `prediction_grid()` or equivalent grid builders, `marginal_effects()` for
  averaging over nuisance covariates or groups, and compatibility checks for
  `emmeans` where the fitted parameter and link scale have a clean contract.
- Slice 101 adds the first `prediction_grid()` contract: focal terms, supplied
  `at` values, conditioned nuisance predictors, mean-reference grids, empirical
  counterfactual grids, and metadata that records the grid rule. It does not add
  plotting, EMM contrasts, slopes, or interval columns.
- Slice 102 adds the first reader-facing empirical-grid workflow to the
  model-workflow article. The example separates a conditioned prediction grid
  for direct `predict_parameters()` rows from an empirical grid that
  `marginal_parameters(..., by = "temperature")` reduces over the fitted-row
  covariate distribution.
- Slice 103 adds interval provenance columns to `predict_parameters()` and
  `marginal_parameters()`. The current point-estimate tables report
  `conf.status = "not_requested"` and
  `interval_source = "not_available"` until a later slice computes real
  intervals.
- Slice 104 adds `plot_parameter_surface()`, the first optional `ggplot2`
  helper for `predict_parameters()` tables. The helper returns a composable
  `ggplot` object, lives on the Reference page under Visualization, and does
  not compute intervals, EMMs, contrasts, or slopes.
- Slice 105 makes the ordinary `summary()` workflow more visible in the
  model-workflow guide. It now shows a random-intercept model where
  `summary()` prints response-scale random-effect SDs, derived repeatability,
  and profile-likelihood confidence-interval status without describing those
  intervals as Bayesian credible intervals.
- Slice 106 adds delta-method standard errors to direct response-scale
  `summary()` parameter rows when `TMB::sdreport()` succeeds. Descriptive
  fitted ranges and derived variance ratios keep missing standard errors, and
  profile-likelihood confidence intervals remain the recommended interval route
  for fitted SD and correlation targets.
- Slice 107 adds a reader-facing `summary()` map to the model-workflow guide.
  The guide names what `coefficients`, `parameters`, `covariance`, `derived`,
  and `confint` report, then points readers to `fixef()`, `sigma()`,
  `rho12()`, `ranef()`, `corpairs()`, and `profile_targets()` when the ordinary
  summary has identified the row they need to inspect further.
- Slice 108 audits and clarifies the pkgdown Reference index for post-fit and
  plotting helpers. Fitting, checking, summaries, predictions, uncertainty, and
  extractors are grouped under "Model fitting and post-fit tools"; exported
  plotting helpers appear under "Visualization"; at the Slice 108 boundary,
  `plot_parameter_surface()` was the exported plotting helper with a stable
  data contract.
- Slice 108 also tightens the `summary()` reference example after reader review:
  profile summaries keep fixed-effect Wald 95% confidence intervals while
  adding direct-profile `sigma` 95% confidence intervals, and direct constant
  parameter rows no longer print duplicated `minimum` and `maximum` values that
  equal the estimate.
- Slice 109 translates the visualization landscape into raw-data-plus-model
  display rules. The model-workflow article now pairs an observed-response
  scatter plot with separate fitted `mu` and `sigma` surfaces, keeps the
  prediction table visible, and warns not to place raw response points on
  `sigma`, `sigma^2`, `rho12`, random-effect SD, or correlation axes.
- Slice 110 improves `plot_parameter_surface()` labels for single-parameter
  panels. When a filtered prediction table contains one `dpar`, the default
  y-axis label now names the parameter and, when unique, the prediction scale.
- Slice 111 adds a Phase 17 visualization decision map to the model-map
  article. It routes observed responses, fitted parameter surfaces, empirical
  marginal summaries, correlation rows, interval tables, and diagnostics to the
  current data helpers before any plotting style is chosen.
- Slice 112 records the `corpairs()` plotting preflight contract. The
  `plot_corpairs()` helper consumes an explicit `corpairs()` table, keeps
  correlation `level` and `class` visible, draws intervals only from finite
  confidence bounds, and was tested for residual, ordinary group-level,
  phylogenetic, empty-table, and missing-`ggplot2` cases before export.
- Slice 113 implements the first narrow `plot_corpairs()` helper. It consumes
  explicit `corpairs()` tables, draws one point per correlation row, adds
  interval segments only for finite `conf.low` and `conf.high` bounds, keeps
  correlation `level` and `class` visible, and lives in the Visualization
  reference section.
- Slice 114 adds optional `facet` support to `plot_corpairs()` so residual,
  group-level, phylogenetic, spatial, or future study-level rows can be separated
  by an explicit table column without changing the extraction contract.
- Slice 115 adds the first `facet = "level"` Reference example for
  `plot_corpairs()`, keeping the example table explicit while making the layer
  separation option visible to readers.
- Slice 116 adds a fitted bivariate-coscale tutorial path where `corpairs()`
  feeds `plot_corpairs(..., facet = "level")`, visually separating residual
  `rho12` from group-level random-intercept correlation rows.
- Slice 117 adds the first `emmeans` preflight test for the existing
  reference-grid and link-scale contract. Small fixed-effect fits now check
  that `prediction_grid()` plus `predict_parameters(type = "link")` and
  `predict_parameters(type = "response")` preserve the documented inverse-link
  relationship across implemented univariate, count, proportion, ordinal, and
  bivariate Gaussian families without adding an `emmeans` dependency or
  contrast API.
- Slice 118 records the planned `emmeans` interface contract in
  `docs/design/40-emmeans-interface-contract.md`. The first public method should
  be a narrow fixed-effect univariate `mu` path using the official
  `recover_data()` and `emm_basis()` extension API, with bivariate,
  zero-inflated, hurdle, ordinal expected-score, random-effect, structured-effect,
  slope, and interval-aware targets staying blocked until their algebra and
  tests are explicit. Broader contrast helpers should stay separate from the
  first EMM grid.
- Slice 119 adds an internal fixed-effect basis helper for the future
  `emm_basis()` path. `drm_fixed_effect_basis()` returns the requested `dpar`
  model matrix, coefficients, optional covariance submatrix, offset, link, and
  linear predictor, and `predict.drmTMB()` now uses that helper for its
  fixed-effect component. This remains internal plumbing, not public `emmeans`
  support.
- Slice 120 adds an internal preflight gate for the first possible `emmeans`
  basis path. `drm_emmeans_mu_basis()` is still private, but it now accepts only
  fixed-effect univariate `mu` targets with covariance available and rejects
  unsupported `dpar`, missing covariance, zero-inflated, and random-effect paths
  before any future method could return an `emmGrid`.
- Slice 121 adds the matching private recover-data preflight. The internal
  helper recovers the retained `mu` model frame, terms, predictor names,
  response name, factor levels, and row names for the same first eligible target
  and errors when memory-light fits did not retain model frames.
- Slice 122 implements the first public `emmeans` bridge. `emmeans` is now a
  suggested package with conditional method registration, and
  `emmeans::emmeans()` works for fixed-effect univariate `mu` targets when model
  frames and fixed-effect covariance are retained. The method still rejects
  non-`mu`, missing-covariance, memory-light, zero-inflated, random-effect, and
  other unsupported paths before returning an `emmGrid`.
- Slice 123 cleans the `plot_corpairs()` R CMD check hygiene left visible by
  Slice 122. The interval segment layer now builds its `ggplot2` aesthetics from
  symbols, matching the existing `plot_parameter_surface()` pattern, so
  `conf.low`, `conf.high`, and `.drmTMB_pair_label` are no longer treated as
  undeclared global variables.
- Slice 124 adds the first reader-facing `emmeans::emmeans()` example to the
  model-workflow article. The example estimates habitat-level EMMs for the
  fixed-effect univariate `mu` path at a supplied temperature and explicitly
  separates that target from `sigma`, random-effect, bivariate, zero-inflated,
  hurdle, ordinal, and slope workflows. Generic `emmeans` contrasts on the
  returned `mu` grid are possible, but drmTMB-specific contrast helpers remain a
  separate future contract.
- Slice 125 extends `emmeans()` parity tests across the remaining univariate
  model types already admitted by the fixed-effect `mu` gate: Student-t,
  lognormal, Gamma, beta-binomial, NB2, and zero-truncated NB2. The tests keep
  link-scale and response-scale EMMs aligned with `predict(dpar = "mu")`
  without widening the gate to unsupported model structures.
- Slice 126 clarifies the downstream contrast boundary. A new test confirms
  that generic `emmeans` pairwise contrasts use differences among the returned
  fixed-effect `mu` EMMs, while docs avoid treating contrast itself as a
  pre-grid unsupported target and keep broader contrast and slope helpers
  separate.
- Slice 127 adds explicit offset parity coverage for the first `emmeans()`
  bridge. A Poisson fixed-effect `mu` model with `offset(log(exposure))` now
  checks that `emmeans(..., at = list(exposure = 2))` matches
  `predict(dpar = "mu")` on link and response scales, without widening support
  to non-`mu`, random-effect, bivariate, zero-inflated, hurdle, ordinal, slope,
  or fitted-response targets.
- Slice 128 adds transformed-predictor recovery coverage for the same first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` model with `log(size)` now
  checks that `emmeans(..., at = list(size = 1.5))` matches
  `predict(dpar = "mu")`, and the recover-data preflight confirms that raw
  source variables for transformed predictors are restored from stored data.
- Slice 129 adds explicit default numeric covariate-reduction coverage for the
  first `emmeans()` bridge. A Gaussian fixed-effect `mu` model with an
  asymmetric numeric covariate now checks that `emmeans(fit, ~ habitat)` matches
  `predict(dpar = "mu")` at `mean(x)`, keeping this as ordinary `emmeans`
  reference-grid behaviour rather than a drmTMB-specific marginalisation rule.
- Slice 130 adds direct `type` argument coverage for the first `emmeans()`
  bridge. A Poisson fixed-effect `mu` model now checks that
  `emmeans(..., type = "response")` matches
  `predict(dpar = "mu", type = "response")`, while `type = "link"` remains on
  the formula linear-predictor scale.
- Slice 131 adds custom numeric covariate-reduction coverage for the first
  `emmeans()` bridge. A skewed Gaussian fixed-effect `mu` example now checks
  that `emmeans(..., cov.reduce = stats::median)` matches
  `predict(dpar = "mu")` at `median(x)`, keeping custom reduction as ordinary
  `emmeans` reference-grid behaviour rather than drmTMB empirical averaging.
- Slice 132 adds unreduced numeric covariate-grid coverage for the first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` example now checks that
  `emmeans(..., cov.reduce = FALSE)` matches `predict(dpar = "mu")` averaged
  over the observed `x` levels in the reference grid, keeping this separate
  from drmTMB row-wise empirical marginalisation.
- Slice 133 adds multiple explicit `at` value coverage for the first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` example now checks that
  `emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` matches
  row-wise `predict(dpar = "mu")` on the same conditional reference grid.
- Slice 134 adds public zero-inflated boundary coverage for the first
  `emmeans()` bridge. A zero-inflated Poisson model now checks that
  `emmeans()` errors before returning an `emmGrid`, names the unsupported
  `"zi_poisson"` model type, and points users back to `prediction_grid()` plus
  `predict_parameters()`.
- Slice 135 adds public hurdle boundary coverage for the first `emmeans()`
  bridge. A hurdle NB2 model now checks that `emmeans()` errors before
  returning an `emmGrid`, names the unsupported `"hurdle_nbinom2"` model type,
  and points users back to `prediction_grid()` plus `predict_parameters()`.
- Slice 136 adds public ordinal boundary coverage for the first `emmeans()`
  bridge. A cumulative-logit model now checks that `emmeans()` errors before
  returning an `emmGrid`, names the unsupported `"cumulative_logit"` model
  type, and points users back to `prediction_grid()` plus
  `predict_parameters()`.
- Slice 137 improves the public bivariate boundary for the first `emmeans()`
  bridge. Bivariate Gaussian fits now error as unsupported `"biv_gaussian"`
  fits before returning an `emmGrid`, with the same prediction-table guidance,
  instead of falling through to a generic missing-`mu` message.
- Slice 138 blocks transformed-response formulas in the first `emmeans()`
  bridge. Fits such as `log(y) ~ x` now error before returning an `emmGrid`,
  with guidance toward explicit transformed-scale prediction tables through
  `prediction_grid()` plus `predict_parameters()`.
- Slice 139 extends the public zero-inflated `emmeans()` boundary to NB2.
  Zero-inflated NB2 fits now error as unsupported `"zi_nbinom2"` fits before
  returning an `emmGrid`, matching the zero-inflated Poisson boundary.
- Slice 140 adds interaction-formula coverage for the fixed-effect univariate
  `mu` `emmeans()` bridge. A Gaussian `habitat * x` fit now checks that
  conditional EMMs at an explicit `x` value match `predict(dpar = "mu")` on the
  same interaction grid.
- Slice 141 adds factor-conditioned reference-grid coverage for the
  fixed-effect univariate `mu` `emmeans()` bridge. A Gaussian `habitat` by
  `season` grid at `x = 0.25` now checks that returned EMM rows preserve factor
  levels and match `predict(dpar = "mu")` on the same grid.
- Slice 142 fixes and covers ordered-factor predictor coding in fixed-effect
  prediction matrices and the first `emmeans()` bridge. A Gaussian model with
  an ordered `condition` predictor now checks that `emmeans(fit, ~ condition |
  habitat, at = list(x = 0.2))` preserves ordered polynomial coding and matches
  `predict(dpar = "mu")` on the same grid.
- Slice 143 adds explicit validation for fixed-effect prediction factor levels.
  Character `newdata` values that match fitted factor levels now route through
  the fitted factor coding, while unknown levels such as `habitat = "forest"`
  error before model-matrix construction with the offending predictor and
  level named. Missing values in fitted factor predictors also error early, and
  extra factor columns not used by the requested distributional parameter are
  ignored.
- Slice 144 extends fixed-effect prediction `newdata` validation to all
  required predictors. Missing required columns and missing values in required
  numeric predictors now error before model-matrix construction, while extra
  unused columns remain harmless.
- Slice 145 adds the corresponding finite-value guard for required numeric
  predictors. Values such as `x = Inf` now error before fixed-effect prediction
  matrices are built.
- Slice 147 extends that finite-value guard to transformed-predictor design
  columns. Values such as `size = 0` in a model with `log(size)` now error
  after formula evaluation names the affected model column, rather than
  returning a non-finite prediction.
- Slice 148 applies the same finite design-matrix guard to random-effect scale
  prediction. Direct `sd(id)` predictions with `newdata` such as `w_pos = 0`
  in a model with `sd(id) ~ log(w_pos)` now error before returning infinite
  link- or response-scale SD predictions.
- Slice 149 extends fitted factor-level validation to random-effect scale
  prediction. Direct `sd(id)` predictions now accept character values that
  match fitted `sd(id)` factor levels and reject unknown levels before base R
  contrast or matrix-conformability errors.
- Slice 150 pins the raw-predictor side of random-effect scale prediction
  `newdata` validation. Missing required `sd(id)` predictor columns, missing
  required values, and non-finite required numeric values now have explicit
  tests and design text before random-effect scale model-matrix construction.
- Slice 151 pins the positive direct-SD `newdata` output contract. Multi-row
  `sd(id)` prediction grids now have explicit tests for one output per row,
  `rownames(newdata)` preservation, default response scale, and response
  predictions equalling `exp(link)` from `type = "link"`.
- Slice 152 pins direct-SD `newdata` container boundaries. Non-data-frame
  `newdata` inputs now have explicit error coverage, while zero-row data-frame
  grids return named length-zero numeric vectors on both link and response
  scales.
- Slice 153 pins multiple direct-SD formula prediction boundaries. Fits with
  both `sd(id) ~ w_id` and `sd(site) ~ w_site` now have explicit tests that
  each requested `dpar` validates its own predictors, ignores sibling-target
  extra columns, and names the missing target-specific predictor.
- Slice 154 pins direct-SD long-table helpers. `predict_parameters()` and
  `marginal_parameters()` now have explicit tests and reference docs for fitted
  random-effect scale model names such as `sd(id)`, with component
  `random-effect-sd-model`, row-label preservation, and marginal averaging over
  supplied direct-SD prediction rows.
- Slice 155 pins the direct-SD prediction-grid helper chain. A grid over a
  predictor such as `w` in `sd(id) ~ w` now has explicit coverage through
  `prediction_grid()`, `predict_parameters(..., dpar = "sd(id)")`, and
  `marginal_parameters(..., by = "w")`.
- Slice 156 adds the first reader-facing model-workflow example for a
  direct-SD prediction surface. The article fits `sd(site) ~ reef_cover`,
  builds a `prediction_grid()` over reef cover, reports
  `predict_parameters(..., dpar = "sd(site)")`, and reduces the same grid with
  `marginal_parameters(..., by = "reef_cover")` while keeping random-effect SD
  separate from residual `sigma` and raw responses.
- Slice 157 updates the model-map article so fitted random-effect SD surfaces
  route through `prediction_grid()`, `predict_parameters(..., dpar =
  "sd(group)")`, and `marginal_parameters()`, with component
  `random-effect-sd-model` kept separate from residual `sigma`.
- Slice 158 adds the first confidence-band path for prediction surfaces.
  `predict_parameters(conf.int = TRUE)` now fills Wald fixed-effect
  `std.error`, `conf.low`, and `conf.high` columns for supplied `newdata` grids
  when the requested distributional parameter has an ordinary fixed-effect
  basis. `plot_parameter_surface()` consumes those columns, drawing confidence
  bands for continuous x-values and interval bars for discrete x-values;
  `not_available` rows remain interval-free. The model-workflow and model-map
  articles now show the table-first band workflow and leave `conf.status`,
  `conf.level`, and `interval_source` visible.
- Slice 159 clarifies the confidence-band example boundary. The
  model-workflow article now prints interval provenance for explicit
  fixed-effect `mu`/`sigma` grids, and contrasts that with a direct
  `sd(site)` surface that reports `conf.status = "wald_unavailable"` when Wald
  intervals are requested. The point is reader-facing: fixed-effect parameter
  surfaces can draw 95% Wald bands on explicit grids; direct random-effect SD
  surfaces need a profile or bootstrap route before a ribbon is honest.
- Revised Phase 18 entry gate after Slice 159: do not jump directly into
  comprehensive simulation while profile/bootstrap intervals, Gaussian
  double-hierarchical random-slope limits, and non-Gaussian
  location-scale-shape surfaces are still uneven. Treat Slices 159-202 as a
  stabilization bridge before resuming Phase 17. Phase 18 comprehensive
  simulation should start only after that resumed Phase 17 closure gate, unless
  a deliberately smaller pilot simulation is opened earlier.
- Next 30-slice stabilization map:

| Slice | Lane | Target |
| --- | --- | --- |
| 159 | Confidence bands | Clarify fixed-effect Wald bands versus explicit unavailable direct-SD surfaces. |
| 160 | Confidence bands | Add or test discrete-x interval-bar examples for factor predictors. |
| 161 | Confidence bands | Document `newdata_required` for fitted-row interval requests. |
| 162 | Confidence bands | Tighten `conf.level` examples and interval-status display conventions. |
| 163 | Confidence bands | Gate the confidence-band docs with render, pkgdown, and stale-wording checks. |
| 164 | Profile intervals | Refresh the profile-target inventory for fixed effects, SDs, correlations, and row-specific parameters. |
| 165 | Profile intervals | Done: the workflow and profile-CI design notes now pin `newdata` examples for row-specific `sigma`, `sigma1`, `sigma2`, and `rho12`. |
| 166 | Profile intervals | Done: direct constant-`sigma` examples are separated from predictor-dependent scale profiles, with `profile.boundary` and `profile.message` interpretation kept visible. |
| 167 | Profile intervals | Done: direct random-effect SD examples now point users to exact `profile_targets()` names, including random-slope suffixes. |
| 168 | Profile intervals | Done: random-effect correlation examples now stay separate from residual `rho12`, with direct targets gated by `profile_targets()`. |
| 169 | Derived intervals | Done: q4 derived correlation and covariance-product rows remain explicit `derived_interval_unavailable` targets until a reparameterized or fix-and-refit derived interval method exists. |
| 170 | Bootstrap intervals | Superseded by the fast-CI slice: the audit requirements now exist for selected direct `confint()` targets through a deterministic simulate/refit route, direct target extractor, failure counts, and runtime controls. |
| 171 | Bootstrap intervals | Done for the first public boundary: `confint(..., method = "bootstrap")` now returns percentile intervals for selected direct targets; `summary()`, `corpairs()`, prediction tables, q4 derived rows, repeatability, and phylogenetic signal remain separate work. |
| 172 | Bootstrap intervals | Done for direct `confint()` targets: bootstrap interval rows now carry `bootstrap`, `bootstrap_unavailable`, success counts, failure counts, backend, and worker metadata. Unsupported non-direct routes still stop before interval work. |
| 173 | Interval evidence | Done: focused tests now cover unsupported-bootstrap errors, q4 derived-unavailable boundaries, direct profile paths, and shared interval-status/source vocabulary. |
| 174 | Interval diagnostics | Done: profile diagnostics remain `profile.boundary`/`profile.message`; direct bootstrap rows report refit success/failure metadata, while unsupported bootstrap surfaces still give explicit unavailable errors. |
| 175 | Interval harmonization | Done: internal status/source vocabulary helpers now align `summary()`, `confint()`, `corpairs()`, and prediction-table interval outputs. |
| 176 | Phase 6/13 gate | Done: the interval-readiness revisit is closed with tests, docs, known-limitations updates, check-log evidence, and an after-phase note. |
| 177 | Gaussian random slopes | Done: ordinary Gaussian `mu` supports multiple independent numeric slopes and one correlated intercept-plus-one-slope block; arbitrary correlated multi-slope blocks were moved to Slices 178-181. |
| 178 | Gaussian random slopes | Done: the parser/API accepts ordinary Gaussian `mu` blocks such as `(1 + x1 + x2 | id)` and labelled variants while keeping residual-scale correlated slope blocks outside scope. |
| 179 | Gaussian random slopes | Done: q > 2 ordinary Gaussian `mu` blocks use the registry-backed positive-definite unstructured covariance path with constant block correlations. |
| 180 | Gaussian random slopes | Done: q=3 recovery, malformed-input, conditional prediction, summary, `corpairs()`, and `profile_targets()` tests cover the first public path. |
| 181 | Gaussian random slopes | Done: user docs state the q=3 evidence, q > 2 output names, profile-ready SDs, derived-unavailable unstructured correlations, and sample-size boundary. |
| 182 | Scale random slopes | Done: multiple independent residual-scale Gaussian `sigma` terms are tested as separate log-`sigma` SDs with correlations fixed at zero; correlated and labelled residual-scale slope covariance blocks remain planned. |
| 183 | Location-scale covariance | Done: two independent matched univariate `mu`/`sigma` random-intercept covariance blocks can be fitted and reported through `corpars$mu_sigma`, `corpairs()`, `summary()`, and `profile_targets()`. |
| 184 | Location-scale covariance | Done: `check_drm()` now reports each independent univariate `mu`/`sigma` block separately, and profile tests cover the second `eta_cor_mu_sigma` interval target. |
| 185 | Bivariate slope route | Superseded by Slice 83: matching slope-only `mu1`/`mu2` blocks such as `(0 + x | p | id)` are now fitted as the first slope-slope covariance route, while `(1 + x | p | id)` q=4 location blocks and all-four q=8 location-scale slope blocks remain closed. |
| 186 | Phylogenetic random slopes | Done: audit confirms phylogenetic slopes remain rejected/intercept-only while coordinate spatial already fits one independent `mu` slope; the error, docs, and tests now state this parity gap explicitly. |
| 187 | Spatial random slopes | Done: coordinate-spatial one-slope support now has a direct profile-interval test for the slope-field SD plus explicit boundary tests for multiple slopes, residual-scale structured slopes, and bivariate spatial slope syntax. |
| 188 | Random-effect gate | Done: the one-slope-per-layer status table and remaining Gaussian double-hierarchical limits are published below before the non-Gaussian revisit. |

- Slice 189 is done: the double-hierarchical endpoint map now reflects the
  current Gaussian boundary after Slices 177-188, including q > 2 ordinary
  `mu`, multiple univariate mean-scale intercept blocks, coordinate-spatial
  one-slope support, and the still-closed bivariate slope, q=6/q=8, and spatial
  q=4 endpoints.
- Slices 190-202 are the pre-simulation non-Gaussian gate. The purpose is not
  to implement every attractive family feature before Phase 18. It is to decide
  which non-Gaussian, scale, shape, zero-inflation, hurdle, ordinal, structured,
  and interval surfaces are fitted, which are explicitly unsupported, and which
  have enough recovery evidence to enter the comprehensive simulation grid.
  Treat the table below as the current working map; each row should become more
  specific as earlier random-effect slices close.

### Slice 188 One-Slope Gate

This is the current random-effect status before the non-Gaussian revisit:

| Layer | One-Slope Status | Inference and Diagnostics | Remaining Gaussian DH Limit |
| --- | --- | --- | --- |
| Ordinary Gaussian `mu` | Fitted for independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric location blocks. | q=3 recovery, `sdpars$mu`, `corpars$re_cov`, `corpairs()`, `summary()`, `profile_targets()`, and direct SD profiles are covered. | Larger q blocks are advanced and sample-size hungry; q > 2 correlations remain derived-unavailable for direct profile intervals. |
| Gaussian `sigma` | Fitted for random intercepts and multiple independent numeric slopes on `log(sigma)`. | `sdpars$sigma`, prediction contributions, direct `log_sd_sigma` profile targets, and tests cover the independent-slope boundary. | Correlated residual-scale slope blocks and labelled residual-scale slope covariance are planned. |
| Univariate `mu`/`sigma` covariance | Fitted for one or more matched labelled random-intercept blocks. | `corpars$mu_sigma`, `corpairs(class = "mean-scale")`, `summary()`, `check_drm()`, and second-block profile tests are covered. | Slope-level mean-scale covariance is planned. |
| Bivariate ordinary covariance | Fitted for matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, one or more same-response `mu`/`sigma` blocks, all-four q=4 intercept blocks, and matching slope-only `mu1`/`mu2` blocks. | Constant q=2 correlation targets and the slope-slope `mu1`/`mu2` target are profile-ready; same-response mean-scale blocks report one row per response-specific label/group pair; q=4 correlations are derived-only with explicit unavailable interval status. | Intercept-plus-slope q=4 location blocks, residual-scale slope blocks, and p8/q8 all-four slope endpoints remain closed. |
| Phylogenetic structured effects | Univariate Gaussian `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` correlation, one-slope `mu`, bivariate, direct-SD, q=2 correlation-regression, and q=4 location-scale paths are fitted. | Direct phylogenetic SDs and q=2 correlations have profile targets; full q=4 correlations are derived-only, while block-diagonal q=4 fallback correlations are direct targets that still need fit-specific profile diagnostics. | Multiple phylogenetic slopes, residual-scale structured slopes, slope correlations, direct-SD formulas combined with structured `sigma`, structured `rho12`, and non-Gaussian phylogenetic effects remain planned. |
| Coordinate spatial structured effects | Fitted for univariate Gaussian `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` correlation, one numeric `mu` slope with independent coordinate fields, constant bivariate Gaussian `mu1`/`mu2` q=2 location covariance, constant q=4 location-scale covariance, and ordinary Poisson/NB2 q=1 `mu` intercepts. | `sdpars$mu`, `sdpars$sigma`, marker-specific `ranef()` blocks, `profile_targets()`, `check_drm()`, `corpairs(level = "spatial")`, `summary()$covariance`, a slope-field profile interval, the q=2 dense covariance comparator, q=4 extractor/diagnostic tests, and count structured tests are covered. | Mesh/SPDE, multiple slopes, residual-scale structured slopes, slope correlations, spatial direct-SD, spatial `corpair()`, count spatial slopes or labels, and zero-inflated spatial effects remain planned. |
| Non-Gaussian families | Fixed-effect likelihoods are fitted; ordinary Poisson and NB2 `mu` random intercepts plus independent numeric slopes are fitted for non-zero-inflated count models; one q=1 structured `mu` intercept from `phylo()`, `spatial()`, `animal()`, or `relmat()` is fitted for ordinary Poisson/NB2; ordinary Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random intercepts have Phase 18 artifact lanes and independent numeric `mu` slopes have focused source tests; ordinary NB2 has the first log-`sigma` random-intercept gate. | Poisson, NB2, Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random-effect SDs appear in `sdpars$mu`, random effects, and direct `profile_targets()` rows; Student-t, zero-truncated NB2, bounded-response, and positive-continuous artifact lanes record fixed-effect Wald rows and direct-SD profile rows for ordinary `(1 | id)` in `mu`; `tests/testthat/test-nongaussian-mu-random-slopes.R` records CRAN-safe slope recovery, prediction, extractor, profile-target, and diagnostic checks; NB2 `sigma` random-intercept SDs appear in `sdpars$sigma`, `random_effects$sigma`, and direct `log_sd_sigma` profile-target rows; family-specific fixed-effect summaries, structured count diagnostics, and intervals exist where already implemented. | Zero-inflation, hurdle, ordinal, structured slopes, simultaneous structured count types, labelled count covariance, cross-parameter covariance, NB2 `sigma` slopes or structured effects, correlated Student-t/zero-truncated NB2/positive-continuous/bounded-response random slopes, non-Gaussian `sigma` random effects, Student-t `nu` random effects, exact 0/1 boundary mass, other non-Gaussian scale random effects, and shape random effects still need separate implementation evidence before broad simulation. |

| Slice | Lane | Target Before Phase 18 |
| --- | --- | --- |
| 190 | Non-Gaussian `mu` random effects | Done and extended: first candidates were ordinary `mu` random intercepts for Poisson and NB2-style count likelihoods. Ordinary Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random intercepts now have focused source-test slices and Phase 18 artifact lanes, and independent numeric `mu` slopes have a CRAN-safe focused recovery slice. Ordinal, zero-inflation, hurdle, shape, correlated slopes, and structured non-Gaussian paths retain explicit unsupported messages. |
| 191 | Non-Gaussian `mu` implementation | Done: ordinary Poisson `mu` random intercepts now fit as `(1 | group)` in the log-mean predictor for non-zero-inflated Poisson models, with recovery, lme4 comparator, random-effect extraction, `sdpars$mu`, and direct SD profile-target coverage. |
| 192 | Non-Gaussian `mu` slopes | Done: ordinary Poisson `mu` now fits independent numeric random slopes such as `(0 + x | group)` on the log-mean predictor, with recovery, lme4 comparator, random-effect extraction, `sdpars$mu`, and direct SD profile-target coverage; correlated Poisson slope blocks and all labelled/cross-parameter covariance remain planned. |
| 193 | Non-Gaussian residual scale | Done and partly superseded: Student-t, lognormal, Gamma, beta, beta-binomial, truncated NB2, and hurdle NB2 `sigma` formulas retain fixed-effect-only scale paths; ordinary NB2 now has the first log-`sigma` random-intercept gate. Other random-effect bar terms still error with a scale-specific boundary and tests until family-specific scale-random-effect likelihood and recovery evidence exists. |
| 194 | Shape and skew boundary | Done: Student-t `nu` random-effect bar terms now have a shape-specific boundary; residual shape/skewness remains fixed-effect-first, future `tau` is second-shape vocabulary only, and ID-level skewness such as `skew(id) ~ x` stays design-only until simulation separates it from residual skewness and heteroscedasticity. |
| 195 | Zero-inflation, hurdle, and one-inflation random effects | Done and extended: `zi`, `hu`, `zoi`, and `coi` random-effect requests receive component-specific boundaries. Fixed-effect zero-inflation and hurdle paths remain implemented, and fixed-effect `zoi`/`coi` are now fitted only in `zero_one_beta()`; count-side random effects in zero-inflated or hurdle routes and covariance among `mu`, `sigma`, shape, inflation, hurdle, or one-inflation random effects remain future work until likelihood, interval, and recovery evidence exists. |
| 196 | Ordinal mixed models | Done: cumulative-logit `mu` random-effect bar terms now have an ordinal-specific boundary. The first future ordinal mixed target remains a random intercept such as `(1 | id)`; ordinal random slopes, scale/discrimination formulas, known covariance, phylo/spatial ordinal effects, and `ordinal::clmm` comparator recovery stay planned. |
| 197 | Structured non-Gaussian random effects | Done: phylogenetic, spatial, animal, and `relmat()` structured markers now have a structured non-Gaussian boundary. Structured count, bounded, ordinal, shape, inflation, and hurdle paths stay deferred until ordinary family-specific random effects and their intervals are stable. The first fitted animal/`relmat()` slice is Gaussian `mu` only. |
| 197a | Animal/relmat reference surface | Done locally: `animal()` and `relmat()` are documented and parsed as structured-effect markers, the reference index leads with animal/phylo/spatial/relmat rather than `gr()`, and `gr()` is deprecated as a public marker while kept as a compatibility placeholder. Later slices add known-matrix Gaussian `mu` intercept fitting for `A`/`Ainv` and `K`/`Q`, dense pedigree fitting for `animal(pedigree = ...)`, and one numeric univariate Gaussian `mu` slope; sparse large-pedigree construction, multiple slopes, and slope correlations remain planned. |
| 198 | Non-Gaussian interval readiness | Done locally: `summary(conf.int = TRUE)` now handles fitted non-Gaussian paths with no summary-level parameter rows, including cumulative-logit ordinal fits with fixed effects or cutpoints only; Wald coefficient intervals remain available, empty coefficient/parameter tables keep explicit interval-status columns, and profile targets stay discoverable through `profile_targets()`/`confint()`. |
| 199 | Reader-facing family docs | Done locally: the model map, family chooser, and structural-dependence article now show implemented, planned, and unsupported states for non-Gaussian random effects and the structural-dependence ladder: animal, phylogeny, spatial, phylogeny plus spatial, then lower-level `relmat()` known-dependence matrices. |
| 200 | Focused non-Gaussian recovery tests | Done locally: ordinary non-zero-inflated Poisson `mu` random-effect recovery now includes a factor-predictor random-intercept case and a weak-SD boundary case that exercises `check_drm()` lower-boundary diagnostics. |
| 201 | Failure ledger | Done locally: `docs/design/34-validation-debt-register.md` now names the convergence, boundary, identifiability, interval, and runtime failures that Phase 18 should measure or exclude for ordinary Poisson, NB2, non-Gaussian scale, shape/skewness, inflation, ordinal, structured, cross-parameter covariance, interval, and runtime surfaces. |
| 202 | Pre-simulation decision gate | Done locally: do not start broad comprehensive Phase 18 yet. Permit only a narrow Poisson `mu` random-effect pilot grid if simulation begins now; otherwise return after Slice 202 to the Phase 17 hardening block, especially meta-analysis `meta_V()`/known-`V` API and interval safety. |

### Slice 202 Pre-Simulation Decision Gate

The Slices 190-202 non-Gaussian gate closes with a narrow decision. The package
has enough evidence to simulate the currently fitted ordinary Poisson `mu`
random-effect path, but not enough evidence to call the next phase a broad
comprehensive simulation.

| Decision Area | Slice 202 Decision | Reason |
| --- | --- | --- |
| Broad Phase 18 comprehensive simulation | Wait. | Too many neighbouring surfaces remain planned or blocked: NB2 `sigma` slopes or structured effects, other non-Gaussian `sigma` random effects, shape/skew random effects, inflation and hurdle random effects, ordinal mixed models, structured non-Gaussian slopes or labelled blocks, cross-parameter non-Gaussian covariance, bootstrap intervals, and derived nonlinear interval coverage. |
| Narrow pilot simulation | Implemented smoke surfaces for Poisson and NB2 `mu` random effects, plus focused ordinary NB2 `sigma`, NB2 q=1 phylogenetic, and count q=1 structured-intercept lanes. | Ordinary non-zero-inflated Poisson and NB2 `mu` random intercepts plus independent numeric slopes have implementation, extractors, `sdpars$mu`, direct profile targets, focused recovery tests, weak-SD boundary diagnostics, Phase 18 smoke runners, manifests, failure ledgers, Wald fixed-effect coverage rows, and direct random-effect SD profile coverage rows. Ordinary NB2 log-`sigma` random intercepts now have a dedicated smoke-grid artifact writer; ordinary NB2 q=1 phylogenetic `mu` has an overdispersion-aware formal-admission lane and local Slices 541-555 audit, but still requires the 500-replicate formal grid before routine recovery or coverage claims. The q=1 spatial/animal/`relmat()` count additions now have focused source tests plus an opt-in smoke artifact lane, not broad simulation admission. |
| Post-202 work direction | Return to Phase 17 before full Phase 18. | Reader-facing inference and examples still need hardening before large simulation reports are useful. The first return block should focus on meta-analysis: preferred `meta_V(V = V)` spelling, vector and matrix `V`, proportional `meta_V(w = w, scale = "proportional")` design boundaries, profile/summary safety, and clear examples. |
| Phase 18 entry rule | Open full grids only surface by surface. | Each surface needs a fitted likelihood, parser validation, extractors, diagnostics, direct or explicitly unavailable interval targets, focused recovery tests, and a failure-ledger row before it appears in a comprehensive simulation table. |

The immediate next block is therefore a Phase 17 return block, not a leap into
full Phase 18. If a simulation task starts before that block closes, it should
be labelled as a Poisson `mu` random-effect pilot with explicitly limited
estimands, not as the comprehensive drmTMB simulation programme.

### Post-202 Phase 17 Return: Meta-Analysis Hardening

The first return block after Slice 202 is meta-analysis hardening. This block
keeps meta-analysis as Gaussian regression with known sampling covariance while
making the public grammar and examples match the preferred long-term name.

| Slice | Lane | Target |
| --- | --- | --- |
| 203 | Meta-analysis return map | Done locally: record the post-202 return block, keep broad Phase 18 closed, and make `meta_V()`/known-`V` hardening the first Phase 17 target. |
| 204 | `meta_V()` API decision | Done locally and superseded by the deprecation slice: `meta_V(V = V)` is the preferred additive known-covariance spelling, the marker should not take a positional response/value argument, and deprecated `meta_known_V(V = V)` remains a compatibility alias rather than a separate likelihood path. |
| 205 | Additive known `V` implementation | Done locally: `meta_V(V = vi_or_V)` is accepted for the additive known-covariance route; deprecated `meta_known_V(V = V)` still shares that path for compatibility. Proportional `meta_V(w = w, scale = "proportional")` remains rejected before fitting. |
| 206 | Proportional sampling-variance boundary | Done locally: keep `meta_V(w = w, scale = "proportional")`, `meta_V(w = w)`, and `meta_V(V = V, scale = "exact")` reserved before fitting; clarify that diagonal/vector `meta_V(V = V)` may use ordinary likelihood weights, full matrix-`V` rejects non-unit weights, and neither route mimics proportional sampling variance. |
| 207 | Meta-analysis interval safety | Done locally: add profile-target and summary interval tests proving `meta_V()` fits expose estimated `sigma`, random-effect SD, and bivariate `rho12` targets while never treating known `V` as an estimated interval target. |
| 208 | Reader examples | Done locally: refresh the meta-analysis tutorial and design examples around preferred `meta_V(V = V)`, vector `V`, matrix `V`, residual heterogeneity `sigma`, random effects, random-effect scale, bivariate known `V`, and the unsupported proportional branch. |

Do not introduce `meta_gaussian()` or `tau ~` syntax in this block. Keep
`sigma` as the fitted extra heterogeneity SD, and explain the translation to
meta-analytic `tau` only in prose and tables.

Slice 190 decision: the first non-Gaussian implementation target should be
ordinary `mu` random intercepts for the count families whose fixed-effect
likelihoods already have focused tests and clear response-scale interpretation.
Use this order unless Slice 191 evidence overturns it:

| Priority | Family Surface | Slice 190 Decision |
| --- | --- | --- |
| 1 | Poisson `mu` | Implemented in Slices 191-192 for ordinary `(1 | group)` and independent numeric `(0 + x | group)` terms in the log-mean predictor, with recovery, lme4 comparator, and direct SD profile target coverage. Correlated slope blocks, labelled blocks, zero-inflation random effects, and cross-parameter covariance remain planned. |
| 2 | NB2 and zero-truncated NB2 `mu` | NB2 ordinary `mu` random intercepts, independent numeric slopes, and ordinary log-`sigma` random intercepts are now fitted for non-zero-inflated models. Zero-truncated NB2 ordinary `mu` random intercepts and independent numeric slopes are fitted, with the intercept slice covered by a Phase 18 artifact lane. Zero-inflated NB2 random effects, correlated zero-truncated slopes, NB2 `sigma` slopes, joint `mu`/`sigma`, and structured `sigma` effects remain planned. |
| 3 | Lognormal, Gamma, Student-t, and bounded-response `mu` | Lognormal, Gamma, Student-t, beta, and beta-binomial ordinary `mu` random intercepts are fitted as narrow first slices and now have Phase 18 artifact lanes; independent numeric `mu` slopes have focused recovery tests. Correlated Student-t, positive-continuous, and bounded-response random slopes, `sigma` random effects, Student-t `nu` random effects, and richer mixed-model surfaces remain later because scale, tail, strict-boundary, denominator, and weak-SD diagnostics need their own grids. |
| 4 | Zero-inflation, one-inflation, hurdle, ordinal, shape, and structured non-Gaussian paths | Keep random-effect and structured routes unsupported for now; revisit in Slices 194-197. For proportion data, fixed-effect `zoi` and `coi` belong to `zero_one_beta()`, not the Poisson count gate. |

- After Slice 202, return to Phase 17 to close the remaining visualization,
  marginal-effect, contrast, slope, and reader-facing inference surfaces. Phase
  18 comprehensive simulation starts only after that resumed Phase 17 closure
  gate, unless the project deliberately opens a smaller pilot simulation with a
  narrower estimand.
- Slices 160-164 close the first confidence-band documentation block and reopen
  the profile-interval inventory. Slice 160 adds the factor-predictor
  interval-bar example and a real prediction-table test. Slice 161 makes
  fitted-row `newdata_required` visible as an action status. Slice 162 shows a
  non-default `conf.level` and states that the level must be read with
  `conf.status` and `interval_source`. Slice 163 is the render/pkgdown/stale
  wording gate for this confidence-band block. Slice 164 refreshes the
  profile-target inventory for fixed effects, constant distributional
  parameters, row-specific `newdata` profiles, ordinary random-effect SDs and
  correlations, modelled `sd(group)` surfaces, q2 and q4 covariance rows,
  phylogenetic/spatial SDs, derived summaries, and ordinal cutpoint internals.
- Slices 169-176 close the interval-readiness gate before random-slope work.
  The important boundary is negative but useful: q4 correlations and covariance
  products remain derived interval-unavailable rows, and bootstrap intervals are
  not a public method until a deterministic simulate-refit harness, target
  extractor, failure ledger, and runtime policy exist.
- Add additional ggplot-oriented helpers only after the data contract is stable:
  location curves, scale/variance curves, residual `rho12` curves,
  `sd(group)` or `sd_phylo()` surfaces, `corpairs()` summaries, and eventually
  spatial fields or maps.
- Treat predictions, adjusted predictions, estimated marginal means, contrasts,
  slopes, and diagnostics as separate estimands. Do not hide reference grids,
  marginalization rules, weighting choices, or link-versus-response scale
  decisions inside a plotting call.
- Every visual interval must state its inference source: Wald fixed-effect
  interval, direct profile-likelihood interval, derived nonlinear interval,
  conditional random-effect uncertainty, or parametric-bootstrap interval.
  Fisher's default is to avoid implying full uncertainty when only fixed-effect
  uncertainty is present.
- Pat's usability gate: examples should show the biological question, the
  fitted model, the visualization call, and the interpretation in one path.
  Rose's audit gate: plotting docs must not overclaim support for parameters or
  interval types that the model object cannot yet supply.
- Design visualization helpers with Phase 18 simulations in mind. Simulation
  studies need plots for bias, root-mean-square error, empirical coverage,
  convergence, interval width, and power curves, so the visualization layer
  should expose reusable data frames rather than only polished figures.
- Slice 259 reopens the public visualization route after the first count-pilot
  diagnostics page proved too narrow to be called a gallery. The user-facing
  `vignettes/figure-gallery.Rmd` should be the Florence showcase for raw data
  plus fitted slopes, 95% confidence bands, categorical and continuous
  interactions, `emmeans` displays, fitted correlation layers, and simulation
  operating-characteristic plots. Simulation and comparator outputs get their
  own pkgdown section, "Simulation & Comparison", so power, bias, coverage,
  runtime, convergence, and failure-ledger articles do not compete with
  tutorials.

### Florence Figure-Gallery Slice Map

| Slice | Target | Done When |
| --- | --- | --- |
| 259 | First public figure gallery route | Done locally: `figure-gallery` is a Tutorials article, `convergence` is a Model Guides article, and `testing-likelihoods` moved to Simulation & Comparison. |
| 260 | Interaction plot polish | The gallery shows categorical x continuous, categorical x categorical, and continuous x continuous examples with fitted values, raw data where useful, 95% confidence intervals, and clear conditioning labels. |
| 261 | Distributional-parameter panels | Done locally: the gallery now labels `mu` and `sigma` panels by estimand and adds fitted Student-t `nu`, zero-inflation probability `zi`, and residual `rho12` examples with explicit response-scale wording and interval provenance. |
| 262 | Random-effect and variance-component figures | Done locally: the gallery now compares residual `sigma` with ordinary group-level intercept and slope SDs, shows conditional random-slope deviations, and plots a fitted `sd(site)` surface while keeping unavailable interval status explicit. |
| 263 | Correlation-layer figures | Done locally and refreshed after the q=4 spatial slice: the gallery now facets implemented residual, ordinary group, phylogenetic, spatial, animal, and `relmat()` q=2 `corpairs()`-style rows, marks spatial q=4 as partly fitted, and keeps richer structured correlation regressions plus standalone scale extensions planned. |
| 264 | `emmeans` and marginal-effects figures | Done locally: the gallery now shows the supported fixed-effect univariate `mu` `emmeans` route, factor-conditioned and interaction grids, an empirical `marginal_parameters()` summary, and unsupported boundaries for `sigma`, bivariate, zero-inflated, hurdle, ordinal, and random-effect targets. |
| 265 | Simulation plot grammar | Done locally: `simulation-plot-grammar` is a Simulation & Comparison article with display contracts for bias, RMSE, coverage, power, convergence, runtime, and warning/error ledgers across continuous, proportion, count, and meta-analysis examples. |
| 266 | Gallery source-map and QA | Done locally: the figure gallery now has a source-map table mapping each display to its fitted object or fixture, extractor or plotter, interval source, and support boundary, with render, pkgdown, and visual checks recorded. |
| 267 | Florence closeout | Done locally: the visualization grammar now records that `plot_parameter_surface()` and `plot_corpairs()` remain the exported helpers, most gallery displays stay tutorial-level `ggplot2` recipes, and simulation/failure-ledger helpers wait for stable Phase 18 result schemas. |
| 299 | Florence visual repair | Done locally: the gallery now draws raindrop-style compatibility displays for `mu`, `sigma`, and correlation intervals, uses shared palettes more consistently, recolours formerly default-black discrete and empirical displays, improves status-strip label contrast, and replaces the simulation bias line plot with raincloud-style replicate clouds plus mean/MCSE intervals because estimands are categorical targets, not trajectories. |
| 300 | Simulation raincloud grammar | Done locally: the Simulation & Comparison plot-grammar article now shows bias as replicate-level error clouds with mean/MCSE intervals in fixed surface facets and keeps RMSE in a separate aggregate point/MCSE panel, so future Phase 18 reports have a clear visual contract before exported simulation plot helpers exist. |
| 301 | Count gallery accuracy grammar | Done locally: the Phase 18 count-pilot gallery now uses fixed family facets for bias and RMSE, draws MCSE bars when aggregate CSVs include `bias_mcse` or `rmse_mcse`, and states that replicate-error clouds wait for replicate-level output instead of being faked from aggregate rows. |
| 302 | Implementation map | Done locally: `implementation-map` is a Model Guides article that maps fitted, first-slice, fixed-effect-only, planned, and blocked surfaces across families, random-effect layers, q, random slopes, `corpairs()`, `zi`, and `hu`, and it refreshes stale structured-slope status after Slices 39-82 and 83-140. |
| 303 | Generic direct-SD design gate | Done locally as planning: `docs/design/62-implementation-map-slices-303-310.md` records that future direct-SD work should design generic `sd*()` grammar and compatibility before copying `sd_phylo*()`-style names across spatial, animal, or `relmat()` layers. |
| 304 | p8/q8 location-scale planning gate | Done locally as planning: the implementation-map roadmap now keeps p8/q8 as a design-first lane requiring endpoint labels, block size, positive-definite parameterization, diagnostics, and interval policy before likelihood code. |
| 305 | Structured q=4 parity plan | Done locally as planning: spatial, animal, and `relmat()` q=4 parity should move one structured level at a time with `corpairs()`, diagnostics, examples, and simulation evidence. |
| 306 | q=4 interval policy | Done locally as planning: derived q=4 correlations keep explicit unavailable interval status until a direct or derived-profile method is designed, tested, and documented. |
| 307 | Inflation and hurdle random-effect decision gate | Done locally as a no-fit decision and later updated by the zero-one beta source slice: `zi`, `hu`, `zoi`, and `coi` stay fixed-effect-only where implemented; random effects wait for clear use cases, recovery, diagnostics, prediction semantics, and interval-status rules. |
| 308 | Non-Gaussian structured-dependence candidate map | Done locally as planning: the next non-Gaussian structured-dependence step should choose one family and one dependence layer only after ordinary likelihood, extractor, diagnostic, profile-target, and simulation gates are clear. |
| 309 | Implementation-map maintenance gate | Done locally as process: after substantial feature slices, update implementation-map, model-map, README, ROADMAP, NEWS, and stale-claim scans together. |
| 310 | User-route examples gate | Done locally as planning: planned rows should point users toward the nearest fitted alternative, design note, or tutorial boundary instead of making unsupported syntax look runnable. |
| 311 | Generic `sd*()` contract | Done locally as planning: `docs/design/63-implementation-map-slices-311-325.md` records explicit level-targeted direct-SD syntax as the future direction, while keeping current `sd_phylo*()` routes compatible and ordinary `sd(group)` distinct. |
| 312 | Direct-SD ambiguity guard | Done locally as planning: ordinary random-effect SD surfaces and future structured direct-SD routes must stay distinguishable in parsing, examples, and the reference index. |
| 313 | Direct-SD user migration | Done locally as planning: generic direct-SD syntax needs compatibility wording, examples, and stale-name scans before users are moved away from existing `sd_phylo*()` names. |
| 314 | p8/q8 endpoint taxonomy | Done locally as planning: q2 slope-only, q4 location slope, q6 partial location-scale, and q8 all-endpoint slope covariance are separated before public syntax opens. |
| 315 | p8/q8 parameterization risk | Done locally as planning: full q8 remains high risk because eight SDs and 28 correlations may be weakly identified; constrained or block-diagonal designs should be considered first. |
| 316 | p8/q8 diagnostics gate | Done locally as planning: any p8/q8 route needs profile-target labels, Hessian/boundary diagnostics, recovery tests, and tutorial warnings before user claims. |
| 317 | Structured q4 ordering | Done locally as planning and superseded by Slices 356-380: spatial q4 was the next constant structured q4 parity lane, while animal and `relmat()` q4 need continued diagnostics and simulation hardening rather than a new fitted claim. |
| 318 | q4 interval contract | Done locally as planning: q4 rows remain estimates with explicit derived-unavailable interval status until direct or derived-profile methods are designed and tested. |
| 319 | Non-Gaussian candidate scoring | Done locally as planning: candidate non-Gaussian structured routes are scored by family maturity, dependence layer, diagnostics, extractor impact, and user value before coding. |
| 320 | First non-Gaussian structured candidate recommendation | Done locally as planning: start with one q1 `mu` structured intercept, likely Poisson as an algebra smoke and NB2 as the first practical count target, before slopes, zero inflation, hurdle probability, or q4. |
| 321 | User-route examples | Done locally as planning: common planned requests now point users toward fixed-effect or smaller fitted alternatives in the implementation map. |
| 322 | Implementation-map sync | Done locally: the public map now carries the 311-325 planning rows and common planned-request table. |
| 323 | Roadmap, NEWS, and check-log | Done locally: the ledger records this set as planning/documentation, not likelihood expansion. |
| 324 | After-task protocol | Done locally: the after-task report records roles, usefulness, checks, and remaining boundaries. |
| 325 | Validation | Done locally: pkgdown and stale-claim scans confirm the rendered map and guardrails. |
| 326 | Generic direct-SD issue spec | Done locally as pre-code: `docs/design/64-implementation-map-slices-326-340.md` records the grammar, compatibility, endpoint, reference-index, and test decisions required before generic structured direct-SD parser work. |
| 327 | Direct-SD parser boundary matrix | Done locally as pre-code: ordinary `sd(group)`, current `sd_phylo*()`, and future level-targeted structured SD routes have separate parser outcomes. |
| 328 | Direct-SD tests and docs checklist | Done locally as pre-code: next direct-SD work requires malformed-input tests, prediction/profile rows, examples, reference docs, and stale-name scans. |
| 329 | p8/q8 endpoint registry sketch | Done locally as pre-code: q2 slope-only, q4 location slope, q6 partial location-scale, and q8 all-endpoint slope classes are named. |
| 330 | p8/q8 staged implementation options | Done locally as pre-code: q4 location-slope and constrained or block-diagonal routes are preferred before full q8 unstructured covariance. |
| 331 | p8/q8 simulation gate | Done locally as pre-code: any q4/q6/q8 slope endpoint must vary group count, repeats, SD ratios, correlations, covariate spread, and boundary cases. |
| 332 | Spatial q4 pre-code checklist | Done locally as pre-code: spatial q4 requires matching labelled terms, extractor rows, `corpairs()`, diagnostics, direct/derived interval status, and a small smoke before tutorial claims. |
| 333 | Structured q4 diagnostics checklist | Done locally as pre-code: q4 rows need Hessian, boundary, profile-target, and derived-interval status checks before routine teaching. |
| 334 | Poisson structured q1 smoke spec | Done locally as pre-code: the first non-Gaussian structured candidate is a q1 Poisson `mu` structured intercept smoke. |
| 335 | NB2 structured q1 practical spec | Done locally as pre-code: NB2 `mu` q1 structured intercept is the first practical count target after Poisson smoke and overdispersion checks. |
| 336 | Non-Gaussian structured ADEMP stub | Done locally as pre-code: the candidate needs an ADEMP sheet before simulation code enters Phase 18. |
| 337 | User-route example expansion | Done locally: the public implementation map now gives more explicit fitted alternatives for planned direct-SD, q4, p8/q8, and non-Gaussian structured requests. |
| 338 | Stale-claim checklist | Done locally: validation targets false fitted claims for generic `sd*()`, p8/q8, spatial q4, and non-Gaussian structured routes. |
| 339 | Roadmap and NEWS sync | Done locally: public and dev ledgers record these as pre-code slices. |
| 340 | After-task and validation | Done locally: the after-task report and pkgdown checks close the slice set. |
| 341 | Generic direct-SD issue template | Done locally as planning: `docs/design/65-implementation-map-slices-341-355.md` records the issue fields needed before generic structured direct-SD parser work starts. |
| 342 | Generic direct-SD acceptance checklist | Done locally as planning: future direct-SD issues require parser, fit-time, prediction/profile, reference, rendered-discoverability, and stale-name checks before closing. |
| 343 | Direct-SD migration and stale-scan recipe | Done locally as planning: existing `sd_phylo*()` users keep compatibility while future generic examples appear only for fitted layers. |
| 344 | p8/q8 issue template | Done locally as planning: future all-endpoint location-scale slope issues must name the endpoint class, covariance structure, interval policy, diagnostics, and nearest fitted alternative. |
| 345 | p8/q8 acceptance checklist | Done locally as planning: p8/q8-adjacent code needs recovery, malformed-input, `corpairs()`, profile-target, Hessian, boundary, and tutorial-warning evidence before user claims. |
| 346 | Spatial q4 issue template | Done locally as planning: spatial q4 parity is specified as constant location-scale spatial intercepts, separate from mesh/SPDE, slope, direct-SD, and non-Gaussian routes. |
| 347 | Spatial q4 acceptance checklist | Done locally as planning: spatial q4 requires endpoint-consistent likelihood, parser, extractor, diagnostics, `corpairs()`, profile-target, and pkgdown example evidence. |
| 348 | Poisson structured q1 issue template | Done locally as planning: the first non-Gaussian structured-dependence issue is scoped to one non-zero-inflated Poisson `mu` structured intercept. |
| 349 | Poisson structured q1 acceptance checklist | Done locally as planning: Poisson q1 structured dependence needs one named layer, guarded neighbouring syntax, simulation recovery, and first-slice docs before advertising. |
| 350 | NB2 structured q1 issue template | Done locally as planning: NB2 q1 structured dependence is the first practical count target after Poisson smoke or an explicit safety justification. |
| 351 | NB2 structured q1 acceptance checklist | Done locally as planning: NB2 q1 requires overdispersion-aware recovery, distinct ordinary-versus-structured labels, scale-honest reporting, guarded `zi`/`hu`, and fallback guidance. |
| 352 | Non-Gaussian structured ADEMP gate | Done locally as planning: Poisson or NB2 structured q1 must have an ADEMP sheet before Phase 18 admits it. |
| 353 | User documentation checklist | Done locally as planning: future implementation issues must synchronize implementation-map, model-map, reference or tutorial docs, README when appropriate, ROADMAP, NEWS, check-log, and after-task notes. |
| 354 | Review and issue-maintenance checklist | Done locally as planning: Ada, Boole, Gauss, Noether, Fisher, Curie, Pat, Darwin, Grace, and Rose review coverage is named before closing future implementation issues. |
| 355 | Validation and handoff gate | Done locally as planning: pkgdown, rendered scans, stale-support scans, after-task reporting, and the next code issue must be recorded before handoff. |
| 356 | Spatial q4 admission | Done locally: matching labelled `spatial()` terms across `mu1`, `mu2`, `sigma1`, and `sigma2` are admitted into the shared structured q4 backend. |
| 357 | Spatial q4 parser boundaries | Done locally: partial, unlabelled, mismatched, and slope spatial q4 requests remain rejected with targeted messages. |
| 358 | Spatial q4 extractor labels | Done locally: spatial q4 exposes four endpoint SDs and six derived latent correlations with spatial labels. |
| 359 | Spatial q4 `corpairs()` rows | Done locally: `corpairs(level = "spatial")` reports six q4 rows and keeps them separate from residual `rho12`. |
| 360 | Spatial q4 covariance summary | Done locally: `summary()$covariance` mirrors the six q4 spatial rows. |
| 361 | Spatial q4 profile-target status | Done locally: direct SD rows and derived-unavailable q4 correlation rows are represented honestly in profile metadata. |
| 362 | Spatial q4 diagnostics | Done locally: `check_drm()` reports `biv_spatial_q4_covariance` with replication, SD-ratio, boundary, and covariance-mode evidence. |
| 363 | Spatial q4 focused test | Done locally: `test-spatial-gaussian` covers the fitted route and malformed-input neighbours. |
| 364 | Spatial q4 user-facing table | Done locally: README, model-map, implementation-map, and structural docs mark q4 spatial as fitted first-slice support. |
| 365 | Spatial q4 formula grammar | Done locally: formula grammar lists the supported all-four labelled spatial endpoint route. |
| 366 | Spatial q4 tutorial route | Done locally: the coordinate-spatial article now shows q4 syntax and interval limitations. |
| 367 | Spatial q4 figure/status sync | Done locally: the figure gallery separates fitted q2, partly fitted q4, and planned regression/scale extensions. |
| 368 | Spatial q4 stale-scan gate | Done locally: high-traffic wording no longer says the constant spatial q4 route is only planned. |
| 369 | Spatial q4 release note | Done locally: NEWS records the fitted route and remaining boundaries. |
| 370 | Spatial q4 fitted-slice closeout | Done locally: the implementation claim stops at constant Gaussian bivariate location-scale intercepts. |
| 371 | Map table sync | Done locally: the implementation map separates fitted spatial q4 from mesh, direct-SD, slope, and non-Gaussian spatial plans. |
| 372 | Model-map sync | Done locally: the stable-core matrix includes the constant q4 spatial route. |
| 373 | Spatial article sync | Done locally: the coordinate-spatial page gives the q4 syntax and interpretation boundary. |
| 374 | Structural overview sync | Done locally: the structural overview routes spatial users to q2 and q4 fitted first slices. |
| 375 | Detailed structural article sync | Done locally: the detailed structural-dependence article now lists spatial q4 parity. |
| 376 | Formula grammar sync | Done locally: grammar docs and vignette list fitted q4 spatial syntax. |
| 377 | Check-log and after-task sync | Done locally: the dev ledger records implementation, checks, usefulness, and limits. |
| 378 | pkgdown sync | Done locally: pkgdown build/check and rendered scans cover the implementation-map page. |
| 379 | PR/status sync | Done locally: the branch records spatial q4 as fitted only after tests and docs move together. |
| 380 | Stop-implementation boundary | Done locally: no non-Gaussian structured likelihood code is fitted in this set. |
| 381 | Non-Gaussian family inventory | Done locally as planning: ordinary count, zero-inflated count, hurdle count, bounded response, ordinal, robust continuous, and mixed-response candidates are separated in `docs/design/66-implementation-map-slices-356-405.md`. |
| 382 | Non-Gaussian component inventory | Done locally as planning: `mu`, `sigma`, `zi`, `hu`, shape/`nu`, future `tau`, cutpoints, and residual coscale `rho12` remain separate gates before structured dependence expands. |
| 383 | Non-Gaussian layer inventory | Done locally as planning: `phylo()`, `spatial()`, `animal()`, and `relmat()` are scored separately, with Poisson phylogenetic q1 kept apart from Gaussian spatial, animal, and `relmat()` evidence. |
| 384 | Poisson q1 algebra gate | Done locally as planning: the first structured non-Gaussian simulation gate is one non-zero-inflated Poisson `mu` phylogenetic intercept, with ADEMP details in `docs/design/70-phase-18-poisson-structured-q1-ademp.md`. |
| 385 | NB2 q1 practical gate | Done locally as planning: NB2 q1 remains the first practical count target after Poisson, because overdispersion can compete with the structured SD. |
| 386 | Zero-inflation gate | Done locally as planning: `zi` stays fixed-effect-only until a separate probability-component use case, diagnostic, and prediction contract exists. |
| 387 | Hurdle gate | Done locally as planning: `hu` stays fixed-effect-only until hurdle-specific recovery and interpretation are specified. |
| 388 | Count slope gate | Done locally as planning: correlated or structured count slopes wait until q1 intercept recovery is reliable. |
| 389 | Non-Gaussian scale gate | Done locally as planning: count overdispersion, beta/BB precision, Gamma coefficient of variation, lognormal log-SD, and Student-t scale each need family-specific structured-scale contracts before structured random effects move outside `mu`. |
| 390 | Shape and ordinal gate | Done locally as planning: Student-t `nu`, future skewness/second-shape slots, ordinal cutpoints, and ordinal scale/discrimination stay separate from count `mu` structure. |
| 391 | Known covariance boundary | Done locally as planning: `meta_V(V = V)` remains known sampling covariance and `relmat()` remains latent relatedness; future issues must not collapse those meanings. |
| 392 | Extractor contract | Done locally as planning: first slices must pre-name `sdpars`, `ranef()`, `profile_targets()`, `summary()`, and diagnostic labels before fitting. |
| 393 | Diagnostic contract | Done locally as planning: convergence, Hessian, replication, boundary, SD-ratio, family-specific, and malformed-neighbour checks are required beyond optimizer return code. |
| 394 | Simulation contract | Done locally as planning: ADEMP, ordinary comparator, recovery estimands, MCSE, failure ledger, and artifact manifest are required before Phase 18 admission. |
| 395 | Interval contract | Done locally as planning: direct structured SD intervals may move first, while derived correlations and non-direct nonlinear summaries must show unavailable status until validated. |
| 396 | User-route fallback | Done locally as planning: unsupported requests should point to fixed-effect, ordinary random-effect, or Gaussian structured alternatives where those answer a safer nearby question. |
| 397 | Error-message gate | Done locally as planning: unsupported `zi`, `hu`, slope, q2, q4, and cross-parameter structured requests must fail early with family, component, layer, and nearest route named. |
| 398 | Formula grammar gate | Done locally as planning: non-Gaussian structured grammar remains closed unless fitted scope and rejected neighbours are documented together. |
| 399 | Documentation gate | Done locally as planning: implementation-map, model-map, family docs, NEWS, ROADMAP, check-log, and after-task reports must move with any fitted-status change. |
| 400 | Issue-template gate | Done locally as planning: future implementation issues must name one family, component, layer, q, and comparator rather than asking for broad non-Gaussian parity. |
| 401 | Poisson first-issue outline | Done locally as planning: the next code issue should be one non-zero-inflated Poisson `mu` q1 phylogenetic intercept with simulations, diagnostics, docs, and malformed neighbours. |
| 402 | NB2 first-issue outline | Done locally as planning: NB2 q1 needs fixed-effect `sigma`, overdispersion conditions, and ordinary NB2 comparator evidence before structured count claims expand. |
| 403 | `zi`/`hu` future issue outline | Done locally as planning: probability-component random effects need a biological use case, prediction semantics, diagnostics, and recovery evidence before fitting. |
| 404 | Phase 18 admission note | Done locally as planning: non-Gaussian structured routes remain outside broad simulation until one narrow route passes recovery, diagnostics, intervals, and docs. |
| 405 | Non-Gaussian planning closeout | Done locally as planning: the closeout stops with a map, issue-ready gates, and validation evidence rather than untested likelihood code. |
| 406 | Route-specific issue ledger | Done locally as planning: `docs/design/71-nongaussian-structured-issue-ledger.md` records the route key and review fields for future implementation issues. |
| 407 | Poisson q1 implementation issue draft | Done locally as planning: the issue draft names one Poisson `mu` q1 phylogenetic route, extractor evidence, diagnostics, docs, and excluded neighbours. |
| 408 | Poisson q1 smoke-runner issue draft | Done locally as planning: the issue draft names the DGP, runner files, artifact schema, and initial smoke grid. |
| 409 | Poisson q1 malformed-neighbour issue draft | Done locally as planning: the issue draft lists unsupported slopes, q2/q4, `zi`, `hu`, NB2, spatial, animal, `relmat()`, scale, shape, ordinal, bounded-response, and cross-parameter requests. |
| 410 | Poisson q1 documentation issue draft | Done locally as planning: the issue draft names the pages that must move only after implementation and validation evidence exists. |
| 411 | NB2 q1 aims skeleton | Done locally as planning: NB2 q1 starts from overdispersion-versus-structured-SD recovery, not syntax parity. |
| 412 | NB2 q1 DGP skeleton | Done locally as planning: the future DGP includes fixed-effect `sigma`, phylogenetic `mu` SD, mean-count levels, overdispersion levels, and tree conditioning. |
| 413 | NB2 q1 estimands and comparator | Done locally as planning: fixed `mu`, fixed `sigma`, structured SD, direct interval target, and ordinary NB2 grouped comparator are named. |
| 414 | NB2 q1 performance measures | Done locally as planning: bias, RMSE, coverage, direct SD profile status, convergence, Hessian, boundary, warning/error, runtime, and MCSE reporting are required. |
| 415 | `zi`/`hu` probability-component contract | Done locally as planning: structured probability-component effects need use cases, prediction semantics, diagnostics, and recovery before syntax. |
| 416 | Non-Gaussian scale public-name contract | Done locally as planning: structured scale effects need family-specific interpretation and separation from latent structured SD. |
| 417 | Shape and ordinal public-name contract | Done locally as planning: shape and ordinal random effects need comparator and boundary evidence before mixed-model syntax. |
| 418 | Known covariance versus latent relatedness issue contract | Done locally as planning: issue titles, formulas, diagnostics, and examples must keep known sampling covariance separate from latent relatedness. |
| 419 | Structured count q1 extractor-name registry | Done locally as planning: `sdpars$mu`, route-specific `ranef()`, direct `log_sd_*`, and absent q1 `corpairs()` rows are reserved before code. |
| 420 | Structured count q1 diagnostic-name registry | Done locally as planning: replication, SD-ratio/boundary, Hessian, fixed-gradient, family warning, and unsupported-neighbour rows are reserved before code. |
| 421 | Poisson q1 direct profile-target contract | Done locally as planning: the runner contract requires a direct `log_sd_phylo` profile-target row for ordinary Poisson q1 phylogenetic `mu`. |
| 422 | Poisson q1 extractor contract | Done locally as planning: `sdpars$mu`, `ranef("phylo_mu")`, fixed `mu` coefficients, and absent q1 `corpairs()` rows are required checks. |
| 423 | Poisson q1 artifact manifest schema | Done locally as planning: surface, cell, replicate, seed, artifact, path, existence, row count, worker, and session fields are required. |
| 424 | Poisson q1 warning/error ledger schema | Done locally as planning: simulate, fit, extract, diagnose, profile, and write stages must report status, messages, convergence, Hessian, and elapsed time. |
| 425 | Poisson q1 smoke-grid gate | Done locally as planning: the first local grid varies species count, observations per species, true phylogenetic SD, mean count, tree conditioning, and 20 smoke replicates per cell. |
| 426 | Poisson q1 formal-grid admission gate | Done locally as planning: formal recovery or coverage claims require MCSEs, diagnostics, failure ledgers, interval-status rows, and at least 500 replicates per cell. |
| 427 | Poisson q1 ordinary-comparator contract | Done locally as planning: ordinary grouped Poisson remains a diagnostic contrast, not a phylogenetic-signal estimator. |
| 428 | Count tutorial stale-boundary correction | Done locally as documentation: count docs should say ordinary Poisson q1 phylogenetic `mu` is fitted while NB2, `zi`, `hu`, slope, q2/q4, spatial, animal, and `relmat()` routes remain planned. |
| 429 | Public-map status guard | Done locally as planning: implementation-map and model-map wording must keep the fitted q=1 count structured slices separate from broad count structured parity. |
| 430 | Likelihood-doc status guard | Done locally as planning: likelihood docs should tie the Poisson q1 route to the log-mean likelihood, direct target, and excluded neighbours. |
| 431 | Poisson q1 unsupported-syntax error table | Done locally as planning: unsupported slope, q2/q4, `zi`, NB2, spatial, animal, `relmat()`, scale, shape, ordinal, bounded, and mixed-response requests have expected guidance. |
| 432 | Poisson q1 malformed syntax test plan | Done locally as planning: malformed neighbours should fail before TMB fitting with family, component, layer, and nearest route named. |
| 433 | Poisson q1 extractor-name test plan | Done locally as planning: tests should assert exact `sdpars`, `ranef()`, profile-target, and absent-correlation rows. |
| 434 | Poisson q1 diagnostic-row test plan | Done locally as planning: tests should assert replication, SD-ratio or boundary, Hessian, fixed-gradient, and family-warning diagnostics. |
| 435 | Poisson q1 simulation-artifact test plan | Done locally as planning: tests should validate aggregate, replicate, manifest, failure-ledger, diagnostic, and profile-target artifacts with row counts. |
| 436 | Poisson q1 source-map sync | Done locally: the implemented source map now points the Poisson mean row to the ADEMP and runner-contract documents. |
| 437 | Poisson q1 validation-debt row sync | Done locally: the `poisson_phylo_q1_mu` debt row now names the runner contract as the next gate. |
| 438 | Structured non-Gaussian validation-debt sync | Done locally: the broader structured non-Gaussian row points to the ADEMP sheet and runner contract before recovery work. |
| 439 | Phase 18 count-lane sync | Done locally: the count scenario lane now separates ordinary Poisson/NB2 random-effect ADEMP work from the Poisson phylogenetic q1 ADEMP and runner contract. |
| 440 | Phase 18 phylogenetic-lane sync | Done locally: the phylogenetic scenario lane keeps the Poisson q1 lane separate from Gaussian phylogenetic grids until the runner contract is implemented. |
| 441 | Pre-simulation Poisson q1 row sync | Done locally: the readiness matrix Poisson q1 row now includes the manifest, warning/error, smoke-grid, and artifact-test contract. |
| 442 | Pre-simulation structured non-Gaussian sync | Done locally: the readiness matrix structured row now points to both Poisson q1 design documents. |
| 443 | Family-registry evidence sync | Done locally: the Poisson family evidence state now includes the runner contract beside tests and profile-target checks. |
| 444 | NEWS and ROADMAP evidence sync | Done locally: release and roadmap ledgers record the evidence-ledger synchronization without claiming new fitted support. |
| 445 | Check-log validation sync | Done locally: validation commands include pkgdown, stale-support scans, and source-ledger scans for the evidence sync. |
| 446 | After-task evidence sync | Done locally: the after-task report records the source-map, readiness, validation-debt, Phase 18, and family-registry updates. |
| 447 | Fitted-versus-planned guard | Done locally: updated ledgers still keep NB2, zero-inflated, hurdle, spatial, animal, and `relmat()` count structure planned. |
| 448 | Simulation-readiness guard | Done locally: Poisson q1 phylogeny remains smoke/runner-contract level, not formal operating-characteristic evidence. |
| 449 | Source-ledger stale-scan gate | Done locally: scans check for false broad structured count support and stale all-phylogeny-count wording. |
| 450 | Evidence-sync closeout | Done locally: source ledgers now agree that implementation, runner evidence, and broad simulation admission are separate gates. |
| 451 | Poisson phylogenetic q1 DGP | Done locally: `inst/sim/dgp/sim_dgp_poisson_phylo_q1.R` generates seeded ordinary Poisson q1 phylogenetic `mu` data with balanced or mildly uneven ultrametric trees. |
| 452 | Poisson q1 condition helper | Done locally: the condition helper crosses species count, observations per species, true `sd_phylo`, mean count, slope, and tree shape. |
| 453 | Poisson q1 fitted summariser | Done locally: `inst/sim/fit/sim_summarise_poisson_phylo_q1.R` records fixed `mu`, phylogenetic SD, standard errors, convergence, Hessian, profile-target, and diagnostic status. |
| 454 | Poisson q1 smoke runner | Done locally: `inst/sim/run/sim_run_poisson_phylo_q1_smoke.R` wires the DGP, `drmTMB()` fit, summariser, registry, and replicate runner. |
| 455 | Poisson q1 summary helper | Done locally: `inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R` returns aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, and direct profile-target tables. |
| 456 | Poisson q1 focused DGP test | Done locally: tests assert seeded reproducibility, tree metadata, truth rows, and non-negative count output. |
| 457 | Poisson q1 focused runner test | Done locally: tests assert output schemas, profile-target status, manifest rows, finite estimates, and saved RDS paths. |
| 458 | Poisson q1 malformed helper tests | Done locally: tests reject one-species trees, negative SDs, bad tree-shape labels, and malformed condition rows. |
| 459 | Poisson q1 neighboring regression tests | Done locally: new tests pass alongside Poisson mean, ordinary Poisson `mu` random-effect, and non-Gaussian structured-boundary tests. |
| 460 | Poisson q1 simulation README sync | Done locally: `inst/sim/README.md` lists the new DGP, summariser, runner, and summary helper. |
| 461 | Poisson q1 source-map implementation sync | Done locally: source-map and family-registry rows point to the new runner and focused test. |
| 462 | Poisson q1 readiness sync | Done locally: readiness and Phase 18 programme rows mark the smoke runner as available while keeping formal recovery grids future. |
| 463 | Poisson q1 design-doc sync | Done locally: ADEMP and runner-contract docs distinguish implemented smoke files from still-future grid writers and formal coverage. |
| 464 | Poisson q1 check-log and after-task | Done locally: validation commands and role-perspective closeout are recorded. |
| 465 | Poisson q1 smoke-runner closeout | Done locally: the branch has runnable smoke infrastructure but no broad non-Gaussian structured parity claim. |
| 466 | Poisson q1 grid writer | Done locally: `inst/sim/run/sim_write_poisson_phylo_q1_grid.R` writes repeatable CSV artifacts beside resumable replicate RDS files. |
| 467 | Poisson q1 grid paths | Done locally: aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage, and profile-target CSV paths are named with a stable prefix. |
| 468 | Poisson q1 grid overwrite guard | Done locally: existing artifact paths are rejected unless `overwrite = TRUE`. |
| 469 | Poisson q1 grid manifest | Done locally: `phase18_grid_artifact_manifest()` records existence and row counts for all Poisson q1 grid CSVs. |
| 470 | Poisson q1 grid writer tests | Done locally: focused tests assert CSV row counts, manifest existence, requested-versus-actual worker counts, and overwrite errors. |
| 471 | Poisson q1 grid validation tests | Done locally: focused tests reject empty output paths and invalid `overwrite`. |
| 472 | Poisson q1 README grid sync | Done locally: `inst/sim/README.md` lists the grid writer and artifact set. |
| 473 | Poisson q1 source-map grid sync | Done locally: the source map includes the grid writer in the Poisson mean implementation row. |
| 474 | Poisson q1 readiness grid sync | Done locally: readiness and Phase 18 programme rows now name repeatable CSV artifacts while keeping formal grids future. |
| 475 | Poisson q1 design grid sync | Done locally: ADEMP and runner-contract docs separate implemented CSV smoke artifacts from formal recovery grids. |
| 476 | Poisson q1 NEWS and roadmap grid sync | Done locally: release and roadmap ledgers record the grid writer without changing fitted support. |
| 477 | Poisson q1 grid check-log | Done locally: validation commands and results are recorded for the grid writer. |
| 478 | Poisson q1 grid after-task | Done locally: after-task report records artifact shape, limits, and role-perspective review. |
| 479 | Poisson q1 grid stale-scan gate | Done locally: false-support scans still return no broad NB2, spatial, animal, `relmat()`, `zi`, `hu`, or structured-slope claims. |
| 480 | Poisson q1 grid closeout | Done locally: repeatable smoke artifacts exist; formal recovery and coverage grids remain future work. |
| 481 | Poisson q1 profile interval opt-in | Done locally: the fit summariser maps `log_sd_phylo` to the public `sd:mu:phylo(1 | species)` row and writes optional direct profile interval columns. |
| 482 | Poisson q1 profile artifact tables | Done locally: the summary and grid writer now save profile interval, profile coverage, interval-evidence, interval-diagnostics, and interval-failure CSVs beside the existing smoke artifacts. |
| 483 | Poisson q1 profile tests | Done locally: focused tests request `log_sd_phylo`, assert profile rows are `ok` or `failed`, and keep failed profiles in the artifact evidence. |
| 484 | Poisson q1 formal condition helper | Done locally: `phase18_poisson_phylo_q1_formal_conditions()` names the larger species-count, repeat, signal, mean-count, slope, and tree-shape grid for formal admission runs. |
| 485 | Poisson q1 formal spec writer | Done locally: `phase18_poisson_phylo_q1_formal_grid_spec()` records `n_rep`, target replicates, profile requests, MCSE requirement, and whether the 500-replicate recovery gate is met. |
| 486 | Poisson q1 formal wrapper | Done locally: `phase18_write_poisson_phylo_q1_formal_grid_outputs()` writes the smoke artifact family plus `poisson-phylo-q1-formal-spec.csv`. |
| 487 | Poisson q1 read-back helper | Done locally: `phase18_read_poisson_phylo_q1_grid_outputs()` reads existing artifact CSVs and can require the complete artifact family. |
| 488 | Poisson q1 artifact QA | Done locally: `phase18_qa_poisson_phylo_q1_grid_outputs()` checks required artifact names, row presence, seed uniqueness, cell alignment, and expected replicate counts. |
| 489 | Poisson q1 promotion decision | Done locally: `phase18_poisson_phylo_q1_promotion_decision()` holds smoke-only artifacts and promotes narrowly only when QA passes and the formal replicate gate is met. |
| 490 | Poisson q1 Actions task | Done locally: `.github/workflows/phase18-simulation-grid.yaml` and `sim_run_actions_cell.R` expose the manual `poisson_phylo_q1_formal` task. |
| 491 | Poisson q1 Actions all guard | Done locally: `task = "all"` still runs only baseline first-wave and interval-heavy tasks; the Poisson formal grid must be selected explicitly. |
| 492 | Poisson q1 formal dry-run test | Done locally: focused tests verify that the Actions entrypoint can plan `--task=poisson_phylo_q1_formal` with `--profile-parameters=log_sd_phylo`. |
| 493 | Poisson q1 formal documentation sync | Done locally: NEWS, source-map, simulation README, readiness, simulation programme, ADEMP, runner contract, and validation-debt text describe the formal-admission wrapper without broad count claims. |
| 494 | Poisson q1 formal check-log and after-task | Done locally: validation commands, role-perspective review, and known limits are recorded for the profile/formal admission slice. |
| 495 | Poisson q1 formal closeout | Done locally: profile and formal-grid infrastructure exists, but formal recovery and coverage claims remain unavailable until the large grid is run and audited. |
| 496 | NB2 q1 R parser gate | Done locally: `drm_build_nbinom2_spec()` extracts one unlabelled `phylo(1 | species, tree = tree)` term in ordinary NB2 `mu` and keeps ordinary random effects, labels, slopes, and `zi` neighbours closed. |
| 497 | NB2 q1 TMB data path | Done locally: NB2 `model_type = 7` now passes `has_phylo_mu`, sparse `Q_phylo`, node indices, and `log_det_Q_phylo` when the q=1 phylogenetic term is present. |
| 498 | NB2 q1 TMB prior contribution | Done locally: the NB2 branch adds the same sparse phylogenetic Gaussian prior for `u_phylo` and direct `log_sd_phylo` reporting as the Poisson q1 route. |
| 499 | NB2 q1 start and map | Done locally: NB2 starts and maps activate `u_phylo` and `log_sd_phylo` only for the ordinary q=1 phylogenetic route. |
| 500 | NB2 q1 extractor contract | Done locally: `sdpars$mu`, `ranef("phylo_mu")`, and `profile_targets()` expose `phylo(1 | species)` and the direct `log_sd_phylo` target. |
| 501 | NB2 q1 diagnostic contract | Done locally: `check_drm()` includes phylogenetic diagnostics for ordinary NB2 q=1 and avoids residual-scale ratio wording for non-Gaussian fits. |
| 502 | NB2 q1 recovery smoke test | Done locally: a deterministic NB2 phylogenetic simulation checks convergence, positive-definite Hessian, fixed-effect recovery, SD recovery, conditional-effect correlation, prediction positivity, and overdispersion positivity. |
| 503 | NB2 q1 neighbour guards | Done locally: tests keep NB2 phylogenetic slopes, ordinary-plus-phylo combinations, zero-inflated NB2 phylogeny, and NB2 `sigma ~ phylo(...)` closed. |
| 504 | NB2 q1 likelihood documentation | Done locally: likelihood notes describe the NB2 q=1 `mu` phylogenetic intercept while keeping fixed-effect `sigma` overdispersion separate. |
| 505 | NB2 q1 family registry sync | Done locally: family, formula grammar, distribution-family, implementation-map, and source-map docs distinguish the fitted ordinary NB2 q=1 route from planned structured neighbours. |
| 506 | NB2 q1 validation-debt sync | Done locally: the validation-debt register records NB2 q=1 as partial and high-risk until overdispersion-aware recovery grids exist. |
| 507 | NB2 q1 NEWS and roadmap sync | Done locally: release and roadmap notes record the fitted first slice without promoting broad NB2 structured parity. |
| 508 | NB2 q1 stale-claim scan | Done locally: stale wording is scanned so old “NB2 phylogeny planned” text does not contradict the fitted q=1 route. |
| 509 | NB2 q1 check-log and after-task | Done locally: validation commands, role-perspective review, and remaining boundaries are recorded. |
| 510 | NB2 q1 closeout | Done locally: the ordinary non-zero-inflated NB2 phylogenetic `mu` intercept is fitted and smoke-tested; formal recovery grids, NB2 `zi`, NB2 structured `sigma`, structured slopes, labelled count covariance, and simultaneous structured count routes remain future gates. |
| 511 | NB2 log-`sigma` ADEMP aim | Done locally: `docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md` states the overdispersion-random-intercept aim and keeps the lane separate from NB2 `mu` and NB2 q1 phylogeny. |
| 512 | NB2 log-`sigma` condition spec | Done locally: `phase18_nbinom2_sigma_re_conditions()` crosses group count, repeats, mean count, baseline overdispersion, true `sigma` SD, and fixed slopes. |
| 513 | NB2 log-`sigma` estimands | Done locally: the ADEMP sheet names fixed `mu`, fixed `sigma`, `sd:sigma:(1 | id)`, direct `log_sd_sigma`, replication diagnostics, and formal replicate gates. |
| 514 | NB2 log-`sigma` DGP | Done locally: `inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R` generates seeded ordinary NB2 data with fixed `mu` and grouped log-`sigma` heterogeneity. |
| 515 | NB2 log-`sigma` fit route | Done locally: `phase18_fit_nbinom2_sigma_re()` fits `bf(count ~ x, sigma ~ z + (1 | id))` with the existing ordinary non-zero-inflated NB2 likelihood. |
| 516 | NB2 log-`sigma` summariser | Done locally: `inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R` records fixed effects, `sdpars$sigma`, convergence, Hessian, warnings, direct `log_sd_sigma` profile-target status, and `check_drm()` replication status. |
| 517 | NB2 log-`sigma` smoke runner | Done locally: `inst/sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R` wires DGP, fit, summariser, registry, and the bounded replicate runner. |
| 518 | NB2 log-`sigma` summary helper | Done locally: `inst/sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R` returns aggregate, replicate, manifest, failure-ledger, Wald, profile-target, interval-evidence, interval-diagnostic, and interval-failure tables. |
| 519 | NB2 log-`sigma` grid writer | Done locally: `inst/sim/run/sim_write_nbinom2_sigma_random_effect_grid.R` writes repeatable CSV artifacts beside resumable replicate RDS files. |
| 520 | Direct `log_sd_sigma` profile target | Done locally: summary rows map `sd:sigma:(1 | id)` to direct TMB target `log_sd_sigma`. |
| 521 | NB2 log-`sigma` profile-status artifact | Done locally: grid outputs include `nbinom2-sigma-re-profile-targets.csv` and optional profile interval/status artifacts without requiring profiles in routine smoke tests. |
| 522 | NB2 log-`sigma` focused tests | Done locally: `tests/testthat/test-phase18-nbinom2-sigma-random-effect.R` checks DGP reproducibility, smoke summaries, artifact row counts, direct profile-target status, overwrite protection, and malformed inputs. |
| 523 | NB2 log-`sigma` Phase 18 docs sync | Done locally: simulation README, source map, Phase 18 programme, readiness matrix, and validation-debt register now name the dedicated smoke lane. |
| 524 | NB2 log-`sigma` release and roadmap sync | Done locally: NEWS and ROADMAP record the grid while keeping NB2 scale slopes, joint `mu`/`sigma`, zero-inflated/truncated/hurdle scale routes, and structured `sigma` planned. |
| 525 | NB2 log-`sigma` closeout | Done locally: the ordinary NB2 log-`sigma` random-intercept smoke grid has code, tests, artifacts, docs, check-log, and after-task evidence; larger formal grids still need separate runtime and artifact review. |
| 526 | NB2 q1 ADEMP aim | Done locally: `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md` states the overdispersion-aware NB2 `phylo(1 | species, tree = tree)` `mu` aim and keeps `sigma` fixed-effect. |
| 527 | NB2 q1 condition spec | Done locally: `phase18_nbinom2_phylo_q1_conditions()` crosses species count, repeats, mean count, baseline overdispersion, true phylogenetic SD, fixed slopes, and tree shape. |
| 528 | NB2 q1 estimands and comparator | Done locally: the ADEMP sheet names fixed `mu`, fixed `sigma`, phylogenetic SD, direct `log_sd_phylo`, diagnostics, and an ordinary grouped species-intercept comparator row. |
| 529 | NB2 q1 overdispersion-aware DGP | Done locally: `inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R` generates seeded NB2 data with phylogenetic log-mean structure and fixed-effect log-`sigma` overdispersion. |
| 530 | NB2 q1 target and comparator fitter | Done locally: `phase18_fit_nbinom2_phylo_q1()` fits the target phylogenetic NB2 model and an ordinary grouped NB2 species-intercept comparator for the same simulated data. |
| 531 | NB2 q1 summariser | Done locally: `inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R` records fixed effects, `sdpars$mu`, comparator SD, convergence, Hessian, warnings, direct profile-target status, and `check_drm()` phylogenetic diagnostics. |
| 532 | NB2 q1 smoke runner | Done locally: `inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R` wires DGP, target/comparator fits, summariser, registry, and the bounded replicate runner. |
| 533 | NB2 q1 summary helper | Done locally: `inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R` returns aggregate, replicate, manifest, failure-ledger, Wald, profile-target, interval-evidence, interval-diagnostic, and interval-failure tables. |
| 534 | NB2 q1 grid writer | Done locally: `inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R` writes repeatable CSV artifacts beside resumable replicate RDS files. |
| 535 | NB2 q1 formal condition and spec | Done locally: `phase18_nbinom2_phylo_q1_formal_conditions()` and `phase18_nbinom2_phylo_q1_formal_grid_spec()` name the larger overdispersion-aware formal grid, replicate gate, MCSE requirement, profile request, and coverage-claim guard. |
| 536 | NB2 q1 formal wrapper and QA | Done locally: `phase18_write_nbinom2_phylo_q1_formal_grid_outputs()`, `phase18_read_nbinom2_phylo_q1_grid_outputs()`, `phase18_qa_nbinom2_phylo_q1_grid_outputs()`, and `phase18_nbinom2_phylo_q1_promotion_decision()` write, read, check, and hold/promote formal artifacts. |
| 537 | NB2 q1 Actions task | Done locally: `.github/workflows/phase18-simulation-grid.yaml` and `sim_run_actions_cell.R` expose the manual `nbinom2_phylo_q1_formal` task, excluded from `task = "all"`. |
| 538 | NB2 q1 focused tests | Done locally: `tests/testthat/test-phase18-nbinom2-phylo-q1.R` checks DGP reproducibility, target/comparator summaries, artifact row counts, direct profile-target status, formal QA, Actions dry-run planning, overwrite protection, and malformed inputs. |
| 539 | NB2 q1 docs and release sync | Done locally: simulation README, source map, Phase 18 programme, readiness matrix, validation-debt register, NEWS, and ROADMAP now name the overdispersion-aware NB2 q1 formal-admission lane. |
| 540 | NB2 q1 closeout | Done locally: the ordinary NB2 q=1 phylogenetic `mu` route now has overdispersion-aware DGP/smoke/grid/formal artifacts with an ordinary grouped comparator row; formal recovery and coverage claims still require running and auditing the 500-replicate grid. |
| 541 | NB2 q1 formal-grid preflight | Done locally: the default formal spec expands to 288 condition cells and 144,000 target/comparator replicate fits at the 500-replicate gate, so a dirty local branch is not a safe place to launch the full run blindly. |
| 542 | NB2 q1 all-cell sentinel run | Done locally: `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_sentinel` ran all 288 formal cells once with `profile_parameters = "log_sd_phylo"`, `backend = "multicore"`, and `cores = 10`. |
| 543 | NB2 q1 all-cell artifact QA | Done locally: the sentinel wrote all expected formal CSV artifacts, with 288 manifest rows, 1,728 replicate rows, complete seed/cell alignment, grouped-comparator rows, and a `hold_smoke_only` promotion decision because `n_rep = 1`. |
| 544 | NB2 q1 all-cell fit diagnostics | Done locally: all sentinel target and comparator fits converged and reported `pdHess = TRUE`; the 55 failure-ledger rows were warnings, all `collapsing to unique 'x' values`. |
| 545 | NB2 q1 all-cell profile audit | Done locally: sentinel direct `log_sd_phylo` profile intervals were 159 `ok` and 129 `failed`, with failures concentrated at the true-zero phylogenetic SD boundary. |
| 546 | NB2 q1 all-cell comparator/runtime audit | Done locally: the ordinary grouped species-intercept comparator stayed present in every cell, and elapsed time ranged from about 1.0 to 22.0 seconds per cell in the manifest. |
| 547 | NB2 q1 representative replicate audit | Done locally: `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_replicate_audit` ran 24 formal-shaped cells with five replicates each, spanning species count, repeats, mean count, and true phylogenetic SD while keeping the 500-replicate gate closed. |
| 548 | NB2 q1 replicate artifact QA | Done locally: the replicate audit wrote all expected formal artifacts, with 120 manifest rows, 720 replicate rows, 29 warning-ledger rows, and 120 `ok` manifest statuses. |
| 549 | NB2 q1 replicate convergence audit | Done locally: all replicate-audit rows converged; 119 of 120 target fits and all 120 grouped-comparator fits reported positive-definite Hessians. |
| 550 | NB2 q1 replicate profile audit | Done locally: direct `log_sd_phylo` profiles produced 74 usable intervals and 46 failures; true-zero SD cells produced no usable two-sided intervals, while positive-SD cells mostly profiled successfully. |
| 551 | NB2 q1 fixed-`sigma` boundary audit | Done locally: low-mean, low-overdispersion cells produced extreme fixed-`sigma` coefficient errors in the 5-replicate audit, so fixed `sigma` recovery remains a formal-grid risk to inspect before promotion. |
| 552 | NB2 q1 grouped-comparator audit | Done locally: the grouped comparator SD had similar small-audit RMSE to the phylogenetic SD, confirming that ordinary unstructured species heterogeneity must remain visible in the artifact schema. |
| 553 | NB2 q1 promotion decision | Done locally: `phase18_nbinom2_phylo_q1_promotion_decision()` returns `hold_smoke_only`; local QA passed, but formal recovery and coverage wording remain blocked because neither local audit met `n_rep >= 500`. |
| 554 | NB2 q1 audit documentation sync | Done locally: `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`, simulation README, source map, readiness matrix, validation-debt register, NEWS, and check-log record the sentinel/audit evidence and the remaining gate. |
| 555 | NB2 q1 formal-audit closeout | Done locally: Slices 541-555 close as an evidence-and-hold lane, not as broad NB2 structured-count promotion; the full 500-replicate formal grid moved to the later sharded Slice D1 audit. |
| 561 | NB2 q1 PR merge hygiene | Done locally: PR #320 merged after green Ubuntu, macOS, and Windows R-CMD-check evidence, giving `main` the NB2 q1 smoke/formal-admission lane before new formal-grid work started. |
| 562 | NB2 q1 singleton dispatch | Done locally: Actions run `26371083871` dispatched `nbinom2_phylo_q1_formal` from `main` with `n_reps = 500`, `cores = 10`, `backend = "multicore"`, and `profile_parameters = "log_sd_phylo"`. |
| 563 | NB2 q1 runtime feasibility audit | Done locally: prior sentinel and representative-audit manifests imply about 27-31 optimistic 10-worker hours for the full 288-cell x 500-replicate grid, exceeding the 360-minute single-job Actions cap. |
| 564 | NB2 q1 singleton cancellation | Done locally: run `26371083871` was cancelled before timeout and produced no formal artifact, preserving the `hold_smoke_only` decision. |
| 565 | Formal condition shard inputs | Done locally: `.github/workflows/phase18-simulation-grid.yaml` exposes one-based `condition_shard` and `condition_shards` inputs and passes them to the Phase 18 Actions runner. |
| 566 | Actions shard validation | Done locally: `sim_run_actions_cell.R` accepts condition sharding only for Poisson/NB2 phylogenetic q1 formal tasks and rejects sharding for ordinary summary tasks. |
| 567 | Stable formal condition partition | Done locally: the Actions runner applies a stable one-based modulo partition over the formal condition table, preserving the original cell ids inside each shard. |
| 568 | Shard artifact naming | Done locally: uploaded Phase 18 formal artifacts include the shard index and shard count in the artifact name so multiple manual runs can be downloaded without losing provenance. |
| 569 | NB2 shard formal spec | Done locally: `phase18_nbinom2_phylo_q1_formal_grid_spec()` records `condition_shard`, `condition_shards`, `full_condition_count`, `shard_condition_count`, and `shard_recovery_gate`. |
| 570 | Poisson shard formal spec parity | Done locally: the Poisson q1 formal spec records the same shard metadata so the shared Actions inputs do not become NB2-only infrastructure. |
| 571 | Shard promotion guard | Done locally: Poisson and NB2 formal specs set `coverage_claim_allowed = FALSE` whenever `condition_shards > 1`, even when a shard uses `n_rep = 500`. |
| 572 | Focused shard tests | Done locally: focused Phase 18 tests cover Actions dry-run shard parsing, non-formal shard rejection, NB2 shard metadata, and the shard promotion guard. |
| 573 | Sharded-grid design note | Done locally: `docs/design/76-phase-18-nbinom2-phylo-q1-sharded-formal-grid.md` records the singleton cancellation, runtime estimate, dispatch command pattern, and combined-audit rule. |
| 574 | NB2 q1 sharding docs sync | Done locally: simulation README, Phase 18 programme, readiness matrix, validation-debt register, NEWS, ROADMAP, check-log, and after-task records now describe sharded formal dispatch without promotion claims. |
| 575 | NB2 q1 sharding closeout | Done locally: the route remains `hold_smoke_only`; the later Slice D1 audit ran all formal shards, downloaded them, merged the artifacts, and held the route after reviewing the full 500-replicate grid. |
| 576 | NB2 q1 shard dispatch preflight | Done locally: the workflow concurrency key was checked before dispatch, because a task-only concurrency group would not preserve all pending formal shards. |
| 577 | Shard-aware Actions concurrency | Done locally: `.github/workflows/phase18-simulation-grid.yaml` now includes `condition_shard` and `condition_shards` in the concurrency group so rapid 16-shard dispatches keep separate pending queues. |
| 578 | Shard concurrency regression test | Done locally: `tests/testthat/test-phase18-actions-runner.R` now asserts that the workflow file mentions both shard inputs, guarding the operational dispatch contract. |
| 579 | Shard queue documentation sync | Done locally: `docs/design/76-phase-18-nbinom2-phylo-q1-sharded-formal-grid.md` records why shard-aware concurrency is required before a full 16-shard dispatch. |
| 580 | NB2 q1 formal dispatch readiness | Done locally: the branch keeps the statistical grid unchanged and makes the 500-replicate formal evidence lane operationally dispatchable without replacing pending shards. |
| 581-590 | NB2 q1 formal shard execution | Done locally: the 16 `nbinom2_phylo_q1_formal` shards from `main` at `2754e536` completed successfully and their artifacts were downloaded and audited together. The merged set has 288 unique formal condition combinations, 144,000 `ok` manifest rows, 500 rows per global shard-cell, and all expected CSV artifact families. Promotion remains blocked because direct `log_sd_phylo` profiles are weak at the true-zero boundary and low-count fixed-`sigma` recovery remains unstable. |
| 591-605 | Supported non-Gaussian evidence map | Done locally: `docs/design/79-supported-nongaussian-evidence-goal.md` adds one goal-level ledger for Student-t, lognormal, Gamma, beta, beta-binomial, Poisson/ZIP, NB2/ZINB2, truncated/hurdle NB2, cumulative logit, first count mixed-model lanes, and blocked neighbours. |
| 606-620 | Fixed-effect family evidence closeout | Done locally as an audit closeout: the supported fixed-effect family rows are mapped to their likelihood, fitted/prediction, deterministic simulation or recovery, boundary, interval/status, and documentation evidence without adding new model syntax. |
| 621-635 | Unsupported neighbour closeout | Done locally as a no-fit boundary: mixed-response, inflation/hurdle random-effect, zero-one-inflation, shape/skew random-effect, cross-parameter covariance, and broad structured non-Gaussian routes stay planned or blocked with fitted alternatives. |
| 636-650 | Count mixed-model evidence closeout | Done locally as ledger sync: ordinary Poisson/NB2 `mu` random effects, the narrow NB2 log-`sigma` random-intercept gate, and Poisson/NB2 q=1 phylogenetic `mu` gates are recorded as separate first slices; NB2 q1 formal promotion still depends on the 581-590 shard audit. |
| 1279-1288 | Core family completion map | Done locally: `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md` routes the next Phase 18 evidence work breadth-first across counts, proportions, positive-continuous responses, ordinal responses, and shape families before another covariance expansion. |
| 1289-1298 | Proportion fixed-effect artifacts | Done locally: `beta()` and `beta_binomial()` now have fixed-effect DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `proportion_fixed_effect` Actions dispatch, focused tests, and design/after-task evidence. Exact boundary mass, `zoi`/`coi`, bounded-response random effects beyond the ordinary `mu` intercept/slope slices, structured bounded responses, and mixed-response bounded models remain planned or unsupported. |
| 1299-1308 | Positive-continuous fixed-effect artifacts | Done locally: `lognormal()` and `Gamma(link = "log")` now have fixed-effect DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `positive_continuous_fixed_effect` Actions dispatch, focused tests, and design/after-task evidence. The later Slices 1369-1378 add the ordinary `mu` random-intercept artifact lane, and the current source slice adds independent numeric `mu` slope tests; Tweedie, generalized Gamma, correlated positive-continuous random slopes, `sigma` random effects, known-covariance positive responses, structured positive responses, and mixed-response positive-continuous models remain planned or unsupported. |
| 1309-1318 | Ordinal fixed-effect artifacts | Done locally: `cumulative_logit()` now has fixed-effect DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `ordinal_fixed_effect` Actions dispatch, focused tests, and design/after-task evidence. Ordinal random effects, scale/discrimination formulas, cutpoint-specific predictors, known-covariance ordinal models, structured ordinal effects, bivariate ordinal models, and mixed-response ordinal models remain planned or unsupported. |
| 1319-1328 | Count first-wave closure | Done locally as Slice C: `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md` inventories the paired Poisson/NB2 `mu`, NB2 log-`sigma`, Poisson q1 phylo, and NB2 q1 phylo evidence lanes; records the Slice D choices without adding COM-Poisson, Tweedie, zero-one beta, skew-normal, or new random-effect syntax; and now points to the later D1 shard audit that kept NB2 q1 at `hold_smoke_only`. |
| 1329-1338 | Zero-one bounded-response design gate | Done locally as Slice D3 and followed by the fixed-effect source slice: `docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md` records fixed-effect zero-one beta as the bounded-response likelihood candidate, the package now fits `zero_one_beta()` with `zoi`/`coi` formulas, and zero-one random effects, correlated or broader bounded-response random slopes, structured bounded responses, Tweedie, skew-normal, COM-Poisson, and generalized Poisson stay out of the fitted surface. |
| 1339-1348 | Zero-one beta fixed-effect artifacts | Done locally: `zero_one_beta()` now has a fixed-effect Phase 18 DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `zero_one_beta_fixed_effect` Actions dispatch, focused tests, and design/after-task evidence. Zero-one random effects, covariance blocks, denominator syntax, known covariance, structured bounded responses, and bivariate or mixed bounded-response models remain planned or unsupported. |
| 1359-1368 | Bounded-response `mu` random-intercept artifacts | Done locally: `beta()` and `beta_binomial()` now have ordinary `mu` random-intercept DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `bounded_response_mu_random_intercept` Actions dispatch, focused tests, and design/after-task evidence. Independent numeric `mu` slopes now have focused source tests; correlated bounded-response slopes, labelled covariance, `sigma` random effects, exact 0/1 boundary mass, zero-one beta random effects, structured effects, known covariance, and mixed bounded-response models remain planned or unsupported. |
| 1369-1378 | Positive-continuous `mu` random-intercept artifacts | Done locally: `lognormal()` and `Gamma(link = "log")` now have ordinary `mu` random-intercept DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `positive_continuous_mu_random_intercept` Actions dispatch, focused tests, and design/after-task evidence. Independent numeric `mu` slopes now have focused source tests; correlated positive-continuous slopes, labelled covariance, `sigma` random effects, Tweedie, generalized Gamma, known-covariance positive responses, structured positive responses, and mixed-response positive-continuous models remain planned or unsupported. |
| 1379-1388 | Student-t `mu` random-intercept artifacts | Done locally: `student()` now has an ordinary `mu` random-intercept DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `student_mu_random_intercept` Actions dispatch, focused tests, and design/after-task evidence. Independent numeric `mu` slopes now have focused source tests; correlated Student-t slopes, labelled covariance, `sigma` random effects, `nu` random effects, structured effects, known covariance, and bivariate Student-t models remain planned or unsupported. |
| 1389-1398 | Zero-truncated NB2 `mu` random-intercept artifacts | Done locally: `truncated_nbinom2()` now has an ordinary `mu` random-intercept DGP, summariser, smoke runner, grid writer, first-wave summary inclusion, manual `truncated_nbinom2_mu_random_intercept` Actions dispatch, focused tests, and design/after-task evidence. Independent numeric `mu` slopes now have focused source tests; correlated zero-truncated NB2 slopes, labelled covariance, `sigma` random effects, hurdle random effects, zero-inflated zero-truncated models, structured effects, and bivariate count models remain planned or unsupported. |
| 1399-1408 | Parallel Phase 18 lane protocol | Done locally as process design: `docs/design/121-phase-18-parallel-lane-protocol-slices-1399-1408.md` records how two independent distribution lanes can be built on separate branches while shared helpers, formula grammar, likelihood contracts, exported APIs, global status files, and merge decisions remain serial integration gates. |
| 1409-1418 | First two-team Phase 18 pilot | Done locally: Team A added `docs/design/122-tweedie-scale-preflight.md` to lock the proposed first Tweedie lane to univariate fixed-effect `mu`, `sigma`, and intercept-only `nu` with public `sigma = sqrt(phi)` before implementation; Team B added zero-truncated NB2 `mu` random-intercept tests for factor/missing-row handling and malformed-neighbour rejection, without opening Tweedie support or broadening the fitted count surface. |
| 1419-1518 | Tweedie fixed-effect admission | Done locally: `tweedie()` now fits the first univariate fixed-effect semicontinuous route with `mu`, public `sigma = sqrt(phi)`, and intercept-only `nu ~ 1`; focused tests cover high-zero and low-zero recovery, fitted response semantics, simulation, support-boundary filtering, and malformed neighbours. Tweedie random effects, predictor-dependent `nu`, structured effects, bivariate or mixed-response routes, zero-inflation aliases, and hurdle aliases remain planned. |
| 1519-1538 | Skew-normal source map | Done locally as design-only evidence: `docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md` records candidate parameterizations, comparator sources, local boundaries, and first implementation tests without adding `skew_normal()` or changing formula grammar. |
| 1619-1668 | Next Team A Tweedie hardening lane | Planned in `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`: decide the PR boundary, add or design the `glmmTMB::tweedie()` comparator contract, keep public `sigma^2` versus comparator `phi` explicit, harden `fitted()`, `sigma()`, `predict(dpar = "nu")`, simulation, stale-claim, and rendered-site checks, and stop before `nu ~ x`, random effects, structured effects, bivariate Tweedie, zero-inflation aliases, or hurdle aliases. |
| 1669-1718 | Next Team B skew-normal decision gate | Planned in `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`: decide native versus moment parameterization, record consequences for `fitted()`, `sigma()`, and `predict(dpar = "nu")`, name the first density, normal-limit, sign-convention, recovery, false-positive, interval-status, diagnostic, and runtime tests, and keep `skew_normal()` absent until that contract is accepted. |
| 1619-1628 | Tweedie comparator contract | Done locally: `docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md` and the optional `glmmTMB` comparator test compare `mu` coefficients, `2 * sigma` coefficients to log-dispersion `phi`, intercept-only power, and log-likelihood on low-zero and high-zero overlapping fixed-effect models without widening Tweedie support. |
| 1669-1672 | Skew-normal parameterization decision | Done locally as design-only evidence: `docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md` chooses the moment contract for the first fitted lane, with public `mu = E[y]`, public `sigma = SD[y]`, `nu` as slant/shape, and internal transform to native `xi`, `omega`, and `alpha`; no constructor or TMB branch was added. |
| 1673-1702 | Skew-normal first-test contract | Done locally as design-only evidence: `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md` records the density normalization, Gaussian normal-limit, sign-orientation, false-positive, and no-C++ admission gates that must become tests before `skew_normal()` is exposed. |
| 1629-1630 and 1687-1688 | Tweedie semantic and skew-normal boundary tests | Done locally: `docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md` records that Tweedie zero-regime comparator cells now reassert `fitted()` as unconditional `mu` and response-scale `nu` in `(1, 2)`, while the skew-normal boundary test reads the first-test contract and keeps `skew_normal()` absent. |
| 1631-1632 and 1685-1686 | Comparator and support-boundary decisions | Done locally as design evidence: `docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md` keeps Tweedie weights as top-level row likelihood multipliers, keeps Tweedie offsets out of the first comparator pass, and records finite-response, missingness, and rank-deficiency decisions for the future skew-normal lane. |
| 1631 addendum | Tweedie row-weight invariant | Done locally: `docs/design/131-phase-18-tweedie-weight-invariant-slice-1631-addendum.md` and `tests/testthat/test-tweedie-location-scale.R` check that constant Tweedie row weights double the log-likelihood without moving `mu`, `sigma`, or intercept-only `nu`, and that integer row weights match explicit row duplication. The weighted external `glmmTMB` comparator remains postponed. |
| 1639, 1641, and 1642 | Tweedie simulation shape and seed hardening | Done locally: `tests/testthat/test-tweedie-location-scale.R` now checks `simulate()` data-frame shape, column names, fitted-row count after missing-row filtering, finite non-negative draws with exact zeros, and repeated-seed reproducibility for the fitted fixed-effect Tweedie lane. |
| 1644-1646 | Tweedie fixed-effect artifact preflight | Done locally as design-only evidence: `docs/design/133-phase-18-tweedie-fixed-effect-artifact-preflight-slices-1644-1646.md` names the future `tweedie_fixed_effect` DGP, estimands, summary columns, manifest, failure-ledger, Wald interval, and coverage fields before runner code. It keeps the lane univariate, fixed-effect, unweighted, and intercept-only for `nu`; Tweedie offsets, random effects, structured effects, bivariate routes, zero-inflation aliases, and hurdle aliases remain excluded. |
| 1689-1702 | Skew-normal implementation gate | Done locally as design-only evidence: `docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md` keeps `skew_normal()` absent while naming the required density, normal-limit, sign-orientation, malformed-neighbour, method, documentation, provenance, no-fit, recovery, false-positive, interval-status, diagnostic, runtime, DGP, and summary gates for the first implementation PR. |
| 1703 | Skew-normal density contract fixture | Done locally as test-only evidence: `tests/testthat/helper-skew-normal-density.R` and `tests/testthat/test-skew-normal-density-contract.R` check the public-moment to native-density transform, integration to one, the `nu = 0` Gaussian limit, and the third-moment sign orientation. No `skew_normal()` constructor, TMB branch, formula-grammar change, exported docs, or user-facing example is added. |
| 1704 | Tweedie density fixture | Done locally as test-only evidence: `tests/testthat/helper-tweedie-density.R` and `tests/testthat/test-tweedie-location-scale.R` compare an intercept-only fitted Tweedie log likelihood with an independent compound Poisson-Gamma density fixture for exact-zero mass and positive observations. No Tweedie DGP, runner, grid writer, coverage table, predictor-dependent `nu`, random effects, structured effects, bivariate route, zero-inflation alias, or hurdle alias is added. |
| 1705-1708 | Tweedie fixed-effect smoke artifacts | Done locally: `inst/sim/dgp/sim_dgp_tweedie_fixed_effect.R`, `inst/sim/fit/sim_summarise_tweedie_fixed_effect.R`, `inst/sim/run/sim_run_tweedie_fixed_effect_smoke.R`, and `inst/sim/run/sim_summary_tweedie_fixed_effect_smoke.R` add the first low/high-zero DGP, fit summariser, smoke runner, resume check, aggregate/replicate/manifest/failure-ledger outputs, and formula-coefficient Wald artifacts for the fitted univariate fixed-effect `tweedie()` route. No grid writer, Actions task, predictor-dependent `nu`, random effects, structured effects, bivariate route, offset/exposure route, zero-inflation alias, or hurdle alias is added. |
| 1709-1712 | Tweedie fixed-effect grid writer | Done locally: `inst/sim/run/sim_write_tweedie_fixed_effect_grid.R` writes repeatable aggregate, replicate, manifest, failure-ledger, Wald interval, and Wald coverage CSV artifacts for `tweedie_fixed_effect`, with overwrite protection, artifact-manifest checks, and focused tests. No manual Actions task, predictor-dependent `nu`, random effects, structured effects, bivariate route, offset/exposure route, zero-inflation alias, or hurdle alias is added. |
| 1713-1716 | Tweedie first-wave summary wiring | Done locally: `inst/sim/run/sim_run_first_wave_summary_smoke.R` now runs a two-cell low/high-zero `tweedie_fixed_effect` grid in the shared first-wave summary smoke runner, includes it in the report bundle, return object, and parallel-summary CSV, and updates the focused first-wave smoke test. No manual Actions task, predictor-dependent `nu`, random effects, structured effects, bivariate route, offset/exposure route, zero-inflation alias, or hurdle alias is added. |
| 1717-1718 | Tweedie manual Actions task | Done locally: `.github/workflows/phase18-simulation-grid.yaml` and `inst/sim/run/sim_run_actions_cell.R` expose a manual-only `tweedie_fixed_effect` dispatch task, update the first-wave Actions dependency list for the merged Tweedie runner, and add dry-run/workflow tests. The task is excluded from `task = "all"` and does not add condition sharding, predictor-dependent `nu`, random effects, structured effects, bivariate route, offset/exposure route, zero-inflation alias, or hurdle alias. |
| 1719-1720 | Tweedie manual Actions smoke audit | Done via GitHub Actions run `26608885245`: `task=tweedie_fixed_effect`, `n_reps=2`, `cores=2`, `backend=multicore`, `render_report=false` completed successfully on `main`. The downloaded artifact contained 8 cells, 16 replicate RDS files, 40 aggregate rows, 80 replicate coefficient rows, 80 Wald interval rows, 40 Wald coverage rows, 16 `ok` manifest rows, and no failure-ledger rows; all 80 coefficient rows had `converged = TRUE` and `pdHess = TRUE`. This is a smoke artifact audit, not a final coverage claim or model-boundary expansion. |
| 1721-1728 | Count structured q1 smoke artifacts | Done locally: `inst/sim/dgp/sim_dgp_count_structured_q1.R`, `inst/sim/fit/sim_summarise_count_structured_q1.R`, `inst/sim/run/sim_run_count_structured_q1_smoke.R`, `inst/sim/run/sim_summary_count_structured_q1_smoke.R`, and `inst/sim/run/sim_write_count_structured_q1_grid.R` add opt-in aggregate, replicate, manifest, failure-ledger, fixed-effect Wald, profile-target, optional profile-interval, interval-evidence, interval-diagnostic, and interval-failure artifacts for ordinary Poisson/NB2 q=1 `spatial()`, `animal()`, and `relmat()` `mu` intercepts. This follows the source-test first slice and does not add zero-inflated structure, structured slopes, labelled count covariance, structured NB2 `sigma`, manual Actions dispatch, or formal recovery claims. |
| 1729-1730 | Count structured q1 manual Actions task | Done locally: `.github/workflows/phase18-simulation-grid.yaml` and `inst/sim/run/sim_run_actions_cell.R` expose a manual-only `count_structured_q1` task, wire the new artifact dependencies, pass through optional `profile_parameters`, and add dry-run/workflow/dependency tests. The task is excluded from `task = "all"` and does not add zero-inflated structure, structured slopes, labelled count covariance, structured NB2 `sigma`, condition sharding, or formal recovery claims. |
| 1731-1732 | Count structured q1 manual Actions smoke audit | Done via GitHub Actions run `26622840562`: `task=count_structured_q1`, `n_reps=2`, `cores=2`, `backend=multicore`, `render_report=false` completed successfully on `main`. The downloaded artifact contained 24 cells, 48 replicate RDS files, 96 aggregate rows, 192 replicate parameter rows, 48 `ok` manifest rows, 48 ready profile-target rows, 192 Wald interval rows, 72 Wald coverage rows, and 96 interval-failure diagnostic rows. One NB2 spatial replicate (`count_structured_q1_020`, replicate 2) had warning `NaNs produced` and `pdHess = FALSE` across its five parameter rows; all 192 parameter rows still had `converged = TRUE`. This is an operational smoke audit, not a formal recovery or coverage claim. |
| 1733-1734 | Count structured q1 warning diagnostic hardening | Done locally: the exact `count_structured_q1_020` replicate 2 seed replayed with the same near-zero spatial SD estimate and fixed-effect estimates, while Hessian status differed between local macOS (`ok`) and the Ubuntu Actions artifact (`pdHess = FALSE`). `phase18_summarise_count_structured_q1_fit()` now records fit-level diagnostic rollup, Hessian status, and random-effect-SD boundary status in each replicate row, and the focused test suite asserts that this seed is a boundary case rather than relying on platform-stable Hessian status. This does not promote the lane to formal recovery or coverage evidence. |
| 1735-1736 | Count structured q1 post-diagnostic Actions smoke audit | Done via GitHub Actions run `26626333581` after the warning-diagnostic columns merged. The selected `count_structured_q1` job succeeded in 3m33s, all unselected jobs skipped, and the downloaded artifact again had 48 `ok` manifest rows, 192 converged parameter rows, 48 ready profile-target rows, and one warning-ledger row for `count_structured_q1_020` replicate 2. The new replicate columns were present: `fit_diagnostic_status` had 169 `ok` and 23 `warning` parameter rows, `sd_boundary_status` had 169 `ok` and 23 `warning` rows, and `hessian_status` had 187 `ok` and 5 `warning` rows. The warnings collapse to five boundary-sensitive replicates, with only the original NB2 spatial replicate also producing a Hessian warning and `NaNs produced`. This is post-merge smoke evidence, not recovery or coverage evidence. |
| 1737-1738 | Count structured q1 pre-grid boundary gate | Done locally as design evidence: larger `count_structured_q1` pilots must collapse replicate-table rows to fitted-replicate units, report fit-diagnostic, SD-boundary, Hessian, and warning-ledger rates overall and by condition, and stop as diagnostic evidence if Hessian warnings exceed 5%, SD-boundary warnings reach 15%, condition-level warning triggers fire, or unexplained optimizer/non-finite warning messages appear. This gate keeps the lane out of formal recovery or coverage claims until the boundary-sensitive smoke behavior has a documented decision rule. |
| 1739-1740 | Count structured q1 boundary audit helper | Done locally: `phase18_audit_count_structured_q1_boundary_gate()` reads a count structured q=1 artifact directory, collapses parameter rows to fitted replicates, reports overall and condition-level gate rates, applies the Slice 1737-1738 Hessian, SD-boundary, condition, and warning-ledger triggers, and returns `hold_diagnostic` or `propose_next_pilot`. The replicate summary now carries `sd_structured`, and the helper can derive that value from older structured-SD rows. |
| 1741-1742 | Count structured q1 helper artifact audit | Done locally using the downloaded artifact from GitHub Actions run `26626333581`: the helper collapsed 192 parameter rows to 48 fitted replicates, found 5 fit-diagnostic and SD-boundary warning replicates, 1 Hessian-warning replicate, no unexplained warning-ledger rows, all gate checks `ok`, and decision `propose_next_pilot`. This permits designing a larger diagnostic pilot but still does not make recovery or coverage claims. |
| 1743-1750 | Count structured q1 next diagnostic pilot spec | Done locally as design evidence: `docs/design/135-phase-18-count-structured-q1-next-pilot-slices-1743-1750.md` specifies a 24-cell x 10-replicate `count_structured_q1` diagnostic pilot, the manual Actions dispatch contract, 20-30 minute runtime expectation, no-profile interval policy, boundary-gate helper audit, stop rules, and after-task reporting requirements. This is a pre-run design, not a grid dispatch or recovery claim. |
| 1751-1752 | Count structured q1 diagnostic pilot audit | Done via GitHub Actions run `26631771105`: `task=count_structured_q1`, `n_reps=10`, `cores=2`, `backend=multicore`, and `profile_parameters=''` completed successfully on `main`, with the selected job finishing in 3m51s and unselected matrix jobs skipped. The artifact contained 24 condition directories, 240 replicate RDS files, 240 `ok` manifest rows, 960 replicate parameter rows, and 240 ready profile-target rows. The boundary helper collapsed the rows to 240 fitted replicates and returned `hold_diagnostic`: SD-boundary warnings were 40/240 = 0.167, above the 15% gate, and six condition cells crossed the condition-level SD-boundary trigger. This stops the lane at diagnostic evidence and does not permit formal recovery or coverage claims. |
| 1753-1760 | Count structured q1 follow-up condition sets | Done locally as executable design evidence: `phase18_count_structured_q1_followup_conditions()` annotates the run `26631771105` pilot cells and exposes `stable`, `stable_watch`, `boundary_stress`, and historical `all` condition sets, while `.github/workflows/phase18-simulation-grid.yaml` and `inst/sim/run/sim_run_actions_cell.R` pass `condition_set` through the manual `count_structured_q1` task. `docs/design/137-phase-18-count-structured-q1-followup-condition-sets-slices-1753-1760.md` specifies that only the 10 clean high-SD `stable` cells can propose a later formal-pilot design, and even then without recovery or coverage claims until direct intervals and MCSE targets are designed. |
| 1761-1762 | Count structured q1 stable diagnostic audit | Done via GitHub Actions run `26638116979`: `task=count_structured_q1`, `condition_set=stable`, `n_reps=20`, `cores=2`, `backend=multicore`, and `profile_parameters=''` completed successfully on `main`, with the selected job finishing in 3m48s and unselected matrix jobs skipped. The artifact contained 10 condition directories, 200 replicate RDS files, 200 `ok` manifest rows, 760 replicate parameter rows, and 200 ready profile-target rows. The boundary helper collapsed the rows to 200 fitted replicates and returned `propose_next_pilot`: SD-boundary warnings were 3/200 = 0.015, no Hessian or warning-ledger rows appeared, and no condition crossed the SD-boundary trigger. This permits writing a formal-pilot design note for the stable cells but still does not permit recovery or coverage claims. |
| 1763-1770 | Count structured q1 formal-pilot design | Done locally as design evidence: `docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md` specifies a stable-set-only manual Actions pilot with `n_reps=100`, `profile_parameters='log_sd_phylo'`, `profile_level=0.70`, bootstrap disabled, a 60-minute selected-job runtime budget, MCSE expectations for 70% profile coverage, and boundary/profile stop rules for the two NB2 high-SD cells that still showed low-rate SD-boundary warnings. This permits dispatching and auditing a formal pilot from `main`; it does not create recovery, coverage, bootstrap, low-SD, zero-inflated, structured-slope, labelled-covariance, or structured NB2 `sigma` claims. |
| 1771-1772 | Phase 18 formal-pilot workflow inputs | Done locally: `.github/workflows/phase18-simulation-grid.yaml` now exposes manual `profile_level` and `require_complete` inputs and passes them to `sim_run_actions_cell.R`, so the Slice 1763-1770 count structured q1 formal-pilot dispatch command can request 70% profile intervals and fail incomplete replicate runs. `tests/testthat/test-phase18-actions-runner.R` guards the workflow contract, and the dry-run plan prints `require_complete` for pre-dispatch evidence. This is workflow plumbing only, not a simulation dispatch or recovery claim. |
| 1773 | Phase 18 post-run print-plan regression | Done locally: `sim_run_actions_cell.R` now passes `require_complete` to the post-run `phase18_actions_print_plan()` call, fixing the failure seen in Actions run `26667502560` after the count structured q1 formal pilot completed its task body. `tests/testthat/test-phase18-actions-runner.R` mocks a non-dry-run `count_structured_q1` execution and asserts that `require_complete=TRUE` prints after saving `phase18-actions-result.rds`. This is runner plumbing only, not artifact audit evidence. |

### Pre-Simulation Readiness Slice Map

This table is the working contract before full Phase 18 simulation begins. It
keeps three lanes separate: user-facing plots, model-feature hardening, and
simulation evidence. A narrow internal pilot, such as the Slice 258 count
simulation diagnostics, should not be promoted as the general figure gallery or
as the whole comprehensive simulation programme.

| Slice | Block | Target | Done When |
| --- | --- | --- | --- |
| 260 | Figure gallery | Interaction plot polish | Done locally: the gallery now shows categorical x continuous, categorical x categorical, and continuous x continuous examples with raw data where useful, fitted values, 95% confidence intervals, clear conditioning labels, alt text, and a cleaner correlation figure using `plot_corpairs(label = ...)`. |
| 261 | Figure gallery | Distributional-parameter panels | Done locally: the gallery labels `mu` and `sigma` by estimand and adds fitted Student-t `nu`, zero-inflation probability `zi`, and residual `rho12` panels with explicit response-scale wording and interval provenance. |
| 262 | Figure gallery | Random-effect and variance-component figures | Done locally: the gallery separates ordinary grouped SDs, random-slope summaries, `sd(group)` surfaces, residual `sigma`, and group-level SDs instead of visually collapsing them. |
| 263 | Figure gallery | Correlation-layer figures | Done locally and refreshed after the q=4 spatial slice: `corpairs()`-style examples distinguish implemented residual, ordinary group, phylogenetic, spatial, animal, and `relmat()` q=2 estimate rows, mark the constant spatial q=4 block as partly fitted, and keep richer structured correlation-regression paths planned. |
| 264 | Figure gallery | `emmeans` and marginal-effects figures | Done locally: the gallery shows the supported fixed-effect univariate `mu` `emmeans` route, factor-conditioned and interaction grids, an empirical `marginal_parameters()` summary, and unsupported boundaries for `sigma`, bivariate, zero-inflated, hurdle, ordinal, and random-effect targets. |
| 265 | Simulation plot grammar | Operating-characteristic plot design | Done locally: the Simulation & Comparison route has reusable plot grammar for bias, RMSE, coverage, power, convergence, runtime, and warning/error ledgers across continuous, proportion, count, and meta-analysis examples. |
| 266 | Figure QA | Gallery source map | Done locally: each figure maps to the fitted object or fixture, extractor or plotter, interval source, support status, and current limitation. |
| 267 | Florence closeout | Plot helper backlog | Done locally: the helper backlog keeps `plot_parameter_surface()` and `plot_corpairs()` as the exported helpers, leaves gallery-specific plots as tutorial recipes, and defers simulation/failure-ledger helpers until result schemas stabilize. |
| 299 | Figure QA | Florence visual repair | Done locally: the public figure gallery now adds raindrop-style compatibility displays for inference intervals, removes the misleading category-connecting line from the simulation bias panel, adds raincloud-style replicate clouds with mean/MCSE intervals, applies explicit colour to formerly default-black displays, and improves tile-label contrast for support-boundary strips. |
| 300 | Simulation plot grammar | Raincloud and MCSE display contract | Done locally: `simulation-plot-grammar` now requires real bias reports to show replicate-level errors beside mean bias and MCSE intervals, and to keep RMSE in a separate aggregate uncertainty panel rather than mixing it with signed bias or an absolute-error cloud. |
| 301 | Count pilot report | Apply accuracy grammar | Done locally: `phase18-count-mu-gallery.Rmd` now applies the Slice 300 accuracy contract to the count-pilot report template, with fixed family facets, aggregate MCSE bars, readable parameter-class labels, and no simulated raincloud when replicate-level rows are absent. |
| 302 | Documentation | Implementation map | Done locally: `vignettes/implementation-map.Rmd` gives users and roadmap work one table set for family components, random effects, dependence layers, q, random slopes, `corpairs()`, `zi`, and `hu`, while keeping fixed-effect-only, first-slice, planned, and blocked statuses separate. |
| 303 | Documentation | Generic direct-SD design gate | Done locally as planning: future `sd*()` work starts with grammar, compatibility, reference-index discoverability, and tests, not with new parallel names. |
| 304 | Documentation | p8/q8 location-scale planning gate | Done locally as planning: the next location-scale slope endpoint remains design-first because full p8/q8 covariance can become too large and weakly identified before users get a reliable model. |
| 305 | Documentation | Structured q=4 parity plan | Done locally as planning: spatial, animal, and `relmat()` q=4 parity stays one structured layer at a time, with `corpairs()`, diagnostics, and simulation admission requirements visible. |
| 306 | Documentation | q=4 interval policy | Done locally as planning: q=4 rows remain point-estimate or derived-summary rows unless interval methods are explicitly available. |
| 307 | Documentation | Inflation and hurdle random-effect gate | Done locally as a no-fit decision, later updated by the fixed-effect zero-one beta source slice: `zi`, `hu`, `zoi`, and `coi` stay fixed-effect-only where implemented until use cases and validation justify a new latent layer. |
| 308 | Documentation | Non-Gaussian structured-dependence candidate map | Done locally as planning: choose one family and one dependence layer before any broad non-Gaussian structured-dependence claim. |
| 309 | Documentation | Implementation-map maintenance gate | Done locally as process: high-traffic status surfaces and stale scans should move together after meaningful feature work. |
| 310 | Documentation | User-route examples gate | Done locally as planning: unsupported rows should direct readers to the closest fitted alternative or design note. |
| 311 | Documentation | Generic `sd*()` contract | Done locally as planning: future structured direct-SD syntax should be explicit about level and compatibility. |
| 312 | Documentation | Direct-SD ambiguity guard | Done locally as planning: ordinary `sd(group)` and future structured direct-SD routes should not collide. |
| 313 | Documentation | Direct-SD user migration | Done locally as planning: existing `sd_phylo*()` users keep a documented route while generic syntax is designed. |
| 314 | Documentation | p8/q8 endpoint taxonomy | Done locally as planning: q2, q4, q6, and q8 endpoint classes are separated before implementation. |
| 315 | Documentation | p8/q8 parameterization risk | Done locally as planning: full unstructured q8 is marked high risk and constrained alternatives should be evaluated first. |
| 316 | Documentation | p8/q8 diagnostics gate | Done locally as planning: profile targets, diagnostics, recovery tests, and warnings are required before p8/q8 claims. |
| 317 | Documentation | Structured q4 ordering | Done locally as planning and superseded by Slices 356-380: spatial q4 was the next constant structured q4 parity lane. |
| 318 | Documentation | q4 interval contract | Done locally as planning: q4 intervals remain unavailable unless explicit interval evidence exists. |
| 319 | Documentation | Non-Gaussian candidate scoring | Done locally as planning: non-Gaussian structured candidates are scored before coding. |
| 320 | Documentation | First non-Gaussian candidate recommendation | Done locally as planning: one q1 `mu` structured intercept is the first candidate class, with Poisson as smoke and NB2 as practical target. |
| 321 | Documentation | User-route examples | Done locally as planning: common planned requests now point to fitted alternatives in the public map. |
| 322 | Documentation | Implementation-map sync | Done locally: the public implementation map carries the 311-325 rows and examples. |
| 323 | Documentation | Roadmap, NEWS, and check-log | Done locally: public and dev ledgers match the planning-only scope. |
| 324 | Documentation | After-task protocol | Done locally: after-task report records the scope and remaining boundaries. |
| 325 | Documentation | Validation | Done locally: pkgdown and stale-claim scans confirm the rendered docs. |
| 326 | Documentation | Generic direct-SD issue spec | Done locally as pre-code: `docs/design/64-implementation-map-slices-326-340.md` records the grammar, compatibility, endpoint, reference-index, and test decisions required before generic structured direct-SD parser work. |
| 327 | Documentation | Direct-SD parser boundary matrix | Done locally as pre-code: ordinary `sd(group)`, current `sd_phylo*()`, and future level-targeted structured SD routes have separate parser outcomes. |
| 328 | Documentation | Direct-SD tests and docs checklist | Done locally as pre-code: next direct-SD work requires malformed-input tests, prediction/profile rows, examples, reference docs, and stale-name scans. |
| 329 | Documentation | p8/q8 endpoint registry sketch | Done locally as pre-code: q2 slope-only, q4 location slope, q6 partial location-scale, and q8 all-endpoint slope classes are named. |
| 330 | Documentation | p8/q8 staged implementation options | Done locally as pre-code: q4 location-slope and constrained or block-diagonal routes are preferred before full q8 unstructured covariance. |
| 331 | Documentation | p8/q8 simulation gate | Done locally as pre-code: any q4/q6/q8 slope endpoint must vary group count, repeats, SD ratios, correlations, covariate spread, and boundary cases. |
| 332 | Documentation | Spatial q4 pre-code checklist | Done locally as pre-code: spatial q4 requires matching labelled terms, extractor rows, `corpairs()`, diagnostics, direct/derived interval status, and a small smoke before tutorial claims. |
| 333 | Documentation | Structured q4 diagnostics checklist | Done locally as pre-code: q4 rows need Hessian, boundary, profile-target, and derived-interval status checks before routine teaching. |
| 334 | Documentation | Poisson structured q1 smoke spec | Done locally as pre-code: the first non-Gaussian structured candidate is a q1 Poisson `mu` structured intercept smoke. |
| 335 | Documentation | NB2 structured q1 practical spec | Done locally as pre-code: NB2 `mu` q1 structured intercept is the first practical count target after Poisson smoke and overdispersion checks. |
| 336 | Documentation | Non-Gaussian structured ADEMP stub | Done locally as pre-code: the candidate needs an ADEMP sheet before simulation code enters Phase 18. |
| 337 | Documentation | User-route example expansion | Done locally: the public implementation map now gives more explicit fitted alternatives for planned direct-SD, q4, p8/q8, and non-Gaussian structured requests. |
| 338 | Documentation | Stale-claim checklist | Done locally: validation targets false fitted claims for generic `sd*()`, p8/q8, spatial q4, and non-Gaussian structured routes. |
| 339 | Documentation | Roadmap and NEWS sync | Done locally: public and dev ledgers record these as pre-code slices. |
| 340 | Documentation | After-task and validation | Done locally: the after-task report and pkgdown checks close the slice set. |
| 341 | Documentation | Generic direct-SD issue template | Done locally as planning: future generic direct-SD issues must name the target structured level, compatibility route, parser boundaries, extractor rows, reference examples, and stale-name migration path. |
| 342 | Documentation | Generic direct-SD acceptance checklist | Done locally as planning: direct-SD work cannot close without parser, fit-time, prediction/profile, reference, rendered-discoverability, and stale-name checks. |
| 343 | Documentation | Direct-SD migration and stale scan | Done locally as planning: current `sd_phylo*()` routes stay compatible while generic structured examples remain tied to fitted layers only. |
| 344 | Documentation | p8/q8 issue template | Done locally as planning: p8/q8 issues must start from a named endpoint class and record covariance structure, parameter labels, interval policy, diagnostics, and fitted alternatives. |
| 345 | Documentation | p8/q8 acceptance checklist | Done locally as planning: recovery, malformed-input, `corpairs()`, profile-target, Hessian/boundary, and tutorial-warning evidence is required before p8/q8 claims. |
| 346 | Documentation | Spatial q4 issue template | Done locally as planning: spatial q4 parity is scoped to constant location-scale spatial intercepts, not mesh/SPDE, spatial slopes, direct-SD regression, or count models. |
| 347 | Documentation | Spatial q4 acceptance checklist | Done locally as planning: spatial q4 needs endpoint-consistent likelihood, parser, extractor, diagnostic, `corpairs()`, profile-target, and pkgdown-example evidence. |
| 348 | Documentation | Poisson structured q1 issue template | Done locally as planning: first non-Gaussian structured dependence is scoped to one non-zero-inflated Poisson `mu` structured intercept. |
| 349 | Documentation | Poisson structured q1 acceptance checklist | Done locally as planning: Poisson q1 requires one named layer, guarded neighbouring syntax, simulation recovery, and first-slice docs before advertising. |
| 350 | Documentation | NB2 structured q1 issue template | Done locally as planning: NB2 q1 is the first practical count target after the Poisson smoke or explicit safety evidence. |
| 351 | Documentation | NB2 structured q1 acceptance checklist | Done locally as planning: NB2 q1 needs overdispersion-aware recovery, distinct labels, correct scale reporting, guarded zero-inflation/hurdle neighbours, and fallback guidance. |
| 352 | Documentation | Non-Gaussian structured ADEMP gate | Done locally as planning: Poisson or NB2 structured q1 must have an ADEMP sheet before Phase 18 simulation admission. |
| 353 | Documentation | User documentation checklist | Done locally as planning: implementation-map, model-map, reference or tutorial docs, README when appropriate, ROADMAP, NEWS, check-log, and after-task notes move together after fitted-status changes. |
| 354 | Documentation | Review and issue maintenance | Done locally as planning: future issues record Ada, Boole, Gauss, Noether, Fisher, Curie, Emmy, Pat, Darwin, Grace, and Rose review coverage before closeout. |
| 355 | Documentation | Validation and handoff gate | Done locally as planning: pkgdown, rendered scans, stale-support scans, after-task reporting, and the next code issue are required before handoff. |
| 356-370 | Structural dependence | Spatial q4 fitted parity | Done locally: constant coordinate-spatial q4 location-scale covariance fits for all-four labelled Gaussian endpoints, with extractors, `corpairs()`, diagnostics, profile-target status, and boundary tests. |
| 371-380 | Documentation | Spatial q4 evidence and map closeout | Done locally: public status surfaces, formula grammar, NEWS, check-log, after-task report, pkgdown, and stale scans separate fitted spatial q4 from remaining spatial plans. |
| 381-388 | Planning | Non-Gaussian structured-dependence front gate | Done locally as planning: family, component, and layer inventories now narrow the first route to Poisson phylogenetic q1 `mu`, with NB2, `zi`, `hu`, and structured slopes held behind explicit gates. |
| 389-405 | Planning | Remaining non-Gaussian structured-dependence gates | Done locally as planning: scale, shape, ordinal, known-covariance boundaries, extractor/diagnostic/simulation/interval contracts, user-route fallbacks, error-message gates, and issue-template fields now close as design-first gates. |
| 406-420 | Planning | Route-specific implementation issue ledger | Done locally as planning: Poisson implementation, Poisson smoke-runner, malformed-neighbour, documentation, NB2 skeleton, component-boundary, extractor-name, and diagnostic-name issue drafts are recorded without opening code. |
| 421-435 | Planning | Poisson phylogenetic q1 runner contract | Done locally as planning: direct-target, extractor, manifest, warning/error, smoke-grid, formal-grid, comparator, documentation-sync, unsupported-syntax, and test-plan contracts are recorded before broader simulation claims. |
| 436-450 | Evidence sync | Poisson phylogenetic q1 source-ledger synchronization | Done locally: source map, validation debt, Phase 18 programme, readiness matrix, family registry, NEWS, check-log, and after-task notes point to the runner contract while keeping broad simulation closed. |
| 451-465 | Simulation smoke | Poisson phylogenetic q1 smoke runner | Done locally: DGP, fit summariser, runner, summary helper, focused tests, README, source-map, readiness, design docs, check-log, and after-task notes create opt-in smoke infrastructure without formal recovery claims. |
| 466-480 | Simulation artifacts | Poisson phylogenetic q1 grid writer | Done locally: repeatable CSV artifact writer, row-count manifest, focused grid-writer tests, README, source-map, readiness, design docs, check-log, and after-task notes create smoke artifacts without formal recovery claims. |
| 268 | Support audit | Pre-simulation capability matrix | Done locally: `docs/design/46-pre-simulation-readiness-matrix.md` now has one capability audit table that says which Gaussian, non-Gaussian, shape, inflation, bivariate, random-slope, meta-analysis, phylogenetic, spatial, animal, and `relmat()` surfaces are implemented, tested, planned, or unsupported before Phase 18 grids admit them. |
| 269 | Random slopes | Ordinary location random slopes | Done locally: a q=4 ordinary Gaussian `mu` block test now confirms multi-slope SD/correlation names, `corpairs()` classes, and profile-target status, while README/model-map/which-scale wording names q > 2 as fitted but sample-size hungry. |
| 270 | Random slopes | Scale random effects | Done locally: a cross-group Gaussian `sigma` test now confirms two independent residual-scale slope terms, direct `log_sd_sigma` targets, and no residual-scale correlation rows, while docs keep correlated residual-scale slope blocks planned. |
| 271 | Random slopes | Shape and inflation random effects | Done locally by audit and later updated by the fixed-effect zero-one beta source slice: random-slope requests in Student-t `nu`, zero-inflation `zi`, hurdle `hu`, `zoi`, and `coi` stay blocked with component-specific tests; no random-effect likelihood path was opened. |
| 272 | Random slopes | Structured random slopes | Superseded by Slices 39-82: one-slope univariate Gaussian `phylo()`, `animal()`, and `relmat()` `mu` paths are now fitted with extractor, profile-target, diagnostic, and recovery-test evidence. Multiple structured slopes, slope correlations, structured `sigma`, structured `rho12`, and non-Gaussian structured effects remain planned. |
| 273 | Bivariate | Bivariate random-slope combinations | Superseded by Slice 83 for matching slope-only `mu1`/`mu2`: that first slope-slope route is fitted with extractor, profile-target, and diagnostic coverage. Intercept-plus-slope q=4 location blocks, residual-scale slope pairs, same-response location-scale slope combinations, and all-four p8/q8-style slope requests remain boundary-tested before Phase 18 treats those grids as fitted. |
| 274 | Convergence | Control presets and defaults | Done locally: `drm_control(optimizer_preset = "careful")` and `"robust"` now expand to explicit recorded `nlminb()` `iter.max`/`eval.max` budgets, user optimizer values can override a preset, and the convergence guide documents when to use the presets without changing ordinary defaults. |
| 275 | Convergence | Warm starts from simpler models | Done locally by design boundary: warm-start names such as `start_from`, `warm_start`, `warm_starts`, and `warm_start_from` are now reserved, the simpler-fit ladder and provenance contract are documented, and no source-fit start is copied before target namespaces, row handling, diagnostics, and selected-optimum provenance are implemented. |
| 276 | Convergence | Multi-optimizer fallback | Done locally by design boundary: fallback-control names such as `fallback_optimizer`, `fallback_optimizers`, `optimizer_fallback`, and `optimizer_fallbacks` are now reserved, the future `nlminb`/BFGS/L-BFGS-B comparison and selected-optimizer provenance contract is documented, and fallback refits remain planned rather than automatic. |
| 277 | Convergence | Hessian and boundary diagnostics | Done locally: `check_drm()` now reports the largest fixed-gradient component in the `fixed_gradient` row, preserving the existing gradient/Hessian boundary status while making non-converged fits easier to triage before Wald or Hessian-based inference. |
| 278 | CIs and profiles | Interval hardening | Done locally: the interval contract now states which fixed-effect, scale, `rho12`, direct SD/correlation, Fisher-z simulation, derived-variance, and bootstrap routes are supported or deliberately unavailable, with Student-t `nu` fixed-effect interval and Fisher-z helper tests. |
| 279 | Known issues | Bergmann report fixes | Done locally and now partly superseded: invalid fixed-effect Wald variances produce `NA` intervals with `conf.status = "wald_unavailable"`; the old unsupported `sigma ~ phylo()` boundary has been replaced by fitted intercept-only univariate structured `sigma` routes; labelled q4 block-diagonal fallback is tested as separate `mu` and `sigma` q2 blocks; convergence guidance covers long iteration histories. |
| 280 | Meta-analysis | `meta_V(V = V)` hardening | Done locally and superseded by the deprecation slice: vector and full-matrix `meta_V(V = V)` routes now have deprecated-alias and Wald fixed-effect interval coverage, `scale = "exact"` gets a targeted remove-`scale` error because additive exact known-`V` is the default, and `drmTMB()` / `meta_vcov_bivariate()` documentation now leads with `meta_V()` while keeping deprecated `meta_known_V()` as a compatibility alias. |
| 281 | Structural dependence | Animal and `relmat()` user surface | Done locally by documentation hardening, superseded after the 0.1.3 preview line by fitted known-matrix slices: `animal(1 | id, A/Ainv = ...)` and `relmat(1 | id, K/Q = ...)` fit Gaussian `mu` intercepts, matching labelled `mu1`/`mu2` terms fit q=2 bivariate location covariance, and matching all-four `mu1`/`mu2`/`sigma1`/`sigma2` terms fit constant q=4 location-scale covariance. The article still keeps observation-level known sampling covariance in `meta_V(V = V)`, not latent relatedness. |
| 282 | Structural dependence | Sparse precision path | Done locally by documentation hardening: ASReml efficiency notes and user docs now separate dense covariance inputs (`A`, `K`) from sparse precision or inverse-relatedness inputs (`Ainv`, `Q`), keep `meta_V(V = V)` as observation-level sampling covariance, and block large-pedigree or large-matrix speed claims until sparse-precision recovery and benchmark evidence exists. |
| 283 | Non-Gaussian audit | Family and parameter map | Done locally by documentation audit: `docs/design/02-family-registry.md` now lists each public family route, distributional-parameter links, shape or coscale slots, fitted random-effect allowance, and test evidence state, while correcting stale beta-binomial, Poisson, NB2, bivariate, and `meta_V()` wording. |
| 284 | Counts | Count-model hardening | Done locally: Poisson, NB2, zero-truncated NB2, zero-inflated Poisson, zero-inflated NB2, and hurdle NB2 tests now assert fixed-effect Wald interval rows for the fitted count dpars (`mu`, `sigma`, `zi`, and `hu` where relevant), while existing Poisson/NB2 `mu` random-effect tests and Phase 18 smoke surfaces remain the fitted mixed-count evidence; the count tutorial now states that boundary explicitly. |
| 285 | Proportions | Beta, binomial, and one-inflation hardening | Done locally and later extended: fixed-effect beta and beta-binomial `mu`/`sigma` coefficients have Wald interval row tests, fixed-effect `zero_one_beta()` now fits `zoi`/`coi`, and the proportion tutorial keeps richer bounded-response random effects, structured effects, beta-binomial zero-inflation, and bounded-response `meta_V(V = V)` routes planned or blocked. |
| 286 | Continuous shape | Heavy-tail and skewness design | Done locally by design hardening: `docs/design/02-family-registry.md` now separates fitted fixed-effect Student-t `nu`, planned fixed-effect skew-normal `nu`, planned skew-t `nu`/future `tau`, and design-only latent-effect `skew(id) ~ ...`; likelihood, tutorial, readiness, NEWS, and formula-grammar text keep shape/skewness random effects out of Phase 18 until fixed-effect density, recovery, false-positive, diagnostic, and interval evidence exists. |
| 287 | Ordinal | Ordinal readiness | Done locally: `docs/design/25-ordinal-scale-discrimination.md` now records the fixed-effect `cumulative_logit()` evidence ledger for likelihood, cutpoints, prediction, expected-score summaries, simulation, fixed-effect Wald intervals, internal cutpoint profile targets, malformed inputs, and unsupported random-effect boundaries; README, the family registry, the distribution-family tutorial, and the pre-simulation matrix keep ordinal random effects, scale/discrimination formulas, structured ordinal effects, bivariate ordinal, and mixed-response ordinal models planned or unsupported. |
| 288 | Bivariate mixed families | Mixed-response combinations | Done locally by boundary hardening: mixed-response combinations such as Gaussian-count, Gaussian-proportion, count-proportion, ordinal mixed, and other two-response families remain planned, tests now cover mixed-family errors for both `c()` and `list()` spellings plus reversed Gaussian-Poisson order, and the family registry, distribution-family tutorial, NEWS, and pre-simulation matrix require a joint likelihood or copula/latent-variable contract, prediction, simulation, extractors, intervals, examples, and comparator checks before any mixed-response route is fitted. |
| 289 | Extractors | Prediction and plotting contracts | Done locally: `corpairs()` now returns `conf.status` and `interval_source` by default, `corpairs(conf.int = TRUE)` marks profiled rows with `interval_source = "profile"`, `plot_corpairs()` draws finite bounds only when status and source mark a real interval, and the readiness matrix records how this shared provenance rule relates to `predict_parameters()`, `vcov()`, the narrow `emmeans()` bridge, and plotting helpers. |
| 290 | Documentation | User-facing boundaries | Done locally: README, the model-map article, the package reference topic, the getting-started article, source-map guidance, and pkgdown reference-section descriptions now share a status vocabulary for stable, first slice, opt-in, planned or reserved, and unsupported or blocked surfaces. |
| 291 | Pre-simulation gate | Evidence ledger | Done locally: `docs/design/46-pre-simulation-readiness-matrix.md` now has a Slice 291 evidence-ledger gate that maps each public stable-core row to implementation evidence, tests or diagnostics, user-facing boundaries, and Phase 18 admission status; `docs/design/41-phase-18-simulation-programme.md` and `docs/design/34-validation-debt-register.md` now require new DGP rows to trace back to this gate before they enter admitted simulation grids. |
| 292 | Phase 18 start | Comprehensive simulation blueprint | Done locally as blueprint: `docs/design/41-phase-18-simulation-programme.md` now has a Slice 292 scenario map covering continuous, proportion, count, ordinal, meta-analysis, bivariate, random-slope, shape, phylogenetic, spatial, `animal()`, and `relmat()` lanes; admitted surfaces require one-page ADEMP sheets before new DGP code, while planned or blocked lanes stay in the failure ledger. |
| 293 | Phase 18 design sheet | Gaussian location-scale ADEMP | Done locally: `docs/design/47-phase-18-gaussian-location-scale-ademp.md` now records aims, DGP conditions, estimands, methods, performance measures, MCSE targets, and Williams-style reporting checks for the admitted Gaussian location-scale lane before larger grids run. |
| 294 | Phase 18 design sheet | `meta_V(V = V)` ADEMP | Done locally: `docs/design/48-phase-18-meta-v-ademp.md` now records aims, vector/dense known-`V` DGP conditions, estimands, methods, performance measures, MCSE targets, and Williams-style reporting checks for the admitted Gaussian meta-analysis lane, while keeping known sampling covariance as input data rather than an estimated interval target. |
| 295 | Phase 18 design sheet | Count `mu` random-effect ADEMP | Done locally: `docs/design/49-phase-18-count-mu-random-effect-ademp.md` now records aims, Poisson/NB2 grouped-count DGPs, estimands, methods, performance measures, MCSE targets, and Williams-style reporting checks for the paired ordinary count `mu` random-effect lane, while keeping zero-inflated, hurdle, zero-truncated, structured, correlated-slope, and labelled covariance count models in the failure ledger. |
| 296 | Phase 18 design sheet | Proportion fixed-effect ADEMP | Done locally: `docs/design/50-phase-18-proportion-fixed-effect-ademp.md` now records aims, beta/beta-binomial DGPs, denominator generation, boundary handling, estimands, methods, performance measures, MCSE targets, and Williams-style reporting checks for the fixed-effect proportion lane, while keeping exact 0/1 boundary mass, `zoi`/`coi`, random effects beyond the beta and beta-binomial ordinary `mu` intercept/slope slices, structured effects, known sampling covariance, and mixed-response bounded models in the failure ledger. |
| 297 | Phase 18 design sheet | Ordinal fixed-effect ADEMP | Done locally: `docs/design/51-phase-18-ordinal-fixed-effect-ademp.md` now records aims, cumulative-logit DGPs, category probabilities, cutpoint recovery, expected-score summaries, malformed-input boundaries, performance measures, MCSE targets, and Williams-style reporting checks for the fixed-effect ordinal lane, while keeping ordinal random effects, scale/discrimination formulas, cutpoint-specific predictors, known sampling covariance, bivariate ordinal models, and mixed-response ordinal models in the failure ledger. |
| 298 | Phase 18 design sheet | Bivariate residual `rho12` ADEMP | Done locally: `docs/design/52-phase-18-bivariate-rho12-ademp.md` now records aims, bivariate Gaussian residual-correlation DGPs, response-specific mean and scale estimands, response-scale `rho12` and covariance grids, boundary diagnostics, performance measures, MCSE targets, and Williams-style reporting checks, while keeping group-level `corpairs()`, structured correlations, known sampling covariance, random effects in `rho12`, mixed-response families, and bivariate random slopes in separate design or failure-ledger lanes. |

## Phase 18: Comprehensive Simulation, Power, Accuracy, and Coverage Evidence

- Status: staged. The reusable simulation infrastructure is partly
  implemented locally, while broad operating-characteristic grids and public
  bootstrap intervals remain planned.
- Build a documented simulation programme that lets project leaders, reviewers,
  and applied readers understand when `drmTMB` is accurate enough for the
  models it claims to fit.
- Treat simulation as a scientific communication layer, not only a test layer.
  Each simulation should name the biological or methodological question, the
  data-generating model, the estimand, the fitted model, and the failure modes
  being probed.
- Add reusable simulation helpers that can also support earlier examples:
  scenario builders, transparent data-generating functions, seed control,
  compact result summaries, and plot-ready output for fitted parameters,
  convergence, diagnostics, and interval status.
- Include power analysis where it answers a reader question: for example, how
  many groups, species, sites, repeated observations, or effect sizes are needed
  to detect a change in `sigma`, `rho12`, `sd(group)`, phylogenetic SD, spatial
  SD, or a structured correlation with acceptable uncertainty.
- Report operating characteristics alongside power: bias, empirical standard
  error, root-mean-square error, profile or Wald interval coverage, convergence
  rate, boundary-hit rate, and diagnostic false-positive or false-negative
  rates.
- Keep routine CRAN tests small and deterministic. The comprehensive grids
  should live in optional scripts, scheduled CI, rendered reports, or paper
  supplements, with compact CRAN smoke tests proving that the simulation
  helpers still run.
- Curie's gate: every simulation helper needs tests for reproducibility,
  malformed input, and summary shape. Fisher's gate: every power or coverage
  statement must name the data-generating scenario and the uncertainty measure.
  Pat's gate: every simulation report should include an interpretation that a
  new applied user can read without reverse-engineering the code.
- Current execution bridge: Slices 539-668 add bounded private bootstrap and
  replicate-runner execution for the existing Phase 18 smoke surfaces. The
  private helpers support serial execution and Unix `multicore`, cap actual
  workers at 10 and at the number of jobs, record requested versus actual core
  counts, and use per-replicate summary factories where profile or bootstrap
  seeds must travel with a replicate. Slices 679-688 forward those settings
  through the first grid and count-gallery wrappers, while keeping separate
  bootstrap backend settings for Student-t shape and bivariate residual
  `rho12` grids to avoid accidental nested parallelism; Slices 689-698 enforce
  that policy when both layers would use more than one worker. Slices 699-708
  give the admitted `meta_V(V = V)` lane the same repeatable grid-output CSV
  and RDS artifact path as the other first-wave surfaces. Slices 709-718 give
  the paired Poisson/NB2 `mu` random-effect lane the same repeatable artifact
  path, including direct-SD profile interval and coverage CSVs. PSOCK remains
  excluded from this package helper until fitted `TMB` object rebuild semantics
  are explicit. Slices 719-728 add repeatable simple artifact writers for
  ordinary Gaussian `mu` random slopes, independent Gaussian `sigma` random
  slopes, and coordinate-spatial Gaussian `mu` slopes. Slices 729-738 add a
  grid-artifact manifest helper so report staging can audit file existence and
  CSV row counts, including empty optional interval tables; Slices 739-748 add
  bind and status summaries across those manifests. Slices 749-758 add a
  first-wave artifact-status writer that saves bound manifest and
  surface-status CSVs before a report consumes the tables. Slices 759-768 add
  the matching artifact-status report template, including a clear failure path
  when required artifacts are missing. Slices 769-778 add a table-bundle writer
  that combines selected first-wave CSV artifacts across grid outputs while
  preserving source surface and artifact columns. Slices 779-788 add the first
  first-wave summary-report skeleton over artifact status, aggregate rows,
  interval diagnostics, interval failures, manifests, and warning/error ledgers.
  Slices 789-798 add the orchestration helper that writes status outputs,
  bundled tables, and an optional HTML summary report in one step. Slices
  839-868 polish the first-wave summary report with priority columns, row caps,
  a compact warning/error summary above the raw ledger, and a compact
  aggregate-bias overview for quick screening. Slices 869-878 add compact
  interval-coverage summaries for Wald, profile, and bootstrap coverage
  artifacts when present. Slices 879-888 add run-manifest summaries for status,
  warnings, errors, skipped rows, and elapsed time. This simulation
  infrastructure is separate from the later public direct-target
  `confint(method = "bootstrap")` route.
- Slices 1279-1388 add the core-family completion map, fixed-effect
  proportion, positive-continuous, ordinal, and zero-one beta artifact lanes,
  plus ordinary `mu` random-intercept artifact lanes for beta/beta-binomial and
  lognormal/Gamma/Student-t. These lanes add DGP, summariser, smoke,
  repeatable grid-output, first-wave summary, manual Actions-dispatch, and
  focused-test evidence for already fitted one-response families; they do not
  open random slopes, structured, mixed-response, skew-normal, Tweedie, or
  generalized
  Gamma likelihoods.
- First three implementation slices after the blueprint: the `inst/sim/`
  skeleton and seed/cell registry are done locally in Slice 210; the Gaussian
  location-scale DGP and pilot summariser are done locally in Slice 211; the
  Gaussian meta-analysis `meta_V(V = V)` DGP with vector and dense matrix `V`
  is done locally in Slice 212; a generic resumable replicate runner is done
  locally in Slice 213; the first end-to-end Gaussian location-scale smoke
  runner is done locally in Slice 214; the matching vector/dense `meta_V(V = V)`
  smoke runner is done locally in Slice 215; the first parameter-level
  aggregation helper is done locally in Slice 216; MCSE and explicit
  interval-coverage helpers are done locally in Slice 217; the first Gaussian
  location-scale summary-smoke run is done locally in Slice 218; the matching
  vector/dense `meta_V(V = V)` summary-smoke run is done locally in Slice 219.
  A reader-facing smoke report template is done locally in Slice 220. A compact
  result manifest helper is done locally in Slice 222 so resumed runs can be
  audited without opening every RDS object. A warning/error failure-ledger
  helper is done locally in Slice 223. Result-directory loading is done locally
  in Slice 224 so manifests and ledgers can be rebuilt from saved RDS output.
  Summary-smoke helpers return manifests and failure ledgers locally in Slice
  225. Synthetic interval-coverage smoke plumbing is done locally in Slice 226.
  The smoke report template accepts aggregate, manifest, and warning/error
  ledger CSVs locally in Slice 227. A skip-aware report-render test with tiny
  CSV fixtures is done locally in Slice 228. The interval-producer contract is
  recorded locally in Slice 229. A generic Wald interval-table helper is done
  locally in Slice 230 for summaries that already contain estimates and
  standard errors. A Fisher-z back-transformed correlation Wald helper is done
  locally in Slice 231. Gaussian location-scale pilot summaries carry
  fixed-effect standard errors locally in Slice 232. Next, connect those
  standard errors to Gaussian location-scale Wald coverage summaries. Gaussian
  location-scale summary smoke returns formula-coefficient Wald intervals and
  coverage locally in Slice 233. `meta_V(V = V)` pilot summaries carry standard
  errors for estimated `mu` coefficients and fitted residual `sigma` locally in
  Slice 234. `meta_V(V = V)` summary smoke returns Wald intervals and coverage
  locally in Slice 235. The random-slope promise audit is done locally in Slice
  236, reconciling the ordinary Gaussian `mu` q > 2 fitted path with the
  remaining Gaussian `sigma`, structured, bivariate, and non-Gaussian
  random-slope gates before broader Phase 18 grids begin. A Gaussian `mu` q=3
  random-slope smoke surface is done locally in Slice 237, giving the fitted
  ordinary multi-slope block a seeded DGP, runner, summary, aggregate, manifest,
  and failure-ledger path before larger grids are allowed. A Gaussian `sigma`
  independent one-slope smoke surface is done locally in Slice 238, giving the
  fitted residual-scale `(0 + w | id)` path the same Phase 18 bookkeeping while
  leaving correlated scale-slope covariance outside Wave A. Slice 239 records
  the structured-slope parity gate: coordinate spatial has one fitted Gaussian
  `mu` slope, while phylogenetic, animal, and `relmat()` one-slope paths remain
  planned until their implementation, profile targets, diagnostics, recovery
  tests, and biological examples exist. Slice 240 records the
  cross-distributional-parameter correlation gate. Slice 241 adds a coordinate
  spatial Gaussian `mu` one-slope smoke surface. Slice 242 adds a Poisson `mu`
  random-effect smoke surface; Slice 243 adds fixed-effect Wald interval
  coverage for that smoke output; Slice 244 adds direct profile-likelihood SD
  interval coverage for the Poisson random-effect SD targets. Slice 245 fits
  ordinary non-zero-inflated NB2 `mu` random intercepts and independent numeric
  slopes with extractor and direct profile-target coverage, while keeping NB2
  `sigma`, zero-inflated NB2 random effects, and correlated or labelled NB2
  slope blocks outside Wave A. Slice 246 adds the matching NB2 `mu`
  random-effect smoke surface with seeded DGP, live fit, parameter summaries,
  aggregate output, manifest, failure ledger, and tests. Slice 247 attaches
  fixed-effect Wald interval rows and coverage summaries to that NB2 smoke
  output for `mu` and `sigma` coefficients, while leaving random-effect SD
  profile coverage as the next evidence step. Slice 248 attaches direct
  profile-likelihood interval rows and coverage summaries for the two fitted
  NB2 `sd:mu` targets in that smoke output. Slice 249 adds a focused weak-SD
  boundary diagnostic for fitted NB2 `mu` random intercepts and keeps larger
  NB2 operating-characteristic grids as future Phase 18 work. Slice 250 records
  a pre-simulation readiness matrix that separates surfaces ready for small
  grids from planned or blocked surfaces before broad Phase 18 reports are
  written. Slice 251 starts the first paired count pilot, combining ready
  Poisson and NB2 `mu` random-effect surfaces into one optional output with
  aggregate, manifest, failure-ledger, Wald-coverage, and profile-coverage
  tables. Slice 252 makes the Poisson and NB2 condition helpers true grid
  builders, allowing optional count pilots to vary group count, repeats, true
  random-effect SDs, fixed mean effects, and NB2 overdispersion settings. Slice
  253 adds the first simulation plot-data contract for the paired count pilot,
  preparing aggregate, coverage, manifest, and failure tables for Florence's
  later figure gallery. Slice 254 adds the first Florence-facing count pilot
  gallery template for bias, RMSE, interval coverage, manifests, and
  warning/error ledgers. Slice 255 adds helper plumbing that writes the
  plot-ready CSV inputs and renders a checked local HTML gallery artifact from
  a paired count pilot object. Slice 256 adds the end-to-end smoke runner that
  runs a tiny paired count pilot, writes gallery inputs, renders the gallery,
  and returns both the pilot and artifact paths. Slice 257 applies the first
  Florence visual polish to that gallery, replacing default diagnostic panels
  with horizontal estimand labels, shared palette/theme helpers, plot captions,
  and MCSE-aware coverage ranges when available. Slice 258 built a narrow
  pkgdown-facing count simulation diagnostics draft, but that page was removed
  from the public site for now because it was not the broad figure gallery the
  user intended. Count diagnostics should return later as a Simulation &
  Comparison article after continuous, proportion, count, meta-analysis, and
  other surfaces are ready to be compared in one framework.

## Structured Slope Parity Gate

- `docs/design/44-structured-slope-parity-gate.md` records the current
  structured-effect slope boundary before Phase 18. Spatial, phylogenetic,
  animal, and `relmat()` one-slope Gaussian `mu` models can enter focused
  Wave A grids; multiple structured slopes, slope correlations, structured
  `sigma`, and non-Gaussian structured effects remain in the failure ledger.
- The intended public order remains biological: `animal()` for pedigree or
  additive relatedness, `phylo()` for shared ancestry, `spatial()` for
  coordinate or mesh structure, combined structural layers when required, and
  `relmat()` as the lower-level known-relatedness escape hatch.

## ASReml Efficiency Lessons For Future Animal Models

- `docs/design/42-asreml-efficiency-lessons.md` records a design-only
  inspection of the local ASReml-R archive. The main lesson is that large
  animal-model performance depends on sparse inverse relationship structures,
  row-name matching metadata, log-determinant bookkeeping, and clear
  covariance-versus-precision contracts.
- For `drmTMB`, `animal()` should remain biological sugar, while `relmat()`
  should become the lower-level known-matrix surface with explicit `K`
  covariance and `Q` precision paths. Do not claim ASReml-like large-pedigree
  speed until the sparse-precision route exists and passes recovery and scaling
  tests.

## Phase 19: Comparator Demonstrations With Other Packages

- Status: planned.
- Compare `drmTMB` with related packages on the same simulated or transparent
  example datasets, but do not make this a repeated simulation phase. Phase 19
  should be a model-overlap and communication layer; Phase 18 is the operating
  characteristics layer.
- For each comparator example, fit one or a few matched datasets with the
  closest defensible model in `drmTMB` and relevant overlap packages such as
  `glmmTMB`, `lme4`, `brms`, `MCMCglmm`, `metafor`, `gamlss`, `sdmTMB`, or
  package-specific TMB examples.
- Report model syntax, model class, fitted parameter estimates on comparable
  scales, standard errors or intervals when available, optimizer or sampler
  diagnostics, and elapsed fitting time.
- Be explicit about non-overlap. If a comparator package cannot fit
  predictor-dependent residual `rho12`, a location-scale phylogenetic block, a
  known dense meta-analytic covariance, or a structured random-effect scale
  model, say so rather than forcing a misleading comparison.
- Use the same simulation helpers and visualization data contracts from Phases
  17 and 18, so comparator articles can reuse datasets, plots, timing summaries,
  and parameter-scale conversions.
- Jason's gate: every comparator must cite the comparator package capability or
  documentation it relies on. Grace's gate: optional heavy packages and MCMC
  fits must stay outside routine CRAN checks. Rose's gate: comparator articles
  must not turn one-off examples into broad speed or accuracy claims.

## Phase 20: CRAN Release and Paper Preparation

- Status: planned.
- Harden the package for CRAN with platform checks, dependency review, examples,
  vignettes, pkgdown, NEWS, reverse-dependency awareness where relevant, and a
  final implemented-versus-planned audit.
- Build the teaching sequence around applied ecological, evolutionary, and
  environmental examples, while keeping the package general like `glmmTMB`.
- Use Phase 18 simulation reports and Phase 19 comparator demonstrations as the
  evidence base for release notes, paper figures, supplementary material, and
  reviewer responses.
- Draft methods papers around the package-defining pieces: fast
  location-scale regression, modelled residual `rho12`, structured
  phylogenetic/spatial distributional regression, and documented simulation
  evidence for accuracy, coverage, and power.
- Grace's gate: release preparation should not begin until the site, examples,
  check logs, known limitations, and roadmap agree about supported syntax and
  fitted model classes. Rose's gate: paper text must not describe roadmap
  features as implemented unless code, tests, docs, examples, and validation
  evidence exist.
