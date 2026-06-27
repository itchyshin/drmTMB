# Session Handoff: drmTMB q-series structured-RE completion lane

Meta: 2026-06-27 · from Claude (very long session) · TARGET = a fresh Claude (ultracode) session

You are Claude, picking up the drmTMB **Q-Series Structured Random-Effect Completion Plan**
(`docs/design/218-structured-q-series-completion-map.md`). A prior long Claude session banked
four PRs and built two more coverage runners. This doc is your lossless entry point — read it
plus the linked after-task reports; do not re-discover.

## Critical Context (read or you will go wrong)

1. **Two hard external blocks you cannot clear yourself:**
   - **Coverage execution is on the cluster (fir/DRAC), and the harness BLOCKS the agent from
     transferring code to external SSH hosts** (bulk-exfiltration guard — confirmed, hard). So
     the agent CANNOT deploy drmTMB to fir. The **maintainer runs the deployment** via the
     copy-paste runbook `tools/slurm/DEPLOY-sigma-slope-coverage.md`. The maintainer already
     said "approve submit" for the SR475 coverage spend; the only reason it isn't running is the
     transfer block.
   - **relmat-Q bridge** is blocked on upstream **DRM.jl #299/#300** (draft, unmerged) + the
     standing **do-not-touch-DRM.jl** guard.
2. **Standing hard guards (from the original handoff, still in force):** no Totoro/DRAC job
   submission without explicit per-run approval; do NOT touch `/Users/.../DRM.jl`; do not
   undraft/merge PRs without approval; no Ayumi-facing replies; no q4 REML / non-Gaussian REML
   / AI-REML claims; no broad bridge / public-optimizer promotion; keep SR150 blocked until
   MCSE-calibrated coverage exists; never infer a half-cell from a neighbour.
3. **A session-scoped `/goal` Stop hook ("Finish the Q-Series … plan") was active** in the
   prior session and fired repeatedly because the plan is genuinely ~25–35% complete and the
   decisive rungs are externally blocked. If it re-appears: holding for a maintainer
   decision/cluster run is correct; do NOT breach guards or fake completion to clear it.
4. **Local R gotcha:** `~/.Rprofile` prepends an R-4.5 library that **segfaults under R 4.6**.
   Always run R with `--no-init-file` (or `--vanilla`); runners use an `--attempt-temp-install`
   temp-source-install path because local `devtools`/`testthat` are absent.

## Goals / mission

Finish the q-series completion plan by treating each exact support cell as the unit of truth
(formula × provider × family × endpoint × route × estimator × interval × coverage), banking
evidence one cell at a time, never inferring support from neighbours. "Done" for a cell = the
full ladder to `supported` (point-fit + fixture-parity + interval reliability + coverage). The
plan is ~25–35% to that bar; the expensive rungs (coverage, intervals, bridge) are mostly
externally gated.

## What Was Accomplished (this session)

- **Took over from a live Codex session** mid-flight on the relmat-NB2 micro-shard; detected
  via repo state that Codex completed it concurrently (commit `f72ca577`, PR **#675**). Verified
  rather than duplicated. **Recorded #675 CI = 3/3 green** on the PR.
- **PR #676** — banked the **count NB2 `sigma` one-slope rejection contract** (`94aecbdf`),
  CI 3/3 green. (Engine rejects structured count sigma; documents the half-cell.)
- **PR #677** — banked the **sigma-slope coverage pilot + SR475 grid scaffolding + deploy
  runbook** (`92578fc4`). Pilot coverage **96–98% near-nominal** (phylo+relmat, 100 reps),
  DGP↔model alignment verified.
- **PR #678** — banked the **non-Gaussian structured-family rejection contract** (`ec2ddb18`):
  8 family/endpoint/provider routes the engine rejects (beta, Gamma, student, ordinal,
  poisson-zi, truncated_nbinom2). q-series cells **90 → 98**. **#678 CI was in-flight at
  handover — first action: record its result.**
- **Ultracode workflow** (9 agents) built + adversarially verified two more coverage runners
  (q2-slope, q4-location), ran a full reconciliation audit, and re-verified all banked work.

## Current Working State

- **Working:** validator `mission_control_ok` on the current tree (98 q-series cells, all
  rejection contracts + scaffolding registered). PRs #676/#677 CI-green; #678 CI pending.
- **In progress / verified-ready:** the **q2-slope coverage runner**
  (`tools/run-structured-re-q2-slope-coverage-grid.R` + `.sbatch`) — Fisher verdict **SOUND**
  (DGP↔model aligned, resumable, correct), pending ONE fix (degenerate MCSE gate) before banking.
- **Held (do NOT bank as-is):** the **q4-location coverage runner**
  (`tools/run-structured-re-q4-location-coverage-grid.R` + `.sbatch`) — Fisher caught real
  defects (see Gotchas).
- **Blocked:** coverage execution (cluster, maintainer-run); relmat-Q bridge (DRM.jl
  #299/#300); q4 **all-four** one-slope intervals (Hessian/`pdHess=FALSE` geometry — engine work).

## Key Decisions & Rationale

- **Detect-concurrent-work, verify-don't-duplicate:** Codex banked relmat-NB2 during the
  session; verifying-before-acting avoided a collision. Apply the same vigilance.
- **Verify before banking subagent output:** caught a real wording-accuracy bug in the #678
  contract (count-specific phrase on non-count families) and a test/sidecar/validator mismatch
  before commit. Always re-run the validator + re-read claim_boundaries after a subagent.
- **q4-location held**, not banked, because its smoke masks a boundary problem (below).
- **Did not pre-build the full cluster coverage runner before the maintainer okayed the spend**,
  and did not breach the exfil/compute/DRM.jl guards under sustained hook pressure.

## Files Created / Modified

**Committed (in the PR stack #676→#678):** see `git diff --name-only main...claude/nongaussian-family-rejection-contract`. Key paths:
- `docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv` (#676)
- `tools/run-structured-re-sigma-slope-coverage-pilot.R`, `…-grid.R`, `tools/slurm/sigma-slope-coverage-grid.sbatch`, `tools/slurm/DEPLOY-sigma-slope-coverage.md` (#677)
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv` (#678)
- `tools/validate-mission-control.py`, `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`, `tests/testthat/test-structured-re-conversion-contracts.R`, `tests/testthat/test-nongaussian-structured-boundary.R`, `docs/design/218-structured-q-series-completion-map.md`, `docs/dev-log/dashboard/README.md`, `docs/dev-log/check-log.md` (across #676/#678)
- After-task reports under `docs/dev-log/after-task/2026-06-26-*` and `2026-06-27-*`.

**Committed by THIS handover (branch below):** the previously-untracked, now-preserved coverage runners:
- `tools/run-structured-re-q2-slope-coverage-grid.R` + `tools/slurm/q2-slope-coverage-grid.sbatch` + `docs/dev-log/simulation-artifacts/2026-06-27-q2-slope-coverage-pilot*/` (q2 — verified-ready)
- `tools/run-structured-re-q4-location-coverage-grid.R` + `tools/slurm/q4-location-coverage-grid.sbatch` + `docs/dev-log/simulation-artifacts/2026-06-27-q4-location-coverage-pilot/` (q4 — HELD, defects)
- `docs/dev-log/after-task/2026-06-27-sigma-slope-coverage-pilot-and-grid-scaffolding.md`
- this doc + the `AGENTS.md` snapshot pointer.

## Next Immediate Steps (ordered; ultracode-parallelizable where noted)

1. **Record #678 CI result** on the PR (mirror the #674/#675/#676/#677 triage-comment style).
2. **[parallel-safe] Fix the degenerate MCSE gate** in BOTH new runners
   (`run-structured-re-q2-slope-coverage-grid.R:902-906,964`;
   `run-structured-re-q4-location-coverage-grid.R:779-781,835`): `sqrt(cov*(1-cov)/n)` → 0 when
   coverage saturates, so `mcse_threshold_met` falsely fires at n=6. Require `n>=475` AND a
   non-degenerate estimate.
3. **[parallel-safe] Bank the q2-slope coverage runner** (after step 2) — extends deployment
   readiness to a 2nd lane (sigma-slope is already deploy-ready).
4. **Fix the sigma-slope sbatch copy-back defect** (`tools/slurm/sigma-slope-coverage-grid.sbatch:44,74-88`):
   `set -euo pipefail` aborts before the `cp …$RESULTS_DIR` step on Rscript failure → results
   stranded on purged `$SCRATCH`. Wrap the Rscript call in `set +e`/`EXIT_CODE=$?`/`set -e`,
   copy unconditionally, then `exit $EXIT_CODE`. Apply the same to the q2/q4 sbatch.
5. **q4-location:** fix the 4 defects (degenerate MCSE; coverage computed on a boundary-censored
   subsample — report a finite-interval fraction; stale `fit_error` rows in
   `01-phylo-mu1_intercept-replicates.tsv`; `estimate_sd` all-NA from a bad `sdpars$mu` key at
   `…:475-479`) OR keep held. Do not gate to SR475 until fixed.
6. **Maintainer-only: run the coverage deployment** per `tools/slurm/DEPLOY-sigma-slope-coverage.md`
   (sigma-slope ready now; q2 after step 3). The agent cannot transfer code to fir. After results
   land in `/project/def-snakagaw/snakagaw/sigcov-results/` and are pulled back, a session does
   Step 7 of that runbook: compute per-target coverage → bank a coverage sidecar → move
   `coverage_status` off `planned` (never promote `supported` without the full ladder).
7. **Decision (do not self-fix — touches guarded engine prose + tests):** the rejection contracts
   + boundary test match the literal `"Structured non-Gaussian paths"`, which is a cli **hint**
   line (`R/drmTMB.R:6631`), NOT the abort headline (`:6628`). Rewording 6631 silently breaks
   5+ sidecars + the test. Either move the phrase to the headline or re-anchor the contracts —
   maintainer's call.

## Blockers / Open Questions

- Coverage: maintainer must run the cluster deployment (agent transfer-blocked). Spend approved.
- Bridge: DRM.jl #299/#300 unmerged; do-not-touch-DRM.jl guard.
- q4 all-four one-slope intervals: Hessian geometry (`pdHess=FALSE`, sigma-SD at lower bound) —
  real engine/identifiability work, needs explicit authorization.

## Gotchas & Failed Approaches (do not retry)

- `scp drmTMB tarball → fir` is **hard-blocked** by the harness (exfiltration). Don't retry;
  the maintainer transfers it.
- `module load X 2>&1 | tail` runs in a subshell → the load is LOST. Never pipe `module load`.
- `~/.Rprofile` R-4.5 lib segfaults under R 4.6 → always `--no-init-file`.
- The q2/q4 sbatch `--time` and the original sigma sbatch timing comment were wildly wrong
  (claimed ~40s/fit; actual **~0.1–0.3s/fit**) — the whole coverage grid is **minutes, not days**.
- q4-location smoke at n=6 looks clean but **boundary fits are silently dropped** and the MCSE
  gate degenerates — do not trust its coverage numbers.
- 8-group DGP → ~20% downward SD bias (shrinkage); keep bias reporting alongside any coverage.

## How to Resume (rehydration recipe — TARGET = Claude, ultracode)

1. `cd "/Users/z3437171/Dropbox/Github Local/drmTMB"`; `git status --short --branch`; `git log --oneline -8`.
2. Read: this doc → `docs/design/218-structured-q-series-completion-map.md` → the after-task
   reports under `docs/dev-log/after-task/2026-06-26-*` + `2026-06-27-*` → `tools/slurm/DEPLOY-sigma-slope-coverage.md`.
3. `python3 tools/validate-mission-control.py` (expect `mission_control_ok`, 98 q-series cells,
   8 non-Gaussian rejection rows).
4. Spawn **Rose** (`systems_auditor`) before any public/status claim; spawn **Fisher**
   (`inference_reviewer`) before trusting any coverage/interval number.
5. **Ultracode fan-out:** steps 2–5 of Next Immediate Steps are parallel-safe across distinct
   files (q2 MCSE fix / q4 fixes / sbatch fixes) — a workflow can build+verify in parallel; the
   main loop applies shared-file edits (validator/sidecars) sequentially, as last session did.
6. Powers: this is a Claude session (plans/refactors/prose/logic+CI checks). **Codex** runs the
   live R/TMB toolchain; the **maintainer** runs the cluster. Route accordingly.

## Mission-control summary

| Lane | State | CI | Next by leverage |
|---|---|---|---|
| count one-slope `mu` (8 cells) | banked (#668–#675) | green | done |
| count `sigma` one-slope rejection (#676) | banked | green | done |
| non-Gaussian family rejection (#678) | banked | **pending — record it** | step 1 |
| sigma-slope coverage scaffolding (#677) | banked, **deploy-ready** | green | maintainer runs cluster (step 6) |
| q2-slope coverage runner | verified-SOUND, untracked→committed here | n/a | MCSE fix → bank (steps 2–3) |
| q4-location coverage runner | HELD (defects), committed here | n/a | fix or keep held (step 5) |
| coverage evidence (all 90+ cells) | 0% — BLOCKED | n/a | cluster run (maintainer) |
| relmat-Q bridge | BLOCKED | n/a | DRM.jl #299/#300 |
| q4 all-four intervals | BLOCKED (Hessian) | n/a | engine work (authorize) |

Authoritative copy: this file. PR stack: #678→#677→#676→#675→… (all draft; maintainer merges).
