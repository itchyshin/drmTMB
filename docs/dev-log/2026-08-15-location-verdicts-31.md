# 31 location verdicts, recovered and checked with zero compute

**Date:** 2026-08-15 (overnight) · **Lane:** `claude/lane-overnight-0815`

## What happened

The 2026-08-15 audit left 31 cells at `interval_feasible` with a retained profile receipt on disk but
**no recoverable `true_parameter_scale`** — it had swept only the frozen campaign contracts. An
overnight recovery pass searched three further surfaces and **recovered truth for all 31**:

| mechanism | cells |
| --- | ---: |
| explicit `true_value` column in `2026-08-05-135-trace-campaign/all-receipts.tsv` | 5 |
| campaign-binding `target_truth`/`truth`, 18 of them cross-validated against an exact fixture-builder constant | 26 |

Several source constants live only at off-mainline commits (`dc62878e6`, `5f4a72b74`), reachable via
`git show` — the same pattern the runner-provenance recovery already documented.

## The check

Each cell's retained interval(s) were compared against its recovered truth using the truth gate's own
rule (`MISS_MAGNITUDE_TOL = 0.05`), joining on the receipt that names the target.

**Result: 31/31 pass — and not marginally. Every retained interval BRACKETS its truth; the worst
relative miss across all 31 cells is 0.0%.**

Five cells (`mc-0568`, `mc-0576`, `mc-0595`, `mc-0596`, `mc-0653`) carry 5 seeds each, so both arms of
the gate rule are reachable and both pass. The other 26 are single-seed: **magnitude-only**, which is
the weaker statement — no single interval missed by more than 5% of scale — and every claim resting on
them must say so.

`location_checked` moved `unchecked → passed` for all 31. Claiming-cell totals: **176 passed · 44
unchecked · 6 not_applicable** (the 44 are exactly the 2026-07-11 import; see
`2026-08-15-import-44-shape-audit.md`).

## Two judgment calls, recorded

**`mc-0282` — two DGPs claim this cell.** The contract
`2026-07-31-b2-e0-q2-reml-execution-authorization.tsv` declares truth 0.55 for dgp
`b2_gaussian_phylo_q2_reml_intercept_v1`, but **no receipt for that dgp_id exists anywhere** — it was
never executed. The receipt actually on disk is a different DGP (`arc2_gaussian_reml_phylo_mu_q2_sd`,
truth 0.6, `tools/arc2-phylo-sigma-fixtures.R:138`). **0.6 was used.** Independent corroboration: the
`UNGATED` exemption comment in `tools/tests/test_profile_truth_gate.py:44-62` records a hand-check
against *the same* 0.6 and reports all five seeds bracketing it. Two routes, one answer.

**`mc-0300` / `mc-0312`** rest on the frozen contract value (0.30) alone — the cited `binding_source`
names the right file but the wrong constant (0.16 there), and no exact fixture script was found in any
commit. Cross-checked only by the retained trace bracketing it. Weaker provenance than the other 29;
flagged rather than smoothed over.

## What this does NOT establish

- **Not coverage.** Bracketing one retained interval is not a calibration statement; 26 of the 31 rest
  on a single seed.
- **Not a tier change.** Every one of these cells keeps the tier it had; `location_checked` is the
  orthogonal fact (`docs/design/255`).
- **Not independent of the contracts.** 26 truths derive from frozen campaign contracts; 18 were
  cross-validated against fixture code, 8 were not.
