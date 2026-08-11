# Handover → Claude — missing-data lane (2026-08-10)

You are Claude, picking up the **missing-data / G4-G5 lane**. You inherit no chat context; this
document and the repository are authoritative.

> **MULTI-LANE.** Four lanes are live (missing-data, MSPL, emmy, Codex/CRAN). This document covers
> **only the missing-data lane**. For the others read
> [`docs/dev-log/coordination-board.md`](../coordination-board.md) — do not assume this handover is a
> project census, and do not repoint the board's other lanes at it.
>
> **The board's Claude row is deliberately NOT updated to point here.** `cursor/handover-0807` has
> three unmerged commits rewriting that exact `## Active Lane Split` block (new Cursor row, rewritten
> Codex and Claude rows). Editing it from `main` would have forked the same block and handed that lane
> a conflict. **After Cursor's restructuring merges, someone should add this handover to the Claude
> row** — one line, pointing at this file. Until then, this document is the missing-data lane's
> authoritative pointer and is reachable from `docs/dev-log/handover/`.

> **⚠ A RELEASE FREEZE MAY STILL BE ACTIVE.** A 0.7.0 tarball freeze was requested around 18:00 on
> 2026-08-10: hold merges to `main` that touch `R/`, `src/`, `NAMESPACE`, `DESCRIPTION`, `tests/`,
> `man/`, `vignettes/`. Docs-only merges are fine. **Check with the owner before merging any code PR.**
> Whatever is on `main` at the freeze is 0.7.0; anything after is 0.7.1.

---

## Mission

Close out drmTMB's missing-data subsystem: bring it under G0–G5 evidence discipline, make its
uncertainty machine-readable, and produce a G5 campaign whose evidence can actually support promoting
`missing_response` rows off G3.

## What was accomplished

**Three PRs merged to `main`:**

| PR | Merge | What |
|---|---|---|
| [#972](https://github.com/itchyshin/drmTMB/pull/972) | `fddb82105` | `missing_predictor` ledger axis (17 rows); `imputed()` route-conditional SEs — **12 of 13 routes now populated**, previously Gaussian only; G4/G5 runner runs 18/18 routes under `library()` (was 16/18); v1/v2 centring switch; #971 retained-failure fix |
| [#985](https://github.com/itchyshin/drmTMB/pull/985) | `8a104a706` | **Design provenance (#982)** — every record stamped with its DGP at generation time; reconcilers hard-error on disagreeing designs, taint-and-warn on missing ones; committed compute paths require an explicit declaration |
| [#989](https://github.com/itchyshin/drmTMB/pull/989) | `2b310d0c2` | **#980 + #981** — `skew_normal` and `student` DGPs fixed; two `truth` constants corrected; three guards added |

**Twelve issues filed:** #962–#971 (the drmSEM upstream ask-set, corrected — six of nine had drifted
line references), #979, #980, #981, #982.

**Four defects found, all invisible to the calibration policy.** This is the durable finding of the
lane: the gate checks denominator completeness, interval availability and MCSE — **none of which can
see a DGP that fails to vary correctly, or a truth constant on the wrong scale.**

1. **Intercept centring.** `u <- u - mean(u)` removed the sampling variability of the group mean, so
   `fixef:mu:(Intercept)` coverage pinned at 1.000. Controlled test, 300 attempts/arm, identical
   seeds: centred **1.0000** vs uncentred **0.9533** (MCSE 0.0122).
2. **`skew_normal`'s DGP was frozen.** Response built from deterministic quantile grids —
   `max|y_a − y_b| = 0` across seeds 111 and 999999, vs 5.256 for gaussian. Only the mask varied, so
   its 15 cells measured sensitivity-to-masking on one realisation, not coverage. Failed 15/15 while
   passing every procedural check.
3. **`student` permuted a fixed quantile multiset.** Subtler: the response *does* vary, so a
   does-it-change test passes. The standardized-residual multiset is frozen, making the profile
   likelihood in `(sigma, nu)` permutation-invariant. Explains its 4/15.
4. **Two `truth` constants on the wrong scale** — tweedie `nu` (response vs link), cumulative_logit
   cutpoint 2 (cumulative value vs log-increment).

## Current working state

**COMPLETE — the authenticated campaign (rorqual array `18777800`).** Finished and reconciled
2026-08-10 20:52. Artifact: `rorqual:~/g5run/g5-reconciled-final.rds`.

**It authenticates itself, which is the whole point of the run:**

```
design_state: centre_random_effects=FALSE
UNAUTHENTICATED rows: 0 / 348,000
```

That is precisely what withheld promotion at the first panel. Noether's objection is now answered by
the artifact rather than by inference from its own results.

**Outcome: 247 pass / 43 fail of 290 reconciled cells** (previous campaign: 236/294).
Failure modes: `unusable_interval` **42** · `coverage_outside_policy_band` **1**.

**Nine routes pass every cell** (was eight): `biv_gaussian` (39), `zero_one_beta` (24),
`zi_poisson` (18), `gaussian` (15), `gamma` (15), `beta_binomial` (15), **`lognormal` (15)**,
`binomial` (6), `cumulative_logit` (3).

Per-route (fail, pass): beta 3/8 · beta_binomial 0/15 · binomial 0/6 · biv_gaussian 0/39 ·
cumulative_logit 0/3 · gamma 0/15 · gaussian 0/15 · hurdle_nbinom2 1/23 · lognormal 0/15 ·
nbinom2 6/9 · poisson 2/7 · skew_normal 3/12 · **student 15/1** · truncated_nbinom2 6/5 ·
tweedie 1/14 · zero_one_beta 0/24 · zi_nbinom2 6/18 · zi_poisson 0/18.

**Two predictions were made in advance. One held; one did not — read this before trusting the
student numbers.**

- **`skew_normal` — CONFIRMED.** Intercepts moved from **1.0000 / 1.0000 / 0.9992** to
  **0.9483 / 0.9583 / 0.9425**; the route went 0/15 → **12/15**. The frozen DGP was the problem.
- **`student` — PREDICTION WRONG.** I predicted substantial improvement from 4/15; it went to
  **1/15, worse.** The *diagnosis* was right — its intercept coverages are now
  **0.9350 / 0.9283 / 0.9400**, all in band, and it fails on `unusable_interval`, not on coverage.
  Permuting a fixed quantile multiset was **artificially stabilising the fits**; real `rt()` draws
  produce genuine heavy-tailed outliers, some profile intervals fail, and the all-1,200-usable rule
  fails the cell. **Better statistics, worse pass rate.** Do not read student's 1/15 as a regression.

**This reframes the remaining work.** 42 of 43 failures are *interval availability*, not calibration.
The open question is no longer "does drmTMB cover correctly" but "can the profile machinery produce an
interval on all 1,200 draws" — i.e. the availability-vs-coverage reporting split raised in #965, now
decidable on evidence.

**⚠ 290 of 294 cells reconciled — FOUR ARE MISSING.** Identify them before the panel: the previous
panel's single blocking objection (raised independently by two reviewers) was exactly an incomplete
admission set. If any missing cell belongs to one of the nine clean routes, that route's "passes every
cell" claim is not exhaustive.
```bash
ssh rorqual 'module load StdEnv/2023 r-bundle-bioconductor/3.21; export R_LIBS_USER=$HOME/R/g4g5-lib; \
  Rscript -e "reg <- readRDS(path.expand(\"~/g5run/registry.rds\")); \
    f <- list.files(path.expand(\"~/g5run/g5\"), \"[.]rds$\", full.names=TRUE); \
    n <- vapply(f, function(p) tryCatch(nrow(readRDS(p)), error=function(e) 0L), integer(1)); \
    have <- vapply(f[n>=1200], function(p){x<-readRDS(p); paste(x\$route_id[1],x\$parm[1],x\$information_rung[1])}, character(1)); \
    want <- paste(reg\$cells\$route_id, reg\$cells\$parm, reg\$cells\$information_rung); \
    print(setdiff(want, have))"'
```

What makes it different from the three earlier runs:

| | Earlier runs | This run |
|---|---|---|
| Design provenance | none — inferrable only from results | **stamped on every record** |
| `skew_normal` / `student` | frozen / permuted DGPs | real `rnorm` / `rt` draws |
| tweedie `nu`, cutpoint 2 truths | wrong scale | corrected |
| G4 construction | 54 fixtures, route-default seeds | **306 independent fixtures, registry seeds** |
| Engine | drmTMB 0.6.0, predating every fix | built from current `main` |

**BLOCKED — `claude/mi-response-leaves`** (Gamma + lognormal `mi()` support). Green: full suite 0
failures, known-DGP recovery passing for both. Blocked *only* by the C17 guard (#979), not by quality.

**DONE and merged** — everything in the table above.

## Landing state ledger

| Item | State | Detail |
|---|---|---|
| #972, #985, #989 | **LANDED** | merged to `main` |
| `claude/mi-response-leaves` @ `01179d89c` | **CARRIED-OVER** | pushed, 2 commits, not merged. Blocked on #979. Resume: see Next Steps. |
| rorqual array `18777800` | **DONE** | complete + reconciled; `rorqual:~/g5run/g5-reconciled-final.rds`; 247 pass / 43 fail of 290. **4 cells unreconciled — identify before the panel.** |
| D-43 panel | **OWED** | must run on the reconciled artifact before any promotion |
| Stale `.git/index.lock` (Aug 5) | **REPORT ONLY** | pre-existing, not mine. Do **not** remove — the harness blocks `.git` deletions. Flag to the owner. |
| Other lanes' unpushed branches | **NOT MINE** | `codex/*`, `hopper/*`, `shannon-install` — the handoff gate flags these; they belong to other lanes |

All my worktrees are clean; all my branches are pushed (local == remote).

## Key decisions & rationale

- **Promotion was WITHHELD** at the first D-43 panel (Fisher PROMOTE-WITH-CAVEATS, Rose
  PROMOTE-WITH-CAVEATS, **Noether WITHHOLD**). By the letter one dissent doesn't block; I withheld
  anyway because the panel brief said in advance that *an estimand dissent outweighs two procedural
  passes*, and Noether's objection checked out on all three counts. **No `missing_response` row has
  moved off G3.**
- **Missing provenance taints rather than blocks.** In #985 I first made a missing `design_state` a
  hard error, then reversed it: refusing to read pre-stamp records destroys access to computed
  evidence rather than protecting anything. Disagreeing designs stay a hard error.
- **`student` was refused for `mi()` support.** Its density needs a per-row shape `nu` the shared
  six-argument leaf can't carry; widening the signature would change every caller. Stopping was
  correct, not a shortfall.
- **The response-family gate was NOT widened** (#962). `src/drmTMB.cpp` has no `has_mi`/`mi_family`
  wiring for Gamma, lognormal, student, beta_binomial or the zi-* responses. The gate already
  describes the implemented surface; admitting a family whose likelihood can't integrate the missing
  predictor would be strictly worse.

## Files created / modified

Merged to `main` via #972 / #985 / #989:

```
R/missing-data.R                                   inst/sim/R/sim_missing_response_g4g5.R
R/methods.R (read-only check; unchanged)           man/imputed.Rd
man/drm_grid_posterior_sd.Rd                       man/drm_imputed_route_conditional_sd.Rd
man/drm_imputed_uncertainty_status.Rd              tools/capability_ledger.py
tools/mr-g5-drac-array.R                           tools/mr-g5-drac-route-array.R
tools/mr-g5-drac-*.sbatch  (5 files)               vignettes/includes/capability-ledger-summary.md
docs/dev-log/dashboard/capability-ledger/{cells,evidence}.tsv, schema.json
docs/dev-log/dashboard/capability-surface.{html,md}
docs/dev-log/after-task/2026-08-09-missing-data-capability-drmsem-part-b.md
tests/testthat/test-missing-response-g4g5-foundation.R
tests/testthat/test-missing-data-robustness.R
tests/testthat/test-missing-predictor-{beta-binomial,binary,categorical}.R
```

On `claude/mi-response-leaves` (**not merged**): `R/drmTMB.R`, `R/missing-data.R`,
`src/drmTMB.cpp`, `src/drm_response_kernels.h`,
`tests/testthat/test-missing-predictor-{gamma,lognormal}-response.R`,
`tests/testthat/test-missing-data-capability-gate.R`,
`vignettes/includes/capability-ledger-family-map.md`.

## Next immediate steps (OWED)

1. **~~Finish the campaign and reconcile.~~ DONE** — see Current Working State. The artifact is
   authenticated (0 UNAUTHENTICATED of 348,000 records). **First: identify the 4 unreconciled cells**
   using the command in that section, and check whether any belongs to the nine clean routes.

2. **Run a fresh D-43 panel** on the reconciled artifact. Brief:
   `scratchpad/d43-panel-brief.md` (session-local; its content is reproduced in the after-task report).
   **Dispatch by TOOL SET, not persona label** — see Gotchas. Reviewers need `Bash` + `Write`.
   Carry forward: Fisher's rung-level granularity (promote rungs, never routes); Rose's boundary
   wording (25% MCAR, ML only, profile intervals only, excluding MAR/MNAR and REML); and the fact that
   Noether's objection is now *directly answerable* because records carry their design.

3. **~~Two predictions to falsify.~~ RESOLVED — `skew_normal` confirmed, `student` prediction WRONG.**
   Details in Current Working State. Carry the correction into the panel brief: student's 1/15 is an
   interval-availability effect on now-correct statistics, not a regression, and its coverage is in
   band at every rung.

4. **Then promote**, if earned. The prior panel converged on 7 routes: `gaussian`, `biv_gaussian`,
   `gamma`, `beta_binomial`, `binomial`, `zero_one_beta`, `zi_poisson`.

5. **#979** — decide the C17 granularity question, then merge `claude/mi-response-leaves`. Note
   [#991](https://github.com/itchyshin/drmTMB/pull/991) may already resolve this from another angle.

## Blockers / open questions

- **#979** (C17 whole-file blob pin) blocks `claude/mi-response-leaves` and, per the MSPL lane, four
  other PRs. Every remedy except re-certifying on every touch weakens a guard — **owner's call.**
- **#967** — ordinal cutpoint profile intervals. Interacts with #981: fix the intervals without fixing
  the truth constant and those six cells will read as an engine bug when they are a truth-table bug.
- **MD7f summation is barely exercised** (raised by the MSPL lane, accepted as this lane's call). The
  17 `test-missing-predictor-*` fixtures share a deterministic no-noise pattern, giving 1.0–1.8
  effective support points out of 9–17. `rowSums(probs) == 1` therefore certifies arithmetic, not the
  marginalisation. Adding residual noise of order `1.15/n_i` would make it a real test. **Same failure
  class as #980** — the check passes because the thing it checks was never exercised.

## Gotchas / failed approaches

- **I dispatched a read-only reviewer to an implementation task TWICE**, the second time on the very
  next dispatch after writing a brain note about it. `math_consistency_reviewer`, `systems_auditor`,
  `inference_reviewer` etc. are `Read/Grep/Glob` (± `Bash`) by construction and **cannot Write**.
  **Select agents by tool set; put the lens in the brief.**
- **`git stash` is not a reliable "was this pre-existing?" check.** A sub-agent used it and reported
  ledger errors as pre-existing; they weren't. Use a detached worktree at `origin/main`.
- **RDS hashes are not portable across R versions.** A trivial `list(a=1:3, b=c(x=0.5))` hashes
  differently under R 4.6.0 and R 4.5.0. I spent a cycle literalising transcendental truths to "fix"
  this before testing the actual hypothesis; the literalisation was discarded. **Manifest-hash
  comparison is only valid within one R version — use `design_state` (#982) for provenance instead.**
  This also corrects an earlier claim of mine that the G4 machinery is "bit-reproducible across
  architectures"; the match that prompted it was same-R-version.
- **Never swap a derived registry under a running campaign.** `mr_g4g5_seed_table()` assigns seeds by
  cell *index*, so changing the cell set renumbers every cell and changes every seed. I did this and
  reconciliation caught it (`"G5 records must retain the deterministic seed"`); reverted, no compute lost.
- **`pkill -f <pattern>` matches its own command line.** Use `[p]attern`. Also: a driver's `bash -c …
  nohup` wrapper outlives its R process, so guard on the R process (`[e]xec/R.*driver`).
- **Never stage from the primary checkout** on `claude/handover-freshness-0718` — it is dirty with
  another session's work (coordination board rule).

## Environment

- Repo: `/Users/z3437171/Dropbox/Github Local/drmTMB` (primary checkout is **dirty** — use a worktree).
- R: `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the `.Rprofile` R-4.5 lib segfaults R 4.6).
- Verify: `devtools::test()` · `rcmdcheck::rcmdcheck(args = "--as-cran")` ·
  `python3 tools/capability_ledger.py --write` then `--check` · `python3 -m unittest tools/tests/test_capability_ledger.py`
- Compute: **rorqual** (`~/g5run`), R 4.5.0, `module load StdEnv/2023 r-bundle-bioconductor/3.21`,
  `export R_LIBS_USER=$HOME/R/g4g5-lib`, account `def-snakagaw_cpu`. drmTMB there is built from current
  `main`. ControlMaster sockets are live for all DRAC clusters — no Duo needed.
- **Do not stage:** `.git/index.lock`, other lanes' branches, `docs/dev-log/check-log.md` line ~92693
  (a committed `=======` conflict marker another lane is fixing in consolidation).

## Mission control

| Repo | Branch / main | CI | What shipped | Plan by leverage |
|---|---|---|---|---|
| drmTMB | `main` @ `60459cfaa` | 0.7.0 freeze requested | ledger axis · `imputed()` SEs 12/13 · design provenance · 4 DGP/truth defects fixed · 3 guards | (1) reconcile + D-43 → promotion · (2) #979 → merge `mi-response-leaves` · (3) #967 · (4) MD7f fixture noise |
| Evidence | array `18777800` | **complete, 0 errors** | first **authenticated** campaign — 247/43 of 290, 0 UNAUTHENTICATED | identify 4 missing cells → D-43 panel → promote (9 routes now clean) |

## How to resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-10-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Classify each handover item `OWED` / `DONE` / `RETRACTED` / `PROTECTED` against the live repo before
acting — `main` moves fast here (it advanced ~6 merges during this session alone).
