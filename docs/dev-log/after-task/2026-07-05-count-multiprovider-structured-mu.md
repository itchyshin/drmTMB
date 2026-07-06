# After Task: Simultaneous Two-Provider Structured Count Mu (Row 105)

## 1. Goal

Admit SIMULTANEOUS multi-provider structured effects in an NB2 count mean:
`drmTMB(y ~ x + spatial(1 | site, coords) + relmat(1 | id, Q), family =
nbinom2())` on a crossed `site x id` design must BUILD and surface BOTH
structured fields. Target: make the RED test
`tests/testthat/test-count-multiprovider-structured-mu.R` pass (both SDs in
`sdpars$mu`, `ranef()` includes `spatial_mu` + `relmat_mu`, both are direct
profile targets). Scope: a SCOPED second structured field (each q=1
intercept-only, each with its own group precision), not a full N-field refactor.

## 2. Implemented

R (`R/drmTMB.R`): `select_count_mu_structured_term()` now admits exactly the
two-provider intercept-only combo (new `allow_pair_types` argument + helper
`count_mu_structured_pair_is_admissible()` + ordered
`select_count_mu_structured_pair()`); every other >1 combo, the zi guard, and the
"cannot be combined with ordinary RE" guard stay intact. `drm_build_nbinom2_spec()`
builds a second `build_structured_mu_structure()` result (`phylo_mu2`), validates
it through the same guard, threads its variables into `vars`, and adds it to
`spec$structured`. A new `structured_mu2_tmb_data()` (merged in
`add_covariance_block_tmb_data()`, one global hook for all 15 specs) supplies
`has_phylo_mu2` / `phylo_mu2_node_index` / `phylo_mu2_value` / `Q_phylo2` /
`log_det_Q_phylo2`. `add_covariance_probe_parameter()` guarantees `u_phylo2` /
`log_sd_phylo2` exist and are mapped off unless the field is active;
`add_structured_mu2_parameters()` supplies live starts when it is.

Extractors: `split_tmb_random_effects()` emits the second block under its own key
(`relmat_mu`); `split_tmb_sdpars()` adds the second SD to `sdpars$mu`;
`profile_sd_internal()` routes the second field's term to `log_sd_phylo2` so the
two SDs are separate direct profile targets.

C++ (`src/drmTMB.cpp`): second structured field declared once
(`Q_phylo2`, `log_det_Q_phylo2`, `has_phylo_mu2`, `phylo_mu2_node_index`,
`phylo_mu2_value`, `u_phylo2`, `log_sd_phylo2`). A parallel scalar-GMRF block was
added to model_type 7 (NB2, applied to `eta_mu`) and model_type 1 (Gaussian
non-aggregation path, applied to `mu`): the field enters `eta` as
`phylo_mu2_value(i,0) * u_phylo2(node_index(i))` and adds the q=1 GMRF density
`0.5*(n*log2pi + 2n*log_sd_phylo2 - log_det_Q_phylo2 + exp(-2*log_sd_phylo2)*u'Q u)`
to the joint nll. No among-endpoint `theta` (both fields are q=1).

## 3a. Decisions and Rejected Alternatives

Decisions:

- Scoped second field `phylo_mu2` rather than an N-field refactor (matches the
  plan's bounded-index preference).
- Field order fixed by the canonical provider list (`phylo`, `phylo_interaction`,
  `spatial`, `animal`, `relmat`): first active provider is the primary
  `phylo_mu` (spatial -> `log_sd_phylo`), second is `phylo_mu2` (relmat ->
  `log_sd_phylo2`). Deterministic, so naming/profile targets are stable.
- Global data/parameter hooks (`add_covariance_block_tmb_data`,
  `add_covariance_probe_parameter`) so the shared C++ signature is satisfied for
  every model type without editing 15 per-branch `make_tmb_data` blocks.
- Thread the field through the Gaussian engine too (guard + spec + model_type 1
  block), not just NB2, so relaxing the Gaussian guard cannot silently drop a
  field.

Rejected alternatives:

- No `theta_phylo2` / among-field correlation (both fields q=1; a cross-field
  correlation is a separate future gate).
- Did not touch the status/gate surfaces (`qseries_*` tools, dashboard TSVs,
  `validate-mission-control.py`, conversion-contracts test) — owned by the
  concurrent rename chip and deferred to plan slice 6.

## 3b. Mathematical Contract

Two independent scalar Gaussian Markov random fields on the count location:
`eta_mu = o + X beta + Z1 a1 + Z2 a2`, with `a1 ~ N(0, sd1^2 Q1^{-1})` (spatial
coordinate kernel) and `a2 ~ N(0, sd2^2 Q2^{-1})` (relatedness `Q`). Each field's
`-log density` is the standard GMRF form with its own `log|Q|` and its own SD on
the unconstrained `log_sd` scale. Identifiability rests on the crossed
`expand.grid(site, id, rep)` design (site and id vary independently).

## 4. Files Touched

- `R/drmTMB.R` — guard relaxation + pair selector, `phylo_mu2` build/thread,
  TMB data hook, parameter defaults, extractor disambiguation.
- `src/drmTMB.cpp` — second structured field decls + GMRF blocks (model_type 1 + 7).
- `R/profile.R` — `profile_sd_internal()` routes the second field to `log_sd_phylo2`.
- `tests/testthat/test-count-multiprovider-structured-mu.R` — the RED admission test (target).
- `tests/testthat/test-count-structured-mu.R` — replaced one stale single-field
  rejection assertion (the exact combo row 105 admits) with a build+surface check.
- `docs/design/03-likelihoods.md` — documented the scoped two-provider count exception.

## 5. Checks Run

`pkgload::load_all(".")` recompiles the DLL clean. `testthat::test_file`:

- `test-count-multiprovider-structured-mu.R` -> PASS 6, FAIL 0 (target met).
- `test-count-structured-mu.R` -> PASS 374, FAIL 0 (was 369 + 1 stale fail).
- `test-structured-effects.R` -> PASS 337, FAIL 0.
- `test-nongaussian-structured-boundary.R` -> PASS 71, SKIP 1 (row-105 gate
  sub-test is `skip_on_cran`; see Known Residuals).
- Broad net (phylo/spatial/animal/relmat Gaussian, phylo-interaction, q4/q6/q8
  biv location, profile-targets, phase18 count/poisson/nbinom2 q1,
  phylo-penalized-map) -> PASS 2545, FAIL 0, ERROR 0.

Recovery smoke on a larger crossed design (n=960): `sd_spatial` 0.437 vs truth
0.45; `sd_relmat` 0.286 vs truth 0.40; `sigma_nb2` 0.342 vs 0.35; convergence 0.

## 6. Tests of the Tests

Confirmed the RED test fails on the pre-change tree (aborts at
`select_count_mu_structured_term`). Confirmed the single-field NB2 path is inert:
`has_phylo_mu2 == 0`, `u_phylo2`/`log_sd_phylo2` mapped off and absent from
`opt$par`, so they contribute nothing to the objective (nll unchanged). Verified
data shapes: field 1 (spatial) 320x1 value, 8x8 Q; field 2 (relmat) 320x1 value,
10x10 Q2; distinct `log_det`; both node-index vectors length = nobs.

## 7a. Issue Ledger

None opened.

## 8. Consistency Audit

Swept for sibling stale rejections (Rose principle): one in
`test-count-structured-mu.R` (fixed). The row-105 gate cell also lives in
`tools/qseries-v1-first-four-rejection-smoke.R` (case at L423-439),
`tools/qseries_v1_release_check.py`, `tools/validate-mission-control.py`, and
`tests/testthat/test-structured-re-conversion-contracts.R` — all status/gate
surfaces the concurrent rename chip owns (plan slice 6). Left untouched by
design; flagged as required follow-up.

## 9. What Did Not Go Smoothly

The status/gate machinery hard-codes row 105 as a rejection with the pattern
"Only one structured". My engine change flips that, so the smoke tool and its
boundary-test assertion will disagree with the engine once run (they skip
locally). This is the intended coordination boundary, not a defect — slice 6
performs the status flip after the rename chip merges.

## 10. Known Residuals

- Slice 6 (status admission) is deferred: flip row 105
  `unsupported`/`rejected` -> `point_fit` in `qseries-v1-first-four-rejection-smoke.R`
  (L423-439), `qseries_v1_release_check.py`, `validate-mission-control.py`, the
  dashboard sidecars, and `test-structured-re-conversion-contracts.R`, after the
  rename chip merges and `main` is pulled. The `skip_on_cran` boundary sub-test
  (`test-nongaussian-structured-boundary.R:524`) must be updated then.
- `sd_relmat` recovers modestly low under a smooth relatedness `Q` (finite-sample
  shrinkage, internally consistent with the empirical mode SD). A recovery test
  should average over seeds or use a tolerance band, not a point equality.
- `pdHess=FALSE` acceptable per locked doctrine; not chased.

## 11. Team Learning

The single-field structured plumbing is threaded through many surfaces
(guard, spec, `make_tmb_data` per-branch, `add_covariance_block_tmb_data`,
`add_covariance_probe_parameter`, `split_tmb_random_effects`, `split_tmb_sdpars`,
`profile_sd_internal`, and the per-model-type C++ blocks). A scoped second field
is cheapest to add via the two GLOBAL hooks (`add_covariance_block_tmb_data` for
data, `add_covariance_probe_parameter` for parameter existence/map) rather than
editing every per-branch block. `profile_sd_internal` previously mapped ALL
structured terms to `log_sd_phylo`; a second internal SD scale requires an
explicit term-to-field check there.
