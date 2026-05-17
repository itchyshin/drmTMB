# Phase 6d Validation-Debt Register

This register is the evidence ledger for the stable-core matrix in the README
and model-map article. It does not make new model claims. It records what backs
each advertised surface and what remains debt before a neighbouring feature can
be taught as routine.

Use these status labels:

- `covered`: the row has implementation, focused tests, user-facing docs, and
  at least one diagnostic or interval route where the surface needs one.
- `partial`: the row fits inside a narrow boundary, but the boundary is still
  scientifically important and must be visible to users.
- `opt-in`: the row is a hardening or scalability control, not a general
  modelling guarantee.
- `blocked`: the row is reserved, rejected, or design-only until likelihood
  code, tests, diagnostics, docs, and after-task evidence exist.

## Register rows

| Surface ID | Matrix row | Register status | Validation risk | Next gate |
| --- | --- | --- | --- | --- |
| `fixed_one_response` | Fixed-effect one-response families | covered | low for listed fixed-effect paths; moderate for family expansion | Add one family at a time with likelihood tests, methods tests, docs, and family-specific diagnostics. |
| `gaussian_ordinary_re` | Gaussian ordinary random effects | covered | low for listed Gaussian ordinary paths; moderate for residual-scale correlated slopes | Keep residual-scale correlation and coefficient-specific SD slopes blocked until direct tests and diagnostics exist. |
| `re_scale_sd_group` | Random-effect scale models | partial | moderate | Add coefficient-specific random-slope scale likelihood, recovery tests, and diagnostics before widening `sd()` syntax. |
| `known_sampling_covariance` | Known sampling covariance | covered/partial | moderate for dense scalability | Keep dense full `V` labelled small-to-moderate until sparse/block-sparse storage has implementation, diagnostics, and benchmark evidence. |
| `biv_residual_rho12` | Bivariate Gaussian residual `rho12` | covered | low for residual `rho12`; high if confused with latent covariance | Keep residual `rho12` separate from group, phylogenetic, and spatial correlations. |
| `ordinary_biv_corpairs` | Ordinary bivariate covariance and `corpairs()` | partial | moderate | Add coefficient-aware bivariate slope covariance only after q=2/q=4 interval status and recovery evidence are explicit. |
| `phylo_structured_effects` | Phylogenetic structured effects | partial | moderate | Add phylogenetic one-slope likelihood, diagnostics, and recovery evidence before teaching slopes. |
| `spatial_coord_effects` | Coordinate spatial structured effects | partial | moderate | Add mesh/SPDE, multiple-slope, and spatial-correlation evidence before widening spatial syntax. |
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
- Debt: richer bounded-response families, zero-one-inflated proportion models,
  ordinal scale/discrimination, and random effects for most non-Gaussian
  families still need separate likelihood work and simulation recovery.

### Poisson ordinary random effects

- Matrix status: first non-Gaussian path implemented for non-zero-inflated
  Poisson `mu`.
- Register status: ordinary unlabelled `(1 | group)` random intercepts and
  independent numeric `(0 + x | group)` slopes enter the log-mean predictor.
  Correlated slope blocks, labelled covariance blocks,
  zero-inflated Poisson random effects, and cross-parameter covariance blocks
  remain planned.
- Evidence: `tests/testthat/test-poisson-mean.R` and
  `tests/testthat/test-comparators.R`.
- Diagnostics and intervals: `sdpars$mu`, `random_effects$mu`, and
  `profile_targets()` expose the random-effect SDs through direct
  `log_sd_mu` profile targets.
- Debt: weak-SD grids, NB2-style count random intercepts, correlated
  non-Gaussian `mu` slopes, and cross-parameter covariance need later slice
  evidence before Phase 18 comprehensive simulation.

### Non-Gaussian scale random effects

- Matrix status: blocked with explicit messages.
- Register status: Student-t, lognormal, Gamma, beta, beta-binomial, NB2,
  truncated NB2, and hurdle NB2 `sigma` formulas are fixed-effect only.
  Random-effect bar terms in those scale formulas error before optimization.
- Evidence: `tests/testthat/test-nongaussian-scale-boundary.R` plus the
  neighbouring family malformed-input tests.
- Diagnostics and intervals: none, because no non-Gaussian scale random-effect
  likelihood is fitted yet.
- Debt: family-specific likelihood code, `sdpars` and `random_effects`
  extractors, `profile_targets()` rows, weak-SD recovery tests, scale-specific
  interpretation docs, and CI evidence are required before any non-Gaussian
  `sigma` random effect is advertised.

### Shape random effects and ID-level skewness

- Matrix status: blocked with explicit messages.
- Register status: Student-t `nu` is a fixed-effect tail-shape formula.
  Future skew-normal and skew-t shape formulas should remain fixed-effect
  residual-shape paths until density, recovery, prediction, and false-positive
  heteroscedasticity checks pass.
- Evidence: `tests/testthat/test-student-location-scale.R` checks that
  `nu ~ x + (1 | id)` and `nu ~ x + (0 + x | id)` fail with a shape-specific
  boundary.
- Diagnostics and intervals: no shape random-effect diagnostics or intervals
  exist because no shape random-effect likelihood is fitted yet.
- Debt: fixed-effect skew-normal and skew-t recovery, normal or Student-t limit
  checks, separation of `sigma ~ x` from `nu ~ x`, then simulation evidence
  before adding `nu`/`tau` random effects or latent ID-level skewness such as
  future `skew(id) ~ x`.

### Gaussian ordinary random effects

- Matrix status: stable.
- Register status: covered for Gaussian `mu` random intercepts, independent
  slopes, one-slope correlated blocks, `sigma` intercepts, and independent
  `sigma` slopes.
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
- Debt: correlated residual-scale slope blocks and coefficient-specific
  random-slope `sd()` surfaces remain blocked.

### Random-effect scale models

- Matrix status: first slice.
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
- Debt: bivariate random slopes, full cross-parameter slope covariance, and
  slope1-slope2 plasticity-syndrome correlations remain blocked until the
  coefficient-aware `corpair()` contract has likelihood code and recovery
  evidence.

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
  values use `newdata`; q=4 phylogenetic correlations are derived-only for
  intervals; `check_drm()` reports phylogenetic covariance diagnostics.
- User-facing docs: `vignettes/phylogenetic-spatial.Rmd`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/design/20-coscale-correlation-pairs.md`.
- Check-log evidence: `docs/dev-log/check-log.md` records the phylogenetic
  direct-SD, bivariate phylogenetic covariance, q=4 phylogenetic, and
  predictor-dependent q=2 phylogenetic `corpair()` slices.
- Debt: phylogenetic slopes, standalone or partial phylogenetic scale terms,
  structured `rho12`, predictor-dependent q=4 correlations, and longer optional
  simulations remain planned.

### Coordinate spatial structured effects

- Matrix status: first slice.
- Register status: partial.
- Evidence: `tests/testthat/test-spatial-gaussian.R`,
  `tests/testthat/test-profile-targets.R`, and
  `tests/testthat/test-check-drm.R`.
- Diagnostics and intervals: `sdpars$mu`, `ranef("spatial_mu")`,
  `profile_targets()`, and `check_drm()` expose the coordinate-spatial fields
  and direct spatial SD targets.
- User-facing docs: `vignettes/phylogenetic-spatial.Rmd`,
  `docs/design/09-phylogenetic-and-spatial-speed.md`, and
  `docs/design/16-phylo-spatial-common-math.md`.
- Check-log evidence: `docs/dev-log/check-log.md` entries "Phase 10
  coordinate spatial one-slope" and "Phase 10 spatial slope reader path";
  `docs/dev-log/after-task/2026-05-15-phase-10-coordinate-spatial-one-slope.md`;
  `docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`.
- Debt: mesh/SPDE, multiple spatial slopes, spatial slope correlations,
  spatial `sigma`, bivariate spatial covariance, and spatial `corpair()` remain
  blocked.

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
- Debt: coefficient-specific `sd()` slopes, random effects in `rho12`,
  phylogenetic slopes, mesh/SPDE, spatial `corpair()`, bivariate random slopes,
  mixed composed families, and other reserved neighbours need implementation,
  recovery tests, diagnostics, documentation, NEWS, check-log evidence, and an
  after-task report before moving out of blocked status.

## Open debt queue

| Debt ID | Surface | Minimum next evidence |
| --- | --- | --- |
| D78-01 | Non-Gaussian random effects | likelihood path, malformed-input tests, simulation recovery, and docs for each family rather than a blanket extension |
| D78-02 | Ordinal scale/discrimination | formula grammar update, likelihood parameterization, ordered-cutpoint stability tests, and interpretation docs |
| D78-03 | Dense known covariance scalability | Sparse or block-sparse `V` implementation, tests, diagnostics, and benchmarks before any broad large-data claim |
| D78-04 | q=4 derived intervals | direct nonlinear interval method or fix-and-refit profile path, plus boundary and convergence status columns |
| D78-05 | Spatial expansion | mesh/SPDE schema, projection path, precision construction, provenance, recovery tests, and diagnostics |
| D78-06 | Phylogenetic slopes | one-slope likelihood, storage order, recovery tests, direct SD targets, and `check_drm()` rows |
| D78-07 | Bivariate random slopes | coefficient-aware covariance registry, `corpairs()` rows, profile target policy, and recovery evidence |
| D78-08 | Large-data claims | non-CRAN benchmarks and compatibility tests for random effects, structured effects, known covariance, bivariate models, and non-Gaussian families |
| D78-09 | Failed or skipped uncertainty | Slice 79 contract for `sdreport()` failures, `se = FALSE` behaviour, and summary/profile status reporting |

## Maintenance rule

When a surface moves from `partial`, `opt-in`, or `blocked` to `covered`, update
this register in the same pull request as the code, tests, docs, NEWS, check-log
entry, and after-task report. If the evidence is not in the repository or a
linked issue, the surface remains debt.
