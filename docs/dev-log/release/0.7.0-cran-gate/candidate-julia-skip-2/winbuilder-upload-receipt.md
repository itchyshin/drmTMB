# win-builder upload receipt — julia-skip-2 (CRAN-lane Julia hard-stop)

**2026-08-18T00:36:29Z · Cursor · optional Ligges path · NOT a CRAN submission**

**Lane:** `cursor/070-julia-skip-winbuilder-fix` @ `eac1133b2`
(from `origin/main` `02b8fbe72`, post-#1068 tip).

## Why

#1061's `^julia` filter was insufficient. `test-binomial-response.R` still
called `engine = "julia"` after Workflow G admitted fixed-effect binomial,
so Ligges R-release hung in `JuliaCall::julia_setup()` on tarball
`8764b2fe…` (`v57uv6zakfKO`, ~10448s). This upload carries the hard-stop in
`drm_julia_setup()` plus the obsolete `expect_error` removal.

## Bytes

| | |
| --- | --- |
| File | `/tmp/drmTMB-0.7.0-julia-skip-2/drmTMB_0.7.0.tar.gz` (also under worktree `_julia_skip2_artifacts/`) |
| Size | 10,098,642 bytes |
| SHA-256 | `5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787` |
| Differs from | `8764b2fe…` (julia-skip-1) and freeze `0d150ef3…` |

## Uploads this session

| Lane | FTP target | Result |
| --- | --- | --- |
| R-oldrelease | `ftp://win-builder.r-project.org/R-oldrelease/` | **226 Transfer complete** |
| R-release | `ftp://win-builder.r-project.org/R-release/` | **550 on first try** (prior `drmTMB_0.7.0.tar.gz` likely still queued); retry exit=25 |

R-devel not uploaded.

## Explicit non-claims

No `submit_cran`. No Ligges email. No #1033. `platform-clean` not advanced.
