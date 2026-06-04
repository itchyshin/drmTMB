# Capability Completion Worklist Toward the Power Simulation

This note is a single dependency-ordered index from the current fitted surface to
the full planned capability set, written so a local-R/TMB implementation session
can work top to bottom without rediscovering the design. It does not restate the
per-capability gates; it sequences them and names the exact code site, test
contract, and simulation lane each remaining slice needs.

The reader is the contributor running a local session with TMB available, plus
the project owner deciding what must be fitted before the big power simulation.

## Why This Exists

The design is largely complete. Every capability below already has a gate or
ADEMP sheet, and `docs/design/46-pre-simulation-readiness-matrix.md` records the
fitted-versus-planned boundary in detail. What was missing is one place that
orders the *remaining implementation* by dependency and points at the precise
parser/likelihood site, so the work is mechanical rather than exploratory.

These slices need a TMB build/test loop, so they cannot be completed in the
cloud sandbox (its network policy blocks the R package repositories). They are
listed here so the local session is turnkey.

## Readiness Snapshot

Fitted today (see doc 46 for the full matrix): Gaussian fixed-effect
location-scale; ordinary Gaussian `mu` intercepts, `q > 2` slopes, and
independent `sigma` slopes; selected bivariate `mu1`/`mu2` and `sigma1`/`sigma2`
random-intercept covariance blocks; slope-only and q4/q6 `mu1`/`mu2` location
blocks (smoke); residual `rho12`; `meta_V(V = V)`; coordinate-spatial,
phylogenetic, `animal()`, and `relmat()` Gaussian `mu`/`sigma` intercepts plus
one `mu` slope; ordinary Poisson/NB2 `mu` random effects and q=1 structured
intercepts; the fixed-effect non-Gaussian family set; fixed-effect ordinal.

The capability gaps below are what stand between that surface and the
"all capabilities planned" milestone.

## Tier A — Individual-Difference Covariance Endpoint (#5, #33)

This is the flagship: correlating individual differences in average response,
plasticity, residual variability, and its change. Implement strictly in order.

1. **Bivariate residual-scale random slopes (q2 scale slope).**
   - Gate: `docs/design/155-bivariate-residual-scale-random-slope-gate.md`.
   - Site: convert the rejection at `R/drmTMB.R:4963-4969`; feed per-observation
     slope design columns into `build_biv_sigma_random_structure` →
     `build_biv_parameter_random_structure` (q=2 layout unchanged in shape).
   - Verify: malformed-input tests at
     `tests/testthat/test-biv-gaussian.R:2837-2864`; recovery lane already
     scaffolded as `biv_gaussian_q2_scale_recovery`.
2. **Same-response location-scale slope covariance (`mu1`/`sigma1` slopes).**
   - Gate: `docs/design/28-double-hierarchical-endpoint.md` (step 5) and the
     "q2 same-response location-scale slope" row in
     `docs/design/67-sdstar-p8-poisson-q1.md`. High identifiability risk — needs
     many observations per group.
   - Depends on slice 1.
3. **q8 all-endpoint block.**
   - Gate: `docs/design/67-sdstar-p8-poisson-q1.md`; registry row
     `bivariate_gaussian_q8_endpoint` (currently `design_only`).
   - Depends on slices 1 and 2. Keep q8 correlations
     `derived_interval_unavailable` until a validated interval method exists.

## Tier B — Structured Random Slopes (#33, #147)

4. **Phylogenetic `mu` slopes beyond the first; slope correlations.**
   - Gate: `docs/design/44-structured-slope-parity-gate.md`,
     `docs/design/148-phase6c-structured-one-slope-ademp.md`.
5. **Coordinate-spatial `mu` slope correlations** (one independent slope is
   already fitted). Same parity gate.
6. **`animal()`/`relmat()` slopes and bivariate genetic covariance (#147).**
   - Gates: `docs/design/54-...`, `55-...`, `58-phase-18-animal-relmat-q4-ademp.md`.
   - Includes sparse large-pedigree precision construction (overlaps Tier E).
7. **Residual-scale structured slopes** (the structured analogue of Tier A.1).

## Tier C — Location-Scale-Shape Family (#3)

8. **`skew_normal()` fixed-effect first slice.**
   - Gates: `docs/design/127-...parameterization-decision`,
     `128-...test-contract`, `132-...implementation-gate`,
     `123-...source-map`. The parameterization and test contract are decided;
     this slice is implementation-ready.
   - Scope: univariate fixed-effect `mu`/`sigma`/`nu` only; no random or
     structured effects in the first slice.

## Tier D — Random Effects in `rho12` (#5 boundary)

9. **Random intercepts in `rho12`**, kept distinct from group-level covariance.
   - Boundary: `docs/design/45-cross-dpar-correlation-gate.md`. Needs its own
     gate before likelihood work; currently only fixed-effect/predictor `rho12`
     is fitted.

## Tier E — Large-Data Readiness (#4)

10. **Sparse fixed-effect matrices** with dense-vs-sparse parity tests, Gaussian
    sufficient-statistic aggregation, and 1M-row / high-species benchmarks.
    - Gate: `docs/design/23-large-data-memory.md`. Benchmarks need a real
      machine, not the sandbox.

## Tier F — Mixed-Response Bivariate (#5 boundary)

11. **Mixed-response bivariate families** (e.g. Gaussian-count) remain blocked
    until a joint-likelihood or copula/latent-variable contract is designed.
    This is research-scoped and should stay in the failure ledger until that
    contract exists; it is not required for the first power simulation.

## Sequencing Note For The Power Simulation

The power simulation does not need every tier. Tier A (the individual-difference
endpoint) and Tier C (skew-normal) are the highest-value additions to the model
surface for power claims. Tiers B and E broaden structured and scaling coverage.
Tier F is deliberately out of scope. Each slice must land its recovery and
coverage evidence (per its ADEMP sheet) before its surface enters a power grid,
following the same rule doc 46 applies to every admitted lane.
