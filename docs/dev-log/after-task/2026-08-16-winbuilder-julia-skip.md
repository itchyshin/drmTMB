# After Task: Exclude live Julia tests from the CRAN lane

**2026-08-16 · Cursor · lane `cursor/070-winbuilder-julia-skip` from freeze `302ac2579`**

## Goal

Stop the Ligges win-builder ERROR on drmTMB 0.7.0. Both R-oldrelease (`GXMxAgB00l1C`, 4.5.3) and R-release (`qdiOL4tO0suj`, 4.6.1) hung inside `JuliaCall::julia_setup()` for 149 / 105 minutes. There was no testthat Failure block. `JuliaCall` is Suggests, so `skip_if_not_installed()` does not skip when those hosts have Julia 1.11.3.

## Implemented

The CRAN invert filter in `tests/testthat.R` now includes `^julia`. testthat matches that pattern against the stem after stripping `test-` and `.R`, so every `test-julia-*.R` file is excluded when `NOT_CRAN` is unset. `NOT_CRAN=true` still calls `test_check("drmTMB")` with no filter.

Live JuliaCall tests call `drm_skip_live_julia()`, which skips on CRAN unless `DRMTMB_JULIA_TESTS=true`. Cheap R tests in `test-xfam-bridge.R` stay on the CRAN lane.

This is a test-lane skip, not a re-freeze and not a `platform-clean` claim.

## Files created or changed

- `tests/testthat.R` — add `^julia` to the CRAN invert filter
- `tests/testthat/helper-julia-bridge-path.R` — add `drm_skip_live_julia()`
- `tests/testthat/test-xfam-bridge.R` — live tests call the helper
- `tests/testthat/test-julia-*.R` live sites — same helper (defense if a file is sourced directly)
- `tests/testthat/test-cran-lane-filter.R` — filter contract + helper behaviour
- `docs/dev-log/research/2026-08-16-platform-clean-status.md` — still NOT READY
- `docs/dev-log/research/2026-08-16-winbuilder-reupload-after-julia-skip.md` — rebuild + re-upload steps
- `docs/dev-log/after-task/2026-08-16-winbuilder-julia-skip.md` — this report
- `docs/dev-log/check-log.md` — this slice

## Checks run and exact outcomes

| Check | Result |
| --- | --- |
| `devtools::test(filter = "^cran-lane-filter$")` with `NOT_CRAN=true` | FAIL 0 / SKIP 0 / PASS 11 |
| Invert simulation of the CRAN filter | 16/16 `test-julia-*.R` stems excluded; `xfam-bridge` and `cran-lane-filter` kept |
| `devtools::test(filter = "cran-lane-filter\|xfam-bridge\|julia-home-path\|julia-bridge")` with `NOT_CRAN=true` | FAIL 0 / SKIP 5 / PASS 191 (xfam live skips are missing DRM.jl, not the CRAN helper) |
| `devtools::test(filter = "^xfam-bridge$\|^cran-lane-filter$")` with `NOT_CRAN=false` | FAIL 0 / SKIP 4 / PASS 65 — four live xfam tests skip `On CRAN`; cheap R tests still run |

## Consistency audit

`rg` on this branch: no `meta_gaussian`, no `tau ~`, no `rho ~` as a residual-correlation formula, no new public syntax. Status inventory (`README.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`) was not rewritten: user-facing Julia support is unchanged. The CRAN lane no longer *tests* live Julia on win-builder.

## Tests of the tests

`test-cran-lane-filter.R` fails if `"^julia"` leaves the invert filter, if a `test-julia-*.R` stem would not match `^julia`, or if `drm_skip_live_julia()` stops skipping when `NOT_CRAN` is unset. A negative check asserts `xfam-bridge` and `cran-lane-filter` are not excluded by `^julia`.

## What did not go smoothly

`.worktrees/cran-07` is the collect lane (`cursor/070-winbuilder-collect`). This fix used a new worktree so those untracked Ligges extracts were not mixed into the patch. Historical 0.5.0 pretest branches also touch `tests/testthat.R`; they only exclude `phase18|structured-re-conversion-contracts` and are not this skip.

## Team learning

`skip_if_not_installed("JuliaCall")` is not a CRAN skip when JuliaCall is Suggests and the check host has Julia. Invert-filter the file stem.

## Design-doc updates

None. Formula grammar and likelihoods are unchanged.

## pkgdown / documentation updates

None. No exported function changed.

## GitHub issue maintenance

No open issue named this Ligges hang. Left the tracker unchanged rather than opening a duplicate of the win-builder collect notes.

## Known limitations and next actions

`platform-clean` stays NOT READY until Shinichi rebuilds the tarball from this branch and re-uploads it to win-builder R-release and R-oldrelease. Do not submit_cran. Do not email Ligges. Do not merge claiming the platform matrix is clean. The incoming-feasibility NOTE (*centile*, *misspecification*, *uncalibrated*) is expected and is not GNU make.
