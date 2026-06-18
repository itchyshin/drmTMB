# Numerical Guard Simulation Audit

## Motivation

Hao Qin flagged a legitimate release-risk question on 2026-06-16: some
constants in `src/drmTMB.cpp` look like hard-coded truncations. If a guard
silently changes the likelihood, it can create apparent numerical convergence
without a matching statistical justification. That concern should be tested,
not waved away.

The project position is:

- domain transforms are allowed when they define the legal parameter space;
- model-defining restrictions are allowed when the documentation says exactly
  what model is being fitted;
- starting-value floors are allowed when they only choose an initial point;
- likelihood-altering guards are diagnostic safeguards, not evidence that the
  fitted model is identified or inferentially reliable.

If a guard has little impact in the intended operating range, the feature can
remain useful, but users still need an honest explanation of the guard and a
diagnostic when it is active.

## Current Guard Classes

| Class | Examples | Interpretation | Simulation question |
|---|---|---|---|
| Domain transform | `rho12 = 0.99999999 * tanh(eta_rho12)` and random-effect correlation guards | Correlations must stay inside `(-1, 1)` so covariance matrices remain positive definite. The multiplier is a numerical guard near singularity. | Do estimates, intervals, and boundary diagnostics behave correctly for true correlations near 0, moderate values, and high `|rho|`? |
| Model-defining restriction | Student-t `nu = 2 + exp(eta_nu)` | The fitted Student-t route is a finite-variance model with `nu > 2`. It deliberately excludes infinite-variance tails. | How often do low-`nu` data push estimates to the boundary, and do diagnostics prevent overconfident interval claims? |
| Density-domain floor | beta and zero-one beta mean/shape epsilons, missing-data beta shape floors | These avoid evaluating beta densities exactly at illegal open-support boundaries. They are acceptable only when paired with response validation and boundary wording. | Are estimates unchanged away from support boundaries, and are boundary-near failures/warnings visible? |
| Tail log floor | skew-normal `log(Phi(nu * z) + 1e-300)` | Prevents `log(0)` in extreme tails while leaving ordinary likelihood values effectively unchanged. | Does the floor matter in strong-skew or outlier scenarios, and does it change sign or scale conclusions? |
| Likelihood-altering scale guard | Gaussian `log(sigma)` soft-clamp | This is a numerical overflow guard. It cannot create identifiability; if active at the optimum, the fit is a guarded diagnostic fit. | Compare disabled/default/wider/tighter clamp settings for bias, coverage, Hessian status, guard activation, and warning rates. |
| Starting-value floor | R-side `pmin()`/`pmax()` starts for probabilities, scales, counts, and missing-data predictors | These choose feasible starting values. They should not change the likelihood once optimization begins. | Verify that changing starts does not change the optimum for well-posed fits, and record when multiple starts expose local minima. |

## Big-Simulation Contract

The big simulation programme should include a numerical-guard sensitivity lane
before guard-dependent routes are used for public inference claims. The lane
should compare at least the default guard configuration with a less restrictive
or disabled configuration whenever the implementation allows it. For the
Gaussian `log(sigma)` clamp, compare:

- `logsigma_clamp = NULL`;
- the default identity-in-band clamp;
- a wider band;
- a narrower diagnostic band.

Each simulation cell should record:

- guard configuration and package SHA;
- whether the guard was active at the optimum or along failed evaluations when
  detectable;
- estimates, standard errors, log likelihood, objective, convergence code,
  `pdHess`, gradient diagnostics, warnings, and elapsed time;
- bias, RMSE, empirical interval coverage, MCSE, boundary flags, failures, and
  refit discrepancies across guard settings;
- the interpretation label: `diagnostic`, `parity`, `guard_sensitivity`, or
  `promotion`.

The acceptance rule is conservative. If guard activation is rare and estimates,
standard errors, log likelihood, and coverage agree within Monte Carlo error in
well-posed cells, the guard can remain a documented numerical safeguard. If a
guard frequently changes estimates, interval coverage, or model status, the
corresponding feature must stay diagnostic or experimental until the likelihood,
parameterization, or diagnostic workflow is redesigned.

## Formal ADEMP Design For The Next Guard Slice

The next slice should be a design-first simulation study, not a code-first
reaction to a list of constants. Use the ADEMP framework from Morris, White &
Crowther (2019) and the transparent simulation-reporting items from Williams et
al. (2024). The purpose is to decide whether each guard is a harmless numerical
safeguard in its intended operating range, a model-defining restriction that
needs clearer wording, or an inference-changing intervention that must keep the
feature diagnostic.

### A -- Aims

Primary aim: quantify whether each numerical guard changes point estimates,
log likelihood, Hessian status, intervals, or scientific conclusions in
well-posed cells where the fitted model is meant to be used.

Secondary aim 1: quantify what happens in edge cells where the guard is
expected to activate, so documentation can tell users whether an active guard is
a harmless warning, a diagnostic-only result, or a reason to refit after
rescaling or redesigning the model.

Secondary aim 2: distinguish legal parameter-space transforms from
likelihood-altering guards and starting-value floors, so the project does not
treat every numerical constant as the same kind of statistical decision.

### D -- Data-Generating Mechanisms

Each guard class gets its own DGP because the estimand and failure mode differ.
Do not mix them into one pooled "guard worked" conclusion.

| Guard lane | Ordinary cell | Edge cell | Stress cell | Notes |
|---|---|---|---|---|
| Correlation open-interval guard | `rho12` or random-effect correlation near 0 and 0.4 | true correlation near 0.9 | true correlation near 0.98 with small `n` | Check covariance conditioning, interval status, and boundary diagnostics. |
| Student-t finite-variance shape | `nu` around 8 | `nu` around 3 | data generated with `nu <= 2` as a misspecification stress | The fitted model is `nu > 2`; low-tail stress is a model-boundary check, not a promotion cell. |
| Support floors | beta, zero-one beta, or missing-predictor beta cells away from 0/1 | observations near open-support boundaries | malformed or boundary-heavy responses routed through validation | Pair every density floor with response-validation evidence. |
| Tail log floor | skew-normal with mild slant | strong slant plus moderate outliers | strong slant plus extreme outliers | Track whether the tail floor changes slant sign, scale, or fit status. |
| `log(sigma)` guard | ordinary and standardized scale cells | legitimate huge/tiny unstandardized scales | weakly identified or confounding-prone scale cells | Compare disabled/default/wide/tight settings only where the control exists. |
| Starting-value floors | well-posed fixed-effect cells | poor starts near parameter boundaries | multiple-start local-minimum stress | These should alter the path, not the target likelihood. |

The first formal grid should use a pilot tier before promotion language:

| Tier | Replicates per cell | Intended MCSE target | Allowed conclusion |
|---|---:|---|---|
| Smoke | 10--25 | none; code-path check only | artifact works or fails |
| Diagnostic pilot | 50--100 | detects large guard effects only | prioritize cells and warnings |
| Calibration pilot | 500 | coverage MCSE about 1 percentage point at 0.95 | cautious interval language for audited cells |
| Promotion grid | 1000 | coverage MCSE below 0.7 percentage points at 0.95 | headline claims only if failures and guard effects are also acceptable |

### E -- Estimands And Targets

For each replicate and guard setting, store the true value and estimate for:

- fixed-effect coefficients on their link and response scales;
- dispersion, shape, or correlation parameters affected by the guard;
- log likelihood, objective, AIC, and BIC when constants make those comparable;
- Hessian status, convergence code, gradient diagnostics, warnings, elapsed
  time, and whether the guard was active at the optimum when detectable;
- interval limits and target-specific interval status for Wald, profile, or
  bootstrap intervals when that interval method is part of the audited claim.

The headline comparison is not "did the optimizer converge?" The headline
comparison is whether guarded and reference configurations give the same
estimand, uncertainty, and decision within Monte Carlo error in cells where the
guard is meant to be inactive or practically irrelevant.

### M -- Methods

Fit the default `drmTMB` route and one reference route per guard class. A
reference route can be a disabled or wider guard when the public control exists,
a high-precision or better-scaled fit, or a comparator package only when the
comparator uses the same likelihood and parameterization. Do not use a
comparator to promote a route with different support, different constants, or a
different residual model.

Every fitted method row should record the package SHA, dirty state, operating
system, R version, package versions, seed, optimizer settings, number of
threads, and interpretation label: `smoke`, `diagnostic`,
`guard_sensitivity`, `calibration`, or `promotion`.

### P -- Performance Measures

For each condition and method, report:

- bias: `mean(theta_hat - theta_true)`;
- RMSE: `sqrt(mean((theta_hat - theta_true)^2))`;
- coverage: `mean(ci_lo <= theta_true & theta_true <= ci_hi)`;
- guard activation rate: `mean(guard_active)`;
- fit-success rate: `mean(converged & pdHess & finite_estimate)`, plus the
  separate convergence, `pdHess`, warning, and failure rates;
- guard-effect summaries: maximum and mean absolute differences in estimates,
  standard errors, log likelihood, AIC/BIC, interval limits, and decision
  labels between the default and reference fits;
- MCSE for every mean, bias, and coverage estimate.

The release threshold is intentionally conservative. A guard can be documented
as practically inactive only for a named cell when the guard activation rate is
near zero or scientifically expected, default-vs-reference differences are
small relative to MCSE and the inferential scale, and failure/warning rates do
not hide the problematic replicates.

## Williams 11-Item Self-Audit

| Item | Covered by this design? | Evidence to require before promotion |
|---|---|---|
| 1. Aims | Yes | Aim text in the artifact README and dashboard row. |
| 2. DGP | Partial | One DGP file and math block per guard lane. |
| 3. Estimands | Yes | Per-replicate truth columns for every audited target. |
| 4. Methods | Partial | Default and reference guard routes listed with exact controls. |
| 5. Performance measures | Yes | Bias, RMSE, coverage, MCSE, guard activation, and status rates. |
| 6. Software details | Required | SHA, dirty state, OS, R/package versions, seeds, and threads. |
| 7. Code availability | Required | `inst/sim/` runner plus artifact README. |
| 8. Data availability | Required | Per-cell CSV/RDS artifacts or explicit storage reason. |
| 9. Applied example | Planned | A small worked model showing how a user sees an active guard. |
| 10. Results reporting | Required | Include failures and warning rows; never drop failed fits silently. |
| 11. MCSE | Required | Every aggregate mean or coverage estimate reports MCSE. |

## Constant Classification Rule

The audit should classify constants by function before judging them. Constants
such as `0.5`, `2`, or `2 * pi` in standard density formulae are mathematical
constants, not numerical guards. Constants such as `0.99999999` in correlation
links, `1e-300` in tail log floors, `1e-12` support epsilons, and `1e-8` shape
floors are guard candidates. Each candidate needs an owner, an intended legal
range, a detectability plan, and a simulation decision rule.

## First Pilot: Fixed-Effect `log(sigma)` Clamp

The first executable slice is banked at
`docs/dev-log/simulation-artifacts/2026-06-17-logsigma-clamp-sensitivity-pilot/`.
It follows the ADEMP discipline from Morris, White & Crowther (2019) and the
transparent simulation-reporting checklist from Williams et al. (2024), but it is
a **diagnostic pilot**, not a promotion grid.

**Aim.** Test whether the configurable Gaussian `log(sigma)` clamp changes
fixed-effect location-scale fits when the default guard is inactive, and show
what happens when legitimate unstandardized scales live outside the default
band.

**Data-generating mechanisms.** Four Gaussian fixed-effect cells use
`mu_i = 0.2 + 0.5 x_i` and `log(sigma_i) = gamma_0 + gamma_1 x_i`, with
ordinary scale, large scale inside the default identity band, huge scale above
the default band, and tiny scale below the default band.

**Estimands.** The pilot tracks fixed-effect `mu` and `sigma` coefficients,
standard errors, log likelihood, AIC/BIC, optimizer convergence, `pdHess`, guard
activation, warning/error rows, and elapsed time.

**Methods.** Each replicate is fit with `logsigma_clamp = NULL`, the default
`c(-12, 12)` band with margin 3, and a wide `c(-25, 25)` band with margin 3.
Differences are computed against the unclamped fit from the same condition and
replicate.

**Performance measures.** The committed summaries report convergence and
`pdHess` rates, clamp activation rates, maximum absolute coefficient
differences, and maximum absolute log-likelihood/AIC/BIC differences. Coverage
is intentionally absent from this pilot; interval calibration remains a future
guard-sensitivity task.

Results from 25 replicates per condition:

| Cell | Default active rate | Default convergence rate | Default `pdHess` rate | Max default-vs-off `logLik` diff | Max default-vs-off `sigma` intercept diff | Max wide-vs-off `logLik` diff |
|---|---:|---:|---:|---:|---:|---:|
| Ordinary scale | 0.00 | 1.00 | 1.00 | 0 | 0 | 0 |
| Near default upper band | 0.00 | 1.00 | 1.00 | 2.046363e-11 | 1.168681e-08 | 0 |
| Above default upper band | 1.00 | 1.00 | 1.00 | 526.8952 | 32.38647 | 0 |
| Below default lower band | 1.00 | 0.00 | 1.00 | 118.9206 | 4.205839 | 0 |

This is exactly the honest pattern the project needs to show. In the audited
fixed-effect cells, the default guard is negligible when inactive. When the
default band binds, it can materially change estimates and log likelihood even
when a fit returns with an apparently useful status field. The wide band matches
the unclamped reference in all four cells, which supports the exposed
`drm_control(logsigma_clamp = ...)` knob for legitimately huge unstandardized
scales.

This pilot does **not** settle scale-side phylogenetic fields, bivariate
Gaussian scale routes, support floors, Student-t finite-variance restrictions,
correlation open-interval guards, profile/bootstrap intervals, or release
readiness.

## Second Pilot: Student-t Finite-Variance Boundary

The second executable slice is banked at
`docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/`.
It uses the same guard-audit discipline, but answers a different question: the
Student-t route is intentionally a finite-variance model with `nu > 2`, so the
diagnostic needs to show when fitted tail shape is close enough to the boundary
that ordinary interpretation should slow down.

**Aim.** Check whether the `student_nu` diagnostic reports ordinary,
near-boundary, and failed Student-t shape fits visibly enough for Phase 18
simulation summaries and applied tutorials.

**Data-generating mechanisms.** Two fixed-effect Student-t shape cells use
`n = 180`, `sigma_slope = 0.20`, `rho_xw = 0.2`, and 25 replicates per cell.
The ordinary cell has `nu(w = 0) = 8.0`; the low-tail cell has
`nu(w = 0) = 2.8`, close to the finite-variance boundary but still inside the
fitted model.

**Estimands.** The pilot tracks fitted `nu`, `student_nu` status/message,
convergence, `pdHess`, warning/error rows, coefficient bias, RMSE, MCSE, and
elapsed time.

**Methods.** Each replicate is fit with the default fixed-effect Student-t
shape path. There is no alternative infinite-variance reference route in this
pilot, because the public model is explicitly `nu > 2`.

**Performance measures.** The committed summaries report convergence and
`pdHess` rates plus `student_nu` ok, note, warning, and error counts. Coverage
and interval calibration are intentionally absent from this pilot.

Results from 25 replicates per condition:

| Cell | Convergence rate | `pdHess` rate | `student_nu` ok | `student_nu` note | `student_nu` warning | `student_nu` error |
|---|---:|---:|---:|---:|---:|---:|
| `nu(w = 0) = 2.8` | 0.92 | 0.88 | 17 | 0 | 5 | 3 |
| `nu(w = 0) = 8.0` | 1.00 | 1.00 | 15 | 10 | 0 | 0 |

This is diagnostic evidence for carrying the `student_nu` row beside model
comparisons and simulation summaries. It does **not** promote Student-t
coverage, power, profile/bootstrap intervals, random effects in `nu`, a
different tail model, or release readiness.

## User-Facing Rule

Do not let a numerical guard upgrade a fit. A guarded fit may avoid overflow
and preserve a useful point-estimate diagnostic, but it does not erase
non-convergence, a non-positive-definite Hessian, boundary status, weak
identification, or a failed profile/bootstrap/simulation check.

The documentation should say what the guard does, when it is expected to be
inactive, and how users can see whether it affected their model. That is more
useful than pretending the constants are invisible.
