# After Task: AGHQ + non-Gaussian REML arc → mc-0227 cumulative_logit RE-SD coverage promotion

## 1. Goal

Give drmTMB two random-effect integration levers for non-Gaussian families — Cox–Reid restricted
likelihood (non-Gaussian REML) and adaptive Gauss–Hermite quadrature (AGHQ) — validate them against
external oracles, then use them to re-score the small-cluster non-Gaussian RE-SD coverage cell mc-0227
(cumulative_logit `mu` random slope) for **nominal** interval coverage, not just caveated point recovery.

## 2. Implemented

- **O2 — binomial Cox–Reid REML by gate-relaxation.** Relaxed the two Gaussian-only gates
  (`R/drmTMB.R:234` + `drm_validate_reml_spec`) to admit `binomial`. The existing `beta_mu` Laplace fold
  IS the joint-Laplace restricted likelihood == `glmmTMB(REML=TRUE)`. No C++ change.
- **O3 — nested AGHQ + Cox–Reid estimator** (`R/aghq-coxreid.R`, pure R): adaptive-GH marginal over the
  scalar RE (Newton mode-finding + warm-start cache) + Cox–Reid adjusted profile over the fixed effects
  (incl. cumulative_logit cutpoints on the pinned θ₀+log-gap scale); profile CI on the natural RE-SD scale.
- **Coverage campaign driver** `tools/run-o3-cumlogit-coverage.R` (one-sided finite-profile scoring,
  directional counts, manifest, SMOKE mode).
- Design doc `docs/design/224`; frozen gate-spec `scratchpad/o3-cumlogit-coverage-gate-spec.md` (rev 2).
- Ledger: mc-0227 `point_fit_recovery → inference_ready_with_caveats` (estimator kept `ML`), +evidence
  +transition, surfaces regenerated.

## 3. Result and gate

Totoro N=1200/cell, true SD 0.5, n_each=15, iid-uncentered, nodes=25, seed_base 20260718:

| M | coverage | 95% CI | finite_rate | one_sided |
|---|---|---|---|---|
| 40 | 0.9515 | [0.9378, 0.9630] | 0.998 | 15.5% |
| **80** | 0.9457 | [0.9313, 0.9578] | 0.997 | 2.2% |
| 160 | 0.9596 | [0.9467, 0.9700] | 0.989 | 0.1% |
| 320 | 0.9508 | [0.9369, 0.9624] | 0.983 | 0% |

Every CI overlaps [0.925, 0.975]; none over-covers; positive control M=320 clean. Point bias ≈0% all M.
Frozen gate = mc-0242's `[0.925,0.975]` exact-binomial overlap + finite-profile + one-sided scoring.
**Memo-blind D-43: 3/3 PROMOTE**, certified floor **M=80** (M=40 clears but is exploratory/boundary-heavy).

## 4. Mathematical contract (Noether / S1, DONE)

The recombination is **nested and external**, NOT a joint TMB `random=` fold: AGHQ marginalizes the latent,
then Cox–Reid adjusts the fixed effects on that AGHQ-marginal (`doc 224 §2`). The joint-determinant identity
that licenses the β-fold assumes the latent is Laplace-integrated, so AGHQ cannot live inside `random=`.
Three distinct objects (O1 Laplace-ML, O2 joint-Laplace-REML=glmmTMB, O3 nested); O2-alone is ~−3% for
ordinal → O3 needed. Estimator validated: ordinal AGHQ vs brute-force 6.4e-9; binomial vs glmer 3.6e-5;
nq=1==Laplace exact; O2 binomial == glmmTMB REML 7.3e-9.

## 5. Decisions & rejected alternatives

- **Keep `estimator="ML"` in the ledger** (Rose F2): a new `AGHQ+CoxReid` token would drop mc-0227 from the
  `capability_ledger.py:872` ML family-map split and flip the slope to "absent" — no test catches it.
  Method encoded in `claim_boundary`/`evidence` instead. Verified the family-map still shows slope present.
- **Certified floor M=80, not the mechanical M=40** (D-43 chair): M=40 is exploratory with a 15.5% σ̂→0
  boundary pile-up (most reseed-fragile).
- **χ²₁ pivot, not the 50:50 boundary mixture** (deferred): disclosed as a caveat; no rung over-covered.
- **Totoro over DRAC** for this run (already half-done + trustworthy); DRAC reserved for the 4-cell batch.

## 6. Files created / modified

- New: `R/aghq-coxreid.R`, `tools/run-o3-cumlogit-coverage.R`, `docs/design/224-*.md`,
  `tests/testthat/test-aghq-coxreid.R`, `tests/testthat/test-reml-binomial-coxreid.R`,
  `docs/dev-log/simulation-artifacts/2026-07-18-o3-cumlogit-slope-coverage/` (README + M=320 raw/summary/
  manifest + main log), this after-task.
- Modified: `R/drmTMB.R` (two REML gates admit binomial), `docs/dev-log/dashboard/…` (ledger + surfaces),
  `tools/tests/test_capability_ledger.py` (point_fit_recovery 163→162),
  `docs/dev-log/dashboard/estimator-surface-conformance.tsv` (gate line drift).
- Scratchpad (never-commit): gate-spec, D-43 panel workflow, apply script, spikes.

## 7. Checks run

- `python3 -m unittest tools.tests.test_capability_ledger` → **37/37 OK**; `capability_ledger.py --check` OK.
- `test-aghq-coxreid.R` 16/16; `test-reml-binomial-coxreid.R` 8/8; full REML suite 96/0; conformance 78/0.
- Estimator re-validated after the Newton+cache optimization (exact reproduction of the smoke; 16/0).
- **Pipeline implementation audit** (5-link adversarial, at the running commit): TRUSTWORTHY, no blocking
  defects — the running driver implements the frozen gate term-for-term.

## 8. Tests of the tests

- The D-43 panel is fail-closed: its first run received empty args (a JSON-string arg-passing bug) and
  correctly WITHHELD rather than rubber-stamping. Fixed (parse args-if-string + a zero-cell guard); the
  re-run on real data returned 3/3 PROMOTE.
- The ledger apply-script is idempotent-guarded and asserts `estimator=="ML"` before editing.

## 9. Consistency audit

Family-map (`vignettes/includes/capability-ledger-family-map.md`) shows cumulative_logit `mu: slope
implemented → inference_ready_with_caveats mc-0227 (estimator=ML)`. cells/evidence/transitions/census/
surface all regenerated by `--write` and pass `--check`. mc-0228 (REML-rejection sibling) untouched.

## 10. What did not go smoothly / known residuals

- **Totoro oversubscription:** a parallel M=320 run was launched twice (duplicate), pushing load to 420;
  killed the duplicate + the main run's redundant M=320. **Per-rep raw for M=40/80/160 was not persisted**
  (main killed before its end-of-run write); summaries preserved in `campaign-main-*.log`; M=320 raw complete.
- **Residuals for the claim:** M=40 exploratory (15.5% boundary pile-up); χ²₁ pivot not boundary-corrected
  (candidate mechanism if calibration drifts on reseed); no external ordinal oracle (internally validated);
  guarantee conditional on the finite-profile + one-sided scoring rule; O2 joint-Laplace does NOT reach
  nominal for ordinal.
- **Fixed a real estimator bug:** `K <- length(unique(y))` mis-counted ordinal categories when one is absent
  → now `n_categories` is passed explicitly (Fisher catch).

## 11. Team learning

- **Adversarial S1/S8 + pipeline audit earned their cost:** S1 caught the nested-vs-joint-fold seam before
  any code; S8 caught the ledger estimator-token trap; the mid-flight pipeline audit confirmed the running
  driver matched the frozen gate so ~11 h of compute wasn't wasted on a buggy pipeline.
- **Cross-repo:** gllvmTMB is on the same arc (their binomial "too-narrow = Laplace signature" = lever 1;
  "REML payoff at n=50" = lever 2). FYI note updated in their dev-log; the scalar O3 does NOT drop into
  their d-dim latent (AGHQ becomes a curse-of-dimensionality grid).
- **Workflow arg-passing:** pass `args` as an actual JSON value; scripts should still parse-if-string.

## 12. Next actions

- **Optional hardening:** a matched-Laplace-fold or external ordinal reference to upgrade the
  internally-validated estimator; a boundary-corrected (50:50 χ²) pivot to firm up M=40.
- **The 4-cell mu-slope batch** (skew_normal mc-0464, tweedie mc-0539, zero_one_beta mc-0575; cumulative_logit
  mc-0227 now done) — the next arc; run it as a DRAC job array.
- **PR #794** (parked capability-surface tooling) rebase remains separate.
