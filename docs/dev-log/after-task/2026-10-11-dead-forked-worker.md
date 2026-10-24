# Dead forked workers abort or record a failure

The reader is a maintainer reviewing the follow-up to merged #1510. A
forked `mclapply()` child that exits without a value returns `NULL`.
`rbind()` then drops that element, so a profile target or bootstrap
replicate can disappear with no error.

## Goal

A dead forked worker must raise a classed error or become a recorded
failure. It must never silently drop a row. Ordinary failed bootstrap
refits still count toward `bootstrap.n` and `bootstrap.failed` (#1501).

## Files changed

`R/profile.R` (`drm_check_parallel_results()`, `drm_rbind_profile_rows()`,
`drm_bootstrap_retain_dead_workers()`), `R/parallel-docs.R`,
`man/drmTMB-parallel.Rd`, `tests/testthat/test-profile-parallel.R`,
`NEWS.md`. `R/julia-bridge.R` is untouched. `R/drmTMB.R` and `R/methods.R`
are untouched, so C17 was not recertified.

## Checks run

`test-profile-parallel.R` on `pkgload::load_all()` (R 4.3.3): 12 tests,
0 fail, 0 error, 3 skips (two cluster-need-installed-build, one Windows-only).
The three new dead-worker tests passed, including a `quit()` child under
`mclapply()`. `test-env-skip-census.R`: 3 tests pass after regenerating
the census (874 skip call sites; `test-profile-parallel.R` os sites 4 → 5).

## Consistency audit

`rg "meta_gaussian|tau ~|rho ~" R/profile.R R/parallel-docs.R NEWS.md tests/testthat/test-profile-parallel.R`
should stay empty. Terms used: `sigma` is not involved; `bootstrap.n` and
`bootstrap.failed` keep the #1501 names.

## GitHub issue maintenance

#1510 is already merged. This is a follow-up branch
`cursor/dead-forked-worker-7717`. The PR body uses `Refs #1232`,
`Refs #1254`, and `Refs #1236` only.

## Known limitations

The `quit()` child test is Unix-only. Socket (`cluster`) workers that die
already error in `parLapply()`; this change targets the `mclapply()` NULL
hole.
