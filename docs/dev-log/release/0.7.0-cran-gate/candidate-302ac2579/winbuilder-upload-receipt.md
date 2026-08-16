# win-builder upload receipt — candidate `302ac2579`

**2026-08-16 00:06 UTC · authorised by Shinichi ("Let's go", in direct response to the win-builder
step being presented as the one pending action) · uploaded by Claude via FTP (the exact-bytes
route; `devtools::check_win_*` is not used because it rebuilds from source).**

| | |
| --- | --- |
| File | `/Users/z3437171/drmTMB-release-artifacts/0.7.0-302ac2579/drmTMB_0.7.0.tar.gz` |
| SHA-256, recomputed immediately before upload | `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075` |
| Size | 10,087,906 bytes |
| R-release upload | `ftp://win-builder.r-project.org/R-release/` — OK at **2026-08-16T00:06:40Z** |
| R-devel upload | `ftp://win-builder.r-project.org/R-devel/` — OK at **2026-08-16T00:06:43Z** |
| R-oldrelease upload | `ftp://win-builder.r-project.org/R-oldrelease/` — OK at **2026-08-16T00:49:55Z** |

Results are expected by email to `itchyshin@gmail.com` within ~30–60 minutes per lane. Expected:
`Status: 1 NOTE` (New submission). The `checking tests` timing in the reply is the one number no
other platform class can measure (the GHA Windows job runs the larger `NOT_CRAN=true` lane).
Result files will be saved here as `winbuilder-release.txt` / `winbuilder-devel.txt` and entered
in the ledger as `external_logs`.

An upload receipt proves the **submitted** state of the win-builder service only — it is not a
check result, and no rung moves on it.
