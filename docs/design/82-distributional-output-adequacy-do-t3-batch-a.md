# DO-T3 Batch A: Base-R-Closed-Form `{d,p,q}` Families (student, lognormal, gamma, beta, binomial, poisson, nbinom2)

## Purpose

This note documents the DO-T3 batch A slice of the distributional output &
adequacy layer arc (issues #747/#748; ultra-plan:
`docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md`;
foundation: `docs/design/81-distributional-output-adequacy-t0a-foundation.md`).
The reader is a future contributor implementing DO-T3 batch B (harder
continuous/ordinal families) or batch C (atoms/mixtures), or a reviewer
checking that batch A's per-family transforms match the compiled density and
did not open a fourth copy of the public->native parameter conversion.

Batch A promotes seven families from "unimplemented" to `status = "reference"`
in `R/family-dpq.R`: **student, lognormal, gamma, beta, binomial, poisson,
nbinom2**. Combined with DO-T0a's gaussian, eight of eighteen `model_type`
values are now `"reference"`. Tweedie and skew_normal remain `status =
"spike"` (staged for batch B/C promotion). The `{d, p, q}` closure signature
`(y_or_u, params)` and the `fitted_distribution()` object shape are unchanged
-- this batch only adds cases inside the frozen registries CP1 explicitly
authorized (`drm_family_dpq()`'s `switch()`, `fitted_distribution_params()`'s
per-family column attachment).

## Dedup prelude (Emmy's #8)

Before adding families, the DO-T0a foundation's one existing duplication was
closed, establishing the pattern the batch-A additions themselves follow:

- **`drm_total_obs_sd(v_known, sigma) = sqrt(v_known + sigma^2)`**
  (`R/methods.R`) is now the single source of truth for the gaussian total
  observation SD. Both `observation_sigma()` (`R/methods.R`, used by
  `residuals()`/other callers) and `drm_gaussian_obs_sigma()`
  (`R/family-dpq.R`, the `{d,p,q}` params-table path) call it, rather than
  each independently re-deriving `sqrt(V_known + sigma^2)`.

Each batch-A family's public->native parameter map reuses the SAME
conversion `simulate.drmTMB()` already computes, extracted into a small
shared helper where the map is a genuine derived formula (not an identity):

| Family | Helper (new) | `simulate.drmTMB()` call site now routed through it |
|---|---|---|
| gamma | `drm_gamma_shape_scale(mu, sigma)` -> `list(shape, scale)` | the `"gamma"` branch (`R/methods.R`) |
| beta | `drm_beta_shapes(mu, sigma)` -> `list(shape1, shape2)` | the `"beta"` branch (`R/methods.R`) |
| nbinom2 | `drm_nbinom2_size(sigma)` -> `1 / sigma^2` | the `"nbinom2"` branch (`R/methods.R`) |

Student, lognormal, binomial, and poisson need no derived-formula helper: the
public dpars ARE the native parameters the compiled density and
`simulate.drmTMB()` already use (an identity map), so `drm_family_dpq()`'s
closures call `predict()`-ed `mu`/`sigma`/`nu` directly, matching
`simulate.drmTMB()`'s corresponding branches by inspection rather than by a
shared helper (there is no formula to duplicate).

**Not consolidated (flagged, not silently left inconsistent):**
`simulate.drmTMB()`'s `"zero_one_beta"` and `"beta_binomial"` branches
duplicate the same `phi <- 1 / sigma^2; shape1 <- mu*phi; shape2 <- (1-mu)*phi`
formula inline, not yet routed through `drm_beta_shapes()`; and
`truncated_nbinom2_p0()` duplicates `1 / sigma^2` inline, not yet routed
through `drm_nbinom2_size()`. Both are out of batch A's scope (neither family
is promoted here) and are left as the natural first move when their DO-T3
batch (B/C) rolls those families' `{d,p,q}` out -- consolidating them now
would touch code outside this task's family set.

## Per-family native maps (Noether's traps, verified against `src/drmTMB.cpp`)

- **student** (`model_type == 3`, `src/drmTMB.cpp:2404-2418`): `sigma` is a
  SCALE, not the response SD. `F(y) = pt((y-mu)/sigma, df=nu)`,
  `d(y) = dt((y-mu)/sigma, df=nu) / sigma`. Matches the compiled
  `log_density = log(dt(z,nu)) - log(sigma)` exactly.
- **lognormal** (`model_type == 4`, `src/drmTMB.cpp:2494-2499`): the compiled
  density is `dnorm(log(y), mu, sigma, log=TRUE) - log(y)`, i.e. the
  lognormal density INCLUDING the `-log(y)` Jacobian; `stats::dlnorm()`
  already applies this internally. The CDF does NOT carry that Jacobian (it
  is a probability, not a density) -- `stats::plnorm(y, meanlog=mu,
  sdlog=sigma)` directly, nothing added. This is the trap DO-T0a named but
  deferred; batch A implements and verifies it (`test-family-dpq-batchA.R`'s
  lognormal test asserts this explicitly).
- **gamma** (`model_type == 5`, `src/drmTMB.cpp:2576-2578`): `shape =
  1/sigma^2`, `scale = mu*sigma^2`.
- **beta** (`model_type == 10`, `src/drmTMB.cpp:2740-2769` -- NOT
  `model_type == 15`, which is `"zero_one_beta"`): `phi = 1/sigma^2`,
  `shape1 = mu*phi`, `shape2 = (1-mu)*phi`. The compiled density additionally
  floors `alpha`/`beta_shape` at `1e-8` via `CppAD::CondExpLt` to guard
  numeric underflow; `stats::{d,p,q}beta()` applies no such floor, so `d()`
  can differ from the compiled density at pathological (near-boundary `mu`,
  huge `phi`) parameter combinations. Not exercised by DG2's fixed theta
  vectors (interior `mu`, modest `phi`); flagged as a residual uncertainty
  below, not silently ignored.
- **binomial** (`model_type == 18`, `src/drmTMB.cpp:2963-2980`): identity map,
  `mu` IS the success probability. `trials` (the `cbind(success, failure)`
  denominator) is not a distributional parameter with a link -- it is
  attached as an extra `params` column inside `fitted_distribution_params()`,
  the CP1-sanctioned extension pattern (same shape as `V_known` for
  meta-analysis gaussian fits).
- **poisson** (`model_type == 6`, `src/drmTMB.cpp:3184-3195`): identity map,
  `mu` IS the Poisson rate.
- **nbinom2** (`model_type == 7`, `src/drm_count_kernels.h:31-41`): public
  `sigma` -> native `size = 1/sigma^2` (the kernel's internal `alpha =
  sigma^2` is the reciprocal of the `size` argument
  `stats::{d,p,q}nbinom(size=, mu=)` expects).

## `trials` attachment (binomial)

`fitted_distribution_params()` gained one new branch: when
`object$model$model_type == "binomial"`, it attaches `params$trials`.

- **Fitted rows** (`newdata = NULL`): `object$model$trials` directly -- the
  same vector `simulate.drmTMB()`'s binomial branch already reads.
- **`newdata` rows**: `newdata` carries no response, so there is no
  denominator to re-derive (that is the point of out-of-sample prediction).
  `drm_newdata_trials()` requires an explicit per-row `trials` column and
  `cli_abort()`s with a clear message otherwise, mirroring
  `drm_newdata_v_known()`'s `meta_V()` `V`-column contract from DO-T0a: never
  silently default a value that changes the fitted distribution.

## DG2 results (per family; `tests/testthat/test-family-dpq-batchA.R`)

All seven families pass all four DG2 checks (inverse identity, normalization,
compiled-density agreement, external-reference agreement) at the verification
spec's tolerances (continuous: `1e-6`; density agreement: `1e-8`). Discrete
families (binomial, poisson, nbinom2) use the right-inverse convention
(`p(q(a)) >= a`, `p(q(a)-1) < a`), not the plain equality identity, per the
verification spec.

Continuous families additionally verify normalization by checking `p()` at
the fitted support boundary (`mu - 1e4*sigma` / `mu + 1e4*sigma` for
location-scale families; `0`/`1` for beta; `0`/a far upper quantile for
gamma/lognormal) approaches `0`/`1`. Discrete families check `p(-1) == 0` and
`p(upper support) ~= 1`.

External-reference checks re-derive the native parameters directly in the
test body (e.g. `shape_direct <- 1/sigma_hat^2`) rather than calling the
package's internal `drm_gamma_shape_scale()`/etc. helpers, so a bug in those
helpers cannot cancel against the same bug in the assertion.

## DG3 smoke results (local scale only)

One fixed-seed, known-DGP smoke test per family: simulate from the family at
a known `theta`, fit the matching `drmTMB()` model, compute
`residuals(fit, type = "quantile")`, assert a Kolmogorov-Smirnov test against
`N(0,1)` does not reject (`p > 0.05`). All seven pass. This reuses DO-T1's
generic `residuals(type = "quantile")` machinery unchanged: once a family's
`drm_family_dpq()` entry sets `discrete`/`has_atom` correctly, the Dunn-Smyth
left-limit logic in `R/adequacy.R` handles it with no family-specific code.

This is explicitly **not** the gated multi-seed DG3 power-arm campaign (type-I
control across >=20 seeds, rejection under >=2 named mis-specifications per
family) the verification spec requires before a stronger behavioural claim --
that is a separate Curie/Grace campaign under `NOT_CRAN`, and (per the
compute directive) belongs on Totoro/DRAC, not this local smoke pass.

## Bonus confirmation (not required by this batch, verified as a side effect)

DO-T2's generic `predict(type = "quantile")` / `exceedance()` surfaces
(`R/distributional-outputs.R`, already committed) also route through
`fitted_distribution()`, so promoting these seven families makes those
surfaces work for them automatically. `tests/testthat/test-distributional-outputs.R`
and `tests/testthat/test-adequacy.R` were updated only where they asserted
"poisson is unimplemented" (now false); no new functionality was added to
either file by this batch.

## Flagged uncertainties (not silently resolved)

1. **Beta's `1e-8` floor.** The compiled density clamps `alpha`/`beta_shape`
   away from 0; `stats::{d,p,q}beta()` does not. DG2's fixed theta vectors
   (interior `mu`, modest `phi`) never approach the floor, so this is
   undetected here. A future DG2 pass that deliberately probes extreme
   `(mu, sigma)` combinations near the beta family's numeric edge should
   re-check this.
2. **`simulate.drmTMB()` duplication left open for zero_one_beta /
   beta_binomial / truncated_nbinom2.** See "Not consolidated" above --
   flagged for their DO-T3 batch, not fixed here.
3. **DG3 is a local smoke pass, not the power-arm campaign.** Type-I control
   across many seeds and detection power under named mis-specifications are
   not yet demonstrated for these seven families; see the verification spec's
   compute directive for the intended follow-up.

## Files touched

- `R/family-dpq.R`: `drm_family_dpq_student()`, `drm_family_dpq_lognormal()`,
  `drm_gamma_shape_scale()` + `drm_family_dpq_gamma()`, `drm_beta_shapes()` +
  `drm_family_dpq_beta()`, `drm_family_dpq_binomial()`,
  `drm_family_dpq_poisson()`, `drm_nbinom2_size()` +
  `drm_family_dpq_nbinom2()`; `drm_newdata_trials()`; the `trials` column
  branch in `fitted_distribution_params()`; the `drm_family_dpq()` switch()
  reordered to mirror `drm_dpar_link()`'s canonical order; `drm_gaussian_obs_sigma()`
  updated to call the new `drm_total_obs_sd()`; status/docstring updates.
- `R/methods.R`: `drm_total_obs_sd()` (new, shared with
  `observation_sigma()`); `simulate.drmTMB()`'s `"gamma"`, `"beta"`, and
  `"nbinom2"` branches updated to call the new shared helpers (numerically
  identical output, verified against `test-gamma-location-scale.R`,
  `test-beta-location-scale.R`, `test-nbinom2-location-scale.R`).
- `tests/testthat/test-family-dpq-batchA.R` (new): DG2 + DG3-smoke tests for
  all seven families.
- `tests/testthat/test-family-dpq.R`, `tests/testthat/test-adequacy.R`:
  updated the "unimplemented model type" probe fits from `poisson()` (now
  promoted) to `beta_binomial()` (still unimplemented).

## Out of scope for DO-T3 batch A (unchanged from the ultra-plan)

Batches B (skew_normal, cumulative_logit, beta -- beta is now done, so batch
B is skew_normal/cumulative_logit) and C (tweedie, zero_one_beta, zi_*,
truncated_*, hurdle_*) and D (bivariate marginal); the gated DG3 power-arm
campaign; calibrated coverage (DG4/DG5); RE/structured adequacy beyond fixed
effects.
