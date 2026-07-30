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
- `pkgdown::check_pkgdown()` is blocked by an unrelated baseline index omission: `predict.drm_pair_association` is absent from `_pkgdown.yml`.

## Tests Of The Tests

The bivariate regression test inserts one missing `y2`, compares the default fit with an explicit complete-pair fit, and asserts the retained `nobs()` count. The engine test asserts the narrowed formal and the negative reserved-engine paths.

## Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/`, `vignettes/`, `R/`, `man/`, `tests/`, and `_pkgdown.yml` for stale Gaussian-only response-mask wording, complete-case `nobs()` wording, and the old three-engine formal. Julia-bridge wording was deliberately left unchanged because this is an R-only arc.

## GitHub Issue Maintenance

Issues #865–#867 remain open until this branch is committed, pushed, and reviewed. PR #869 remains a separate documentation-only cross-package brief.

## What Did Not Go Smoothly

The first strict CRAN-style check stopped before package validation because `palmerpenguins` is unavailable locally. The no-force-suggests check completed and exercised installation, generated documentation, examples, the CRAN-safe test subset, and vignette rebuilding.

## Team Learning

Rose found three stale current-claim remnants after the initial implementation: the consolidated design section, the unsupported-family message, and a historical first-slice record. All were reconciled before closeout.

## Known Limitations

Dense known covariance with bivariate partial responses, MNAR, response-plus-`mi()`, EM/profile engines, and broad random/structured masking remain outside the claim. The unrelated pkgdown index omission must be repaired in its owning lane.

## Next Actions

Complete the running full source suite, rerun the final focused tests and build after the documentation reconciliation, then commit, push, open the focused PR, and close #865–#867 with the exact evidence.
