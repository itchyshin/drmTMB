# GOAL — useful-0.7 user-facing (IMMUTABLE — re-read at the top of EVERY arc)

## Mission

Land the four first-week user-facing deliverables for a “really useful 0.7”
programme: (1) default uncertainty story frozen in NEWS + `?confint`;
(2) onboarding path fit → `profile_targets()` → `confint(method="profile")` →
`profile.boundary` → when not to trust; (3) parseable family × dpar × RE ×
interval-tier skim; (4) Ayumi-scale `se_group_sd` advice in `large-data`.
No packaging, no CRAN upload, no DESCRIPTION bump.

## Headline

Make a new ecology/evolution user productive in week one without reading the
capability ledger TSV or claiming nominal coverage everywhere.

## Invariants

- One lane: worktree `~/local-scratch/worktrees/drmTMB-useful-07`, branch
  `cursor/useful-07-user-facing`. Never the dirty primary checkout.
- Never claim “CRAN ready”. Never bump DESCRIPTION to 0.7.0.
- No platform-clean, win-builder, R-hub, or CRAN upload.
- No Totoro / DRAC. No AGHQ / Cox-Reid campaigns.
- Do **not** touch `tests/testthat/test-guard-branch-continuity.R`, PR #941, or
  `docs/dev-log/release/` packaging ledgers.
- Capability-surface edits **cite existing tiers only** — no ledger promotions.
- Docs restatement of measured behaviour only; no new public claims.

## Authoritative WHAT

→ `LOOP/ultra-plan.md` · `scratchpad/2026-08-07-arc-useful-07-user-facing.md`
(PR #940 @ ~`8004fc05`)

## Definition of done

1. Onboarding path exists and is linked from Getting Started + `drmTMB.Rmd`.
2. NEWS + `?confint` state the default uncertainty story without
   nominal-coverage-everywhere.
3. Users can parse family × dpar × RE × interval tier from README/pkgdown
   without opening the ledger TSV.
4. Ayumi-scale `se_group_sd` advice is in `large-data` (and learning-path).
5. After-task written; draft PR opened; AGHQ remains deferred; STOP (no
   packaging claim).
