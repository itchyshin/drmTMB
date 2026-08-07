# Platform-clean dispatch receipts (2026-08-07)

## GitHub Actions 3-OS (`workflow_dispatch`)

- Run: https://github.com/itchyshin/drmTMB/actions/runs/31195187084
- Ref: `main` @ `744b9fbeec226784fa0b94f27e63bf121f31bed7`
- Event: `workflow_dispatch` (full ubuntu + macOS + windows matrix)
- Note: superseded in-progress ubuntu-only push run 31194260935 (cancelled by concurrency; cancelled ≠ fail)

## R-hub (`workflow_dispatch`)

- Run: https://github.com/itchyshin/drmTMB/actions/runs/31195195196
- Config: `clang-asan,clang-ubsan,gcc-asan,valgrind,rchk`
- Ref: `main` @ `744b9fbe`

## win-builder

- R-release + R-devel submitted via `devtools::check_win_release` / `check_win_devel`
- Results email: itchyshin@gmail.com (ETA ~10:32–10:36 AM MDT 2026-08-07)
- See `winbuilder-*-submit.log`
