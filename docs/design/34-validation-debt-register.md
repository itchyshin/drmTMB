# Phase 6d Validation-Debt Register

This register is the evidence ledger for the stable-core matrix in the README
and model-map article. It does not make new model claims. It records what backs
each advertised surface and what remains debt before a neighbouring feature can
be taught as routine.

For Phase 18 simulation admission, read this register together with the Slice
291 evidence-ledger gate in
`docs/design/46-pre-simulation-readiness-matrix.md`. A simulation DGP row should
not enter the admitted grid unless its public surface, implementation evidence,
tests, diagnostics or interval route, user-facing boundary, and simulation
status can all be traced back to these two ledgers.

Use these status labels:

- `covered`: the row has implementation, focused tests, user-facing docs, and
  at least one diagnostic or interval route where the surface needs one.
- `partial`: the row fits inside a narrow boundary, but the boundary is still
  scientifically important and must be visible to users.
- `opt-in`: the row is a hardening or scalability control, not a general
  modelling guarantee.
- `blocked`: the row is reserved, rejected, or design-only until likelihood
  code, tests, diagnostics, docs, and after-task evidence exist.

Map rows should record the same evidence dimensions used by the pkgdown maps:
family or component, dependence layer, formula route, q or endpoint class,
random-intercept support, random-slope support, cross-parameter or bivariate
combination, extractor route, simulation status, interval status, and the
nearest fitted user route. "Fitted" and "simulation-ready" are not synonyms.
A fitted first slice can remain smoke/artifact-only until recovery, interval,
and operating-characteristic evidence justify a broader claim.

## Register rows

| Surface ID | Matrix row | Register status | Validation risk | Next gate |
| --- | --- | --- | --- | --- |
| `fixed_one_response` | Fixed-effect one-response families | covered | low for listed fixed-effect paths; moderate for family expansion | Add one family at a time with likelihood tests, methods tests, docs, and family-specific diagnostics. |
| `supported_nongaussian_evidence_goal` | Supported non-Gaussian distribution evidence | partial/covered by row | moderate if readers infer broad parity | `docs/design/79-supported-nongaussian-evidence-goal.md` closes the goal-level audit for supported fixed-effect families and first count mixed-model lanes while keeping blocked neighbours out. |
| `gaussian_ordinary_re` | Gaussian ordinary random effects | covered | low for listed Gaussian ordinary paths; moderate for labelled or cross-formula `sigma` slope covariance | Unlabelled ordinary `sigma` intercept-slope and multi-slope correlations are fitted; keep labelled or cross-formula slope covariance and coefficient-specific SD slopes blocked until direct tests and diagnostics exist. |
| `re_scale_sd_group` | Random-effect scale models | partial | moderate | Add coefficient-specific random-slope scale likelihood, recovery tests, and diagnostics before widening `sd()` syntax. |
| `known_sampling_covariance` | Known sampling covariance | covered/partial | moderate for dense scalability | Keep dense full `V` labelled small-to-moderate until sparse/block-sparse storage has implementation, diagnostics, and benchmark evidence. |
| `biv_residual_rho12` | Bivariate Gaussian residual `rho12` | covered | low for residual `rho12`; high if confused with latent covariance | Keep residual `rho12` separate from group, phylogenetic, and spatial correlations. |
| `ordinary_biv_corpairs` | Ordinary bivariate covariance and `corpairs()` | partial | moderate | Matching slope-only `mu1`/`mu2`, matching q2 same-response `mu`/`sigma` slope, matching q2 `sigma1`/`sigma2` scale-slope, q=4/q=6 `mu1`/`mu2` location covariance, and the first q8 all-endpoint ordinary Gaussian block are fitted, with smoke artifact routing for q4/q6 location blocks and diagnostic smoke/recovery/staged-start routing for q8. The same-response q2 500-replicate audit and robust-refit follow-up are diagnostic, not power evidence: 130 weak fits were not rescued, while two clean fits showed endpoint-profile feasibility. The 2026-06-07 q8 two-cell audit is also diagnostic hold evidence: 38/40 manifests completed, convergence rates were 0.263 and 0.158, positive-Hessian rates were 0, two fits errored with non-positive leading minors, and no Wald intervals were usable. Keep q8 coverage, q8 power, and predictor-dependent slope-correlation routes blocked until deliberately sized evidence and interval policy are explicit. |
| `phylo_structured_effects` | Phylogenetic structured effects | partial | moderate | The documented Gaussian routes are fitted. Exact non-Gaussian gates include ordinary Poisson/NB2 q1 phylogenetic `mu` intercept-plus-one-slope, recovery-grade NB2 q1 phylogenetic `sigma`, Student-t q1 phylogenetic `nu`, and cumulative-logit q1 phylogenetic `mu`; keep multiple or labelled covariance, broad bridge/inference, structured `rho12`, and non-Gaussian phylogenetic effects outside those gates in debt. The q4 scale-side endpoints are **weakly identified at about one observation per tip**, not non-identified: report the mean-side model with fixed-effect `sigma ~ predictors` as the supported one-record-per-species analysis, and gate any scale-side phylogenetic estimate behind within-species replication or the planned `estimator = "penalized"` prior path (see `docs/dev-log/known-limitations.md` and de Villemereuil & Nakagawa 2014; Nakagawa et al. 2025). |
| `poisson_phylo_q1_mu` | Ordinary Poisson q=1 phylogenetic `mu` intercept and one-slope terms | partial | moderate to high until recovery grids exist | The first phylogenetic count route is fitted for `phylo(1 | species, tree = tree)` and the unlabelled `phylo(1 + x | species, tree = tree)` one-slope term in ordinary Poisson `mu`; the opt-in smoke runner, repeatable CSV artifact writer, optional direct `log_sd_phylo` profile-interval artifacts, formal-grid spec, read-back QA, promotion decision, and manual Actions task now exist for the intercept route, but formal recovery grids remain the next evidence gate. The same source path also admits q=1 `spatial()`, `animal()`, and `relmat()` count `mu` intercept and unlabelled one-slope terms. Separately, one exact Poisson q1 `zi ~ spatial()` intercept is diagnostic-only. Keep pure, multiple, or labelled count structured slopes, simultaneous structured types, zero-inflation beyond that exact gate, and cross-parameter covariance blocked until separate evidence lands. |
| `nbinom2_phylo_q1_mu` | Ordinary NB2 q=1 structured `mu` intercept and one-slope terms | partial | high after the 500-replicate phylogenetic shard audit | Ordinary NB2 fits q1 `phylo()`, `spatial()`, `animal()`, or `relmat()` intercept and one-slope routes in `mu`; the phylogenetic formal audit remains held because profile intervals fail frequently at the true-zero boundary and low-count cells retain fixed-`sigma` instability. Separate recovery-grade q1 NB2 structured `sigma` routes fit for all four providers. One exact crossed `mu ~ spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` route also has recovery-only evidence with both variance components recovered on the crossed design. Keep pure, multiple, or labelled NB2 structured slopes, structured-`sigma` intervals/coverage, zero-inflated structure, simultaneous structured types beyond that exact two-provider gate, and labelled count covariance blocked. |
| `spatial_mu_coord` | Coordinate spatial univariate Gaussian `mu`/`sigma` plus narrow non-Gaussian gates | partial | moderate | Gaussian location and residual-scale intercepts plus one numeric `mu` slope, the first fixed-covariance sigma-only residual-scale one-slope cell, and the matched fixed-covariance `mu+sigma` one-slope native point-fit/extractor cell are fitted; ordinary Poisson/NB2 q1 spatial `mu` routes, one exact Student-t q1 spatial `mu` route, and three exact diagnostic-only spatial-inflation routes—Poisson `zi`, fixed-`zi` Poisson `mu`, and fixed-`zi` NB2 `mu`—are also fitted at their recorded tiers. Keep mesh/SPDE, multiple slopes, labelled structured slope covariance, direct-SD surfaces, unsupported count slopes, and zero-inflated spatial effects outside the exact Poisson `zi`, fixed-`zi` Poisson `mu`, and fixed-`zi` NB2 `mu` gates in debt. |
| `spatial_biv_q2` | Coordinate spatial bivariate q=2 `mu1`/`mu2` covariance | partial | moderate | q=2 location covariance is fitted and admitted for focused artifacts; keep spatial `corpair()` regression and broader bivariate spatial slopes blocked. |
| `spatial_q4` | Coordinate spatial all-four q=4 location-scale covariance | partial | high if treated as formal coverage evidence | Constant all-four q=4 is fitted with extractor/diagnostic smoke and derived-unavailable correlation intervals; add q=4 recovery, convergence/Hessian evidence, and DGP artifacts before operating-characteristic claims. |
| `animal_mu_relatedness` | Animal-model Gaussian `mu`/`sigma` intercept and one-slope `mu` effects plus exact non-Gaussian gates | partial | moderate to high for sparse large pedigrees | Dense pedigree and known `A`/`Ainv` Gaussian first slices are fitted. Exact non-Gaussian gates include ordinary Poisson/NB2 q1 animal `mu` intercept-plus-one-slope routes, recovery-grade NB2 q1 animal `sigma`, and the row-specific beta animal route recorded in the live ledger. Keep sparse large-pedigree construction, multiple or labelled covariance, broad bridge/inference, direct-SD grammar, and non-Gaussian animal effects outside those exact gates in debt. |
| `animal_biv_q2_q4` | Animal-model bivariate q=2 and q=4 covariance | partial | high if q=4 point estimates are read as coverage evidence | q=2 and constant q=4 are fitted for small/dense routes with smoke artifacts; q=2 has fixed-effect Wald and opt-in profile status, while q=4 correlations remain derived-unavailable. |
| `relmat_mu_relatedness` | `relmat()` Gaussian `mu`/`sigma` intercept and one-slope `mu` effects plus exact non-Gaussian gates | partial | moderate for matrix conditioning | Known `K`/`Q` Gaussian first slices are fitted. Exact non-Gaussian gates include ordinary Poisson/NB2 q1 relmat `mu` intercept-plus-one-slope routes, recovery-grade NB2 q1 relmat `sigma`, Gamma q1 relmat `mu`, and truncated-NB2 q1 relmat `hu`. Keep multiple or labelled covariance, broad bridge/inference, direct-SD grammar, and non-Gaussian `relmat()` effects outside those exact gates in debt. |
| `relmat_biv_q2_q4` | `relmat()` bivariate q=2 and q=4 covariance | partial | high if q=4 point estimates are read as coverage evidence | q=2 and constant q=4 are fitted for known matrices with smoke artifacts; q=2 has fixed-effect Wald and opt-in profile status, while q=4 correlations remain derived-unavailable. |
| `profile_diagnostics` | Profile intervals and diagnostics | partial | moderate | Complete Slice 79 uncertainty-state handling and a nonlinear interval method for derived summaries. |
| `large_data_controls` | Large-data fit controls | opt-in | moderate to high for extrapolated claims | Add non-CRAN benchmarks and compatibility tests before claiming broad scalability. |
| `reserved_planned_neighbours` | Reserved or planned neighbours | blocked | high if advertised as runnable syntax | Keep errors and docs synchronized until implementation, tests, diagnostics, NEWS, and after-task evidence exist. |

### Fixed-effect one-response families

- Matrix status: stable.
- Register status: covered, with family-specific extension debt.
- Evidence: `tests/testthat/test-gaussian-location-scale.R`,
  `tests/testthat/test-student-location-scale.R`,
  `tests/testthat/test-lognormal-location-scale.R`,
  `tests/testthat/test-gamma-location-scale.R`,
  `tests/testthat/test-beta-location-scale.R`,
  `tests/testthat/test-beta-binomial.R`,
  `tests/testthat/test-poisson-mean.R`,
  `tests/testthat/test-nbinom2-location-scale.R`,
  `tests/testthat/test-count-kernels.R`,
  `tests/testthat/test-zi-poisson.R`,
  `tests/testthat/test-zi-nbinom2.R`,
  `tests/testthat/test-truncated-nbinom2-location-scale.R`,
  `tests/testthat/test-hurdle-nbinom2.R`, and
  `tests/testthat/test-cumulative-logit.R`.
- Diagnostics and intervals: Wald fixed-effect intervals are the default;
  direct fixed-effect profile targets appear through `profile_targets()` where
  the fitted object retains the TMB object.
- User-facing docs: `vignettes/distribution-families.Rmd`,
  `vignettes/formula-grammar.Rmd`, and `docs/design/03-likelihoods.md`.
- Check-log evidence: family-specific check-log entries are summarized in
  `vignettes/source-map.Rmd`; Slice 78 keeps them grouped because this row is
  a family collection rather than one likelihood.
- Debt: richer bounded-response families, ordinal scale/discrimination, and
  non-Gaussian random effects outside the ordinary `mu` recovery gates and
  exact row-specific gates still need separate likelihood or simulation work.

### Poisson ordinary random effects

- Matrix status: first non-Gaussian path implemented for non-zero-inflated
  Poisson `mu`.
- Register status: ordinary unlabelled `(1 | group)` random intercepts and
  independent numeric `(0 + x | group)` slopes enter the log-mean predictor.
  Correlated slope blocks, labelled covariance blocks, and cross-parameter
  covariance remain planned. Separately, one exact recovery-grade q1
  `zi ~ spatial(1 | id, coords = coords)` intercept is fitted; other
  zero-inflated Poisson random effects remain planned.
- Evidence: `tests/testthat/test-poisson-mean.R`,
  `tests/testthat/test-phase18-poisson-mu-random-effect.R`, and
  `tests/testthat/test-comparators.R`.
- Diagnostics and intervals: `sdpars$mu`, `random_effects$mu`, and
  `profile_targets()` expose the random-effect SDs through direct
  `log_sd_mu` profile targets.
- Debt: larger grids, correlated non-Gaussian `mu` slopes, labelled
  covariance blocks, zero-inflated Poisson random effects beyond the exact
  q1 spatial-`zi` intercept, and
  cross-parameter covariance need later slice evidence before Phase 18 treats
  them as routine.

### Poisson phylogenetic q=1 `mu` intercept

- Matrix status: first structured non-Gaussian dependence slice.
- Register status: ordinary non-zero-inflated Poisson can add
  `phylo(1 | species, tree = tree)` to the `mu` formula. The term enters the
  log-mean predictor as a q=1 phylogenetic species effect. It cannot yet be
  combined with ordinary Poisson random effects, `zi`, labels, structured
  slopes, or simultaneous structured layers within Poisson. Separate q=1 spatial, animal, and
  `relmat()` count routes are now tracked as source/diagnostic first slices
  rather than as phylogenetic evidence.
- Evidence: `tests/testthat/test-poisson-mean.R`,
  `tests/testthat/test-nongaussian-structured-boundary.R`,
  `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`, and
  `vignettes/source-map.Rmd`.
- Diagnostics and intervals: `sdpars$mu` exposes the phylogenetic SD,
  `ranef("phylo_mu")` exposes conditional species effects,
  `profile_targets()` exposes the direct `log_sd_phylo` target, and
  `check_drm()` reports the same phylogenetic diagnostics used for q=1
  structured `mu` effects. No count `corpairs()` row exists because q=1 has no
  correlation parameter.
- User-facing docs: `README.md`, `NEWS.md`, `R/formula-markers.R`,
  `vignettes/model-map.Rmd`, `vignettes/implementation-map.Rmd`,
  `vignettes/source-map.Rmd`, `vignettes/formula-grammar.Rmd`, and
  `docs/design/67-sdstar-p8-poisson-q1.md`.
- Debt: formal recovery grids, zero-inflated structured boundaries, labels,
  simultaneous structured count types beyond the exact crossed NB2
  spatial-plus-relatedness `mu` gate, and pure, multiple, or labelled
  structured count slopes need separate implementation and evidence before the
  map can claim broad non-Gaussian structural parity.

### NB2 ordinary random effects

- Matrix status: first non-Gaussian overdispersed-count paths implemented for
  non-zero-inflated NB2 `mu` and the first ordinary NB2 log-`sigma` random
  intercept.
- Register status: ordinary unlabelled `(1 | group)` random intercepts and
  independent numeric `(0 + x | group)` slopes enter the log-mean predictor.
  Ordinary `sigma ~ z + (1 | group)` random intercepts enter the
  log-overdispersion predictor when there are no `mu` random effects in the
  same fit. Exact q1 structured `sigma` intercept-plus-one-slope routes for
  `phylo()`, `spatial()`, `animal()`, and `relmat()` are fitted at recovery
  grade. Correlated ordinary slope blocks, labelled covariance blocks, joint
  `mu`/`sigma` random effects, zero-inflated NB2 random effects, ordinary NB2
  `sigma` slopes, richer structured sigma blocks, and structured-sigma
  intervals/coverage remain planned.
- Evidence: `tests/testthat/test-nbinom2-location-scale.R`,
  `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`,
  `tests/testthat/test-phase18-nbinom2-sigma-random-effect.R`, and
  `tests/testthat/test-phase18-nbinom2-phylo-q1.R`.
- Diagnostics and intervals: `sdpars$mu`, `random_effects$mu`, and
  `profile_targets()` expose the fitted `mu` random-effect SDs through direct
  `log_sd_mu` profile targets. `sdpars$sigma`, `random_effects$sigma`,
  `sigma()`, `predict(dpar = "sigma")`, `profile_targets()`, and
  `check_drm()` expose the fitted ordinary `sigma` random-intercept gate
  through a direct `log_sd_sigma` target and replication diagnostics. The Phase
  18 smoke surface records fixed-effect Wald rows for `mu` and `sigma`
  coefficients and direct profile rows for the `mu` random-effect SDs.
- Debt: zero-inflated NB2 random effects, ordinary NB2 `sigma` slopes, joint
  `mu`/`sigma` random effects, correlated or labelled NB2 slope blocks,
  richer or labelled structured NB2 scale effects, structured-`sigma`
  intervals/coverage, and cross-parameter non-Gaussian covariance
  need separate likelihood, extractor, interval, diagnostic, and recovery
  evidence before comprehensive simulation.

### Inflation, hurdle, and one-inflation random effects

- Matrix status: two narrow fitted gates; all neighbours fail closed.
- Register status: fixed-effect `zi` formulas are implemented for Poisson and
  NB2, and fixed-effect `hu` formulas are implemented for hurdle NB2.
  One exact diagnostic-only q1 Poisson `zi ~ spatial()` intercept and one exact
  diagnostic-only q1 truncated-NB2 `hu ~ relmat(K/Q)` intercept are fitted.
  Other random-effect bar terms in `zi` or `hu`, count-side random-effect bar
  terms in zero-inflated or hurdle routes, and bounded-response `zoi`/`coi`
  random effects are rejected before optimization.
- Evidence: `tests/testthat/test-zi-poisson.R`,
  `tests/testthat/test-zi-nbinom2.R`,
  `tests/testthat/test-hurdle-nbinom2.R`,
  `tests/testthat/test-beta-location-scale.R`, and
  `tests/testthat/test-beta-binomial.R`; Slice 271 confirms both
  random-intercept and random-slope bar requests stay blocked for the relevant
  count, hurdle, and planned bounded-response parameters. Slice 285 adds
  fixed-effect Wald interval row checks for fitted beta and beta-binomial
  `mu` and `sigma` coefficients, before the zero-one beta likelihood opened.
  Slice D3 records fixed-effect zero-one beta as the bounded-response design
  gate, `tests/testthat/test-zero-one-beta.R` records the first runnable
  source-level `zoi`/`coi` evidence, and Slices 1339-1348 add the fixed-effect
  artifact lane before broad grid claims.
- Diagnostics and intervals: the two exact gates have local
  point-fit/extractor evidence only. Neither has interval, coverage,
  `inference_ready`, or `supported` promotion.
- Debt: fixed-effect zero-one beta now has a smoke-scale artifact lane. Any
  future covariance among `mu`, `sigma`,
  shape, `zi`, `hu`, `zoi`, or `coi` random effects should use constant block
  correlations first and needs extractor, `corpairs()`, profile-target, weak-SD,
  boundary, and simulation-recovery evidence before Phase 18.

### Non-Gaussian scale random effects

- Matrix status: narrow ordinary and structured gates; all neighbours fail
  closed.
- Register status: ordinary NB2, lognormal, and Gamma each admit an independent
  grouped log-`sigma` random intercept; lognormal/Gamma cannot combine that
  gate with their `mu` random effects. NB2 additionally has exact
  recovery-grade q1 structured `sigma` intercept-plus-one-slope routes for
  `phylo()`, `spatial()`, `animal()`, and `relmat()`. Beta has one exact q1
  `sigma ~ animal()` intercept at point/recovery grade. Other scale
  random-effect terms error before optimization.
- Evidence: `tests/testthat/test-nongaussian-scale-boundary.R` plus the
  neighbouring family malformed-input tests.
- Diagnostics and intervals: the ordinary NB2/lognormal/Gamma gates expose
  fitted extractor and direct log-SD target surfaces; only the exact lognormal
  ledger domain is `inference_ready_with_caveats`. The structured NB2 and beta
  gates remain point/recovery-only, without interval/coverage promotion.
- Debt: family-specific likelihood code, `sdpars` and `random_effects`
  extractors, `profile_targets()` rows, weak-SD recovery tests, scale-specific
  interpretation docs, and CI evidence are required before any additional
  non-Gaussian `sigma` random effect is advertised.

### Ordinal mixed models

- Matrix status: one narrow fitted gate; all neighbours fail closed.
- Register status: ordinary cumulative-logit `mu` random intercepts and
  independent slopes are fitted at recovery grade. In addition, the exact
  unlabelled q=1 `mu ~ phylo(1 | id, tree = tree)` intercept route is fitted
  with local point-fit/extractor evidence only. Other structured ordinal
  effects, labelled terms, and scale/discrimination formulas are rejected
  before optimization.
- Evidence: `tests/testthat/test-cumulative-logit.R` checks fixed-effect
  ordinal likelihood behavior and the ordinal random-effect boundary.
  `tests/testthat/test-phase18-ordinal-fixed-effect.R` checks the Phase 18
  fixed-effect ordinal DGP, smoke/grid artifacts, Wald rows, malformed helper
  inputs, and cutpoint-ordering summaries.
- Diagnostics and intervals: the ordinary random-effect routes have recovery
  diagnostics, but no interval/coverage promotion. The exact phylogenetic gate
  is point-fit/extractor only (`control = drm_control(se = FALSE)`); it has no
  interval, coverage, `inference_ready`, or `supported` claim. Existing
  cutpoint profile targets do not change that boundary.
- Debt: add deliberately sized interval/coverage evidence and an
  `ordinal::clmm` comparator before promoting ordinary ordinal random effects.
  Add provider-specific recovery before opening any structured route beyond
  the exact q=1 phylogenetic intercept. Ordinal scale/discrimination, known
  covariance, spatial/animal/relatedness effects, and bivariate ordinal models
  remain later phases.

### Structured non-Gaussian random effects

- Matrix status: narrow family- and parameter-specific gates; all neighbours
  fail closed.
- Register status: ordinary Poisson/NB2 `mu` q=1 intercept-plus-one-slope
  routes are fitted for `phylo()`, `spatial()`, `animal()`, and `relmat()`;
  NB2 also has exact recovery-grade q=1 structured `sigma`
  intercept-plus-one-slope routes for those providers. One exact crossed NB2
  `mu ~ spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` route is
  recovery-only, with both variance components recovered on the crossed design
  and no interval or coverage promotion. Row-specific q=1
  intercept gates additionally exist for Poisson `zi ~ spatial()`, truncated
  NB2 `hu ~ relmat(K/Q)`, cumulative-logit `mu ~ phylo()`, Student-t
  `nu ~ phylo()`, Student-t `mu ~ spatial()`, Gamma `mu ~ relmat()`, and beta
  `mu`/`sigma ~ animal()`. These gates do not imply general non-Gaussian
  structured support.
- Evidence: `tests/testthat/test-nongaussian-structured-boundary.R` checks
  count, bounded, positive-continuous, ordinal, phylogenetic, spatial, animal,
  and `relmat()` marker boundaries.
- Diagnostics and intervals: fitted rows have route-specific point-fit or
  recovery evidence only unless their ledger row says otherwise. The exact
  Poisson-`zi`, hurdle-`hu`, ordinal-phylo, Student-t, Gamma, and beta gates do
  not carry interval or coverage promotion.
- Debt: add route-specific interval/coverage evidence before promotion; keep
  pure, multiple, or labelled structured slopes, simultaneous structured
  types beyond the exact crossed NB2 gate, and broader family/parameter combinations out until separately
  implemented and validated.

### Shape random effects and ID-level skewness

- Matrix status: one narrow structured gate; all neighbours fail closed.
- Register status: Student-t `nu` is ordinarily a fixed-effect tail-shape
  formula, with one exact q=1 `nu ~ phylo(1 | id, tree = tree)` intercept route
  fitted at local point-fit/recovery grade. Other `nu` random effects remain
  blocked. Skew-normal fixed effects are fitted; skew-normal random,
  structured, and bivariate routes plus the skew-t family remain planned.
- Evidence: `tests/testthat/test-student-location-scale.R` checks that
  `nu ~ x + (1 | id)` and `nu ~ x + (0 + x | id)` fail with a shape-specific
  boundary.
- Diagnostics and intervals: the exact Student-t phylogenetic `nu` gate is
  point-fit/recovery only, without interval, coverage, `inference_ready`, or
  `supported` evidence.
- Debt: formal high-replicate skew-normal operating-characteristic grids,
  external comparators on the public moment scale, skew-t recovery and normal
  or Student-t limit checks, separation of `sigma ~ x` from `nu ~ x` in larger
  designs, then simulation evidence before adding `nu`/`tau` random effects or
  latent ID-level skewness such as future `skew(id) ~ x`.

### Gaussian ordinary random effects

- Matrix status: stable.
- Register status: covered for Gaussian `mu` random intercepts, independent
  slopes, one-slope correlated blocks, `sigma` intercepts, independent
  `sigma` slopes, and unlabelled correlated `sigma` intercept-slope or
  multi-slope blocks.
- Evidence: `tests/testthat/test-gaussian-random-intercepts.R`,
  `tests/testthat/test-comparators.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-check-drm.R`.
- Diagnostics and intervals: `check_drm()` reports replication, weak-slope,
  boundary, and Hessian diagnostics; direct SD and fitted correlation targets
  are profile-ready when the TMB object is retained.
- User-facing docs: `docs/design/04-random-effects.md`,
  `docs/design/17-correlated-random-effect-blocks.md`,
  `vignettes/location-scale.Rmd`, and `vignettes/formula-grammar.Rmd`.
- Check-log evidence: `docs/dev-log/check-log.md` entries "Phase 6c-core
  random-effect foundation" and "Phase 6c-core closure gate before Phases 10+";
  `docs/dev-log/after-phase/2026-05-15-phase-6c-core-random-effect-closure.md`.
- Debt: labelled residual-scale slope blocks, cross-formula slope covariance,
  and coefficient-specific random-slope `sd()` surfaces remain blocked.

### Random-effect scale models

- Matrix status: first coordinate slices, including constant q=2 bivariate
  location covariance.
- Register status: partial.
- Evidence: `tests/testthat/test-gaussian-random-effect-scale.R` and
  `tests/testthat/test-comparators.R`.
- Diagnostics and intervals: fixed coefficients for `sd(group) ~ predictors`
  are direct coefficient targets; row-specific group SD summaries are derived.
- User-facing docs: `docs/design/18-random-effect-scale-models.md`,
  `docs/design/13-gaussian-location-scale-math.md`,
  `vignettes/location-scale.Rmd`, and `vignettes/which-scale.Rmd`.
- Check-log evidence: `docs/dev-log/check-log.md` records the random-effect
  scale formula implementation and later Phase 6c core closure.
- Debt: slope-specific forms such as
  `sd(id, dpar = "mu", coef = "x") ~ ...` are deliberately reserved and
  rejected until coefficient-specific likelihood, diagnostics, and recovery
  tests exist.

### Known sampling covariance

- Matrix status: stable.
- Register status: covered for diagonal, dense, and row-paired bivariate
  Gaussian known covariance; partial for scalability and combinations.
- Evidence: `tests/testthat/test-meta-known-v.R`,
  `tests/testthat/test-meta-vcov.R`, `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-comparators.R`, and
  `tests/testthat/test-check-drm.R`.
- Diagnostics and intervals: `check_drm()` reports known-covariance summaries.
  Dense matrix `V` is reported as a note with dimension, storage, density,
  size, rank, and conditioning so users see the small-to-moderate storage
  boundary. Fixed effects and response-scale residual summaries use the usual
  interval routes.
- User-facing docs: `vignettes/meta-analysis.Rmd`,
  `vignettes/testing-likelihoods.Rmd`, `docs/design/08-meta-analysis.md`, and
  `docs/design/22-likelihood-weights.md`.
- Check-log evidence: `docs/dev-log/check-log.md` records diagonal, dense,
  random-effect-scale, and bivariate known-covariance validation; source
  evidence is summarized in `vignettes/source-map.Rmd`.
- Debt: sparse known covariance, block-sparse known covariance, broad
  large-data claims, and dense full known covariance with non-unit likelihood
  weights remain blocked. Slice 81 added dense-storage diagnostics and wording
  guardrails, but did not implement sparse or block-sparse `V`.

### Bivariate Gaussian residual `rho12`

- Matrix status: stable.
- Register status: covered for fixed-effect `rho12` and row-specific residual
  correlation intervals.
- Evidence: `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-summary.R`.
- Diagnostics and intervals: `rho12()` extracts response-scale residual
  correlations; `confint(..., parm = "rho12", newdata = ...)` profiles supplied
  rows; `check_drm()` reports near-boundary residual correlation diagnostics.
- User-facing docs: `vignettes/bivariate-coscale.Rmd`,
  `docs/design/15-location-coscale-phylogenetic-extension.md`,
  `docs/design/20-coscale-correlation-pairs.md`, and
  `vignettes/model-workflow.Rmd`.
- Check-log evidence: `docs/dev-log/check-log.md` records the bivariate
  location-coscale closure and the later row-specific profile-CI slices.
- Debt: random effects in `rho12`, mixed composed families, and any attempt to
  use residual `rho12` as a group-level, phylogenetic, or spatial correlation
  remain blocked.

### Ordinary bivariate covariance and `corpairs()`

- Matrix status: first slice locally closed.
- Register status: partial.
- Evidence: `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-corpairs.R`,
  `tests/testthat/test-covariance-block-registry.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-summary.R`.
- Phase gate: the ordinary bivariate random-intercept and `corpairs()`
  foundation is recorded in
  `docs/dev-log/after-phase/2026-05-15-phase-11-bivariate-corpairs-foundation-closure.md`.
- Diagnostics and intervals: constant q=2 SD/correlation targets are direct;
  predictor-dependent q=2 `corpair()` values use `newdata`; q=4 rows are
  derived summaries and should report unavailable derived intervals.
- User-facing docs: `vignettes/bivariate-coscale.Rmd`,
  `docs/design/20-coscale-correlation-pairs.md`,
  `docs/design/28-double-hierarchical-endpoint.md`, and
  `docs/design/30-labelled-covariance-block-assembler.md`.
- Check-log evidence: `docs/dev-log/check-log.md` records the labelled
  covariance block assembler, q=4 scaffold, `corpairs()` output, and profile
  target namespace slices.
- Debt: full all-endpoint slope covariance and predictor-dependent slope
  correlations remain blocked. The matching slope-only `mu1`/`mu2`, matching
  same-response `mu`/`sigma`, matching slope-only `sigma1`/`sigma2`, and q4/q6
  `mu1`/`mu2` location covariance routes are fitted, and q4/q6 location now have
  smoke artifact routing. The same-response q2 `mu`/`sigma` formal audit and
  hardening pass are diagnostic because 130 weak fits stayed false-converged
  under robust refits. Coefficient-aware `corpair()` regression, p8/q8 endpoint
  covariance, and formal q > 2 simulation recovery still need likelihood or
  recovery-grid evidence.

### Phylogenetic structured effects

- Matrix status: first slices locally closed.
- Register status: partial.
- Evidence: `tests/testthat/test-phylo-gaussian.R`,
  `tests/testthat/test-phylo-utils.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-check-drm.R`.
- Phase gate: the phylogenetic correlation foundation is recorded in
  `docs/dev-log/after-phase/2026-05-15-phase-12-phylogenetic-correlation-foundation-closure.md`.
- Diagnostics and intervals: direct phylogenetic SD and constant q=2
  correlation targets are profile-ready; predictor-dependent q=2 `corpair()`
  values use `newdata`; full q=4 phylogenetic correlations are derived-only
  for intervals; block-diagonal q=4 fallback correlations are direct targets
  that still need fit-specific profile diagnostics; `check_drm()` reports
  phylogenetic covariance diagnostics.
- User-facing docs: `vignettes/phylogenetic-spatial.Rmd`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/design/20-coscale-correlation-pairs.md`.
- Check-log evidence: `docs/dev-log/check-log.md` records the phylogenetic
  direct-SD, bivariate phylogenetic covariance, q=4 phylogenetic, and
  predictor-dependent q=2 phylogenetic `corpair()` slices.
- Debt: multiple phylogenetic slopes, phylogenetic slope correlations,
  standalone or partial phylogenetic scale terms, structured `rho12`,
  predictor-dependent q=4 correlations, and longer optional simulations remain
  planned.

### Coordinate spatial structured effects

- Matrix status: first slice.
- Register status: partial.
- Evidence: `tests/testthat/test-spatial-gaussian.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-check-drm.R`.
- Diagnostics and intervals: `sdpars$mu`, `ranef("spatial_mu")`,
  `profile_targets()`, `corpairs(level = "spatial")`, `summary()$covariance`,
  and `check_drm()` expose the coordinate-spatial fields, direct spatial SD
  targets, the q=2 spatial mean-mean row, and the six q=4 spatial endpoint
  rows. q=4 spatial correlations are derived summaries with
  `derived_interval_unavailable` status, not direct profile-proven targets.
- Simulation tier: univariate coordinate-spatial `mu` intercept and one-slope
  routes, plus q=2 spatial `mu1`/`mu2` location covariance, have smoke or
  artifact evidence. Constant q=4 spatial location-scale is fitted with
  extractor/diagnostic smoke only; it needs q=4-specific DGP, recovery,
  convergence/Hessian, and interval-status artifacts before formal operating
  characteristic claims.
- User-facing docs: `vignettes/phylogenetic-spatial.Rmd`,
  `vignettes/spatial-models.Rmd`, `vignettes/structural-dependence.Rmd`,
  `vignettes/implementation-map.Rmd`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/design/66-implementation-map-slices-356-405.md`.
- Check-log evidence: `docs/dev-log/check-log.md` entries "Phase 10
  coordinate spatial one-slope" and "Phase 10 spatial slope reader path";
  `docs/dev-log/after-task/2026-05-15-phase-10-coordinate-spatial-one-slope.md`;
  `docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`;
  `docs/dev-log/after-task/2026-05-21-spatial-q2-ademp-admission.md`;
  `docs/dev-log/after-task/2026-05-21-spatial-q2-grid-artifacts.md`; and
  `docs/dev-log/after-task/2026-05-21-implementation-map-slices-356-405.md`.
- Debt: mesh/SPDE, multiple spatial slopes, labelled structured slope covariance,
  broad bridge/inference beyond deterministic matched `mu+sigma` slope fixtures,
  spatial
  slope correlations, spatial direct-SD surfaces, spatial `corpair()`
  regression, pure, multiple, or labelled count spatial slopes,
  zero-inflated spatial effects outside the exact recovery-grade Poisson q1
  spatial `zi` intercept, exact diagnostic-only fixed-`zi` Poisson q1 spatial
  `mu` gate, and exact diagnostic-only fixed-`zi` NB2 q1 spatial `mu` gate,
  and q=4 recovery/coverage evidence remain blocked; the fixed-`zi` NB2 route
  has no recovery, interval, or coverage promotion, and the fixed-`zi` Poisson
  route has no interval or coverage promotion.

### Animal-model and user-supplied relatedness effects

- Matrix status: first slices fitted for Gaussian `mu`, q=2, and constant q=4.
- Register status: partial.
- Evidence: `tests/testthat/test-animal-relmat-gaussian.R`,
  animal/`relmat()` q=2 and q=4 Phase 18 artifact tests, and dense-likelihood
  comparison checks for the fitted small or known-matrix routes.
- Diagnostics and intervals: known-matrix univariate `mu` intercepts and
  one-slope routes, matching labelled bivariate q=2 `mu1`/`mu2` location
  covariance, and constant all-four q=4 location-scale covariance have
  extractor rows, direct q=2 profile-target status, `corpairs()` rows,
  `summary()$covariance`, and `check_drm()` diagnostics. q=2 grid artifacts
  include fixed-effect Wald rows and opt-in profile-status rows. q=4
  correlations are derived-unavailable for intervals.
- User-facing docs: the structural-dependence article now shows fitted
  pedigree and known-matrix first slices, q=2 bivariate location covariance,
  and constant q=4 location-scale covariance, while still keeping sparse
  large-pedigree construction, standalone residual-scale animal models,
  predictor-dependent `corpair()` regression, direct-SD grammar, and structured
  slopes planned. It separates additive genetic relatedness from phylogenetic
  relatedness, spatial dependence, ordinary grouped random effects, and known
  sampling covariance.
- Debt: add sparse large-pedigree construction, structured animal/`relmat()` slopes,
  residual-scale relatedness models, predictor-dependent `corpair()`
  regression, direct-SD grammar, and formal q=4 coverage only after the matrix
  validation, diagnostics, profile targets, and recovery evidence for each
  route are explicit. Recovery tests should keep covering dense
  `A`/`K` versus sparse `Ainv`/`Q`, row-name and level alignment, near-singular
  matrices, weak additive variance, and separation from meta-analysis
  `meta_V(V = V)`.

### Profile intervals and diagnostics

- Matrix status: first slice locally closed.
- Register status: partial.
- Evidence: `tests/testthat/test-profile-targets.R`,
  `tests/testthat/test-summary.R`, `tests/testthat/test-check-drm.R`,
  `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-phylo-gaussian.R`, and
  `tests/testthat/test-spatial-gaussian.R`.
- Diagnostics and intervals: `conf.status`, `profile.boundary`, and
  `profile.message` expose interval status; `profile_targets()` is the target
  namespace; q=4 derived rows use `derived_interval_unavailable`.
- Phase gate: the derived-summary and interval-status foundation is recorded in
  `docs/dev-log/after-phase/2026-05-15-phase-13-derived-inference-foundation-closure.md`.
- User-facing docs: `vignettes/model-workflow.Rmd`,
  `vignettes/model-map.Rmd`, `docs/design/12-profile-likelihood-cis.md`, and
  `docs/design/28-double-hierarchical-endpoint.md`.
- Check-log evidence: `docs/dev-log/check-log.md` entries for Slices 51-59,
  especially direct profile robustness, random-effect intervals, derived-target
  status, output integration, profile diagnostics, and profile inference docs.
- Debt: nonlinear derived intervals for covariance, repeatability,
  phylogenetic signal, and total variance need a valid direct-target or
  fix-and-refit method before they are advertised as interval-ready. Slice 79
  should also make failed or skipped standard-error calculations explicit.

### Large-data fit controls

- Matrix status: opt-in control.
- Register status: opt-in.
- Evidence: `tests/testthat/test-sparse-fixed-effects.R`,
  `tests/testthat/test-gaussian-aggregation.R`,
  `tests/testthat/test-control.R`, and `bench/large-phylo-location.R`.
- Diagnostics and intervals: `check_drm()` reports sparse fixed-effect design
  and aggregation diagnostics where fitted; these controls do not create new
  interval targets by themselves.
- User-facing docs: `vignettes/large-data.Rmd`,
  `docs/design/23-large-data-memory.md`,
  `docs/design/26-sparse-fixed-effect-matrices.md`, and
  `docs/design/31-gaussian-aggregation-sufficient-statistics.md`.
- Check-log evidence: `docs/dev-log/check-log.md` records memory-light object,
  sparse fixed-effect matrix, and Gaussian aggregation slices.
- Debt: broad scalability claims for random effects, structured effects,
  non-Gaussian families, bivariate models, dense known covariance, and combined
  sparse plus aggregation paths remain blocked until benchmarks and checks cover
  those combinations.

### Reserved or planned neighbours

- Matrix status: reserved, rejected, or design-only.
- Register status: blocked.
- Evidence: rejection and guardrail tests live across
  `tests/testthat/test-gaussian-location-scale.R`,
  `tests/testthat/test-gaussian-random-intercepts.R`,
  `tests/testthat/test-gaussian-random-effect-scale.R`,
  `tests/testthat/test-biv-gaussian.R`,
  `tests/testthat/test-phylo-gaussian.R`,
  `tests/testthat/test-spatial-gaussian.R`,
  `tests/testthat/test-cumulative-logit.R`, and family-specific unsupported
  combination tests.
- Diagnostics and intervals: planned-feature errors should fire before fitting;
  no interval target should be advertised.
- User-facing docs: `vignettes/formula-grammar.Rmd`,
  `vignettes/model-map.Rmd`, `vignettes/source-map.Rmd`, and `ROADMAP.md`.
- Check-log evidence: planned-feature and unsupported-combination evidence is
  spread across the family, random-effect, bivariate, phylogenetic, spatial,
  and large-data check-log entries named above.
- Debt: coefficient-specific `sd()` slopes, random effects in `rho12`, multiple
  structured slopes, structured slope correlations, mesh/SPDE, spatial
  `corpair()`, residual-scale bivariate random slopes, formal q > 2 bivariate
  location recovery grids, mixed composed families, and other reserved
  neighbours need implementation, recovery tests, diagnostics, documentation,
  NEWS, check-log evidence, and an after-task report before moving out of
  blocked status.

## Slice 201 non-Gaussian pre-simulation failure ledger

This ledger closes the pre-simulation non-Gaussian gate by naming the failure
modes that Phase 18 should measure or deliberately exclude. It is not a new
implementation claim. A surface enters the first comprehensive simulation grid
only when the fitted likelihood, extractor rows, diagnostics, interval targets,
and focused recovery tests already exist.

| Surface | Current fitted state | Main failure modes to track | Phase 18 decision |
| --- | --- | --- | --- |
| Ordinary Poisson `mu` random effects | Fitted for non-zero-inflated Poisson random intercepts and independent numeric random slopes. | Boundary fitted SDs near zero, weak group replication, weak within-group slope variation, biased fixed effects when group SD is small, and profile failure for `log_sd_mu` targets. | Include in the first non-Gaussian pilot grid with true SD, number of groups, repeats per group, fixed-effect contrast size, factor predictors, slope variation, convergence, Hessian, `check_drm()` status, profile success, bias, RMSE, and interval coverage where available. |
| NB2 and zero-truncated NB2 ordinary random effects | NB2 is fitted for non-zero-inflated `mu` random intercepts, independent numeric `mu` slopes, and ordinary log-`sigma` random intercepts; NB2 now has a smoke runner, fixed-effect Wald intervals, direct SD profile intervals for `mu`, a weak-SD boundary test, focused `sigma` intercept recovery/extractor tests, and a separate NB2 log-`sigma` smoke-grid artifact writer with direct `log_sd_sigma` profile-target rows. Zero-truncated NB2 is fitted for ordinary `mu` random intercepts with focused source tests, direct `log_sd_mu` profile targets, and planned-neighbour boundary tests. | Confounding among overdispersion, group-level heterogeneity, zero truncation, count-side mean effects, and grouped overdispersion heterogeneity. | Admit NB2 as a focused first slice until larger grids vary overdispersion, group count, repeats, true `mu` SD, true `sigma` SD, and mean count; admit zero-truncated NB2 `mu` intercepts only as a source-tested first slice until a separate positive-count grid is designed. |
| Non-Gaussian `sigma` random effects | Ordinary non-zero-inflated NB2 fits a plain log-`sigma` random intercept and separate recovery-grade q=1 `phylo()`/`spatial()`/`animal()`/`relmat()` structured `sigma` intercept-plus-one-slope routes; fixed-effect `sigma` formulas remain available where other families support them. | Scale random effects can mimic mean random effects, overdispersion, zero inflation, tail shape, and unmodelled heteroscedasticity. | Keep the plain NB2 intercept in its dedicated small smoke grid and the exact q=1 structured routes at recovery grade; exclude plain NB2 `sigma` slopes, richer or labelled structured `sigma`, structured-`sigma` intervals/coverage, zero-inflated/truncated/hurdle scale random effects, and other family-specific scale-random-effect likelihoods until their own contracts and grid evidence exist. |
| Shape, skewness, and tail random effects | One exact q=1 Student-t `nu ~ phylo(1 | id, tree = tree)` intercept is fitted at diagnostic-only local fit/extractor grade; its single smoke has no recovery denominator. Other Student-t `nu` random effects are blocked. Skew-normal fixed effects are fitted; skew-normal random/structured/bivariate routes and the skew-t family remain planned. | Tail shape, residual skewness, residual scale, outliers, and latent ID-level skewness can mimic each other. | Keep the exact Student-t phylogenetic `nu` intercept diagnostic-only with no recovery, interval, or coverage claim. Exclude every other random effect in `nu`, future `tau`, and future ID-level skewness such as `skew(id) ~ x`. |
| Zero inflation, hurdle, zero-one inflation, and one inflation | Fixed-effect `zi` and `hu` paths exist for selected count families; one diagnostic-only Poisson q=1 `zi ~ spatial()` intercept and one diagnostic-only truncated-NB2 q=1 `hu ~ relmat(K/Q)` intercept are fitted; fixed-effect bounded-response `zoi`/`coi` paths exist only in `zero_one_beta()`, and the fixed-effect zero-one beta artifact lane now exists. | Count-side random effects can mimic structural zeros; hurdle, inflation, and exact-boundary components can be weakly separated from mean, dispersion, sampling zeros, and sampling ones. | Keep the two exact q=1 `zi`/`hu` intercept gates diagnostic-only; exclude other random effects in `zi`, `hu`, `zoi`, and `coi`; do not open an exact-boundary random-effect grid until the fixed-effect artifact lane has been audited beyond smoke scale. |
| Ordinal mixed models | Cumulative-logit fixed effects, ordinary `mu` random intercepts and independent slopes, and one exact diagnostic-only q=1 `mu ~ phylo(1 | id, tree = tree)` intercept are fitted. The phylogenetic route has local point-fit/extractor evidence only. | Cutpoint separation, sparse categories, latent-scale identification, and random-effect SD boundaries can dominate ordinary coefficient recovery. | Keep the exact phylogenetic gate diagnostic-only with no interval or coverage claim; exclude other structured ordinal effects, ordinal scale/discrimination, and broader ordinal covariance until they receive route-specific evidence. |
| Structured non-Gaussian dependence | Ordinary Poisson/NB2 fit q1 structured `mu` intercept and one-slope routes; NB2 separately fits recovery-grade q1 structured `sigma` routes. One exact crossed NB2 `mu ~ spatial() + relmat()` two-provider route has recovery-only evidence. Pure, multiple, or labelled structured count slopes, simultaneous structured types beyond that exact gate, zero-inflation beyond its exact gates, richer scale, and cross-parameter covariance remain blocked. | Known dependence matrices, Laplace random effects, sparse group support, overdispersion, and non-Gaussian links can create boundary and runtime failures before biology is interpretable. | Treat the single-provider rows at their source/smoke/recovery tiers, the exact NB2 structured `sigma` rows as recovery grade, and the crossed two-provider route as recovery-only without intervals or coverage. Do not infer broader simultaneous structured support. |
| Cross-parameter non-Gaussian covariance | Blocked. | Correlations among `mu`, `sigma`, shape, inflation, hurdle, and structured random effects can be weakly identified and can change sign under alternative parameterizations. | Exclude from Phase 18 until each marginal random-effect path is stable and a constant-block-correlation design has extractor, `corpairs()`, direct-target, and recovery evidence. |
| Non-Gaussian intervals | Wald intervals exist for fixed effects and selected direct fitted targets where covariance is available; Poisson/NB2, Student-t, zero-truncated NB2, lognormal, Gamma, and beta `mu` random-effect SDs expose direct `log_sd_mu` profile targets, and `confint(..., method = "bootstrap")` now has a narrow direct-target simulate/refit route. | Wald intervals can understate uncertainty for boundary SDs; profiles can be one-sided, non-monotone, or fail inner optimization; bootstrap refits can fail or be too slow for broad grids. | Measure interval coverage only for currently supported fixed-effect Wald, direct Wald, direct profile, and direct `confint()` bootstrap targets. Record `profile.boundary`, `profile.message`, `bootstrap.n`, and `bootstrap.failed`; do not report derived or non-`confint()` bootstrap coverage yet. |
| Runtime and scale | Routine tests are small deterministic gates, not benchmarks. | Large group counts, large dense known matrices, structured dependence, and repeated refits can change runtime and convergence rates. | Keep Phase 18 grids explicit about sample size, groups, repetitions, elapsed time, convergence rate, and failure rate. Large-data claims need optional benchmarks, not CRAN tests. |

The immediate simulation-entry decision is therefore narrow. The first
non-Gaussian operating-characteristics grid should include ordinary
non-zero-inflated Poisson `mu` random intercepts and independent numeric slopes.
NB2 `mu`, NB2 ordinary log-`sigma`, and ordinary Poisson/NB2 q=1 structured
`mu` routes should enter separate smoke or ADEMP-planning lanes, not be blended
into one ordinary count grid. The phylogenetic route has the longest formal
audit trail; the spatial, animal, and `relmat()` q=1 count routes have
source-level recovery tests and shared count-structured q1 artifacts, but they
still need their own operating-characteristic evidence before any formal
simulation parity claim.
All other non-Gaussian random-effect, structured-dependence, scale, shape,
inflation, hurdle, ordinal, and cross-parameter covariance surfaces beyond the
exact ordinary and row-specific gates recorded above remain failure-ledger rows
until their own implementation and recovery evidence exists.

## Open debt queue

| Debt ID | Surface | Minimum next evidence |
| --- | --- | --- |
| D78-01 | Non-Gaussian random effects | likelihood path, malformed-input tests, simulation recovery, and docs for each family rather than a blanket extension |
| D78-02 | Ordinal scale/discrimination | formula grammar update, likelihood parameterization, ordered-cutpoint stability tests, and interpretation docs |
| D78-03 | Dense known covariance scalability | Sparse or block-sparse `V` implementation, tests, diagnostics, and benchmarks before any broad large-data claim |
| D78-04 | q=4 derived intervals | direct nonlinear interval method or fix-and-refit profile path, plus boundary and convergence status columns |
| D78-05 | Spatial expansion | mesh/SPDE schema, projection path, precision construction, provenance, recovery tests, and diagnostics |
| D78-06 | Phylogenetic slopes | one-slope likelihood, storage order, recovery tests, direct SD targets, and `check_drm()` rows |
| D78-07 | Broader endpoint bivariate random slopes | coefficient-aware covariance registry beyond the matching slope-only `mu1`/`mu2`, q2 `sigma1`/`sigma2` scale-slope, and q=4/q=6 `mu1`/`mu2` location slices, `corpairs()` rows, profile target policy, and recovery evidence |
| D78-08 | Large-data claims | non-CRAN benchmarks and compatibility tests for random effects, structured effects, known covariance, bivariate models, and non-Gaussian families |
| D78-09 | Failed or skipped uncertainty | Slice 79 contract for `sdreport()` failures, `se = FALSE` behaviour, and summary/profile status reporting |

## Maintenance rule

When a surface moves from `partial`, `opt-in`, or `blocked` to `covered`, update
this register in the same pull request as the code, tests, docs, NEWS, check-log
entry, and after-task report. If the evidence is not in the repository or a
linked issue, the surface remains debt.
