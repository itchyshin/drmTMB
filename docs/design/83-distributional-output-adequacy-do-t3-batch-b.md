# DO-T3 Batch B: Shape/Ordinal `{d,p,q}` Families (skew_normal, beta_binomial, cumulative_logit)

## Purpose

This note documents the DO-T3 batch B slice of the distributional output &
adequacy layer arc (issues #747/#748; ultra-plan:
`docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md`;
foundation: `docs/design/81-distributional-output-adequacy-t0a-foundation.md`;
prior batch: `docs/design/82-distributional-output-adequacy-do-t3-batch-a.md`).
The reader is a future contributor implementing DO-T3 batch C (atoms/mixtures:
tweedie, zero_one_beta, zi_\*, truncated_\*, hurdle_\*) or batch D (bivariate
marginal), or a reviewer checking that batch B's per-family transforms match
the compiled density and did not open a fourth copy of the public->native
parameter conversion.

Batch B promotes three families to `status = "reference"` in
`R/family-dpq.R`: **skew_normal, beta_binomial, cumulative_logit**. Combined
with DO-T0a's gaussian and batch A's seven families, twelve of eighteen
`model_type` values are now `"reference"`. Only `"tweedie"` remains
`status = "spike"`. The `{d, p, q}` closure signature `(y_or_u, params)` and
the `fitted_distribution()` object shape are unchanged -- this batch only
adds cases inside the frozen registries CP1 explicitly authorized
(`drm_family_dpq()`'s `switch()`, `fitted_distribution_params()`'s per-family
column attachment), and reorders the switch to match `drm_dpar_link()`'s
canonical model_type order (`beta_binomial` after `beta`,
`cumulative_logit` after `binomial`).

## Dedup prelude (Emmy's #8 for batch B)

- **skew_normal (xi, omega, alpha, delta) moment inversion.** Before batch B,
  the (xi, omega) moment-inversion formula existed in three places:
  `src/drmTMB.cpp`'s compiled density (model_type == 17), the DO-T0a spike's
  `drm_skew_normal_native()` (`R/family-dpq.R`), and `rskew_normal_public()`
  (`R/methods.R`, the `simulate.drmTMB()` path). `drm_skew_normal_moments(mu,
  sigma, nu)` is now the single R-side source of truth:
  `drm_skew_normal_native(params)` calls it with the params-table columns,
  and `rskew_normal_public()` calls it with the plain vectors `simulate()`
  already has. The compiled C++ density is a fourth, necessarily independent
  copy (TMB `Type` arithmetic cannot call back into R), verified to match by
  the DG2 compiled-density-agreement check below rather than by sharing code.
- **beta_binomial (alpha, beta_shape) shape map.** `drm_beta_shapes(mu,
  sigma)` (added in batch A for the "beta" family: `phi = 1/sigma^2, shape1 =
  mu*phi, shape2 = (1-mu)*phi`) is the SAME formula the compiled beta-binomial
  kernel uses (`phi(i) = exp(-2*log_sigma(i))`, `alpha(i) = mu(i)*phi(i)`,
  `beta_shape(i) = (1-mu(i))*phi(i)`; `src/drmTMB.cpp:2886-2892`, model_type
  == 14). Batch A flagged `simulate.drmTMB()`'s `"beta_binomial"` branch as a
  still-open duplicate of this formula; batch B closes it -- that branch now
  calls `drm_beta_shapes()` too, and `drm_family_dpq_beta_binomial()`'s
  `{d,p,q}` closures call it a third time, all three routes sharing one
  formula.

**Not consolidated (flagged, not silently left inconsistent):**
`simulate.drmTMB()`'s `"zero_one_beta"` branch still duplicates the
`phi <- 1 / sigma^2; shape1 <- mu*phi; shape2 <- (1-mu)*phi` formula inline
(batch A's flag, not yet promoted -- deferred to zero_one_beta's own DO-T3
batch). `truncated_nbinom2_p0()`'s inline `1 / sigma^2` (batch A's other
flag) is likewise untouched here.

## Per-family native maps (Noether's traps, verified against `src/drmTMB.cpp`)

- **skew_normal** (`model_type == 17`, `src/drmTMB.cpp:2427-2469`): public
  `(mu, sigma, nu)` -> native `(xi, omega, alpha)` via the moment-inversion
  above (`alpha = nu`, `delta = alpha / sqrt(1 + alpha^2)`,
  `omega = sigma / sqrt(1 - delta^2 * 2/pi)`,
  `xi = mu - omega * delta * sqrt(2/pi)`). The density is
  `d(y) = (2/omega) * dnorm(z) * pnorm(alpha*z)`, `z = (y - xi)/omega`,
  matching the compiled log-density exactly (including the compiled
  version's `log(pnorm(...) + 1e-300)` floor only mattering in the deep
  tail, not exercised by DG2's fixed theta vectors). The CDF has no
  elementary closed form (Owen's-T); `p()` numerically integrates the
  density (`stats::integrate()`) and `q()` numerically inverts `p()`
  (`stats::uniroot()`) -- unavoidable regardless of package, since even
  `sn::qsn()` numerically inverts `psn()`. **DG2 normalization trap found
  while promoting**: `stats::integrate()`'s adaptive quadrature silently
  returns ~0 (not an error) when the integration interval is astronomically
  wide relative to the density's support (e.g. `y` at `xi +/- 1e4*omega`,
  the far-tail boundary DG2's normalization check uses for other continuous
  families) -- the mass is too concentrated for the default subdivision
  budget to find across that width. `drm_skew_normal_cdf()` now clamps `y`
  outside `xi +/- 40*omega` directly to 0/1 (that band already integrates to
  1 at float precision, since skew-normal tails decay at a Gaussian rate)
  rather than handing an arbitrarily wide interval to `integrate()`. This is
  a real numerical-robustness fix to the DO-T0a spike closure, not a
  pre-existing test workaround: it changes behaviour only for `y` far outside
  the practical support, where the DO-T0a spike previously returned an
  incorrect ~0 instead of ~1 for `y` above the support.
- **beta_binomial** (`model_type == 14`, `src/drmTMB.cpp:2859-2916`): public
  `(mu, sigma)` -> native `(alpha, beta_shape)` via `drm_beta_shapes()`
  (identical to the "beta" family's map; `phi = alpha + beta_shape =
  1/sigma^2`). No closed-form pmf/CDF exists in base R (`stats` has no
  `dbbinom`/`pbbinom`), so `drm_beta_binomial_dpmf()` reproduces the
  compiled kernel's exact lgamma pmf formula in R (self-contained, no
  runtime package dependency), and `drm_beta_binomial_p()`/
  `drm_beta_binomial_q()` do an exact `cumsum()` of that pmf over the
  row's finite discrete support `0:trials[i]` (no closed form for the CDF
  either). `trials` is attached as a `params` column via the SAME
  `drm_newdata_trials()` helper batch A introduced for "binomial" (now
  shared by both families; its error message was generalized from
  "This binomial fit needs..." to "This fit needs..." since it no longer
  names one specific family).
- **cumulative_logit** (`model_type == 13`, `src/drmTMB.cpp:2984-3051`):
  proportional-odds ordinal regression over `K` categories coded `1:K`
  (matching `object$model$y`, `ordinal_expected_score()`). `mu` is the
  identity-link linear predictor (`drm_dpar_link()`:
  `cumulative_logit = c(mu = "identity")`). The natural distributional
  object is the CUMULATIVE category probability, not a location/scale pair:
  `logit(P(Y <= k)) = cutpoints[k] - mu` for `k = 1..K-1`
  (`F(k) = plogis(cutpoints[k] - mu)`), `F(K) = 1`, `F(0) = 0`,
  `d(k) = F(k) - F(k-1)`. This matches the compiled kernel's
  `drm_log_inv_logit_diff(upper, lower)` construction exactly (verified via
  the compiled-nll agreement check, not by sharing the log-stabilized
  formula -- `drm_cumulative_logit_p()`/`d()` compute the plain
  `plogis()`-difference, which is mathematically identical and numerically
  indistinguishable at DG2's interior theta, though it could in principle
  lose precision relative to the compiled kernel's log-space subtraction at
  extreme near-degenerate cutpoint/eta combinations -- flagged below, not
  exercised by DG2).

## `trials` and cutpoint attachment (`fitted_distribution_params()`)

Two extensions inside the CP1-sanctioned column-attachment pattern:

- **`trials`** (beta_binomial): the condition guarding the existing
  `params$trials <- ...` branch changed from
  `identical(object$model$model_type, "binomial")` to
  `object$model$model_type %in% c("binomial", "beta_binomial")` -- both
  families reuse the exact same fitted-row/`newdata`-row logic and the same
  `drm_newdata_trials()` helper (now family-agnostic wording, per the dedup
  note above).
- **`CP1`..`CP(K-1)`** (cumulative_logit): `object$ordinal$cutpoints` (a
  named length-`(K-1)` vector, already computed at fit time) is unpacked
  into `K-1` constant columns, one value per column repeated across every
  row. Unlike `trials`/`V_known`, cutpoints do not depend on covariates, so
  `newdata` rows get the SAME cutpoints as fitted rows with no additional
  contract or required column -- there is nothing per-row to supply.
  `drm_cumulative_logit_cutpoints(params)` reads the `CPk` columns back out
  by name (`grep("^CP[0-9]+$", ...)`, sorted by index) inside the `{d,p,q}`
  closures, rather than needing the fitted `object` -- this keeps the number
  of ordinal categories discoverable purely from `params`, so the same
  closure returned by `drm_family_dpq_cumulative_logit()` (built with no
  arguments, like every other family builder) works for any fitted `K`.

## FIREWALL: skew_normal `{d,p,q}` promotion vs. the family's fit-quality status

Promoting `drm_family_dpq_skew_normal()`'s `status` to `"reference"`
certifies CDF/quantile CORRECTNESS on the distributional-output axis only
(DG2: compiled-density agreement, an independent bivariate-normal CDF
identity, p-q inverse identity; DG3: a local quantile-residual smoke pass).
It does **not** certify, and must not be read as certifying, that the
skew_normal FAMILY is inference-ready. `check_drmTMB()`'s
`check_skew_normal_nu()` (`R/check.R`) is a separate axis with its own
`diagnostic_hold` status, unchanged by this batch -- `R/check.R` was not
touched. A code comment beside `drm_family_dpq_skew_normal()`
(`R/family-dpq.R`) states this explicitly, and the roxygen for
`drm_family_dpq()` cross-references it.

## DG2 results (per family; `tests/testthat/test-family-dpq-batchB.R`)

All three families pass all four DG2 checks (inverse identity,
normalization, compiled-density agreement, external-reference agreement) at
the verification spec's tolerances (continuous: `1e-6`; density agreement:
`1e-8` for beta_binomial/cumulative_logit, `1e-6` for skew_normal -- the
`integrate()`/`uniroot()` numeric-inversion route has looser precision than
a closed-form base-R `{d,p,q}FAMILY`, matching the DO-T0a spike's original
tolerance). skew_normal and beta_binomial use continuous/discrete inverse
identity as appropriate; cumulative_logit uses the discrete right-inverse
convention (`p(q(a)) >= a`, `p(q(a) - 1) < a`).

External references:

- **skew_normal**: the independent bivariate-normal CDF identity
  `F(z) = 2*Phi(z) - 2*Phi2(0, z; rho = delta)` (Azzalini 1985), evaluated
  via `mvtnorm::pmvnorm()` -- the same identity DO-T0a's spike test already
  used, now extended with the compiled-density and inverse-identity checks
  and moved into this batch's test file.
- **beta_binomial**: `extraDistr::{d,p}bbinom()`, re-parameterized from the
  package's `(mu, sigma)` to `(alpha, beta)` directly in the test body (not
  via `drm_beta_shapes()`), matching to `1e-8`/`1e-14` in practice.
  `extraDistr` is added to `Suggests` (guarded by
  `testthat::skip_if_not_installed("extraDistr")`); it is not a runtime
  dependency of the package's own `{d,p,q}` closures, which are
  self-contained (no external pmf/CDF package call).
- **cumulative_logit**: no single external package computes a
  proportional-odds cumulative-logit CDF in this parameterization, so the
  test builds the category-probability matrix directly from `cutpoints`/
  `eta` in the test body (the same construction as
  `tests/testthat/test-cumulative-logit.R`'s existing
  `ordinal_prob_from_fit()` helper, independently re-derived here rather than
  imported, so a bug in that helper cannot cancel against the assertion),
  per the verification spec's "hand-built mixture ... document the
  construction" convention for families with no external comparator.

## DG3 smoke results (local scale only)

One fixed-seed, known-DGP smoke test per family: simulate from the family at
a known `theta`, fit the matching `drmTMB()` model, compute
`residuals(fit, type = "quantile")`, assert a Kolmogorov-Smirnov test
against `N(0,1)` does not reject (`p > 0.05`). All three pass. As in batch A,
this reuses DO-T1's generic `residuals(type = "quantile")` machinery
unchanged -- no family-specific residual code was added.

This is explicitly **not** the gated multi-seed DG3 power-arm campaign
(type-I control across >=20 seeds, rejection under >=2 named
mis-specifications per family) the verification spec requires before a
stronger behavioural claim -- that remains a separate Curie/Grace campaign
under `NOT_CRAN`, on Totoro/DRAC per the compute directive.

## Flagged uncertainties (not silently resolved)

1. **cumulative_logit's plain `plogis()`-difference vs. the compiled
   kernel's log-space subtraction.** `drm_cumulative_logit_p()`/`d()`
   compute `plogis(upper) - plogis(lower)` directly; the compiled kernel
   uses `drm_log_inv_logit_diff()`, a log-space-stable equivalent. These are
   mathematically identical and agree to `1e-8` at DG2's interior theta
   (verified against the compiled nll), but could diverge at extreme
   near-degenerate cutpoint/eta combinations where catastrophic cancellation
   in the plain difference matters. Not exercised here; a future DG2 pass
   probing near-degenerate cutpoints should re-check this.
2. **beta_binomial's/beta's shared `1e-8` floor gap carries forward.** Batch
   A flagged that the compiled beta density floors `alpha`/`beta_shape` at
   `1e-8` (`CppAD::CondExpLt`) while `stats::{d,p,q}beta()` does not;
   `drm_beta_binomial_dpmf()` reuses `drm_beta_shapes()` and so inherits the
   same gap at pathological (near-0/near-1 `mu`, huge `phi`) parameter
   combinations. Undetected at DG2's interior fixed theta.
3. **zero_one_beta's `simulate.drmTMB()` duplication remains open.** Batch A
   flagged it; batch B closed beta_binomial's copy but did not touch
   zero_one_beta's (out of scope -- zero_one_beta is not promoted in this
   batch). Left for zero_one_beta's own DO-T3 batch.
4. **DG3 is a local smoke pass, not the power-arm campaign** (same caveat as
   batch A). Type-I control across many seeds and detection power under
   named mis-specifications are not yet demonstrated for these three
   families.
5. **Pre-existing stale comment, not introduced by this batch**:
   `R/distributional-outputs.R`'s file-header comment (line ~20) still says
   `drm_family_dpq()`'s switch "covers only \"gaussian\"/\"tweedie\"/
   \"skew_normal\"\"" -- stale since batch A already added seven more
   families; batch B adds three more on top. Left unedited (out of this
   batch's file scope; DO-T2 surface commentary, not the `{d,p,q}` registry
   itself), flagged here rather than silently left wrong.

## The two "unimplemented model type" probes (required consequence)

`beta_binomial` was batch A's example of a family `drm_family_dpq()`/
`residuals(type = "quantile")` does not yet cover; batch B promotes it, so
(mirroring batch A's own poisson -> beta_binomial swap) both probes --
`tests/testthat/test-family-dpq.R`'s `"drm_family_dpq() aborts clearly for
an unimplemented model type"` and `tests/testthat/test-adequacy.R`'s
`"residuals(type = 'quantile') errors clearly for an unimplemented model
type"` -- now fit `zero_one_beta()` instead (still unimplemented; staged for
a later DO-T3 batch).

## Files touched

- `R/family-dpq.R`: `drm_skew_normal_moments()` (new, shared dedup helper);
  `drm_skew_normal_native()` now calls it; `drm_family_dpq_skew_normal()`'s
  `status` flipped to `"reference"` with the firewall comment;
  `drm_skew_normal_cdf()`'s wide-interval `integrate()` guard (normalization
  fix); `drm_beta_binomial_dpmf()`/`drm_beta_binomial_p()`/
  `drm_beta_binomial_q()` + `drm_family_dpq_beta_binomial()` (new);
  `drm_cumulative_logit_cutpoints()`/`drm_cumulative_logit_p()`/
  `drm_cumulative_logit_q()` + `drm_family_dpq_cumulative_logit()` (new);
  the `drm_family_dpq()` switch reordered/extended (`beta_binomial` after
  `beta`, `cumulative_logit` after `binomial`); `fitted_distribution_params()`
  extended (`trials` condition now covers `beta_binomial` too; new `CPk`
  cutpoint-column branch for `cumulative_logit`); `drm_newdata_trials()`'s
  error message generalized from binomial-specific wording; status/docstring
  updates throughout (top-of-file comment, `drm_family_dpq()` roxygen,
  `fitted_distribution()` roxygen).
- `R/methods.R`: `rskew_normal_public()` now calls
  `drm_skew_normal_moments()`; `simulate.drmTMB()`'s `"beta_binomial"` branch
  now calls `drm_beta_shapes()`; `residuals.drmTMB()`'s roxygen `type =
  "quantile"` paragraph updated to list the current promoted-family set.
- `DESCRIPTION`: `extraDistr` added to `Suggests` (guarded test dependency
  for beta_binomial's DG2 external reference).
- `tests/testthat/test-family-dpq-batchB.R` (new): DG2 + DG3-smoke tests for
  all three families.
- `tests/testthat/test-family-dpq.R`: the skew_normal spike CDF-identity
  test moved to `test-family-dpq-batchB.R` (extended to full DG2/DG3, status
  assertion updated from `"spike"` to `"reference"`); the "unimplemented
  model type" probe fit changed from `beta_binomial()` (now promoted) to
  `zero_one_beta()`; header comment updated.
- `tests/testthat/test-adequacy.R`: the "unimplemented model type" probe fit
  changed from `beta_binomial()` to `zero_one_beta()`.
- `tests/testthat/test-family-dpq-batchA.R`: header comment corrected to
  point to `test-family-dpq-batchB.R` for skew_normal (no longer covered in
  `test-family-dpq.R`).

## Out of scope for DO-T3 batch B (unchanged from the ultra-plan)

Batch C (tweedie, zero_one_beta, zi_\*, truncated_\*, hurdle_\*) and batch D
(bivariate marginal); the gated DG3 power-arm campaign; calibrated coverage
(DG4/DG5); RE/structured adequacy beyond fixed effects.
