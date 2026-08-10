# ARC CARD — 0.7.0 CRAN release readiness (source-clean → tarball probe)

Created 2026-08-05 by Cursor via `arc-creation`, after the post-135 landing
stop and the owner question “what next toward CRAN?”

**Mode:** size  
**Requested outcome:** advance drmTMB toward first CRAN submission as **0.7.0**
(not “on CRAN” yet — that is a later, upload-gated rung)  
**Mechanism authority:** merge of already-green PR #930 (owner); one-word
**D-93/D-117 discharge**; claim-surface edits (README / NEWS / pkgdown /
experimental banner); init + run `cran-release-gate` through **source-clean**
and a local **tarball-clean** probe.  
**Excluded:** AGHQ / Cox-Reid campaigns; missing-data G4+ / MNAR / predictor MI;
WITHHOLD re-prereg or Totoro; more `interval_feasible` promotions; actual CRAN
**upload** (needs a separate explicit “submit” word); force-cleaning the dirty
primary checkout; touching #858 / #893 / #869.  
**Recommended arc:** **5.0 h** programme (Arc 0 = 45 min)  
**Time contract:** ceiling 5 h; each rung independently stoppable  
**Estimate confidence:** **inferred** — prior CRAN audits (2026-07-11 / 07-20 /
07-21) exist as analogues; this exact 0.7 path has not been timed end-to-end.
Ubuntu R-CMD-check on #930 measured **46m** (under 75m ceiling).  
**Arc 0 outcome:** D-93/D-117 discharge is either **YES** (profile + boundary
warning = honest 0.7 position) or **NO** with a named remaining measurement;
PR #930 merge status settled.  
**State transition:** `cran-gate: unstarted / D-93 hold open` →
`source-clean` for a named 0.7.0 RC commit (and a local tarball probe started).
**Not** `submitted` / `live-with-check-page`.  
**Executable rung and evidence:** owner discharge text in
`~/shinichi-brain/memory/DECISIONS.md`; merged #930 on `main`; claim-diff
receipt; `python3 tools/cran_release_gate.py` (or protocol ledger) reporting
highest proven rung = **source-clean** (or honest **NOT READY** with the next
failing row). Upload blocked until Shinichi says submit.

## Why this arc and not AGHQ / missing data

D-93 held 0.7 until RE-SD intervals were *fixed*. D-97 accepted the profile
route; D-117 ran the 10-group gate; boundary undercoverage matches lme4; the
user-facing warning shipped. What remains is the **publish call**, then
**release engineering** (D-49 / cran-release-gate), not another capability
campaign. AGHQ and missing-data deepening are post-0.7 science arcs.

## State-transition gate

| Step | Content |
| --- | --- |
| 1. Current | `DESCRIPTION` 0.6.0; not on CRAN; D-117 measured / PASS withheld / not discharged; #930 open CI-green ready-for-review; claim surfaces mostly corrected (D-125) |
| 2. Intended | Highest proven cran-release-gate rung = **source-clean**; local tarball identity recorded; path to **tarball-clean** known |
| 3. Intervention | Discharge + merge #930 + claim freeze + gate ledger + local `--as-cran` / gate script |
| 4. Approval | Discharge and merge and any later upload are **owner-gated**. If discharge is NO, this programme is **preparation only** and unused capacity is returned. |

## Capacity ladder

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 45 min | Discharge packet + #930 merge decision | Start now. One-word YES/NO on D-93/D-117. |
| Rung 1 | 75 min | #930 on `main`; worktree/main census 187 IF / frozen 54 | If Arc 0 = YES (or “proceed under profile+warning”). |
| Rung 2 | 90 min | Claim freeze: README / NEWS 0.7 draft / D-41 experimental banner / capability-surface honesty vs ledger | If Rung 1 lands. |
| Rung 3 | 75 min | Init cran-release-gate ledger; local tarball + gate script; report highest proven rung | If Rung 2 claim freeze is clean. |
| Integrate/close | 15 min | After-task + Actuals; HAND TO next arc or STOP for submit word | Always reserve. |
| **Total** | **300 min** | | |

## Budget — Arc 0

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Re-read D-86 / D-93 / D-117 / D-122 / cran-release-gate Gate −1; confirm #930 still CLEAN |
| Core | 15 | Write one-paragraph discharge proposal; ask Shinichi YES/NO |
| Verify | 10 | Confirm no conflicting public “ready / on CRAN” claim on `main` tip |
| Repair reserve | 0 | External wait is not arc time |
| Closeout | 5 | Record answer; if NO, return remaining 4.25 h |
| **Total** | **45** | |

**In scope:** discharge decision; merge #930; claim freeze; source-clean gate;
local tarball probe.  
**Not in this arc:** CRAN upload; R-hub/win-builder full matrix as a *merge*
blocker for this slice (they belong to **platform-clean**, Rung after this
programme); AGHQ; missing-data expansion; WITHHOLD re-prereg; primary-checkout
cleanup.  
**Evidence used:** PR #930 CI green (ubuntu 46m4s); D-117 artifacts on `main`;
README already targets 0.7.0; brain D-86/D-93/D-117/D-49; protocol
`~/shinichi-brain/protocols/cran-release-gate.md`.  
**Risk branch:** If discharge is **NO**, stop after Arc 0 — do not invent
claim-freeze theatre. If #930 conflicts after another lane merges, rebase in
the 135trace worktree only; never stage primary debris. If local `--as-cran`
fails on a real NOTE/ERROR, leave gate at **NOT READY** and open a repair
sub-arc — do not bump to 0.7.0 early (D-86).

**Done when:** (size-mode programme) D-93/D-117 is discharged in writing; #930
is on `main`; public claims match the ledger for the 0.7.0 RC; cran-release-gate
reports **source-clean** (or an honest failing row); a tarball SHA is recorded
even if tarball-clean is still open.  
**First action:**

```text
Shinichi — D-93/D-117 discharge for 0.7.0:
Accept profile RE-SD intervals + profile.boundary warning as the honest
0.7.0 position (PASS claim stays withheld; not a drmTMB defect vs lme4)?
Reply YES to proceed with claim-freeze + cran-release-gate, or NO + what
extra evidence you still want.
Also: merge https://github.com/itchyshin/drmTMB/pull/930 when ready.
```

### Actuals (complete at close)
**Recommended / actual:** 300 / _ · **Requested / used:** N/A / _ · **Rungs completed:** _  
**Under-run event:** _  
**Calibration:** _  
**Metric movement:** cran-gate unstarted → _ · census after #930: _  
**Result:** _ · **Next arc:** platform-clean (R-hub/win-builder) **or** submit-word wait

---

HAND TO ULTRA PLAN: 5h drmTMB 0.7.0 CRAN readiness — Arc 0 = D-93/D-117
discharge + #930 merge; then claim freeze + source-clean gate + local tarball
probe; no AGHQ, no missing-data expansion, no CRAN upload without explicit
submit word; work only from a clean worktree off `main` after #930.
