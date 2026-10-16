# Bootstrap shards record a dead forked worker

The reader is a maintainer who needs the shard path
(`drm_bootstrap_shard()`) and `confint(method = "bootstrap")` to treat a dead
forked worker the same way (#1537).

## Goal

A forked `mclapply()` child that exits without a value returns `NULL`. On
`main`, `do.call(rbind, ...)` in `R/bootstrap-shards.R` dropped that
replicate silently, so a shard had no ledger row for that index. A shard now
records a `refit_status = "worker_died"` attempt for it, and
`drm_bootstrap_ledger()` gains a `worker_died` column so
`attempted = usable + failures` still holds.

## Files changed

`R/profile.R`, `R/bootstrap-shards.R`,
`tests/testthat/test-bootstrap-shards.R`, `inst/extdata/env-skip-census.tsv`
(one new `skip_on_os` site), this report, and a check-log fragment.

## Relation to #1530

The `R/profile.R` hunks are a verbatim copy of #1530's (`on_dead`,
`drm_check_parallel_results()`, `drm_rbind_profile_rows()`,
`drm_bootstrap_retain_dead_workers()`), made at the maintainer's request so
this lane does not wait on #1530. Identical hunks merge cleanly: whichever
PR lands second rebases onto the other. #1530's tests, roxygen
(`R/parallel-docs.R`) and `man/drmTMB-parallel.Rd` stay with #1530.

## Checks

No R package is installed in the authoring container and installs were not
allowed, so no R code was run locally: neither `devtools::document()` nor
the test suite. No roxygen block changed, so `document()` produces no
`man/` or `NAMESPACE` diff. `python3 tools/capability_ledger.py
--check-c14-receipt-equivalence`: OK. The census was regenerated with
`Rscript tools/write-env-skip-census.R` (base R only). CI is the first
execution of the new test.
