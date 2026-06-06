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

## Capability Status: Three Distinct Categories

Read this first — it is the distinction most likely to be confused.

1. **Implemented (fitted).** The model fits and returns estimates, with
   extractors, diagnostics, and interval status. This is the real "capability"
   surface. See the Readiness Snapshot below and doc 46 for the full list.
2. **Simulation-evidence (lanes).** Recovery/coverage simulation lanes that
   *measure* an already-implemented surface (bias, RMSE, MCSE, coverage). A lane
   adds **no new model capability** — it only quantifies accuracy for a model
   that already fits. On 2026-06-05, GitHub Actions ran the newly wired formal
   lanes at 500 replicates per cell. The q2 scale, q2 scale-slope,
   slope-only `mu1`/`mu2`, Poisson `mu`, and NB2 `mu` lanes produced usable
   operating-characteristic artifacts, with NB2 retaining overdispersion and
   profile-SD cautions. The q4 and q6 bivariate Gaussian location lanes
   produced weak formal artifacts and remain smoke/diagnostic surfaces rather
   than recovery-ready surfaces. The same-response q2 `mu`/`sigma` slope lane
   now has local smoke/recovery writers, Actions dispatch, and a completed
   local 500-replicate diagnostic audit, but that audit does not support
   power-grid use; a follow-up robust-refit audit did not rescue any of the
   130 weak fits, while two clean representative fits showed endpoint-profile
   feasibility for the direct q2 targets.
3. **Not-yet-fitted (the gap).** Capabilities that require new TMB likelihood
   work and do not fit today. These are the ordered tiers in this note and the
   whole point of the local-R session.

| Capability | Category |
| --- | --- |
| Gaussian fixed-effect + location-scale; ordinary `mu` intercepts/slopes/q>2 blocks; independent `sigma` slopes | Implemented |
| Bivariate Gaussian: residual `rho12`; `mu1`/`mu2`, same-response `mu`/`sigma`, and `sigma1`/`sigma2` random-**intercept** covariance; slope-only `mu1`/`mu2`, same-response `mu`/`sigma`, and q4/q6 `mu1`/`mu2` **location** blocks; q2 `sigma1`/`sigma2` scale-slope blocks | Implemented (same-response q2 and q2 scale-slope rows have smoke/recovery writers; q4/q6 correlations are derived-interval-unavailable) |
| Recovery/coverage for the bivariate Gaussian + Poisson/NB2 `mu` surfaces | Simulation-evidence (formal Actions artifacts exist for the seven 2026-06-05 lanes; q4/q6 are weak and not promotion evidence) |
| Ordinary non-Gaussian (`Poisson`/`NB2`/`Student`/`lognormal`/`Gamma`/`beta`/`beta_binomial`/`truncated_nbinom2`) `mu` intercepts + **independent** slopes; NB2 log-`sigma` intercept; q=1 structured intercepts | Implemented |
| **q8** endpoint | **Not-yet-fitted** |
| **Correlated** non-Gaussian slopes; labelled non-Gaussian covariance (q2/q4); non-Gaussian q4/q6/q8 blocks | **Not-yet-fitted** (registry `count_labelled_q2_q4` is `blocked`) |
| skew-normal; structured slopes beyond one `mu` slope; `rho12` random effects; large-data; mixed-response bivariate | **Not-yet-fitted** |

So: **q4/q6 exist only for bivariate *Gaussian location*, q2 same-response
`mu`/`sigma` and q2 scale-slope `sigma1`/`sigma2` exist as first slices, q8 is
design-only, and there is no non-Gaussian random-slope correlation or
q4/q6/q8 block at all.**

## Recommended Working Order

A single flat sequence for the local-R session. Phase A is capability
implementation (TMB); Phase B runs the evidence; Phase C is comparator and
release. Items marked *(parallel)* have no dependency and can be picked up any
time.

**Phase A — implement capabilities (local TMB), in this order:**

1. q8 all-endpoint block — Tier A.2; depends on same-response q2 slope
   evidence. *(Completes the
   individual-difference covariance endpoint, the package's headline goal.)*
2. *(parallel)* `skew_normal()` fixed-effect first slice — Tier C;
   implementation-ready, independent of Tier A, good early win.
3. Structured `mu` slopes + slope correlations — Tier B: phylogenetic, then
   coordinate-spatial, then `animal()`/`relmat()` (with bivariate genetic
   covariance).
4. Correlated non-Gaussian slopes and labelled non-Gaussian covariance —
   currently `blocked`; needs a likelihood-design gate before code.
5. Random effects in `rho12` — Tier D; needs its own gate first.
6. *(parallel)* Large-data: sparse fixed effects, sufficient-statistic
   aggregation, 1M-row benchmarks — Tier E.
7. Mixed-response bivariate — Tier F; research-scoped, **defer** (not needed for
   the first power simulation).
8. *(parallel, inference engine — not a model surface)* Gaussian variational
    approximation (GVA), an accuracy-oriented alternative to Laplace for
    non-Gaussian random-intercept models — Tier G; independent of Tiers A–F.

**Phase B — run the evidence (local R / Actions):** for each implemented surface,
run its recovery/coverage lane at formal replicate count (the ADEMP sheets name
the counts), audit the artifacts, and promote the matching row in doc 46 only
when the evidence supports that promotion. The first seven lanes listed above
were run on Actions on 2026-06-05. They support the q2 scale, q2 scale-slope,
slope-only `mu1`/`mu2`, Poisson `mu`, and cautious NB2 `mu` rows, but they do
not support q4/q6 bivariate location promotion. The same-response q2
`mu`/`sigma` slope route now has its own smoke/recovery writer and Actions
task. Its 2026-06-06 local 500-replicate formal audit produced complete
manifest artifacts, but convergence/positive-Hessian rates of 0.856 and 0.884
plus all-replicate fixed-effect Wald coverage of 0.796-0.850 keep it out of
power-grid use. The follow-up hardening audit did not rescue the 130 weak
false-convergence fits; among interval-available converged fits, fixed-effect
Wald coverage was 0.930-0.972. Endpoint profiles succeeded on two clean
representative fits for `rho12`, both slope SDs, and the same-response
correlation, but broad profile/bootstrap coverage remains unrun.

**Phase C — comparator and release:** run the Phase 19 comparator matrix
(`docs/design/158-...`) on shared datasets with the tabulated scale conversions,
then the 0.2.0 release checklist (`docs/design/159-...`) including the
profile-likelihood demonstration article.

**Then:** the big power simulation, covering whichever Phase A surfaces have
passed Phase B recovery/coverage. The q8 endpoint, a stronger same-response q2
interval/convergence lane, and the parallel skew-normal first slice are the
highest-value additions for power claims.

## Readiness Snapshot

Fitted today (see doc 46 for the full matrix): Gaussian fixed-effect
location-scale; ordinary Gaussian `mu` intercepts, `q > 2` slopes, and
independent `sigma` slopes; selected bivariate `mu1`/`mu2`, same-response
`mu`/`sigma`, and `sigma1`/`sigma2` random-intercept covariance blocks;
slope-only and q4/q6 `mu1`/`mu2` location blocks (smoke, with weak q4/q6 formal
artifacts); the first same-response q2 `mu`/`sigma` slope block with
smoke/recovery writers; the first q2 `sigma1`/`sigma2` scale-slope block;
residual
`rho12`; `meta_V(V = V)`; coordinate-spatial,
phylogenetic, `animal()`, and `relmat()` Gaussian `mu`/`sigma` intercepts plus
one `mu` slope; ordinary Poisson/NB2 `mu` random effects and q=1 structured
intercepts; the fixed-effect non-Gaussian family set; fixed-effect ordinal.

The remaining evidence and capability gaps below are what stand between that
surface and the "all capabilities planned" milestone. The q2 `sigma1`/`sigma2`
scale-slope route and the same-response q2 `mu`/`sigma` smoke/recovery route
now serve as evidence for the next all-endpoint individual-difference slice.

## Tier A — Individual-Difference Covariance Endpoint (#5, #33)

This is the flagship: correlating individual differences in average response,
plasticity, residual variability, and its change. Finish it in order.

1. **Same-response location-scale slope covariance (`mu1`/`sigma1` slopes).**
   - Gate: `docs/design/28-double-hierarchical-endpoint.md` (step 5) and the
     "q2 same-response location-scale slope" row in
     `docs/design/67-sdstar-p8-poisson-q1.md`. High identifiability risk — needs
     many observations per group.
   - The first slice is implemented for matching same-response slope-only
     labels and now has smoke/recovery writers plus Actions dispatch; completed
     formal artifact audit and power-grid evidence remain separate follow-up
     evidence.
2. **q8 all-endpoint block.**
   - Gate: `docs/design/67-sdstar-p8-poisson-q1.md`; registry row
     `bivariate_gaussian_q8_endpoint` (currently `design_only`).
   - Depends on same-response location-scale slope evidence. Keep q8 correlations
     `derived_interval_unavailable` until a validated interval method exists.

## Tier B — Structured Random Slopes (#33, #147)

3. **Phylogenetic `mu` slopes beyond the first; slope correlations.**
   - Gate: `docs/design/44-structured-slope-parity-gate.md`,
     `docs/design/148-phase6c-structured-one-slope-ademp.md`.
4. **Coordinate-spatial `mu` slope correlations** (one independent slope is
   already fitted). Same parity gate.
5. **`animal()`/`relmat()` slopes and bivariate genetic covariance (#147).**
   - Gates: `docs/design/54-...`, `55-...`, `58-phase-18-animal-relmat-q4-ademp.md`.
   - Includes sparse large-pedigree precision construction (overlaps Tier E).
6. **Residual-scale structured slopes**.

## Tier C — Location-Scale-Shape Family (#3)

7. **`skew_normal()` fixed-effect first slice.**
   - Gates: `docs/design/127-...parameterization-decision`,
     `128-...test-contract`, `132-...implementation-gate`,
     `123-...source-map`. The parameterization and test contract are decided;
     this slice is implementation-ready.
   - Scope: univariate fixed-effect `mu`/`sigma`/`nu` only; no random or
     structured effects in the first slice.

## Tier D — Random Effects in `rho12` (#5 boundary)

8. **Random intercepts in `rho12`**, kept distinct from group-level covariance.
   - Boundary: `docs/design/45-cross-dpar-correlation-gate.md`. Needs its own
     gate before likelihood work; currently only fixed-effect/predictor `rho12`
     is fitted.

## Tier E — Large-Data Readiness (#4)

9. **Sparse fixed-effect matrices** with dense-vs-sparse parity tests, Gaussian
    sufficient-statistic aggregation, and 1M-row / high-species benchmarks.
    - Gate: `docs/design/23-large-data-memory.md`. Benchmarks need a real
      machine, not the sandbox.

## Tier F — Mixed-Response Bivariate (#5 boundary)

10. **Mixed-response bivariate families** (e.g. Gaussian-count) remain blocked
    until a joint-likelihood or copula/latent-variable contract is designed.
    This is research-scoped and should stay in the failure ledger until that
    contract exists; it is not required for the first power simulation.

## Tier G — Gaussian Variational Approximation (inference engine)

12. **Gaussian variational approximation (GVA).** An accuracy-oriented
    alternative latent-variable integration method, for non-Gaussian
    random-intercept models where the Laplace approximation is biased
    (Bernoulli/low-count Poisson, small clusters). Maximizes an ELBO with a
    Gaussian `q(u) = N(m, S)` instead of expanding around the conditional mode.
    - Gate: `docs/design/160-gaussian-variational-approximation-gate.md`.
    - This is an **inference-engine** addition, not a model-surface tier: it
      adds an `inference = "gva"` path to the existing TMB template (Laplace
      stays default), so it is independent of Tiers A–F and can proceed in
      parallel.
    - First slice: univariate `mu` random-intercept GLMM (Poisson, Bernoulli),
      Gaussian-prior expectation in closed form, data-term expectation by
      adaptive Gauss-Hermite quadrature, block-diagonal `S`.
    - Out of scope first slice: skew/non-Gaussian `q` (genuine skewness),
      mean-field VB, structured/low-rank `S`, structured/bivariate models,
      stochastic ELBO. Validate against a gold standard (high-order GH or MCMC)
      and label variational SEs as such.

## Sequencing Note For The Power Simulation

The power simulation does not need every tier. Tier A (the individual-difference
endpoint) and Tier C (skew-normal) are the highest-value additions to the model
surface for power claims. Tiers B and E broaden structured and scaling coverage.
Tier F is deliberately out of scope. Each slice must land its recovery and
coverage evidence (per its ADEMP sheet) before its surface enters a power grid,
following the same rule doc 46 applies to every admitted lane.
