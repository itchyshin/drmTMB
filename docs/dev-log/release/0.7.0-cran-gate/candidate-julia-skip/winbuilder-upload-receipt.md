# win-builder upload receipt — post-#1061 julia-skip tarball

**2026-08-17T23:21Z · Cursor · optional Ligges path · NOT a CRAN submission**

**Lane:** `cursor/070-julia-skip-winbuilder-upload` from `origin/main` tip
`5108c9207` (#1061 already on main as `2f7403902`). Do **not** confuse with
the frozen candidate `302ac2579` / `0d150ef3…` bytes, which already ERROR'd on
R-release and R-oldrelease when live Julia hung.

## Why

#1061 skips live Julia on the CRAN lane (`tests/testthat.R` invert filter
`^julia` + `drm_skip_live_julia()`). Ligges hosts have Julia 1.11.3 and
Suggests `JuliaCall`, so `skip_if_not_installed("JuliaCall")` did not skip.
This upload tests the **new** exact bytes already sitting at
`~/drmTMB-release-artifacts/0.7.0-julia-skip/` — exact-bytes FTP route; no
`devtools::check_win_*` rebuild.

Shinichi authorised this optional path: FTP only; **no** `submit_cran`; **no**
Ligges email; **no** #1033.

## Bytes (immutable for this receipt — never rebuild here)

| | |
| --- | --- |
| File | `/Users/z3437171/drmTMB-release-artifacts/0.7.0-julia-skip/drmTMB_0.7.0.tar.gz` |
| Size | 10,089,274 bytes |
| SHA-256 expected | `8764b2febf1d01b0c8709f3b931cae5195373ae9e1b35939fd5e39c39f058212` |
| SHA-256 recomputed immediately before upload | `8764b2febf1d01b0c8709f3b931cae5195373ae9e1b35939fd5e39c39f058212` |
| Match | YES |

These bytes differ from freeze `302ac2579`
(`0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`,
10,087,906 bytes) by design.

## Uploads this session

| Lane | FTP target | UTC (curl finish) | curl exit | FTP reply | Post-upload listing |
| --- | --- | --- | --- | --- | --- |
| R-release | `ftp://win-builder.r-project.org/R-release/` | **2026-08-17T23:21:44Z** | 0 | 226 | `drmTMB_0.7.0.tar.gz` present |
| R-oldrelease | `ftp://win-builder.r-project.org/R-oldrelease/` | **2026-08-17T23:21:47Z** | 0 | 226 | `drmTMB_0.7.0.tar.gz` present |

R-devel was **not** uploaded (optional matching log only; prior devel result on
the old bytes already filed under `candidate-302ac2579/`).

Upload commands (exact-bytes):

```sh
curl -T ~/drmTMB-release-artifacts/0.7.0-julia-skip/drmTMB_0.7.0.tar.gz \
  ftp://win-builder.r-project.org/R-release/
curl -T ~/drmTMB-release-artifacts/0.7.0-julia-skip/drmTMB_0.7.0.tar.gz \
  ftp://win-builder.r-project.org/R-oldrelease/
```

## Explicit non-claims

- This receipt is **not** a check result. Wait for Ligges emails to
  `itchyshin@gmail.com`; do not invent Status / ERROR / NOTE lines here.
- `status_claim` stays `tarball-clean` until new R-release and R-oldrelease
  logs are filed and adjudicated.
- `platform-clean` is **not** advanced.
- Gate 7 panel is **not** run.
- CRAN submission remains **forbidden**.
- No email was sent to Ligges.
- PR **#1033** was not touched.

## Next (human / later session)

1. Collect Ligges result emails for R-release and R-oldrelease.
2. File verbatim bodies + `00check.log` beside this receipt.
3. Only then decide whether the julia-skip path cleared the Ligges hang.

See also: `docs/dev-log/research/2026-08-16-winbuilder-reupload-after-julia-skip.md`.
