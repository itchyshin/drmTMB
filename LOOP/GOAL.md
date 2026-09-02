# GOAL — drmTMB true-parity overnight lane, 2026-09-02/03 (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then LOOP/checkpoint.md, then continue.

## Mission
Run the next arcs of drmTMB's half of true R<->Julia parity unattended until ~05:00 local (2026-09-03),
starting from main @ 0ceb77eb0 (the reverse-parity lane, the base-R label contract, A4/A5, the q4 SE
receipt, promotion wave 1 and the pkgdown index are all merged). Each arc lands as a green PR that the
lane itself merges (pre-authorised, D-208), with an unlazy ledger gate met or ABANDONED with reason, and a
checkpoint on disk. Finish line for the night: the label contract covers every bridge route and the
legacy predict-time rewrite is gone; then, in order and as time allows, the reverse-gap accessors (#1115),
the objective_at()/start= label widening, the board projection + deterministic indefinite test, and the
P2 inference-qualification pilots on Totoro (pre-run first).

## Headline
Extend `coef_labels` (design 258 §7) to the structured / bivariate-known-structured / joint / cross-family
bridge payload builders so DRM.jl's echo covers every route, then delete the legacy `gsub()` rewrite in
`drm_julia_predict_fixed_eta()` and turn gate S3-G4 from ABANDONED back to MET. This is the last hole in
"engine = julia shows exactly the names engine = tmb shows".

## Invariants
- One lane, this worktree (`claude/lane-true-parity-night`); arcs branch from `origin/main`; PRs to main.
- DRM.jl is READ-ONLY (a live foreign lane); Julia-side needs go to `claude/rev-parity-drmjl-findings`.
- DRM.jl pinned in the throwaway clone at main 77513aa0 (re-pin only if that lane asks).
- No CRAN action (D-164), no release, no registration, no public claim beyond a receipt.
- Every "done" is a re-run ledger gate (`.unlazy/night/`), verified by LOG not exit code; a pipe never masks
  an exit code (`set -o pipefail` or write to a file and read it).
- Before any PR: the touched test files run once with `env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS` (CI has no
  Julia, no sibling checkout, Linux LAPACK); `pkgdown::check_pkgdown()` if NAMESPACE grows;
  `python3 -m unittest tools/tests/test_capability_ledger.py`; regenerate whole-file receipts LAST.
- D-139: state an estimate before any run; >30 min needs a pre-run shown in the log; Totoro ≤150 cores,
  BLAS pinned; never GitHub Actions for campaigns.
- Pace: Sonnet/Haiku children; Opus once per arc for the adversarial pass; checkpoint every arc.

## Authoritative WHAT
-> LOOP/ultra-plan.md (the approved plan + D-208 envelope + this night's arc list). This file wins on
"what must never be lost".

## Definition of done (for the night)
Arc N1 merged (label contract on all routes, legacy rewrite removed, S3-G4 MET); every later arc either
merged-green, or checkpointed with its open gate named; LOOP/checkpoint.md current; after-task + handover
for the night landed; Melissa reconcile written; lane lease released.

## Pre-authorisation (D-208, Shinichi 2026-09-02 evening)
Scoped edits; worktrees; filtered tests; local commits; pushes of lane branches; DRAFT PRs; MERGING any PR
this lane opens once CI is green and its ledger gates are met (merge commits, each logged); Totoro pilots
under ≤150 cores with a pre-run shown; deleting merged lane branches.

## Must stop for
Any DRM.jl edit; any CRAN/release/registration action; a public claim not backed by a receipt; a change
that reopens D-179/D-181/D-202/D-204; compute beyond the Totoro cap or beyond an estimate without a
pre-run; a surprise that invalidates the plan (bring it back to G0 in the morning).
