# CI blind-spot test repairs (PR 1663)

## What was done

The source-tree job failed in four test files. Each failure was reproduced locally under load_all and traced to one of three causes.

1. test-docs-audit-semantics.R. Caused by this branch. The binomial validator now admits a labelled scalar intercept, so the old probe (a labelled intercept) no longer errors. The binomial probe is now a labelled slope, which is still refused. The beta probe is unchanged. The test also asserts that the binomial refusal names phylo and relmat; this branch's rewording of the message dropped that text, so the assertion still fails until the R patch below restores it. No assertion was removed or loosened.
2. test-estimator-surface-conformance.R. Caused by this branch. The sd_phylo plus sigma phylo refusal was reworded in R/drmTMB.R. The conformance TSV row reml_gate_sd_phylo_plus_sigma_phylo now cites "not implemented with residual-scale effects", which is the surviving text. The refusal itself is unchanged.
3. test-julia-admission-census.R. Caused by this branch. The structured-family refusal message was reworded, so the gate pattern "only for univariate Gaussian, Poisson, NB2, or Gamma" matched nothing and 66 refusals turned into REFUSE_UNGATED. Updating the gate pattern restores them as gated refusals. The expected-ungated list was not touched.
4. test-julia-gate-vs-engine.R. Three causes. (a) Capability artifact row 26 (fe_cumulative_logit) was stale: the registry carries this lane's admission text, the TSVs did not. Regenerated with tools/write-julia-capability-comparison.R. (b) The dashboard julia-gates.tsv row fe_only_random_effects carried new text that the R registry never had, while inst/extdata matched the old registry. The R registry needs the new text (patch), and both TSVs were regenerated from it. (c) Caused by this branch: drmTMB_julia_bridge now resolves a single bridge family type before the cross-family branch, so c(gaussian(), poisson()) aborts on the mixed-response check instead of reaching the xfam bridge. The patch resolves it only for non-cross-family fits. The structured test pattern at the structured_unsupported_family check was updated to the new message text.

## Files changed

tests/testthat/test-docs-audit-semantics.R, tests/testthat/test-julia-gate-vs-engine.R, docs/dev-log/dashboard/estimator-surface-conformance.tsv, docs/dev-log/dashboard/julia-capabilities.tsv, docs/dev-log/dashboard/julia-gates.tsv, inst/extdata/julia-capabilities.tsv, inst/extdata/julia-gates.tsv.

## Required R patch (not applied here)

batch6-ci-blindspot.patch in the session scratchpad touches R/julia-bridge.R (gate pattern, fe_only text, cross-family family-type fix) and R/drmTMB.R (binomial refusal hint). The two gates TSVs were generated against the patched registry, so until the patch is applied julia-gate-vs-engine fails on the dashboard artifact comparison, and docs-audit, census and cross-family tests also fail. With the patch overlaid in memory, all four files pass.

## Not covered

No calibration, parity or recovery claim. No live Julia engine was exercised. The full test suite was not run, only the four named files.
