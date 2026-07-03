# After Task: Q-Series Tranche 90 q1 mu one-slope spatial DRAC path-alignment patch review

## 1. Goal

Patch the pre-fit path-normalization blocker exposed by Tranche 89 without running new compute, and bank the review layer before any repeat DRAC/Rorqual sbatch.

## 2. Implemented

T90 adds `structured-re-gaussian-mu-slope-tranche90-spatial-drac-path-alignment-patch-review.tsv`, SC430 member-board rows, Mission Control build `r284`, validator checks, focused conversion-contract tests, dashboard README wording, completion-map entry `21bn`, and this after-task report. The T85 R runner now normalizes a missing output path through its nearest existing parent before testing whether it is under the exact T83 DRAC run root. The T87 sbatch packet now pins the patched runner hash.

## 3a. Decisions and Rejected Alternatives

The accepted decision was a local path-alignment patch and review only. I did not run SSH, remote copy, `sbatch`, module load, package load, `devtools::load_all()`, smoke execution, model fitting, or coverage. I also did not rewrite historical T87/T88/T89 evidence to the new hash; those rows remain the record of what was staged and run then. T91, if opened, must be no-compute remote restaging proof before any repeat sbatch.

## 4. Files Touched

The functional packet edits are in `tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R` and `tools/slurm/q1-mu-slope-spatial-t87-rorqual-smoke.sbatch`. Evidence and display updates are in `docs/dev-log/dashboard/`, `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche90-spatial-drac-path-alignment-patch-local/`, `docs/design/218-structured-q-series-completion-map.md`, `docs/dev-log/check-log.md`, `tools/validate-mission-control.py`, and `tests/testthat/test-structured-re-conversion-contracts.R`.

## 5. Checks Run

Passed: `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`; `node --check /tmp/drmtmb-mission-control-index-r284.js`; `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`; focused `devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")`; support-cell invariant scan `104 96 8 0 0 0 0`; after-task structure check. Recovery checkpoint: `docs/dev-log/recovery-checkpoints/2026-07-02-193315-codex-checkpoint.md`.

## 6. Tests of the Tests

The first focused R-test run failed because older queue assertions still expected T89 as current evidence and T90 as next action. Updating those expectations to T90 current evidence and T91 next action exercised the new queue boundary. The T90 test also checks physical artifacts: runner helper presence, absence of the old direct `startsWith(output_dir_norm, ...)` check, refreshed sbatch runner hash, wrapper manifest output path, refusal exit code 64, and unchanged support-cell status.

## 7a. Issue Ledger

No GitHub issue action was taken. This tranche is an internal dashboard/packet review slice and does not change public API, formula grammar, package behavior, README, NEWS, pkgdown, or support-cell status.

## 8. Consistency Audit

Rose: no tier/status claim is made from T90. Fisher: no retained denominator, interval, admission, or coverage evidence exists. Gauss: no Hessian/Wald/profile result exists because no model was fitted. Noether: direct-SD target identity remains `sd_mu_intercept;sd_mu_x` for spatial q1 `mu` one-slope. Grace: remote files are stale until T91 restaging proof validates patched hashes on Rorqual.

## 9. What Did Not Go Smoothly

One generated no-Rscript proof command had a shell quoting mistake while extracting the manifest output directory; I regenerated that artifact cleanly. The validator also caught that the member-discussion slice range still stopped at SC429, so I extended the allowed range to SC430. The first focused R-test run then caught stale queue expectations and was updated.

## 10. Known Residuals

T90 does not prove that the patched packet has been restaged remotely, and it does not authorize a repeat sbatch. It creates no fit evidence, no denominator evidence, no admission pass, no coverage evidence, and no support-cell status movement. The next allowed step is T91 remote restaging proof only.

## 11. Team Learning

For host paths with symlinked storage aliases, normalize the nearest existing parent when checking a not-yet-created output path. Also keep historical hash evidence separate from current local packets: old sidecars describe what happened then; new sidecars describe the superseding local packet.
