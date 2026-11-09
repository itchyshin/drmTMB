# 2026-11-09 covr shard 1: drm_pkg_path resolved the installed package (PR #1686)

Repair pass on `cursor/codecov-rollout-c9a1` after producer run
[42526163025](https://github.com/itchyshin/drmTMB/actions/runs/42526163025)
(head `20cb94b8b`). Shards 2-4 and R-CMD-check passed; shard 1 failed with
`FAIL 2 | WARN 44 | SKIP 158 | PASS 11204`, both in
`test-newton-polish-guard.R`:

- line 61: `subprocess timed out or errored: ! in callr subprocess. Caused by
  error in getDLLRegisteredRoutines.DLLInfo(dll, addNames = FALSE): must
  specify DLL via a "DLLInfo" object`;
- line 68: `is.finite(res)` is `FALSE`, a consequence of line 61 (`res` is
  `NA`).

## Root cause

`covr::package_coverage()` (covr 3.6.x) calls `tools::testInstalledPackage()`
with `outDir = file.path(install_path, "drmTMB")`, so tests run from
`<install_path>/drmTMB/drmTMB-tests/testthat`. The test computes
`drm_guard_pkg_root <- dirname(drm_pkg_path("DESCRIPTION"))`, and the first
`drm_pkg_candidates()` entry, `../../DESCRIPTION`, is
`<install_path>/drmTMB/DESCRIPTION`: the installed instrumented package, not
the planted `00_pkg_src/drmTMB` source tree. The callr subprocess ran
`pkgload::load_all()` on that installed directory. It has no `src/`, so
pkgload's `library.dynam2()` returned `NULL` (no `src/drmTMB.so`) and
`assignNativeRoutines(NULL, ...)` raised the DLLInfo error. In R CMD check,
`../../DESCRIPTION` from `drmTMB.Rcheck/tests/testthat` does not exist, so the
`00_pkg_src` candidate wins and the test passes; that is why only covr failed.
Earlier `R/`, `man/`, and `src/` lookups were unaffected because the installed
package has no such source files. `NEWS.md` had the same latent mis-resolution
(the installed copy is byte-identical, so it passed).

## Fix

`drm_pkg_path()` (tests/testthat/helper-drm-pkg-path.R) now ignores a
candidate whose package root contains `Meta/package.rds`, the marker of an
installed package. The test file, its 30 s timeout, and its finite-logLik
assertion are unchanged. A covr-layout case (D) was added to the
`drm_pkg_path` layout regression test in `test-guard-branch-continuity.R`.

## Local reproduction (R 4.5.2, covr 3.6.5, pkgload 1.5.3)

Scratch copy with only `test-newton-polish-guard.R` and
`test-guard-branch-continuity.R`, then the workflow's own steps:
`bash tools/covr-source-tree-layout.sh "$RUNNER_TEMP/package" .` and
`covr::package_coverage(quiet = FALSE, clean = FALSE, type = "tests",
install_path = install_path)`.

- Before: `[ FAIL 2 | WARN 0 | SKIP 0 | PASS 97 ]`, identical DLLInfo message.
  `drm_pkg_path("DESCRIPTION")` from the covr cwd returned
  `<install_path>/drmTMB/DESCRIPTION`.
- After: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 99 ]`.
- Subprocess timing under instrumentation: `load_all` 1.46 s, Tweedie fit
  1.82 s, total 3.6 s of the 30 s budget; logLik 9.92. It loaded the
  covr-built `src/drmTMB.so` in the source tree (mtime unchanged, no
  recompile).
- `devtools::test(filter = "guard-branch-continuity|newton-polish-guard")`
  in a source checkout: pass.
- `python3 -m unittest tools/tests/test_codecov_workflow.py`: 8 tests OK.

## Follow-up: source-tree manifest (head b45e93c2)

`source-tree tests (blind spot)` failed at its manifest step, not on a test:
`NOT IN MANIFEST ... test-guard-branch-continuity.R`. The scanner in
`tools/run-source-tree-tests.R` flags any double-quoted literal whose path
prefix matches `.Rbuildignore`; case D's
`file.path(lib_d, "drmTMB", "Meta", "package.rds")` matches `^Meta$`. The
premise is a tempdir fixture, so the file still runs under R CMD check; the
scanner's sanctioned remedy (`--update`) adds it to the source-tree lane as
well. No test was hidden from the scanner or changed. Full lane locally
(scratch git copy, `Rscript --no-init-file tools/run-source-tree-tests.R`):
manifest agrees, 51 files, `[ FAIL 0 | WARN 14 | SKIP 7 | PASS 26618 ]`.

## Live result on c3b5c07d8 and shard 4 timeout

[test-coverage 42624436768](https://github.com/itchyshin/drmTMB/actions/runs/42624436768)
(tested merge `196d0e80f`): shard 1/4 `[ FAIL 0 | WARN 44 | SKIP 158 | PASS
11205 ]`, 63.3837%; shard 2/4 `PASS 10190`, 66.4887%; shard 3/4 `PASS
10813`, 63.7692%. Shard 4/4 was cancelled at the 120-minute job timeout while
still in tests (13:24Z to 15:20Z); on run 42526163025 the same shard finished
in 106.8 minutes, and shard 2/4 ranged 65 to 109 minutes between the two runs.
Job `timeout-minutes` is raised to 180, matching R-CMD-check's unsharded
job. No test or test-level timeout changed.
[R-CMD-check 42624436767](https://github.com/itchyshin/drmTMB/actions/runs/42624436767)
passed, including `source-tree tests (blind spot)`.
