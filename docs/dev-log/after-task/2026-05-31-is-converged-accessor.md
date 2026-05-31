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
