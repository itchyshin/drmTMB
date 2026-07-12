# DO-T0a: Distributional-Output Foundation (`{d,p,q}` Registry, `fitted_distribution()`, Seed Contract)

## Purpose

This note documents the DO-T0a slice of the distributional output & adequacy
layer arc (issues #747/#748; ultra-plan:
`docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md`).
The reader is a future contributor implementing DO-T3's per-family rollout, or
a reviewer at the CP1 API-freeze gate, deciding whether the interface shape
below is stable enough to build `residuals(type = "quantile")`,
`predict(type = "quantile")`, and `exceedance()` on top of it.

DO-T0a delivers the **foundation only**: the registry interface, one promoted
reference family (gaussian), two feasibility spikes (tweedie, skew_normal)
that stress-test the interface against the two hardest CDFs in the family
set, and the Dunn-Smyth randomized-quantile-residual seed contract. It does
**not** roll out `{d,p,q}` for the other 15 model types -- that is DO-T3.

## Architecture decision (Emmy)

The `{d,p,q}` registry does **not** attach to the `drm_family()` constructor
object. Only 11 of 18 fitted `model_type` routes carry a `drm_family()`
object at all, and the repository already declined this unification once:
see the header comment on `drm_dpar_link()` (`R/methods.R:5057-5069`), which
explains why the canonical *runtime* link table is a `model_type`-keyed
`switch()` rather than a field on `drm_family()`.

`drm_family_dpq(object)` (new file `R/family-dpq.R`) mirrors that same
`switch()` shape, in the same `model_type` order, so a reviewer can diff the
two side by side when a family is promoted. Each case returns:

```r
list(
  dpars    = c("mu", "sigma", ...),  # native dpar names the closures read
  d = function(y, params) ...,       # density
  p = function(y, params) ...,       # CDF
  q = function(u, params) ...,       # quantile
  discrete = TRUE/FALSE,
  has_atom = TRUE/FALSE,
  status   = "reference" | "spike"
)
```

`params` is a wide (one row per observation) data frame of native dpar
estimates, built by `fitted_distribution_params()` from
[`predict_parameters()`](../../R/predict-parameters.R) (`R/predict-parameters.R:79`)
plus a `V_known` column (see below). `d`/`p`/`q` never see the fitted model
object directly -- only the per-row parameter table -- which keeps them
callable at arbitrary fixed `theta` for verification (DG2-style
cross-checks), not just at a fit's own fitted rows.

`fitted_distribution(object, newdata = NULL)` (S3 generic, `drmTMB` method)
is the shared accessor: it calls `drm_family_dpq()` once, builds `params`
once, and returns an S3 object of class `"drm_fitted_distribution"` carrying
`model_type`, `status`, `discrete`, `has_atom`, the wide `params` table, and
three one-argument closures `d(y)`, `p(y)`, `q(u)` already bound to `params`.
Downstream consumers (planned: quantile residuals, `predict(type =
"quantile")`, `exceedance()`) are meant to call `fitted_distribution()` once
and reuse its closures, rather than re-deriving the public-to-native
parameter conversion a fourth time (it is already duplicated across
`predict`/`simulate`/`residuals`; see `R/methods.R:2831,2969,3306,2858,2877,3095`
for examples of the existing duplication this registry is meant to arrest).

## Noether's traps: family-specific public -> native maps

A generic `pFAMILY(y, mu, sigma)` is wrong. Every `drm_family_dpq()` case
must reproduce the exact transform the compiled `src/drmTMB.cpp` density
uses. DO-T0a verifies three of Noether's four named traps directly (the
fourth, lognormal's `-log_y` Jacobian, is noted but not implemented in
DO-T0a; lognormal is deferred to DO-T3/DO-T0b's base-R-closed-form batch):

- **Gaussian meta `V_known`** (`src/drmTMB.cpp:634`,
  `obs_sigma = sqrt(V_known + sigma * sigma)`): `fitted_distribution_params()`
  always attaches a `V_known` column (0 for ordinary fits and for any
  `newdata` rows, `known_v_diag(object)` for fitted rows of a `meta_V()`
  fit). Gaussian's `d`/`p`/`q` reconstruct `obs_sigma` from `params$mu`,
  `params$sigma`, `params$V_known` -- the SAME quantity `observation_sigma()`
  (`R/methods.R:4794`) already computes for `simulate.drmTMB()`, so there is
  one source of truth, not two.
- **Skew-normal `(xi, omega, alpha)` moment inversion**
  (`src/drmTMB.cpp:2441-2447`): `drm_skew_normal_native()` reproduces
  `delta = alpha / sqrt(1+alpha^2)`, `omega = sigma / sqrt(1 - delta^2*2/pi)`,
  `xi = mu - omega*delta*sqrt(2/pi)` -- the same inversion `rskew_normal_public()`
  (`R/methods.R:3083-3093`) already uses for `simulate.drmTMB()`.
- **Tweedie public `sigma` -> native `phi = sigma^2`, `nu` via the
  `logit12` link** (`src/drmTMB.cpp:2593-2621`, model_type 16): the spike's
  `drm_tweedie_dpq()` maps `phi = sigma^2`, `power = nu` before calling
  `tweedie::{d,p,q}tweedie()`.

Student's `sigma` (a scale, not an SD; `src/drmTMB.cpp:2404`) and lognormal's
CDF-drops-the-Jacobian trap (`src/drmTMB.cpp:2498`) are **not** implemented in
DO-T0a; they are named here so DO-T0b does not silently reintroduce them when
those two families are promoted next (student and lognormal are both in
DO-T0b's base-R-closed-form batch).

## Gaussian reference: verification results

Verified on this machine (R 4.6.0, `devtools::load_all()`), not asserted:

**Ordinary gaussian** (`n = 200`, `sigma ~ x`):
- `p(q(u))` identity over `u = {0.01, ..., 0.99}`: max `|p(q(u)) - u| = 2.2e-16`.
- `d()` vs `dnorm(y; mu_hat, observation_sigma(fit))`: max abs diff `0`.
- Compiled TMB `nll` vs `-sum(log(d(y)))`: `252.4508` vs `252.4508`, diff `2.6e-13`.

**Meta-analysis gaussian** (`meta_V()`, `n = 60`, known per-study `V`):
- `params$V_known` equals `known_v_diag(fit)` exactly.
- `d()` vs `dnorm(y; mu_hat, observation_sigma(fit))`: max abs diff `0`.
- Compiled `nll` vs `-sum(log(d(y)))`: diff `7.8e-14`.
- `p(q(u))` identity: max abs diff `1.1e-16`.
- `newdata` rows: `V_known` correctly defaults to `0` (no per-row known
  variance is available for un-fitted rows; documented limitation, see
  "Open questions" below).

## Feasibility spikes

Both spikes are wired into `drm_family_dpq()`'s `switch()` with
`status = "spike"`, so the CP1 reviewers can inspect the actual interface
holding a hard case, not a description of one. Neither is promoted past
`diagnostic_hold`; DG2 (atom-decomposition, left-limit, external reference)
and DG3 (recovery, power arm) are DO-T3 work.

### Tweedie (compound Poisson-gamma, atom at 0)

**What it needs:** the `tweedie` CRAN package (`dtweedie`/`ptweedie`/
`qtweedie`), already installed on this machine but **not yet a formal
package dependency**. No series re-implementation was necessary -- TMB's own
compiled `dtweedie()` (used in `src/drmTMB.cpp:2609`) and the R `tweedie`
package's `dtweedie()` use the same series-expansion algorithm (Dunn & Smyth)
and the same `(mu, phi, power)` parameterization, so only the public
`sigma -> phi = sigma^2` and `nu` (already the native power via the
`logit12` link) maps were needed.

**One real limitation found:** `tweedie::{d,p,q}tweedie()` require `power`
to be a **single scalar**, not a per-row vector (`sort_notation()` rejects a
vector). `drm_tweedie_dpq()` therefore vectorises the call when the fitted
`nu` is row-constant (the common case: `nu ~ 1`) and falls back to one call
per row when `nu` varies by row (e.g. `nu ~ x`). This is a genuine external
constraint, not a workaround for an interface gap.

**Verification** (`n = 300`, `mu ~ x`, `sigma ~ 1`, `nu ~ 1`, ~3.3% exact
zeros):
- `d()` vs `tweedie::dtweedie(y, mu_hat, sigma_hat^2, nu_hat)` direct call:
  max abs diff `0`.
- Compiled `nll` vs `-sum(log(d(y)))`: `485.4377` vs `485.4377`, diff `-4.8e-11`.
- Atom check: `p(0)` (the CDF at the atom) equals `d(0)` (the point mass)
  exactly, confirming the CDF correctly returns the atom probability at the
  left edge of support (`F(0) == P(Y=0)`, since `F(0-) = 0` for a
  non-negative-support family).
- `p(q(u))` identity for `u = {0.5, 0.7, 0.9, 0.99}` (away from the atom):
  max abs diff `9.0e-14`.

### Skew-normal (Owen's-T CDF, no elementary closed form)

**What it needs:** the CDF has no elementary closed form
(`F(y) = Phi(z) - 2*T(z, alpha)`, Owen's T function). The `sn` package
(which provides `psn()`/`qsn()`) is **not installed** on this development
machine (`requireNamespace("sn", quietly = TRUE)` returns `FALSE`).

**What was used instead (no new hard dependency):** `p()` is computed by
`stats::integrate()` of the compiled skew-normal density from `-40*omega`
(effectively `-Inf` for practical purposes) to `y`, row by row. `q()` is
`stats::uniroot()` numeric inversion of `p()` -- this step is unavoidable
regardless of package choice, since even `sn::qsn()` numerically inverts
`psn()` internally; there is no elementary closed-form quantile either.

**Cross-checked three independent ways** (`n = 150`, `mu ~ x`, `sigma ~ 1`,
`nu ~ 1`, fitted `nu ~ 1.93`):
1. Compiled TMB `nll` vs `-sum(log(d(y)))`: `219.3282` vs `219.3282`, diff
   `2.3e-13`.
2. **External closed-form identity** (not derived from the same density
   code): the skew-normal CDF also equals `2*Phi(z) - 2*Phi2(0, z; rho =
   delta)`, a bivariate-normal orthant probability, computed independently
   via `mvtnorm::pmvnorm()`. Max abs diff vs the `integrate()`-based `p()`:
   `2.2e-16` (8 test rows).
3. **Large-`N` Monte Carlo** (`2e6` draws per row via the existing
   `rskew_normal_public()` sampler, `R/methods.R:3083`, an independently
   written generator, not the density code): empirical CDF vs `p()`, max abs
   diff `4.0e-4`, consistent with Monte Carlo standard error at `N = 2e6`.
4. `p(q(u))` identity (`n = 8` rows, `u = {0.1,...,0.9}`): max abs diff
   `4.7e-10` (bounded by `uniroot()`'s `tol = 1e-8`).

**Conclusion:** the interface holds a genuinely non-closed-form CDF via
numeric integration/inversion with zero new hard dependencies, verified
against an independent closed-form identity and an independent Monte Carlo
oracle. For DO-T3, `sn::psn()`/`qsn()` would likely be faster and more
numerically robust in the tails; adding `sn` as a `Suggests` dependency is a
recommendation for that phase, not a DO-T0a requirement.

## Dunn-Smyth randomized-quantile-residual seed contract

For discrete/atom families, `F` is a step function (or has isolated jumps),
so a plain `u = F(y)` residual is not uniform even under the true model.
Dunn & Smyth (1996) draw `u ~ Uniform(F(y-), F(y)]`, where `F(y-)` is the
left limit of `F` at `y` (0 for purely continuous families; the CDF
evaluated just below the atom for atom families such as Tweedie at `y = 0`;
`F(y-1)` for count families).

`drm_dunn_smyth_u(lower, upper, seed = NULL)` (`R/family-dpq.R`) is the
seed-contract primitive, reusing the SAME `.Random.seed` save/restore idiom
as `simulate.drmTMB()` (`R/methods.R:2770-2792`, save-before/`set.seed()`/
restore-on-exit):

- `seed = NULL` (default): draws use the caller's current RNG stream,
  ordinary R behaviour, no save/restore.
- `seed = <integer>`: deterministic AND side-effect-free -- the caller's
  prior `.Random.seed` is saved before the call and restored on exit, so a
  seeded call never permanently disturbs the global RNG stream (verified:
  `set.seed(1); runif(3)` gives the same draws whether or not a seeded
  `drm_dunn_smyth_u()` call happened in between).
- Multi-realization envelopes (Fisher's DG3 power-arm requirement, planned
  for DO-T1): call `drm_dunn_smyth_u()` `nsim` times with distinct seeds, or
  without a seed inside a single seeded outer block, and summarise the
  resulting envelope.

**End-to-end demonstration** on the tweedie atom spike (`n = 300`, true
model): `Fy_left <- ifelse(y == 0, 0, p(y))`, `u <- drm_dunn_smyth_u(Fy_left,
p(y), seed = 7)`, `z <- qnorm(u)`. Result: `mean(z) = -0.0004`,
`sd(z) = 0.9999`, Kolmogorov-Smirnov test vs `N(0,1)`: `D = 0.040`,
`p = 0.72` (does not reject). This is a single-seed sanity demonstration,
not the quantified power arm DG3 requires (type-I under truth + rejection
under >=2 named misspecifications) -- that is DO-T1 work.

## Recommendations before the CP1 API-freeze

1. **`newdata` + meta `V_known` gap.** `fitted_distribution(object, newdata
   = <new rows>)` silently treats the known sampling variance as 0 for new
   rows, because `newdata` carries no per-row `V` column. This matches
   `predict_parameters()`'s existing `newdata` behaviour (fixed-effect,
   population-level only) but is worth an explicit CP1 decision: should
   `fitted_distribution()` accept a `V` column in `newdata` for meta models,
   or should it `cli_abort()` when `newdata` is supplied to a `meta_V()` fit
   (safer, but blocks a legitimate use case: predicting `p(y)` for a new
   study with a stated sampling variance)? DO-T0a leaves this as silent
   `V_known = 0`, documented in the roxygen but not enforced.
2. **`status` field semantics.** `"reference"` vs `"spike"` is a two-level
   flag invented for this slice. DO-T3 will need a third state (something
   like `"promoted"` after DG2/DG3 pass) or a small enum; worth fixing the
   vocabulary at CP1 rather than growing ad hoc strings per phase. Related:
   nothing currently reads `fitted_distribution()$status` to gate behaviour
   (e.g. refuse `residuals(type = "quantile")` on a `"spike"` family). DO-T1
   will need to decide whether that gate lives in `fitted_distribution()`
   callers or in `drm_family_dpq()` itself.
3. **Row-varying-parameter fallback performance.** Both spikes fall back to
   an R-level per-row loop when a shape parameter is not constant across
   rows (tweedie's `power` scalar limit; skew_normal's `integrate()`/
   `uniroot()` are already row-by-row). This is fine at DO-T0a's
   demonstration scale (n in the hundreds) but will need a documented
   performance ceiling or a vectorised alternative before DO-T3 exposes it
   on `predict(type = "quantile")` for e.g. `n = 10,000` fits.
4. **`tweedie` and `mvtnorm` are now `Suggests`-only dependencies** (added
   to `DESCRIPTION` in this slice, since `R/family-dpq.R` and
   `tests/testthat/test-family-dpq.R` reference them; every call site is
   guarded by `drm_require_tweedie()`/`requireNamespace()` or
   `skip_if_not_installed()`). `sn` was NOT added -- it is not installed on
   this development machine and DO-T0a's skew_normal spike does not depend
   on it. If DO-T3 adopts `sn::psn()`/`qsn()` for speed/robustness, add it
   then.
5. **`d`/`p`/`q` closures take `(y_or_u, params)`, not `(y_or_u, object)`.**
   This was a deliberate choice so the closures are callable at arbitrary
   fixed `theta` (useful for DG2 unit tests that don't need a live fit), but
   it means any family whose density needs something beyond the per-row
   `params` table (V_known is the one gaussian case handled by attaching an
   extra column) will need the same pattern: extend `params`, don't add
   arguments to the closures. Worth confirming this constraint at CP1 before
   DO-T3 hits a family that needs it (e.g. a family needing trial counts,
   like binomial/beta-binomial, will need `params$trials` attached the same
   way `V_known` is).

## Out of scope for DO-T0a (unchanged from the ultra-plan)

Calibrated coverage (DG4/DG5); uncertainty beyond `theta_hat`; RE/structured
residual-adequacy beyond fixed effects; bivariate joint outputs; `drmTMB_julia`;
any of the remaining 15 model types' `{d,p,q}`; promoting skew_normal or
tweedie past `diagnostic_hold`.

## Files touched

- `R/family-dpq.R` (new): `drm_family_dpq()`, `fitted_distribution()` +
  `fitted_distribution.drmTMB()`, `fitted_distribution_params()`,
  `drm_dunn_smyth_u()`, and the gaussian/tweedie/skew_normal per-family
  helpers.
- `tests/testthat/test-family-dpq.R` (new): gaussian reference (ordinary +
  `meta_V()`), the unimplemented-model-type error path, the two spikes
  (guarded by `skip_if_not_installed()`), and the seed-contract tests.
- `man/drm_family_dpq.Rd`, `man/fitted_distribution.Rd` (generated),
  `NAMESPACE` (generated: exports `fitted_distribution` and its `drmTMB`
  S3 method).
