# Handover -> Claude -- drmTMB true-parity overnight lane, 2026-09-03 (05:00)

**You are Claude, picking up the overnight lane's unfinished close.** You inherit no chat context.
This document, `AGENTS.md`, `LOOP/GOAL.md`, `LOOP/checkpoint.md`, and the current git/PR state are
authoritative. The lane worktree is `~/local-scratch/lanes/drmTMB-true-parity-night` on branch
`claude/lane-true-parity-night`, launched from `origin/main` at `0ceb77eb0`, envelope D-208
(Shinichi, 2026-09-02 evening).

## State for Shinichi at 05:00

Two of five arc PRs merged clean overnight: #1122 (N5/N5b pilot receipts, merged `5aa488259`) and
#1126 (N4 board row + deterministic indefinite test, merged `ef796e7f9`); both show green CI at
merge. The other three sit open as draft PRs with CI still running on their last push and are not
yet mergeable by the lane on its own authority: #1124 (N1, the headline label-contract arc,
Rose-repaired three ways, head `fc4690ea0`), #1125 (N2, the `heritability()`/`icc()`/
`repeatability()` accessors, Rose-repaired four ways, head `762ac950f`), and #1128 (N3, the
`objective_at()` label widening to `rho12` and the q4 phylo block, Rose-repaired two ways, head
`6def01c6d`). All three passed `os-matrix` and were mid-run on `ubuntu-latest (release)` at last
check; none has failed. Fenced and untouched: DRM.jl (only the expected `shannon-coordinator.toml`
sits dirty there), CRAN/release/registration (D-164), and every `r_bridge_status`/
`julia-capabilities.tsv` cell (no leaf's gate touches promotion). Four issues were filed from this
lane's own findings and remain open: #1123 (bootstrap CIs error on `cbind()` binomial responses),
#1127 (16 live-Julia test sites across 9 files swallow engine errors as skips), #1129
(`imputed()` conditional modes off by 1e-4-1e-3), #1130 (nlminb tolerance leaves location-scale
fits ~1e-5 short, mirror of #575). N6 close itself is incomplete: this handover and the after-task
exist as drafts in the lane worktree only, not on `main`; the Melissa reconcile is also
worktree-only; the lease has not been released.

## REHYDRATION (run in order)

1. Read `LOOP/GOAL.md`, then `LOOP/checkpoint.md`, then `LOOP/arcs.md` in the lane worktree
   (`~/local-scratch/lanes/drmTMB-true-parity-night`). Expected: GOAL.md states the mission and
   fences unchanged since launch; checkpoint.md's last line is the `06d40af53`/`54d10ca1e`/
   `6d9fa6582` state (all five arcs re-verified, merge order set, after-task and reconcile drafted);
   arcs.md shows N0/N5/N5b as `[x]`, N1/N2/N3 as `[~]` (built, PR open), N6 as `[ ]`.
2. `git fetch origin` from the lane worktree. Expected: no error; confirms whether #1124/#1125/
   #1128 moved since this file was written (a fresh Rose repair push, a CI re-run, or a merge).
3. `gh pr list --author @me --state open --repo itchyshin/drmTMB`. Expected: #1124, #1125, #1128
   still listed as open drafts if untouched; their absence means one merged or was closed -- check
   `gh pr view <n> --json state,mergedAt` before assuming either.
4. `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status .unlazy/night/GATES.md`
   from the main checkout (`/Users/z3437171/Dropbox/Github Local/drmTMB`, not the lane worktree --
   the checker resolves ledgers against `--root`). Expected AT LAST CHECK: all four night gates
   (N1-N4) show `UNMET (unchecked)` because `.unlazy/night/reverify-all.result` has never been
   written -- the runner below has not been re-run since the individual leaf files were last
   verified directly. This is a stale ledger, not a failing one; do not read it as red.
5. `.unlazy/night/bin/reverify-all.sh` (from the main checkout). **Before running it**, read it --
   it hardcodes `DRM_JL_PATH` to a scratchpad path under a specific past session's temp directory
   (`/private/tmp/claude-503/.../scratchpad/drmjl-objat`) and worktree paths for n2-n5 under the
   same session-specific scratchpad. Those paths belong to the session that authored the runner and
   will not exist in a fresh session -- see gotcha below before trusting its exit code.
6. DRM.jl pinned clone at ref `77513aa0` (carries #577 and #599; this is the SHA every leaf's live
   Julia gate, A4/A5, and the tip-identity receipt were verified against). If no durable clone
   exists at that ref, create one: `git clone <DRM.jl remote or local path> <dest> && git -C <dest>
   checkout 77513aa0 && export DRM_JL_PATH=<dest>`. Verify with `git -C <dest> log -1 --oneline`;
   expected `77513aa0 Merge pull request #597 from itchyshin/claude/577-ml-path-structural-zeros`.
   Do not re-pin to a newer DRM.jl SHA without checking with that lane first (GOAL.md invariant).

### Gotcha: the night runner's paths are session-scratchpad, not durable

`.unlazy/night/bin/reverify-all.sh` sets `S=/private/tmp/claude-503/.../7db7461b-.../scratchpad`
and points `DRM_JL_PATH` and every leaf's `--cwd` worktree at subdirectories of that one path
(`$S/wt-n2`, `$S/wt-n3`, `$S/wt-n4`, `$S/wt-n5`, plus `~/local-scratch/lanes/drmTMB-n1-worktree`
for n1, which IS durable). Claude Code scratchpads are per-session and are cleaned up; a fresh
session gets a different path and none of `$S`'s contents. Before trusting a green run from this
script, edit its `S=` line to a durable clone/worktree set (re-clone DRM.jl at 77513aa0 per step 6
above; recreate or relocate the n2/n3/n4/n5 arc worktrees if they too were session-scratchpad --
check with `git worktree list` in the main checkout first, since n1's worktree survived at a
durable path and the others may have as well).

## OWED Next Immediate Steps (smallest first)

1. **(Done before close.) All five PRs merged.** #1126 ef796e7f9, #1122 5aa488259, #1128 fa1ebf95b,
   #1125 9bc9db99f, #1124 d3d205486; merge log `.unlazy/night/merge-log.txt`; the after-task and
   reconcile carry the SHAs. Verify: `gh pr view 1122 1124 1125 1126 1128 --json state,mergeCommit`.
2. **(Done before close.) S3-G4 flipped ABANDONED to MET** in `.unlazy/true-parity/gates/leaf-s3.md`
   after #1124 merged; oracle `NO_GUESSING_OK` re-run and red control recorded in the EVIDENCE line.

3. **Regenerate the lss-tip-identity receipt on `main` LAST, after both #1124 and #1128 land**
   (both touch `R/julia-bridge.R`, and the receipt pins the whole file -- regenerating before both
   land would need a second regeneration). From the post-merge `main` checkout:
   ```
   OPENBLAS_NUM_THREADS=1 DRM_JL_PATH=<clone-at-77513aa0> \
     Rscript tools/run-julia-phylo-labels-public.R <clone-at-77513aa0> \
     docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json.new tree
   ```
   then `cp docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json{.new,}` (the
   script refuses to overwrite in place), then verify:
   ```
   Rscript tools/check-julia-phylo-labels-receipt.R \
     docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json --current --self-test
   ```
   Expected: exits 0, self-test passes, no diff against the copied-in file. Commit the regenerated
   receipt on `main` directly or via a small docs/receipt PR -- this file is a whole-file pin, so
   land it promptly to unblock the next lane that touches `R/julia-bridge.R`.
4. **Land the docs on `main` via a docs PR**: this handover, the after-task
   (`docs/dev-log/after-task/2026-09-03-true-parity-night.md`), and the reconcile
   (`docs/dev-log/plan-actual/2026-09-03-true-parity-night.md`), all currently living only on
   `claude/lane-true-parity-night` in the lane worktree. Branch from post-merge `main`, cherry-pick
   or copy the three files (with step 1's SHAs filled in and step 2/3 done), open a plain docs PR,
   merge once CI is green (docs-only changes should not touch R CMD check content). Verify:
   `git log main --oneline | grep <merge sha>` and `gh pr view <n> --json mergedAt`.
5. **Delete merged `claude/night-*` and `claude/n1-*` branches** (approved under D-208's
   "deleting merged lane branches" pre-authorisation): `claude/night-n5-prerun` (merged as #1122),
   `claude/night-n4-board-indefinite` (merged as #1126), and once landed, `claude/night-n2-accessors`
   (#1125), `claude/night-n3-labels` (#1128), `claude/n1-label-contract-all-routes` (#1124). Verify
   each with `git branch -r --merged origin/main | grep <branch>` before deleting, then
   `git push origin --delete <branch>`.
6. **Carry the morning questions forward** (from the reconcile's "Morning questions for Shinichi"
   section, items 1, 3-9 -- item 2 is resolved and kept for the record only): the `summary()`
   repeatability-denominator vs. `icc()` naming collision; whether #1127 gets its own arc or is
   absorbed by an existing swallow-pattern lane; priority on #1123/#1129/#1130; whether sigma-side
   phylo terms and random-slope phylo blocks (design 258 S7.7, still measured-broken under the
   Julia echo after N1's repair) deserve their own arc; whether N5b's up-to-0.18 bootstrap deltas
   need a same-seed follow-up before being called RNG noise; and the standing fog item from
   `LOOP/ultra-plan.md` -- is "true parity" one-directional (R -> Julia) or two-directional, given
   N2 ported three DRM.jl-only accessors under a relayed "both-ways rule D-204" that was never
   confirmed in Shinichi's own words for drmTMB specifically. Do not re-derive these; ask them.

7. **q4 Wald SEs across engines: an owner decision, not a bug (DRM.jl lane, 02:45 UTC).** DRM.jl #611
    (merged 88493250) established that the all-NaN bridge `vcov()` recorded in the q4 SE-axis receipt is
    the bridge's deliberate default `q4_vcov = false` for bivariate q4 phylogenetic fits
    (`src/bridge.jl:458-464`); native REML and the bridge with `options[["q4_vcov"]] = TRUE` both return
    a finite positive-definite `vcov` agreeing with an independent Hessian to below 1e-5. The seven Wald
    SEs in the `biv-q4-phylo-reml` `[se]` block stay `not_comparable` while the default stands. Three
    ways to make the block comparable, any one of which suffices: flip the bridge default in DRM.jl; add
    a size heuristic there; or have drmTMB pass `q4_vcov = TRUE` when it wants Wald SEs (the R-side
    option, which this lane could take without touching DRM.jl). Which?

## CARRIED-OVER (every branch not on main, why, and the resume command)

| branch | why not landed | resume command |
|---|---|---|
| `claude/lane-true-parity-night` (lane worktree, local commits only, not pushed) | the lane's own working branch; holds `LOOP/` checkpoints plus draft handover/after-task/reconcile not yet promoted to `main` | `cd ~/local-scratch/lanes/drmTMB-true-parity-night && git log --oneline origin/main..HEAD` to see the full commit list; step 4 above lands the docs subset on `main` |
| `claude/n1-label-contract-all-routes` (PR #1124, head `fc4690ea0e6ca5b0ba41b3eba696ae843f638151`) | draft PR, CI was mid-run (`os-matrix` green, `ubuntu-latest (release)` in progress) at last check, not yet merged by the lane | `gh pr view 1124 --json state,statusCheckRollup`; if green, `gh pr merge 1124 --squash` or the lane's usual merge path per D-208 pre-authorisation |
| `claude/night-n2-accessors` (PR #1125, head `762ac950f486acb71b6fd7e61331aa849a40bf35`) | draft PR, CI mid-run at last check (`os-matrix` green), mergeable per `gh pr view` | `gh pr view 1125 --json state,statusCheckRollup,mergeable`; merge when green |
| `claude/night-n3-labels` (PR #1128, head `6def01c6d2538571ef95a7e25dcb0f36a1e40aa0`) | draft PR, CI mid-run at last check (`os-matrix` green) | `gh pr view 1128 --json state,statusCheckRollup`; merge when green |
| `claude/rev-parity-handover` | carries the 2026-09-02 handover docs and decision-map history not yet folded into `main`; predates this lane | `git log origin/main..origin/claude/rev-parity-handover --oneline`; land via a docs PR when convenient, not urgent |
| `claude/rev-parity-drmjl-findings` | the findings memo to the DRM.jl lane (label-map echo contract, fixture re-key, stale `capabilities.md`, q4 REML vcov() note); lives here because it is addressed to a foreign lane, not because it is unfinished | read-only reference; hand its tip to the DRM.jl lane's own session if a fresh finding needs appending, do not merge it into drmTMB `main` |

Everything else under `claude/07-*`, `claude/arc*`, `claude/handover-*`, etc. in this worktree's
local branch list predates this lane and this lane's own AGENTS.md OWNS block did not touch them;
they are out of scope for this handover.

## Fence list (verbatim from LOOP/GOAL.md)

> Any DRM.jl edit; any CRAN/release/registration action; a public claim not backed by a receipt; a
> change that reopens D-179/D-181/D-202/D-204; compute beyond the Totoro cap or beyond an estimate
> without a pre-run; a surprise that invalidates the plan (bring it back to G0 in the morning).

## LANE

`LANE: START A FRESH TASK`

Resume prompt (arc-loop RESUME template):

```
READ FIRST, in order:
1. ~/local-scratch/lanes/drmTMB-true-parity-night/LOOP/GOAL.md
2. ~/local-scratch/lanes/drmTMB-true-parity-night/LOOP/checkpoint.md
3. ~/local-scratch/lanes/drmTMB-true-parity-night/LOOP/arcs.md
4. This handover: ~/local-scratch/lanes/drmTMB-true-parity-night/docs/dev-log/handover/2026-09-03-claude-true-parity-night-handover.md
5. The after-task: ~/local-scratch/lanes/drmTMB-true-parity-night/docs/dev-log/after-task/2026-09-03-true-parity-night.md
6. The reconcile: ~/local-scratch/lanes/drmTMB-true-parity-night/docs/dev-log/plan-actual/2026-09-03-true-parity-night.md

WORKSPACE: ~/local-scratch/lanes/drmTMB-true-parity-night, branch claude/lane-true-parity-night,
launched from origin/main @ 0ceb77eb0. Main checkout for gate-check --root and post-merge work:
/Users/z3437171/Dropbox/Github Local/drmTMB (currently on feat/bridge-lss-reml-row12, do not work
there directly -- create a fresh worktree off origin/main for any new edits).

RUN: `tools/lane_preflight.sh` in the main checkout first. Then `git fetch origin` and
`gh pr list --author @me --state open --repo itchyshin/drmTMB` to see whether #1124/#1125/#1128
moved since this handover was written.

CONTINUE FROM: the six OWED Next Immediate Steps in this handover, in order -- fill merge SHAs,
flip S3-G4, regenerate the tip-identity receipt, land the docs PR, delete merged branches, carry
the morning questions to Shinichi. Steps 1-3 depend on #1124/#1125/#1128 actually merging first;
if they are still open and green, that is itself the first action (merge them per D-208's
pre-authorisation, in the order checkpoint.md records).

PAUSE AT: any DRM.jl edit; any CRAN/release/registration action; a claim not backed by a receipt;
reopening D-179/D-181/D-202/D-204; compute beyond the Totoro cap or beyond an estimate without a
pre-run (D-139); or a surprise that invalidates this plan -- bring it back to Shinichi rather than
improvising past it.
```

## Acceptance ledger receipt (coordinator, 2026-09-03 02:43 UTC)

`.unlazy/night/bin/reverify-all.sh` re-ran every leaf against the worktree holding its code (never the main checkout), with `DRM_JL_PATH` at the pinned DRM.jl clone (77513aa0) and single-threaded BLAS, and wrote `.unlazy/night/reverify-all.result`:

- leaf-n1: ALL MET (12 met, reran 10)
- leaf-n2: ALL MET (11 met, reran 9)
- leaf-n3: ALL MET (5 met, reran 4)
- leaf-n4: ALL MET (5 met, reran 4)
- leaf-n5: ALL MET (4 met, 1 abandoned: N5-G2, Totoro cannot embed Julia; intent met by N5b)
- leaf-n5b: ALL MET (4 met, reran 4)

Pipeline `.unlazy/night/GATES.md`: N1 (every leaf re-verifies) PASS on that receipt; N2 (CI green at every merge) recorded from `merge-log.txt`; N3 (DRM.jl fence) PASS; N4 (docs landed) is met by the merge of the docs PR that carries this file. In `.unlazy/true-parity/`, S3-G4 flipped ABANDONED to MET and S3-G11 was superseded (zero legacy sites, not one), both with dated notes. After the receipt the arc worktrees and merged local branches were removed; re-running the runner needs the worktrees re-created at the merge SHAs listed in the merge log.

## Follow-on arcs N7 and N8 (added after the 03:35 UTC close, inside the mission and envelope)

Both are drmTMB-side bugs found during the night's own work; owner-decision items (#1129, #1130, promotion, `q4_vcov`) stayed in the morning queue. Each landed as a green PR with a ledger written before dispatch and a Rose pass before merge.

- **N8, #1123, PR #1132 merged 208e0c903 (04:43 UTC).** Parametric bootstrap CIs aborted for every binomial fit written as `cbind(successes, failures)` because `response_name_from_model_frame()` returned `model.frame()`'s label `"cbind(s, f)"`, never a data column. `bootstrap_response_data()` now rebuilds both columns from the simulated successes and `trials - successes`, gated on the cbind encoding; Bernoulli and weights paths unchanged. RED test reproduced the exact error on main; a per-row trial-size invariant is tested; Rose's five attacks (other encodings, row alignment, edge rows, alternative spellings, regression) all survived. Ledger leaf-n8 all met.
- **N7, #1127, PR #1133 merged 20b107bf3 (06:50 UTC), after one red CI run.** The first run failed because CI sets `NOT_CRAN=true` and the shared gate never checked for a DRM.jl checkout, so with the swallows gone a Julia fit ran on the runner; the swallows had hidden that on every CI run to date. The one helper now skips with "DRM.jl engine not available (set DRM_JL_PATH)" when the path does not exist, while an existing non-DRM.jl path still fails loudly. All 22 tryCatch-to-skip sites in the live Julia tests removed (a paren-aware oracle counted 21 plus, after Rose, one spelled as a NULL handler followed by `skip_if(is.null(...))`; the issue said 16). One helper resolves the DRM.jl path (`DRM_JL_PATH`, `DRM_JL_PHYLO_PATH` only as a fallback inside it). No assertion removed (Rose's census: identical `expect_` counts across 11 files); a fake DRM.jl directory now yields a test error, not a skip. Removing the swallows exposed four constructs measured broken at DRM.jl 77513aa0, each now a visible skip naming the cause: `resd_sigma` (sigma-side phylo, two sites), `phylocov` at `test-julia-tmb-parity.R:348`, and `resd` for a random-slope phylo block (`test-julia-slope-nongaussian.R`). The first and last are the holes design 258 S7.7 already lists; the `phylocov` site is new and narrower.

**Added morning question 11.** The `coef_labels` producer has three remaining label gaps under DRM.jl's echo: `resd_sigma` (sigma-side phylo), `resd` for random-slope phylo blocks, and `phylocov` for the construct at `test-julia-tmb-parity.R:348`. Extend the producer (one arc, same pattern as N1's repair) or keep them as documented boundaries?

**Oracle lesson of record.** A ledger gate whose file list comes from `git diff --name-only origin/main` breaks as soon as main moves (N8 landed a test file N7 does not have); use `--diff-filter=AM`. And a text oracle for "no swallow" needs the NULL-handler shape as well as the inline `skip()` shape; the widened script is `.unlazy/night/bin/count-skip-swallow.py`.
