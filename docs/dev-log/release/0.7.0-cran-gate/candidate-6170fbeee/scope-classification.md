# Release-lane classification — 2026-08-18/19

This classification reconciles the historical Ligges handoff with the selected
current-main candidate. `DONE` means the named evidence task is complete; it
does not promote a superseded artifact.

| Item | Classification | Evidence / boundary |
| --- | --- | --- |
| File `5153ae7e…` R-devel | **DONE** | `MunJ44aZB7BQ`; R-devel r90424; 1 NOTE; raw output `FAIL 0 · WARN 99 · SKIP 143 · PASS 11403` |
| File `5153ae7e…` R-release | **DONE** | `qOBUstEvxol1`; R 4.6.1; 1 NOTE; raw output `FAIL 0 · WARN 53 · SKIP 143 · PASS 11379` |
| File `5153ae7e…` R-oldrelease | **DONE** | `T2LOH4zOG6WT`; R 4.5.3; 1 NOTE; raw output `FAIL 0 · WARN 53 · SKIP 143 · PASS 11379` |
| Use `5153ae7e…` as final 0.7.0 candidate | **RETRACTED** | useful predecessor / Julia-hard-stop evidence only; it is not represented by the final ledger and differs from selected current main |
| Candidate `6b45164b…` platform ladder | **DONE** | local, 3-OS, R-hub, and three win-builder arms were archived under `candidate-5485ccb8a/` |
| Use `6b45164b…` as final 0.7.0 candidate | **RETRACTED** | fresh panel found shipped release-identity contradictions and excessive Windows CRAN-lane time; fixed in the next candidate |
| Freeze current-main candidate `1d6445db…` | **DONE** | clean source `6170fbeee…`; immutable 4,368,396-byte tarball; 946 entries; exact local CRAN lane green at 0 errors / 0 warnings / 1 expected NOTE |
| Exact-source R-hub diagnostics for `1d6445db…` | **DONE** | three sanitizers green; rchk retained red and adjudicated in `rhub-result.md` |
| Build-excluded handover PR #1073 | **DONE** | merged only after the real `ubuntu-latest (release)` job passed; see `handover-pr-1073-result.md` |
| CRAN extra checks for `1d6445db…` | **DONE** | metadata, README/install surface, export documentation, rights, URLs, and spelling adjudicated in `cran-extra-checks.md` |
| Exact-source full 3-OS matrix for `1d6445db…` | **DONE** | run `32207379448` succeeded on macOS, Ubuntu, and Windows; full developer-suite NOTEs retained in `gha-3os-result.md` |
| Exact-byte win-builder R-devel / R-release / R-oldrelease for `1d6445db…` | **DONE** | all three URLs, indexes, complete logs, raw test outputs, upload traces, versions, timestamps, and client-side custody are archived; every arm has `PASS 3501` |
| Final machine-readable ledger and executable gate | **DONE** at `platform-clean` | ledger `2026-08-19-070-cran-release-ledger-1d6445db.json` passes the executable gate; final promotion waits for the fresh panel |
| Fresh Grace / Rose / Pat panel | **OWED** | must review only the completed `1d6445db…` packet and current governance state |
| `submit_cran()` or any CRAN upload | **PROTECTED** | separate owner decision; not authorized here, and no submission on 19 August |
| PR #1033 | **PROTECTED** | never inspect, modify, merge, or use in this lane |
| `_julia_skip2_artifacts/` and foreign/dirty worktrees | **PROTECTED** | never stage, clean, delete, or use as final-candidate provenance |

All win-builder associations are client-side chains of custody. win-builder
does not attest the uploaded server-side SHA-256.
