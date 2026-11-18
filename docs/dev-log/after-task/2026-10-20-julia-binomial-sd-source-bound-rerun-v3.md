# After Task: Source-bound Julia Bernoulli SD bridge rerun

## Goal

Verify the Bernoulli Julia bridge against the current production-source snapshot and retain enough evidence to reproduce the test identity.

## Implemented

No model code changed. The focused bridge suite returned exit code 0, and its summary reported five live Julia tests with no failures or skips.

## Mathematical Contract

The rerun does not change the model. Bernoulli random-effect SD predictors remain on the link scale, with no free Bernoulli residual SD.

## Files Changed

- `docs/dev-log/check-log.d/2026-10-20-julia-binomial-sd-source-bound-rerun-v3.md`
- `docs/dev-log/after-task/2026-10-20-julia-binomial-sd-source-bound-rerun-v3.md`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/sources-before.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/sources-after.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-bridge-source-bound-20261020-v3/test-console.log`

## Checks Run

`DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-sd", reporter = "summary")'` exited 0. The bridge reported five live Julia tests, with no failures or skips. I hashed the R and native source trees, the paired Julia source tree, and the focused R and Julia test files before and after the run. Both 167-file manifests match byte for byte. The raw console log and both manifests are retained with SHA-256 values in the matching check-log shard.

## Tests Of The Tests

The console output confirms that five Julia tests ran through the bridge; the result was not a skip-only pass. The existing synthetic test checks Bernoulli SD coefficient recovery and a same-data comparison with native TMB. No new test was added.

## Consistency Audit

No model source, formula grammar, or public behavior changed. The source manifest matched before and after. The after-task and check-log reports distinguish point/recovery evidence from interval coverage. No design-doc, NEWS, README, or pkgdown change was needed. The broader public status inventory was not rerun because no capability or user-facing claim changed.

## GitHub Issue Maintenance

No issue was changed. This is a source-bound verification receipt for an existing route; it does not close a broader parity or interval-validation issue.

## What Did Not Go Smoothly

An earlier v2 receipt hashed selected files but omitted `R/drmTMB.R` and did not retain the raw console log. After independent review identified those evidence limits, this v3 run captured the broader source manifest and raw output. Repository-wide `git diff --check` also found a pre-existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`; this task did not edit that leased/concurrent test file. The repo-local after-task validator is absent in this checkout.

## Team Learning

For source-bound bridge evidence, retain production-source manifests and the raw console output alongside the live-test count and process exit code.

## Known Limitations

Two singular-Hessian warnings recurred (`rcond=9.23265335367337e-10`, coordinate 7; `rcond=3.879150990279055e-17`, no flat coordinate identified). Wald standard errors for those fits are not trustworthy. This run does not establish interval coverage or support across the remaining families, random-effect types, endpoints, or providers.

## Next Actions

An independent reviewer confirmed the v3 source receipt and that the combined native/Julia evidence supports G2 for the tested Bernoulli slice. The G2 checkbox remains unchanged because `.unlazy/general-sd-regression/GATES.md` is owned by another live lane. Coverage stays deferred; the wider programme and its other open gates remain active.
