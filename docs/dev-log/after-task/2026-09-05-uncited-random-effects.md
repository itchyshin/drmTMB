# Six UNCITED random-effect capabilities, given an ending

**Leaf** `uncited-random-effects` (parity-joint, 2026-09-05).
**Baseline measured, not assumed** drmTMB `e172e7002` + DRM.jl `345892520`:
`Rscript tools/write-parity-scoreboard.R` reports **23 UNCITED** on the bridge
axis. After this branch, with DRM.jl at `1ccb957b` (PR itchyshin/DRM.jl#729):
**17 UNCITED**. Every one of the six capabilities in this leaf now ends in a
receipt or a written boundary, and the delta of six is entirely this leaf's.

| capability | before | after |
|---|---|---|
| `Gaussian random intercept (mean)` | UNCITED | **RECEIPT** |
| `Gaussian random slope (mean)` | UNCITED | **RECEIPT** |
| `Gaussian phylogenetic random intercept (mean)` | UNCITED | **RECEIPT** |
| `Gaussian random effect on sigma (scale)` | UNCITED | **RECEIPT-NOT-PASS** (cited negative control) |
| `Tweedie random intercept (mean)` | UNCITED | **REFUSED** at `R/julia-bridge.R:1223` |
| `Gaussian phylogenetic random intercept + slope, two SDs (mean)` | UNCITED | **REFUSED** at `R/julia-bridge.R:2394` |

## What was measured

Same target fitted twice through `drmTMB()`, `engine = "tmb"` against
`engine = "julia"`, at DRM.jl `345892520` (**not** the dead `430ef64cc` pin) with
comparator build `3bbe615e`. Harness and rows live in DRM.jl:
`tools/parity_ranef.R` -> `docs/dev-log/evidence/parity-classc.tsv`, the table
the scoreboard actually joins by `capability_id`.

| cell | status | coef | logLik | SE (max rel) |
|---|---|---:|---:|---:|
| `gaussian_ri_mu_ml` | PARITY_PASS | 1.318e-11 | 1.506e-12 | SE_PASS 3.333e-07 |
| `gaussian_ri_mu_reml` | PARITY_PASS | 8.295e-11 | 7.674e-13 | SE_PASS 3.333e-07 |
| `gaussian_rs_mu_ml` | PARITY_PASS | 8.457e-12 | 1.421e-13 | SE_PASS 3.290e-07 |
| `gaussian_sigma_ri_ml` | **PARITY_FAIL** | 4.743e-04 | 1.009e-01 | SE_FAIL 1.762e-02 |
| `gaussian_phylo_mu_ml` | PARITY_PASS | 6.216e-09 | 1.001e-09 | **SE_FAIL 3.491e-03** |

## The three things that are not "it passes"

**The phylogenetic receipt is SPLIT, and the row now says so.** Coefficients
agree to 6.2e-09 and logLik to 1.0e-09, but the fixed-effect Wald SEs agree only
to 3.491e-03 relative — over the 1e-3 bar `tools/parity_se.R` argues from. DRM.jl
said why during that very fit: *"sparse-Laplace vcov: finite-difference Hessian
is not positive definite at the optimum; reported SEs are not trustworthy"* and
*"Hessian is numerically singular at the optimum — using a pseudo-inverse"*
(`src/vcov_guard.jl`, `rcond = 2.78e-08`, flagged coordinate = the phylo-mean
variance block). The point-estimate parity of this route is now citable; its
bridge-side SEs are not. That is a NEW boundary this receipt adds.

**The sigma-side random intercept must not be promoted, and is the harness's own
negative control.** drmTMB integrates it by Laplace, DRM.jl by 32-node
Gauss–Hermite quadrature. Both converge; the gap is the approximation, not a
wrong answer. The diagnosis reproduces at a different DRM.jl sha on a different
draw with the same sign and order of magnitude, so it is the integrator, not a
seed.

**Two routes are refused by drmTMB's own fences, and the matrix used to deny it.**
Both rows previously read *"no bridge route: fits natively on both sides, nothing
to marshal"*. That was wrong twice over: a bridge route IS attempted, and it IS
refused. Measured, each with a positive control that fitted:

- **Tweedie** — `drm_julia_refuse_fe_only_random_effects()`, the G17 fe-only
  fence. Control: the same `tweedie()` call with no bar — fitted. Use
  `engine = "tmb"`; this is drmTMB's decision, not a DRM.jl limit.
- **Gaussian `phylo(1 + x | species)`** — `drm_julia_refuse_marker_slope_unsupported()`,
  whose switch `drm_julia_marker_slope_pin_supports()` is `FALSE`. Control: the
  same call with an intercept-only marker — fitted.

## The stale fence, corrected but not lifted

The marker-slope guard told users *"the pinned DRM.jl engine refuses this
construct rather than fitting it"*. **At DRM.jl `345892520` that is false.**
`1a041d089` (its #644, closing #620) implements the Gaussian two-SD phylogenetic
random slope; `test/test_phylo_slope_two_sd.jl` was re-run in this session and
passes **51 of 51 assertions in 21.5 s**, including a same-target native-drmTMB
oracle. The message, the comment above the switch, and the
`structured_marker_slope` gate row are corrected to say the fence is drmTMB's own.

It is **not lifted**, and that is measured rather than asserted: flipping the
switch to `TRUE` as a red control does not reach a fit — `drm_julia_phylo_payload()`
refuses next, because it admits the slope shape only for
`drm_julia_slope_phylo_families()` (nbinom2, poisson, gamma, beta), which route
to DRM.jl's **correlated** `_fit_corr_locscale` rather than the **independent**
two-SD model #620 added. Lifting it needs a family-aware switch, a payload
admission, and `sdpars` translation for the two-SD block — a route-widening, and
it belongs to its own leaf.

## The scoreboard predicate was too narrow

`sb_is_refused()` matched only `REFUSED at drm_julia_family_tag()`, so a
capability refused at a **registered gate** — guard named, `R/julia-bridge.R:<line>`
printed, receipt row behind it — still counted UNCITED. That contradicts the
file's own rule that "a refusal is a determination with a file:line, so it is NOT
uncited". The predicate now also matches the gated phrasing
`tools/write-parity-matrix.R` emits. No new verdict word, no vocabulary change.

## Red controls (all three planted, failed, restored byte-identically)

1. Neutralise `drm_julia_refuse_fe_only_random_effects()` -> `test-julia-fe-only-fence.R`
   fails (10-failure cap reached). Restored; `R/julia-bridge.R` sha256 `ffab9f0d…`.
2. Flip `drm_julia_marker_slope_pin_supports()` to `TRUE` ->
   `test-julia-marker-slope-guard.R` fails 5. Restored; same sha256.
3. Break the added refusal pattern in `sb_is_refused()` -> the scoreboard goes
   back to **19 UNCITED** with both cells reading UNCITED; restored ->
   **17 UNCITED** with both reading REFUSED. Generator sha256 `629969bd…`.

## Tests

`NOT_CRAN=true`, `DRM_JL_PATH` set. `test-parity-matrix.R` 140/0/0 (1 pre-existing
skip: PR #1184's five ledger rows), `test-julia-gate-vs-engine.R` 144/0/0,
`test-julia-marker-slope-guard.R` 36/0/0, `test-julia-fe-only-fence.R` 204/0/0
(1 skip: `cumulative_logit` has no second dpar), `test-reml-route-table.R` 5/0/0,
`test-julia-structured.R` 68/0/0 and `test-julia-slope-nongaussian.R` 9/0/0 — the
last two with live Julia exercised, not skipped.

## What this does NOT claim

One draw per shape, one seed. Result-shape and point/SE parity only — **not
interval coverage**; no `interval_status` fence moves. The two refused routes are
boundaries, not passes. `docs/design/parity-matrix.md` re-pins from DRM.jl
`d3efbad2` to `1ccb957b`, so all 45 rows show a sha refresh on top of the two
rows whose content changed.

## Dependency

This branch cites `DRM.jl@1ccb957b`, which is **itchyshin/DRM.jl#729 and is not
yet merged**. Merge that first; this drmTMB PR is BLOCKED-on-DRM.jl-PR-729, not
unmet.
