# win-builder resubmit receipt (2026-08-07)

- **source_head:** `25e38cc743d0422d3292063aeaa41a25d5772f87`
- **tarball:** `drmTMB_0.6.0.tar.gz` rebuilt after CondExp path repair
- **SHA-256:** `f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`
- **size:** 9818425 bytes (differs from frozen probe 9817096)
- **Contains repair:** `drm_src_candidates` present in
  `tests/testthat/test-guard-branch-continuity.R` inside the tarball.

## Submit status

| Target | Method | Status |
| --- | --- | --- |
| R-devel | `devtools::check_win_devel()` from HEAD `25e38cc74` | **submitted** (email ETA ~14:24 MDT); see `winbuilder-devel-resubmit.log` |
| R-release | `devtools::check_win_release()` | FTP **550** |
| R-release | curl of **stale** morning tarball (9817096) | **accidentally uploaded** earlier — may re-ERROR |
| R-release | curl of **fixed** tarball (9818425) after rebuild | see retry logs below |
| R-devel | curl of fixed tarball | see retry logs below |

## Exact re-submit commands (Shinichi)

From worktree `~/local-scratch/worktrees/drmTMB-07-platform` on `cursor/07-platform-clean`:

```sh
cd ~/local-scratch/worktrees/drmTMB-07-platform
git checkout cursor/07-platform-clean
git pull
R_PROFILE_USER=/dev/null R CMD build .
# prove repair is inside:
tar -xOf drmTMB_0.6.0.tar.gz drmTMB/tests/testthat/test-guard-branch-continuity.R | grep drm_src_candidates
curl -T drmTMB_0.6.0.tar.gz ftp://win-builder.r-project.org/R-release/ --user anonymous:itchyshin@gmail.com
curl -T drmTMB_0.6.0.tar.gz ftp://win-builder.r-project.org/R-devel/ --user anonymous:itchyshin@gmail.com
# or:
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::check_win_release(); devtools::check_win_devel()'
```

If FTP returns **550**, wait until the previous same-name upload leaves the
queue (or until its result email arrives), then retry the **fixed** tarball
only — do not re-upload the frozen probe SHA `c787ee40…` (9817096 bytes).

## Retry log excerpts
### R-release
30:> STOR drmTMB_0.6.0.tar.gz
31:< 550 
32:* Failed FTP upload: 550
37:curl: (25) Failed FTP upload: 550
### R-devel
30:> STOR drmTMB_0.6.0.tar.gz
35:< 226 Transfer complete.

## Retry 2026-08-07T20:16Z (Cursor handover resume)

- Fixed tarball still present: size **9818425**, SHA-256 `f9b9588e…`, contains `drm_src_candidates`.
- R-release FTP **still 550** (`winbuilder-release-resubmit-retry.log`). Queue not clear yet.
- Do **not** advance `platform-clean`. Wait for prior same-name upload result email, then upload fixed tarball only.

## Retry 2026-08-07T23:00Z (blackout must-do)

- Fixed tarball verified in place: size **9818425**, SHA-256
  `f9b9588e31c15040ad6b4b4eafa7ffeb1e7eb64a2379d1a6a3859670109a8065`.
- Proven inside tarball: `drm_src_candidates` /
  `drm_src_path` in `drmTMB/tests/testthat/test-guard-branch-continuity.R`.
- **R-release FTP: 226 Transfer complete** (`winbuilder-release-resubmit-retry2.log`).
- **R-devel FTP: 226 Transfer complete** (`winbuilder-devel-resubmit-retry2.log`).
- Do **not** re-upload stale morning tarball `c787ee40…` / 9817096.

## Adjudication 2026-08-07T~24:00Z (Gmail MCP)

Result emails for the fixed upload (thread `19fdd3b95ebe5f0b`):

| Flavor | URL | Status | CondExp ERROR |
| --- | --- | --- | --- |
| R-devel | https://win-builder.r-project.org/qS15UqA2O00A | **1 NOTE** | cleared |
| R-release | https://win-builder.r-project.org/BQVnXOH066rJ | **1 NOTE** | cleared |

Logs: `winbuilder-devel-fixed-00check.log`,
`winbuilder-release-fixed-00check.log`. Full table:
`winbuilder-emails.md`.

**Ledger still `tarball-clean`.** ERROR-free evidence is ready for owner
authorize of `platform-clean`; do not write that claim without owner word.

