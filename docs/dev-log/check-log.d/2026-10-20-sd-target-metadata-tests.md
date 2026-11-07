# SD target metadata regression tests

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^random-effect-target-metadata$", reporter = "summary", stop_on_failure = TRUE)'`

Result: pass, 19 assertions across two fit-free test blocks. Valid ordinary and phylogenetic target identities resolve. Missing and non-scalar ordinary identity fields, plus empty, non-scalar, or non-character block labels, are rejected with the metadata error. Missing, empty, group-level, and non-scalar structured levels are rejected with the structured-level error. No live Julia tests ran and no model fit was performed. The test covers input validation only, not distribution/provider fit support or uncertainty.

Issue search: `gh issue list --state open --search 'random-effect SD target metadata' --json number,title,url --limit 10` returned unrelated issue #61; no matching issue was found or changed.
