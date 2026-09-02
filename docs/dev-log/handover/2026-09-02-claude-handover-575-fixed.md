# Session Handoff: R–Julia parity arc — #575 FIXED, promotion wave gated on reviews

Meta: written 2026-09-02 early morning (the session ran 2026-09-01 evening → 2026-09-02 05:0x MDT; all "2026-09-01" dates in filenames/receipts below are the working date and are correct as written) · from Claude (Fable) · target **Claude (Fable 5.1)** · working
directory `/private/tmp/drmtmb-control-audit` (drmTMB worktree, branch
`codex/rebase-julia-optimizer-controls`) + the DRM.jl checkout at
`/Users/z3437171/Dropbox/Github Local/DRM.jl`.

> You are Claude, picking up the drmTMB↔DRM.jl true-parity programme. You inherit **no chat
> context**. This document plus the repo is the record. Predecessor handover (inbound, from Codex):
> `docs/dev-log/handover/2026-09-01-claude-handover.md` — its OWED items are all now DONE or
> RETRACTED; see Landing State.

## Critical Context

The programme objective is unchanged: make every implemented native-R workflow available in direct
Julia **and** through `engine = "julia"`, with retained parity, inference, performance, and
documentation evidence, under gates G0–G8 (currently G2/G3). The session that just ended closed a
long arc whose headline was **DRM.jl#575** — the q4 bridge route landing at an apparently inferior
optimum (Δ logLik ≈ 1.6e-2).

**#575 is fixed.** The cause was *finite-difference gradient noise*, not the "basin-dependence" the
mid-arc reports (correctly, on the evidence then available) concluded. The q4 REML mode-finder
certified convergence on an FD gradient whose noise floor (~1e-3) sat at `g_tol`. Replacing it with
an **exact REML gradient** collapsed the gap. Two intermediate fix attempts were measured and
**honestly reverted** rather than shipped against the convergence contract — that history is
retained deliberately; do not re-run those strategies.

**Nothing is merged and nothing is promoted.** Three review gates belong to Shinichi.

## What Was Accomplished

1. **Arc-1 (earlier same day):** Rose's R1–R6 pre-publish repairs applied to the capability ledger
   and Ayumi drafts; matched-control q4 fixture receipts; Ayumi's exact 343-tip recipe located
   (deterministic — `R/51_batch_clade_revised_spec.R` in her repo, tree-tips ∩ non-missing
   lightness, no seed); the GLLVM.jl-style parity scoreboard page (DRM.jl PR #576, draft); the
   frozen-manifest programme re-estimate (~92–159 agent-h, replacing the un-receipted 157–297,
   with a G5 Totoro pre-run design).
2. **#575 diagnosis chain:** mechanism probe (mode-finder, not objective translation) → plateau
   report (polish/multistart insufficient; #484 convergence contract violated) → basin-selection
   attempt (K=5 starts incl. structured Λ0; plateaued again) → **exact REML gradient (the fix)**.
3. **The fix (DRM.jl PR #579, DRAFT, `closes #575`):** derivation-first. The REML objective
   collapses to −J(ẑ;φ) − ½logdet𝓗 + ½logdetP over the augmented state, so the ML path's exact
   O(p) machinery transfers with `Vblk → Ω_i = Vsel_blk + G_i S⁻¹ G_iᵀ`, never factorising 𝓗.
   Exact-vs-central-difference **≤6.2e-8** relative at three points (each certified ‖∇_z J‖<1e-8).
   Cold-start public route **−219.614005** converged (g_residual 9.5e-5); warm-at-φ_TMB
   −219.614006; drmTMB −219.613986. Full suite **9203 pass / 0 fail / 0 error / 1 pre-existing
   Broken**, with both new tests wired into `runtests.jl`.
4. **Independent bridge re-measure (P1.4):** `ll_delta 1.92e-05`, `max_coef_delta 1.68e-04`,
   both engines converged — inside the fixture's **pre-recorded** tolerance (atol_loglik 0.03,
   atol_coef 0.0251). **GATE-PASS on the coefficient and log-likelihood axes only.**
5. **Two verification panels (both adversarial, fresh agents):** Rose V2 on the plateau close
   (7/8 hold, 1 demote applied) and the **D-43 completion panel** on the fix — returned
   NOT-CONFIRMED with two real blockers, both since fixed: the new tests were **orphans** not in
   `runtests.jl`, and the ledger had acquired an over-eager "promotion-ready" phrase. Public
   surfaces were only updated after those repairs.
6. **Follow-ups filed rather than silently carried:** DRM.jl **#577** (the same `prior_precision`
   structural-zero degeneracy is still unguarded on the ML path — pre-fix lc-gradient errors up to
   13.70 at diagonal Λ) and **#578** (`_reml_border_blocks` mask-consistency change is untested for
   missing responses). Also receipted on **#467**: the gated formula-construct suite reads **1 pass
   / 6 fail on origin/main** (coefficient-NAME mismatches: I(), factor, poly, poly-cross, power,
   scale) — pre-existing, invisible to CI because the suite is gated, and it is exactly Ayumi's
   limitation #4.

## Current Working State

- **Working / landed:** everything above, committed and pushed. All branch pushes verified by
  `git ls-remote` (not ahead/behind counts — a Rose method note worth keeping).
- **In progress:** nothing is mid-run. No background agents, workflows, or compute remain.
- **Blocked only on human review** (see Next Immediate Steps).
- **PROTECTED — do not touch:** the ~11 other live lanes (`codex/*`, `cursor/*`, `tmp/rebase-*`,
  `hopper/*`), their worktrees and stashes. The handoff gate reports many unpushed foreign branches;
  they are **outside this lane** and are declared here rather than landed.

## Key Decisions and Rationale

- **Reverted twice rather than ship a better objective that fails the gradient contract.** The
  basin-selection winner had `g_residual 2.6e-3 > g_tol 1e-3` and regressed #484; a "better number,
  broken contract" trade was refused. This is why the fix ended up being the right one.
- **Promotion is receipt-gated, and q4 did not qualify.** The wave-1 bar is coef **+ SE** + logLik;
  the v3 re-measure computed `coef()` only, and the row's own coverage evidence (phylocov diagonal
  0.974 vs off-diagonal 0.876; L43 0.827; L44 1.000) independently blocks a status move. The
  ledger's `next_action` now says so explicitly.
- **No speed claim.** Warm Julia ran 0.876 s vs TMB 0.928 s on one fixture in a tree with
  concurrent sessions — an observation, fenced as "not a controlled measurement".
- **No public reply to Ayumi.** The 205 readiness gate holds; drafts are on disk, unsent.

## Files Created / Modified

drmTMB lane branch `codex/rebase-julia-optimizer-controls` (21 commits ahead of origin/main;
40 files; the session's own additions listed):
- `docs/dev-log/ayumi-drafts/2026-09-01-issue-28-reply-draft.md`, `…-issue-29-reply-draft.md`
- `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/` — `receipt.md`,
  `a1a2-summary.md`, `a2-delta-diagnosis.md`, `575-mechanism.md`, `p12a-summary.md`,
  `p12a-basin-summary.md`, `p12a-basin-progress.md`, `exact-grad-summary.md`,
  `exact-grad-progress.md`, `p14-remeasure.md`, `q4-fixture-bridge-parity-v2.R`, `…-v3.R`,
  `q4-fixture-v2-result.txt`, `q4-fixture-v3-result.txt`, `warmstart_575.jl`
- `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-rose-verdict.md`,
  `objective-at-bridge-note.md`
- `docs/dev-log/plan/2026-09-01-parity-programme-estimate.md`,
  `…/2026-09-01-bridge-promotion-wave1.md`
- `docs/dev-log/plan-actual/2026-09-01-parity-arc.md`, `…/2026-09-01-arc-p1.md`
- `docs/dev-log/loop/GOAL-arc-p1.md`, `docs/dev-log/coordination-board.md`
- `docs/dev-log/handover/2026-09-01-claude-reverse-parity-brief.md`, **this file**
- `inst/extdata/julia-capabilities.tsv` + `docs/dev-log/dashboard/julia-capabilities.tsv`
  (R1–R3 repairs; q4 `next_action` requalified)

DRM.jl branches (all pushed; verified by `ls-remote`):
- `feat/575-exact-reml-gradient` @ `c1773e21` → **PR #579 (draft)** — the fix + derivation note +
  wired tests
- `feat/575-objective-at` @ `dc3ce190` — `reml_objective_at` diagnostic primitive (TDD), no PR yet
- `fix/575-q4-optimum` @ `f33dfb69` — the RED test + `@test_broken` pin from the plateau phase
  (superseded by #579; keep for history or close)
- `docs/drmtmb-parity-scoreboard` @ `9306c669` → **PR #576 (draft)** — `docs/src/drmtmb-parity.md`

Outside the repos: the "Parity Standing" artifact
(`https://claude.ai/code/artifact/cabc9c81-95fe-4d0a-8b49-6bfd5943f57b`, last label
`575-fixed-panel-verified`) and Mission Control `live/status/drmTMB.json` (committed in the vault).

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
|---|---:|---:|---|---|
| drmTMB `codex/rebase-julia-optimizer-controls` | yes | yes (`c69a348c`) | [#1112](https://github.com/itchyshin/drmTMB/pull/1112) | LANDED on branch; **merge is Shinichi's** |
| DRM.jl `feat/575-exact-reml-gradient` | yes | yes (`c1773e21`) | [#579](https://github.com/itchyshin/DRM.jl/pull/579) draft | LANDED on branch; src/ change → maintainer approval |
| DRM.jl `docs/drmtmb-parity-scoreboard` | yes | yes (`9306c669`) | [#576](https://github.com/itchyshin/DRM.jl/pull/576) draft | LANDED on branch |
| DRM.jl `feat/575-objective-at` | yes | yes (`dc3ce190`) | none | CARRIED-OVER: diagnostic primitive; open a PR or fold into #579 |
| DRM.jl `fix/575-q4-optimum` | yes | yes (`f33dfb69`) | none | CARRIED-OVER: superseded by #579; keep as history or close |
| Foreign branches (`cursor/*`, `tmp/rebase-*`, `hopper/*`, `shannon-install`) | — | no | — | **PROTECTED / out-of-lane** — pre-existing, not this session's; do not land, clean, or rebase |
| Ayumi reply drafts | yes | yes | — | CARRIED-OVER **by design**: unsent; 205 gate requires Shinichi's explicit approval |

FINDING-OF-RECORD: a finite-difference gradient whose noise floor sits at `g_tol` can fake
non-convexity — #575's "basin-dependence" was FD noise, and the exact REML gradient removes it;
plus the two corollaries (structural-zero sparsity can silently break an exact gradient; a better
objective that violates the convergence contract must be reverted, not shipped).
vault-note: [[A finite-difference gradient can fake a non-convex surface — the DRM.jl q4 REML case]]

Repo-side companions to that note: DRM.jl#577 (ML path still exposed to the structural-zero
degeneracy), DRM.jl#578 (untested missing-response mask consistency), DRM.jl#467 (the gated bridge
formula-construct suite is 1/7 on main and CI never runs it). Receipts for all of the above are in
`…/2026-09-01-matched-q4/`.

## Next Immediate Steps (all OWED; the first three are Shinichi's, not yours)

1. **Rehydrate:** run `~/shinichi-brain/tools/lane_preflight.sh .` in the drmTMB worktree, read
   this doc + `AGENTS.md` + `docs/dev-log/coordination-board.md` (Active-Lane-Split), and classify
   every item above `OWED / DONE / RETRACTED / PROTECTED` against the live git state.
2. **Await/expedite three reviews** (do not merge them yourself): drmTMB **#1112**, DRM.jl **#579**,
   DRM.jl **#576**.
3. **When #1112 merges → execute promotion wave 1** exactly as prepared in
   `docs/dev-log/plan/2026-09-01-bridge-promotion-wave1.md`: 4 receipt-verified rows
   (`base_gaussian_location_scale`, `biv_gaussian_residual`, `plain_binomial_nonphylo`,
   `gaussian_response_mask`) `experimental → partial` on the **bridge axis only**, each citing its
   receipt, on a fresh branch, Rose forbidden-claim scan on the diff, DRAFT PR. **q4 stays out**
   until a same-target SE receipt exists.
4. **Optional next engineering slice — the SE-axis receipt:** extend the v3 bridge script to
   compare `vcov()`/SEs on the same draw (the v2/v3 scripts and `tools/parity_se.R` are the
   pattern). That is the one measurement standing between q4 and a later promotion wave.
5. **Housekeeping when convenient:** amend the fixture's `expected.toml` tolerance rationale if a
   drmTMB Wald-SE refit is ever run (a dated CORRECTION already withdraws the stale FD
   justification); decide the fate of `feat/575-objective-at` and `fix/575-q4-optimum`.

## Plans / Roadmap Beyond This Slice

Gates G0–G8 stand (G0 scope · G1 recovery · G2 functional parity · G3 numerical/inference · G4
parallel correctness · G5 matched warm-workflow performance · G6 documentation · G7 integration ·
G8 reconciliation). Costed arc sequence and the **G5 pre-run design** (Totoro, never GitHub
Actions — D-50) are in `docs/dev-log/plan/2026-09-01-parity-programme-estimate.md`. Re-estimate
~92–159 agent-hours. DEFERRED and fenced: P2 profile/bootstrap qualification; the G5 campaign
(needs a D-139 estimate + pre-run + approval); releases and registration (D-164 CRAN hold; D-183
registration at v0.7.1).

## Blockers / Open Questions

- Three PRs need Shinichi's review; nothing technical blocks them.
- The SE axis for q4 is unmeasured — the only gap between the current receipts and a q4 promotion.
- #577 and #578 are open, unfixed, and deliberately out of #579's scope.
- The interval-coverage fences stay up regardless of #575: engine agreement is not calibration.

## Gotchas & Failed Approaches

- **Do not re-attempt** tighter-`g_tol` restarts, NelderMead+LBFGS polish loops, jittered
  multistart, or isotropic-Λ0 basin selection for the q4 REML optimum. All four were measured;
  best reached −219.6243 and violated the gradient contract. The exact gradient is the answer.
- **Speculative optimizer trials mutate the shared `u_cache`/`beta_cache` Refs via `fg!` even when
  rejected** — snapshot/restore around any future trial, or a rejected trial silently corrupts the
  accepted point's reported objective (observed: −219.6302 → −219.6344).
- `confint()` for q4 with a single target is invalid — request all q4 SD targets together via
  `profile_targets(fit)$parm`.
- Run-to-run BLAS/SuiteSparse threading noise on this pipeline is ~1e-3 on `reml_loglik` — never
  set a fixed tolerance at that scale.
- **Push claims settle by `git ls-remote`, never by ahead/behind counts** (a panel got this wrong;
  the conclusion survived, the reasoning did not).
- The parity runner `runparity.jl` aborts at the first failing cell (bridge-I), masking 17 others —
  noted on #467; an outer testset would help.

## Mission-control summary

| repo | branch / main | CI | what shipped | plan by leverage |
|---|---|---|---|---|
| DRM.jl | `feat/575-exact-reml-gradient` @ `c1773e21` | full suite 9203/0/0 (local) | exact REML gradient; #575 fixed; tests wired; PR #579 draft | ① merge #579 ② SE-axis receipt ③ q4 promotion |
| DRM.jl | `docs/drmtmb-parity-scoreboard` @ `9306c669` | n/a (docs) | GLLVM.jl-style parity scoreboard; PR #576 draft | merge after #579 lands so the page's q4 row is current |
| drmTMB | `codex/rebase-julia-optimizer-controls` @ `c69a348c` | #1112 os-matrix green | bridge controls, non-interactive gate fix, all evidence + plans | ① merge #1112 ② fires promotion wave 1 (4 rows) |

## How to Resume

Claude (this target) plans, refactors, writes prose, runs logic checks, and owns the evidence
ledger and review panels. Live R/TMB + Julia fits also ran fine from this session (they are local
and bounded); anything longer than 30 minutes stops for a D-139 estimate + pre-run + approval, and
campaigns go to Totoro, never GitHub Actions.

Working directory: `/private/tmp/drmtmb-control-audit` (drmTMB lane) and
`/Users/z3437171/Dropbox/Github Local/DRM.jl` (Julia side; note local `main` is behind
`origin/main` — base new work on `origin/main`). Safe verification commands:

```sh
Rscript -e 'devtools::load_all("/private/tmp/drmtmb-control-audit", quiet=TRUE); testthat::test_file("/private/tmp/drmtmb-control-audit/tests/testthat/test-julia-bridge.R", reporter="summary")'
julia --project=<DRM.jl worktree> -e 'using Pkg; Pkg.test()'
```

Never stage: `.codex/agents/shannon-coordinator.toml`, foreign-lane files, or anything under other
lanes' worktrees.

```text
Read AGENTS.md and docs/dev-log/handover/2026-09-02-claude-handover-575-fixed.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
