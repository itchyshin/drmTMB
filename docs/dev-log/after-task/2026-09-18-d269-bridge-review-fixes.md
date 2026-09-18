# D-269 bridge review fixes — after-task report

## 1. Goal

Correct concrete D-269 bridge review findings without overlapping the open
help/documentation lanes, and record the actual limits of the live evidence.

## 2. Implemented

- Made the G5 formula fidelity probe query `drmTMB_backend`, the module the
  selected-checkout loader actually binds.
- Made the clean relmat child set `drmTMB.DRModels.jl.path`, which has the
  intended canonical precedence over inherited legacy settings.
- Updated the location-scale vignette's Julia tutorial name and Pages URL to
  DRModels.jl.

## 3a. Decisions and Rejected Alternatives

Did not edit `R/drmTMB.R` or `man/drmTMB.Rd`: open PRs #1110 and #1111 own
those paths, and their reconciliation remains an explicit #1381 hold.  Did
not delete or rebuild Julia caches after the Julia-1.10 dependency conflict;
the matching Julia-1.13 probe supplied bounded evidence without mutating the
environment.

## 4. Files Touched

- `tests/testthat/test-julia-formula-constructs.R`
- `tests/testthat/test-julia-structured.R`
- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.d/2026-09-18-d269-bridge-review-fixes.md`
- `docs/dev-log/after-task/2026-09-18-d269-bridge-review-fixes.md`

## 5. Checks Run

- `devtools::test(filter = "julia-formula-constructs")` PASSed with all
  non-live cells green; seven live cells skipped when no checkout was set.
- `devtools::test(filter = "julia-structured")` PASSed with non-live cells
  green; one live relmat cell skipped when no checkout was set.
- A canonical-path precedence assertion PASSed with a deliberately conflicting
  `DRMODELS_JL_PATH`.
- A Julia-1.13 fresh-process setup loaded `drmTMB_backend` as `DRModels`.
- `knitr::knit("vignettes/location-scale.Rmd", output = tempfile(...))` and
  `git diff --check` PASSed.

## 6. Tests of the Tests

The old formula probe named `DRM` directly, which would error after a selected
DRModels checkout.  The corrected probe names `drmTMB_backend`; the fresh
Julia-1.13 setup demonstrates that this binding resolves to `DRModels`.
The canonical-precedence assertion deliberately supplied a conflicting
environment path and verified that the configured selected checkout still won.

## 7a. Issue Ledger

This is a corrective addendum to open draft PR #1381.  It does not close an
issue, merge a PR, publish a package, or remove #1381's reconciliation hold on
#1110/#1111.

## 8. Consistency Audit

Searched the sibling formula and structured test paths for the same
selected-checkout assumption.  The two concrete cases were corrected.  The
location-scale vignette was the stale public Pages link found in the review.
The R help and generated Rd finding was verified but held because those paths
are owned by open documentation lanes.

## 9. What Did Not Go Smoothly

Running a test file directly bypassed package loading and produced irrelevant
missing-symbol failures; rerunning through `devtools::test()` was clean.  A
Julia-1.10 live attempt reached the renamed checkout but failed before bridge
assertions from mixed JuliaCall/default-environment and checkout-manifest
dependencies.  The matching Julia-1.13 live probe succeeded.

## 10. Known Residuals

The broad compatibility question raised by activating the selected project
after JuliaCall starts needs a dedicated design decision: current CI is
mock-driven and has no Julia engine.  The public `?drmTMB` help wording remains
for #1110/#1111 to reconcile.  PR #1381 remains draft and unmerged; no release
or Pages deployment was performed.

## 11. Team Learning

For a dynamically selected Julia package, test probes must use the loader's
backend binding, never a historical module literal.  A fresh runtime matching
the selected checkout's manifest is necessary evidence, but it is not proof
that mixed JuliaCall/backend dependency environments are compatible.

## 12. Cross-Product Coverage

This covers ✓ the selected-backend formula probe, isolated relmat checkout
precedence, and the location-scale reader link.  It does NOT cover the
JuliaCall/project-activation compatibility design, all public R help, release
readiness, public Pages deployment, or a merge.
