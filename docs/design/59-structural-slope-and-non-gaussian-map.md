# Structural Slopes And Non-Gaussian Dependence Map

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
`sigma`, the first ordinary bivariate Gaussian slope-only and
smoke-artifact-routed q=4/q=6 location `mu1`/`mu2` covariance routes, the first
same-response bivariate Gaussian q2 `mu`/`sigma` slope route, the first
ordinary bivariate Gaussian q2 `sigma1`/`sigma2` scale-slope route, coordinate
spatial Gaussian `mu`, phylogenetic Gaussian
`mu`, animal-model Gaussian `mu`, `relmat()` Gaussian `mu`, ordinary
Poisson/NB2 `mu`, and selected ordinary Student-t/lognormal/Gamma/beta/
beta-binomial/zero-truncated NB2 `mu`. Broader all-four endpoint bivariate
random slopes and
most structured non-Gaussian dependence remain planned. The fitted structured
non-Gaussian routes are narrow ordinary Poisson/NB2 q=1 `mu` intercept slices
for `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, and `relmat()`,
plus unlabelled intercept-plus-one-slope slices for `phylo()`, `spatial()`,
`animal()`, and `relmat()`; they are source-test, native point-fit/extractor,
smoke, or diagnostic lanes, not broad count parity. Three non-count families also
fit an unlabelled structured `mu` one-slope as native point-fit/extractor
recovery-only lanes: Gamma `relmat(1 + x | id, K)`, Student
`spatial(1 + x | id, coords)`, and beta `animal(1 + x | id)`; labelled covariance,
multiple slopes, scale/shape/inflation structured slopes, and other non-count
families remain planned. Additional row-specific q1 intercept gates are fitted
at diagnostic-only grade for Poisson `zi ~ spatial()`, truncated-NB2
`hu ~ relmat(K/Q)`, cumulative-logit `mu ~ phylo()`, and Student-t `nu ~ phylo()`;
beta `sigma ~ animal()` retains recovery evidence. Those exact gates do not imply broader
family/parameter support or any interval/coverage promotion.
One exact crossed NB2 `mu ~ spatial(1 | site, coords = coords) +
relmat(1 | id, Q = Q)` route also has recovery-only evidence; both variance
components recover on the crossed design, but intervals and coverage remain
unsupported.

## Random-Slope Parity

| Random-effect layer | At least one fitted random slope? | Fitted route | Still planned or blocked |
| --- | --- | --- | --- |
| Ordinary Gaussian `mu` group effects | Yes | Independent numeric slopes such as `(0 + x | id)` and one correlated intercept-slope block such as `(1 + x | id)`; q > 2 ordinary `mu` blocks are fitted but advanced | Bivariate slope1-slope2 covariance and broader cross-parameter slope covariance |
| Ordinary Gaussian `sigma` group effects | Yes | Independent residual-scale slopes plus unlabelled correlated intercept-slope and multi-slope blocks on the log-`sigma` predictor | Labelled residual-scale blocks, cross-formula `mu`-`sigma` slope covariance, and broader all-endpoint slope covariance |
| Ordinary bivariate group covariance | Yes, first slices | Matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, same-response `mu`/`sigma`, constant q=4 intercept location-scale blocks, matching slope-only `mu1`/`mu2`, same-response `mu`/`sigma`, `sigma1`/`sigma2` blocks, matching q=4/q=6 `mu1`/`mu2` location blocks with smoke artifact routing, and the first ordinary q8 all-endpoint block with diagnostic smoke/recovery/staged-start routing are fitted | Predictor-dependent slope `corpair()` regressions, q8 coverage/power evidence, broader p8/q8 endpoint variants, and formal q > 2 simulation recovery |
| Coordinate spatial Gaussian effects | Yes | `spatial(1 | site, coords = coords)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `spatial(1 + x | site, coords = coords)` fits independent coordinate-spatial intercept and slope fields for univariate Gaussian `mu`, sigma-only residual scale, and matched `mu+sigma` location-scale cells with deterministic same-target fixtures | Multiple spatial slopes, spatial intercept-slope correlation, bivariate spatial slopes, mesh/SPDE, and broad bridge/inference beyond deterministic same-target fixtures |
| Phylogenetic Gaussian effects | Yes | `phylo(1 | species, tree = tree)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `phylo(1 + x | species, tree = tree)` fits independent phylogenetic intercept and slope fields for univariate Gaussian `mu`, sigma-only residual scale, and matched `mu+sigma` location-scale cells with deterministic same-target fixtures; matching bivariate `mu1`/`mu2`, selected q=4 location-scale, direct `sd_phylo*()`, and q=2 phylogenetic `corpair()` routes are also fitted | Multiple phylogenetic slopes, phylogenetic slope correlations, bivariate phylogenetic slopes, phylogenetic non-Gaussian effects, and broad bridge/inference beyond deterministic same-target fixtures |
| `animal()` Gaussian effects | Yes | `animal(1 | id, pedigree/A/Ainv = ...)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `animal(1 + x | id, A = A)` fits independent animal-model intercept and slope fields for univariate Gaussian `mu`, sigma-only residual scale, and matched `mu+sigma` location-scale cells with deterministic same-target fixtures; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Sparse large-pedigree construction, multiple animal slopes, animal slope correlations, predictor-dependent `corpair()`, direct-SD grammar, and broad bridge/inference beyond deterministic same-target fixtures |
| `relmat()` Gaussian effects | Yes | `relmat(1 | id, K/Q = ...)` fits univariate Gaussian `mu` and/or `sigma` intercepts; `relmat(1 + x | id, K/Q = ...)` fits independent relatedness intercept and slope fields for univariate Gaussian `mu`, sigma-only residual scale, and matched `mu+sigma` location-scale cells with K/Q target parity and deterministic same-target fixtures; matching bivariate q=2 location covariance and constant all-four q=4 location-scale blocks are fitted | Multiple `relmat()` slopes, relatedness slope correlations, predictor-dependent `corpair()`, direct-SD grammar, and broad bridge/inference beyond deterministic same-target fixtures |
| Selected non-Gaussian `mu` group effects | Yes, first slice | Eligible ordinary Student-t, skew-normal, lognormal, Gamma, Tweedie, beta, zero-one beta, beta-binomial, binomial, zero-truncated NB2, and cumulative-logit routes fit `mu` random intercepts and independent numeric slopes such as `(0 + x | id)`; unlabelled structured `mu` one-slope point-fit/extractor recovery cells additionally fit Gamma `relmat(1 + x | id, K)`, Student `spatial(1 + x | id, coords)`, and beta `animal(1 + x | id)` | Correlated slopes, labelled covariance blocks, non-Gaussian `sigma` or shape random effects beyond the exact gates, zero-one beta distributional random effects beyond ordinary `mu`, hurdle/inflation random effects beyond the exact row-specific gates, and structured dependence beyond the admitted non-count recovery cells (labelled covariance, multiple slopes, scale/shape/inflation structured slopes, and other families) |
| Ordinary Poisson `mu` group effects | Yes, first slice | Non-zero-inflated Poisson `mu` random intercepts and independent numeric slopes on the log-mean predictor; one q=1 structured log-mean intercept or unlabelled intercept-plus-one-slope term can use `phylo()`, `spatial()`, `animal()`, or `relmat()`; exact spatial-inflation gates fit diagnostic-only `zi ~ spatial()` and fixed-`zi` `mu ~ spatial()` intercepts | Correlated Poisson slopes, labelled covariance blocks, zero-inflated Poisson random effects beyond the exact spatial-`zi` and fixed-`zi` spatial-`mu` gates, pure or multiple structured count slopes, simultaneous structured types, and structured count covariance |
| Ordinary NB2 group effects | Yes, first slice | Non-zero-inflated NB2 `mu` random intercepts and independent numeric slopes; one q1 structured `mu` intercept or one-slope term can use `phylo()`, `spatial()`, `animal()`, or `relmat()`; exact q1 structured `sigma` routes are recovery-grade; one exact crossed spatial-plus-relatedness `mu` route is recovery-only; one fixed-`zi` `mu ~ spatial()` intercept is diagnostic-only | Correlated NB2 slopes, ordinary NB2 `sigma` slopes, joint `mu`/`sigma` random effects, zero-inflated NB2 random effects beyond the exact fixed-`zi` spatial-`mu` diagnostic gate, pure or multiple NB2 structured slopes, richer or labelled structured sigma, structured-sigma intervals/coverage, labelled covariance, and simultaneous structured types beyond the exact crossed gate |
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
slopes, the q2 scale-slope gap is opened for matching `sigma1`/`sigma2`, and
the first same-response q2 `mu`/`sigma` slope gap is opened with smoke/recovery
routing. The next slope gaps are q8 coverage/power evidence, multiple
structured slopes, structured slope correlations, and non-Gaussian structured
effects beyond the exact ordinary Poisson/NB2 q=1 count cells.

The #440 bivariate slope-only evidence gate is recorded in
`docs/design/145-phase6c-bivariate-slope-evidence-gate.md`. Its decision is
artifact-ready and held from recovery, coverage, and power claims: the matching
`mu1`/`mu2` slope-only route has extractor, profile-target, diagnostic,
Phase 18 helper, artifact-writer, manual Actions, and one small pilot-artifact
handle, but #446 remains responsible for the formal simulation plan.

## Structured Gaussian Audit Closure

The #442 audit closes the current-status question for the four Gaussian
structured one-slope routes. The fitted `mu` claim is deliberately narrow: one
numeric univariate Gaussian `mu` slope fits as independent structured intercept
and slope fields. First sigma-only residual-scale and matched `mu+sigma`
one-slope cells are tracked separately for phylo, fixed-covariance spatial,
A-matrix animal, and K/Q relmat. Neither lane is a slope-correlation model,
bridge fixture, interval/coverage claim, REML route, or random effect in
residual `rho12`.

| Route | One-slope status | q2/q4 covariance status | Evidence handles | Still outside |
| --- | --- | --- | --- | --- |
| `phylo()` | Fitted for the documented Gaussian slope/covariance routes plus exact non-Gaussian Poisson/NB2 q1 `mu` intercept-plus-one-slope, recovery-grade NB2 q1 `sigma`, Student-t q1 `nu`, and cumulative-logit q1 `mu` gates | Gaussian q2/q4 rows and each non-Gaussian gate retain their row-specific evidence tiers | `tests/testthat/test-phylo-gaussian.R`, family-specific structured tests, and the live ledger | Multiple or labelled phylogenetic slopes, slope correlations, structured `rho12`, non-Gaussian phylogenetic effects outside the exact gates, predictor-dependent q4 correlations, broad bridge support, and unpromoted intervals/coverage |
| `spatial()` | Fitted for one numeric univariate Gaussian `mu` slope, the first fixed-covariance sigma-only residual-scale one-slope cell, and the matched `mu+sigma` one-slope cell with independent coordinate-spatial endpoint members and deterministic same-target fixtures | q2 bivariate location covariance and constant q4 location-scale rows are fitted first slices; q4 is extractor/diagnostic smoke rather than formal coverage evidence | `tests/testthat/test-spatial-gaussian.R`, `tests/testthat/test-phase18-spatial-mu-slope.R`, `tests/testthat/test-phase18-random-slope-grid-writers.R`, `docs/design/46-pre-simulation-readiness-matrix.md` | Mesh/SPDE, multiple spatial slopes, spatial slope correlations, spatial direct-SD surfaces, spatial `corpair()` regression, non-Gaussian spatial slopes outside the exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope, recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial `zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates, broad bridge support beyond deterministic one-slope fixtures, intervals, and coverage |
| `animal()` | Fitted for documented Gaussian routes plus exact ordinary Poisson/NB2 q1 `mu` intercept-plus-one-slope, NB2 q1 `sigma`, and beta animal gates | Gaussian q2/q4 and each non-Gaussian gate retain row-specific evidence tiers | Gaussian and family-specific structured tests plus the live ledger | Sparse large-pedigree speed claims, multiple or labelled slopes, slope correlations, predictor-dependent `corpair()`, non-Gaussian animal neighbours outside exact gates, broad bridge support, and unpromoted intervals/coverage |
| `relmat()` | Fitted for documented Gaussian routes plus exact ordinary Poisson/NB2 q1 `mu` intercept-plus-one-slope, NB2 q1 `sigma`, Gamma `mu`, and truncated-NB2 `hu` relmat gates | Gaussian q2/q4 and each non-Gaussian gate retain row-specific evidence tiers | Gaussian and family-specific structured tests plus the live ledger | Multiple or labelled slopes, slope correlations, predictor-dependent `corpair()`, non-Gaussian relmat neighbours outside exact gates, broad bridge support, and unpromoted intervals/coverage |

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
| Selected ordinary non-Gaussian `mu` random effects | Yes, first slice | Student-t, zero-truncated NB2, lognormal, Gamma, beta, beta-binomial, binomial, and cumulative-logit fit ordinary unlabelled `mu` random intercepts and independent numeric slopes; row-specific q1 structured gates additionally fit Student-t `mu ~ spatial()`, Gamma `mu ~ relmat()`, beta `mu ~ animal()`, and cumulative-logit `mu ~ phylo()` | Correlated slopes, labelled covariance, unsupported shape random effects, and structured dependence beyond the exact gates |
| Ordinary Poisson mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts, independent numeric `mu` slopes, one q=1 structured log-mean intercept or unlabelled intercept-plus-one-slope term from `phylo()`, `spatial()`, `animal()`, or `relmat()`, plus diagnostic-only q1 `zi ~ spatial()` and fixed-`zi` `mu ~ spatial()` intercepts | `zi` or fixed-inflation random effects beyond the two exact spatial gates, correlated slopes, labelled covariance, pure or multiple structured count slopes, and simultaneous structured count types |
| Ordinary NB2 mixed models | Yes, first slice | Non-zero-inflated `mu` random intercepts/slopes, ordinary log-`sigma` random intercepts, single-provider q1 structured `mu` routes, recovery-grade q1 structured `sigma` routes, one recovery-only crossed spatial-plus-relatedness `mu` route, and one diagnostic-only fixed-`zi` `mu ~ spatial()` intercept | ordinary NB2 `sigma` slopes, structured-sigma intervals/coverage, zero-inflation random effects beyond the exact diagnostic spatial-`mu` gate, correlated slopes, pure or multiple structured count slopes, labelled covariance, and simultaneous structured count types beyond the exact crossed gate |
| Non-Gaussian `sigma`, shape, inflation, hurdle, zero-one, or one-inflation random effects | Narrow fitted gates | Fixed-effect formulas exist for selected families and parameters; ordinary NB2, lognormal, and Gamma have separate first log-`sigma` random-intercept gates; NB2 has exact recovery-grade q1 structured `sigma` intercept-plus-one-slope routes; beta has an exact q1 `sigma ~ animal()` intercept; Student-t has an exact q1 `nu ~ phylo()` intercept; Poisson has an exact q1 `zi ~ spatial()` intercept; truncated NB2 has one diagnostic-only q1 `hu ~ relmat(K/Q)` intercept | Other scale, shape, inflation, and hurdle random effects outside the named gates, combined positive-continuous `mu`+`sigma` random effects, and random effects in the remaining distributional parameters are blocked or planned |
| Ordinal mixed models | Narrow fitted gates | Ordinary cumulative-logit `mu` random intercepts and independent slopes plus one exact diagnostic-only q1 `mu ~ phylo()` intercept with local point-fit/extractor evidence | Other structured ordinal effects, ordinal scale/discrimination, bivariate ordinal models, and interval/coverage promotion for the exact phylogenetic gate |
| Structured non-Gaussian dependence | Narrow family- and parameter-specific gates | Ordinary Poisson/NB2 q1 structured `mu` routes, exact NB2 structured-`sigma` recovery routes, and one exact crossed NB2 spatial-plus-relatedness `mu` route are fitted. Row-specific q1 gates additionally fit diagnostic-only Poisson `zi ~ spatial()`, diagnostic-only fixed-`zi` Poisson `mu ~ spatial()`, diagnostic-only fixed-`zi` NB2 `mu ~ spatial()`, truncated-NB2 `hu ~ relmat(K/Q)`, cumulative-logit `mu ~ phylo()`, Student-t `nu ~ phylo()`, Student-t `mu ~ spatial()`, Gamma `mu ~ relmat()`, and beta `mu`/`sigma ~ animal()` at their live-ledger diagnostic or point/recovery tiers | Pure or multiple structured count slopes, labelled q2/q4 count blocks, richer or labelled NB2 structured `sigma`, structured-sigma intervals/coverage, simultaneous structured types beyond the exact crossed gate, unsupported family/provider/parameter combinations, and interval/coverage promotion for these row-specific gates remain planned |
| Mixed-response bivariate non-Gaussian models | No | All-Gaussian bivariate models are fitted | Gaussian-count, count-count, ordinal-mixed, and other mixed-response bivariate likelihoods remain planned |

For applied users, the current route is therefore:

- use Gaussian structural dependence when the response model is Gaussian and
  the fitted structured layer matches the question;
- use ordinary Poisson or NB2 `mu` random effects for count mixed models when
  a plain grouping factor is enough;
- use ordinary NB2 `sigma ~ z + (1 | id)` only when the question is grouped
  overdispersion heterogeneity with no simultaneous `mu` random effects;
- use ordinary Poisson or NB2 `phylo(1 + x | species, tree = tree)`,
  `spatial(1 + x | site, coords = coords)`, `animal(1 + x | id, ...)`, or
  `relmat(1 + x | id, ...)` only when the count question is one q=1 structured
  log-mean intercept or unlabelled intercept-plus-one-slope cell and, for NB2,
  fixed `sigma` overdispersion is enough;
- use only the exact diagnostic-only Poisson `zi ~ spatial()` and truncated-NB2
  `hu ~ relmat(K/Q)` intercept gates for inflation/hurdle questions;
- do not fit zero-inflated or hurdle structured routes beyond those gates,
  pure or multiple structured count slopes, labelled count covariance,
  simultaneous structured count types beyond the exact crossed NB2
  spatial-plus-relatedness `mu` gate, or NB2 structured-`sigma` routes beyond
  the exact recovery-grade q1 intercept-plus-one-slope cells.

That boundary is conservative, but useful. Non-Gaussian links, latent
structured matrices, zero inflation, and distributional scale or shape
parameters can all change identifiability. The package should advertise only
the exact non-Gaussian structured routes and evidence tiers listed above. Any
broader family/provider/parameter combination still needs the same evidence
standard as the Gaussian routes: likelihood code, focused recovery tests,
extractors, diagnostics, interval-status rows, examples, check-log evidence,
and an after-task report.
