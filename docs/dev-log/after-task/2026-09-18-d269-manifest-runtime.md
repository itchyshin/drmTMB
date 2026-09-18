# D-269 selected-manifest runtime guard — after-task report

## 1. Goal

Turn the measured Julia-1.10 selected-manifest failure into a narrow,
actionable D-269 bridge diagnostic, without changing Julia runtime discovery,
dependency resolution, package identity, or public release state.

## 2. Implemented

- Added a Julia-side manifest inspection helper, called after `JuliaCall` has
  started its actual runtime and before `Pkg.activate()` reaches the selected
  DRModels.jl / DRM.jl checkout.
- Refused only manifest format `2.1` on Julia older than 1.13, with the
  selected manifest path and actual runtime in the error.
- Added a mocked regression test asserting that this case sends no activation
  or import command and leaves bridge setup unready.

## 3a. Decisions and Rejected Alternatives

Did not reject `julia_version` differences: that records the manifest's
generating runtime rather than a general package minimum.  Did not guess a
Julia executable before `JuliaCall::julia_setup()`, because JuliaCall's runtime
selection can differ from `PATH`.  Did not instantiate, rewrite, remove, or
substitute a manifest.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-module-compat.R`
- `docs/dev-log/check-log.d/2026-09-18-d269-manifest-runtime.md`
- `docs/dev-log/after-task/2026-09-18-d269-manifest-runtime.md`

## 5. Checks Run

- Red: the new focused test failed before implementation: no error, nine
  activation/import commands, and ready state incorrectly true.
- Green: `devtools::test(filter = "julia-module-compat")` PASSed: 47 pass,
  one expected live skip.
- Adjacent: `devtools::test(filter = "julia-bridge")` PASSed: 204 pass,
  three expected live skips, and two pre-existing `beta()` deprecation warnings.
- Live negative: Julia 1.10.0 stopped before selected-checkout activation with
  the new format-2.1 diagnostic.
- Live positive: Julia 1.13.0 activated the selected checkout and loaded
  `drmTMB_backend` as `DRModels`.
- `git diff --check` and `parse()` of the two changed R files PASSed.

## 6. Tests of the Tests

The new test first failed because no runtime guard existed.  Its mock returns
the actual boundary facts (format 2.1, Julia 1.10.0) and proves no
`Pkg.activate()`/import command follows.  The live negative and positive
fresh-process checks exercise the real JuliaCall boundary rather than only the
mocked path.

## 7a. Issue Ledger

This is an explicitly authorized corrective addendum to draft PR #1381.  It
does not close an issue, merge a PR, publish a package, deploy Pages, or alter
the #1110/#1111 reconciliation hold.

## 8. Consistency Audit

The guard uses Julia's own `project_file_manifest_path` resolver, retaining
legacy/canonical checkout parity and versioned-manifest precedence.  It rejects
only the documented format incompatibility, not all newer `julia_version`
values.  No public API name, formula surface, README, vignette, or generated
help text changed.

## 9. What Did Not Go Smoothly

The initial Julia-1.13 positive-control command supplied JuliaCall's parent
directory rather than its `bin` directory; JuliaCall failed before entering the
bridge.  The corrected executable path loaded `DRModels` successfully.  This
was a test-launch configuration mistake, not a bridge defect.

## 10. Known Residuals

This narrowly diagnoses one selected-manifest format incompatibility.  It does
not make arbitrary mixed JuliaCall/backend environments supported, and it does
not reconcile the #1110/#1111-owned public help paths.  PR #1381 remains draft
and unmerged; no release or stable Pages action was performed.

## 11. Team Learning

For a dynamically selected Julia backend, runtime compatibility must be
measured after JuliaCall starts, not inferred from shell discovery.  A manifest
format is a more precise compatibility signal than the manifest's generating
Julia version.

## 12. Cross-Product Coverage

This covers ✓ canonical selected-checkout loading on Julia 1.13 and ✓ a clear
early failure for the selected format-2.1 checkout on Julia 1.10.  It does NOT cover general Julia dependency isolation, a legacy checkout with that format,
all help/documentation reconciliation, merges, releases, registry work, or
stable Pages deployment.
