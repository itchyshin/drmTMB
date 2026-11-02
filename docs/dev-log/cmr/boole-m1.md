# Boole M1 contract audit

## 1. Goal

Add focused Julia and R tests for the frozen CJS history, keyed-predictor, formula-schema, and terminal-identification contract. Keep this leaf test-only.

## 2. Implemented

Added independent contract coverage for invalid histories and intervals, keyed row shuffling, surveyed post-capture predictor requirements, masked omissions, factor levels and contrasts, finite offsets, rank deficiency, unsupported random terms, and global terminal constraints. Tests call the Julia production preparer and the R production join/design helpers; terminal fitting behavior is checked through the R public fit API.

## 3a. Decisions and Rejected Alternatives

Used the R design helpers for preparation checks because the R implementation has no separate full preparation function. Used two small R fits only to check terminal identification and returned constrained designs; each was estimated under one minute and completed within the two-minute cap. Did not generate fixtures, add kernel tests, modify source, or run broader suites.

## 4. Files Touched

- `test/test_cmr_contract.jl`
- `/private/tmp/cmr-drmtmb-20261006/tests/testthat/test-cmr-contract.R`
- `docs/dev-log/cmr/boole-m1.md`

No other files were changed by this leaf.

## 5. Checks Run

- Julia: `julia --project=. -e 'using DRModels; include("test/test_cmr_contract.jl")'`: passed, 31 assertions across four testsets.
- R: `Rscript -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-cmr-contract.R", reporter="summary")'`: passed, 35 assertions. The first red runs exposed missing explicit errors for non-finite offsets, random terms, aliased designs, and unknown/missing join keys, plus lost contrast metadata. A concurrent source repair addressed these; the final targeted run is green.
- The initial Julia invocation with `--project=test` could not resolve the package; rerunning against the already-resolved package project passed.
- Route lookup was attempted with the custom worktree path and returned no manifest. I did not resolve the canonical route and lane-preflight tool paths for this worktree; the parent ran canonical routing by repository name and handled leases. Graft lookup ran but its refresh was blocked by a cache-lock permission error and returned unrelated indexed spans.
- Memory receipt: read the frozen `docs/dev-log/cmr/contract.md` and approved CMR plan. The custom-path route attempt returned no manifest; the parent handled canonical routing. Golden Set: not run because this test-only data/schema audit did not touch a known-mistake class.

## 6. Tests of the Tests

The R tests reproduced the unknown/missing keyed-ID acceptance directly against the production join helper. Earlier targeted runs also exposed lost contrast metadata, non-finite-offset acceptance, a generic rather than actionable random-term error, and aliased-design acceptance; the concurrent R source repair was visible by the final run, where those checks passed. Julia contract tests all pass against the current production preparer.

## 7a. Issue Ledger

- No issue ID was assigned to this leaf.
- Initial R red output identified the production gaps above. Concurrent source repairs were performed outside this leaf; no source edits are claimed here.

## 8. Consistency Audit

Compared Julia `CMRData`/`_cjs_prepare` and R `cmr_data()`/`.cmr_join_predictors()`/`.cmr_design()` against `docs/dev-log/cmr/contract.md`. The Julia keyed joins, factor schema, mask omission, intervals, and global terminal flags matched the exercised contract. R unit labels remain strings and do not rescale declared intervals; factor contrast values and active-row levels are checked. Concurrent source repairs now reject unknown and missing R keys, and the final targeted run passes those cases.

## 9. What Did Not Go Smoothly

The custom-path route lookup returned no manifest, and the graft cache lock prevented refresh. The test project environment did not resolve DRModels directly, so the repository's resolved root project was used. During test construction, factor expectations were corrected to reflect active-row ordering and labeled factor levels.

## 10. Known Residuals

No full Julia or R package suite, source repair, integration runner, or performance/inference check was run. The results are contract evidence only.

## 11. Team Learning

Keyed table validation should reject unknown and missing join keys before merging; an `all.x=TRUE` merge can otherwise silently ignore malformed extras. Contrast tests should retain and compare the supplied matrix, since a method-name string cannot represent a custom contrast matrix.

## 12. Cross-Product Coverage

Coverage is limited to CJS history construction, predictor joins/design schemas, and terminal identification. This leaf **does NOT cover** the likelihood kernel, fitting accuracy, simulation/recovery, predictions, random effects, reference selection, inference calibration, the R-to-Julia bridge, or release readiness.
