# 3-OS matrix — candidate `302ac2579` (run 31908830334)

**2026-08-15 · `workflow_dispatch` on branch `candidate-302ac2579`, whose tip IS the candidate's
source commit — so head SHA = `302ac2579969f7d5f949a73610468c9f73f938c8`, exact-commit evidence.**

Run: https://github.com/itchyshin/drmTMB/actions/runs/31908830334

| job | conclusion | note |
| --- | --- | --- |
| os-matrix (fan-out) | success | full matrix selected via `workflow_dispatch` |
| ubuntu-latest (release) | **success** | on rerun — the first attempt was **cancelled by the workflow's own `timeout-minutes: 75`** on a slow runner (75 min vs the 46.5-min historical norm), with zero check findings before the cut; rerun completed green |
| windows-latest (release) | **success** | first attempt |
| macos-latest (release) | **success** | first attempt |

## Provenance caveat

GitHub Actions builds its own tarball from the source checkout: this is **same-commit, not
same-bytes** evidence relative to the frozen artifact `0d150ef3…`. The exact-bytes classes for
this candidate are the local `--as-cran` and the Totoro valgrind subset. The Windows job also
runs with `NOT_CRAN=true` (the full test lane, larger than the CRAN lane) — which makes its green
*stronger* than a CRAN-lane pass on test coverage, while still not measuring the Windows
CRAN-lane timing; that number only win-builder can produce.

## Platform-matrix status for the ledger

With this run, every self-serve platform class for the candidate is green or adjudicated:
3-OS ✅ · clang-ubsan ✅ (incl. vignettes) · gcc-asan ✅ · clang-asan (no findings; quirk
adjudicated) · rchk (noise, re-confirmed) · valgrind exact-bytes subset ✅.
**Absent and still owed: win-builder** — the `external_logs` class, Shinichi's action.
