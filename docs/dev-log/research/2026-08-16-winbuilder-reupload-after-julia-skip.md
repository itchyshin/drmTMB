# Re-upload after the win-builder Julia skip (Shinichi)

**Reader:** Shinichi. **Purpose:** the Ligges ERROR is patched on `cursor/070-winbuilder-julia-skip`. These are the steps to prove the new bytes, not a claim that they are already clean.

Do not submit_cran. Do not email Ligges. Do not re-upload the frozen `0d150ef3…` tarball that already ERROR'd.

## What changed

`tests/testthat.R` now invert-filters `^julia` on the CRAN lane. Live JuliaCall tests also call `drm_skip_live_julia()`. `NOT_CRAN=true` still runs the full suite.

## Rebuild

From a clean checkout of `cursor/070-winbuilder-julia-skip` after the PR commit is on the branch:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::build(path = ".")'
```

Record the new SHA-256 and byte size. They will differ from `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075` / 10,087,906 bytes.

## Upload

FTP the **new** `drmTMB_0.7.0.tar.gz` to win-builder:

- R-release
- R-oldrelease

R-devel was already 1 NOTE / tests OK on the old bytes (`84RS0Yqy5t0Y`). Re-upload devel only if you want a matching log for the new bytes.

## After the emails

File the verbatim Ligges bodies and `00check.log` files. `platform-clean` stays NOT READY until R-release and R-oldrelease are both ERROR-free on the new tarball. The incoming-feasibility NOTE (New submission + *centile* / *misspecification* / *uncalibrated*) is expected and is not GNU make.
