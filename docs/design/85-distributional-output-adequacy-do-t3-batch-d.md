# DO-T3 Batch D: Bivariate Marginal `{d,p,q}` for `biv_gaussian`

## Purpose

This note documents the DO-T3 batch D slice of the distributional output &
adequacy layer arc (issues #747/#748; ultra-plan:
`docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md`;
foundation: `docs/design/81-distributional-output-adequacy-t0a-foundation.md`;
prior batches: `docs/design/82-distributional-output-adequacy-do-t3-batch-a.md`,
`docs/design/83-distributional-output-adequacy-do-t3-batch-b.md`,
`docs/design/84-distributional-output-adequacy-do-t3-batch-c.md`). The reader
is a reviewer checking that all 18 fitted `model_type` values are now
`status = "reference"`, or a future contributor deciding whether to extend
`biv_gaussian`'s distributional output beyond the marginal-only scope this
batch delivers (e.g. joint bivariate quantile regions, or a residual `rho12`
diagnostic).

Batch D promotes the last remaining family, **`biv_gaussian`**, to
`status = "reference"` in `R/family-dpq.R`. Combined with DO-T0a's gaussian
and batches A/B/C's sixteen families, **all 18 `model_type` values are now
`"reference"`**. This closes DO-T3's per-family rollout.

## Design: marginal-only, reusing the gaussian closures verbatim

The marginal of a bivariate normal for response `k` is EXACTLY `N(mu_k,
sigma_k)`, independent of `rho12` -- a property of the multivariate normal
(marginalizing the joint density over the other response integrates `rho12`
out entirely), not an approximation or a scope simplification. So
`biv_gaussian`'s `{d,p,q}` reuse `drm_family_dpq_gaussian()`'s closures
**verbatim** on a SELECTED response:

```r
drm_family_dpq_biv_gaussian <- function() {
  drm_family_dpq_gaussian()
}
```

No new density/CDF/quantile code, no new cascade -- exactly the reuse the
goal specified. `drm_family_dpq(object)`'s signature is unchanged (still
`function(object)`, no `response` argument); the closures it returns for
`biv_gaussian` are identical regardless of which response is selected. The
response-selection step lives one layer up, in
`fitted_distribution_params()`.

### The `response` argument

`fitted_distribution()`/`fitted_distribution.drmTMB()` gains an additive
`response = NULL` argument (the frozen `(y_or_u, params)` closure signature
and the returned object's core fields -- `model_type`, `status`, `discrete`,
`has_atom`, `atoms`, `params`, `d`, `p`, `q` -- are unchanged):

- **Univariate fits**: `response` must stay `NULL` (the default). Supplying a
  non-`NULL` value errors clearly ("`response` is only used for bivariate
  model types"), rather than being silently ignored -- this is the
  "validated for univariate" half of the goal's contract.
- **`biv_gaussian` fits**: `response` is **required**. `1` selects `(mu1,
  sigma1)`, `2` selects `(mu2, sigma2)`. Omitting it errors:

  > `"biv_gaussian"` is bivariate; pass `response = 1` or `response = 2` for
  > the marginal distribution.

  matching the goal's exact required wording. A value outside `{1, 2}` (or
  length != 1, or `NA`) also errors clearly.

Both rules are centralized in one new helper,
`drm_validate_fitted_distribution_response(object, response)`
(`R/family-dpq.R`), shared by `fitted_distribution.drmTMB()` and
`R/adequacy.R`'s `drm_quantile_residuals()` -- one source of truth for the
error wording rather than two independently maintained checks.

### How `fitted_distribution_params()` builds the generic `mu`/`sigma` columns

`drm_family_dpq_biv_gaussian()`'s `dpars` is the generic `c("mu", "sigma")`
(reused verbatim from gaussian), but a `biv_gaussian` fit's coefficients are
named `mu1`/`mu2`/`sigma1`/`sigma2` -- not `mu`/`sigma`.
`fitted_distribution_params()` translates the generic dpar names to the
selected response's fit-specific names before calling
`predict_parameters()` (`request_dpars <- paste0(dpars, response)`, e.g.
`c("mu1", "sigma1")`), then renames the returned columns back to the generic
`mu`/`sigma` so the reused gaussian closures (which read `params$mu`/
`params$sigma`) work completely unchanged.

## The V_known bug fix

DO-T2's original marginal path (`drm_biv_gaussian_marginal_distribution()`,
removed in this batch -- see below) explicitly did NOT attach a `V_known`
column at all, documenting that it "deliberately ignores any known bivariate
sampling covariance" because reusing `known_v_diag()` directly would be
wrong: that helper returns the fit's FULL row-paired `2n`-length known
sampling-variance vector (`y1[1], y2[1], y1[2], y2[2], ...`, matching
`biv_gaussian_start()`'s `V_known_diag` convention, `R/drmTMB.R`), not a
single response's `n`-row slice -- reusing it directly for an `n`-row
`params` table throws a length mismatch.

This batch fixes it with `drm_biv_response_v_known(object, newdata, response,
n)` (`R/family-dpq.R`): for FITTED rows (`newdata = NULL`), it de-interleaves
`known_v_diag(object)` with `unstack_biv_response()` (`R/methods.R` -- the
SAME de-interleaving helper `bivariate_observation_covariance()`/
`simulate.drmTMB()`'s `biv_gaussian` branch already use for the `(y1, y2)`
response pair itself) and selects response `k`'s column. **For non-meta biv
fits this is all zeros** (`known_v_diag()` defaults to `rep(0, 2n)` when no
`meta_V()` was supplied) -- the goal's exact requirement. For a `meta_V()`
biv fit, response `k`'s slice now correctly recovers that response's known
sampling variance (verified below). For `newdata` rows, `V_known` stays `0`
(no per-row known bivariate sampling covariance is available for
out-of-sample rows -- this preserves DO-T2's original marginal-path scope
note rather than adding a new `V1`/`V2`-column contract to `newdata`; see
"Flagged uncertainties" below).

## DG2 results (`tests/testthat/test-family-dpq-batchD.R`)

Verified on this machine (`devtools::load_all()`), per response `k = 1, 2`:

1. **Marginal `d`/`p`/`q` equal `N(mu_k, sigma_k)`**: `fd$d(y_k)` /
   `fd$p(y_k)` / `fd$q(u)` compared exactly to `stats::dnorm`/`pnorm`/`qnorm`
   at `predict(fit, dpar = "mu<k>"/"sigma<k>")` -- exact agreement (float
   precision), both responses, both non-meta and `meta_V()` fits.
2. **`p(q(u))` inverse identity**: `u in {0.01, ..., 0.99}`, max abs
   difference `<= 1e-8`, both responses.
3. **Agreement with the compiled joint density's marginal at fixed theta**:
   the compiled kernel's per-row joint covariance is `Sigma_i = [[sigma1_i^2,
   rho12_i*sigma1_i*sigma2_i], [rho12_i*sigma1_i*sigma2_i, sigma2_i^2]]`
   (`src/drmTMB.cpp` `model_type == 2`). Marginalizing a bivariate normal
   over the OTHER response leaves EXACTLY the diagonal element -- a standard
   MVN identity, verified numerically (not just asserted) by integrating an
   INDEPENDENT `mvtnorm::dmvnorm()` joint density (built directly from
   `predict()`-ed dpars in the test body, not via `fd$d()`, so a bug in
   `fd$d()` cannot cancel against the assertion) over the other response's
   support (`stats::integrate()`, `+/- 15 sigma`) at 6 probe rows. Max abs
   difference `< 1e-6`, both responses.
4. **`rho12`-invariance**: two fits sharing the IDENTICAL response-1 draw
   (same `e1` seed) but different fitted `rho12` (`0.115` vs. `0.782` in one
   run) give numerically indistinguishable response-1 marginal parameters
   (`mu`/`sigma` diff `< 1e-4`, `fd$d()` diff `< 1e-4` -- bounded by
   optimizer tolerance, not a systematic `rho12` dependency) and
   `fd$d()`/`p()`/`q()` outputs. Structurally confirmed independent of any
   particular fit's numbers: `drm_family_dpq(fit)$dpars` is exactly `c("mu",
   "sigma")` -- `rho12`/`mu1`/`mu2` are not even listed, so the reused
   closures cannot read `rho12` at all.
5. **V_known fix**, a `meta_V()` biv fit (`n = 60`, independently drawn
   `v1`/`v2`/`cor12 = 0.3` via `meta_vcov_bivariate()`): `fd1$params$V_known`
   equals the original `v1` exactly (previously would have thrown a length
   error or misaligned); `fd2$params$V_known` equals `v2` exactly;
   `fd$d(y_k)` matches `dnorm(y_k; mu_k, sqrt(v_k + sigma_k^2))` exactly, both
   responses. Non-meta fit: `V_known` is all zero for both responses, as
   required.

## DG3 results (local smoke, `tests/testthat/test-family-dpq-batchD.R`)

One fixed-seed, correctly-specified `biv_gaussian` fit (`n = 400`, `rho12 =
0.35`): `residuals(fit, type = "quantile", response = k)` for `k = 1, 2`,
Kolmogorov-Smirnov test against `N(0,1)` does not reject (`p > 0.05` for
both responses in the run recorded here). `residuals(type = "quantile",
response = 1)` matches `drm_quantile_residuals(fit, response = 1)` directly
(mirroring `test-adequacy.R`'s univariate contract test). Omitting `response`
on a `biv_gaussian` fit errors with the required message rather than
silently defaulting to a response. `worm_plot(fit, response = k)`/
`qq_plot(fit, response = k)` return `ggplot` objects; omitting `response`
errors the same way.

This is explicitly **not** the gated multi-seed DG3 power-arm campaign (same
caveat as batches A/B/C) -- that remains a separate Curie/Grace campaign
under `NOT_CRAN`, on Totoro/DRAC per the compute directive.

## `predict(type = "quantile")`/`exceedance()`/`centile_chart()`: unified through the registry

DO-T2's separate biv marginal path (`drm_biv_gaussian_marginal_distribution()`,
`R/distributional-outputs.R`) is **removed** in this batch, since
`fitted_distribution()` now covers `biv_gaussian` directly via the registry.
`drm_response_fitted_distribution()` (still the `dpar`-to-`response`
translation layer `predict(type = "quantile")` calls) now routes through the
SAME `fitted_distribution(object, newdata, response = k)` call every other
surface uses, rather than duplicating a second marginal-parameter-table
constructor:

- **`predict(type = "quantile")`** keeps its existing, tested `dpar`-based
  response selector (`"mu1"`/`"sigma1"` for response 1, `"mu2"`/`"sigma2"`
  for response 2 -- unchanged, since this convention already has test
  coverage and a clear "needs `dpar` to identify a response" error for
  `dpar = "rho12"`) and translates it to `response` internally via the
  existing `drm_biv_gaussian_response_index()` helper (unchanged).
- **`centile_chart()`** delegates to `predict()` and so inherits the same
  `dpar` selector unchanged -- no new argument needed there.
- **`exceedance()`** had NO response selector at all before this batch
  (`biv_gaussian` was unregistered, so it could only ever reach
  `fitted_distribution()`'s "not yet covered" error). It gains a `response =
  NULL` argument directly, matching `fitted_distribution()`'s.

Verified (`skip_on_cran()`, Monte Carlo, `test-family-dpq-batchD.R`):
`exceedance(fit, threshold, response = 1)` matches a `2e4`-draw
`simulate()` Monte Carlo estimate within `3 * MCSE`; `predict(fit, dpar =
"mu<k>", type = "quantile", prob = c(0.1, 0.5, 0.9))` matches the
corresponding simulate() Monte Carlo sample quantile within `3 * MCSE`, both
responses. `centile_chart(fit, covariate = "x", dpar = "mu1"/"mu2")` returns
a `ggplot` object for both responses (smoke-only, not MC-verified -- it
delegates to the already-verified `predict()`).

## 18/18 families now `status = "reference"`

`drm_family_dpq()`'s `switch()` gains `biv_gaussian =
drm_family_dpq_biv_gaussian()` as its final case, in the same relative
position `drm_dpar_link()`'s switch uses (`biv_gaussian` is the last entry
there too). The `cli_abort()` default branch ("does not yet cover model
type") is now **defensive-only**: unreachable via any live `drmTMB()` fit's
`model_type`, kept so a future new `model_type` fails loudly rather than
silently. The two "unimplemented model type" probes
(`test-family-dpq.R`, `test-adequacy.R`) that every prior batch swapped to
the next-unpromoted family now exercise this defensive branch directly with
a synthetic `object$model$model_type` (`drm_family_dpq()`/
`fitted_distribution()` read only that one field, so a minimal fake list, or
a real fit with its `model_type` mutated after fitting, is enough) --
per the goal's "assert a genuinely unsupported model_type" instruction, since
there is no longer a real unimplemented family to fit.

## Flagged uncertainties (not silently resolved)

1. **`newdata` for a `meta_V()` `biv_gaussian` fit has no `V1`/`V2`-column
   contract.** Unlike the univariate gaussian path (`drm_newdata_v_known()`,
   which REQUIRES an explicit `V` column in `newdata` for a meta fit and
   errors rather than silently assuming 0), `biv_gaussian`'s `newdata` rows
   get `V_known = 0` unconditionally, regardless of the fit's meta status.
   This matches DO-T2's ORIGINAL marginal-path documentation ("deliberately
   ignores any known bivariate sampling covariance: marginal-only scope") and
   keeps the first implementation simple, but is an inconsistency with the
   univariate contract worth resolving in a future pass if `biv_gaussian`
   `meta_V()` + `newdata` prediction becomes a real use case (the natural
   fix mirrors `drm_newdata_v_known()`: require a `V1`/`V2` column pair, or a
   full `2n x 2n` `V` matrix, and error otherwise).
2. **No joint bivariate distributional output.** This batch is explicitly
   marginal-only, per the goal's declared scope. There is no `response =
   "joint"` option, no joint quantile region, and no residual `rho12`
   diagnostic surfaced through this registry. `residuals(fit)`/`residuals(fit,
   type = "pearson")` already compute a two-column response/Pearson residual
   using the full joint covariance (`R/methods.R`, unchanged by this batch);
   `type = "quantile"` remains marginal-per-response only.
3. **DG3 is a local smoke pass, not the power-arm campaign** (same caveat as
   batches A/B/C).
4. **`rho12`-invariance is demonstrated empirically at optimizer tolerance
   (`1e-4`), not proven exactly from a live fit.** The exact, zero-tolerance
   argument is structural (`drm_family_dpq(fit)$dpars` does not include
   `rho12`/`mu1`/`mu2`, so the closures literally cannot read them); the
   empirical two-fits-same-data check corroborates that the WHOLE pipeline
   (through `predict_parameters()`/`fitted_distribution_params()`) respects
   that structural fact, not just the closures in isolation.

## Files touched

- `R/family-dpq.R`: top-of-file status-enum comment and `drm_family_dpq()`'s
  roxygen updated (all 18 model types "reference", abort branch now
  defensive-only); `biv_gaussian = drm_family_dpq_biv_gaussian()` added to
  the switch (final case, matching `drm_dpar_link()`'s order);
  `drm_family_dpq_biv_gaussian()` (new, reuses `drm_family_dpq_gaussian()`
  verbatim); `fitted_distribution()`/`fitted_distribution.drmTMB()` extended
  with `response = NULL` (roxygen + implementation);
  `drm_validate_fitted_distribution_response()` (new, shared with
  `R/adequacy.R`); `fitted_distribution_params()` extended with `response =
  NULL` and a `biv_gaussian` branch (dpar-name translation, `V_known` via the
  new helper); `drm_biv_response_v_known()` (new, the V_known bug fix).
- `R/distributional-outputs.R`: file-header comment rewritten (biv_gaussian
  scope, no longer stale); `drm_response_fitted_distribution()` now routes
  through `fitted_distribution(object, newdata, response = k)` instead of the
  removed `drm_biv_gaussian_marginal_distribution()` (deleted, ~35 lines);
  `exceedance()`/`exceedance.drmTMB()` extended with `response = NULL`
  (roxygen + implementation, threaded into the `fitted_distribution()` call).
- `R/adequacy.R`: `drm_quantile_residuals()` extended with `response = NULL`
  (roxygen + implementation, validated via the shared helper);
  `drm_quantile_residual_response_y()` (new: `object$model$y1`/`y2` for
  `biv_gaussian`, `object$model$y` otherwise); `drm_quantile_residual_mask()`
  (new: per-response `observed_y1`/`observed_y2` masking for `biv_gaussian`,
  delegates to the existing `drm_mask_missing_response_values()` otherwise --
  does NOT reuse that helper directly for biv, since its `observed_y` field
  is a two-column matrix there, not an n-length vector);
  `drm_quantile_residual_qq_data()` extended with `response = NULL`.
- `R/adequacy-plots.R`: `worm_plot()`/`qq_plot()` extended with `response =
  NULL` (roxygen + implementation, threaded into
  `drm_quantile_residual_qq_data()`).
- `R/methods.R`: `residuals.drmTMB()`'s `type = "quantile"` roxygen paragraph
  updated (all 18 families, the `biv_gaussian` `response` contract).
- `tests/testthat/test-family-dpq-batchD.R` (new): DG2 (marginal identity,
  `p(q(u))` inverse, compiled-joint-marginal agreement via independent
  `mvtnorm::dmvnorm()` integration, `rho12`-invariance, the V_known fix) +
  DG3 local smoke (both responses) + `worm_plot()`/`qq_plot()`/`exceedance()`/
  `centile_chart()`/`predict(type = "quantile")` MC-agreement checks.
- `tests/testthat/test-family-dpq.R`: header comment updated; the
  "unimplemented model type" probe changed from fitting `biv_gaussian()` to a
  synthetic `list(model = list(model_type = "not_a_real_model_type"))`
  object passed directly to `drm_family_dpq()`.
- `tests/testthat/test-adequacy.R`: the "unimplemented model type" probe
  changed from fitting `biv_gaussian()` to a real gaussian fit with
  `model_type` mutated to a synthetic value after fitting.
- `tests/testthat/test-distributional-outputs.R`: the biv_gaussian
  `exceedance()` "out of scope" test reworked to exercise the NEW contract
  (errors without `response`, computes a correct marginal exceedance with
  `response = 1`) instead of the old "not yet covered" error.

## Out of scope for DO-T3 batch D (unchanged from the ultra-plan)

Joint bivariate distributional output (quantile regions, residual `rho12`
diagnostics); the gated DG3 power-arm campaign; calibrated coverage
(DG4/DG5); RE/structured adequacy beyond fixed effects; a `newdata`
`V1`/`V2`-column contract for `meta_V()` `biv_gaussian` fits (flagged above,
not implemented).
