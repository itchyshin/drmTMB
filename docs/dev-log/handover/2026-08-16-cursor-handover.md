# Handover → Cursor: the interval-truth programme after a three-PR day

**You are Cursor, picking up the drmTMB interval-truth lane.** This chat's context is gone; this
document plus the repo is everything. Author: Claude (lane `claude/lane-overnight-0815` and two
predecessors, 2026-08-15/16, all merged).

## Critical context

Three PRs merged in ~24 h, `main` verified green after each (R-CMD-check `success`, pkgdown deployed):

| PR | what it did |
| --- | --- |
| #1040 | The interval-claim truth audit: 7 spatial demotions (fixture truth ≠ estimand), 28 spatial claims narrowed to the fixed-range condition, 2 evidence-ladder inversions fixed (`supported` token split; `TIER_ORDER` made monotone in reader permission), 134 off-mainline runners/contracts recovered |
| #1047 | 16 `inference_ready_with_caveats` cells re-wired to their real campaigns (zero demotions — the 2026-07-11 migration had dropped the links); **the tier contract decided**: `interval_feasible` claims SHAPE; location lives in a new derived `location_checked` column (docs/design/255) |
| #1050 | Overnight: 31 cells recovered truth + location-checked (31/31 pass, 100% bracketing, zero compute); the 44-cell import audited (facts only); `location_checked` rendered on all reader surfaces; staleness supersession extended to 9 files; **one finding retracted** (the PSOCK "leak" — see Gotchas) |

**Ledger truth on `main`:** 226 interval-claiming cells → **176 `location_checked=passed` · 44
`unchecked` · 6 `not_applicable`**. The 44 are exactly the 2026-07-11 legacy import.

## Current working state

- **Working:** everything merged; no uncommitted state in any of my lanes; all 11 CI gates green on
  `main` (6 python suites, ledger `--check`, 4 R gates).
- **Blocked/reserved (owner decisions, NOT yours to take):**
  1. **The 44-cell disposition** — audit says 19 shape-justified / 22 whose cited evidence never
     computes an interval / 3 with an unwired campaign. Read
     `docs/dev-log/2026-08-15-import-44-shape-audit.md` before touching anything.
  2. **`mc-0596`** (D-87) — reduced to a fixture difference, facts in
     `docs/dev-log/2026-08-15-…` scratch summary inside #1050's after-task.
- **In another lane (PROTECTED):** `claude/eloquent-driscoll-521fa1` holds a worker-hygiene guard
  test held out of `main` under the 2026-08-15 quiesce. Unpushed foreign branches
  `codex/staged-eta-godambe-se` (3), `hopper/bridge-finish-phase15-5` (2), `shannon-install` (1) —
  CARRIED-OVER by their owners, not this lane; do not land or touch them.

## Key decisions and rationale (short — full reasoning is linked)

- `interval_feasible` = **shape only**; location is orthogonal (`docs/design/255-interval-feasible-tier-contract.md`).
- Demotion wording is fixed: *"this claim is not currently supported"* — never "proven mislocated".
- Truth is **derived** (fixture code / frozen contracts), never lifted from prose.
- Corrections are **appended and dated**, never rewritten (`mc-0248`, class-(c), the retraction).
- `mc-0282` truth = **0.6** not 0.55 — the 0.55 DGP was never executed.

## Files created/modified (the load-bearing set; full lists in the after-tasks)

`tools/capability_ledger.py` (LOCATION_CHECKED, rendering, TIER_ORDER) ·
`tools/integrate_b4_ci_c1.py` (3 gated re-freezes) · `tools/tests/test_capability_ledger.py` (+5
tests) · `docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv` + `schema.json` ·
7 test files (endpoint assertions) · `docs/design/255…` · ~15 dev-log docs. After-tasks:
`2026-08-15-interval-claim-truth-audit.md`, `2026-08-15-irc-evidence-rewire-and-tier-contract.md`,
`2026-08-16-overnight-location-and-import-audit.md` (each with plan-actual beside it).

## Next immediate steps (narrow, in order)

1. **Lane preflight first**: `bash ~/shinichi-brain/tools/lane_preflight.sh .` — 10+ lanes live;
   name yours.
2. Reconcile this handover against `git log origin/main` and classify each item OWED / DONE /
   RETRACTED / PROTECTED.
3. **OWED, mechanical, safe:** compute the blob-pinning partition of the 22 no-interval import cells
   — for each, is its cited test file a pinned source blob in `tools/integrate_b4_ci_c1.py` or the
   C14/C16 manifests? (That partition decides whether the cheap assertion fix is possible per cell;
   the zero_one_beta attempt is documented as blocked by `mc-0568`'s receipt binding.)
4. **OWED, review-grade:** the student campaign
   (`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`, coverage
   0.81–0.86 vs nominal 0.95) — draft the review that decides whether wiring it sets
   `location_checked=failed` for `mc-0484/0485/0486`. **Do not wire it as a promotion.**
5. Wait for Shinichi on the 44-cell disposition before any tier change.

## Blockers / open questions

The two owner decisions above · 26 of 31 new verdicts are **magnitude-only** (single seed — say so in
any claim) · `mc-0300`/`mc-0312` truths rest on a frozen contract value alone.

## Gotchas / failed approaches (read before repeating them)

- **The PSOCK "leak" was a false positive — RETRACTED.** `R/` contains no cluster creation at all.
  `PPID 1` is normal for healthy PSOCK workers (R ≥ 4.0 `setup_strategy="parallel"`); attribute
  processes by PORT, never by a global `ps` count on this ten-lane host.
- **Editing a test file can break a different cell's provenance.** `test-zero-one-beta.R` is the
  pinned source blob for `mc-0568`'s receipt; an additive assertion edit was written, proven, and
  reverted. Check blob-pinning before touching any test a receipt cites.
- **Line-shifts in cited ranges must be verified by content, not arithmetic** — two citation errors
  came from one mechanical shift.
- The B4-CI C1 guard (`test_b4_ci_c1`) fires on ANY byte change to pinned ledger rows; re-freeze only
  after a field-level diff proves what moved (three worked examples in the comments beside the pins).

## Environment / how to verify (Cursor has none of my session state)

- Repo: `/Users/z3437171/Dropbox/Github Local/drmTMB` (shared checkout — many lanes; prefer a
  worktree via `~/shinichi-brain/tools/lane_launch.sh`). Installed drmTMB is stale; R entry:
  `NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgload::load_all(".", compile = FALSE)'`.
- Cheap full verification (no R build):
  `python3 tools/capability_ledger.py --check` and the 6 suites in `tools/tests/` (CI list in
  `.github/workflows/R-CMD-check.yaml:110-118`) — **run the full list, never a subset**.
- Never stage: other lanes' untracked files in the shared checkout; anything under `scratchpad/`
  unless deliberately.

## ADDENDUM (2026-08-16, after this doc was merged) — the 44-cell decision is MADE

Shinichi decided the reserved item: **demote the import cells whose cited evidence never computes an
interval.** Executed on branch `claude/demote-22-import` → **PR #1054** (open at the time of writing;
merge on green).

- **21 cells demoted** `interval_feasible` → `point_fit_recovery`, `location_checked` →
  `not_applicable`, with 21 `transitions.tsv` rows and a `next_gate` on each saying how to re-earn
  the tier: `mc-0029 mc-0031 mc-0177 mc-0178 mc-0179 mc-0180 mc-0181 mc-0210 mc-0211 mc-0236 mc-0238
  mc-0240 mc-0244 mc-0378 mc-0487 mc-0488 mc-0510 mc-0559 mc-0560 mc-0561 mc-0562`.
- **The count is 21, not the 22 this doc's audit table claimed.** The table mis-tallied; the four
  batch reports and the doc's own prose list both give 20 B / 21 C. Corrected in the audit doc.
- Two frozen count guards were updated deliberately (`FROZEN_CENSUS_POINT_FIT_RECOVERY` 55→76; the
  model-surface test pin 56→77), each with the reason recorded beside it.

**Ledger after #1054 merges:** 205 claiming = **176 passed · 23 unchecked · 6 not_applicable**. The
23 are the **20 shape-justified** (correctly tiered, honestly unchecked for location) plus the **3
student cells** awaiting their campaign review.

**What this changes for you:** the "44 unchecked" figure above is superseded. **Next Immediate Step 5
("wait for Shinichi on the 44-cell disposition") is now DONE** — do not re-open it. Steps 3 and 4
stand unchanged, and step 3 (the blob-pinning partition) is now *only* relevant to re-earning the
tier for the demoted 21, not to deciding their disposition.

**If PR #1054 is still open when you start:** verify its CI is green, then merge it, or ask Shinichi.
Do not re-derive the demotion set — it is evidence-derived and recorded in `transitions.tsv`.

## ADDENDUM 2 (2026-08-16, Cursor `cursor/interval-truth-owed`) — steps 3 and 4 drafted

PR #1054 is **merged**. Step 3 and step 4 were drafted on this branch before
the owner wiring decision. Do not re-do the review from scratch.

- Blob-pin partition of the 21:
  `docs/dev-log/2026-08-16-import-21-blob-pin-partition.md`
  (4 PINNED = `mc-0559`–`mc-0562`; 17 UNPINNED).
- Student campaign review:
  `docs/dev-log/2026-08-16-student-campaign-location-review.md`

## ADDENDUM 3 (2026-08-16, same lane) — student wiring done; CRAN stays prep-only

Shinichi approved wiring option 1. `mc-0484` / `mc-0485` / `mc-0486` are now
`location_checked=failed` and still `interval_feasible`. Receipts:
`ev-mc-048*-student-wald-location` and `tr-mc-048*-student-wald-location`.
Among the 187 interval-claiming cells the generated surfaces now read
**164 passed · 20 unchecked · 3 failed**.

The pasted Ligges mail for `https://win-builder.r-project.org/84RS0Yqy5t0Y` is
**R-devel**, already filed. Gmail still has no R-release or R-oldrelease
thread. Merging #1055 does **not** advance `platform-clean`.

**CRAN submit remains withheld.** Owner window is **end of August or early
September**, not a this-week submit. Do not bump `Version` to `0.7.0.9000`
without a separate ask. Do not touch missing-data #1033, MSPL, or NG
correlated implementation from this lane.

## How to resume

Paste-ready prompt at the end of this file. Read `AGENTS.md` first; it is the repo's source of truth.

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-16-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
