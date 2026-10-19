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
(five `skip_on_os` and five `skip_on_cran` sites in
`test-bootstrap-shards.R`), this report, and a check-log fragment. On
2026-10-19 the lss-tip-identity receipt
(`docs/dev-log/evidence/julia-r-parity/lss-tip-identity/`) was refreshed,
because it hashes `R/profile.R` and `R/bootstrap-shards.R`. After the
rebase onto `4f151444f` it was refreshed again and the C17 model-15
manifest
(`docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`)
was recertified.

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

### Review follow-up 2 (2026-10-18)

1. **`skip_on_cran()` on the forked live-fit tests.** The five tests that fit
   models in forked `mclapply()` children (the multicore-equals-serial test
   and the four #1537 dead-worker tests) now call `testthat::skip_on_cran()`
   before `skip_on_os("windows")`, as `test-profile-parallel.R` does. They
   still run under `devtools::test()` and on CI, which sets `NOT_CRAN: true`
   in `.github/workflows/R-CMD-check.yaml`. The env-skip census was
   regenerated: one new `cran-lane` row for `test-bootstrap-shards.R` with
   five sites.
2. **"No error" versus "aborts".** The PR body said that on `main` a dead
   worker made the replicate vanish "with no error"; #1537 says the shard
   aborts. Both are true of different code. A probe with base `ca3ddefa5`'s
   `drm_parallel_lapply()` and a `SIGKILL`ed child gave one warning ("did not
   deliver a result") and a shard with the replicate dropped, because
   `drm_mclapply_stop_on_error()` stops only on `try-error` results. With
   #1530's `drm_parallel_lapply()`, whose default is `on_dead = "error"`, the
   same `NULL` aborts with `drmTMB_parallel_worker_died`. The PR body now says
   the shard aborts under #1530, as #1537 reports, and keeps the measured
   behaviour on `main`.

Checks: `devtools::document()` again rewrote only the 39 pre-existing Rd
drifts, which were reverted. Full suite results are in the check-log
fragment.

### Rebase onto `main` `5aa693bab` (2026-10-19)

The branch was rebased onto `main` `5aa693bab` (#1590, which refreshed the
lss-tip-identity receipt after #1504 and #1513). There were no conflicts,
and the PR diff is byte-identical before and after the rebase. That receipt
records a SHA-256 for every file under `R/`. This PR changes
`R/bootstrap-shards.R` and `R/profile.R`, so `tools/ci-receipt-staleness.sh`
found 55 of 57 recorded `R/` files matching. The receipt was regenerated
with the unchanged runner `tools/run-julia-phylo-labels-public.R` (Julia
1.13.0, DRModels.jl `da8b3f871`, one thread). It passed 8 of 8 checks. The
native/direct coefficient difference was 7.736e-12 and the log-likelihood
difference 7.105e-14; bridge/direct was 0. These are the same values as
#1590. The checker passes with `--current --self-test`. The staleness
script now finds all 57 `R/` files, the runner and all 95 DRM.jl-side
entries matching. The prior receipt is kept verbatim under
`historical-pre-1537-2026-10-19/`. C17 was not recertified, because this PR
does not change `R/drmTMB.R`, `R/methods.R` or `src/`.

Checks: `devtools::document()` rewrote the same 39 Rd files as on `main`,
with identical text; nothing was kept. Full suite results are in the
check-log fragment.

### Rebase onto `main` `4f151444f` (2026-10-19, third)

`main` moved to `4f151444f` (#1581), which changed `R/methods.R`,
refreshed the lss-tip-identity receipt and recertified C17. The three code
and test commits and the previous docs commit were replayed onto it
without conflicts, and the PR diff for `R/`, tests, `NEWS.md`, the census
and these notes is byte-identical to the pre-rebase diff. The previous
receipt commit (`754b8b80a`) was dropped and regenerated, not merged by
hand: its `historical-pre-1537-2026-10-19/` archive held the #1590
receipt, which `main` already keeps as `historical-pre-1545-2026-10-19/`.

- **lss-tip-identity receipt.** Before the refresh,
  `tools/ci-receipt-staleness.sh` found 55 of 57 `R/` hashes matching
  (`R/bootstrap-shards.R` and `R/profile.R`). The receipt was regenerated
  with the unchanged runner, Julia 1.13.0 and DRModels.jl `da8b3f871`, one
  thread. `JULIA_HOME` must point at the 1.13.0 install: juliaup's default
  channel here is 1.10.0, and the first attempt failed on the format-2.1
  Manifest, as the 2026-10-18 `setup-failure-julia110` evidence records.
  With 1.13.0 it passed 8 of 8 checks in 124.2 s. Every coefficient and
  log-likelihood is bit-identical to the #1581 receipt; the manifest
  differs only at the two `R/` files, plus the native DLL path and hash
  from a fresh compile. The checker log (`--current --self-test`, 12
  mutations rejected) is byte-identical. With `DRM_JL_PATH` set, the
  staleness script finds 57 of 57 `R/` files, the runner and 95 of 95
  DRM.jl entries matching. The #1581 receipt is kept under
  `historical-pre-1537-2026-10-19/`.
- **C17 recertified.** This PR changes none of the five C17-pinned files,
  so C14 equivalence already passed. The manifest's `current_source_sha`
  named `a4ce4172f`, a #1581 branch commit that the squash merge does not
  put on `main`. `python3 tools/recertify-c17.py --label rebase-1537
  --tolerance 1e-10` reproduced model 15 exactly (|change| 0 on mc-0568,
  mc-0569 and mc-0576; 4 of 4 attempts in each cell) and repointed the
  manifest at `2026-10-19-rebase-1537-c17c2-c14-final-source-compatibility/`
  with `current_source_sha` `54fc3cc2e`, the receipt commit. Only the
  receipt paths and that SHA changed; `source_fingerprint`,
  `runner_sha256` and `claim_boundary` did not. The committed
  `2026-08-01-...-run-1/` folder (`2d2db519f`) was moved aside for the run
  and restored byte-identical.

Checks: `capability_ledger.py --check`, `--check-c14-receipt-equivalence`,
`tools/tests/test_capability_ledger.py` (80 tests), env-skip census
`--check` (905 sites) and `tools/run-source-tree-tests.R --check`: all OK.
Nine targeted test files (`test-bootstrap-shards.R`,
`test-profile-parallel.R`, `test-bootstrap-cbind.R`,
`test-bootstrap-response-mask.R`, `test-optimizer-selection.R`,
`test-optimizer-selection-downstream.R`, `test-profile-targets.R`,
`test-profile-interpolation-ties.R`, `test-summary-nonconverged.R`): 130
tests, 1,427 expectations, 0 failures, 0 errors, 3 skips (the
installed-build tests in `test-profile-parallel.R`). The full suite and
`devtools::document()` were not rerun locally for this rebase; CI runs the
full suite.
