# Platform-clean — ERROR-free win-builder evidence; claim still tarball-clean

**Reader:** next CRAN-lane agent / Shinichi.
**Highest proven rung (ledger `status_claim`):** `tarball-clean`
  (unchanged — owner must authorize any `platform-clean` write).
**Frozen probe SHA:** `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
**Fixed win-builder tarball SHA:** `f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`
  (9818425 bytes; CondExp path repair inside).
**Source tip with repair on main:** `13e8cafb0` (#941).

## Verdict

**win-builder R-release + R-devel are ERROR-free on the fixed tarball**
(Status: **1 NOTE** each). The CondExp `drm_src_path` ERROR is **cleared**.

**Ledger claim remains `tarball-clean`.** Do **not** advance `status_claim` to
`platform-clean` without explicit owner authorization. DESCRIPTION stays
**0.6.0**. No CRAN upload.

This file keeps its historical filename so prior links resolve; the blocker
that made the first platform attempt NOT READY is resolved in evidence. The
*claim* is still gated on the owner.

## Matrix

| Cell | Result | Evidence |
| --- | --- | --- |
| GHA ubuntu-latest (release) | **success** (46.5 min < 75) | https://github.com/itchyshin/drmTMB/actions/runs/31195187084/job/92921623522 |
| GHA macos-latest (release) | **success** (31.7 min) | …/job/92921623507 |
| GHA windows-latest (release) | **success** (58.8 min < 75) | …/job/92921623453 |
| win-builder R-release 4.6.1 (**fixed**) | **1 NOTE** (0 ERROR) | https://win-builder.r-project.org/BQVnXOH066rJ · `winbuilder-release-fixed-00check.log` · email 2026-08-07T23:49:12Z |
| win-builder R-devel (**fixed**) | **1 NOTE** (0 ERROR) | https://win-builder.r-project.org/qS15UqA2O00A · `winbuilder-devel-fixed-00check.log` · email 2026-08-07T23:44:22Z |
| win-builder R-release (morning, unrepaired) | **1 ERROR, 1 NOTE** (superseded) | https://win-builder.r-project.org/XhAiv0jf1AUd · `winbuilder-release-00check.log` |
| win-builder R-devel (morning, unrepaired) | **1 ERROR, 1 NOTE** (superseded) | https://win-builder.r-project.org/nF44JzoI2nZ9 · `winbuilder-devel-00check.log` |
| R-hub clang-asan | **OK** | run 31195195196 |
| R-hub clang-ubsan | **OK** | run 31195195196 |
| R-hub gcc-asan | **OK** | run 31195195196 |
| R-hub rchk | job FAIL; **adjudicated NOISE** (TMB headers) | `rhub-rchk-adjudication.md` |
| R-hub valgrind | see poll log / incomplete at first write | job 92921626041 |

## CondExp ERROR — cleared on fixed tarball

Morning ERROR (`tests/testthat/test-guard-branch-continuity.R` could not locate
`src/drmTMB.cpp` under win-builder layout) is absent from both fixed
`00check.log` files: tests **OK**, Status **1 NOTE** only, no
`Cannot locate` / CondExp match.

Repair on `main` via #941 (`drm_src_candidates` / `drm_src_path`). Fixed
tarball receipt: `winbuilder-resubmit-RECEIPT.md`. Email adjudication:
`winbuilder-emails.md`.

## Remaining NOTE (submission-facing, not ERROR)

CRAN incoming feasibility on both flavors:

- New submission
- Possible DESCRIPTION spellings (`centile`, `mis`, `uncalibrated`)
- Possibly invalid file URI `function-map-cheatsheet.png` from
  `inst/doc/function-map-cheatsheet.html`

## Ask for Shinichi (owner)

1. Authorize advancing ledger `status_claim` → `platform-clean` (or withhold
   until valgrind is finished / other cells reviewed)?
2. After that (or separately): DESCRIPTION **0.7.0** bump and CRAN submit —
   still **STOP** until you say so. CRAN submit UI offline until ~2026-08-19.

Default until you answer: keep **`tarball-clean`**, DESCRIPTION **0.6.0**,
no upload.
