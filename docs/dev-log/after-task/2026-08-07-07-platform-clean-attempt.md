# After-task: drmTMB 0.7 platform-clean attempt (NOT READY)

**Reader:** next CRAN-lane agent / Shinichi.
**Purpose:** record the platform matrix run Shinichi authorized, and the honest
block that keeps the proven rung at `tarball-clean`.

## What ran

Worktree `~/local-scratch/worktrees/drmTMB-07-platform` on `cursor/07-platform-clean`
from `origin/main` @ `744b9fbe` (`.Rbuildignore` contains `^LOOP$`; DESCRIPTION
still 0.6.0). Frozen probe SHA re-verified:
`c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`.

1. **GHA 3-OS** via `workflow_dispatch` on `R-CMD-check.yaml` → run
   [31195187084](https://github.com/itchyshin/drmTMB/actions/runs/31195187084):
   ubuntu / macOS / windows all **success** (46.5 / 31.7 / 58.8 min; all under
   the 75-minute ceiling). Concurrent ubuntu-only push run 31194260935 was
   cancelled by concurrency — pacing, not a fail.
2. **win-builder** `devtools::check_win_release` + `check_win_devel` → both
   **Status: 1 ERROR, 1 NOTE**
   ([release](https://win-builder.r-project.org/XhAiv0jf1AUd),
   [devel](https://win-builder.r-project.org/nF44JzoI2nZ9)).
3. **R-hub** `clang-asan,clang-ubsan,gcc-asan,valgrind,rchk` → run
   [31195195196](https://github.com/itchyshin/drmTMB/actions/runs/31195195196):
   ASAN/UBSAN/gcc-ASAN **OK**; rchk job red but adjudicated **NOISE** (TMB
   headers); valgrind long-running at close of this report.

## Blocking finding

`test-guard-branch-continuity.R` cannot locate `src/drmTMB.cpp` under
win-builder's `R CMD check` paths (`../../src` and `../../00_pkg_src/...`).
FAIL 1 / PASS 15427. Local macOS `--as-cran` freeze did not surface this.
See `docs/dev-log/release/0.7.0-cran-gate/platform/PLATFORM-NOT-READY.md`.

## Ledger / gate

`status_claim` remains **`tarball-clean`**. Platform evidence files are under
`docs/dev-log/release/0.7.0-cran-gate/platform/` for the repair lane; they do
**not** license a platform-clean claim.
`python3 ~/shinichi-brain/tools/cran_release_gate.py` → READY FOR CLAIMED RUNG
at `tarball-clean`.

## Fences held

No CRAN upload. No DESCRIPTION 0.7.0 bump. No AGHQ / missing-data / #858 / #893
/ #869. Primary checkout untouched.

## Highest proven rung

`tarball-clean`. **Next = repair win-builder CondExp source-path guard, then
re-run win-builder (+ finish valgrind), then re-evaluate platform-clean.**
Submission-ready still needs owner.
