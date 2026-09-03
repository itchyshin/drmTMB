# 260. `nlminb` stopping rules vs. the true optimum: a Newton polish (#1130)

Reader: anyone changing `drmTMB()`'s optimizer path, or debugging a fit whose
predictions disagree with another engine at extrapolated newdata by a small
(~1e-5) amount despite `nlminb()` reporting convergence.

## The problem

`stats::nlminb()`'s stopping rules (`control$rel.tol`, default `1e-10`, and
`control$x.tol`, default `1.5e-8`) trigger on a *relative* change in the
objective value or the step size across iterations. They do not look at the
gradient. On a surface that is flat or weakly curved in some direction --
for example a variance component identified by few groups, or any
combination of parameters with a near-singular Hessian at the optimum --
`nlminb()` can report `convergence == 0` ("relative convergence") while the
exact gradient at that point is still far from zero. The resulting
coefficients are close enough to the true MLE that most quantities look
fine, but the gap is large enough to fail a tight downstream comparison,
most visibly at extrapolated `newdata` points where a small coefficient
error is amplified by a large predictor value.

Issue #1130 (DRM.jl #609) surfaced this on `bf(y ~ x + (1 | g), sigma ~ x)`
fit to a 144-row, 12-group fixture: predicted `mu` at `newdata x = 0.8`
disagreed with DRM.jl's own (independently verified, gradient-norm-based)
optimum by `1.086e-05`, against a `4e-6` cross-engine parity bar.

## What was measured

Fixture: `tests/testthat/fixtures/s10-varying-scale.csv` (copied from DRM.jl
branch `fix/563-s10-lss-ranef-gtol` @ `744d28b3`,
`test/parity/lss-ranef-varying-scale/data.csv`), fit with
`bf(y ~ x + (1 | g), sigma ~ x)`.

**Reproduction on this branch's base (before this change).** The default
`nlminb()` fit reports `convergence == 0` ("relative convergence (4)"), but
the exact TMB outer gradient at `opt$par` (`obj$gr(opt$par)`) has 2-norm
`3.46e-4`, max component `2.94e-4` -- not small. This is the coefficient set
that had been baked into the DRM.jl test fixture as the "R oracle" (it
matches by construction, since the oracle *was* drmTMB's default output).

**Mechanism (a)/(b): tighten `nlminb`'s own `rel.tol`/`x.tol`.** Re-running
with `control = list(rel.tol = 1e-14, x.tol = 1e-14)` moves the intercept by
`1.053e-5` -- but nlminb now reports `convergence == 1`
("singular convergence (7)"), and the exact gradient at the new point is
`2.18e-4`, similar magnitude to before, not smaller. The new point is *not*
closer to a verified stationary point; it is nlminb's finite-difference-based
internal machinery losing precision at that tolerance and stopping for a
different (and less trustworthy) reason. This was tested globally and
restricted to location-scale fits (a `sigma` formula with covariates,
mechanism (b)); both share the same failure mode because the fragility is in
`nlminb`'s own stopping logic, not in which fits it is applied to. **Rejected**:
unreliable, and the non-zero convergence code it produces would need special-
casing (the "trap" below) for no real gain.

**Mechanism (c): a Newton polish using the exact TMB gradient.** `obj$gr()`
is TMB's exact outer gradient (up to the inner Laplace solve's own
precision), independent of `nlminb`'s internal finite-difference machinery.
Building a numerical Hessian by finite-differencing that exact gradient
(`stats::optimHess(par, obj$fn, obj$gr)`) and taking a Newton step from
`nlminb`'s reported optimum:

| step | step norm | new gradient (max abs) |
|---|---|---|
| 0 (nlminb default) | -- | 2.94e-4 |
| 1 | 1.077e-5 | 1.79e-9 |
| 2 | 8.60e-11 | 3.46e-14 |

One step already drives the gradient to `1.79e-9`; a second step reaches
machine precision. The step-1 movement (`1.077e-5`) matches the magnitude of
both the #1130 cross-engine gap (`1.086e-5`) and the mechanism-(a) movement
(`1.053e-5`) -- all three numbers describe the same true shortfall, seen from
different diagnostics. After the polish, predicted `mu` at `newdata x = 0.8`
differs from the DRM.jl-fixture "R oracle" (drmTMB's *unpolished* default
output) by `1.086e-5` -- matching the originally reported cross-engine gap
almost exactly, without ever running DRM.jl. This is strong self-consistency
evidence that the polish lands on the same optimum DRM.jl independently
verified.

**Chosen: mechanism (c).** It is immune to the relative-objective stopping
pathology (it stops only on the actual gradient), it is cheap (below), and it
does not require special-casing a non-zero convergence code from nlminb.

### Cost (same machine, `OPENBLAS_NUM_THREADS=1`, median of 3-5 fits, `devtools::load_all()`)

| fit | `newton_polish = FALSE` | `newton_polish = TRUE` | delta |
|---|---|---|---|
| small Gaussian, no RE (n=60, 3 fixed params) | 0.017 s | 0.018 s | +0.001 s |
| location-scale (#1130 fixture, n=144, RE, 5 params) | 0.120 s | 0.136 s | +0.016 s |
| phylogenetic random intercept (n=192, 4 fixed params) | 0.142 s | 0.120 s | within noise |

The already-converged small fit is skipped by the `grad_tol` short-circuit
(no Hessian is built at all). The location-scale fit pays for one
`optimHess()` call (`~2 * length(par)` extra gradient evaluations); at
`length(par) = 5` that is ~15 ms. The phylo fit shows no measurable cost at
this `n_tip = 32`, `4`-fixed-parameter scale. Cost scales with the number of
*fixed* parameters (`optimHess()` is O(`length(par)`) gradient evaluations,
each of which re-solves the inner Laplace problem for random-effects
models), capped by `max_iter = 3`; it is not measured here for
high-dimensional fixed-effect surfaces (for example per-tip fixed effects or
a wide `factor()` design). `drm_control(newton_polish = FALSE)` opts out.

## The convergence-code decision (the trap)

nlminb's `convergence` code and message describe *its own* stopping
criterion, not whether the returned point is a stationary point of the
TMB objective. Two situations were observed:

1. **`nlminb` reports `convergence == 0` but the polish still moves the
   point** (the #1130 case above). Reporting this fit as "converged" without
   the polish would be dishonest about the fit that was actually returned.
2. **Tightening `nlminb`'s own tolerances reports `convergence == 1`
   ("singular convergence")** while landing close to (in this case, within
   `3e-7` of) the true optimum. Trusting nlminb's code alone here would
   incorrectly discard a nearly-correct fit.

**Decision:** `drm_newton_polish()` ignores `nlminb`'s reported code
entirely as an input, and instead re-derives convergence from the one
criterion that means something across every fit -- the polished exact
gradient. If the polish drives `max(abs(gradient))` at or below `grad_tol =
1e-8` (default `max_iter = 3`), `opt$convergence` is set to `0L` with an
honest message identifying the polish
(`"converged (Newton polish; max |gradient| = ...)"`), regardless of what
`nlminb` originally reported. If the polish cannot reach that gradient
(Hessian not finite, step not finite, or the objective would get worse --
each a `break`, never a "worse" acceptance), `nlminb`'s original
`convergence`/`message` are left untouched, so a genuinely non-converged fit
still triggers `drm_warn_if_not_converged()` and is visible in
`fit$optimizer_attempts` / `check_drm()` exactly as before. This makes the
stored status honest in both directions: a nominally-"converged" nlminb
result that was not actually stationary is corrected, and a nominally
non-converged result that the polish cannot rescue stays flagged.

## Not covered here

- The non-Gaussian S9 cells (DRM.jl #606; Bernoulli and ordinal theta gaps
  ~1e-5) and the prediction "factors" case are suspected to be the same
  class of shortfall (a flat/weakly-curved likelihood surface plus
  `nlminb`'s relative stopping rule), but were not re-measured here. The
  Newton polish mechanism generalizes to those families (it only needs
  `obj$fn`/`obj$gr`), but its cost on their specific parameter counts and
  inner-solve costs has not been measured.
- Cost on high-dimensional fixed-effect surfaces (many fixed parameters,
  where `optimHess()`'s `O(length(par))` extra gradient evaluations would be
  more expensive) was not measured; `newton_polish = FALSE` remains the
  escape hatch.
- `R/julia-bridge.R`'s `drm_julia_translate_control()` does not include
  `newton_polish` in its "TMB-only, abort if non-default" field list (it is
  a no-op under `engine = "julia"` either way, since that path never touches
  `nlminb`/`obj$gr`/`obj$fn`); adding it there is out of this leaf's scope
  (`R/julia-bridge.R` is not owned here).

## Implementation

- `drm_newton_polish()` (`R/drmTMB.R`, next to `drm_optimize_with_preset_retry()`):
  the polish itself.
- Call site: `drm_fit_spec()` (`R/drmTMB.R`), immediately after
  `drm_optimize_with_preset_retry()` returns and before
  `drm_warn_if_not_converged()`, so a downgraded-to-honest convergence code
  is what the warning and every downstream consumer (`fit$opt`,
  `fit$optimizer_used`, `check_drm()`) sees.
- `drm_control(newton_polish = TRUE)` (`R/control.R`): opt-out flag,
  documented default and rationale.
- Regression tests: `tests/testthat/test-optimizer-tolerance.R` (self-
  contained; no DRM.jl dependency). Fixture:
  `tests/testthat/fixtures/s10-varying-scale.csv`.
