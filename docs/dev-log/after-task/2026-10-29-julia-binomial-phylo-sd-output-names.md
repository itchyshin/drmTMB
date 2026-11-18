# After Task: Current-source Julia Binomial phylogenetic SD output names

## 1. Goal

Verify the current candidate for the Binomial phylogenetic SD-regression bridge after its R bridge and test files changed since the earlier saved run.

## 2. Implemented

No model code changed. I corrected two test expectations to reflect the existing public output convention: `predict()` returns group-level tip names, while `sdpars[[target]]` retains target-qualified names. The test checks each name contract separately and compares the corresponding values.

## 3a. Decisions and Rejected Alternatives

Keep the existing output names. The current public `predict()` output matches neighboring native Binomial phylogenetic tests; the stored `sdpars` vector retains a target-qualified name. This test-only correction changes no likelihood, covariance, or parameterization.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-phylo-sd-output-names.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-sd-bridge-live-20261029/receipt.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-sd-bridge-live-20261029/source-manifest.sha256`
- This report.

## 5. Checks Run

On drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1` against DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`, I ran:

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0; the filtered test file passed, and three live Julia bridge tests ran. The run emitted the raw-tree-scale message and the standard serial-refit notice.

Source hashes at the successful run:

- `R/julia-bridge.R`: `9bb4cb48d3a07dd3fa598888628f7b84c98b992cea87b2f5128b7ac953906b34`
- `tests/testthat/test-julia-binomial-phylo-sd.R`: `69177fed96998939c56c825b3a567074cc11104b2e51cb5699f87c0162462b6c`
- DRM.jl `src/binomial_sd_regression.jl`: `70f03e0651e6994151a80b6db76579ab478d143ee2ebf6665af97ebb78a557c0`
- DRM.jl `src/sparse_laplace_glmm.jl`: `71c23b8db4f70fe6a58da8a064cd001a279c1f2413925fb98fe01e3a0ce2712c`

`git diff --check -- tests/testthat/test-julia-binomial-phylo-sd.R` passed.

`python3 tools/general-sd-regression/reconcile_evidence.py` passed after linking exactly three required rows for the tree provider, one each for logit, probit, and cloglog. The evidence ledger now has 196 receipt records, 176 distinct linked rows, and 20,174 unlinked rows out of 20,350 candidate rows. No capability status was promoted.

## 6. Tests of the Tests

The first current-source run failed on the two name assertions while fitted and predicted values agreed. After correcting the assertions, the same live bridge filter passed. The failures came from comparing names across two different output containers.

## 7a. Issue Ledger

I searched open issues for “Binomial phylogenetic SD Julia bridge.” No issue matched this output-name test correction; no issue was changed.

## 8. Consistency Audit

Neighboring native Binomial phylogenetic tests use plain tip labels for `predict()`. The saved `sdpars` vector remains target-qualified. Public documentation and capability classifications were not changed because user-facing behavior is unchanged. The internal evidence ledger now points to the current focused receipt for the three tested tree-provider links.

## 9. What Did Not Go Smoothly

The old test expected a target-prefixed label from `predict()`. A later assertion also treated the stored target-qualified vector and the tip-labelled prediction as identically named. The API distinguishes those containers, so the assertions now verify their names separately.

## 10. Known Residuals

Evidence covers one candidate-source phylogenetic Binomial SD-regression bridge route. It does not establish broad Julia parity, repeated-sample recovery, calibrated uncertainty, or interval coverage. The candidate worktrees remain dirty and are not release evidence.

## 11. Team Learning

When comparing stored parameter vectors with prediction results, assert each API's naming convention and compare numeric values separately. A name mismatch alone should not be treated as a model discrepancy.

Memory receipt: `route.py` found no LOAD-FIRST manifest. The `graft` command was unavailable, so I read the exact source and test spans directly. The repository remains the technical source. Golden Set: not run; this output-name test correction did not touch a registered repeated-mistake class.

## 12. Cross-Product Coverage

Covers the current R-to-Julia candidate bridge fit and public SD outputs for a Bernoulli phylogenetic random-intercept SD regression using the filtered live tests. The evidence ledger links only the tree provider for logit, probit, and cloglog.

Does not cover other links, providers, effect shapes, response families, broad cross-engine parity, interval coverage, full package checks, or release readiness.
