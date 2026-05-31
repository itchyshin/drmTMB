# Four-Week Random-Slope and Digital-Twin Sprint

## Purpose

This note turns the 2026-05-30 planning session into a repo-visible sprint
contract. The reader is a future `drmTMB` contributor deciding which issue to
open next, which status claim is already supported, and which sister-package
lesson can be used only as a candidate design signal.

Parent issue: <https://github.com/itchyshin/drmTMB/issues/436>

Child issues:

- #437: daily digital-twin and sister-package exchange.
- #438: random-slope support matrix refresh.
- #439: Gaussian ordinary random-slope closeout.
- #440: bivariate Gaussian slope-only evidence gate.
- #441: non-Gaussian independent `mu` slope admission.
- #442: structured Gaussian one-slope audit.
- #443: coscale and `corpairs()` boundary.
- #444: random-slope tutorial and release ledger.
- #446: random-slope simulation power, accuracy, and coverage plan.

Simulation planning issue:

- #59 is the Phase 18 simulation mega-issue for power, accuracy, coverage,
  runtime, and failure-mode evidence across families and model types.
- #446 is the Phase 6c random-slope child issue that turns #59 into a concrete
  four-week plan for power, accuracy, coverage, convergence, runtime, and
  failure-ledger evidence before candidate cells are promoted.
- #255 is the artifact-grain child issue that keeps replicate-level rows,
  aggregate summaries, MCSE intervals, and figure geometry honest.
- #60 is the smaller comparator-package lane for `glmmTMB`, direct TMB
  baselines, Julia twins such as `DRM.jl` and `GLLVM.jl`, and other packages
  where the parameter target is genuinely comparable. Comparator or twin
  results can motivate `drmTMB` simulations, but they are not `drmTMB`
  coverage evidence.

## Current Sprint Matrix

| Layer | Current status | Sprint action |
| --- | --- | --- |
| Ordinary Gaussian `mu` | Fitted for independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric location blocks. | Use #439 to consolidate q=3 recovery, extractor, `summary()`, `corpairs()`, and direct-SD profile evidence. |
| Gaussian `sigma` | Fitted for random intercepts and multiple independent numeric slopes on `log(sigma)`. | Use #439 to keep correlated residual-scale slope blocks and labelled residual-scale slope covariance planned, not fitted. |
| Bivariate Gaussian covariance | Fitted for selected labelled intercept blocks and matching slope-only `mu1`/`mu2` blocks. | Use #440 to promote or hold the `biv_gaussian_mu_slope` grid from dispatch/artifact evidence to recovery evidence. |
| Non-Gaussian `mu` slopes | Fitted or source-tested for selected ordinary independent `mu` slope paths, depending on family. | Use #441 to admit families one by one; do not write a broad non-Gaussian slope claim. |
| `phylo()`, `spatial()`, `animal()`, `relmat()` | First univariate Gaussian `mu` one-slope paths are fitted as independent intercept and slope fields. | Use #442 to audit tests, diagnostics, profile targets, and q2/q4 status; keep multiple structured slopes, slope correlations, residual-scale structured slopes, structured `rho12`, and non-Gaussian structured slopes planned. |
| Coscale and correlation extraction | Residual `rho12` and fitted group/structured covariance rows are separate output layers. | Use #443 to keep `rho12`, `corpair()`, and `corpairs()` wording precise in random-slope examples. |
| Tutorial and release ledger | Existing tutorials cover pieces of the ordinary core and bivariate/coscale surfaces. | Use #444 to produce a reader-facing path and reference-index check after status wording is reconciled. |

## Issue #443 Boundary Language

Use this wording in user-facing prose until a later design issue supersedes it.
Coscale means the residual bivariate Gaussian correlation parameter `rho12`.
It is a distributional parameter in the residual covariance matrix, not a
group-level, phylogenetic, spatial, animal-model, or known-matrix covariance
row. Random effects and structured terms in `rho12` remain unsupported.

The singular `corpair()` marker is a formula for a named latent random-effect
correlation pair. It is fitted only where the likelihood and positive-definite
parameterization already exist, currently selected q=2 ordinary and
phylogenetic location-location routes. Predictor-dependent q=4, spatial,
animal, `relmat()`, residual-scale, and slope-specific `corpair()` regressions
remain planned.

The plural `corpairs()` helper is an extractor. It reports residual `rho12`
and fitted latent correlation rows from ordinary group, phylogenetic, spatial,
animal-model, and `relmat()` covariance layers where those layers are already
implemented. It does not fit a new covariance model.

## Issue #439 Gaussian Ordinary Closeout

Use this table as the #439 ordinary Gaussian grouped random-slope closeout
ledger. It separates fitted extractor support, simulation/artifact admission,
and unsupported residual-scale covariance claims; use #446 for recovery,
accuracy, power, and coverage grids.

| Surface | Current support | Evidence handles | Boundary |
| --- | --- | --- | --- |
| Gaussian `mu` q > 2 grouped blocks | Fitted for numeric ordinary grouped blocks such as `(1 + x1 + x2 | id)` and larger numeric multi-slope blocks. | `tests/testthat/test-gaussian-random-intercepts.R` checks q=3 and q=4-style ordinary blocks, including `sdpars$mu`, `corpars$re_cov`, `corpairs()`, `summary(fit)$covariance`, and `profile_targets()`. `tests/testthat/test-phase18-gaussian-mu-random-slope.R` checks the q=3 smoke runner. | Larger q blocks are advanced and sample-size hungry. SD rows are direct profile targets; q > 2 correlation rows are derived and not direct profile-interval targets. |
| Gaussian `sigma` independent slopes | Fitted for random intercepts and multiple independent numeric slopes on `log(sigma)`, such as `sigma ~ z + (0 + w | id)`. | `tests/testthat/test-gaussian-random-intercepts.R` checks independent and multiple residual-scale terms, prediction contribution on the `log(sigma)` scale, `sdpars$sigma`, and `profile_targets()`. `tests/testthat/test-phase18-gaussian-sigma-random-slope.R` checks the Phase 18 smoke runner. | Correlated residual-scale slope blocks, labelled residual-scale slope covariance, and slope-level mean-scale covariance remain planned. |
| Phase 18 routing | Both ordinary Gaussian `mu` slopes and independent Gaussian `sigma` slopes are `ready_grid` rows routed through `first_wave_summary`. | `inst/sim/registry/phase18_structured_workflow_registry.csv` rows `gaussian_ordinary_mu_slopes` and `gaussian_sigma_independent_slopes`; `inst/sim/README.md` first-wave summary entries. | First-wave dispatch is simulation-artifact readiness, not broad power, accuracy, or coverage evidence for every q or covariance pattern. |

## Issue #441 Non-Gaussian Slope Admission

Use this table until #441 is superseded by a family-specific simulation run.
Fixed-effect likelihood support, independent `mu` slope source tests, and
Phase 18 artifact routes are separate evidence layers.

| Family or lane | Fixed-effect likelihood | Independent `mu` slope source test | Phase 18 artifact route | #441 status |
| --- | --- | --- | --- | --- |
| Ordinary Poisson `mu` | Yes | Yes | `poisson_mu_random_effect` smoke/grid lane | Strongest non-Gaussian count `mu` slope candidate; keep correlated slopes, labels, zero inflation, and structured slopes separate. |
| Ordinary NB2 `mu` | Yes | Yes | `nbinom2_mu_random_effect` smoke/grid lane | Strong count `mu` slope candidate; keep NB2 `sigma` slopes, zero inflation, labelled covariance, and structured slopes separate. |
| Student-t `mu` | Yes | Yes | `student_mu_random_intercept` artifact lane | Source-tested independent slope, but the current artifact lane is random-intercept focused; do not claim slope recovery or coverage until #446 designs it. |
| Lognormal `mu` | Yes | Yes | `positive_continuous_mu_random_intercept` artifact lane | Source-tested independent slope; keep correlated positive-continuous slopes, `sigma` random effects, and known-covariance positive-response routes planned. |
| Gamma `mu` | Yes | Yes | `positive_continuous_mu_random_intercept` artifact lane | Same status as lognormal: source-tested independent slope, not slope-specific Phase 18 recovery or coverage evidence. |
| Beta `mu` | Yes | Yes | `bounded_response_mu_random_intercept` artifact lane | Source-tested independent slope; keep correlated bounded-response slopes, `sigma` random effects, exact boundary mass, and zero-one beta random effects planned. |
| Beta-binomial `mu` | Yes | Yes | `bounded_response_mu_random_intercept` artifact lane | Same status as beta: source-tested independent slope, not broad bounded-response random-slope support. |
| Zero-truncated NB2 `mu` | Yes | Yes | `truncated_nbinom2_mu_random_intercept` artifact lane | Source-tested independent slope; keep correlated slopes, hurdle/inflation neighbours, `sigma` random effects, and structured routes planned. |
| Tweedie, zero-one beta, hurdle/zero-inflated counts, ordinal, shape parameters | Fixed-effect subsets only where implemented | No #441 slope admission | Separate fixed-effect or design lanes | Do not admit as non-Gaussian random-slope support from #441. |

The current family-spanning source test is
`tests/testthat/test-nongaussian-mu-random-slopes.R`. It checks fit
convergence, `pdHess`, random-effect labels, `sdpars$mu`, `ranef()`,
prediction contribution, direct `profile_targets()` rows, and `check_drm()`
replication/design diagnostics for Student-t, lognormal, Gamma, beta,
beta-binomial, and zero-truncated NB2. That is valuable source evidence, but
not a substitute for a slope-specific Phase 18 recovery, accuracy, coverage,
or power grid.

## Issue #442 Structured One-Slope Audit

Use this table to keep one-slope Gaussian structured effects separate from q2,
q4, count, and future multi-slope claims.

| Layer | Gaussian `mu` one-slope | q2 structured covariance | q4 structured covariance | Current artifact route | Keep planned or diagnostic |
| --- | --- | --- | --- | --- | --- |
| `phylo()` | Fitted for one numeric `mu` slope with independent intercept and slope fields. | Fitted for selected bivariate `mu1`/`mu2` location rows and q2 phylogenetic `corpair()` routes. | Fitted for selected location-scale blocks, but q4 rows remain diagnostic-heavy and interval-limited. | Registry wrapper target for Gaussian one-slope; Poisson/NB2 q1 phylogenetic formal tasks are separate count lanes, not Gaussian one-slope evidence. | Multiple phylogenetic slopes, phylogenetic slope correlations, residual-scale structured slopes, non-Gaussian phylogenetic slopes, and structured `rho12`. |
| `spatial()` | Fitted for one coordinate-spatial `mu` slope; mesh/SPDE slopes remain planned. | Fitted for constant bivariate spatial `mu1`/`mu2` q2 covariance with DGP, smoke, and grid helpers. | Fitted for constant coordinate-spatial q4 location-scale blocks as smoke/artifact evidence; recovery and interval-status evidence remain separate. | Manual `spatial_mu_slope` Actions task plus spatial q2 smoke/grid helpers. | Mesh/SPDE, multiple spatial slopes, spatial slope correlations, residual-scale structured slopes, spatial direct-SD regression, spatial `corpair()` regression, and count spatial slopes. |
| `animal()` | Fitted for one dense-pedigree or known-matrix Gaussian `mu` slope. | Fitted for known-matrix bivariate `mu1`/`mu2` q2 covariance with smoke/grid artifacts. | Fitted for constant all-four q4 location-scale blocks as point-estimate smoke; derived q4 intervals remain unavailable. | Registry wrapper target for Gaussian one-slope; animal/`relmat()` q2 and q4 smoke/grid helpers exist, but no standalone one-slope Actions task. | Sparse large-pedigree speed claims, multiple animal slopes, slope correlations, residual-scale structured slopes, predictor-dependent `corpair()` regression, count animal slopes, and direct-SD grammar. |
| `relmat()` | Fitted for one known-matrix Gaussian `mu` slope through `K` or `Q`. | Fitted for known-matrix bivariate `mu1`/`mu2` q2 covariance with smoke/grid artifacts. | Fitted for constant all-four q4 location-scale blocks as point-estimate smoke; derived q4 intervals remain unavailable. | Registry wrapper target for Gaussian one-slope; animal/`relmat()` q2 and q4 smoke/grid helpers exist, but no standalone one-slope Actions task. | Multiple `relmat()` slopes, slope correlations, residual-scale structured slopes, predictor-dependent `corpair()` regression, count `relmat()` slopes, and direct-SD grammar. |

The current registry handles this split in
`inst/sim/registry/phase18_structured_workflow_registry.csv`: Gaussian
`phylo()`, `animal()`, and `relmat()` one-slope rows are `ready_grid` but need
a structured-dependence wrapper target; coordinate-spatial one-slope now has
the manual `spatial_mu_slope` task; structured q2 rows are `ready_or_smoke`;
structured q4 rows are `diagnostic_only` with derived intervals unavailable.

## Issue #438 Support-Matrix Labels

Use these labels in #438, the roadmap, and pkgdown pages until a later evidence
slice supersedes them. Fitted support, simulation admission, and interval
readiness are separate claims.

| Label | Current cells | Evidence handles |
| --- | --- | --- |
| Fitted | Ordinary Gaussian `mu` random intercepts/slopes, independent Gaussian `sigma` slopes, selected bivariate Gaussian covariance, residual `rho12`, Gaussian structured `phylo()`/`spatial()`/`animal()`/`relmat()` intercept and one-slope `mu` rows, ordinary Poisson/NB2 `mu` slopes, and selected ordinary non-Gaussian `mu` slopes. | `docs/design/46-pre-simulation-readiness-matrix.md`, `docs/design/59-structural-slope-and-non-gaussian-map.md`, `vignettes/implementation-map.Rmd`, and the current README/model-map status rows. |
| Simulation-ready | Registry rows marked `ready_grid`, including `gaussian_ordinary_mu_slopes`, `gaussian_sigma_independent_slopes`, `bivariate_gaussian_slope_only`, residual `rho12`, selected ordinary q=2 `corpairs()` rows, ordinary Poisson/NB2 `mu` random effects, and Gaussian structured one-slope rows queued for focused wrappers. | `inst/sim/registry/phase18_structured_workflow_registry.csv` and `docs/design/143-phase-18-structured-workflow-registry.md`. |
| Smoke or source-only | Selected bounded, positive-continuous, Student-t, and zero-truncated NB2 ordinary `mu` independent slopes; NB2 `sigma` random intercepts; Poisson q=1 phylogenetic formal-admission lane; NB2 q=1 phylogenetic held-smoke lane. | Registry rows with `ready_source_test`, `ready_smoke`, `smoke_formal_admission`, or `hold_smoke_only`. |
| Diagnostic-only | Ordinary or structured q=4 `corpairs()` rows, q=4 spatial/animal/`relmat()` location-scale point-estimate lanes, count q=1 spatial/animal/`relmat()` structured rows before formal recovery, and Ayumi hard real-data q2/q4 cases. | Registry rows marked `diagnostic_only`, plus hard-fit diagnostics in `docs/design/46-pre-simulation-readiness-matrix.md`. |
| Design-only | Mixed-response bivariate families and any future joint/coplanar likelihood or latent contract work. | `mixed_response_bivariate` in the Phase 18 registry. |
| Unsupported or blocked | Count labelled q2/q4 covariance, random effects in `rho12`, correlated non-Gaussian slopes, structured count slopes, zero-inflation/hurdle random effects, Student-t `nu` random effects, ordinal random effects, NB2 `sigma` slopes, and structured `sigma`. | Registry rows marked `blocked`, failure-ledger text in the readiness matrix, and the implementation-map planned-neighbour rows. |

## Simulation Admission Bridge

The four-week sprint does not replace the larger Phase 18 simulation programme
in #59. Each capability child issue should end by saying whether the surface is
documentation-only, source or smoke only, simulation-ready, or ready for a
larger operating-characteristic grid. A supported claim needs local `drmTMB`
evidence for the relevant estimand, not only a successful fit.

For every surface promoted from fitted to simulation evidence, require a small
ADEMP sheet or equivalent row that names the aim, data-generating mechanism,
estimand, fitted method, performance measures, replicate plan, and Monte Carlo
standard-error target. The minimum performance vocabulary is bias or accuracy,
RMSE, interval coverage, power or Type I error when a null comparison is part
of the question, convergence and Hessian status, boundary rate, and runtime.

The first sheet is
`docs/design/144-phase6c-gaussian-random-slope-ademp.md`. It plans ordinary
Gaussian `mu` q > 2 grouped random slopes and independent Gaussian `sigma`
random slopes, while keeping q > 2 correlations derived-only for intervals and
correlated residual-scale slope covariance planned.

The second sheet is `docs/design/145-phase6c-bivariate-slope-ademp.md`. It
plans the matching bivariate Gaussian `mu1`/`mu2` slope-only lane from #440 and
keeps residual `rho12` separate from group-level slope-slope covariance in
truth, extraction, interval, and reporting columns.

The artifact-schema audit is
`docs/design/146-phase6c-bivariate-slope-artifact-schema-audit.md`. It records
that the current bivariate slope-only replicate and aggregate artifacts already
separate `random_correlation` from `residual_rho12`, while coverage and power
remain planned until interval-status and rejection-rule artifacts exist.

The third sheet is
`docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`. It plans an
artifact-admission lane for selected ordinary non-Gaussian independent `mu`
slopes while keeping family evidence separate and leaving coverage, power,
correlated slopes, structured dependence, and non-Gaussian scale or shape
random effects planned or blocked.

The fourth sheet is
`docs/design/148-phase6c-structured-one-slope-ademp.md`. It plans the #442
Gaussian structured one-slope lane for `phylo()`, `spatial()`, `animal()`, and
`relmat()`, while keeping `spatial_mu_slope` artifact readiness separate from
the `phylo()`, `animal()`, and `relmat()` wrapper-target rows.

Keep the first Phase 6c simulation bridge narrow:

- #439 queues ordinary Gaussian q > 2 `mu` slopes and independent Gaussian
  `sigma` slopes into #59 only when extractor and direct-SD interval targets
  are stable.
- #440 queues the bivariate Gaussian slope-only lane into #59 only when
  residual `rho12` is separated from group-level covariance in the estimands
  and report tables.
- #441 queues non-Gaussian independent `mu` slopes family by family, with
  fixed-effect likelihood and interval evidence ahead of random-effect claims.
- #442 queues structured Gaussian one-slope rows only as one-slope rows; q2/q4
  structured covariance, multiple structured slopes, and structured
  residual-scale slopes remain separate design or diagnostic lanes.

## Daily Twin/Sister Exchange

The daily exchange lives in #437 and in
`docs/dev-log/twin-sister-exchange.md`. Each lesson card records source repo,
branch/commit, observed pattern, applicability, proposed `drmTMB` action,
provenance risk, and comment status.

The direct digital twin is `DRM.jl`. It is an MIT Julia package that mirrors
the `drmTMB` formula surface and aims to become the fastest correct engine for
the one-response and two-response `drmTMB` model class. Treat it as a design
mirror, not a dependency.

The sister package is `gllvmTMB`, with Julia digital twin `GLLVM.jl`. They
are useful for performance, validation, and workflow
lessons, but higher-dimensional latent-variable models remain out of
`drmTMB` scope. Their speed and coverage results motivate candidate benchmark
or diagnostic slices only; they are not `drmTMB` evidence.

## Guardrails

- Keep `drmTMB` to one-response and two-response models.
- Keep residual `rho12`, ordinary group-level covariance, structured
  covariance, and known-matrix covariance as separate layers.
- Do not change formula grammar without updating
  `docs/design/01-formula-grammar.md`.
- Do not change likelihood parameterisation without updating
  `docs/design/03-likelihoods.md`.
- Do not port or adapt code from another package without recording source,
  commit, license, adaptation, and reviewer in `inst/COPYRIGHTS`.
- Do not describe `DRM.jl`, `GLLVM.jl`, or benchmark-repo
  performance as `drmTMB` performance until a `drmTMB` benchmark or simulation
  artifact exists.
