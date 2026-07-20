## Submission summary

This is a new submission of drmTMB, a package for fast distributional
regression models (univariate and bivariate) built on Template Model Builder
(TMB).

## R CMD check results

`R CMD check --as-cran` on local macOS (R 4.6.0): 0 errors | 0 warnings | 1 note.

The note is:

* **New submission.** This is the first CRAN submission of the package.

CRAN's own build machines may additionally report an **installed size** note: the
installed package is ~25 Mb, of which ~13 Mb is the compiled TMB C++ in `libs/`.
The C++ holds the automatic-differentiation likelihood templates that the
package's speed depends on; the size is intrinsic to TMB-based packages (the same
pattern as the existing CRAN package `glmmTMB`) and cannot be reduced without
removing functionality.

## Submission notes

* DESCRIPTION quotes the method name 'Tweedie' and hyphenates "semi-continuous"
  to resolve the two possible-spelling flags.
* Routine CRAN check time is bounded by keeping the exhaustive Phase 18
  simulation/reporting harness, its generated ~22,000-assertion conversion
  audit, and two high-dimensional diagnostics in the package's non-CRAN test
  lane (run in repository CI with `NOT_CRAN=true`). Fast unit, likelihood, API,
  malformed-input, extractor, and representative recovery tests run in the
  routine CRAN suite.

## Test environments

* local macOS (aarch64-apple-darwin), R 4.6.0 — `R CMD check --as-cran`
  (0 errors | 0 warnings | 1 note, the new-submission note only), plus a local
  clang UBSAN compile of the compiled TMB C++.

Cross-platform confirmation is a separate step completed immediately before
upload and is not yet reflected above: the GitHub Actions ubuntu/macOS/windows
matrix, win-builder (R-release and R-devel), and R-hub v2 (including the
gcc/clang UBSAN and valgrind/rchk configurations relevant to the compiled TMB
C++) are run and their logs recorded here before submission.

## Reverse dependencies

This is a new package; there are no reverse dependencies.

## Notes for the CRAN team

* `JuliaCall` is a Suggested dependency only. It powers an optional,
  experimental `engine = "julia"` back end. All tests that would invoke it are
  guarded with `skip_if_not_installed()` and additionally require a local
  development checkout of the (not-yet-registered) companion Julia package, so
  they are skipped on CRAN. The default and only required engine is the
  bundled TMB code.
