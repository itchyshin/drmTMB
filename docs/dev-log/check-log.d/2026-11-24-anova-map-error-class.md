# ANOVA MAP error class check (2026-11-24)

- Source under test: current-main prior candidate `b490dbfae99d068c3de8e2466cd5ebc95278d66f` (base main `9d36584027467bba1c38b3dad5dc1855d73f67b5`). Its `anova()` guard intentionally emits `drmTMB_anova_map_error`, distinct from the lower-level `drmTMB_lrtest_map_error`.
- The strict four-shard full-suite retry assigned 912 test files exactly once. Shards 1, 3 and 4 exited 0. Shard 2 exited 1 on `test-anova-lrt.R`: the test expected the lower-level class although `anova.drmTMB()` correctly returned the ANOVA-specific class and emitted the MAP warning.
- Updated that assertion to the documented ANOVA-specific condition. `Rscript -e 'devtools::test(filter="anova-lrt", stop_on_failure=TRUE)'` on the isolated checkout with R 4.6.0 passed 39/39, 0 failures, 0 warnings, 0 skips in 3.5 seconds.
- Not yet run: the full shard-2 allocation on the corrected test source. The three clean shard receipts remain usable only after verifying their source manifest excludes the changed test file and the package source is byte-identical. No release or merge.
