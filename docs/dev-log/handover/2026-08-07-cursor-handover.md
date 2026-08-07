# Cursor Handover — drmTMB 0.7: useful-0.7 CI + platform-clean (NOT READY)

> **POST-MERGE (2026-08-07 evening).** `#942` / `#943` / `#941` are on `main`
> (`13e8cafb0`). Highest proven rung remains **`tarball-clean`**. DESCRIPTION **0.6.0**.
> **Do not upload.** **Do not claim platform-clean** until win-builder R-release +
> R-devel are ERROR-free on the repaired tarball. Next owner work = adjudicate
> win-builder results / re-submit if needed, then re-evaluate the rung.

**You are Cursor**, picking up drmTMB after the 0.7 packaging ladder reached
**`tarball-clean`** and two live Cursor lanes (`useful-0.7`, `platform-clean`)
were left mid-flight. You inherit **no chat context**. This document plus
`AGENTS.md` plus current git state are authoritative.

**Meta:** 2026-08-07 · from **Cursor** (handover session) → to **Cursor** ·
`origin/main` @ `8004fc058` · DESCRIPTION still **0.6.0** · highest proven CRAN
rung **`tarball-clean`** (PR #939) · **no upload** · **not platform-clean** ·
**not CRAN-ready**.

Multi-lane board (read every live row):
[`docs/dev-log/active-lane-split.md`](../active-lane-split.md).

---

## 0. READ THIS FIRST — working-directory trap

**The primary checkout is PROTECTED and will mislead you.**
`/Users/z3437171/Dropbox/Github Local/drmTMB` sits on
`claude/handover-freshness-0718`, far behind `origin/main`, with a large dirty
tree (AGHQ-era debris, scratchpads, ~96 uncommitted paths, 2 unpushed commits on
HEAD, hundreds of foreign unpushed branches).

- **Do not commit, clean, revert, stash, or stage those files.**
- **Never `git add -A` anywhere in this repo.**
- Work in a **fresh clean worktree** off `origin/main`, or in the existing lane
  worktrees named below.

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
# example: recreate a clean tree for the next owed slice
git worktree add ~/local-scratch/worktrees/drmTMB-<slice> -b cursor/<slice> origin/main
```

---

## 1. Critical Context

1. **Packaging ladder is proven through `tarball-clean` only.** Merged:
   #930 (135-trace), #931 (arc card / board), #938 (`source-clean`), #939
   (`tarball-clean`), #940 (useful-0.7 arc card). Freeze artifact SHA-256
   `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
   (`docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES.md`). Local
   `--as-cran` was Status: **1 NOTE** (New submission). **Do not claim
   platform-clean or CRAN ready. Do not upload. Do not bump DESCRIPTION to
   0.7.0.**

2. **`useful-0.7` is CARRIED-OVER with CI in flight.** Draft PR **#942**
   (`cursor/useful-07-user-facing` @ `e6f781388`) lands first-week user-facing
   surfaces + vignette column fix (`parm`/`lower`/`upper`). Watch GHA run
   [31214014701](https://github.com/itchyshin/drmTMB/actions/runs/31214014701)
   (`ubuntu-latest (release)` was still **IN_PROGRESS** at handover write).
   Human skim for claim honesty remains open on the PR checklist.

3. **`platform-clean` is NOT READY.** Draft PR **#941**
   (`cursor/07-platform-clean` @ `fb30d60ff`) records the win-builder ERROR in
   `test-guard-branch-continuity.R` (CondExp `drm_src_path`), lands the path
   repair (`25e38cc74`), and records the win-builder resubmit receipt
   (`fb30d60ff`). GHA 3-OS + R-hub ASAN/UBSAN/gcc-ASAN were green on the freeze
   tip; win-builder R-release + R-devel were **1 ERROR**. Resubmit ~2026-08-07
   19:54 UTC — **results not yet adjudicated into a `platform-clean` claim**.
   Some raw logs may still be untracked in the platform worktree (declare
   below). GHA on #941 tip: watch
   [31215197798](https://github.com/itchyshin/drmTMB/actions/runs/31215197798)
   (prior run `31212472502` was cancelled by the resubmit-docs push — pacing,
   not a code failure).

4. **Handoff gate FAILS on every tree** — mostly because the shared object store
   still has many **foreign unpushed branches** and the primary is dirty. That
   is expected. Treat failures as **declare CARRIED-OVER**, not as a license to
   clean the primary.

---

## 2. Goals / mission (if applicable)

Finish an honest **first CRAN submission path for drmTMB 0.7** while keeping
user-facing uncertainty prose accurate: packaging rungs proven, platform matrix
honest, DESCRIPTION stays 0.6.0 until owner authorizes the bump + upload.
Sibling science lanes (#858, etc.) must not be orphaned by a single CRAN pointer.

## 3. Plans / roadmap (beyond immediate steps)

After `platform-clean` actually greens (win-builder without ERROR + remaining
sanitizer adjudication): owner decides DESCRIPTION `0.7.0` bump, `cran-comments`,
and upload. Separately: useful-0.7 merge when CI + human skim clear; D-117
*discharge* remains an owner publish call (PASS stays withheld). Do not reopen
the closed 135-trace prereg.

---

## 4. What Was Accomplished (this programme, already on `main` or pushed)

| Item | State |
|---|---|
| 135-trace promotions + post-campaign handover | LANDED (#930 → `8df6f240`) |
| CRAN arc card + coordination board + phase snapshot | LANDED (#931) |
| `source-clean` probe-2 (LOOP excluded; 1 NOTE) | LANDED (#938 → freeze tip `459bd3fa9`) |
| `tarball-clean` ledger + freeze notes | LANDED (#939 → `744b9fbee`) |
| useful-0.7 arc card on `main` | LANDED (#940 → `8004fc058`) |
| useful-0.7 user-facing surfaces + vignette CI fix | Pushed on #942 @ `e6f781388` — **not merged** |
| platform-clean attempt doc + CondExp src-path fix + resubmit receipt | Pushed on #941 @ `fb30d60ff` — **not merged**; rung **not** advanced |

---

## 5. Current Working State

- **Working:** `origin/main` at `tarball-clean`; packaging docs/ledger on main;
  useful and platform branches pushed with draft PRs.
- **In progress:** #942 CI re-run; #941 CI; win-builder re-check emails/results
  after resubmit; optional commit of untracked platform raw logs.
- **Not working / blocked:** platform-clean claim; CRAN upload; primary-checkout
  debris (PROTECTED); foreign unpushed branch estate (do not mass-push).

---

## 6. Key Decisions & Rationale

- Highest proven rung remains **`tarball-clean`** until win-builder re-greens
  without ERROR on a tarball that includes `25e38cc74` (or successor).
- useful-0.7 is **orthogonal** to packaging: no `docs/dev-log/release/` edits,
  no continuity-test edits, no version bump (arc card #940).
- Primary `claude/handover-freshness-0718` stays **PROTECTED** (D-87/D-88 lane
  hygiene; prior AGHQ debris).
- Mesh/SPDE #893 and missing-data brief #869 are **MERGED** (do not treat as
  open blockers). Lane B E0 **#858** remains open draft — foreign.

---

## 7. Landing State

`bash ~/shinichi-brain/tools/handoff_gate.sh` on primary / useful / platform /
cran-exec returns **FAIL**. Annotated ledger:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `8004fc058` (packaging through #940) | y | y | #930–#940 merged | **LANDED** |
| `cursor/useful-07-user-facing` @ `e6f781388` | y | y | **#942 draft** | **CARRIED-OVER** — CI watch / human skim / merge decision |
| `cursor/07-platform-clean` @ `fb30d60ff` (path fix `25e38cc74` + resubmit receipt) | y | y | **#941 draft** | **CARRIED-OVER** — NOT READY; win-builder email adjudication owed |
| Platform worktree leftover untracked raw logs (`*.raw.log`, valgrind poll, etc.) | n | n | — | **CARRIED-OVER** — receipt/logs for resubmit already on branch tip; remaining raw logs optional |
| `cursor/07-cran-readiness` (cran-exec worktree) tip vs main | y (superseded by #938/#939) | y | historical | **DONE** for source-clean; do not reopen as current tip |
| Primary `claude/handover-freshness-0718` dirty + 2 unpushed | mixed | n | — | **PROTECTED** — never stage |
| Foreign unpushed branches (`codex/lane-b-q1-…`, `codex/aoi2-…`, etc.) | y | n | various | **CARRIED-OVER / foreign** — do not push or clean from this lane |
| This handover branch `cursor/handover-0807` | this PR | land with PR | draft | **OWED → LAND** (docs only) |

### CARRIED-OVER resume commands

**useful-0.7**

```bash
cd ~/local-scratch/worktrees/drmTMB-useful-07
git fetch origin && git status -sb
gh pr checks 942 --repo itchyshin/drmTMB
gh run watch 31214014701 --repo itchyshin/drmTMB   # if still running
# After green + human skim: ready-for-review / merge (human); do not auto-merge
```

**platform-clean**

```bash
cd ~/local-scratch/worktrees/drmTMB-07-platform
git fetch origin && git checkout cursor/07-platform-clean && git pull --ff-only
gh pr checks 941 --repo itchyshin/drmTMB
gh run watch 31215197798 --repo itchyshin/drmTMB   # if still running
# Poll win-builder emails / https://win-builder.r-project.org/ for the
# resubmitted tarball recorded in winbuilder-resubmit-RECEIPT.md (tip fb30d60ff).
# Only after R-release + R-devel have 0 ERROR: consider advancing ledger claim.
# Until then: status_claim stays tarball-clean.
```

---

## 8. Next Immediate Steps (classify on resume)

| # | Item | Class at write |
|---|---|---|
| 1 | Rehydrate: `AGENTS.md` → this doc → `active-lane-split.md` → `git status` on the worktree you will use | **OWED** |
| 2 | Watch / finish **#942** CI (`31214014701`); if red, fix only useful-0.7 surfaces | **OWED** (CI may complete to DONE before you start — re-check) |
| 3 | Human claim-honesty skim of useful-0.7 vignette + capability skim; then merge decision (human) | **OWED** |
| 4 | Watch **#941** CI (`31215197798`); adjudicate win-builder resubmit results; **do not** set `platform-clean` until both release+devel are ERROR-free | **OWED** |
| 5 | Optionally commit platform raw/resubmit logs onto #941 with explicit paths | **OWED** (optional) |
| 6 | Claim packaging rungs `source-clean` / `tarball-clean` as already proven | **DONE** |
| 7 | Claim `platform-clean` or CRAN readiness / upload | **RETRACTED** until evidence |
| 8 | Touch primary checkout debris / mass-push foreign branches | **PROTECTED** |
| 9 | Re-run Totoro under closed 135-trace prereg / reopen WITHHOLD without new prereg | **PROTECTED** |
| 10 | Edit #858 Lane B E0 as part of CRAN lane | **PROTECTED** (foreign) |

---

## 9. Blockers / Open Questions

- Win-builder results for the CondExp path repair — inbox / builder URLs.
- Valgrind / residual R-hub noise adjudication if still incomplete
  (`PLATFORM-NOT-READY.md`).
- Owner: when (if) to bump DESCRIPTION to 0.7.0 and upload after a real
  `platform-clean`.
- D-117 discharge (publish call) — orthogonal; PASS remains withheld.

---

## 10. Gotchas & Failed Approaches

- `#942` first CI failed because the vignette selected `estimate` /
  `conf.low` / `conf.high`; `confint()` returns `parm` / `lower` / `upper`.
  Fixed in `e6f781388` — do not reintroduce tidyverse column names.
- Local macOS `--as-cran` can pass the CondExp guard via checkout geometry while
  win-builder tarball layout fails — **do not treat local green as platform-clean**.
- Gate FAIL from “428 UNPUSHED on other branch(es)” is **noise for this lane**;
  declare foreign, do not “fix” by pushing them.
- `gh pr merge` may refuse when workflow blobs must be synthesised without
  `workflow` OAuth scope — use update-branch then merge (known from prior arcs).

---

## 11. Files Created / Modified (this handover PR)

- `docs/dev-log/handover/2026-08-07-cursor-handover.md` (this file)
- `AGENTS.md` — Latest pointer → multi-lane board + this doc
- `docs/dev-log/active-lane-split.md` — useful-0.7 + platform-clean rows; 135-trace marked landed
- `docs/dev-log/coordination-board.md` — current Cursor ownership
- `docs/dev-log/phase-snapshot.md` — replace entry; prior archived
- `docs/dev-log/phase-snapshot-archive.md` — create with prior 2026-08-05 entry

---

## 12. Environment Cursor needs

| Need | Value |
|---|---|
| Preferred cwd | `~/local-scratch/worktrees/drmTMB-useful-07` or `…/drmTMB-07-platform` or a new clean worktree |
| R | `R_PROFILE_USER=/dev/null Rscript --no-init-file` (avoid `.Rprofile` R-4.5 lib segfault on R 4.6) |
| Safe verify (docs) | `pkgdown::check_pkgdown()`; focused tests only if touching `tests/` |
| Safe verify (CRAN rung) | `python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` |
| Env | `NOT_CRAN=true` for ordinary test runs; CRAN-lane checks intentionally without that |
| Must not stage | Primary checkout debris; `*.tar.gz` binaries; foreign branch tips |

---

## 13. Sibling lanes (do not orphan)

| Lane | State | Pointer |
|---|---|---|
| **useful-0.7** | draft #942 @ `e6f781388` | this doc §7–8 |
| **platform-clean** | draft #941; NOT READY | this doc §7–8; `PLATFORM-NOT-READY.md` on branch |
| Packaging / tarball-clean | on `main` via #938/#939 | FREEZE-NOTES + after-task `2026-08-07-07-tarball-clean.md` |
| 135-trace | **LANDED** #930 | historical `2026-08-05-cursor-handover-post-135.md` |
| Lane B E0 | open draft **#858** | foreign — preserve |
| Mesh/SPDE #893 | **MERGED** | closed |
| Missing-data brief #869 | **MERGED** | closed |
| GVA decision land | open **#937** (docs) | optional docs merge; not CRAN-blocking |
| Primary AGHQ debris | PROTECTED | never clean |

---

## 14. Mission-control summary

| Repo | Branch / main | CI | Shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | `main` `8004fc058` | packaging merged | tarball-clean proven | do not upload |
| drmTMB | #942 useful | watch 31214014701 | user-facing surfaces pushed | merge after green+skim |
| drmTMB | #941 platform | watch 31215197798 + win-builder | path fix + resubmit receipt; rung NOT READY | re-green then ledger |

---

## 15. How to Resume

1. Open a **fresh** Cursor agent in a clean drmTMB worktree (not the primary).
2. Paste the prompt below.
3. Classify every Next Immediate Step as OWED / DONE / RETRACTED / PROTECTED
   against **live** `gh pr checks` / win-builder results before acting.
4. Execute **only OWED** items; prefer one lane per session.

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-07-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

---

## Resume classification (2026-08-07 Cursor rehydrate)

Reconciled against live git/`gh` after switching to worktree
`~/local-scratch/worktrees/drmTMB-handover-0807` (primary checkout remains
**PROTECTED**).

| # | Item | Class now | Evidence |
|---|---|---|---|
| 1 | Rehydrate | **DONE** | Read AGENTS + this doc + active-lane-split; worktree on `cursor/handover-0807` @ `bd4bdc17a+`; `origin/main` still `8004fc058` |
| 2 | Watch #942 CI | **OWED** (in flight) | run `31214014701` on `e6f781388` — ubuntu-latest still pending |
| 3 | useful-0.7 claim-honesty skim | **DONE** | PASS posted on #942 comment; no overclaim; fences held |
| 4 | Watch #941 + win-builder adjudicate | **OWED** | tip now `fb30d60ff` (FTP-550 retry receipt); new GHA `31215197798` (prior `31214642847` cancelled by docs push — pacing). R-release FTP **still 550**; Gmail search returned no win-builder result threads yet. **No `platform-clean` claim.** |
| 5 | Optional platform raw logs | **DONE** (narrow) | Committed retry receipt + retry log only; left ~4.5 MB ASAN raw logs untracked as CARRIED-OVER |
| 6–10 | DONE / RETRACTED / PROTECTED | unchanged | packaging rungs proven; no upload; no primary clean; no #858 |

Primary `claude/handover-freshness-0718` remains dirty/PROTECTED. Foreign unpushed branches remain CARRIED-OVER.

