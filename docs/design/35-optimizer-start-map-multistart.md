# Optimizer, Start, Map, And Multi-Start Contract

## Purpose

`drmTMB` currently exposes optimizer controls through `drm_control()` and passes
them to `stats::nlminb()`. Slice 80 records the stricter contract needed before
the package exposes user starts, fixed parameters, fallback optimizers, or
multi-start fitting.

The central invariant is simple:

```text
All reported quantities must be functions of the selected optimum opt$par.
```

That includes coefficient extractors, `sdpars`, `corpars`, `summary()`,
`vcov()`, `TMB::sdreport()`, and profile-likelihood intervals. The TMB object
may contain mutable last-parameter state, so methods that call back into TMB
must re-pin that object to `fit$opt$par` before launching a profile.

## Current Public Contract

The only public optimizer entry point is:

```r
control = drm_control(
  optimizer = list(eval.max = 1000, iter.max = 1000)
)
```

Slice 274 adds named optimizer-budget presets without changing the default fit:

```r
control = drm_control(optimizer_preset = "careful")
control = drm_control(optimizer_preset = "robust")
```

These presets expand to explicit `nlminb()` `iter.max` and `eval.max` controls
and are stored on the fitted object as ordinary optimizer settings. User-supplied
`optimizer = list(...)` values override the selected preset when a fit needs a
specific budget.

For backward compatibility, plain lists remain optimizer-only controls:

```r
control = list(eval.max = 1000, iter.max = 1000)
```

Plain lists must not be used for future `drmTMB` model-control names. Slice 80
therefore reserves these names and errors if they appear in a plain optimizer
list:

```text
se
keep_data
keep_model_frame
keep_tmb_object
sparse_fixed
aggregate_gaussian
optimizer_preset
start
starts
start_from
warm_start
warm_starts
warm_start_from
map
fixed
fallback_optimizer
fallback_optimizers
optimizer_fallback
optimizer_fallbacks
multi_start
multistart
```

The error tells users to use `drm_control(...)` for `drmTMB` controls and
`control = list(...)` only for optimizer settings.

## Selected-Optimum Invariant

The fit path now has three selected-optimum anchors:

1. `stats::nlminb()` returns the selected fixed-parameter vector in `opt$par`.
2. `TMB::sdreport()` is called with `par.fixed = opt$par` when standard errors
   are requested.
3. The fitted object splits reported coefficients, random-effect SDs,
   correlations, and conditional random effects from
   `obj$env$parList(opt$par)`.

Slice 80 adds the fourth anchor: before any profile-likelihood call,
`drmTMB` pins the mutable TMB object state back to `fit$opt$par`. This protects
profiles from stale `obj$env$last.par` or `obj$env$last.par.best` state left by
earlier profiles, diagnostics, or user experimentation.

## Future Start Contract

User starts should not be a free-form replacement of the entire TMB parameter
list. The public interface should be namespaced by fitted parameter labels:

```r
drm_control(
  start = list(
    "fixef:mu:(Intercept)" = 0,
    "fixef:sigma:(Intercept)" = log(0.5),
    "sd:mu:(1 | id)" = 0.3,
    "cor:mu:cor((Intercept),x | id)" = 0
  )
)
```

Design constraints before implementation:

- starts must be checked after formula parsing, because valid names depend on
  the fitted family, distributional parameters, random-effect terms, and
  structured effects;
- starts must be transformed to the internal unconstrained scale before TMB
  sees them;
- unknown names must error before optimization;
- partial starts should update only named targets and leave family builders in
  charge of the remaining robust defaults;
- random-effect latent starts should remain internal until there is a clear
  biological use case and simulation evidence.

## Future Simpler-Fit Warm-Start Contract

Warm starts from a simpler fitted model are useful only if they are explicit and
auditable. Slice 275 reserves warm-start control names but does not implement
them. A future interface might look like:

```r
fit_mu <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)

fit_location_scale <- drmTMB(
  bf(y ~ x, sigma ~ z),
  data = dat,
  control = drm_control(start_from = fit_mu)
)
```

The intended ladder is from simpler to richer models:

1. location-only to location-scale;
2. fixed-effect location-scale to ordinary random-effect models;
3. univariate or response-specific fits to bivariate Gaussian fits;
4. ordinary Gaussian fits to structured phylogenetic or spatial fits only after
   the target structured surface has its own diagnostics and recovery tests.

Design constraints before implementation:

- the source fit must have the same response family or an explicitly supported
  simpler-to-richer route;
- response names, distributional parameters, factor contrasts, offsets, and
  complete-case row handling must be checked before parameters are copied;
- copied parameters must use the same public target namespace as `start`, then
  transform to the internal unconstrained scale;
- any target not present in the simpler fit must use the richer model builder's
  ordinary start;
- the fitted object must record the source call, source family, copied target
  names, skipped target names, and the final optimizer result;
- `check_drm()` should report that a warm start was used, but inference should
  still be based only on the selected optimum of the final model;
- unsupported warm-start routes must error before optimization.

## Slice 373-390 Q2 Source-Start Evidence

Slices 373-390 tested the future warm-start idea on Ayumi's bivariate
phylogenetic species-effect stress case without exposing any public start API.
The developer-only prototype compared six or eight source strategies for a
row-capped bivariate Gaussian q2 phylogenetic target:

- the current default start;
- default covariance starts with modest jitter;
- fixed/residual source starts;
- ordinary species q2 source starts;
- aggregate phylogenetic q2 source starts;
- aggregate phylogenetic q2 source starts with modest covariance jitter.

The source-fit ladder showed the distinction that matters for the public
contract. Fixed/residual source models and aggregate phylogenetic q2 source
models can converge on 80, 300, and all 6,196 species. Ordinary row-capped
species q2 source models false-converged with residual `rho12` at the boundary.
When those source fits were copied into the row-capped phylogenetic q2 target,
every target fit still false-converged and residual `rho12` landed essentially
at `+/-1`.

| Species subset | Target rows | Tested target starts | Main target signal |
| --- | ---: | ---: | --- |
| 80 species | 395 | 8 | all false convergence; residual `rho12` at 1 |
| 300 species | 1,431 | 8 | all false convergence; residual `rho12` at `+/-1` |
| 6,196 species | 29,489 | 6 | all false convergence; residual `rho12` at 1 |

The full-species run is the strongest negative result so far. Larger species
coverage helped the aggregate phylogenetic q2 source fit, but it did not rescue
the row-capped target because residual response-response covariance and
phylogenetic species covariance remained poorly separated. Starts and jitter
changed objective values, gradients, and fitted phylogenetic correlations; they
did not produce a trustworthy non-boundary optimum.

This evidence changes the warm-start design in three ways:

- source-fit starts should be treated as diagnostics before they are treated as
  convenience controls;
- a future public `start_from` route must record copied, skipped, and jittered
  targets because a source fit can move the optimizer to a different bad
  boundary;
- the first implementation should probably be deterministic restart from the
  reported optimum, then an all-fit-style comparison table, before stochastic
  multi-start is exposed.

Regularization is a separate estimator, not a hidden start strategy. The
mixed-model literature supports maximum-a-posteriori or penalized likelihood
for weak variance and covariance components, and TMB-family packages such as
`glmmTMB` and `sdmTMB` expose priors as penalized likelihood/MAP tools. If
`drmTMB` later adds a residual-correlation or structured-correlation penalty,
the output should be labelled as penalized/MAP, with a documented base model,
scale, sensitivity check, and simulation coverage. It must not be described as
ordinary maximum likelihood with better starts.

## Future Bootstrap And Parallel Refit Contract

Slice 391-402 added a developer-only parametric bootstrap prototype for the
correct Ayumi Mass + Beak PV2 locphylo target. Slice 403-412 extended the same
prototype to the block-diagonal phylogenetic fallback and capped worker use at
10 cores. The prototype confirms that bootstrap is a practical refit and audit
path when `TMB::sdreport()` or the Hessian is unavailable. It becomes a
scientific uncertainty path only after the selected optimum is defensible. The
fallback smoke run shows the danger case: it refitted all 10 replicates, but
every replicate retained convergence code 1 and the scale-scale phylogenetic
correlation stayed essentially at `-1`.

The core invariant remains the same as for starts and profiles:

```text
Every bootstrap or profile refit must report the selected optimum, convergence
status, gradient or diagnostic status, and the refit target values.
```

Bootstrap must not hide model-geometry decisions. In the Mass + Beak model,
body mass is both a response and the allometric covariate for Beak. The
prototype therefore splits the roles into `Mass_z` and `Mass_cov_z`: the former
is simulated as a response, while the latter remains fixed as the conditioning
covariate. Any public bootstrap route needs an equally explicit rule for
response variables that also appear as predictors.

Slice 423-432 added the matching positive-control run for the clean
`PV2_locphylo` Mass + Beak model. With the same `B = 10`, `multicore`, and
10-core cap, all ten refits returned convergence code 0, median maximum
gradient was 0.043, and the bootstrap summaries stayed near residual
`rho12 = -0.80` and phylogenetic `mu1`-`mu2 = -0.88`. The contrast with the
fallback run is the intended bootstrap contract: refits can support uncertainty
only when the selected model also passes convergence and gradient diagnostics.

Slice 509-518 applies the same bounded-worker rule to the developer-only
profile fallback helper. `DRMTMB_PROFILE_CORES` is capped at 10 and at the
number of selected targets, `DRMTMB_PROFILE_BACKEND` is recorded in preflight
metadata, and the script supports serial or Unix `multicore` profiling. It does
not advertise PSOCK profiling because fitted `TMB` objects carry external
pointers; cross-session workers would need a refit-or-rebuild contract before
that backend is trustworthy.

Parallel execution should be opt-in and bounded. A future API should support
serial execution for CRAN and reproducibility, plus local worker backends for
interactive work:

```r
confint(
  fit,
  method = "bootstrap",
  R = 500,
  parallel = "multicore",
  workers = 10,
  seed = 1
)
```

or an equivalent lower-level refit helper shared by bootstrap and profile
intervals. Design constraints before implementation:

- workers must default to one in tests and CRAN-facing examples;
- worker count must never silently exceed the requested number or the number of
  bootstrap/profile tasks;
- seed streams must be deterministic and recorded in the output;
- each replicate must carry convergence, objective, gradient or `check_drm()`
  status, and failure messages;
- fits with false convergence, boundary correlations, or large gradients should
  be retained as failed or warning replicates, not silently discarded;
- bootstrap intervals for a non-PD-Hessian model should be labelled as
  bootstrap intervals, not as Wald/profile replacements;
- q4 boundary fits should use bootstrap first as an instability diagnostic,
  and only later as an uncertainty summary if refits repeatedly land on a
  defensible optimum.

## Future Fixed-Parameter Or Map Contract

Fixed parameters and TMB maps are more dangerous than starts because they alter
the fitted model. The public contract should avoid raw TMB parameter names and
use the same target namespace:

```r
drm_control(
  fixed = list(
    "fixef:rho12:(Intercept)" = 0,
    "sd:mu:(1 | id)" = 0
  )
)
```

Design constraints before implementation:

- fixing a parameter must update degrees of freedom, profile targets,
  `vcov()`, `summary()`, and `check_drm()`;
- fixed random-effect SDs or correlations near a boundary should create a
  diagnostic note;
- fixed residual `rho12` must remain separate from latent group,
  phylogenetic, or spatial correlations;
- raw `map` objects should stay internal unless a developer-only escape hatch
  is explicitly approved.

## Future Fallback Optimizer Contract

Fallback optimizers should be deterministic and recorded in the fitted object.
Slice 276 reserves the remaining obvious fallback-control names but does not
implement fallback fitting. A future interface might look like:

```r
drm_control(
  optimizer = list(eval.max = 1000),
  fallback_optimizer = list(
    name = "optim",
    method = "BFGS",
    control = list(maxit = 1000)
  )
)
```

The first supported fallback set should be small and explicit: the primary
`nlminb()` path, then `stats::optim(method = "BFGS")`, then
`stats::optim(method = "L-BFGS-B")` only if the unconstrained internal parameter
scale and any box constraints are explicitly reconciled. Fallbacks must not run
by default for ordinary fits.

The selected optimizer must be recorded with:

- optimizer name and settings;
- starting parameter vector;
- convergence code and message;
- objective value;
- fixed-gradient summary;
- whether the selected optimum came from the primary or fallback optimizer.

`summary()`, `vcov()`, profiles, `check_drm()`, and extractors must use the
selected optimizer result, not whichever optimizer ran last.

The comparison record must include every attempted optimizer, not only the
winner:

- optimizer name and method;
- control settings;
- convergence code and message;
- objective value;
- maximum absolute fixed-gradient value when available;
- elapsed time;
- whether the attempt was eligible for selection;
- a reason when an attempt was rejected.

The winner should be the converged eligible attempt with the lowest objective,
with a deterministic tie rule. If no attempt converges, the fit may still return
the best attempted optimum only if `check_drm()` clearly reports the fallback
failure state and all inference remains tied to that selected optimum.

## Future Multi-Start Contract

Multi-start should be a cautious diagnostic tool, not a default fitting mode.
A future interface should make the search finite and reproducible:

```r
drm_control(
  multi_start = list(
    n = 10,
    seed = 1,
    jitter = list("fixef:sigma:(Intercept)" = 0.5)
  )
)
```

Required safeguards:

- every start should be recorded with objective value, convergence status, and
  maximum fixed-gradient value;
- the winning run is the converged run with the lowest objective, with a clear
  rule for ties and non-converged runs;
- the final fit stores the winning `opt$par` and pins all TMB callbacks to it;
- `check_drm()` should report if several starts converged to meaningfully
  different optima;
- stochastic starts require a stored seed and reproducible jitter rule.

## Tests Required Before Public Starts Or Maps

- malformed start names error before optimization;
- partial starts alter the intended internal start only;
- fixed parameters reduce degrees of freedom and are absent or marked fixed in
  `vcov()`;
- profile targets respect fixed parameters;
- fallback and multi-start fits report the selected optimizer and selected
  `opt$par`;
- `TMB::sdreport()`, profile intervals, summaries, and extractors all agree
  with the selected optimum after deliberately perturbing mutable TMB object
  state in tests.

## Current Slice 80 Boundary

Slice 80 does not implement public starts, fixed parameters, fallback
optimizers, or multi-start fitting. It reserves the public names, documents the
contract, and tests the selected-optimum invariant for the current
single-optimizer path. Slice 274 adds only single-optimizer budget presets.
Slice 275 reserves warm-start names and documents the simpler-fit contract.
Slice 276 reserves fallback-optimizer names and documents fallback comparison
provenance. Neither slice adds user starts, warm starts, maps, fallback
optimizers, or multi-start fitting.
