# Structural Slopes And Non-Gaussian Dependence Map

This note is the closeout ledger for #128. It keeps ordinary location
slopes, residual-scale slopes, random-effect scale models, bivariate slope
blocks, structured Gaussian slopes, and non-Gaussian random-effect slices in
separate rows so the package does not promote a nearby fitted cell as broad
random-slope parity.

This note answers two user-facing status questions after the post-0.1.3
structural-parity slices:

1. Do all random-effect types have at least one fitted random-slope route?
2. Does structural dependence work in non-Gaussian settings?

The short answers are closer now, but still bounded. `drmTMB` has at least one
fitted random-slope route for ordinary Gaussian `mu`, ordinary Gaussian
`sigma`, the first ordinary bivariate Gaussian slope-only and smoke-artifact-routed
q=4/q=6 location `mu1`/`mu2` covariance routes, coordinate spatial Gaussian `mu`,
phylogenetic Gaussian
`mu`, animal-model Gaussian `mu`, `relmat()` Gaussian `mu`, ordinary
Poisson/NB2 `mu`, and selected ordinary Student-t/lognormal/Gamma/beta/
beta-binomial/zero-truncated NB2 `mu`. Broader bivariate random slopes and
most structured non-Gaussian dependence remain planned. The fitted structured
non-Gaussian routes are narrow ordinary Poisson/NB2 q=1 `mu` intercept slices
for `phylo()`, `spatial()`, `animal()`, and `relmat()`; they are
source-test, smoke, or diagnostic lanes, not broad count parity.

## Random-Slope Parity

| Random-effect layer | At least one fitted random slope? | Fitted route | Still planned or blocked |
| --- | --- | --- | --- |
| Ordinary Gaussian `mu` group effects | Yes | Independent numeric slopes such as `(0 + x | id)` and one correlated intercept-slope block such as `(1 + x | id)`; q > 2 ordinary `mu` blocks are fitted but advanced | Bivariate slope1-slope2 covariance and broader cross-parameter slope covariance |
| Ordinary Gaussian `sigma` group effects | Yes | Independent residual-scale slopes such as `sigma ~ z + (0 + w | id)` on the log-`sigma` predictor | Correlated residual-scale slope blocks and labelled `mu`/`sigma` slope covariance |
| Ordinary bivariate group covariance | Yes, first slices | Matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, constant q=4 intercept location-scale blocks, matching slope-only `mu1`/`mu2` blocks, and matching q=4/q=6 `mu1`/`mu2` location blocks with smoke artifact routing are fitted | Residual-scale slope covariance, same-response location-scale slope covariance, all-four p8/q8 slope location-scale blocks, predictor-dependent slope `corpair()` regressions, and formal q > 2 simulation recovery |
| Coordinate spatial Gaussian effects | Yes | `spatial(1 | site, coords = coords)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `spatial(1 + x | site, coords = coords)` fits independent coordinate-spatial intercept and slope fields for univariate Gaussian `mu` | Multiple spatial slopes, residual-scale structured slopes, spatial intercept-slope correlation, bivariate spatial slopes, mesh/SPDE |
| Phylogenetic Gaussian effects | Yes | `phylo(1 | species, tree = tree)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `phylo(1 + x | species, tree = tree)` fits independent phylogenetic intercept and slope fields for univariate Gaussian `mu`; matching bivariate `mu1`/`mu2`, selected q=4 location-scale, direct `sd_phylo*()`, and q=2 phylogenetic `corpair()` routes are also fitted | Multiple phylogenetic slopes, residual-scale structured slopes, phylogenetic slope correlations, bivariate phylogenetic slopes, and phylogenetic non-Gaussian effects |
| `animal()` Gaussian effects | Yes | `animal(1 | id, pedigree/A/Ainv = ...)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `animal(1 + x | id, pedigree/A/Ainv = ...)` fits independent animal-model intercept and slope fields for univariate Gaussian `mu`; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Sparse large-pedigree construction, multiple animal slopes, residual-scale structured slopes, animal slope correlations, predictor-dependent `corpair()`, direct-SD grammar |
| `relmat()` Gaussian effects | Yes | `relmat(1 | id, K/Q = ...)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `relmat(1 + x | id, K/Q = ...)` fits independent relatedness intercept and slope fields for univariate Gaussian `mu`; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Multiple `relmat()` slopes, residual-scale structured slopes, slope correlations, predictor-dependent `corpair()`, direct-SD grammar |
| Selected non-Gaussian `mu` group effects | Yes, first slice | Student-t, lognormal, Gamma, beta, beta-binomial, and zero-truncated NB2 `mu` random intercepts and independent numeric slopes such as `(0 + x | id)` | Correlated slopes, labelled covariance blocks, non-Gaussian `sigma` or shape random effects, zero-one beta random effects, hurdle/inflation random effects, and structured dependence |
| Ordinary Poisson `mu` group effects | Yes, first slice | Non-zero-inflated Poisson `mu` random intercepts and independent numeric slopes on the log-mean predictor; one q=1 structured log-mean intercept can use `phylo()`, `spatial()`, `animal()`, or `relmat()` | Correlated Poisson slopes, labelled covariance blocks, zero-inflated Poisson random effects, Poisson structured slopes, simultaneous structured types, and structured count covariance |
| Ordinary NB2 group effects | Yes, first slice | Non-zero-inflated NB2 `mu` random intercepts and independent numeric slopes on the log-mean predictor; `sigma ~ z + (1 | id)` fits the first grouped overdispersion random intercept on log-`sigma`; one q=1 structured log-mean intercept can use `phylo()`, `spatial()`, `animal()`, or `relmat()` with fixed-effect `sigma` | Correlated NB2 slopes, NB2 `sigma` slopes, joint `mu`/`sigma` random effects, zero-inflated NB2 random effects, NB2 structured slopes or structured `sigma`, labelled covariance, and simultaneous structured types |
| `sd(group)` random-effect SD models | No slope-specific SD route | Fitted for unlabelled Gaussian `mu` random-intercept SD surfaces such as `sd(id) ~ x_group` | Coefficient-specific random-slope SD formulas such as `sd(id, coef = "x") ~ ...` |
| Meta-analysis known `V` | Not a random-slope layer | `meta_V(V = V)` treats sampling covariance as known input data | Variance-component meta-analysis and phylogenetic-plus-study extensions |

## Evidence Handles For The Matrix

- Ordinary Gaussian `mu` q > 2 and Gaussian `sigma` independent slopes are
  tracked in `docs/design/33-phase-6c-core-random-effects.md`,
  `tests/testthat/test-gaussian-random-intercepts.R`,
  `tests/testthat/test-gaussian-location-scale.R`,
  `tests/testthat/test-phase18-gaussian-mu-random-slope.R`, and
  `tests/testthat/test-phase18-random-slope-grid-writers.R`.
- The first ordinary bivariate slope-only and one-slope q=4 `mu1`/`mu2` location
  routes are tracked in
  `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-phase18-biv-gaussian-mu-slope.R`, and the after-task
  reports for the bivariate Gaussian slope smoke, grid writer, Actions task, and
  q4/q6 location smoke routes.
- The structured one-slope Gaussian `mu` routes are tracked in
  `docs/design/44-structured-slope-parity-gate.md`,
  `docs/design/60-structural-parity-slices-39-82.md`,
  `tests/testthat/test-spatial-gaussian.R`,
  `tests/testthat/test-phylo-gaussian.R`, and
  `tests/testthat/test-animal-relmat-gaussian.R`.
- The selected non-Gaussian `mu` slope and structured count q=1 boundaries are
  tracked in `tests/testthat/test-nongaussian-mu-random-slopes.R`,
  `tests/testthat/test-count-structured-mu.R`,
  `tests/testthat/test-phase18-count-structured-q1.R`,
  `docs/design/41-phase-18-simulation-programme.md`, and
  `docs/design/46-pre-simulation-readiness-matrix.md`.

The practical consequence is that the first structured one-slope parity gap is
closed for univariate Gaussian `mu`, and the first ordinary bivariate
slope-slope plus q=4/q=6 location gaps are opened for matching `mu1`/`mu2`
slopes. The next slope gaps are residual-scale bivariate slope covariance,
same-response location-scale slope covariance, all-four p8/q8 location-scale
covariance, multiple structured slopes, structured slope
correlations, and non-Gaussian structured effects.

The #440 bivariate slope-only evidence gate is recorded in
`docs/design/145-phase6c-bivariate-slope-evidence-gate.md`. Its decision is
artifact-ready and held from recovery, coverage, and power claims: the matching
`mu1`/`mu2` slope-only route has extractor, profile-target, diagnostic,
Phase 18 helper, artifact-writer, manual Actions, and one small pilot-artifact
handle, but #446 remains responsible for the formal simulation plan.

## Structured Gaussian Audit Closure

The #442 audit closes the current-status question for the four Gaussian
structured one-slope routes. The fitted claim is deliberately narrow: one
numeric univariate Gaussian `mu` slope fits as independent structured intercept
and slope fields. It is not a slope-correlation model, not a residual-scale
structured slope, and not a random effect in residual `rho12`.

| Route | One-slope `mu` status | q2/q4 covariance status | Evidence handles | Still outside |
| --- | --- | --- | --- | --- |
| `phylo()` | Fitted for one numeric univariate Gaussian `mu` slope with independent phylogenetic intercept and slope fields | q2 bivariate location covariance, q2 phylogenetic `corpair()` regression, selected full q4 location-scale, and block-diagonal q4 fallback rows are fitted first slices; full q4 correlations are derived-only and block-diagonal q4 correlations still need fit-specific profile diagnostics | `tests/testthat/test-phylo-gaussian.R`, `tests/testthat/test-check-drm.R`, `tests/testthat/test-profile-targets.R`, `docs/design/44-structured-slope-parity-gate.md`, `docs/design/46-pre-simulation-readiness-matrix.md` | Multiple phylogenetic slopes, phylogenetic slope correlations, residual-scale structured slopes, structured `rho12`, non-Gaussian phylogenetic slopes, and predictor-dependent q4 correlations |
| `spatial()` | Fitted for one numeric univariate Gaussian `mu` slope with independent coordinate-spatial intercept and slope fields | q2 bivariate location covariance and constant q4 location-scale rows are fitted first slices; q4 is extractor/diagnostic smoke rather than formal coverage evidence | `tests/testthat/test-spatial-gaussian.R`, `tests/testthat/test-phase18-spatial-mu-slope.R`, `tests/testthat/test-phase18-random-slope-grid-writers.R`, `docs/design/46-pre-simulation-readiness-matrix.md` | Mesh/SPDE, multiple spatial slopes, spatial slope correlations, residual-scale structured slopes, spatial direct-SD surfaces, spatial `corpair()` regression, and non-Gaussian spatial slopes |
| `animal()` | Fitted for one numeric univariate Gaussian `mu` slope with independent animal-model intercept and slope fields | q2 bivariate location covariance and constant q4 location-scale rows are fitted first slices; q4 correlation intervals are derived-unavailable | `tests/testthat/test-animal-relmat-gaussian.R`, `docs/design/44-structured-slope-parity-gate.md`, `docs/design/46-pre-simulation-readiness-matrix.md` | Sparse large-pedigree speed claims, multiple animal slopes, animal slope correlations, residual-scale structured slopes, predictor-dependent `corpair()` regression, count slopes, labelled count covariance, and generic direct-SD grammar |
| `relmat()` | Fitted for one numeric univariate Gaussian `mu` slope with independent known-matrix intercept and slope fields | q2 bivariate location covariance and constant q4 location-scale rows are fitted first slices; q4 correlation intervals are derived-unavailable | `tests/testthat/test-animal-relmat-gaussian.R`, `docs/design/44-structured-slope-parity-gate.md`, `docs/design/46-pre-simulation-readiness-matrix.md` | Multiple `relmat()` slopes, relatedness slope correlations, residual-scale structured slopes, predictor-dependent `corpair()` regression, count slopes, labelled count covariance, and generic direct-SD grammar |

Metadata access is not a blocker for this audit. Issue #335 is closed by the
exported `structured_effects()` accessor, so downstream packages no longer
need formula-string greps to identify `phylo()`, `spatial()`, `animal()`, or
`relmat()` markers. Phase 18 wrapper and artifact-routing gaps remain in the
simulation programme and should be handled by #446 or focused follow-up
issues, not by broadening the fitted-surface claim here.

## Non-Gaussian Structural Dependence

| Non-Gaussian surface | Implemented now? | What is fitted | What is not fitted |
| --- | --- | --- | --- |
| Fixed-effect non-Gaussian families | Yes | Poisson, NB2, zero-inflated counts, truncated/hurdle NB2, beta, beta-binomial, Gamma, lognormal, Student-t, and fixed-effect ordinal routes where listed in the family registry | Fixed-effect support does not imply random effects or structural dependence |
| Selected ordinary non-Gaussian `mu` random effects | Yes, first slice | Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial fit ordinary unlabelled `mu` random intercepts such as `(1 | id)` and independent numeric slopes such as `(0 + x | id)` | Correlated slopes, labelled covariance, `sigma` or shape random effects, and structured dependence |
| Ordinary Poisson mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts, independent numeric `mu` slopes, and one q=1 structured log-mean intercept from `phylo()`, `spatial()`, `animal()`, or `relmat()` | `zi` random effects, correlated slopes, labelled covariance, structured slopes, and simultaneous structured count types |
| Ordinary NB2 mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts, independent numeric `mu` slopes, ordinary log-`sigma` random intercepts, and one q=1 structured log-mean intercept from `phylo()`, `spatial()`, `animal()`, or `relmat()` | NB2 `sigma` slopes or structured effects, zero-inflation random effects, correlated slopes, structured count slopes, labelled covariance, and simultaneous structured count types |
| Non-Gaussian `sigma`, shape, inflation, hurdle, zero-one, or one-inflation random effects | Mostly no | Fixed-effect formulas exist for selected families and parameters; ordinary NB2 has a first log-`sigma` random-intercept gate | Random effects in these distributional parameters are otherwise blocked or planned |
| Ordinal mixed models | No | Fixed-effect cumulative-logit ordinal location | Ordinal random effects, ordinal scale/discrimination, structured ordinal effects |
| Structured non-Gaussian dependence | First Poisson/NB2 slices only | Ordinary Poisson and ordinary NB2 fit one q=1 `phylo()`, `spatial()`, `animal()`, or `relmat()` effect in `mu`, with `sdpars`, marker-specific `ranef()` blocks, `profile_targets()`, and `check_drm()` evidence | Zero-inflated structured effects, structured count slopes, labelled q=2/q=4 count blocks, NB2 structured `sigma`, simultaneous structured types, and non-count spatial/animal/`relmat()` routes remain planned until family-specific recovery evidence exists |
| Mixed-response bivariate non-Gaussian models | No | All-Gaussian bivariate models are fitted | Gaussian-count, count-count, ordinal-mixed, and other mixed-response bivariate likelihoods remain planned |

For applied users, the current route is therefore:

- use Gaussian structural dependence when the response model is Gaussian and
  the fitted structured layer matches the question;
- use ordinary Poisson or NB2 `mu` random effects for count mixed models when
  a plain grouping factor is enough;
- use ordinary NB2 `sigma ~ z + (1 | id)` only when the question is grouped
  overdispersion heterogeneity with no simultaneous `mu` random effects;
- use ordinary Poisson or NB2 `phylo(1 | species, tree = tree)`,
  `spatial(1 | site, coords = coords)`, `animal(1 | id, ...)`, or
  `relmat(1 | id, ...)` only when the count question is one q=1 structured
  log-mean intercept and, for NB2, fixed `sigma` overdispersion is enough;
- do not fit zero-inflated structured count models, structured count slopes,
  labelled count covariance, simultaneous structured count types, or
  structured effects in NB2 `sigma`.

That boundary is conservative, but useful. Non-Gaussian links, latent
structured matrices, zero inflation, and distributional scale or shape
parameters can all change identifiability. The package should not advertise
non-Gaussian structural dependence beyond the Poisson/NB2 q=1 structured
`mu` intercept routes until it has the same evidence standard as the Gaussian
routes: likelihood code, focused recovery tests, extractors, diagnostics,
interval-status rows, examples, check-log evidence, and an after-task report.
