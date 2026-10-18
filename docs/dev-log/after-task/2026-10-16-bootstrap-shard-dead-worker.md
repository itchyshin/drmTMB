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

## Review follow-up (2026-10-18)

Three reviewer points, plus one test hazard found while answering them.

1. **Replicates queued on the dead worker.** `mclapply()` preschedules by
   default: with two workers, one child runs replicates 1 and 3 and the other
   runs 2 and 4. A child that dies returns nothing, so every replicate it held
   is `NULL`, including ones it had already refitted. A new test kills the
   child at replicate 2 and asserts that replicates 2 and 4 are both
   `worker_died` attempts and that replicates 1 and 3 equal the serial shard.
   `mc.preschedule = FALSE` was not chosen: `drm_parallel_lapply()` sits
   inside the `R/profile.R` hunks copied from #1530, and changing it there
   would stop those hunks from diffing to empty when the second PR rebases.
2. **Counting after a combine.** No `print()`, `summary()` or `format()`
   method exists for `drm_bootstrap_shard` or `drm_confint` on this branch,
   on `main`, or on any of the 207 remote refs searched. The places that count
   failures are `drm_bootstrap_ledger()` (one column per failure status) and
   `confint(method = "bootstrap")` (`bootstrap.failed = attempted - usable`).
   Two new tests pin both: a dead-worker shard combined with a clean shard
   keeps the `worker_died` row, and its ledger gives
   `usable + failures = attempted = 4`; `confint()` with a dead worker
   reports `bootstrap.failed = 1` and `bootstrap.n + bootstrap.failed = R`.
3. **Rebase order.** The PR body now says that whichever of #1542 and #1530
   lands second rebases so the shared `R/profile.R` hunks (the dead-worker
   block at about lines 2966-3105 and the four call-site hunks above it)
   diff to empty. Checked: the added and removed lines of both PRs'
   `R/profile.R` diffs are identical.

**Test hazard.** `quit()` in a forked `mclapply()` child deletes the parent
session's `tempdir()`, because the child shares it and runs R's exit cleanup.
Measured with a two-line probe: after the child quit, `dir.exists(tempdir())`
was `FALSE` in the parent. Any later test that writes a temporary file would
then fail. The tests here now kill the child with `SIGKILL`
(`tools::pskill(Sys.getpid(), tools::SIGKILL)`), which is also what the OOM
killer sends and skips R's cleanup; the first dead-worker test asserts that
`tempdir()` survives. #1530's `tests/testthat/test-profile-parallel.R:63`
uses the same `quit()` pattern and is left to that lane.

**Not covered.** The ledger has no single `failed` total. An attempt whose
refit converged but whose estimate is not finite has status `"ok"`, so it is
counted in neither `usable` nor any failure column; this predates #1537.

### Checks (2026-10-18)

`devtools::document()` ran with roxygen2 8.0.0. It rewrote 39 Rd files whose
committed text already differed from their roxygen sources on the base commit
(`ca3ddefa5`); none of that is this PR's, so it was reverted and no `man/` or
`NAMESPACE` change is committed. `test-bootstrap-shards.R`: 9 tests,
49 expectations, 0 failures. The full-suite tally is in the check-log
fragment.
