# Session Handoff: drmTMB 0.7 rescope + pre-19 Aug CRAN ladder → Codex

Meta: 2026-08-07 evening (MDT) · from **Cursor** → to **Codex** · live-toolchain lane.

**You are Codex**, picking up drmTMB after Cursor closed the useful-0.7 / CondExp / board
slice on `main` and a sibling Cursor agent adjudicated win-builder on the **fixed**
tarball. You inherit **no chat context**. This document plus `AGENTS.md` plus current
git/`gh` state are authoritative.

Multi-lane board (read **every** live row — do not orphan siblings):
[`docs/dev-log/active-lane-split.md`](../active-lane-split.md).

---

## Critical Context

1. **Highest proven CRAN rung remains `tarball-clean`.** DESCRIPTION is still
   **0.6.0**. **Do not upload. Do not bump DESCRIPTION. Do not write
   `status_claim: platform-clean` without Shinichi’s explicit authorize.**
   Silence is not publish (CI-17 / D-93 publish half). D-49 still requires an
   exact-artifact runged gate — “docs only, skip platform-clean” would be dishonest.

2. **Win-builder on the fixed tarball is ERROR-free. That is evidence, not a
   ledger advance.** Fixed SHA-256
   `f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`
   (size **9818425**; CondExp `drm_src_path` repair inside):
   - R-devel [qS15UqA2O00A](https://win-builder.r-project.org/qS15UqA2O00A) —
     **1 NOTE**, CondExp ERROR **cleared** (email 2026-08-07T23:44:22Z)
   - R-release 4.6.1 [BQVnXOH066rJ](https://win-builder.r-project.org/BQVnXOH066rJ) —
     **1 NOTE**, CondExp ERROR **cleared** (email 2026-08-07T23:49:12Z)
   Remaining NOTE only: New submission; DESCRIPTION spellings
   (`centile` / `mis` / `uncalibrated`); `function-map-cheatsheet.png` URI.
   **Never FTP the stale unrepaired tarball** `c787ee40…` / 9817096 again.

3. **#946 is MERGED** → `origin/main` **`5affb962b`** (2026-08-08T01:08Z).
   Docs-only win-builder adjudication; GHA **never started** on the PR; Shinichi
   asked to merge anyway. #945 was CLOSED without merge (superseded). Receipts
   now live on `main` under `docs/dev-log/release/0.7.0-cran-gate/platform/`.
   Do **not** rewrite them. **`platform-clean` is still NOT claimed.**

4. **CRAN submit UI is offline 5–19 Aug 2026.** Upload is impossible until ~20 Aug
   **and** still requires owner word after that. Use the blackout for freeze /
   pkgdown / D-43 / `cran-comments`, not for science campaigns.

5. **Recommend YES — rescope 0.7** to first CRAN submission = packaging ladder
   through `submission-ready`, not “science complete.” See §Rescope. This does
   **not** contradict D-86 (first CRAN number is still **0.7.0**), D-49 (rungs
   still mandatory), or CI-17 (publish remains owner-only). It **does** treat
   D-93’s original “hold until RE-SD coverage is nominal everywhere” as
   **superseded in scope** by later measurement (D-97 / D-117 + shipped boundary
   warning #924): 0.7 ships honest documented inference, not AGHQ/REML science
   and not a D-117 PASS reinstatement.

---

## Goals / mission

Finish an honest **first CRAN submission path for drmTMB 0.7** before the submit
UI reopens (~19 Aug 2026): one freeze artifact that includes the CondExp repair,
platform evidence earned then owner-authorized, submission paperwork, DESCRIPTION
still 0.6.0 until publish call. Keep sibling science lanes (#858, #937, AGHQ
debris, 135-trace WITHHOLD) unorphaned and unentangled.

## Plans / roadmap (beyond this blackout)

Post-0.7 / 0.7.1+: AGHQ + non-Gaussian REML; Lane B E0 (#858); new Totoro interval
prereg for WITHHOLD cells; optional GVA implementation; q12 policy fence. D-117
*discharge* stays an owner publish judgement either way — PASS remains withheld.

---

## What Was Accomplished (already on `origin/main` or sibling PRs)

| Item | State |
| --- | --- |
| 135-trace promotions | **LANDED** #930 → `8df6f240` |
| CRAN arc card + board + snapshot | **LANDED** #931 |
| `source-clean` | **LANDED** #938 → freeze tip `459bd3fa9` |
| `tarball-clean` ledger | **LANDED** #939 → `744b9fbee` |
| useful-0.7 arc card | **LANDED** #940 → `8004fc058` |
| useful-0.7 user-facing | **LANDED** #942 → `9e85ff91d` |
| Cursor multi-lane handover (historical) | **LANDED** #943 → `80573f987` |
| CondExp `drm_src_path` repair + honest NOT READY docs | **LANDED** #941 → `13e8cafb0` |
| Post-merge board #944 | **LANDED** → `b0525f463` |
| Fixed-tarball win-builder FTP 226 + ERROR-free adjudication | **LANDED** #946 → `5affb962b` (GHA never started; docs-only merge authorized) |
| #945 FTP-receipt draft | **CLOSED** without merge (superseded by #946) |

Unrepaired freeze (historical, still the **claimed** tarball-clean artifact in
the ledger JSON): SHA `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
 / 9817096 / source `459bd3fa9`. That freeze **does not** contain #941. The
win-builder ERROR-free result is on the **later** fixed tarball `f9b9588e…` /
9818425. Next freeze must be a **new** SHA from post-#946 `main` (`5affb962b`
or later), never a reuse of `c787ee40…`.

---

## Current Working State

- **Working:** `origin/main` @ `5affb962b` (DESCRIPTION 0.6.0; useful-0.7 + CondExp
  repair + win-builder ERROR-free docs on main; ledger `tarball-clean`). CRAN UI
  offline until ~19 Aug.
- **In progress:** owner authorize of `platform-clean`; freeze / pkgdown / D-43 /
  cran-comments before ~19 Aug.
- **Not working / blocked:** `platform-clean` **claim**; `submission-ready`;
  DESCRIPTION 0.7.0 bump; CRAN upload; primary checkout AGHQ debris
  (**PROTECTED**); foreign unpushed branch estate (do not mass-push).

---

## Key Decisions & Rationale

- **D-49 / cran-release-gate:** report highest **proven** rung + next unproven
  rung. Default verdict NOT READY. One frozen tarball identified by source
  commit + SHA-256 + size + inventory. Grace/Rose/Pat (D-43) before first upload.
- **D-86:** first CRAN number is **0.7.0**; `0.6` is the never-submitted dev cycle.
  Bump DESCRIPTION only as part of the publish slice, not before a tarball exists.
- **D-93 / CI-17:** original hold was “do not publish known-weak RE-SD inference.”
  Later: D-97 accepted the **profile** route’s pooled coverage; D-117 measured the
  10-group corner and **withheld PASS**; #924 shipped the boundary warning; lme4
  matched the boundary behaviour. **Publish remains owner-only.** Rescope 0.7 to
  packaging + honest caveats, not to “wait for AGHQ/REML / PASS reinstatement.”
- **D-122:** “0.7 is coming later”; 0.6 was never released (no `0.6*`/`0.7*` tag;
  CRAN 404). Blackout does not change that.
- **D-50:** Totoro/DRAC for campaigns; never GitHub Actions artifacts.
- **D-87/D-88:** one owner per subject; do not touch #858 from this CRAN lane.
- **Rescope (this handover, for Shinichi to accept/reject):** see next section.

---

## Rescope 0.7 — product call (accept / reject)

**Recommend YES.** First CRAN submission = **tarball-clean proven + platform-clean
actually earned + submission-ready paperwork**, not “science complete.” Do **not**
shrink 0.7 to docs-only without platform-clean (that would violate D-49).

### In 0.7 (must / should before reopen ~19 Aug, then hold for owner publish)

- Packaging ladder through **`submission-ready`** on **one freeze artifact** that
  includes CondExp path repair **and** win-builder ERROR-free R-release + R-devel
  (already measured on `f9b9588e…`; re-freeze from post-#946 `main`).
- useful-0.7 user-facing already on `main` (#942).
- pkgdown `check_pkgdown` + **full rendered-site** + human skim (Gate 2/4).
  Blocks `submission-ready`, **not** `platform-clean`.
- D-43 Grace / Rose / Pat on that freeze artifact.
- `cran-comments.md` rewritten for a **new** submission (0.6 never shipped; 0.5.0
  was never accepted).
- DESCRIPTION bump to **0.7.0** only at owner publish call.
- Upload only after CRAN UI returns **and** Shinichi says publish.

### Explicitly OUT of 0.7 (defer post-0.7 / 0.7.1+)

- AGHQ + non-Gaussian REML science (primary `claude/handover-freshness-0718`
  debris stays **PROTECTED**).
- Lane B E0 **#858**.
- WITHHOLD re-prereg / new Totoro interval campaigns (closed 135-trace prereg).
- D-117 **PASS reinstatement** (discharge = owner publish call; warning already
  shipped).
- GVA **implementation** (docs #937 optional, not blocking).
- q12 policy fence lift.

---

## Landing State

`bash ~/shinichi-brain/tools/handoff_gate.sh` on the primary Dropbox checkout
**FAILS** (dirty `claude/handover-freshness-0718` + many foreign unpushed
branches). That is expected. **Declare CARRIED-OVER; do not mass-push.**

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `5affb962b` (#930–#946) | y | y | merged | **LANDED** |
| `#946` win-builder ERROR-free docs | y | y | **MERGED** `5affb962b` | **DONE** — GHA never started; docs-only merge authorized; ledger still `tarball-clean` |
| `#945` earlier FTP-receipt draft | y | y | **CLOSED**, not merged | **DONE / superseded** by #946 |
| This handover `cursor/codex-handover-0807` | this PR | land with PR | draft | **OWED → LAND** (docs only) |
| `#937` `claude/land-gva-decision` | y | y | open | **CARRIED-OVER / foreign-optional** — docs only; not CRAN-blocking |
| `#858` `codex/lane-b-e0-readiness` | y | y | draft open | **PROTECTED / foreign** |
| Primary `claude/handover-freshness-0718` dirty + unpushed | mixed | n | — | **PROTECTED** |
| Other local unpushed `codex/*` / agent branches | mixed | n | various | **CARRIED-OVER / foreign** — do not push from this lane |

### CARRIED-OVER resume commands

**#946 receipts (now on `main`; do not rewrite)**

```bash
git fetch origin
git show origin/main:docs/dev-log/release/0.7.0-cran-gate/platform/winbuilder-emails.md | head
# URLs: https://win-builder.r-project.org/qS15UqA2O00A (devel)
#       https://win-builder.r-project.org/BQVnXOH066rJ (release)
```

**This CRAN / Codex lane (fresh tree)**

```bash
git fetch origin
git worktree add ~/local-scratch/worktrees/drmTMB-07-codex -b codex/07-submission-ready origin/main
cd ~/local-scratch/worktrees/drmTMB-07-codex
export R_PROFILE_USER=/dev/null
export NOT_CRAN=true   # ordinary tests only; CRAN-lane checks run WITHOUT this
```

---

## Next Immediate Steps (classify on resume; execute only OWED)

| # | Item | Class at write |
|---|---|---|
| 1 | Rehydrate: `AGENTS.md` → this doc → `active-lane-split.md` → `git fetch` / confirm `origin/main` includes #946 | **OWED** |
| 2 | Ask Shinichi: authorize `platform-clean` ledger write? bump/upload still STOP until after ~19 Aug + his word? | **OWED** |
| 3 | Merge #946 | **DONE** (`5affb962b`; GHA never started; docs-only) |
| 4 | If `platform-clean` authorized: update ledger + freeze notes on a **fresh** worktree; still no DESCRIPTION bump / no upload | **OWED** (gated) |
| 5 | Re-freeze post-#946 `main` (new SHA / size / inventory + local `R CMD check --as-cran --no-manual`). Must include CondExp repair + useful-0.7 + #946 docs. Never reuse `c787ee40…` / 9817096 | **OWED** |
| 6 | Pkgdown Gate 2/4: `pkgdown::check_pkgdown()` + full rendered-site + human skim | **OWED** (blocks submission-ready, not platform-clean) |
| 7 | D-43 panel (Grace / Rose / Pat) on the freeze artifact | **OWED** after freeze |
| 8 | Draft `cran-comments.md` for a **new** 0.7.0 submission (0.6 never shipped) | **OWED** |
| 9 | Hold at submission-ready; DESCRIPTION **0.6.0** until owner bump + upload after ~20 Aug | **OWED** |
| 10 | Claim `tarball-clean` / useful-0.7 / CondExp-on-main / win-builder ERROR-free **evidence** | **DONE** (evidence); claim `platform-clean` is **not** DONE |
| 11 | Claim `platform-clean` / CRAN-ready / upload / DESCRIPTION 0.7.0 | **RETRACTED** until owner |
| 12 | Re-run Totoro under closed 135-trace prereg; reopen WITHHOLD; D-117 PASS reinstatement | **PROTECTED** |
| 13 | Touch #858, primary AGHQ debris, or mass-push foreign branches | **PROTECTED** |
| 14 | FTP stale unrepaired tarball `c787ee40…` / 9817096 | **RETRACTED** |

### Before-19th cadence (execute in order, no chat required once owner answers §2)

1. #946 land is **DONE**. If a later win-builder ERROR appears on a new freeze,
   fix on a fresh worktree and re-FTP **only** the repaired tarball (never
   `c787ee40…` / 9817096).
2. Re-freeze post-#946 main.
3. Pkgdown rendered-site audit.
4. D-43 on freeze.
5. `cran-comments.md` for new submission.
6. Hold. No bump. No upload until UI + owner.

Fences: D-50 Totoro/DRAC never GHA; no primary checkout; no #858 entanglement;
no 135-trace rerun.

---

## Blockers / Open Questions

1. **Owner authorize `platform-clean`?** Evidence exists (ERROR-free R-release +
   R-devel on `f9b9588e…`). Ledger must not move without yes.
2. **#946 merge-without-GHA:** DONE. Checks never started; owner asked to merge
   docs-only. Main ubuntu `R-CMD-check` will still fire on the merge commit.
3. **Valgrind / residual R-hub:** earlier platform attempt left valgrind
   incomplete; rchk adjudicated TMB-header noise. Ask whether that still gates
   `platform-clean` or only `submission-ready`.
4. **D-117 discharge / CI-17 publish:** still owner-only; unrelated to packaging
   rungs; PASS stays withheld.
5. **CRAN UI blackout** through 19 Aug 2026 — upload physically unavailable.

---

## Gotchas & Failed Approaches

- Local macOS `--as-cran` can pass CondExp via checkout geometry while win-builder
  tarball layout fails. **Do not treat local green as platform-clean.** The
  morning ERROR (`XhAiv0jf1AUd` / `nF44JzoI2nZ9`) was exactly that; fixed SHA
  cleared it.
- Intermediate win-builder queue emails (20:45–21:54Z) are **noise**. Only the
  ~23:00Z FTP pair (`qS15UqA2O00A` / `BQVnXOH066rJ`) counts. See #946
  `winbuilder-emails.md`.
- `PLATFORM-NOT-READY.md` on `main` after #946 keeps the historical filename and
  records ERROR-free evidence while the **ledger claim** stays `tarball-clean`.
- GitHub `conclusion: cancelled` can be concurrency **or** timeout. Compare job
  duration to the 75 min ceiling.
- `gh pr merge` may refuse when workflow blobs must be synthesised without
  `workflow` OAuth scope — update-branch, push over SSH, then merge.
- Handoff gate FAIL from hundreds of foreign unpushed branches is **not** a
  license to push them.
- useful-0.7 vignette CI: `confint()` columns are `parm` / `lower` / `upper`,
  not tidyverse names. Do not reintroduce `estimate` / `conf.low`.

---

## Files Created / Modified (this handover PR)

From `git diff --name-only origin/main...HEAD` after commit (plus this PR’s
own files):

- `docs/dev-log/handover/2026-08-07-codex-handover.md` (this file)
- `AGENTS.md` — Latest pointer → multi-lane board + this doc
- `docs/dev-log/active-lane-split.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/phase-snapshot.md` + `phase-snapshot-archive.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-08-07-codex-handover-rescope.md`

---

## Environment Codex needs (live toolchain)

| Need | Value |
|---|---|
| Preferred cwd | fresh worktree off `origin/main`, e.g. `~/local-scratch/worktrees/drmTMB-07-codex` — **never** Dropbox primary |
| R | `R_PROFILE_USER=/dev/null Rscript --no-init-file` (`.Rprofile` R-4.5 lib segfaults R 4.6) |
| Ordinary tests | `NOT_CRAN=true` |
| CRAN-lane check | **without** `NOT_CRAN`; `R CMD check --as-cran --no-manual` on the freeze tarball |
| Rose / D-43 | `.codex/agents/systems-auditor.toml` (Rose); reproducibility + user-tester for Grace/Pat |
| Safe verify (docs) | `pkgdown::check_pkgdown()`; full `pkgdown::build_site()` before submission-ready |
| Safe verify (rung) | `python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` |
| Must not stage | primary debris; `*.tar.gz` binaries; #946 receipt rewrites; foreign branch tips |

Codex runs live R/TMB (`R CMD check`, freeze rebuild, pkgdown render). Cursor/Claude
keep planning/prose unless Shinichi reassigns. Do not start Totoro.

---

## Sibling lanes (do not orphan)

| Lane | State | Pointer |
|---|---|---|
| **0.7 CRAN / this handover** | `tarball-clean` on main; win-builder ERROR-free docs **merged** (#946); rescope proposed | **this doc** |
| **#946 platform receipts** | **MERGED** `5affb962b` | on `main`; do not rewrite |
| useful-0.7 | **MERGED** #942 | after-task `2026-08-07-useful-07-user-facing.md` |
| CondExp repair | **MERGED** #941 | after-task `2026-08-07-winbuilder-drm-src-path-fix.md` |
| 135-trace | **LANDED** #930; prereg closed | historical `2026-08-05-cursor-handover-post-135.md` |
| Lane B E0 | open draft **#858** | foreign |
| GVA docs | open **#937** | optional; not blocking |
| Mesh/SPDE #893 | **MERGED** | closed |
| Missing-data #869 | **MERGED** | closed |
| Primary AGHQ debris | **PROTECTED** | never clean |

---

## Mission-control summary

| Repo | Branch / main | CI | Shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | `main` `5affb962b` | packaging + useful + CondExp + #946 merged | `tarball-clean` proven; DESCRIPTION 0.6.0 | no upload |
| drmTMB | #946 win-builder docs | GHA never started; **merged** anyway | ERROR-free R-rel+R-devel on `f9b9588e…` | owner: `platform-clean`? |
| drmTMB | this handover PR | docs-only draft | rescope + before-19th cadence | Codex executes freeze → pkgdown → D-43 → cran-comments |

---

## How to Resume

1. Start Codex in a **fresh** drmTMB worktree off `origin/main` (not the Dropbox
   primary).
2. Paste the prompt below.
3. Classify every Next Immediate Step as OWED / DONE / RETRACTED / PROTECTED
   against **live** `gh pr view 946` / `origin/main` before acting.
4. Execute **only OWED**. Ask Shinichi before writing `platform-clean`. #946 is
   already merged.
5. Rose (`.codex/agents/systems-auditor.toml`) before any public rung claim.

```text
Rehydrate from docs/dev-log/handover/2026-08-07-codex-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps.
```
