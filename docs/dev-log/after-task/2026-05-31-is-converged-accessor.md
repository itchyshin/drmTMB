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
# After Task: `is_converged()` Accessor

## Goal

Close issue #317's smallest package-capability need: a compact programmatic
convergence flag for downstream comparison and display tools that should not
have to parse the full `check_drm()` table.

## Implemented

Added exported `is_converged()` with a `drmTMB` method. The default flag returns
`TRUE` only when the stored optimizer convergence code is 0 and the stored
objective and log-likelihood are finite. `include_hessian = TRUE` additionally
requires successful `TMB::sdreport()` output with `pdHess = TRUE`.

## Mathematical Contract

This task does not change model equations, likelihoods, parameter transforms,
or formula grammar. It only reports stored fit status. A failed Hessian check is
treated as an inference-readiness signal, not automatic proof that point
estimates are unusable.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `NEWS.md`
- `_pkgdown.yml`
- `NAMESPACE`
- `man/is_converged.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/check.R R/methods.R tests/testthat/test-check-drm.R tests/testthat/test-structured-effects.R NEWS.md _pkgdown.yml
Rscript --vanilla -e "invisible(parse('R/check.R')); invisible(parse('R/methods.R')); invisible(parse('tests/testthat/test-check-drm.R')); invisible(parse('tests/testthat/test-structured-effects.R')); cat('parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^(check-drm|structured-effects|package-skeleton)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^(check-drm|structured-effects|package-skeleton)$', reporter = 'summary')"
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
Rscript --vanilla -e "devtools::check(args = c('--no-manual'), error_on = 'never')"
```

The full package check completed in 6m 58.2s with 0 errors, 0 warnings, and 0
notes.

## Tests Of The Tests

The new test mutates a real Gaussian fit to cover optimizer nonconvergence,
non-finite objective, `pdHess = FALSE`, skipped `sdreport()`, invalid
`include_hessian`, reserved `...`, and default-method failure.

## Consistency Audit

The helper is documented as a compact status accessor and cross-references
`check_drm()` for full diagnostics. The pkgdown Reference index and rendered
NEWS page both expose `is_converged()`.

## GitHub Issue Maintenance

PR closure should use `Closes #317` once this branch is opened.

## What Did Not Go Smoothly

`devtools::document()` tried to add `RoxygenNote: 7.3.2` and unrelated Rd
changes from the local roxygen version. Those generated artifacts were removed
from the final diff to keep the PR focused.

## Team Learning

Ada and Rose should keep compact status helpers separate from broader
diagnostic tables: downstream tools need one-bit gates, but readers still need
the richer `check_drm()` table when diagnosing why a fit is unsafe for
inference.

## Known Limitations

`is_converged()` does not inspect gradients, boundary estimates, replication,
or scale/correlation diagnostics. Those remain `check_drm()` responsibilities.

## Next Actions

Open the clean post-fit accessor PR and let it close #317 after review and
merge.
