# Phase 18 Simulation Programme

Phase 18 is the evidence layer for `drmTMB`: simulation, power, accuracy,
coverage, runtime, and failure-mode reporting. It should follow the ADEMP
structure of Morris, White, and Crowther (2019) and the transparent-reporting
items of Williams et al. (2024), but it should stay practical for ecology,
evolution, and meta-analysis readers.

The first rule is scope. A surface enters the comprehensive simulation only
after it has a fitted likelihood, parser validation, extractors, diagnostics,
interval status, and focused recovery tests. Surfaces that are still only
planned belong in the failure ledger, not in a broad simulation table.

## A - Aims

Primary aim: quantify when fitted `drmTMB` surfaces recover scientifically
interpretable distributional parameters with acceptable bias, coverage, and
diagnostic behaviour.

Secondary aims:

- estimate power for effects on `sigma`, `rho12`, random-effect SDs,
  structured-effect SDs, and direct-SD models under realistic eco-evo sample
  sizes;
- compare narrow `drmTMB` surfaces with standard practice where a comparator is
  defensible, such as Gaussian meta-analysis with known `V`;
- record failure rates, boundary hits, non-positive-definite Hessians, and
  unsupported surfaces instead of silently dropping hard cases.

## D - Data-Generating Mechanisms

Each DGP should be a small named surface, not a giant all-features grid. The
minimum first wave is:

| Surface | Current gate | DGP sketch | Vary first |
| --- | --- | --- | --- |
| Gaussian location-scale | Fitted | `y_i ~ Normal(mu_i, sigma_i^2)` with `mu ~ x` and `log(sigma) ~ z` | `n`, sigma slope, collinearity |
| Gaussian ordinary random effects | Fitted | `y_ij = mu_ij + u_j + e_ij`, optional slopes | groups, observations per group, SD size |
| Gaussian ordinary q=3 random slopes | Fitted but advanced | `mu_ij = X beta + b_0j + x1 b_1j + x2 b_2j` with `(1 + x1 + x2 | id)` | groups, observations per group, slope SD, correlation |
| Gaussian residual-scale random slopes | Fitted independent slope | `log(sigma_ij) = X beta + w_ij a_j` with `(0 + w | id)` | groups, observations per group, scale-slope SD |
| Gaussian location-scale covariance | Fitted | matched `mu`/`sigma` random intercept blocks | group count, correlation, SD ratio |
| Bivariate Gaussian coscale | Fitted | two responses with `sigma1`, `sigma2`, and `rho12` | residual correlation, missing rows excluded |
| Phylogenetic and spatial Gaussian | Fitted subsets | known relatedness or coordinate covariance plus Gaussian residuals | number of taxa/sites, signal size |
| Structured one-slope parity | Spatial fitted; phylo/animal/relmat planned | coordinate spatial `mu` one-slope only in Wave A | sites, slope-field SD, covariate spread |
| Coordinate spatial one-slope smoke | Fitted smoke surface | `eta_mu = X beta + z0_site + x z1_site` with two independent coordinate-spatial fields | sites, observations per site, intercept-field SD, slope-field SD |
| Gaussian meta-analysis | Fitted | `y ~ MVN(mu, V + Omega_estimated)` with vector or matrix `V` | effect sizes, dense `V`, heterogeneity |
| Poisson `mu` random effects | Fitted smoke surface | log-mean count model with ordinary random intercepts and independent numeric slopes | groups, observations per group, mean count, SD size |
| NB2 `mu` random effects | Fitted smoke surface | log-mean overdispersed count model with ordinary random intercepts and independent numeric slopes; `sigma` remains fixed-effect overdispersion | groups, observations per group, mean count, overdispersion, SD size |

Later waves can add zero inflation, hurdle, ordinal, shape/skew, and
non-Gaussian scale/random-effect surfaces only after their focused gates are
closed. The NB2 `mu` random-effect row is admitted as a fitted smoke surface,
not yet as a full simulation grid or interval-coverage surface. The failure
ledger in
`docs/design/34-validation-debt-register.md` names the remaining blocked
surfaces.

The cross-distributional-parameter correlation gate in
`docs/design/45-cross-dpar-correlation-gate.md` is part of the same admission
rule. Residual `rho12`, group-level random-effect correlations, structured
random-effect correlations, and known sampling covariance `V` are different
layers. Phase 18 Wave A should not simulate random effects in `rho12`,
non-Gaussian covariance among `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`, or
`nu`, or slope-level cross-parameter covariance until the focused likelihood,
extractor, interval, diagnostic, and recovery gates exist.

Every DGP file should state the hierarchy, true fixed effects, random-effect
distributions, covariance labels, sampling covariance `V` when present,
interval target truths, varied conditions, and number of replicates per cell.

## E - Estimands

Store both the true value and the estimator output for each estimand:

| Class | Truth | Estimator output |
| --- | --- | --- |
| Fixed effects | DGP coefficient on the link scale | `coef(fit, dpar)` |
| Residual scale | response-scale `sigma` or sigma ratio | `sigma(fit)` or documented transform of `coef(fit, "sigma")` |
| Residual correlation | true `rho12` or mean true `rho12_i` | `rho12(fit)` and `profile_targets()` rows |
| Random-effect SD | true group-level SD | `sdpars` and direct profile target |
| Random-effect correlation | true block correlation | `corpars`, `corpairs()`, and profile target when direct |
| Known sampling covariance | supplied `V` | no estimator; it is input data and must not become an interval target |
| Derived quantities | repeatability, variance share, total observation variance | explicit formula from fitted components |

Replicate-specific truths should be saved when they depend on realised sample
sizes, realised `V`, or a generated covariance matrix.

## M - Methods

The first implementation should fit the intended `drmTMB` model, a simpler
nested `drmTMB` model when the question is power or false-positive rate, and at
most one external comparator per surface where the parameterization and
likelihood are close enough to be honest.

Do not create a comparator zoo. If `glmmTMB`, `brms`, `metafor`, ASReml, or
MCMCglmm cannot fit the same parameter target, the report should say that
directly rather than forcing an unfair comparison.

## P - Performance Measures

Each report should include the metric and its Monte Carlo standard error:

| Measure | Formula | Report with |
| --- | --- | --- |
| Bias | `mean(theta_hat - theta_true)` | MCSE of the mean |
| Relative bias | `mean((theta_hat - theta_true) / theta_true)` when denominator is stable | MCSE of the mean |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` | bootstrap or delta MCSE |
| Coverage | `mean(lo <= theta_true & theta_true <= hi)` | `sqrt(p * (1 - p) / n_sim)` |
| Power | `mean(ci_excludes_null)` or test rejection | binomial MCSE |
| Convergence | `mean(converged & pdHess)` | binomial MCSE |
| Boundary rate | `mean(check_drm_boundary_flag)` | binomial MCSE |
| Runtime | median and high quantiles | MCSE or bootstrap interval |

Coverage MCSE should be planned before running large grids. Coverage near 0.95
has MCSE about 1.0 percentage point with 500 replicates and about 0.7
percentage points with 1000 replicates. A pilot grid can use fewer replicates
if it is labelled as a pilot and does not make final coverage claims.

## Implementation Layout

Use a resumable layout:

```text
inst/sim/
  dgp/
    sim_dgp_gaussian_ls.R
    sim_dgp_meta_v.R
  fit/
    sim_fit_drmtmb.R
    sim_fit_comparators.R
  run/
    0_prepare_cells.R
    1_run_cells.R
    2_summarise_cells.R
  reports/
    phase18-gaussian-ls.qmd
    phase18-meta-analysis.qmd
```

Per-cell results should be saved as RDS files with replicate seeds, fit status,
warnings, elapsed time, `check_drm()` rows, interval status, and session info.
CRAN tests should only run smoke checks for seed stability and output shape.

## Williams-Style Self-Audit

| Item | Covered by this blueprint |
| --- | --- |
| 1. Aims | Named in the A section. |
| 2. Data-generating mechanisms | Named by surface with required DGP fields. |
| 3. Estimands | Truth and estimator output table. |
| 4. Methods | `drmTMB`, nested models, and limited comparators. |
| 5. Performance measures | Bias, RMSE, coverage, power, convergence, boundary, runtime. |
| 6. Software and settings | Required session info and seeds in per-cell output. |
| 7. Code availability | Planned under `inst/sim/` and rendered reports. |
| 8. Replicability | Per-cell RDS output and replicate-level seeds. |
| 9. Real-data motivation | Reports should pair each simulation wave with the relevant tutorial/example. |
| 10. Complete results | Failed fits, boundary hits, and diagnostics are reported, not dropped. |
| 11. Monte Carlo uncertainty | Every aggregate metric carries an MCSE or bootstrap uncertainty estimate. |

## First Three Slices

1. Slice 210 adds the `inst/sim/` skeleton, seed helper, cell registry, and
   one tiny CRAN-safe smoke test.
2. Slice 211 adds the Gaussian location-scale DGP and a pilot summariser that
   records truth, estimate, error, convergence, and Hessian status.
3. Slice 212 adds the Gaussian meta-analysis `meta_V(V = V)` DGP with vector
   `V`, dense matrix `V`, pilot summaries, and interval-target checks.
4. Slice 213 adds a resumable replicate runner with warning/error capture and
   optional per-replicate RDS output.
5. Slice 214 adds the first end-to-end Gaussian location-scale smoke surface,
   wiring registry, DGP, fit, summariser, saved output, and combined parameter
   table without yet making coverage or power claims.
6. Slice 215 adds the matching `meta_V(V = V)` smoke surface for vector and
   dense known sampling covariance cells, again stopping at per-parameter
   summaries rather than aggregate operating-characteristic claims.
7. Slice 216 adds the first parameter-level aggregation helper for bias, RMSE,
   empirical standard error, convergence, Hessian, warning, and elapsed-time
   summaries. Monte Carlo uncertainty and interval coverage remain separate
   follow-up slices.
8. Slice 217 adds Monte Carlo uncertainty helpers for mean error, RMSE, and
   proportions, plus an explicit interval-coverage summary that only runs when
   lower and upper interval columns are present.
9. Slice 218 wires the Gaussian location-scale smoke runner to the aggregation
   and MCSE helpers, giving the first tiny end-to-end bias/RMSE summary surface.
10. Slice 219 does the same for vector and dense `meta_V(V = V)` smoke cells,
    preserving the separation between known sampling covariance and fitted
    residual heterogeneity `sigma`.
11. Slice 220 adds a reader-facing smoke report template so aggregate outputs
    have a stable place for purpose, methods, reader checks, and interpretation
    boundaries before full evidence reports are claimed.
12. Slice 222 adds compact result manifests so saved or resumed runs can be
    audited without opening every per-replicate summary.
13. Slice 223 adds a warning/error ledger for replicate results so failed fits
    remain visible beside aggregate summaries.
14. Slice 224 adds result-directory loading so manifests and warning/error
    ledgers can be rebuilt from saved RDS output after a resumable run.
15. Slice 225 attaches manifests and warning/error ledgers to Gaussian
    location-scale and `meta_V(V = V)` summary-smoke outputs.
16. Slice 226 adds synthetic interval-coverage smoke plumbing. This validates
    the coverage summary path before real Wald, profile, or bootstrap interval
    producers are attached surface by surface.
17. Slice 227 updates the smoke report template so aggregate, manifest, and
    warning/error ledger CSVs have explicit reader-facing sections.
18. Slice 228 adds a skip-aware render test for the smoke report template using
    tiny aggregate, manifest, and warning/error ledger CSV fixtures.
19. Slice 229 records the interval-producer contract for Wald, profile, and
    bootstrap endpoints, including reported scale, method, failure status, and
    correlation-scale rules.
20. Slice 230 adds a generic Wald interval-table helper for summaries that
    already carry estimates and standard errors.
21. Slice 231 adds Fisher-z back-transformed Wald intervals for correlation
    summaries, complementing raw-rho Wald intervals from the generic helper.
22. Slice 232 adds fixed-effect standard errors to Gaussian location-scale pilot
    summaries when fitted models expose them.
23. Slice 233 attaches formula-coefficient Wald interval rows and coverage
    summaries to the Gaussian location-scale summary-smoke output.
24. Slice 234 adds standard errors to `meta_V(V = V)` pilot summaries for
    estimated `mu` coefficients and fitted residual `sigma`, while leaving
    known sampling covariance `V` out of interval targets.
25. Slice 235 attaches Wald interval rows and coverage summaries to the
    `meta_V(V = V)` summary-smoke output.
26. Slice 236 reconciles the random-slope pre-simulation promise: ordinary
    Gaussian `mu` q > 2 is fitted but advanced; Gaussian `sigma` is independent
    slopes only; coordinate spatial has one fitted `mu` slope; phylogenetic,
    bivariate slope, slope-level location-scale covariance, and non-Gaussian
    scale/shape random-effect slopes remain outside Phase 18 Wave A until
    their recovery gates close.
27. Slice 237 adds a CRAN-safe smoke surface for ordinary Gaussian `mu` q=3
    random slopes, including a seeded DGP, replicate runner, summary table,
    aggregate output, manifest, failure ledger, and tests.
28. Slice 238 adds a CRAN-safe smoke surface for Gaussian `sigma` independent
    one-slope random effects on `log(sigma)`, keeping correlated scale-slope
    covariance and labelled scale-slope blocks outside Wave A.
29. Slice 239 records the structured-slope parity gate: coordinate spatial has
    one fitted Gaussian `mu` slope, while phylogenetic, animal, and `relmat()`
    one-slope paths remain planned until they have implementation, diagnostics,
    profile targets, recovery tests, and biological examples.
30. Slice 240 records the cross-distributional-parameter correlation gate:
    residual `rho12`, constant fitted random-effect block correlations,
    predictor-dependent q=2 `corpair()` routes, and known sampling covariance
    `V` stay separate; non-Gaussian, slope-level, shape, inflation, hurdle,
    one-inflation, and `rho12` random-effect covariance surfaces remain outside
    Wave A until focused gates close.
31. Slice 241 adds a CRAN-safe smoke surface for the fitted coordinate spatial
    Gaussian `mu` one-slope path, including a seeded DGP, live `drmTMB()` fit,
    parameter summaries, aggregate output, manifest, failure ledger, and tests.
32. Slice 242 adds a CRAN-safe smoke surface for fitted ordinary
    non-zero-inflated Poisson `mu` random effects, covering random intercepts
    plus independent numeric slopes on the log-mean predictor.
33. Slice 243 attaches Wald interval rows and coverage summaries to the
    Poisson `mu` random-effect smoke output for fixed log-mean coefficients,
    while leaving random-effect SD rows visible as profile-needed interval
    failures until direct SD profile producers are attached.
34. Slice 244 attaches direct profile-likelihood interval rows and coverage
    summaries for the Poisson `mu` random-effect SD targets in the smoke output.
35. Slice 245 fits ordinary non-zero-inflated NB2 `mu` random intercepts and
    independent numeric slopes, exposes their SDs and direct profile targets,
    and keeps zero-inflated NB2, correlated/labelled NB2 slope blocks, and NB2
    `sigma` random effects outside Wave A.
36. Slice 246 adds a CRAN-safe smoke surface for fitted ordinary
    non-zero-inflated NB2 `mu` random effects, covering random intercepts plus
    independent numeric slopes on the log-mean predictor, while leaving Wald
    and profile interval coverage for follow-up slices.
37. Slice 247 attaches Wald interval rows and coverage summaries to the NB2
    `mu` random-effect smoke output for fixed log-mean and log-overdispersion
    coefficients, while leaving random-effect SD rows visible as profile-needed
    interval failures until direct SD profile producers are attached.
38. Slice 248 attaches direct profile-likelihood interval rows and coverage
    summaries for the NB2 `mu` random-effect SD targets in the smoke output.
39. Slice 249 adds a focused weak-SD boundary diagnostic for fitted NB2 `mu`
    random intercepts, exercising `check_drm()` lower-boundary reporting before
    larger NB2 grids vary the true random-effect SD.
40. Slice 250 records the pre-simulation readiness matrix in
    `docs/design/46-pre-simulation-readiness-matrix.md`, separating fitted,
    smoke-tested, interval-ready, weak-boundary-tested, planned, and blocked
    surfaces before broad simulation reports are written.
41. Slice 251 starts the first paired count pilot by combining the ready Poisson
    and NB2 `mu` random-effect smoke surfaces into one optional pilot output
    with aggregate, manifest, failure-ledger, Wald-coverage, and profile-
    coverage tables.
42. Slice 252 turns the Poisson and NB2 `mu` random-effect condition helpers
    into true grid builders, so optional pilots can cross group count, repeats,
    true random-effect SDs, fixed mean effects, and NB2 overdispersion settings.
43. Slice 253 adds the first Phase 18 plot-data helper, converting the paired
    count pilot into aggregate, coverage, manifest, and failure tables ready for
    Florence's later figure gallery.
44. Slice 254 adds the first count-pilot figure-gallery report template,
    rendering bias, RMSE, coverage, manifest, and warning/error sections from
    the plot-ready tables.
45. Slice 255 adds count-pilot gallery helpers that write the plot-ready CSV
    inputs and render a checked local HTML gallery artifact from a paired count
    pilot object.
46. Slice 256 adds the end-to-end count-gallery smoke runner that runs a tiny
    paired count pilot, writes gallery inputs, renders the HTML gallery, and
    returns the pilot and artifact paths together.
47. Slice 257 applies the first Florence visual polish to the count-pilot
    gallery, including horizontal estimand labels, shared palette/theme
    helpers, captions, and MCSE-aware coverage ranges when available.
48. Slice 258 built the first pkgdown-facing count simulation diagnostics draft,
    but the public page is removed for now because it was narrower than the
    intended figure gallery. Count diagnostics should return later as part of a
    broader set of simulation result articles covering power, bias, coverage,
    runtime, convergence, and failures across continuous, proportion, count,
    and other data types.
49. Slice 265 adds `vignettes/simulation-plot-grammar.Rmd` as the first
    Simulation & Comparison article for operating-characteristic displays. The
    article uses illustrative fixtures across continuous, proportion, count,
    and meta-analysis examples to show bias, RMSE, coverage, power,
    convergence, runtime, and warning/error ledger plots. It is a display
    contract for later simulation reports, not final Phase 18 evidence.
