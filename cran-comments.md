## Submission summary

This is a new submission of drmTMB, a package for fast distributional
regression models (univariate and bivariate) built on Template Model Builder
(TMB).

## R CMD check results

`R CMD check --as-cran` on local macOS (R 4.5.2): 0 errors | 0 warnings | 2 notes.

The two notes are:

* **New submission.** This is the first CRAN submission of the package.

* **Installed size.** The installed package is ~25 Mb, of which ~13 Mb is the
  compiled TMB C++ in `libs/`. The C++ holds the automatic-differentiation
  likelihood templates that the package's speed depends on; the size is
  intrinsic to TMB-based packages (the same pattern as the existing CRAN
  package `glmmTMB`) and cannot be reduced without removing functionality.

## Test environments

* local macOS (aarch64-apple-darwin), R 4.5.2 — `R CMD check --as-cran`, clean.

## Reverse dependencies

This is a new package; there are no reverse dependencies.

## Notes for the CRAN team

* `JuliaCall` is a Suggested dependency only. It powers an optional,
  experimental `engine = "julia"` back end. All tests that would invoke it are
  guarded with `skip_if_not_installed()` and additionally require a local
  development checkout of the (not-yet-registered) companion Julia package, so
  they are skipped on CRAN. The default and only required engine is the
  bundled TMB code.
