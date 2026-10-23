# R–Julia true-parity programme — frozen-manifest re-estimate (2026-09-01)

Decision doc for Shinichi. Runs nothing. Supersedes the un-receipted "157–297 active agent-hours"
figure carried by the 2026-09-01 handover. All hour figures are AGENT-INFERRED estimates from the
frozen manifest below — leads for a decision, not a delivery promise (D-139 applies to every run).

## Frozen manifest (what "every implemented native-R workflow" means, measured today)

- **12 ledger capabilities** (`inst/extdata/julia-capabilities.tsv`): 11 claim_status=covered,
  1 partial (cross_family_latent — no native comparator by design; simulation-recovery route).
- **10 bridge routes** with r_bridge_status=experimental; 0 promoted. Promotion = the programme.
- **4 evidence axes per capability**: native R · direct Julia · engine="julia" bridge · inference.
- Banked already (does NOT need re-doing): G1 recovery evidence for the covered rows; the
  2026-08-31 integration batch; alias/g_tol/algorithm bridge controls (#1112, 125/0 suite);
  polytomy validation contract; depth-scaled inits + bootstrap nonconverged-discard (#573);
  the public scoreboard page (G6 partially landed today, DRM.jl branch
  `docs/drmtmb-parity-scoreboard`).
- **New blocker of record**: DRM.jl #575 — on the biv-q4-phylo-REML fixture the Julia solver lands
  at a slightly inferior optimum than TMB (|Δ logLik| ≈ 1.6e-2, g_tol-insensitive). Blocks q4
  bridge promotion and re-prices G2.

## Costed arc sequence (each arc separately approvable; nothing launches without its own gate)

| Arc | Gate | Scope | Est. agent-h | Compute | Hard gate before running |
|---|---|---|---|---|---|
| P1 | G2 | Matched point-parity receipts for all 10 bridge routes on committed fixtures; root-cause + fix the #575 class (objective-at-point evaluator first — cheap and diagnostic) | 20–35 | local | none (≤30 min per cell) |
| P2 | G3 | Profile + bootstrap parity qualification per route (q4 all-targets contract; small convergent cells; boundary honesty on unbounded endpoints) | 30–50 | local + Totoro pilots ≤150 cores | D-139 estimate + pre-run per cell family |
| P3 | G4 | Threaded bootstrap/profile parallel-correctness and determinism checks | 10–20 | local/Totoro | pre-run |
| P4 | G5 | Matched WARM-workflow performance grid (the only route to any bridge speed number) | 15–25 + campaign | **Totoro** (never Actions, D-50) | the pre-run test below + Shinichi's explicit go |
| P5 | G6–G7 | Docs/vignette closure, scoreboard maintenance, integration receipts in CI-light form | 15–25 | local | none |
| — | G8 | Melissa reconciliation of programme plan-vs-actual | 2–4 | — | — |

**Re-estimated total: ~92–159 agent-hours** — below the prior 157–297 figure because G1 is banked,
G6 partially landed today, and the manifest is smaller than the blanket phrasing implied. The prior
figure is retired, not contradicted: it priced an unfrozen scope.

## G5 pre-run test design (so approval is a one-decision act later)

1 fixture cell (biv-q4-phylo-reml) × 2 engines × warm start × 3 replicates, single-core pinned
(`OPENBLAS_NUM_THREADS=1`), on Totoro. Expected < 10 minutes. It must prove: non-empty timed
output, warm-up discarded, per-rep receipts retained, and a sane TMB/Julia ratio before the full
grid (12 routes × 2 engines × ≥5 reps) is even estimated. If the pre-run's ratio is dominated by
#575-style optimum mismatches, the grid is postponed — a speed number over non-matching optima is
not a benchmark.

## Sequencing recommendation

P1 first and alone (it is blocking: #575 gates everything downstream), then P2; P4 only after P2
gives matched, converged cells to time. P5 can interleave. Ayumi lane items fold into P1/P2 and are
already partly delivered (drafts on disk; her deterministic 343-tip recipe located, so same-fixture
evidence is reproducible).
