# Platform-clean attempt — NOT READY (2026-08-07)

**Reader:** next CRAN-lane agent / Shinichi.
**Highest proven rung remains:** `tarball-clean`.
**Frozen SHA:** `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
**Source tip exercised:** `main` @ `744b9fbe` (docs-only after freeze commit `459bd3fa9`).

## Verdict

**NOT READY for `platform-clean`.** Blocking row: **win-builder R-release and R-devel both Status: 1 ERROR**.

## Matrix

| Cell | Result | Evidence |
| --- | --- | --- |
| GHA ubuntu-latest (release) | **success** (46.5 min < 75) | https://github.com/itchyshin/drmTMB/actions/runs/31195187084/job/92921623522 |
| GHA macos-latest (release) | **success** (31.7 min) | …/job/92921623507 |
| GHA windows-latest (release) | **success** (58.8 min < 75) | …/job/92921623453 |
| win-builder R-release 4.6.1 | **1 ERROR, 1 NOTE** | https://win-builder.r-project.org/XhAiv0jf1AUd · `winbuilder-release-00check.log` |
| win-builder R-devel | **1 ERROR, 1 NOTE** | https://win-builder.r-project.org/nF44JzoI2nZ9 · `winbuilder-devel-00check.log` |
| R-hub clang-asan | **OK** | run 31195195196 |
| R-hub clang-ubsan | **OK** | run 31195195196 |
| R-hub gcc-asan | **OK** | run 31195195196 |
| R-hub rchk | job FAIL; **adjudicated NOISE** (TMB headers) | `rhub-rchk-adjudication.md` |
| R-hub valgrind | still running at ledger write / see poll log | job 92921626041 |

## Blocking ERROR (win-builder)

`tests/testthat/test-guard-branch-continuity.R:68` under CRAN-lane `R CMD check`:

```
Error: Cannot locate C++ source 'drmTMB.cpp'. Tried:
  ../../src/drmTMB.cpp
  ../../00_pkg_src/drmTMB/src/drmTMB.cpp
[ FAIL 1 | WARN 64 | SKIP 147 | PASS 15427 ]
```

Local macOS `--as-cran` on the freeze tip was Status: 1 NOTE only — the guard's
`00_pkg_src` path resolution does not hold on win-builder's layout. GHA Windows
passes because `NOT_CRAN=true` / source-checkout geometry differs from CRAN's
tarball check. This is a **CRAN-lane test path defect**, not a compiled-code
runtime defect.

## Secondary win-builder NOTE (not the ERROR, but submission-facing)

CRAN incoming feasibility also flagged: New submission; possible DESCRIPTION
spellings (`centile`, `mis`, `uncalibrated`); possibly invalid file URI
`function-map-cheatsheet.png` from `inst/doc/function-map-cheatsheet.html`.

## Next (owner / repair lane)

1. Fix `drm_src_path()` (or skip-with-loud-fail policy) so CondExp guard resolves
   sources under win-builder / CRAN Windows `R CMD check`, **or** move the
   source-text audit to a tools/ CI-only guard (same class as citation guards).
2. Re-submit win-builder R-release + R-devel; require Status without ERROR.
3. Finish valgrind adjudication if still pending.
4. Only then advance ledger `status_claim` → `platform-clean`.
5. **STOP** before DESCRIPTION 0.7.0 bump / CRAN upload.
