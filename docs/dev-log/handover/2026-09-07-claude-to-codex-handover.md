# Handover — Claude → Codex, 2026-09-07 (drmTMB ↔ DRM.jl)

Reader: Codex, picking this up cold. Everything below is measured and re-checkable.
Where something is a lead rather than evidence, it says so.

## RESUME

```
1. Check whether drmTMB PR "promote 5 more routes" merged. If it did, the receipts
   campaign is closed and the next work is §5.
2. Read this file, then docs/dev-log/after-task/ for the campaign record.
3. Codex owns the live toolchain from here: real fits, R CMD check, simulations,
   rendering. See §6 for what that specifically means on this work.
```

## 1. Where the two repos stand

| | |
|---|---|
| drmTMB main | `566a56815` (+ the promotion PR, chained — see §3) |
| DRM.jl main | `6208a52e5` (+ #767, in flight — see §3) |
| capability ledger | `r_bridge_status`: **17 supported · 6 partial · 13 experimental · 1 unsupported** |
| parity-matrix headline | **4 of 45 GREEN — and that is CORRECT, see §4** |

## 2. What the campaign did

The eight capability rows that carried *"do not promote beyond partial without a
G3 receipt"* are **all now `supported`**. `r_bridge_status` went 5 → 17 across the day.

The gate ladder was read from drmTMB PR #1187's own receipt rather than assumed:

- **G3** = "a non-empty ready set, every member profiling to a finite interval" — the
  PROFILE pipeline.
- **G4** = same-target agreement. Bootstrap is scored **`OVERLAP ONLY`, never endpoint
  equality**, because each engine draws its own resamples.

That second point is load-bearing. `tools/parity_intervals.R` still compares bootstrap
endpoints for EQUALITY, which cannot hold, so all 14 bootstrap rows read
`INTERVAL_MISMATCH` even though 5 of 5 measured pairs OVERLAP. **Do not "fix" those
rows by loosening the tolerance** — the test asks the wrong question. A written patch
replacing it with an overlap test exists (§5.1).

## 3. IN FLIGHT when this was written

- **DRM.jl #767** — the SkewNormal simulate fix + 4 interval cells + regenerated
  receipts. Gate armed, merges itself on green.
- **drmTMB `claude/parity-g3-promote-5`** — committed at `6663a8aeb`, NOT yet pushed.
  A chained script holds it:
  `~/local-scratch/parity-joint/land-promote5.sh` → wait for #767 to merge → verify its
  content is on DRM.jl main by grep → **regenerate the tip-identity receipt at the new
  pin** → push. It REFUSES at any step that fails. If it exited non-zero, read
  `land-promote5.log` before doing anything by hand.

## 4. The one thing not to over-read

The campaign moved the **evidence** axis (`r_bridge_status`), not the **governance**
axis (`claim_status`). No row's `claim_status` changed, and the parity-matrix headline
still reads 4 GREEN **correctly** — GREEN keys on `claim_status`.

Design 168 wants four limbs before a row is `covered`: implementation, focused tests,
public documentation, interval evidence. This work supplied the **first and fourth**.
Promoting the governance axis is the owner's call, not a lane's.

## 5. What remains, in rough value order

1. **The bootstrap overlap patch + the capability_id join.** Two halves, and NEITHER
   works alone — this is the part most likely to be got wrong:
   - DRM.jl: `parity-intervals.tsv` has no `capability_id` column.
   - drmTMB: `tools/write-parity-scoreboard.R:131` `sb_receipt_tables()` omits
     `"intervals"` — **and adding it alone is a literal no-op**, because the consumer
     guards at `:183` with `if (is.null(tab) || !"capability_id" %in% names(tab)) next`,
     and again at `:222`. It fails SILENTLY. Both halves are required.
   Until both land, these receipts stay UNCITED no matter how many are banked.
2. **The 6 remaining `partial` rows**, each blocked differently:
   - `fe_beta_binomial` — native **TMB** produced no bootstrap interval, so overlap
     (which needs two) is *unscoreable*, not failing.
   - `fe_biv_lognormal` — no bootstrap on the **Julia** engine.
   - `fe_biv_student` — **neither** engine returns an endpoint; a gate aborts in 0 s
     even with an explicit `parm`, so it is NOT the parm-convention gap #765 fixed.
     Filed as **DRM.jl #766**.
   - `fe_cumulative_logit` — waits on drmTMB #1195 (merged; re-verify then re-measure).
   - `hurdle_nbinom2` — three self-described non-blocking follow-ups.
   - `accessor_model_comparison` — **owner decision**: export a boundary-aware LRT verb,
     or record the no-anova-LRT refusal as permanent.
3. **`source-pins.json` is stale** at `430ef64cc` (two byte-identical copies: committed
   under `docs/dev-log/loop/parity-joint-20260905/` and in the lane kit). Updating it
   needs a decision nobody should make alone: should `drmjl_base` be main's tip, or the
   pin the standing receipt was actually measured at?
4. **~18 worktrees** under `~/local-scratch/parity-rerun/` and `parity-joint/`. Inventory
   before removing: some hold uncommitted work, and `git worktree remove` exceeded two
   minutes on this filesystem.
5. **drmTMB #1150 is an owner decision**, not a task: `receipt-staleness` exists but is
   push-to-main only, so "a stale receipt merges green" still happens by deliberate choice.

## 6. Codex-specific: what the live toolchain must respect

- **Bridge work is LOCAL ONLY.** Totoro's R segfaults embedding JuliaCall (measured,
  ABANDONED receipt). Native-R and native-Julia suites can go to Totoro; anything
  `engine = "julia"` cannot.
- **`Manifest.toml` is gitignored.** A fresh DRM.jl worktree CANNOT instantiate — every
  fit dies with `ForwardDiff ... Run Pkg.instantiate()`. Copy it from a working clone
  before the first fit. Four agents lost a run to this in one day.
- **Verify the installed drmTMB before believing a refusal.** A build 273 commits stale
  silently refuses every family added since 0.7.0, and the refusal is indistinguishable
  from an engine limit. Check `packageDescription("drmTMB")$Version` (expect 0.7.1) and
  that your family is in `drmTMB:::drm_julia_family_registry()` (17 entries).
- A noisy `UndefVarError: loglogistic` / `LogExpFunctionsInverseFunctionsExt` line at
  Julia boot is **measured non-fatal**. Only treat a cell as failed if that cell produced
  no numbers.
- The R fitting function is **`drmTMB()`**; `drm()` is the Julia-side name.

## 7. Do not repeat — the expensive ones

1. **Verify CONTENT, never merge status.** Resolving a conflict "to main" silently
   dropped four functions this week while leaving their call sites standing. Every merge
   here now runs a definition-level diff against both parents.
2. **`git push origin <branch>` from a DETACHED HEAD pushes the branch ref, not your
   work, and exits 0.** Use `push origin HEAD:refs/heads/<branch>`.
3. **`gh pr merge --auto` fails open** where auto-merge is disabled: it merges
   immediately and reports success. Use `tools/pr_merge_when_green.sh`, then confirm
   `mergedAt`.
4. **Regenerate the tip-identity receipt LAST.** It hashes every `R/*.R` plus 95
   DRM.jl-side files. `receipt-staleness` went red on main three times on 2026-09-07
   purely because three PRs touched `R/julia-bridge.R` in succession.
5. **A generator is the only correct oracle for a generated table.** Never hand-edit
   `inst/extdata/*.tsv` or `docs/design/parity-*.md`.
6. **Never read a main checkout's working tree as source truth** — `git show
   origin/main:<path>`. ~30 worktrees share that checkout. And never `git stash` here:
   one shared stash stack spans all of them.
7. **A green suite that never called Julia is not parity evidence.** The source-tree lane
   prints ~24500 PASS and, in the same trailer, *"the LIVE ENGINE was not exercised in
   this configuration."*
8. **A grep miss is not proof of absence.** This codebase writes cells both as
   `list(id = "x"` on one line and split across two, and ids vary in case. Four confident
   wrong findings on 2026-09-07 came from naive greps — including a near-miss claim that
   31 receipts were unreproducible, which was flatly untrue.
