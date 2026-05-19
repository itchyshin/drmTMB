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
