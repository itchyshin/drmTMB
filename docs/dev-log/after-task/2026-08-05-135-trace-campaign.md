# After-task — 135-trace Prong B campaign (2026-08-05)

**Reader:** next Cursor / Claude / Codex agent on the interval-evidence lane.  
**Purpose:** record what the Totoro campaign actually promoted, what it
withheld, and where the receipts live.

## Outcome

Promoted **5** of 14 candidate cells `point_fit_recovery` →
`interval_feasible`. Census: model_surface **182 → 187**
`interval_feasible`, **60 → 55** `point_fit_recovery`;
`FROZEN_CENSUS_POINT_FIT_RECOVERY` **59 → 54**.

| PASS (promoted) | WITHHOLD (stay PFR) |
|---|---|
| `mc-0568`, `mc-0576`, `mc-0595`, `mc-0596`, `mc-0653` | `mc-0593`, `mc-0594`, `mc-0597`, `mc-0418`, `mc-0436`, `mc-0446`, `mc-0450`, `mc-0454`, `mc-0425` |

## What ran

- Worktree: `~/local-scratch/worktrees/drmTMB-135trace`, branch
  `cursor/135-trace-campaign`, runner SHA `6618e4b30`.
- Totoro: rsync to `/home/snakagaw/hsq_work/drmTMB-135trace-cursor`,
  smoke `mc-0568` matched local, then GNU **parallel -j64** over 135 jobs;
  joblog `ok=135 fail=0` in ~3 minutes wall.
- Recorded engine: `stats::profile()` → `TMB::tmbprofile` (grid). Clamp /
  both-sides LR / unimodality computed on every receipt (not hard-coded).
- Review: `tools/review-135-trace-receipts.R` + `FISHER-REVIEW.md` (clause 10).

## Artifacts

`docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/`

- `PREREGISTRATION.md`, `CELL-VERDICTS.md`, `FISHER-REVIEW.md`
- `totoro-receipts/` (135), `totoro-meta/` (joblog, SOURCE_SHA)
- `reconcile/mc-*-reconcile.tsv` for the five PASS cells
- Tools: `run-135-trace-campaign.R`, `run-135-trace-totoro.sh`,
  `review-135-trace-receipts.R`, `promote-135-trace-passes.py`

## Ledger / NEWS

- `cells.tsv` / `evidence.tsv` / `transitions.tsv` updated for five PASS cells.
- `tools/capability_ledger.py`: `FROZEN=54`, `ARC135_TARGETS`,
  `ARC135_WITHHELD` guard.
- `NEWS.md` entry for the five routes; structured-σ claim_boundary names ML
  bias + REML unavailable on `mc-0595` / `mc-0596` / `mc-0653`.
- `python3 tools/capability_ledger.py --check` OK; ledger unittest OK;
  `profile_truth_gate.py` exit 0. Adversarial flip of withheld `mc-0593` fails
  the frozen census and the WITHHOLD guard.

## What this did NOT do

- Did **not** promote the aspirational +14 / frozen 59→45.
- Did **not** claim coverage, calibration, or inference-ready.
- Did **not** touch PR #858, D-117 discharge, PR #926, coi/Tier-2, or primary
  checkout debris.
- Did **not** push the feature branch (owner push gate).

## Plan vs actual

See `docs/dev-log/after-task/2026-08-05-135-trace-plan-vs-actual.md`.
