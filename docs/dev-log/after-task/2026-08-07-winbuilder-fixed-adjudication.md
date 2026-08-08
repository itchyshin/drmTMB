# After-task: win-builder fixed-tarball adjudication (still tarball-clean)

**Reader:** Shinichi / next CRAN-lane agent.
**Purpose:** record ERROR-free win-builder results for the CondExp-repaired
tarball without advancing the release ledger claim.

## What was adjudicated

Fixed tarball SHA-256
`f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`
(size 9818425), FTP 226 to R-release and R-devel ~2026-08-07T23:00Z.

Gmail MCP search (`from:ligges` / win-builder / drmTMB, thread
`19fdd3b95ebe5f0b`) distinguished morning ERROR runs from the fixed pair:

| Flavor | URL | Status | CondExp ERROR |
| --- | --- | --- | --- |
| R-devel | https://win-builder.r-project.org/qS15UqA2O00A | 1 NOTE | cleared |
| R-release 4.6.1 | https://win-builder.r-project.org/BQVnXOH066rJ | 1 NOTE | cleared |

NOTE only: New submission; DESCRIPTION spellings; `function-map-cheatsheet.png`
URI. Tests OK on both flavors.

## Ledger / fences

- `status_claim` remains **`tarball-clean`** in
  `docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json`
  (not rewritten).
- DESCRIPTION remains **0.6.0**.
- No CRAN upload.
- Ask for owner: authorize `platform-clean` claim (or withhold for valgrind /
  other review); separately authorize DESCRIPTION 0.7.0 / submit.

## Artifacts

Under `docs/dev-log/release/0.7.0-cran-gate/platform/`:
`winbuilder-emails.md`, `PLATFORM-NOT-READY.md`,
`winbuilder-release-fixed-00check.log`, `winbuilder-devel-fixed-00check.log`.
PR #945 on `cursor/07-winbuilder-adjudicate`.

Updated: 2026-08-08T00:25Z (CI re-trigger after cancel stale/full-matrix runs).
