# Phase 6c Random-Slope Sprint Closeout

This note closes #436 as the parent tracker for the focused Phase 6c
random-slope and twin/sister exchange sprint. It does not close the broader
Phase 6c structured-slope programme in #33, the Phase 18 simulation programme
in #59, comparator work in #60, public bootstrap intervals in #265, or the
larger covariance-block issue #5.

## Closeout Claim

The sprint is complete at the capability-ledger level. The current repository
now separates fitted, source-tested, artifact-ready, planning-only, planned,
and unsupported random-slope cells before larger operating-characteristic
simulation begins.

The sprint produced documentation, tests, artifact-routing, and validation
handles for the first ordinary, bivariate, non-Gaussian, structured,
coscale-boundary, tutorial, simulation-planning, and twin/sister exchange
lanes. It did not promote broad recovery, coverage, power, benchmark, p8/q8,
random-`rho12`, residual-scale structured-slope, correlated non-Gaussian
slope, or higher-dimensional multivariate claims.

## Child Issue Status

| Issue | Sprint lane | Closed by | Main evidence on `main` | Remaining boundary |
| --- | --- | --- | --- | --- |
| #437 | Twin/sister exchange | PR #466 | `docs/dev-log/twin-sister-exchange.md`, ROADMAP Slice 79, and the 2026-06-01 after-task report | Sister-package speed, convergence, coverage, or recovery does not transfer to `drmTMB` without local validation |
| #438 | Support matrix refresh | Earlier Phase 6c PR | `docs/design/59-structural-slope-and-non-gaussian-map.md`, README status rows, and known-limitations updates | Remaining unsupported and planned cells stay visible rather than inferred from nearby fitted cells |
| #439 | Ordinary Gaussian random-slope closeout | Earlier Phase 6c PR | ROADMAP ordinary grouped status, tests for Gaussian random slopes, `corpairs()`, `summary()`, and `profile_targets()` handles | Larger ordinary q blocks remain sample-size hungry; q > 2 correlations do not yet have direct profile intervals |
| #440 | Bivariate Gaussian slope-only evidence gate | Earlier Phase 6c PR | `docs/design/145-phase6c-bivariate-slope-evidence-gate.md` and `biv_gaussian_mu_slope` artifact route | Held from recovery, coverage, power, residual-scale slope, random-`rho12`, and p8/q8 claims; the later q4 and q6 location routes now have smoke artifact routing |
| #441 | Non-Gaussian independent `mu` slope admission | Earlier Phase 6c PR | `docs/design/147-phase6c-nongaussian-mu-slope-ademp.md` and family-specific source tests | Correlated, labelled, structured, scale, shape, inflation, hurdle, ordinal, and mixed-response random slopes remain planned or blocked |
| #442 | Structured Gaussian one-slope audit | Earlier Phase 6c PR | `docs/design/59-structural-slope-and-non-gaussian-map.md`, structured one-slope tests, metadata accessors, and simulation-plan handoff | Multiple structured slopes, structured slope correlations, residual-scale structured slopes, and non-Gaussian structured slopes remain planned |
| #443 | Coscale and `corpairs()` boundary | Earlier Phase 6c PR | ROADMAP coscale boundary, formula/tutorial wording, and `corpair()`/`corpairs()` evidence | Residual `rho12`, singular `corpair()`, and plural `corpairs()` remain distinct layers |
| #444 | Tutorial and release ledger | PR #465 | `docs/design/151-phase6c-random-slope-tutorial-ledger.md`, model-map, location-scale article, bivariate-coscale article, and worked-example inventory | Fuller simulated bivariate plasticity-syndrome and advanced structured-slope tutorials remain future work |
| #446 | Simulation power, accuracy, and coverage plan | Earlier Phase 6c PR | `docs/design/148-phase6c-random-slope-simulation-plan.md` and registry preflight | Diagnostic pilots may propose formal grids; they cannot by themselves create recovery, coverage, or power claims |

## Sprint Deliverables

The current sprint closed the support ledger before the planned large
simulation work:

- Ordinary Gaussian `mu` and independent Gaussian `sigma` random-slope rows
  are separated from residual-scale correlated-slope plans.
- The first bivariate Gaussian slope-only `mu1`/`mu2` row is fitted and
  artifact-ready, but it remains held from recovery, coverage, power, and
  p8/q8 claims.
- Selected ordinary non-Gaussian independent `mu` slopes are admitted at
  `ready_grid` or `ready_source_test`, while correlated, labelled, structured,
  scale, shape, inflation, hurdle, ordinal, and mixed-response neighbours stay
  planned or blocked.
- The first Gaussian `phylo()`, `spatial()`, `animal()`, and `relmat()`
  one-slope `mu` rows are visible as fitted first slices, with multiple
  structured slopes and residual-scale structured slopes still planned.
- The `rho12` coscale, `corpair()` formula marker, and `corpairs()` extractor
  boundaries are explicit before simulation reports reuse these tables.
- The tutorial path points readers to supported syntax, output rows,
  diagnostics, and profile-target status without advertising planned routes as
  runnable examples.
- The twin/sister exchange protocol records transferable process lessons as
  planning evidence only.

## Remaining Open Work

#436 can close because its child lanes are now repo-visible and issue-linked.
The following remain intentionally open:

- #33 for the broader Phase 6c structured and bivariate random-slope
  programme;
- #59 for Phase 18 diagnostic and formal operating-characteristic simulations;
- #60 for comparator-package demonstrations;
- #147 for broader `animal()` and `relmat()` known-relatedness work;
- #265 for public bootstrap intervals for hard fits;
- #342 and #61 for release and CRAN/paper gates;
- #5 for larger covariance blocks for individual-difference models.

## Closeout Boundary

This closeout is a status and coordination artifact. It does not change
likelihoods, parser grammar, simulation runners, GitHub Actions dispatch,
pkgdown navigation, or missing-data behavior. Future simulation work should
start from #59 and the #446 run order rather than reopening #436.
