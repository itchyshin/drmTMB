# Handover → Claude (Fable 5.1) — drmTMB REVERSE-parity lane, 2026-09-02

**You are Claude, picking up the drmTMB reverse-parity lane.** You inherit no chat context.
This document plus `AGENTS.md` and the current git state are authoritative.

**Nothing is merged. Nothing is pushed. No PR exists. No release motion was taken.**
D-164 still holds CRAN. All work is on 18 local `claude/rev-parity-*` branches.

---

## FIRST ACTIONS (do these before anything else)

1. `~/shinichi-brain/tools/lane_preflight.sh .` — **23 lanes were live at handover**, several
   codex-owned with open PRs. Name the lane you take.
2. Read this doc, then `docs/dev-log/handover/2026-09-01-claude-rev-parity-handover.md`
   (the overnight companion — more narrative detail, same facts).
3. Reconcile against git, and classify every item below as **OWED / DONE / RETRACTED / PROTECTED**.
4. **Do not work in the main checkout.** It sits on `feat/bridge-lss-reml-row12`, **45 commits
   behind `origin/main`**, and contains none of this lane's files. Read with
   `git show origin/main:<path>`; work in a worktree.

## ⚠ The landing gate FAILS, and it is a false negative — read this before you believe it

`~/shinichi-brain/tools/handoff_gate.sh .` reports **GATE FAIL — 11 acceptance ledgers have
UNMET gates**. It is pointed at the wrong tree. The gate runs
`gate-check --root <repo> --cwd <repo> --reverify`, i.e. it re-executes every oracle against the
**main checkout**, which is 45 behind `origin/main` and has neither `R/objective-at.R` nor
`R/provenance.R`. Of course they fail there.

The lane's own measurement, reproducible:

    node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . --status --scope rev-parity
    -> UNMET: 11 (met: 44)

and the 11 unmet are **exactly** leaf-a4 (4), leaf-a5 (5), leaf-b3 (2) — all explicitly **HELD**,
never attempted, each with a `## STATUS: HELD` block giving the reason and resume condition.
Every leaf with runnable oracles (a1, a2, a3, b1, b2, c1, d2, d3, d4, e0) reports **ALL MET**.

To reverify for real, point it at the integration worktree:

    node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --root . \
      --cwd <integration-worktree> --approve --jobs 1 .unlazy/rev-parity/gates/leaf-d4.md

This is the repo's own standing lesson — *a working tree is one BRANCH, not the repo* — biting a
tool rather than a person.

## Mission control

| item | state |
|---|---|
| repo / branch | drmTMB · 18 `claude/rev-parity-*` branches off `origin/main@27073059e` · **none merged, none pushed** |
| integration | `claude/rev-parity-integration-all` — 32 commits, 39 files, +4464/−145 |
| full suite | **PASSES, no abort.** 2 failures, both **proven pre-existing** on an `origin/main` control |
| `R CMD check --as-cran` | ARC D: **0 ERRORs**; +1 WARNING vs main = missing `checkbashisms` **tool**, substance verified under `/bin/dash` |
| acceptance ledger | **44 / 55 met**; 11 HELD behind PR #1112 |
| fences | DRM.jl untouched (pinned `main@f4778964`, `FENCE HELD`); **0 forbidden-path changes across all 18 branches** |
| leases | all released |

## What shipped (all verified by re-running, not by reading reports)

The programme was blocked because drmTMB could not answer cross-engine questions. It can now:

    objective_at(own optimum) = 167.361354778 ; -logLik = 167.361354778 ; diff 0.0e+00
    rival point WORSE by      = 0.301863757
    cross-start from rival    -> logLik -167.361354778 (orig -167.361354778)
    anchor on a PENALIZED fit -> diff 0.0e+00

| slice | branch head | what |
|---|---|---|
| A0 | `a7ccd5f25` | design 35: public `start=` contract DECIDED + `objective_at` section |
| A1 | `049a60c21` | 10 RED test blocks (verified 10/10 red before implementation) |
| A2 | `cb1671cb7` | `drm_control(start = ...)` + clamp-saturation and REML repairs |
| A3 | `7afe0b8fd` | exported `objective_at()` + penalized-fit convention fix |
| B1 | `0b0f869d9` | `fit$gradient`, `fit$gradient_max_component` — survives `keep_tmb_object=FALSE` |
| B2 | `05ad57465` | `hessian_conditioning` row, now from `sdr$cov.fixed` |
| C1 | `eb952d119` | `docs/design/258` naming spec — **stops at the spec by design** |
| D1 | `dd645c778` | landed the stranded R↔Julia parity board (42/42 rows match exactly) |
| D2 | `6f8871468` | #1081 — a green run states its own boundary |
| D3 | `c8329c80b` | #1083 — parity tests FAIL on code errors instead of skipping |
| D4 | `7ab8cf74b` | `drm_provenance()` + `configure` bake |
| docs | `2648d4422`, `dfeccc931`, `9068317b5`, `9663fb2f7`, `ee7053af1` | DRM.jl findings (+correction), board entry, routing receipt, reconciliation + ARC E scout, overnight handover |

## Key decisions & rationale

- **`objective_at()` reports `logLik()`'s UNPENALIZED convention**, re-evaluating the penalty at
  the *queried* point so the invariant holds away from the optimum. Cost stated in roxygen: the
  number is not literally what the optimizer minimised on a MAP fit.
- **`obj$he()` was DELETED**; conditioning comes from `sdr$cov.fixed`. It segfaulted on
  deserialized fits and a segfault is uncatchable. Measured equivalent (`cond(H) = 2.408905027`
  vs `cond(cov) = 2.408903421`), serialization-safe, and it **closes the random-effect gap**
  where `he()` errors outright. **Taken unattended** — the alternative was shipping code that
  kills user sessions; branch is unmerged and reviewable. **Confirm you agree with this.**
- **A4/A5 HELD** behind PR #1112 (216 lines of `R/julia-bridge.R`) — D-87, the overlap is
  Shinichi's call. A4's question is already answered: the shim is reachable with **zero DRM.jl
  edits**, but only via two DRM.jl **private** names — a "yes, but".
- **ARC C stops after the spec** pending the naming-authority decision.

## Blockers / open questions — ALL need Shinichi, none are yours to settle

1. **Naming authority** (blocks C2–C4): base-R spelling vs DRM.jl's translated map. Spec
   recommends base-R and refuses to decide. Sharpened by a correction: a producer **does** exist
   on both sides (`DRM.jl src/bridge.jl:1272-1279`) — the real question is whether the map is
   *populated and correct for the constructs that fail*.
2. **PR #1112 ordering** — unblocks A4/A5.
3. **The `sdr$cov.fixed` redesign** — is it the right permanent shape?
4. **Ultracode opt-in** — still unspent; two places it would pay.
5. Recorded limitations, not bugs: Student-t `nu` labels rejected by the start vocabulary
   (breaks the `fixef()`→labels idiom **both gate oracles use**); `vcov()` hard-aborts when
   `sdreport` fails, and the fallback choice is a statistical decision, not an engineering one.

## Gotchas / failed approaches — do NOT repeat these

- **A pass/fail count cannot express "the process died".** Two full-suite runs reported
  **0 failures** while killing R. Read the abort line, the exit code, and the *timings*.
- **`--as-cran` with `NOT_CRAN=false` runs the suite in 43 seconds, not ~20 minutes.** It does
  **not** subsume the full-suite gate. I claimed it did; I was wrong.
- **A dead-pointer guard cannot fix the `he()` segfault** — `check_drm()` revives the pointer, so
  it is not null when a guard tests it, but the ADGrad tape is still unusable. Disproven, deleted.
- **Route sub-agents by TOOLS, not tier.** `documentation_writer` has no Bash; `formula_reviewer`
  has no Write.
- **Worktrees are slow here** (19,135 files on Dropbox). Create them serially, never inside a
  parallel fan-out; prefer git plumbing for docs-only commits.
- **The coordination board has THREE diverging versions** across live refs, one deleting 72
  lines. Diff before appending.
- Four of my own gates were wrong until I ran them (`ifne` absent; a whole-repo grep that failed
  on a doc quoting its own evidence; a "DRM.jl must be clean" fence that failed on the foreign
  lane's file; an A1 gate counting expectations where blocks were the unit).

## Files created / modified

`git diff --name-only origin/main claude/rev-parity-integration-all` → 39 files. Highlights:
`R/objective-at.R` (new) · `R/provenance.R` (new) · `R/check.R` · `R/control.R` · `R/drmTMB.R` ·
`configure`, `configure.win` (new) · `tools/drmtmb_provenance.R` (new) ·
`tools/function-cheatsheet-source.Rmd` · `docs/design/35-*`, `docs/design/258-*` (new) ·
`docs/design/capability-status.md` (new) · 6 new `tests/testthat/test-*.R` · `NEWS.md` ·
plus `docs/dev-log/{handover,plan-actual,after-task}/2026-09-0*`.
**Never stage:** `.unlazy/` (git-excluded run state), foreign lanes' worktrees.

## Environment

    cd <a worktree off origin/main>          # NOT the main checkout (45 behind, stale branch)
    NOT_CRAN=true Rscript -e 'devtools::test(filter = "...")'   # filtered: minutes
    NOT_CRAN=true Rscript -e 'devtools::test()'                 # FULL: ~25 min (D-139 — estimate first)
    R CMD build --no-build-vignettes . && R CMD check <tar.gz> --as-cran --no-manual

`--no-build-vignettes` adds **2 spurious vignette WARNINGs**; a control on `origin/main` with the
same flags shows them too. Local only; never GitHub Actions for campaigns (D-50).

## CARRIED-OVER — every item, and why it is not landed

**All 18 branches are CARRIED-OVER. None is merged; none is pushed** (`git ls-remote --heads
origin 'claude/rev-parity-*'` returns **0**). They exist only on this machine's disk. A fresh
clone, a disk failure, or a `git gc` in an unexpected state loses the entire lane.

**Reason, common to all of them:** the lane brief is explicit — *no merges to drmTMB main without
Shinichi* — and pushing is an outward-facing action nobody authorised while he was away. This is
a deliberate hold, not an oversight. **Pushing is his call and it is the first thing to raise.**

| branch (`claude/rev-parity-…`) | head | commits | reason held |
|---|---|---|---|
| `integration-all` | `14035812f` | 32 | **the one to read first** — everything merged, suite passes |
| `arcd-integration` | `3c07afb6e` | 12 | ARC D only; superseded by `integration-all` |
| `a0-design35` | `a7ccd5f25` | 2 | design decision, needs owner review |
| `a1-start-tests` | `049a60c21` | 3 | RED tests; meaningless without A2 |
| `a2-start-impl` | `cb1671cb7` | 5 | public API change |
| `a3-objective-at` | `7afe0b8fd` | 8 | **new export**; convention choice needs confirming |
| `b1-stored-gradient` | `0b0f869d9` | 5 | changes the fit object's shape |
| `b2-check-conditioning` | `05ad57465` | 4 | **`obj$he()` removed unattended — confirm first** |
| `c1-naming-spec` | `eb952d119` | 1 | spec only; blocked on the authority decision |
| `d1-capability-status` | `dd645c778` | 1 | shared parity board |
| `d2-loud-julia-skip` | `6f8871468` | 1 | closes #1081 |
| `d3-error-not-skip` | `c8329c80b` | 2 | closes #1083 |
| `d4-provenance` | `7ab8cf74b` | 3 | adds `configure`/`configure.win` — CRAN-visible |
| `drmjl-findings` | `2648d4422` | 3 | owed to the DRM.jl lane, incl. a correction |
| `board-entry` | `dfeccc931` | 1 | coordination board has 3 diverging versions |
| `routing-receipt` | `9068317b5` | 1 | Melissa input |
| `overnight-docs` | `9663fb2f7` | 1 | reconciliation + ARC E scout |
| `handover` | `d569a4ac5` | 5 | this document |

**Exact resume commands.** Inspect without disturbing the main checkout (which is on a foreign
branch, 45 behind):

    git log --oneline origin/main..claude/rev-parity-integration-all
    git diff --stat origin/main claude/rev-parity-integration-all
    git show origin/main:<path>                       # read main's version of any file

    # work on it safely (worktrees are slow here -- ~19k files on Dropbox; allow minutes)
    git worktree add /tmp/wt-rp claude/rev-parity-integration-all

    # push, ONLY if Shinichi says so:
    git push -u origin claude/rev-parity-integration-all

**PROTECTED — do not touch:** the main checkout's branch `feat/bridge-lss-reml-row12` and every
`codex/*` and `cursor/*` branch; `/Users/z3437171/Dropbox/Github Local/DRM.jl` in its entirety
(a live foreign lane; we only ever read it, and the pinned fence confirms it is unchanged);
`.unlazy/` (git-excluded run state — never stage it).

**No PR was opened**, because a PR requires a push and the push is unauthorised. The protocol's
"commit, then open a PR, do not auto-merge" stops at the commit here, deliberately.

## Next immediate steps — narrow, and all OWED

1. **Reconcile.** Run lane preflight; run the scope status command above; confirm 44/55 and that
   the 11 unmet are the HELD ones. Classify this doc's items.
2. **Ask Shinichi the five open questions** above. Do not settle 1–4 yourself.
3. **Push or don't — his call, and say it loudly.** 18 branches are **local only**; a fresh clone
   or a disk loss takes them all. `git ls-remote --heads origin 'claude/rev-parity-*'` returns 0.
4. **Only after (2):** unblock ARC C (needs the authority decision) or A4/A5 (needs #1112).
5. Do **not** re-run the full suite unless something changed — it passed, and it costs ~25 min.

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
