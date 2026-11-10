# After Task: covr shard 1 newton-polish guard repair

## Goal

Make coverage shard 1 on PR #1686 run `test-newton-polish-guard.R` for real
and pass, with the cause understood, without skipping or loosening the test.

## Implemented

`drm_pkg_path()` in `tests/testthat/helper-drm-pkg-path.R` now refuses
candidates whose root is an installed package (`Meta/package.rds`). Under
covr the test working directory is `<lib>/drmTMB/drmTMB-tests/testthat`, so
`../../DESCRIPTION` had pointed at the installed package, which the newton
polish test then handed to `pkgload::load_all()`. The installed directory has
no `src/drmTMB.so`, so pkgload failed with the DLLInfo error before the fit
ran. With the fix the subprocess loads the planted source tree, which holds
the covr-instrumented `src/drmTMB.so`. The test's stated intent is to load
the package "from source (via `pkgload::load_all()`, not the installed
copy)", so the locator now matches that intent in every layout.

## Files created or changed

`tests/testthat/helper-drm-pkg-path.R`,
`tests/testthat/test-guard-branch-continuity.R` (covr layout case D),
`.github/workflows/test-coverage.yaml` (comment only), `CONTRIBUTING.md`,
`docs/dev-log/check-log.d/2026-11-09-covr-shard1-pkg-root.md`, this note.

## Checks run and exact outcomes

Local covr reproduction with the workflow's own plant script and
`package_coverage()` call: before `FAIL 2 / PASS 97` with the CI error text,
after `FAIL 0 / PASS 99`. The guarded subprocess took 3.6 s of its 30 s
budget. `devtools::test()` on the two files in a source checkout passed.
Workflow unittest passed. Live result: see PR #1686 CI.

## Consistency audit

No `R/`, `src/`, likelihood, or grammar change. No test, tolerance, timeout,
or guard was skipped or loosened. `skip_on_covr` is still absent.

## Tests of the tests

Case D builds a fake covr library with an installed `drmTMB/DESCRIPTION` plus
`Meta/package.rds` and a planted `00_pkg_src/drmTMB/DESCRIPTION`. It requires
the planted copy. Without the helper change it returns the installed copy and
fails.

## What did not go smoothly

The earlier harness note assumed every `drm_pkg_path` hit under covr came
from `00_pkg_src`; root-level files (`DESCRIPTION`, `NEWS.md`) hit the
installed package first.

## Team learning and process improvements

When a test resolves "the package root", check what an installed package also
ships at its root. A file existing is not evidence that the directory is a
source tree.

## Design-doc updates

None.

## pkgdown/documentation updates

`CONTRIBUTING.md` Test coverage paragraph.

## GitHub issue maintenance

None. Work stays on PR #1686.

## Known limitations and next actions

Shard wall time is unchanged by this fix (65 to over 116 minutes across
runs). Shard 4/4 exceeded the 120-minute job timeout on c3b5c07d8, so the job
timeout is now 180 minutes. More shards would cut wall time if 180 proves
tight.
