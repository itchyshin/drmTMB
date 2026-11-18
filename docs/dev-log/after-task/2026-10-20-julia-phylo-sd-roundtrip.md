# After Task: Julia phylogenetic SD scale round-trip

## Goal

Check that the Julia bridge's phylogenetic SD scale conversion survives saving and reloading a fitted object.

## Implemented

The focused test covers intercept and no-intercept SD formulas. In the live Julia bridge case it saves and reloads the fitted object, then checks that public phylogenetic SD coefficients and a new-data SD prediction are unchanged. No model or likelihood code changed in this slice.

## Mathematical Contract

For this ultrametric tree, Julia's raw Brownian kernel has height 2.5 and native TMB reports the correlation-scaled marginal SD. The public bridge therefore applies the existing `sqrt(2.5)` SD multiplier, or its log offset for the intercept. No kernel is rescaled and no model parameterization changed.

## Files Changed

- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/check-log.d/2026-10-20-julia-phylo-sd-roundtrip.md`
- This report.

## Checks Run

- `DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true JULIA_DEPOT_PATH='/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia' JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary")'` passed with 33 assertions, 0 failures, 0 warnings, and 0 skips. One live Julia fit ran in about 40 seconds; the output confirmed bridge glue was exercised.
- `git diff --check -- tests/testthat/test-julia-binomial-phylo-sd.R docs/dev-log/check-log.d/2026-10-20-julia-phylo-sd-roundtrip.md docs/dev-log/after-task/2026-10-20-julia-phylo-sd-roundtrip.md` passed.
- `slop_check.py` passed for both prose files with zero findings.
- `tools/check-after-task.R` was not available in this checkout, so its automated report validation could not run.

## Tests Of The Tests

The serialization assertions exercise the feature together with a non-unit phylogenetic scale, both intercept conventions, and existing public extraction and prediction methods. The live test also compares the fitted Julia and native TMB coefficients and likelihood. No deliberate mutation control was run in this slice. This is evidence from a dirty candidate worktree and does not establish clean-source or released-package behavior.

## Consistency Audit

No formula grammar, likelihood, or user-facing capability changed. The test uses the existing `sd(species, level = "phylogenetic") ~ z` syntax. No broader status-inventory search was warranted for this test-only scale round-trip addition.

## GitHub Issue Maintenance

`gh issue list --state open --search 'phylogenetic SD Julia' --limit 20` found no issue specifically about the scale-conversion round-trip. No issue was changed; the closest results concern unrelated family-status documentation and simulation infrastructure.

## What Did Not Go Smoothly

The worktree has many concurrent edits, so the test and two documentation paths were checked and leased individually. The first preflight command targeted the wrong worktree for the R test; rerunning from the R/TMB candidate succeeded and confirmed the live test result.

## Team Learning

Serialization belongs in the public-output contract for scale-adjusted bridge objects. A good regression test should inspect public methods after reloading, not only the in-memory fit. Run each test from the worktree that owns the source being tested, even when paired-engine paths are configured separately.

## Known Limitations

The evidence covers one synthetic Bernoulli phylogenetic model, one ultrametric tree height, and one live Julia/TMB comparison. It does not pass the broader Bernoulli calibration gate, establish cross-family support, or verify non-ultrametric tip-wise scaling.

## Next Actions

Continue the implementation-first programme on a source slice with reconciled ownership. Keep interval-coverage calibration deferred under the revised finish line; this round-trip check does not close the broader Bernoulli, family, effect-type, or engine-parity work.
