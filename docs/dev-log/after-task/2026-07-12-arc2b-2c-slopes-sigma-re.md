# After Task: Arc 2b/2c — random slopes + a sigma random intercept

**Date:** 2026-07-12 · **Branch:** `feature/arc2b-2c-slopes-sigma-re` (off `main @ 0ba88fd8`) ·
**Commits:** `1c5651a6` (2b) · `1a865948` (2b doc) · `4d99bb44`→`27b5a69c` (2c merge) ·
`705ee195` (2c consolidation).

## Goal

Execute the next arc after Arc 2a (which gave the five no-RE families a `mu` random
intercept): **Arc 2b** — one independent `mu` random slope `(0 + x | id)` for those same
five families (binomial, cumulative_logit, skew_normal, tweedie, zero_one_beta); and
**Arc 2c** — a `sigma` random intercept `(1 | id)` for the identifiable scale families.
Evidence bar: DG2 point recovery with an honest small-cluster ML-Laplace SD-bias caveat
(Fisher's plan-review raised this from a smoke test to an SD-magnitude assertion + a
≥50-seed bias sweep). Coverage (DG3) deferred.

## Implemented

- **2b:** the independent `mu` slope now works for all five families. The only code change
  was a one-line predicate flip in each `validate_<family>_mu_random_terms`
  (`term$type != "intercept"` → `!(term$type %in% c("intercept","slope"))`) plus a message
  update mirroring `validate_beta_mu_random_terms`. The parser, data builder, start/map,
  and the C++ mu-RE loop were already column-generic — **no data-builder or C++ change**.
  Correlated `(1 + x | id)` and labelled `(0 + x | p | id)` blocks stay rejected.
- **2c:** `sigma ~ ... + (1 | id)` now works for **lognormal** and **Gamma(log)**, joining
  gaussian (full) + nbinom2 (int-only). This required threading `re_sigma` through the
  gaussian machinery: guard lift (`validate_positive_continuous_sigma_random_terms`, now
  also blocking a `mu`-RE + `sigma`-RE combination), `re_sigma`/`mu_sigma` in both spec
  builders, `u_sigma`/`log_sd_sigma` in the start + map builders, `"u_sigma"` in
  `random_names`, the grouping var retained via `random_effect_vars`, the un-zero-filled
  `make_tmb_data` sigma fields, and the nbinom2 sigma-RE C++ snippet dropped into
  `model_type == 4` and `== 5`. A `sigma` slope, labelled blocks, and mu+sigma-RE combos
  stay rejected.

## Mathematical Contract

For every fitted univariate family, the `mu` linear predictor now admits an independent
Gaussian random slope: `eta_mu_i = X_mu beta_mu + z_i b_{g(i)}`, `b_g ~ N(0, sigma_b^2)`,
one numeric `z`, no intercept-slope correlation. For lognormal/Gamma the residual-scale
linear predictor admits a random intercept: `log sigma_i = X_sigma beta_sigma + u_{g(i)}`,
`u_g ~ N(0, sigma_u^2)`. All fit by ML with the Laplace approximation; the RE-SD MLE is
consistent but downward-biased at small cluster counts (documented, quantified below).

## Files Changed

- Code: `R/drmTMB.R` (5 slope validators; 2c threading), `src/drmTMB.cpp` (sigma-RE block
  in model_type 4 + 5).
- Tests: `tests/testthat/test-arc2b-mu-random-slope.R` (new),
  `tests/testthat/test-arc2c-sigma-random-intercept.R` (new); reconciled stale assertions in
  `test-cumulative-logit.R`, `test-nongaussian-scale-boundary.R`,
  `test-lognormal-location-scale.R`, `test-gamma-location-scale.R`.
- Evidence: `docs/dev-log/simulation-artifacts/2026-07-12-arc2b-slope-recovery/` and
  `.../2026-07-12-arc2c-sigma-recovery/` (bias tables + READMEs).
- Docs: `NEWS.md` (Arc 2b + Arc 2c sections, honest caveat), `docs/design/04-random-effects.md`.

## Checks Run

- Targeted regression across the affected families + the two new sentinel files + the four
  reconciled boundary/family tests: **560 assertions, 0 failures** (arc2b 100, arc2c 36,
  arc2a 77, nongaussian-scale-boundary 6, lognormal 62, gamma 76, nongaussian-mu-slopes 108,
  cumulative_logit 95).
- `rcmdcheck --as-cran`: **0 errors / 0 warnings / 1 NOTE** — the note is the benign
  new-submission + "version 0.6.0.9000 contains large components" (expected for a dev version).
- Adversarial NOT-DONE review (D-43, 3 fresh lenses): **Correctness DONE** (recompiled + ran
  the suites live: no NaN trap, guards intact, C++ correct, no regressions, Gamma fixed+RE
  combination independently verified); **Evidence/Fisher DONE** (sweeps genuinely ≥50-seed,
  SD-magnitude asserted on the correct scale, no supported/inference_ready over-claim);
  **Scope/Rose NOT-DONE** with valid must-fixes, all now applied (see Consistency Audit).
  Tally 2 DONE / 1 NOT-DONE — below the ≥2 threshold, so the claim holds, and Rose's findings
  were fixed rather than waved through.

## Tests Of The Tests

Fisher's review caught that the pre-existing non-Gaussian slope sentinel was a smoke test
(`SD > 0.03`, single-seed `|cor| > 0.25` — a 90%-biased SD and noise-level BLUP both pass).
The new sentinels therefore assert **SD magnitude** (`|sd_hat - sd_true|/sd_true < tol`), a
latent-scale BLUP correlation, the slope design column, and that a correlated block still
errors. The ≥50-seed bias sweeps (60 seeds each) are the campaign-grade evidence the
single-seed tests cannot be: they measure the systematic downward bias directly.

## Consistency Audit

- NEWS + design doc updated to match the code; the honest "point recovery, not interval
  coverage" caveat is stated verbatim.
- Stale-assertion sweep (Rose principle): every `tests/testthat/` assertion that a slope /
  sigma-RE is rejected for the affected families was found and reconciled (4 files).
- Rose's review additionally caught a stale error hint in `drm_reject_phase1_terms`
  (`R/drmTMB.R:8051`) that still listed lognormal/Gamma as needing scale-RE recovery tests —
  now corrected — and a dead generator citation in the sim-artifact READMEs — now fixed by
  committing the generators as `generate.R` in each artifact directory.
- **Capability ledger/census/surface: REGENERATED.** The paired cells turned out to be
  ML vs REML estimator rows, so only the 7 ML cells were flipped to
  `implemented`/`verified`/`point_fit_recovery` (mu-slope `mc-0061/0227/0464/0539/0575`;
  sigma-int `mc-0242/0382`); the REML rows correctly stay `rejected_by_design` (non-Gaussian
  REML out of scope, SR159). `cells.tsv` + `evidence.tsv` + `transitions.tsv` updated, the
  hard-coded status-count guard moved 288/339/41 -> 295/333/40, and
  `tools/capability_ledger.py --write` regenerated all 30 outputs; `--check` passes.
- **Only remaining item:** the curated artifact `a1bf21a1` (per-family table + aggregate
  counts) still reflects pre-2b/2c state — a follow-up refresh from the regenerated census.

## GitHub Issue Maintenance

No issue opened/closed by this arc (the 0.6.0 arcs are tracked in the candidate-arcs plan,
not per-arc issues). PR not yet opened — see Next Actions.

## What Did Not Go Smoothly

- **2c was mis-scoped as a "snippet."** Three Explore agents plus the plan assumed 2c was a
  guard-lift + C++ snippet. In execution it proved to be a ~10–15-point per-family plumbing
  pass (un-zero-fill `make_tmb_data`, thread `re_sigma` through start/map/`random_names`,
  retain the grouping var), each miss risking the Arc-2a NaN trap. Resolved by delegating to
  a worktree-isolated `tmb_engineer` (Gauss) with the full map + a "revert any family you
  can't land with pdHess" instruction; both families landed cleanly.
- The guard-lift flipped three pre-existing boundary tests (they asserted exactly what 2c
  now supports); these needed hand reconciliation the worktree agent was scoped out of.

## Team Learning

When adding a random-effect capability to a family, the rejection lives in a family-specific
**validator**, but enabling it correctly touches four+ *hidden* plumbing points
(make_tmb_data field population, start-value sizing, TMB map, `random_names`, grouping-var
retention). The symptom of any miss is a NaN objective from a good start (declared-but-unused
random parameter). Always mirror the gaussian/nbinom2 reference end-to-end, and smoke-fit
for `convergence == 0 && pdHess` before believing it.

## Known Limitations

- Point recovery only (`point_fit_recovery`), ML-Laplace; RE-SDs biased low at small cluster
  counts (2b slopes: −2% to −9% at 40 groups, cumulative_logit worst; 2c sigmas: −3% to −4%).
  No interval-coverage (DG3) — that is a separate Totoro campaign.
- 2b is one *independent* slope only; correlated `(1 + x | id)` blocks remain Gaussian-only.
- 2c is intercept-only, lognormal + Gamma only, and NOT combinable with a `mu` RE in the same
  model yet; student/skew_normal/beta sigma-RE deferred (sigma↔nu / sigma↔skew / boundary
  identifiability).

## Next Actions

1. **Refresh the curated artifact `a1bf21a1`** from the regenerated census: the five families
   gain `mu ✓ int + slope`; lognormal/Gamma gain a `sigma` intercept; aggregate counts move to
   295 implemented / 333 rejected / 40 not-implemented.
2. Open the PR for this branch (`--as-cran` is clean: 0/0/1-benign-note).
3. Minor hardening (P2/P3 from the review, non-blocking): add a positive test for the
   `sigma ~ x + (1 | id)` fixed+RE combination (the dropped boundary tests weren't replaced);
   assert `(1 + x | id)` rejection for the 4 slope families that currently only test the
   labelled `(0 + x | p | id)` form (behaviour confirmed identical via the shared parser); add
   a `.cpp` comment noting the model_type 4/5 sigma-RE blocks omit correlation conditioning by
   design (guarded R-side).
4. Later arcs: 2c for student/beta (with Fisher's identifiability probes), the DG3 coverage
   campaign on Totoro, and the AGHQ estimator axis for the logit/binary families.
