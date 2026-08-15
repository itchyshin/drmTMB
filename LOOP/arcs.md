# ARCS — drmTMB interval-claim truth audit

Status: `TODO` · `WIP` · `DONE` · `GATE` (needs human)

## Wave 1 — CLASSIFY (checkpoint `T1-classify`) — ~90 min, no compute

| # | Arc | Agent · model | Status |
| --- | --- | --- | --- |
| **T1** | Document the gate rule, the manifest derivation, and the exact extension point for a new cohort. Read `tools/profile_truth_gate.py`, `tools/emit-profile-truth-manifest.R`, `tools/arc2_profile_reconcile.py`, the four `reconcile-arc1-*.py`. → `docs/dev-log/2026-08-15-truth-gate-extension-points.md` | `tmb_engineer` · sonnet/high | TODO |
| **T2a–c** | Partition the 209 uncovered cells; classify each as **(a)** genuinely unchecked, **(b)** checked by a stronger instrument, **(c)** legacy import with no run. Start from `evidence.tsv`'s `evidence_class`. **Record what the record says; do not judge.** → 3 × `scratchpad/uncovered-cohort-N.md` | `Explore` ×3 · haiku/low | TODO |
| **T3** | Adjudicate into the defect list; quantify **re-check vs re-run** per cohort. → `docs/dev-log/2026-08-15-interval-truth-coverage-map.md` | `general-purpose` · sonnet/high | TODO |

### GATE `T1-classify` — STOP. Report to Shinichi before ANY compute:
1. the **re-check vs re-run split** (decides whether Totoro/DRAC is needed at all);
2. the **1-seed instrument problem** — the gate calibrates for 3–5 seeds (`MISS_MAGNITUDE_TOL=0.05`,
   `MISS_COUNT_TOL=1`); at one seed only the magnitude arm can fire. Accept magnitude-only verdicts
   and say so, or top up seeds (compute). **Owner's call.**
3. the **52 receiptless + 6 `association` cells** — need a scoping decision, not silent absorption;
4. the **two known blockers** (`runner_sha256` mismatch on `mc-0421/0423/0424`; `mc-0423` receipts
   built under `n_founders=4` vs current default `8`).

## Wave 2 — EXTEND the manifest (`T2-manifest`) — ~2 h — NOT BEFORE THE GATE

| # | Arc | Agent · model | Status |
| --- | --- | --- | --- |
| **T4a–c** | Per cohort, **derive** `true_value` from that cohort's fixture builders → `scratchpad/truth-derivation-<cohort>.R`. Do NOT edit the shared script. | `simulation_tester` ×3 · sonnet/med | TODO |
| **T5** | **Sole writer** of `tools/emit-profile-truth-manifest.R` — fold in all three derivations in one pass. Extend the sweep in `tools/tests/test_profile_truth_gate.py:97-120`. **Leave the Arc-1 reconcilers alone.** CI green. | `general-purpose` · sonnet/med | TODO |

## Wave 3 — RE-CHECK and ADJUDICATE (`T3-verdicts`) — ~3 h

| # | Arc | Agent · model | Status |
| --- | --- | --- | --- |
| **T6a–d** | Run the extended gate over the re-checkable cells using the **existing** rule. Record every verdict as *magnitude-only* where one seed. | `simulation_tester` ×4 · sonnet/med | TODO |
| **T7** | Adjudicate every miss. Demote with the fixed wording. Copy the `transitions.tsv:1300-1301` schema precedent literally (no `evidence_tier` column; tier change recorded as prose in `reason`). | `inference_reviewer` · sonnet/high | TODO |

The **52 receiptless + 6 association** cells are NOT in this wave. Any re-run or seed top-up is a
**separate compute slice** with a measured pre-run (D-139) — never folded into T6.

## Wave 4 — VERIFY, RECONCILE, CLOSE (`T4-close`) — ~60 min

| # | Arc | Agent · model | Status |
| --- | --- | --- | --- |
| **T8** | MECHANICAL-VERIFY: manifest covers what the map says; CI green; counts match `cells.tsv` | `Explore` · haiku/low | TODO |
| **T9** | Adversarial verify — **try to refute** the coverage claim | `inference_reviewer` · **opus**/high | TODO |
| **T10** | Close: after-task; mark `docs/dev-log/release-audits/q-series-v1-release-status.md` **superseded** (a staleness fix — it is generated from a superseded 104-row board and is NOT a contradiction to chase); AGENTS.md pointer; plan-vs-actual | `systems_auditor` · sonnet/med | TODO |
