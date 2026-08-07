## Submission summary

This is a **planned** first CRAN submission of drmTMB (target version **0.7.0**).
The package is still on the `0.6.0` development cycle in `DESCRIPTION` and is
**not** being uploaded in this readiness slice. These comments will be finalised
against the frozen `0.7.0` tarball immediately before upload.

## R CMD check results

Post-merge GitHub Actions on `main` @ `8df6f2402` (PR #930 merge, 2026-08-05):

* R-CMD-check ubuntu-latest (release): **success** (~50 min; under the 75 min
  ceiling). Run: https://github.com/itchyshin/drmTMB/actions/runs/31043189202
* pkgdown: **success**. Run: https://github.com/itchyshin/drmTMB/actions/runs/31047116604

Local `R CMD check --as-cran` on the candidate tarball is recorded under
`docs/dev-log/release/0.7.0-cran-gate/` when the readiness probe completes.
Until that log exists, do **not** treat this file as submission-ready evidence.

Expected CRAN-lane notes (from prior 0.5.0-era probes; re-confirm on the frozen
0.7.0 tarball):

* **New submission.**
* Possible **installed size** note (~25 Mb with ~13 Mb compiled TMB `libs/`),
  intrinsic to TMB packages (same pattern as CRAN `glmmTMB`).

## Submission notes

* DESCRIPTION quotes the method name 'Tweedie' and hyphenates "semi-continuous"
  to resolve possible-spelling flags.
* Routine CRAN check time is bounded by keeping the exhaustive Phase 18
  simulation harness and heavy diagnostics in the non-CRAN test lane
  (`NOT_CRAN=true` in repository CI).
* Random-effect SD profile intervals warn at variance-component boundaries
  (`drmTMB_profile_boundary_warning`). The D-117 10-group gate measured
  conditional undercoverage that matches `lme4` on the same seeds; this is
  documented in `?confint.drmTMB` and is **not** claimed as a packaging defect.
* First CRAN number is **0.7.0** (D-86). Experimental lifecycle labelling is
  intentional (D-41).

## Test environments

* GitHub Actions ubuntu-latest, R-release — green on `8df6f2402` (above).
* Full ubuntu + macOS + windows matrix, win-builder, and R-hub (including
  sanitizers / valgrind / rchk for compiled TMB) are **deferred** to the
  platform-clean rung and will be recorded here before upload.

## Reverse dependencies

This is a new package; there are no reverse dependencies.

## Notes for the CRAN team

* `JuliaCall` is Suggested only (optional experimental `engine = "julia"`).
  Julia-backed tests are skipped on CRAN. The required engine is bundled TMB.
