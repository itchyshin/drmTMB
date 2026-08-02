# After Task: Missing-data R claim reconciliation (#865–#867)

## 1. Goal

Align the R missing-data public contract with the verified implementation, without adding a new missing-data algorithm.

## 2. Implemented

`response = "drop"` now explicitly documents and tests complete-pair removal for bivariate Gaussian responses. `response = "include"` is described as the current observed-response mask across the documented univariate route inventory plus bivariate Gaussian partial-response rows without dense known covariance. `miss_control()` now formally exposes only `engine = "laplace"`; explicit `"em"` and `"profile"` calls fail as reserved, unimplemented engines.

## 3a. Decisions and Rejected Alternatives

This arc reconciles the existing R implementation and its public claim only. It rejects new missing-data algorithms, EM/profile implementation, MNAR, response-plus-`mi()`, new families, capability-tier promotion, Julia work, and changes to the separate PR #869 brief.

## 3b. Mathematical Contract

Missing supported responses contribute no direct response likelihood. A bivariate Gaussian partial row is distinct: one observed component contributes its marginal Gaussian density, whereas the default policy drops the whole pair. This is not a generic FIML, MNAR, response-imputation, response-plus-`mi()`, REML, interval, or coverage claim.

## 4. Files Touched

Roxygen and generated Rd now agree with the tests; the missing-data vignette, formula grammar, likelihood/design records, controls record, roadmap, and historical NEWS entry distinguish current scope from the historical first slice.

## 5. Checks Run

- `devtools::document()` completed after each Roxygen change.
- Focused missing-data suite: 99 expectations, 0 failures, 0 warnings, 0 skips.
- `R CMD build .` completed successfully.
- `NOT_CRAN=false R CMD check --as-cran --no-manual` completed with 2 pre-existing/environmental notes: unavailable optional `palmerpenguins` and a missing `utils::head` import.
- `pkgdown::check_pkgdown()` passed after adding the existing exported `predict.drm_pair_association` topic to the frozen-margin association reference group.

## 6. Tests of the Tests

The bivariate regression test inserts one missing `y2`, compares the default fit with an explicit complete-pair fit, and asserts the retained `nobs()` count. The engine test asserts the narrowed formal and the negative reserved-engine paths.

## 7a. Issue Ledger

- #865: closed automatically when PR #871 merged; complete-pair default behavior is documented and regression-tested.
- #866: closed automatically when PR #871 merged; the current R response-mask surface is documented without broad inference claims.
- #867: closed automatically when PR #871 merged; `engine = "laplace"` is the only default and reserved engines error intentionally.
- PR #869: separate documentation-only cross-package brief; unchanged by this arc.

PR #871 merged as `5e732894` on 2026-07-30. GitHub CLI authentication was restored for `itchyshin` with SSH Git protocol and a repo-scoped API token. Mission Control was updated in the local Shinichi vault at commit `d7577e0` to record this R claim closeout as complete while retaining Lane C as the unchanged capability source.

## 8. Consistency Audit

Searched `README.md`, `ROADMAP.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/`, `vignettes/`, `R/`, `man/`, `tests/`, and `_pkgdown.yml` for stale Gaussian-only response-mask wording, complete-case `nobs()` wording, and the old three-engine formal. Julia-bridge wording was deliberately left unchanged because this is an R-only arc.

## 9. What Did Not Go Smoothly

The first strict CRAN-style check stopped before package validation because `palmerpenguins` is unavailable locally. The no-force-suggests check completed and exercised installation, generated documentation, examples, the CRAN-safe test subset, and vignette rebuilding.

## 11. Team Learning

Rose found three stale current-claim remnants after the initial implementation: the consolidated design section, the unsupported-family message, and a historical first-slice record. All were reconciled before closeout.

## 10. Known Residuals

Dense known covariance with bivariate partial responses, MNAR, response-plus-`mi()`, EM/profile engines, and broad random/structured masking remain outside the claim. The strict CRAN-style check remains environment-limited by an unavailable optional suggested package and the existing `utils::head` namespace note.

## 12. Cross-Product Coverage

This R claim-reconciliation arc covers the `missing` control's documented response and engine surface, the generated Rd and vignette surfaces, `nobs()` explanation, direct default-policy tests, local installed-package checking, pkgdown validation, Mission Control, and the linked GitHub issue lifecycle. It does NOT cover dense known covariance with bivariate partial responses, MNAR, response-plus-`mi()`, EM/profile engines, REML, intervals, coverage, broad random/structured masking, Julia parity, or new missing-data algorithms.

## Next Actions

No missing-data claim closeout action remains. A broad source suite was started and reached unrelated phase-18 contexts without failures, then intentionally stopped; the focused suite and installed CRAN-safe suite are the final evidence for this arc.
