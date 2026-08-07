# GOAL — drmTMB-0.7-cran-readiness (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Advance cran-release-gate to highest proven rung **source-clean** (or honest
**NOT READY**), record a local candidate tarball SHA, write after-task + LOOP
checkpoint. Do **not** upload to CRAN.

## Headline

Claim-freeze + D-49 source-clean after #930 (`8df6f240` on main; this branch
includes docs from #931 @ `7bacb9e2c`).

## Invariants

- One lane: worktree `~/local-scratch/worktrees/drmTMB-07-cran-exec`, branch
  `cursor/07-cran-readiness`. Never the dirty primary checkout.
- Never claim "CRAN ready" — report highest proven rung only.
- `DESCRIPTION` stays `0.6.0` until an explicit freeze slice bumps to `0.7.0` (D-86).
- D-93/D-117 discharged for readiness (G0 2026-08-07): profile RE-SD +
  `profile.boundary` warning; PASS claim remains withheld.
- No Totoro/DRAC in this goal. No AGHQ / missing-data G4+ / WITHHOLD re-prereg.
- Do not touch #858 / #893 / #869.

## Authoritative WHAT

→ `LOOP/ultra-plan.md` · `~/.cursor/plans/0.7_cran_ultra-plan_42828b75.plan.md` ·
`scratchpad/2026-08-05-arc-07-cran-release-readiness.md`

## Definition of done

1. Claim surfaces honest vs ledger (187 IF / 55 PFR).
2. cran-release-gate ledger for Gates −1/0/1 exists; `cran_release_gate.py`
   reports READY FOR CLAIMED RUNG at **source-clean** (or lists honest failures).
3. Local candidate tarball SHA recorded under `docs/dev-log/release/0.7.0-cran-gate/`.
4. After-task + Melissa plan-vs-actual written; STOP before upload.
