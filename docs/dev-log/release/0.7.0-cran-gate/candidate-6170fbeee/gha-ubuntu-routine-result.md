# Exact-head routine Ubuntu result

- Run: <https://github.com/itchyshin/drmTMB/actions/runs/32204506090>
- Event: push of merged `main`
- Head SHA: `6170fbeeea65f22444d7b0934f4e808c40744d22`
- Job: `ubuntu-latest (release)`
- Job conclusion: `success`
- Started: `2026-08-19T01:19:29Z`
- Completed: `2026-08-19T02:05:59Z`

This is a **same-source, full-repository** `NOT_CRAN=true` check, not an
exact-byte CRAN-lane check. It retained the exhaustive repository suite and
reported `FAIL 0 | WARN 67 | SKIP 314 | PASS 21012`.

`R CMD check` completed with 0 errors, 0 warnings, and 2 notes:

1. the full test suite exceeded the check-time threshold (`46m` elapsed / `29m`
   reported); and
2. two Julia temporary directories remained in the runner's check directory.

Those notes belong to the deliberately exhaustive repository lane. They do not
replace or broaden the exact immutable tarball's `NOT_CRAN=false` result, whose
selected CRAN test lane completed in 45 seconds elapsed / 54 seconds reported
without check-directory detritus. This Ubuntu run is supporting regression
evidence only and is not used by itself to claim `platform-clean`.

Archived raw evidence:

- `gha-ubuntu-routine-run.json`
- `gha-ubuntu-routine-job.log`
