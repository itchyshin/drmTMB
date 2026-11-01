# After Task: Source-bound Julia Bernoulli SD bridge rerun

## Goal

Bind the live Bernoulli Julia bridge check to the exact native and Julia candidate files used by the test.

## Implemented

No model code changed. The focused bridge suite passed five live Julia tests with no failures or skips.

## Mathematical Contract

The rerun does not change the model. Bernoulli random-effect SD predictors remain on the link scale; the model has no free Bernoulli residual SD.

## Files Changed

- `docs/dev-log/check-log.d/2026-10-20-julia-binomial-sd-source-bound-rerun-v2.md`
- `docs/dev-log/after-task/2026-10-20-julia-binomial-sd-source-bound-rerun-v2.md`

## Checks Run

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'` returned `R_EXIT_CODE=0`. The bridge reported five live Julia tests, with no failures or skips. Before and after SHA-256 checks matched for the R bridge, TMB source, focused R test, and Julia binomial, SD-regression, inference, and test files. Exact values are in the check-log shard.

## Tests Of The Tests

The reporter confirmed five live Julia tests, so the bridge did not pass by skipping its engine checks. The existing test includes a synthetic recovery assertion and a same-data comparison to native TMB. No new test was added in this verification-only task.

## Consistency Audit

No model source, formula grammar, docs, or public behavior changed. The seven selected source hashes before and after the test were identical. An independent reviewer confirmed that these hashes closed the named dirty-Julia identity gap, while noting that `R/drmTMB.R` and the native integration test were not included in this v2 receipt. The broader status inventory was not rerun because this task changed no implemented capability.

## GitHub Issue Maintenance

No issue was changed. This run adds current-source evidence to the open SD-regression programme and does not resolve broader interval or parity issues.

## What Did Not Go Smoothly

The first terminal poll did not retain a final exit code, so the same bounded check was repeated with explicit exit-code capture. The repeat completed successfully.

## Team Learning

For live Julia bridge evidence, capture the process exit code together with the live-test count and hashes of both bridge and engine sources.

## Known Limitations

Two singular-Hessian warnings recurred (`rcond=9.23265335367337e-10`, coordinate 7; `rcond=3.879150990279055e-17`, no flat coordinate identified). Wald standard errors for the affected fits are not trustworthy. This check does not establish interval coverage or parity across the required families, effects, endpoints, or providers.

## Next Actions

The broader v3 receipt supersedes this selected-file rerun and includes a full production-source manifest plus retained console output. Coverage calibration remains deferred. The programme-level gates remain open until the owned ledger and remaining capability rows are reconciled.
