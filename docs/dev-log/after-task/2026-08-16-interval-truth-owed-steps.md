# After-task — interval-truth docs, student `failed` wiring, and #1055 merge prep

**Lane:** `cursor/interval-truth-owed` · **Platform:** Cursor · **Date:** 2026-08-16
**Base:** `origin/main` @ `723ed80a0` (fresh worktree; never the dirty primary).

## 1. Goal

Land the still-OWED interval-truth docs and the owner-approved student
location wiring. Merge win-builder collect PR #1055 as-is. Do not submit to
CRAN. Do not treat the pasted Ligges mail as R-release. Do not frame the
0.7.0 ladder as a this-week submit; the owner window is end of August or
early September.

## 2. Implemented

- **Blob-pin partition of the 21** (facts only): 4 PINNED (`mc-0559`–`mc-0562`)
  · 17 UNPINNED. `docs/dev-log/2026-08-16-import-21-blob-pin-partition.md` + TSV.
- **Student campaign review, then wiring.** Shinichi approved option 1.
  `mc-0484` / `mc-0485` / `mc-0486` stay `interval_feasible`;
  `location_checked` `unchecked → failed`. Evidence class is
  `estimator_diagnostic` (the artifact's own `diagnostic_calibration_pilot`
  label). Primary shape evidence stays the legacy rows.
- **Ligges recheck.** `in:anywhere drmTMB_0.7.0` still returns exactly one
  thread (`1a0080c713d427f0`, 2026-08-16T00:50:26Z, Trash). That thread is
  R-devel (`https://win-builder.r-project.org/84RS0Yqy5t0Y`), already filed
  as `winbuilder-devel.txt`. No R-release or R-oldrelease mail. `status_claim`
  stays unmoved.
- **#1055** is mergeable with green CI; merge is a separate step after this
  PR is opened. Merging it does not unlock `platform-clean`.
- **Held out of this commit:** `docs/dev-log/check-log.md` and
  `docs/dev-log/coordination-board.md`, because `cursor/070-winbuilder-collect`
  (#1055) already carries those paths. Facts live here and in handover
  addendum 3.

## 3a. Decisions and rejected alternatives

| Decision | Rejected | Why |
| --- | --- | --- |
| Wire `location_checked=failed`, keep `interval_feasible` | leave `unchecked`; pass; promote | owner chose option 1; design 255 separates shape from location |
| `estimator_diagnostic`, not `coverage_study` | treat the 200-fit Wald pilot as certified coverage | the artifact caps itself at diagnostic calibration |
| Keep primary evidence on the legacy shape rows | replace `primary_evidence_id` with the campaign | the campaign is negative location evidence, not a new shape warrant |
| Hold `vignettes/includes/` in the PR | drop the generated include | `--check` requires it; #1054 already set that pattern; no `R/` / `src/` |
| Do not advance `platform-clean` | treat the pasted Ligges mail as R-release | it is R-devel; release/oldrelease remain absent |
| Prep only toward end-Aug / early-Sep | frame as submit-this-week | owner addendum 2026-08-16 |

## 3b. Checks run

| Check | Result |
| --- | --- |
| `lane_preflight.sh` | FOREIGN LANE ACTIVE (main-direct); this slice took `cursor/interval-truth-owed` |
| Gmail `in:anywhere drmTMB_0.7.0` | 1 thread (R-devel only, Trash) |
| Gmail `in:anywhere subject:winbuilder drmTMB after:2026/08/14` | empty |
| `gh pr view 1055` | OPEN, MERGEABLE, CI green |
| `python3 tools/capability_ledger.py --write --check` | OK (31 generated outputs) |
| `test_capability_ledger` + `test_b4_ci_c1` | 82 tests OK; C17 current-source compatibility PASS |
| remaining CI python suites (`test_arc1_profile_reconcilers`, `test_b3_q6_target_promotion`, `test_b4_ci_guard`, `test_profile_truth_gate`) | 42 tests OK |
| shipped `R/` / `src/` / `DESCRIPTION` | untouched |

Ledger after wiring, among the 187 interval-claiming cells (supported /
inference_ready_with_caveats / interval_feasible): **164 passed · 20
unchecked · 3 failed · 0 not applicable**.

## 4. Consistency audit

Design 255 (shape vs location) is the contract. The three student cells remain
`interval_feasible`. B4-CI C1 pins do not include `mc-0484` / `0485` / `0486`.
Generated reader surfaces now print **3 failed**. Quiesce still stands for
shipped package code; this PR is ledger + docs + the generated include
`vignettes/includes/capability-ledger-summary.md` (same class as #1054).

## 5. What did not go smoothly

`get_thread` on the devel mail was permission-denied; identity was confirmed
from the already-filed `winbuilder-devel.txt` URL
`https://win-builder.r-project.org/84RS0Yqy5t0Y` plus the earlier Trash
search. Queries without `in:anywhere` miss that thread.

## 6. Known limitations and next actions

- Ligges R-release / R-oldrelease still absent. Do not re-upload again today.
- Do not submit to CRAN. Owner window: end of August or early September.
- Do not bump `Version` to `0.7.0.9000` without a separate ask.
- Cheap assertion work on the 17 unpinned demoted cells remains unstarted.
- A later student profile location campaign is a new pre-registered slice,
  not a re-score of these Wald rows.
