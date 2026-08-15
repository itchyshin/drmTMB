# Session Handover: the 0.7.0 CRAN ladder

Meta: 2026-08-15 · from Claude · target **Claude** (fresh session) ·
`origin/main` = `e19cc0807`.

## Critical Context

**Run the `cran-release-gate` skill FIRST.** It is mandatory at the start of any
CRAN release or resubmission and it is fail-closed: the default verdict is NOT
READY. Do not begin by reading old release documents — several of them are stale
in ways this handover names below.

**The previous CRAN-lane handover (`2026-08-11-070-gate-truth-handover.md`) is
partly wrong now.** It calls PR #996 "OPEN, do not merge"; #996 is **MERGED**.
Trust the repo over any narrative, including this one.

**The external-validation arc that ran before this is CLOSED** and touched none of
the release lane. See `2026-08-15-claude-handover.md`. But four PRs merged today
(#1030, #1031, #1034, #1035) and they bear on the candidate — see *Candidate drift*.

## Where the ladder actually stands

Rung vocabulary, in order, from `~/shinichi-brain/tools/cran_release_gate.py`:

```
source-clean → tarball-clean → platform-clean → submission-ready → submitted →
confirmed → incoming-passed → accepted → archived → live-with-check-page
```

**Current: `tarball-clean`.** One rung past the start, not two.
Recorded in `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json`
and `RUNG-REPORT-0.7.0.md`.

**Proven, for exactly one artifact:** `drmTMB_0.7.0.tar.gz`, SHA-256
`2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9`, 9,925,713
bytes, built from commit `a75c3c901`.

**Next rung `platform-clean` is mechanically blocked**, not merely unclaimed. The
gate requires `EVIDENCE_BY_RUNG["platform-clean"] = ["platform_matrix",
"external_logs"]`; **both keys are absent** from the ledger's `evidence` object.
Raising `status_claim` past `tarball-clean` fails closed today.

## The blocker that decides the shape of this work

**`src/drmTMB.cpp` changed on `main` after the freeze (PR #1012).** Every piece of
platform evidence therefore describes a *different binary* than `main` would build
now. A re-freeze is not a relabel — it needs a **new platform-matrix campaign**.

Compounding it: **win-builder has never run against the candidate's exact bytes.**
The newest win-builder log
(`docs/dev-log/release/0.7.0-cran-gate/platform/winbuilder-devel-submit.log`) is
dated 2026-08-07, four days *before* the 2026-08-11 freeze. The 3-OS and R-hub
runs that exist are same-*source*, not same-*bytes* — those services rebuild their
own tarball. The ledger already admits this as
`known_evidence_gaps.platform_evidence_provenance`.

The 2026-08-12 refreeze notice framed the choice — re-freeze now, or defer the
MSPL non-logit work to 0.7.1/0.8.0 and re-cut from an earlier point. **That choice
has not been made.** Making it is step 1 of real work.

## Candidate drift from today's merges

Four PRs landed on `main` today, all after the freeze:

- **#1035** changed `R/zzz.R` (`.onLoad` now registers `ranef`/`fixef` on `nlme`'s
  generics) and added `nlme` to Suggests. **This changes package load behaviour**
  and is the most release-relevant of the four.
- **#1034** added a vignette, `metadat` to Suggests, and edits to `_pkgdown.yml`,
  the reader-contract manifest and `docs/design/226`.
- **#1031** added three test files; **#1030** was one line of `_pkgdown.yml`.

None touched `src/`. But `DESCRIPTION` and `R/` both moved, so the candidate is
further from `main` than the 2026-08-11 record describes. Local `--as-cran` on the
#1034 branch was **0 errors / 0 warnings / 2 notes** (New submission; a stray
`figure/` directory since removed) — useful signal, **not** candidate evidence,
because it was not the frozen bytes.

## Non-engineering gates — neither is yours to resolve

- **D-93 — HELD, undischarged.** Repo and brain agree. No engineering step in this
  repository can discharge it. It is Shinichi's to lift.
- **D-117 — CONFLICTED, and you must not pick a side silently.** The brain's
  `memory/DECISIONS.md` records a discharge on 2026-08-09. `origin/main` — both
  `AGENTS.md` and `coordination-board.md`, written **two days later** on
  2026-08-11 — still says "RECOMMENDED, NOT DECIDED", and no repo-side record of
  an actual discharge was found. Treat it as **not decided** and resolve it with
  Shinichi before relying on either source.

## Open PRs on this lane

- **#959** (`claude/07-release-slice`, DRAFT) and **#955**
  (`codex/handover-07-candidate-prep-0809`) are stale by **248 / 259 commits** and
  superseded by #996's freeze lineage. **Close them explicitly. Do not merge
  either** — merging would reintroduce an abandoned candidate history.
- **#1037** (`claude/handover-2026-08-15`) is the previous arc's closeout handover.
  Handover-only; merge or leave, but it is not release work.
- **#1032**, **#1033**, **#858** are other lanes. Fenced.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `origin/main@e19cc0807` | yes | yes | #1030/#1031/#1034/#1035 merged | LANDED |
| `claude/external-oracle-intervals`, `claude/phase19-comparator-workflows`, `claude/ranef-s3-registration` | yes | yes | merged | LANDED; retained branches |
| `claude/pkgdown-reader-contracts-index` | yes | yes | #1030 merged | LANDED (0 ahead) |
| `claude/handover-2026-08-15` | yes | yes | #1037 open | CARRIED-OVER — handover only |
| `.worktrees/external-oracle` — 1 untracked path | no | no | — | SUPERSEDED copy of `docs/dev-log/external-oracle/phase19/`, which is on `main` via #1034. Safe to discard. |
| ~14 foreign branches with unpushed commits | mixed | no | — | PROTECTED FOREIGN — not this lane's to land |

**`handoff_gate.sh` FAILS**, on foreign unpushed branches and a stale lock. That is
global coordination state, not this lane's debt.

**⚠ REPORT TO SHINICHI, DO NOT REMOVE:** a stale `.git/index.lock` (0 bytes,
2026-08-14 18:43). The gate flags it; the harness blocks `.git` deletions.

## Next Immediate Steps — OWED only

1. Run lane preflight, fetch/prune, and reconcile this document against live git.
   Classify every item `OWED` / `DONE` / `RETRACTED` / `PROTECTED` before editing.
2. **Run the `cran-release-gate` skill.** Fail-closed; do not skip it because this
   handover already names the rung.
3. **Resolve D-117's true status** — find or produce a repo-side record of whether
   Shinichi recorded the discharge. Do not silently trust brain or repo.
4. **Put the re-freeze decision to Shinichi explicitly**, with its real cost: a new
   freeze means a **new platform-matrix campaign**, because `src/drmTMB.cpp` moved.
   Present the 2026-08-12 notice's two options and recommend one.
5. **Close #959 and #955** with a comment saying they are superseded by #996.
6. Only after 3–5: plan the platform evidence (win-builder against exact candidate
   bytes, plus the matrix). **Do not raise `status_claim` past `tarball-clean`**
   until `platform_matrix` and `external_logs` exist in the ledger.

**Do not** submit to CRAN, write `platform-clean`, or advance `status_claim` on
your own initiative. Those are Shinichi's calls.

## Environment

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin && git log --oneline origin/main -5
git worktree add .worktrees/cran-07 -b claude/07-cran-ladder origin/main
```

**Never work in the primary checkout** — it sits on `claude/handover-freshness-0718`,
~1020 commits behind `main` and dirty. Run R as
`R_PROFILE_USER=/dev/null Rscript --no-init-file` (the repo `.Rprofile` segfaults
R 4.6). Compute is local; no campaign is authorised by this handover.

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-15-070-cran-ladder-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
