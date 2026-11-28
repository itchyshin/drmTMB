# Generalized prior-table integration checks

On drmTMB source `d4531fdcd23b33de3a3f67fb8b2660ad8a105bd2`, the 24-shard package test covered 925 unique assigned files; all shards and the controller exited 0. The updated prior article rendered and `pkgdown::check_pkgdown()` passed. An R package build and check without tests or vignette builds exited 0 with two warnings because built vignettes were absent from that archive. The article was built separately.

Live R-to-Julia fixtures passed on the same R production tree and DRModels.jl production source `d8ccb7195de5fe0ed50f094460a07fc55530ebd7`, with 47, 12 and 17 assertions in the three groups. Two generated cases reported singular Hessians; uncertainty calibration is outside this evidence.

The DRModels.jl 731-file suite is `PASS_RECONCILED_WITH_TEST_ONLY_REPLAYS`: six original sections and two exact-assignment test-only replays exited 0 on the same production code. The original failures remain preserved. The combined receipt is `/home/snakagaw/hsq_work/generalized-prior-table-arc/drmodels-v5-full-d8ccb719-20261128/attempt-01/combined-source-reconciliation.json`, SHA-256 `eede4bdb0a9f539a8520d0ba9194a336b788f1209a80981eb760d8e1005e4a69`. The original controller-summary print was malformed; individual source-integrity snapshots, logs and exit receipts were checked.

GitHub checks and review remain pending. This evidence does not authorize a merge or release.
