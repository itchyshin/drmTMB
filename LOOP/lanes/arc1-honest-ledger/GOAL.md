# GOAL: arc1-honest-ledger (IMMUTABLE; re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then `checkpoint.md`, then `ultra-plan.md`, then continue.

## Mission
Arc 1 of the drmTMB R–Julia parity programme: make the parity ledger honest before any coverage is
widened. Finish line: `Rscript tools/parity-honesty-gate.R` prints `uncited=0 defect=0` at the
DRModels pin `da8b3f8711beb5ef3186b890544c2e7850c7f194`. Every non-GREEN row of the 45 in
`docs/design/parity-matrix.md` is FENCED, CITED-PARTIAL, CITED-LIMITED, or OWNER-DECISION by the rules in
`ultra-plan.md` (Pre-G0 amendments A4 to A8). Every route the bridge admits joins a ledger row or a
refusal gate. No admitted route fits a different model than the user wrote. Every open programme
issue that describes landed work has an evidence-cited disposition. The work ships as DRAFT PRs.

## Headline
One command, `tools/parity-honesty-gate.R`, turns "the ledger is honest" from a reading exercise into a
check that fails, and keeps it honest after Arc 1 ends.

## Owner answers (Shinichi, 2026-09-24; binding)
- G0: plan v2 approved (`ultra-plan.md`).
- T1 AGHQ, T2 VA/ELBO, T3 heritability/icc/repeatability on bridge fits, T4 `anova()` LRT, T6 Gaussian
  phylo RI + slope: **fence all now** (R refusal naming the native route); exposing any of them is Arc 2.
- T5: integrator difference (GHQ-32 on the bridge vs Laplace natively, same model): **ledger row plus a
  one-line note in the bridge fit's `summary()`**.
- T7: **fold #1304** into a fresh Claude draft PR with provenance; its new API goes to Arc 2. Draft the
  #1304 comment; post it only after Shinichi says yes.
- T8 moot: #1421 merged as `7f7293f2d`; Arc 1 is based on `origin/main`.

## Invariants
- One lane: this worktree and its branch. Claim paths with `lane_lease.sh` before writing.
- Never edit a foreign branch (#1304, #1110, #1111, #1417 to #1419, #1033) or `R/drmTMB.R`.
  #1111 also edits `R/julia-bridge.R`: S0 checks the overlap; overlap = ticket T10 for Shinichi.
- Never change an existing row's `claim_status` (maintainer-only). New rows enter at the lowest status
  their evidence supports, never `covered`.
- A refusal may only remove a wrong silent answer, never a route users have working; otherwise it becomes
  a ticket.
- Every live run is estimated first; over 30 min stops for approval (D-139). Julia 1.13.0 via `JULIA_HOME`,
  DRModels pin checkout `~/local-scratch/lanes/DRModels-pin-da8b3f871`, `OPENBLAS_NUM_THREADS=1`.
- The tip-identity receipt is regenerated LAST in any PR that touches `R/`.
- An "already true" claim needs a command run against `origin/main`.
- At most 5 sub-agents live; never `SendMessage` a running agent.

## Authoritative WHAT
`ultra-plan.md` (plan v2; the Pre-G0 amendments override the text below them). This file wins on what must
never be lost.

## Definition of done
`gate-check --reverify` passes every gate in `.unlazy/arc1-honest-ledger/` (D1 to D5 plus the leaf gates);
Rose's S11 adversarial review is recorded; draft PRs are open; the after-task report, check-log row, and
plan-actual reconciliation are written; nothing is merged.

## Pre-authorisation (G0)
Scoped edits in this worktree on the OWNS paths; lane leases; local Rscript and Julia runs estimated at
30 min or less; testthat and `devtools::test()`; regeneration of parity artefacts; `gate-check --claim`
and `--reverify`; local commits; push arc1 branches; open DRAFT PRs.

## Must stop for
Any merge; any GitHub comment, close, or label; any `claim_status` change; editing a foreign branch or
`R/drmTMB.R`; a run estimated over 30 min; evidence that a refusal would remove a working route; a
surprise that invalidates the plan.
