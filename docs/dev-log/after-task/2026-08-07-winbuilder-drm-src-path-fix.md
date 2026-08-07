# After-task: win-builder CondExp `drm_src_path` repair

**Reader:** next CRAN-lane agent / Shinichi.
**Purpose:** fix the path helper that made win-builder ERROR on the CondExp
drift guard, without claiming `platform-clean`.

## Root cause

Under `test_check()` (`R CMD check`), `testthat::test_path()` returns paths
relative to `getwd()`, and `getwd()` is `<pkg>.Rcheck/tests/` (not
`tests/testthat/`). The old helper tried:

- `../../src/drmTMB.cpp`
- `../../00_pkg_src/drmTMB/src/drmTMB.cpp`

Both overshoot the Rcheck tree. Local macOS `--as-cran` still passed when the
Rcheck lived inside a source checkout, because `../../src` accidentally hit
that checkout's `src/`. win-builder's layout is
`R-release/{drmTMB, drmTMB.Rcheck}/` with no such accident, so both candidates
missed and the guard ERRORed after 15427 passes.

## Fix

`tests/testthat/test-guard-branch-continuity.R`:

- `drm_src_candidates()` / `drm_src_path(start_dir=)` now also try
  `../00_pkg_src/drmTMB/src` (correct Rcheck-relative path from `tests/`),
  `../../drmTMB/src` (win-builder unpacked sibling), and a short upward /
  sibling walk.
- New unit test covers checkout, Unix `00_pkg_src`, and win-builder sibling
  temp layouts.
- Still fail-loud if the file is truly absent (no silent `skip_*()`).

Focused `test_dir(..., filter = "guard-branch-continuity")`:
`FAIL 0 | PASS 51`. Pure win-builder fixture: old helper miss → new helper hit.

## Rung honesty

Highest proven rung remains **`tarball-clean`**. This repair changes the
candidate; win-builder must be re-green before any `platform-clean` claim.
DESCRIPTION stays 0.6.0. No CRAN upload.
