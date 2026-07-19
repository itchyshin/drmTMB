# mc-0227 — cumulative_logit mu random-slope RE-SD coverage via O3 (AGHQ + Cox–Reid)

**Date:** 2026-07-18 · **Venue:** Totoro (`OPENBLAS_NUM_THREADS=1`) · **Commit:** `1ed90599`
**Estimator:** O3 = adaptive Gauss–Hermite (nodes=25) over the scalar slope RE + Cox–Reid restricted
likelihood over the fixed effects (incl. cumulative_logit cutpoints). Pure R (`R/aghq-coxreid.R`);
no TMB/DLL. **Verdict:** memo-blind D-43 **3/3 PROMOTE** → `inference_ready_with_caveats`,
certified floor **M=80**.

## Design (frozen pre-registration: `scratchpad/o3-cumlogit-coverage-gate-spec.md` rev 2)

- **Estimand:** population SD of the mu random slope, `u ~ N(0, σ²)`, true **σ = 0.5**; iid-**uncentered**;
  `η = 0.7·x + x·u[id]`, no intercept (cutpoints carry location, K=4, cutpoints c(−1,0,1.2)).
- **Grid:** M ∈ {40, 80, 160, 320}, n_each = 15, **N = 1200/cell**, seed_base 20260718.
- **Interval:** `drm_o3_profile_ci()` — profile of the Cox–Reid restricted objective in log σ,
  `exp()`-back-transformed (natural RE-SD scale), plain **χ²₁ pivot** (disclosed; not boundary-corrected).
- **Scoring:** finite-profile + **one-sided** (both-NA reps = computability failure, excluded + tallied
  as `n_fail`; one-sided intervals scored on their single computable bound).
- **Gate:** exact-binomial 95% CI **overlaps [0.925, 0.975]**; M=320 positive control (coverage ≉0/≉1).

## Results (all four cells NOMINAL)

| M | coverage | exact-binomial 95% CI | profile_finite_rate | one_sided | n_fail | truth_above / below | rel_bias |
|---|---|---|---|---|---|---|---|
| 40 | 0.9515 | [0.9378, 0.9630] | 0.998 | 186 (15.5%) | 2 | 28 / 30 | +0.0% |
| **80** | 0.9457 | [0.9313, 0.9578] | 0.997 | 26 (2.2%) | 4 | 35 / 30 | −0.1% |
| 160 | 0.9596 | [0.9467, 0.9700] | 0.989 | 1 | 13 | 21 / 27 | +0.1% |
| 320 | 0.9508 | [0.9369, 0.9624] | 0.983 | 0 | 21 | 26 / 32 | +0.1% |

Every CI overlaps [0.925, 0.975] and none over-covers (all ci_hi ≤ 0.97). Point bias ≈0% at every M
(firewall: earns no coverage credit). **Positive control M=320 (0.9508) confirms the exp/natural-RE-SD
scale contract.** Certified floor **M=80** (first clean non-exploratory rung); **M=40 clears mechanically
but is exploratory/boundary-heavy** (15.5% σ̂→0 pile-up, most reseed-fragile) — not the reporting floor;
M=160/320 confirm with ~0 boundary. Directional: mild large-M lean toward miss-from-below = mild Cox–Reid
over-correction, underpowered, diagnostic only.

## Files
- `coverage-iid-raw.tsv` — **M=320** per-replicate raw (1200 rows; from the parallel M=320 run).
- `coverage-iid-summary.tsv` — M=320 summary. `coverage-iid-manifest.tsv` — provenance (git_sha, nodes,
  seed_base, host).
- `campaign-main-M40-M80-M160.log` — the main sequential run's per-M summary lines for M=40/80/160.

**Provenance note (honest):** M=40/80/160 came from the sequential main run and M=320 from a parallel
run (same `SEED_BASE=20260718`, so M=320's seeds match what the main run would have used — coherent).
The main run was terminated after M=160 to free cores (its redundant M=320 duplicated the parallel run),
so **per-replicate raw for M=40/80/160 was not persisted to TSV** (the driver writes raw only at the end);
their per-M summaries are preserved in `campaign-main-*.log`. M=320 raw is complete. The summary numbers
above are the gate evidence; per-rep raw for the smaller M is re-derivable by re-running those cells if
ever needed.

## Reproduce
```
# On Totoro, from a fresh main clone (pure-R estimator; no compile):
OPENBLAS_NUM_THREADS=1 NSIM=1200 NCORES=150 MS=40,80,160,320 NODES=25 SEED_BASE=20260718 \
  OUTDIR=<dir> Rscript tools/run-o3-cumlogit-coverage.R
```

## Review trail
- Estimator adversarially derived + verified (S1 14-agent workflow; design `docs/design/224`).
- Gate-spec S8-ratified (Fisher + Rose, CONDITIONAL-DONE, fixes folded).
- **Pipeline implementation audited** against the frozen gate at the running commit (5-link adversarial
  audit → TRUSTWORTHY, no blocking defects).
- **S11 D-43:** 3 fresh memo-blind judges (inference-coverage · estimand-scale · applied-honesty) →
  3/3 PROMOTE, floor M=80.
