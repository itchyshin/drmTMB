# win-builder upload receipt — julia-skip-2 (CRAN-lane Julia hard-stop)

**2026-08-18T00:44:00Z · Cursor · optional Ligges path · NOT a CRAN submission**

**Lane tip:** `cursor/070-julia-skip-winbuilder-fix` @ `d1827f1b9`
**Code fix:** `eac1133b2` (from `origin/main` `02b8fbe72`, post-#1068).

## Why

#1061's `^julia` filter was insufficient. Confirmed on hung Ligges run
[`v57uv6zakfKO`](https://win-builder.r-project.org/v57uv6zakfKO/):
`00check.log` truncates at `* checking tests ...`; `testthat.Rout` ends at
`Julia version 1.11.3 ... Loading setup script for JuliaCall...` **after**
printing a `<summary.drmTMB>` block and **while** the CRAN invert filter
already included `^julia`. Root leak: `test-binomial-response.R` still called
`engine = "julia"` inside `expect_error()`; Workflow G admits fixed-effect
binomial, so the call reached `JuliaCall::julia_setup()` (~10448s hang on
tarball `8764b2fe…`, 10,089,274 bytes).

This upload carries the hard-stop in `drm_julia_setup()` plus the obsolete
`expect_error` removal.

## Bytes (julia-skip-2)

| | |
| --- | --- |
| File | `/tmp/drmTMB-0.7.0-julia-skip-2/drmTMB_0.7.0.tar.gz` |
| Size | 10,098,642 bytes |
| SHA-256 | `5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787` |
| Differs from | `8764b2fe…` (julia-skip-1, 10,089,274 B) and freeze `0d150ef3…` |
| Code blob | `R/julia-bridge.R` matches `eac1133b2` (`07a2be5a…`) |

Tip rebuild `7f18f519…` (10,098,680 B) differs only in DESCRIPTION Packaged
date + vignette HTML timestamps; same hard-block code. FTP used `5153ae7e…`.

## Uploads

| Lane | FTP target | Result |
| --- | --- | --- |
| R-oldrelease | `ftp://win-builder.r-project.org/R-oldrelease/` | **226** earlier this session; later re-STOR **550** (queue occupied) |
| R-release | `ftp://win-builder.r-project.org/R-release/` | **550** — listing still shows prior julia-skip-1 `drmTMB_0.7.0.tar.gz` at **10,089,274** bytes (`8764b2fe…`) |
| R-devel | `ftp://win-builder.r-project.org/R-devel/` | **226 Transfer complete** (2026-08-18T00:43Z, `5153ae7e…`) |

Retry R-release/R-oldrelease after the queued julia-skip-1 job clears (or after
Ligges finishes processing the 10,089,274-byte file).

### Gap-fill reuploads

The exact `5153ae7e…` tarball was hash-verified again immediately before these
uploads:

| Lane | UTC interval | curl exit | Server response | Transfer time |
| --- | --- | ---: | ---: | ---: |
| R-release | 2026-08-18T11:53:23Z–11:53:26Z | 0 | **226 Transfer complete** | 3.258620 s |
| R-oldrelease | 2026-08-18T11:53:26Z–11:53:29Z | 0 | **226 Transfer complete** | 3.086274 s |

Each transfer uploaded 10,098,642 bytes. FTP `226` is an upload receipt, not a
Ligges check result; no new result email had been reported when these receipts
were filed.

## Local prove (this lane)

- Non-interactive `NOT_CRAN=false`: `drm_julia_setup()` aborts with CRAN-lane
  message before JuliaCall.
- Same env: `drmTMB(..., family=binomial(), engine="julia")` aborts with that
  message (not a hang).
- `mspl` / `biv_student` still early-abort with engine gates (never JuliaCall).
- `test-cran-lane-filter.R`: 20/20 under `NOT_CRAN=false`.
- Invert filter: 0 `test-julia-*` files remain on the CRAN lane.

## Explicit non-claims

No `submit_cran`. No Ligges email. No #1033. `platform-clean` not advanced.
