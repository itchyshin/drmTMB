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

## Repair landed (awaiting win-builder re-green)

`drm_src_path()` now resolves:

- checkout `tests/testthat` → `../../src`
- R CMD check `*.Rcheck/tests` → `../00_pkg_src/drmTMB/src`
- win-builder sibling → `../../drmTMB/src` (+ short upward/sibling walk)

Local fixture: old two-candidate helper **misses**; new helper **hits**.
Focused continuity suite: `FAIL 0 | PASS 51`. See after-task
`2026-08-07-winbuilder-drm-src-path-fix.md`.

**Still NOT READY for `platform-clean`** until win-builder R-release + R-devel
return without ERROR on a tarball that includes this repair.

### Resubmit status (2026-08-07 afternoon)

- Repair commit: `25e38cc74` on PR #941.
- Fixed tarball rebuilt: size **9818425**, SHA-256 `f9b9588e…` (see
  `winbuilder-resubmit-RECEIPT.md`).
- **R-devel:** submitted from HEAD (`check_win_devel`) + fixed tarball curl OK.
- **R-release:** FTP **550** while a same-name upload is queued; an earlier curl
  accidentally sent the *stale* morning tarball (9817096). Re-upload the fixed
  tarball after that queue clears — commands in the receipt.


## Next

1. Re-submit win-builder R-release + R-devel; require Status without ERROR.
2. Finish valgrind adjudication if still pending.
3. Only then advance ledger `status_claim` → `platform-clean`.
4. **STOP** before DESCRIPTION 0.7.0 bump / CRAN upload.

### Retry note (2026-08-07 ~20:16 UTC)

Fixed tarball R-release curl still **FTP 550**. Highest proven rung remains **`tarball-clean`**. No `platform-clean` claim.

## Blackout update 2026-08-07T23:00Z

**Still NOT READY for `platform-clean`.** Highest proven rung remains
`tarball-clean`.

- CondExp path repair is on `main` via #941 (`13e8cafb0`).
- Fixed win-builder tarball re-uploaded successfully to **both** R-release and
  R-devel (FTP 226; SHA-256 `f9b9588e…`, size 9818425).
- Prior morning ERROR receipts (`XhAiv0jf1AUd`, `nF44JzoI2nZ9`) remain the last
  adjudicated results; they used the unrepaired layout.
- **Await** new win-builder result emails for the fixed tarball. Do not advance
  the ledger without ERROR-free evidence **and** explicit owner authorization.
- CRAN submit UI offline until ~2026-08-19 — no CRAN upload. DESCRIPTION stays
  **0.6.0**.

