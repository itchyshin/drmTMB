# Handover to Codex — drmTMB 0.7.0 CRAN lane: the gate now names the right package; four decisions are outstanding

Meta: 2026-08-11 · from Claude to a fresh **Codex** session · **the committed repository is
authoritative; the authoring chat is gone.**

> **Filename note.** Deliberately not `2026-08-11-codex-handover.md`. Two other handovers already
> carry this date — `2026-08-11-claude-handover.md` (a different Claude lane) and
> `2026-08-11-070-gate-truth-handover.md` (this lane's arc doc). Same-date collisions have caused
> real ambiguity in this repo twice before.

Read `AGENTS.md` first (native to you), then this file, then
[`../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md`](../release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md)
and [`../release-audits/2026-08-11-0.7.0-open-issue-triage.md`](../release-audits/2026-08-11-0.7.0-open-issue-triage.md).
Classify every item below `OWED`, `DONE`, `RETRACTED`, or `PROTECTED` against live git and GitHub
state before acting.

## Goal

drmTMB's **first CRAN release as 0.7.0** (D-86), under D-49's fail-closed rung ladder: never say
"CRAN ready" — always report the **highest proven rung and the next unproven one**. D-89 sets the
pace: submission is far away *by choice*, and the ~19 Aug portal reopening is **a floor, not a
deadline**. Shinichi reconfirmed that today.

## Current state — read this before anything else

**`origin/main` = `511a7a390`. `DESCRIPTION` is now `0.7.0`.**
**Rung: `tarball-clean` proven · `platform-clean` unproven.** The rung did not move today, deliberately.

| field | value |
| --- | --- |
| candidate tarball | `drmTMB_0.7.0.tar.gz` |
| SHA-256 | `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` |
| size | 9,925,713 bytes |
| built from | `a75c3c9013e1e7c4ab8e56aa13baf5e668b99c76` |
| durable copies | `~/drmTMB-release-artifacts/0.7.0/` · `snakagaw@totoro:~/drmTMB_0.7.0_cand2.tar.gz` |
| gate ledger | `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` |

**⚠ The candidate no longer matches `main`.** `NEWS.md` and today's source fixes are shipped files.
**A re-freeze is required before submission.** Check currency with:

```sh
git diff --name-only a75c3c901 origin/main -- R src inst man tests vignettes DESCRIPTION NAMESPACE NEWS.md
# non-empty => re-freeze needed. Currently non-empty (NEWS.md + today's fixes).
```

## What shipped today (8 PRs, all merged)

| PR | merge | what |
| --- | --- | --- |
| #1000 | `5a225378d` | The CRAN gate now describes the live candidate |
| #996 | `a3217da93` | Candidate freeze; `DESCRIPTION` → 0.7.0 |
| #1002 | `f1fa27288` | `NEWS.md` stops claiming a CRAN release drmTMB has not had |
| #1003 | `08a7df49f` | All 42 open issues triaged — **0 BLOCKING** |
| #1006 | `4e4a915aa` | #983 fixed, #870 message fixed, 4 limits documented, C17 re-certified |
| #1013 | `aa76c2399` | CI receipts recorded |
| #1014 | `511a7a390` | Coordination-board ownership contradiction resolved |

**The headline defect this lane fixed.** The repo's only machine-checkable release gate,
`2026-08-07-07-cran-release-ledger.json`, described the **superseded 0.6.0 tarball** `2e5234bd` /
`ad475cc39` — and running `cran_release_gate.py` against it printed `READY FOR CLAIMED RUNG`. A green
mechanical verdict for a package nobody intends to ship. The evidence was never wrong; the gate
guarding it had drifted onto a dead artifact.

## OWED — Next Immediate Steps

**Three of the four are owner decisions, not engineering. Do not try to resolve them by measuring
more.**

1. **D-93 holds 0.7.0 — undischarged.** Shinichi chose to hold rather than ship with documented
   undercoverage: *"we do not publish 0.7 yet — we will fix it."* **No amount of platform evidence
   releases 0.7.0 while this stands.** The concrete ask carried forward: *write down what "coverage
   is fixed" means numerically BEFORE looking at more numbers* — nominal 0.95, the small-sample floor
   0.918 (which the profile route already clears at 0.9248), or something `g`-aware. Deciding after
   looking repeats D-117's trap.
2. **D-117 — discharge RECOMMENDED, NOT DECIDED.** Re-run 2026-08-09 at **400,000 attempts**: pooled
   **0.9248** (SE 0.000417), every cell clearing `ss_floor(10) = 0.918`. Recommendation with four
   conditions at
   [`../release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md`](../release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md).
   It names the reading that would overturn it: if *"recovery/coverage gate"* requires a pass on
   **both** halves, it does not discharge, because **no recovery criterion was ever pre-registered**.
   Brain row corrected 2026-08-11 (`DECISIONS.md`, commit `a07b8af`) — it had been stale since the
   2026-08-04 run.
3. **win-builder — ABSENT, and it is Shinichi's action.** The agent upload path is classifier-blocked.
   Run-book: [`../release/0.7.0-cran-gate/WIN-BUILDER-RUNBOOK.md`](../release/0.7.0-cran-gate/WIN-BUILDER-RUNBOOK.md).
   Upload the **durable** copy, not the `/private/tmp` one. It is also the only measurement of
   Windows CRAN-lane time, which remains a projection.
4. **Owed before `submission-ready`, and these ARE yours:** the **rights re-review** (stale — predates
   the 2026-08-09 `inst/COPYRIGHTS` gllvmTMB binomial-link adaptation; documented borrowing, licence
   compatible, but unreviewed) and the **source-clean re-cut** (`product_contract` and
   `rendered_site` describe `8df6f2402`, 339 files back). All four gaps are recorded in the ledger's
   `known_evidence_gaps`.

## Explicitly yours as the live-toolchain lane

Claude planned and wrote; **you run the real toolchain.** The genuinely actionable Codex work here:

- **The rendered-site check on the candidate.** No `pkgdown` render covers `a75c3c901`; the existing
  `rendered_site` evidence explicitly declines a rebuild and describes `8df6f2402`. The candidate
  ships a vignette (`vignettes/first-week-intervals.Rmd`) that did not exist then.
- **The re-freeze**, once Shinichi authorises it. `scratchpad/freeze-ready.sh` gates the cut point
  (three conditions, not one); `scratchpad/freeze.sh` performs it. Both are **untracked** in the
  primary checkout — a prior session's, not this one's.
- **Any campaign** if D-93 gets a numeric criterion. Route to Totoro/DRAC, never GitHub Actions
  (D-50). Obey the 30-minute rule: estimate first, and above 30 min show a pre-run test and get
  approval.

## Live environment

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e '...'   # the .Rprofile R-4.5 lib segfaults R 4.6
python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json
python3 -B tools/capability_ledger.py --check              # expect OK (31 generated outputs)
python3 -m unittest tools.tests.test_capability_ledger     # expect 67 tests OK
python3 tools/recertify-c17.py --label <x> --dry-run       # C17 re-cert; owner-gated
```

Work in a fresh worktree off `origin/main`. **Never the primary checkout** —
`/Users/z3437171/Dropbox/Github Local/drmTMB` is on the stale July branch
`claude/handover-freshness-0718`, is dirty, and is **PROTECTED**. Never `git add -A`. Do not stage
anything under `scratchpad/` you did not create. Totoro is reachable through its existing
ControlMaster (`ls ~/.ssh/cm-*totoro*`), no Duo needed; pin `OPENBLAS_NUM_THREADS=1`.

Team mirror: `.codex/agents/*.toml`. **A Rose audit is mandatory before any public claim.**

## Gotchas — each cost real time today

- **"Same commit" is not "same bytes."** GitHub Actions and R-hub check out source and build their
  own tarball; they never see the frozen file. Only the local `--as-cran` and the Totoro valgrind run
  are exact-bytes. `cran-comments.md` briefly asserted otherwise and was corrected before commit.
- **The frozen bytes cannot be regenerated.** `R CMD build` embeds timestamps. Restore from a copy;
  never rebuild and assume equivalence.
- **The gate stats every path and fails closed.** A ledger anchored in a session scratchpad stops
  passing once `/private/tmp` is purged. Evidence now lives in `~/drmTMB-release-artifacts/0.7.0/`
  with `repo_path` back-references — but that root is **machine-local and not version-controlled**.
- **The gate has no supersession concept.** It ignores `superseded_by`, so the 2026-08-07 predecessor
  ledger *also* still returns `READY FOR CLAIMED RUNG`. The marker is prose. **Read the first line of
  any ledger before citing it.**
- **C17 pins five whole files** (`R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`, the model-15 test and
  runner). Editing a `cli_abort()` string in an 18,000-line file stales the receipt. Clear it with
  `tools/recertify-c17.py` — **owner-gated** — never by hand. It refuses to rewire if behaviour moved.
  `claim_boundary` is prose **no automated check validates**; a human must read and update it.
- **`recertify-c17.py` exits 0 while printing "refusing to run"** if its run directory exists. A
  caller checking `$?` reads the refusal as success.
- **`test_c17_failure_modes_give_opposite_fingerprint_instructions` reads live repo state** and
  asserts a message naming `R/methods.R`, so it fails whenever a *different* pinned file changed.
- **Cite valgrind as "clean on a documented seven-file subset", never "valgrind clean."**
- **Re-run certification runners on a CLEAN tree.** An earlier run recorded a dirty worktree in its
  own provenance; a receipt taken over uncommitted source is weaker evidence.

## Landing state

**This lane's own work is fully landed** — all seven branches merged to `main`; nothing of mine is
carried over.

| artifact | state |
| --- | --- |
| 7 lane branches (`claude/07-*`) | **MERGED** — #996, #1000, #1002, #1003, #1006, #1013, #1014 |
| `~/drmTMB-release-artifacts/0.7.0/` | durable, **outside version control** — do not delete |
| Brain `DECISIONS.md` D-117 row | committed locally `a07b8af` (vault has no remote, D-37) |
| **22 foreign branches with unpushed commits** (`codex/lane-b-q1-preflight-admission` **226**, `codex/lane-c-provider-cohort-20260729` **99**, `codex/aoi2-drac-recovery` **59**, …) | **CARRIED-OVER · PROTECTED FOREIGN** — pre-existing, not this session's. Do **not** push, clean, or reconcile |
| PRs #1012, #1005, #1004, #959, #955, #858 | **PROTECTED FOREIGN** — other lanes, including two other Claude lanes |
| Stale `.git/index.lock` (2026-08-05) | **REPORT ONLY** — needs a human `rm`; the harness blocks `.git` deletions |
| 3 unmerged Cursor branches rewriting the coordination board | **CARRIED-OVER** — see below |

`tools/handoff_gate.sh` returns **GATE FAIL**, entirely from the foreign branches and the lock above.
Declared here per the protocol.

## Blockers / open questions — Shinichi's, not yours

- **D-93 and D-117** (above). Both are decisions; neither is a measurement problem now.
- **Cursor vs Claude ownership of the live 0.7 slices.** Three unmerged Cursor branches
  (`cursor/handover-0807`, `cursor/07-tarball-clean`, `cursor/07-cran-readiness`, all 2026-08-07)
  rewrite the coordination board's Active Lane Split. They **agree** with the current board that
  Codex no longer owns the CRAN ladder; the single conflict is Cursor vs Claude. **Rebase, do not
  straight-merge** — a straight merge drops the 2026-08-11 reassignment. Resolving it is D-87,
  Shinichi's call.
- **A THIRD candidate identity is in circulation, on an unmerged branch.** `claude/07-release-slice`
  (PR **#959**, draft, `bce9cfb6f`) carries an `AGENTS.md` snapshot reading *"0.7.0 CANDIDATE
  `a8f7c479` FROZEN at `tarball-clean`"*. That is **not** the live candidate — this lane's is
  `2176e4b8…cda9`, built from `a75c3c901`. If #959 merges as-is its snapshot **overwrites the current
  pointer and names a superseded artifact**, which is precisely the class of defect this lane spent
  the day removing. Reconcile #959's snapshot before merging it; do not assume the newest merge wins.
- **An evidence-led validation doctrine packet** is under discussion (non-binding). If adopted, the
  highest-value part for this repo is the **pre-registered PASS/HOLD rule** — precisely what D-117's
  absence of one is costing right now.

## Multi-lane pointer

**17 lanes were live at handover.** Per the multi-lane rule, the `AGENTS.md` snapshot points at the
coordination board's Active-Lane-Split — which lists each lane's current handover — **not** at this
document alone. Do not narrow it. Board:
[`../coordination-board.md`](../coordination-board.md).

## Files created / modified this session

`NEWS.md` · `R/drmTMB.R` · `R/mspl-estimator.R` · `R/profile.R` · `cran-comments.md` ·
`man/confint.drmTMB.Rd` · `man/drmTMB.Rd` · `tests/testthat/test-mspl-estimator.R` ·
`docs/dev-log/active-lane-split.md` · `docs/dev-log/check-log.md` ·
`docs/dev-log/coordination-board.md` ·
`docs/dev-log/after-task/2026-08-11-070-gate-truth.md` ·
`docs/dev-log/plan-actual/2026-08-11-070-gate-truth.md` ·
`docs/dev-log/handover/2026-08-11-070-gate-truth-handover.md` · this file ·
`docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES.md` ·
`docs/dev-log/release/0.7.0-cran-gate/WIN-BUILDER-RUNBOOK.md` ·
`docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` ·
`docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` ·
`docs/dev-log/release-audits/2026-08-11-0.7.0-open-issue-triage.md` ·
`docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` ·
`docs/dev-log/implementation-recovery/2026-08-11-cran-polish-c17c2-c14-final-source-compatibility/` (4 files) ·
plus `AGENTS.md` (snapshot pointer, in this handover's commit).

## How to resume

```sh
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git diff --name-only a75c3c901 origin/main -- R src inst man tests vignettes DESCRIPTION NAMESPACE NEWS.md
python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json
gh pr list --state open
```

## Fenced — do not do without a new decision

Claim or write `platform-clean` · upload to CRAN · re-freeze without authorisation · resolve the
Cursor/Claude board overlap · push, clean, or reconcile any foreign branch · `rm` the stale
`.git/index.lock` · work in or stage from the primary checkout.

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-11-codex-handover-07-cran-lane.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
