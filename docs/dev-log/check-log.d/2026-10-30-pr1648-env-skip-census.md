# 2026-10-30: refresh env-skip census for #1648

CI shard 4 failed `test-env-skip-census.R` because
`test-quantile-conditional-docs.R` was not in
`inst/extdata/env-skip-census.tsv`. Regenerated with
`Rscript tools/write-env-skip-census.R` (two new rows: build-premise
skips 2, cran-lane runs 1).
