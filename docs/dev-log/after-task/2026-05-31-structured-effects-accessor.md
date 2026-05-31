# After Task: `structured_effects()` Accessor

## Goal

Close issue #335's smallest downstream API gap by exposing fitted
structured-effect marker metadata through a stable post-fit table instead of
forcing downstream tools to grep formula text.

## Implemented

Added exported `structured_effects()` with a `drmTMB` method. The method returns
one row per fitted `phylo()`, `spatial()`, `animal()`, or `relmat()` structured
marker, including grouping variable, matrix attachment, structure, block, `q`,
random-effect block name, correlation level, and list columns for fitted
distributional parameters, coefficient names, and original marker arguments.
Empty fits return the same columns with zero rows.

## Mathematical Contract

This task does not change structured-effect equations, likelihoods,
parameterizations, TMB data, precision construction, or formula grammar. It
only exposes metadata already produced by the parser and fit builders.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-structured-effects.R`
- `NEWS.md`
- `_pkgdown.yml`
- `NAMESPACE`
- `man/structured_effects.Rd`
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
rg -n "structured_effects|Extract structured-effect metadata|matrix_attachment|#335" pkgdown-site/reference/index.html pkgdown-site/reference/structured_effects.html pkgdown-site/news/index.html
git diff --check
Rscript --vanilla -e "devtools::check(args = c('--no-manual'), error_on = 'never')"
```

The full package check completed in 6m 58.2s with 0 errors, 0 warnings, and 0
notes.

## Tests Of The Tests

The new test checks the empty-table schema and the four fitted structured
marker families available on `main`: `phylo()`, `spatial()`, `animal()`, and
`relmat()`. It verifies marker names, grouping variables, matrix attachments,
structures, random-effect block names, correlation levels, `dpars`,
coefficient names, `q`, `n_re`, and argument list columns.

## Consistency Audit

The public documentation names only fitted `main` markers and avoids claiming
support for missing-data behavior, `phylo_interaction()`, mesh/SPDE inputs, or
new formula grammar. The pkgdown Reference index and rendered NEWS page expose
`structured_effects()`.

## GitHub Issue Maintenance

PR closure should use `Closes #335` once this branch is opened.

## What Did Not Go Smoothly

The first local implementation was drafted in the dirty Phase 6c worktree,
which also contains missing-data and `phylo_interaction()` changes. The final
PR branch was rebuilt from clean `origin/main` and intentionally excludes those
separate lanes.

## Team Learning

Rose should keep fitted, planned, and lane-owned features visibly separate in
accessor docs. The accessor schema can be forward-looking enough to stay stable
without advertising markers that are not on the PR base.

## Known Limitations

The accessor reports metadata, not estimates. Use `ranef()`, `sdpars`,
`corpairs()`, `profile_targets()`, and `check_drm()` for fitted values,
variance components, correlations, intervals, and diagnostics.

## Next Actions

Open the clean post-fit accessor PR and let it close #335 after review and
merge.
