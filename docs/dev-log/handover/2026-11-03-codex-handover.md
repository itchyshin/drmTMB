# Handover to Codex: DRModels.jl PR 1250 green on Julia 1.13, then drmTMB PR 1670

Meta: 2026-11-03 · from Claude Code · to Codex · lane: general predictor-dependent random-effect SD regression

You are Codex, picking up a lane that Claude ran. Read `AGENTS.md` first. This note stands alone; Claude's chat is not available to you.

## Goal

Merge DRModels.jl PR 1250 (branch `claude/sd-regression-into-main`) once its CI is green on Julia 1.13. Then drmTMB PR 1670 (branch `codex/general-sd-regression`) merges through a chained gate. Then check that `main`'s post-merge runs are green, especially `tools/ci-receipt-staleness.sh` (receipt staleness).

Calibration (G5) is deferred by the user. Make no calibration, interval-coverage or broad Julia-versus-native parity claim.

## State at handover (2026-11-03, evening)

| item | state |
|---|---|
| DRModels.jl PR 1250, head `d8c8f8137` | OPEN, auto-merge armed. CI re-running after the last push; not yet seen green |
| Previous head `4ee336d50` | shards 2, 3, 4 passed; shard 1 failed only on `test_docstring_formula_examples.jl` (a docstring example without `@formula`). Fixed in `d8c8f8137`, verified locally (93 of 93) |
| Head before that, `28277cef6` | shard 3 failed: `BoundsError` in `test_negbinomial_sd_regression.jl`. Fixed in `4ee336d50` |
| drmTMB PR 1670, head `0cecd7a9a` | OPEN, waiting on the chain gate |
| Chain gate | `/tmp/claude-503/chain-gates2.sh` (log `/tmp/claude-503/chain-gates2.log`). It polls PR 1250 for MERGED, then runs `~/shinichi-brain/tools/pr_merge_when_green.sh itchyshin/drmTMB 1670 --keep-branch --poll 60`. It may have timed out by the time you read this; check the log, and re-arm if needed |

## What was fixed on PR 1250 (Julia 1.13 CI repair)

All four Julia shards were red on 1.13. Causes, each fixed separately:

1. Julia 1.12+ throws `FieldError`, not `ErrorException`, for a missing NamedTuple field (`_missing_column_lookup` in `src/gaussian_core.jl`).
2. Sparse CHOLMOD `.U` is the factor of the permuted matrix; the mesh and phylo-interaction simulators now use `.UP` (`src/inference.jl`). This was a real source defect.
3. Per-thread warm-start caches were sized `nthreads()` but indexed by `threadid()`. On 1.13 a default task can run on a thread id above `nthreads()`. Now sized by `maxthreadid()` in `beta`, `gamma`, `negbinomial`, `skewnormal`, `student`.
4. MersenneTwister streams differ across Julia versions (CI RNG policy 388). Fixtures that were tuned on 1.10 now use StableRNG; truth-recovery assertions that are seed-fragile are gated behind `DRM_SLOW_TESTS`. Identities, oracles, convergence and refusals are never gated.
5. Docstring examples now wrap `bf()` formulas in `@formula`, as `main`'s new docstring test requires.
6. `main` advanced (PRs 1249 and 1210) and conflicted. Merged `main` into the branch; where both sides edited the same tolerances (`test_ls_inv2x2_chol`, `test_temporal_ou`), `main`'s version was taken.

Flag to Shinichi in the final report: tolerance changes that remain on this branch (the poisson oracle Newton cutoff 1e-12 to 1e-10 relative; one crossed-oracle stall rule using the Newton decrement). Each is explained in the PR body ("Julia 1.13 CI repair" section). No gate was silently loosened.

## Next immediate steps (Codex, in order)

1. Check PR 1250: `gh pr view 1250 -R itchyshin/DRModels.jl --json state,mergeStateStatus,statusCheckRollup`. If a shard is red, read the job log with `gh api --allow-escape-sequences repos/itchyshin/DRModels.jl/actions/jobs/<id>/logs`, strip colour codes, find the first `Error During Test` or `Test Failed`. `runtests.jl` aborts a shard at its first failing file, so a green rerun can expose a later file. Use a continue-on-failure driver (`test/runtests_nc.jl`, a copy of `runtests.jl` that wraps `include` in try/catch) on Totoro to see every failure at once.
2. Work in the scratch clone `/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/20a92c74-3258-42f3-8482-db19e9dcad30/scratchpad/jl-mergeprobe-1` (branch `probe`, remote `gh`). Push with `git push gh probe:claude/sd-regression-into-main`. If that path is gone, clone `itchyshin/DRModels.jl`, fetch `claude/sd-regression-into-main`, and work there. Do not use the Julia lane worktree `.worktrees/general-sd-julia`: it has about 275 unrelated dirty files.
3. When PR 1250 merges, confirm PR 1670 merges via the gate (`gh pr view 1670 --json state`). If the gate timed out, run `~/shinichi-brain/tools/pr_merge_when_green.sh itchyshin/drmTMB 1670 --keep-branch --poll 60`. Never use `--admin`.
4. After 1670 merges, run `gh run list -R itchyshin/drmTMB --branch main -L 5` and confirm `main`'s own run completes. If the receipt-staleness check is red, regenerate the `lss-tip-identity` receipt on a fresh branch with `tools/run-julia-phylo-labels-public.R` against the pinned DRModels.jl `main` clone, then `tools/check-julia-phylo-labels-receipt.R public-001.json --current` and `tools/ci-receipt-staleness.sh` with `DRM_JL_PATH` set. See `docs/dev-log/after-task/2026-11-03-lss-receipt-refresh-after-1668.md` for the exact recipe. After PR 1250 merges, the pinned DRModels.jl clone ref will change; regenerate against the new `main`.
5. Write the AGENT_LOG entry (top of `~/shinichi-brain/memory/AGENT_LOG.md`, newest first) and a final after-task report (`protocols/after-task.md`).

## Live toolchain (Codex runs this)

- Julia 1.13 on Mac: `~/.julia/juliaup/julia-1.13.0+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin/julia`. On Totoro: `~/.julia/juliaup/julia-1.13.2+0.x64.linux.gnu/bin/julia` and `julia-1.10.12+0.x64.linux.gnu`.
- Totoro trees under `~/hsq_work/`: `pr1250-final` (clean full copy, 1.13.2), `main-base` (clean DRModels main `973bbb675`, now older than `main`). Pin `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=4`.
- Totoro: `ssh -o ControlPath=$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22 -o BatchMode=yes snakagaw@totoro.biology.ualberta.ca`. Max 150 cores, and only core ids 0 to 383. Never trigger a Duo prompt; use the ControlMaster socket only. Never compute on a DRAC login node. Do not use a bare `pkill -f` pattern that matches the ssh shell (it killed a session once).
- Live R-to-Julia tests run only on the Mac, one R process at a time, about 4 cores.
- R side: `export NOT_CRAN=true`; `export DRM_JL_PATH=<pinned DRModels.jl clone>` for the staleness check.

## Constraints that still apply

Do not touch other lanes' files: `docs/dev-log/active-lane-split.md`, `AGENTS.md`, `vignettes/implementation-map.Rmd`, `vignettes/predictor-dependent-random-sd.Rmd`, untracked `inst/examples/`, `.sq_work/`, `evidence/`, `figure/`, `news/`, `src/graft`, old calibration dirs; keep stash 8f3daba95e. Stage explicit paths only. No @handles in PR text (`python3 ~/shinichi-brain/tools/agent_mention_check.py --text <file>`). No em dashes in shipped prose; run `python3 ~/shinichi-brain/tools/slop_check.py <abs path>`. Both repos are public, but campaigns never use GitHub Actions. Estimate before any run; over 3 hours needs a plan and approval.

## Known limitations (documented in the PR, not fixed)

- Plain NB2 `animal(1|g)` route stalls at a worse optimum on about 35 to 50 percent of fixture draws.
- Mesh Binomial fits report non-convergence on some draws of weakly identified fixtures.
- `converged=true` was reported at an SD intercept of -26.9 in `test_binomial_sd_regression` (not investigated).
- D-342 (REML objective policy) awaits Shinichi.
- Julia `predict()` on stored rows is population-level; phylo, mesh, crossed and REML structured routes are not exported.

## Files

This handover writes only `docs/dev-log/handover/2026-11-03-codex-handover.md`. The code work lives in DRModels.jl commits `d436cbfa2`, `79f6a9d6b`, `9bce52347`, `28277cef6`, `4ee336d50`, `d8c8f8137` on top of `17b368a85`. The repo has no "Live Phase Snapshot" block in `AGENTS.md`, and `AGENTS.md` belongs to another lane, so no snapshot edit was made.

## How to resume

From the drmTMB repo root, start Codex and paste:

`Rehydrate from docs/dev-log/handover/2026-11-03-codex-handover.md, then continue with the Next Immediate Steps.`

Claude plans, refactors and writes prose; Codex runs the live Julia and R toolchain, so steps 1 to 4 above are yours.
