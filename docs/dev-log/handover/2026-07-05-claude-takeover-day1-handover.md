# Session Handoff: Q-Series v1 Takeover — Day 1 Checkpoint

Meta: 2026-07-05 · from Claude to Claude (or Codex for live toolchain) · context medium

You are the next session picking up `drmTMB` after a Claude takeover session on the
Q-Series v1 practical-surface arc. Read `AGENTS.md` first, then this file, then the
prior Codex→Claude handover `docs/dev-log/handover/2026-07-05-claude-handover.md`
(still valid for deep background). This session executed **Day 1 (PR + CI + claim
audit)** and **Day 2 (last-ten triage)** of the 3-4 day arc.

## Goals / Mission (durable)

Finish `drmTMB` as the primary R/TMB package first with honest claim boundaries and
a clean PR/CI path. `DRM.jl`/Julia stays **optional and later** — never required for
v1, CI, install, docs, or tutorials. The near-term win is a credible, usable drmTMB
R/TMB v1 state, NOT the old all-inference campaign.

## Critical Context

Mission Control truth (reconfirmed this session, `python3 tools/qseries_v1_release_check.py --summary`):

```text
support cells: 104
practical_v1_surface: 94/104 (90.4%)   <- implementation/recovery surface, NOT inference authority
gaussian_core: 59/67 (88.1%)
basic_distribution_recovery: 35/37 (94.6%)
exact_inference_ready: 8/104 (7.7%)     <- did NOT expand
structured_supported_authority: 0/104   <- nothing is public-claim `supported`
post_v1: 10/104 (9.6%)
rows_to_100: 10
```

Do NOT inflate 94/104 into `supported`, broad inference-readiness, q4/q8 promotion,
REML/AI-REML expansion, coverage authorization, or Q-Series completion.

## What Was Accomplished (this session)

- Confirmed branch `drmtmb/fix-family-conventions` is pushed at/newer than the handover
  SHA and reproduces Mission Control truth exactly.
- **CI trim** (commit `0ce8b919`): `.github/workflows/R-CMD-check.yaml` now runs
  `ubuntu-latest` only on routine `pull_request`/push-to-main; the full ubuntu+macOS+
  windows matrix runs only on release tags (`v*`) and `workflow_dispatch`. Verified
  live: the PR run emitted the ubuntu-only matrix (no macOS/Windows leg).
- **Draft PR #730** opened (`drmtmb/fix-family-conventions` → `main`) with a corrected
  94/104 body sourced from the generated ledger
  `docs/dev-log/release-audits/q-series-v1-release-status.md`.
- **Rose/Fisher/Ada/Grace release-candidate audit** — clean. No boundary violations;
  `inference_ready` independently recounted = 8; no stale `91/104` in active surfaces
  (only in dated dev-log records, historically correct/superseded).
- **Last-ten triage** — `0 finish-now, 10 post-v1`. All 10 have design/engine blockers
  (not compute); q8 rows (7-10) are policy-barred by the no-q4/q8 rule. Full row-by-row
  table with blocker class + cost in
  `docs/dev-log/after-task/2026-07-05-q-series-v1-last-ten-triage.md`.

## Current Working State

- **Working:** branch HEAD `0ce8b919` (CI trim) pushed to origin; draft PR #730 open.
- **Working:** all Mission Control fast gates green; audit clean.
- **In progress:** ubuntu-only R-CMD-check on #730 — confirm green before ready-for-review.
- **Pending commit (this session's docs, docs-only):** the last-ten triage after-task,
  the check-log entry, and this handover — committed onto the same branch as a docs commit.
- **Not done (pre-ready-for-review debt, Codex live-toolchain lane):** a full local
  `rcmdcheck::rcmdcheck(args = "--as-cran")` + `pkgdown::build_site()` on the Mac, and one
  3-OS `workflow_dispatch` R-CMD-check for the compiled-code change (~590 lines of
  `src/drmTMB.cpp` + `src/drm_numeric.h`).

## Key Decisions & Rationale

- **All 10 remaining rows are post-v1.** Economy rule: finish-now requires cheap +
  deterministic + no new coverage/authority. None qualifies; blockers are design/engine,
  not compute (the 2026-07-05 economy plan already proved the count-mu row's blocker is a
  one-structured-field-slot engine-design gap). q8 rows are additionally policy-barred.
- **CI trimmed to ubuntu-only for routine PRs** per the standing cost rule; 3-OS reserved
  for tags/dispatch so the compiled-code cross-OS check is available on demand.
- **Declined to bump `status.json`'s `updated` timestamp** (Grace flagged it stale). The
  07-05 status.json diff was wording-only and this session did not re-verify its board
  metrics; refreshing the timestamp would falsely imply a content refresh.
- **Land as one PR** (Ada): the 79-file diff is single-theme (q2 scale-only recovery +
  tooling); the split decision can be a review outcome, not a blocker.

## Next Immediate Steps

1. Confirm the ubuntu R-CMD-check on #730 is green (`gh run list --branch
   drmtmb/fix-family-conventions --workflow R-CMD-check.yaml`).
2. **Codex lane:** run local `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
   'rcmdcheck::rcmdcheck(args = "--as-cran")'` + `pkgdown::build_site()`; fix any
   compiled-code portability or Rd/NAMESPACE drift.
3. Trigger one 3-OS R-CMD-check on the branch via `gh workflow run R-CMD-check.yaml
   --ref drmtmb/fix-family-conventions` to exercise macOS/Windows TMB compilation.
4. Make the **merge-or-split product decision** on #730 (Shinichi's call). If merging,
   mark ready-for-review after gates 2-3 are green.
5. If not merging the last 10 before v1 (recommended), the arc's remaining work is
   **package-level v1 polish** (NEWS/README/pkgdown coherence, examples, `--as-cran`
   cleanliness), then close the Q-Series practical surface at 94/104.
6. Only after drmTMB v1 is current should serious time shift to `DRM.jl` parity. Julia
   stays optional.

## Blockers / Open Questions

- **Product decision:** land #730 as one PR or split, and whether to pursue any of the 10
  post-v1 rows before v1 (recommended answer: no — they are design/engine/policy-barred).
- **Pre-merge:** full local `--as-cran` + pkgdown not yet run (Codex lane).

## Gotchas & Failed Approaches

- Do NOT promote any q8 row (7-10) — barred by the no-q4/q8 rule; even an honest rejection
  boundary that *counts* q8 toward the practical surface is q8 movement.
- Do NOT bump `status.json`'s timestamp without a real content refresh (honesty).
- Do NOT use any pre-2026-07-05 compare/handover text in the PR body — it says 91/104.
- Residual `91/104`/`87.5%` strings are correct-for-their-date dev-log records; do not
  rewrite history, and do not treat them as live claims.
- Run R with `R_PROFILE_USER=/dev/null Rscript --no-init-file` (older profile/library
  combos have segfaulted; the Mac R 4.6 env is otherwise fixed).
- Do NOT make Julia required anywhere.

## Mission Control Summary

| Area | State | Meaning |
| --- | --- | --- |
| Repository | `drmTMB` | Finish-first R/TMB target; Julia optional/later. |
| Branch | `drmtmb/fix-family-conventions` @ `0ce8b919` | Pushed; draft PR #730 into `main`. |
| CI | ubuntu-only R-CMD-check (trimmed) | 3-OS on tags/dispatch only; confirm PR run green. |
| Practical v1 surface | 94/104 (90.4%) | Implementation/recovery; not inference authority. |
| Exact inference-ready | 8/104 | Unchanged; Gaussian anchors only. |
| Supported authority | 0/104 | No structured row is public-claim `supported`. |
| Post-v1 rows | 10/104 | All design/engine-blocked; q8 policy-barred. 0 finish-now. |
| Next gate | local `--as-cran` + pkgdown + 1× 3-OS CI | Codex lane; before ready-for-review. |
| Julia/DRM.jl | optional later | Not required for v1, CI, install, docs, tutorials. |

## How to Resume

Rehydrate, then continue the Next Immediate Steps. From the repo root in an authenticated
terminal:

- Interactive (steer it):
  ```sh
  claude "Rehydrate from docs/dev-log/handover/2026-07-05-claude-takeover-day1-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
  ```
- Autonomous, clean context:
  ```sh
  claude -p "Rehydrate from docs/dev-log/handover/2026-07-05-claude-takeover-day1-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps." --max-budget-usd 10
  ```
- For the live R/TMB gates (local `--as-cran`, pkgdown, 3-OS CI), hand to **Codex** in the
  repo (it reads `AGENTS.md` natively): paste the same rehydrate prompt. Codex runs the
  compiler/toolchain; Claude plans, audits claims, writes prose, and runs logic/CI checks.

Spawn Rose (and Fisher for any inference wording) before any public status claim.
