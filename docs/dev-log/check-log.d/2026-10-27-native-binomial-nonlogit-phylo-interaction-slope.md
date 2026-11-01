# Native Binomial non-logit phylogenetic-interaction slope check log (2026-10-27)

Source: branch `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-interaction-slope-sd", reporter = "summary", stop_on_failure = TRUE)'` — exit 0. Native logit/probit/cloglog checks passed; the separate live Julia bridge companion was skipped because `DRM_JL_PATH` and `DRMODELS_JL_PATH` were unavailable.
- The first 64-pair cloglog pilot estimated the SD slope as 1.212 with truth 0.55 and failed the unchanged 0.35 recovery bound. The final 256-pair fixture passed without changing the truth or bound.
- Before/after source manifests match for `R/drmTMB.R`, `src/drmTMB.cpp`, and `tests/testthat/test-binomial-phylo-interaction-slope-sd.R`.
- Evidence reconciliation: 19,230 candidate rows, 87 linked rows, 19,143 unlinked rows, 107 evidence records.
- Run log and hashes: `docs/dev-log/general-sd-regression/evidence/native-binomial-nonlogit-phylo-interaction-slope-20261027/`.
- This is fixed-seed point-recovery evidence, not interval coverage or Julia parity.
