# Platform-clean status — drmTMB 0.7.0 candidate `302ac2579`

**2026-08-16 · Julia skip fix on `cursor/070-winbuilder-julia-skip` · Cursor.**
**Reader:** Shinichi. **Verdict: `platform-clean` is still NOT READY.** The Ligges R-release and R-oldrelease ERRORs are explained and patched on this branch. They are not re-proven. No CRAN submit. No Ligges email. No rung advance. No merge claiming platform-clean.

The NOTE on both Ligges hosts is CRAN incoming feasibility (New submission + DESCRIPTION words *centile*, *misspecification*, *uncalibrated*). It is not a GNU-make NOTE. A NOTE-only log does not make the platform matrix clean.

## Fix landed here (not yet re-uploaded)

Branch `cursor/070-winbuilder-julia-skip` from freeze `302ac2579`:

1. CRAN-lane invert filter in `tests/testthat.R` now includes `^julia`, so every `test-julia-*.R` file is excluded when `NOT_CRAN` is unset. `NOT_CRAN=true` still runs the full suite.
2. Live JuliaCall tests call `drm_skip_live_julia()` (skip on CRAN unless `DRMTMB_JULIA_TESTS=true`). Cheap R tests in `test-xfam-bridge.R` stay on the CRAN lane.

This does **not** re-freeze the candidate and does **not** make `platform-clean` READY. The next proof is a new tarball from this branch, then win-builder R-release + R-oldrelease of those new bytes.

## 2026-08-16 Ligges ERROR (R-release + R-oldrelease)

Frozen bytes that ERROR'd: commit `302ac2579969f7d5f949a73610468c9f73f938c8`, SHA-256 `0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`. Prior R-devel at https://win-builder.r-project.org/84RS0Yqy5t0Y was **1 NOTE** only, tests `[13m] OK`.

| Host | Label | URL | Tests | Status |
| --- | --- | --- | --- | --- |
| `qdiOL4tO0suj` | R-release 4.6.1 (2026-06-24 ucrt) | https://win-builder.r-project.org/qdiOL4tO0suj | `[105m] ERROR` | 1 ERROR, 1 NOTE |
| `GXMxAgB00l1C` | R-oldrelease 4.5.3 (2026-03-11 ucrt) | https://win-builder.r-project.org/GXMxAgB00l1C | `[149m] ERROR` | 1 ERROR, 1 NOTE |

Both `testthat.Rout.fail` files end at `JuliaCall::julia_setup()` with no testthat Failure block. Extract: `docs/dev-log/research/winbuilder-2026-08-16/FAILURE-EXTRACT.md` on the collect lane.

## Next human action

Rebuild the tarball from this branch (or from freeze + this patch). Upload the **new** tarball to win-builder R-release and R-oldrelease. Do not re-upload the frozen `0d150ef3…` bytes. Do not submit_cran. Do not email Ligges. Keep `status_claim` at `tarball-clean` until those new logs are clean.
