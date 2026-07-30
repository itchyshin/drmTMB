# After Task: Missing-data R claim reconciliation (#865–#867)

## Goal

Align the R missing-data public contract with the verified implementation, without adding a new missing-data algorithm.

## Implemented

`response = "drop"` now explicitly documents and tests complete-pair removal for bivariate Gaussian responses. `response = "include"` is described as the current observed-response mask across the documented univariate route inventory plus bivariate Gaussian partial-response rows without dense known covariance. `miss_control()` now formally exposes only `engine = "laplace"`; explicit `"em"` and `"profile"` calls fail as reserved, unimplemented engines.

## Mathematical Contract

Missing supported responses contribute no direct response likelihood. A bivariate Gaussian partial row is distinct: one observed component contributes its marginal Gaussian density, whereas the default policy drops the whole pair. This is not a generic FIML, MNAR, response-imputation, response-plus-`mi()`, REML, interval, or coverage claim.

## Files Changed

Roxygen and generated Rd now agree with the tests; the missing-data vignette, formula grammar, likelihood/design records, controls record, roadmap, and historical NEWS entry distinguish current scope from the historical first slice.

## Checks Run

- `devtools::document()` completed after each Roxygen change.
- Focused missing-data suite: 99 expectations, 0 failures, 0 warnings, 0 skips.
- `R CMD build .` completed successfully.
- `NOT_CRAN=false R CMD check --as-cran --no-manual` completed with 2 pre-existing/environmental notes: unavailable optional `palmerpenguins` and a missing `utils::head` import.
- `pkgdown::check_pkgdown()` passed after adding the existing exported `predict.drm_pair_association` topic to the frozen-margin association reference group.

## Tests Of The Tests

The bivariate regression test inserts one missing `y2`, compares the default fit with an explicit complete-pair fit, and asserts the retained `nobs()` count. The engine test asserts the narrowed formal and the negative reserved-engine paths.

## Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/`, `vignettes/`, `R/`, `man/`, `tests/`, and `_pkgdown.yml` for stale Gaussian-only response-mask wording, complete-case `nobs()` wording, and the old three-engine formal. Julia-bridge wording was deliberately left unchanged because this is an R-only arc.

## GitHub Issue Maintenance

The branch is committed and pushed. GitHub issue comments/closures and pull-request creation are pending because this session's GitHub credentials are invalid. PR #869 remains a separate documentation-only cross-package brief.

Mission Control was updated in the local Shinichi vault at commit `73f3317` to
record this R claim closeout as the current user-directed lane while retaining
Lane C as the unchanged capability source.

## What Did Not Go Smoothly

The first strict CRAN-style check stopped before package validation because `palmerpenguins` is unavailable locally. The no-force-suggests check completed and exercised installation, generated documentation, examples, the CRAN-safe test subset, and vignette rebuilding.

## Team Learning

Rose found three stale current-claim remnants after the initial implementation: the consolidated design section, the unsupported-family message, and a historical first-slice record. All were reconciled before closeout.

## Known Limitations

Dense known covariance with bivariate partial responses, MNAR, response-plus-`mi()`, EM/profile engines, and broad random/structured masking remain outside the claim. The strict CRAN-style check remains environment-limited by an unavailable optional suggested package and the existing `utils::head` namespace note.

## Next Actions

Open the focused PR from the pushed branch and close #865–#867 with the recorded evidence once GitHub authentication is restored. A broad source suite was started and reached unrelated phase-18 contexts without failures, then intentionally stopped; the focused suite and installed CRAN-safe suite are the final evidence for this arc.
