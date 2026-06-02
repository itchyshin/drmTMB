# After-Task Report: `is_converged()` Accessor

Date: 2026-05-31

Issue: #317

## Goal

Give downstream tools, including `symbolizer::compare_symbolic()`, a compact
no-rerun way to ask whether a fitted `drmTMB` model converged before displaying
or comparing model structure.

## Changes

- Added exported `is_converged()` S3 generic with `is_converged.drmTMB()`.
- Made the default flag return `TRUE` only when the stored optimizer convergence
  code is zero and the stored objective/log-likelihood values are finite.
- Added `include_hessian = TRUE` for the stricter inference-readiness flag that
  also requires completed `TMB::sdreport()` output with `pdHess = TRUE`.
- Documented that `is_converged()` is the compact flag and `check_drm()` remains
  the full diagnostic table for convergence, Hessian, boundary, standard-error,
  design, and replication rows.
- Added pkgdown Reference-index navigation and NEWS entry for #317.

## Boundary

This slice is a post-fit status accessor. It does not change fitting,
likelihoods, formula grammar, `check_drm()` row semantics, TMB code, or
missing-data handling.

## Validation

```sh
air format R/check.R tests/testthat/test-check-drm.R NEWS.md _pkgdown.yml
Rscript --vanilla -e "invisible(parse('R/check.R')); invisible(parse('tests/testthat/test-check-drm.R')); cat('parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = 'check-drm', reporter = 'summary')"
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^(check-drm|package-skeleton)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n "is_converged|Check whether a fit converged|include_hessian|#317" pkgdown-site/reference/index.html pkgdown-site/reference/is_converged.html pkgdown-site/news/index.html
git diff --check
```

Results:

- Parse checks passed.
- Focused `check-drm` tests passed.
- Focused `check-drm` plus `package-skeleton` tests passed.
- `devtools::document()` wrote `NAMESPACE` and `man/is_converged.Rd`; local
  roxygen version metadata was kept out of `DESCRIPTION`.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(lazy = TRUE, preview = FALSE)` built
  `reference/is_converged.html`, refreshed `reference/index.html`, and rebuilt
  `news/index.html`.
- The rendered scan found `is_converged()` on the Reference index, the new
  reference page, and NEWS.
- `git diff --check` passed.

## Tests Of The Tests

- The test checks a fitted model, a synthetic optimizer non-convergence state,
  a synthetic non-positive-definite Hessian state, and a synthetic
  `sdreport()`-skipped state.
- This verifies the two intended modes: optimizer-only convergence remains true
  for Hessian-skipped or Hessian-failed fits, while `include_hessian = TRUE`
  requires inference-ready uncertainty evidence.

## Consistency Audit

Search:

```sh
rg -n "is_converged|Check whether a fit converged|include_hessian|#317" pkgdown-site/reference/index.html pkgdown-site/reference/is_converged.html pkgdown-site/news/index.html
```

Result:

- Rendered documentation exposes the accessor in the Reference index, reference
  page, and NEWS.
- The new reference page points users to `check_drm()` for the larger diagnostic
  table, keeping the compact flag from overclaiming identifiability coverage.

## GitHub Issue Maintenance

- #317 remains open until the mixed local branch is pushed or split into a clean
  PR. The local implementation now covers the no-rerun convergence flag that the
  issue named explicitly; `check_drm()` continues to cover the broader table.

## Member-Group Review

- Ada kept this as a narrow package-surface capability before the planned large
  power simulations.
- Boole kept the function name and argument shape short enough for downstream
  package code.
- Fisher kept Hessian readiness separate from optimizer convergence.
- Emmy kept the richer diagnostic vocabulary in `check_drm()` instead of adding
  a second table API.
- Grace required export, package-skeleton, pkgdown, rendered Reference-index,
  and whitespace checks before recording the slice as locally complete.
