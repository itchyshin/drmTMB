# After-Task Report: Structured-Effects Accessor

Date: 2026-05-31

Issue: #335

## Goal

Expose the structured-effect metadata that `drmTMB` already parsed at fit time,
so downstream tools can read fitted `phylo()`, `spatial()`, `animal()`,
`relmat()`, and `phylo_interaction()` metadata without grepping formula text.

## Changes

- Added exported `structured_effects()` S3 generic with `structured_effects.drmTMB()`.
- Returned a stable base data-frame schema with marker, grouping variable,
  matrix attachment, structure, group-pair fields, label, block, `q`, `n_re`,
  random-effect block, correlation level, and list columns for `dpars`,
  `coef_names`, and `args`.
- Documented the current fitted structured-marker grammar in
  `?structured_effects`.
- Added `structured_effects` to the pkgdown Reference index.
- Added self-contained tests covering the empty-table contract and the current
  parsed marker set: `phylo`, `spatial`, `animal`, `relmat`, and
  `phylo_interaction`.
- Added a NEWS entry linking the accessor to #335.

## Boundary

This slice is a read-only post-fit accessor. It does not change likelihood
parameterization, formula grammar, TMB data, optimizer behavior, or
missing-data handling.

## Validation

```sh
air format R/methods.R tests/testthat/test-structured-effects.R
Rscript --vanilla -e "invisible(parse('R/methods.R')); invisible(parse('tests/testthat/test-structured-effects.R')); cat('parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = 'structured-effects', reporter = 'summary')"
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^(structured-effects|package-skeleton)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n "structured_effects|Extract structured-effect metadata|phylo_interaction\\(1 \\| plant:pollinator|matrix_attachment|args" pkgdown-site/reference/index.html pkgdown-site/reference/structured_effects.html pkgdown-site/news/index.html
git diff --check
```

Results:

- The parser check printed `parse ok`.
- The focused `structured-effects` test passed after replacing the first helper
  draft with `do.call(drm_formula, ...)`, which preserves `drm_formula()`'s
  non-standard formula capture.
- The focused `structured-effects` plus `package-skeleton` bundle completed
  without failures.
- `devtools::document()` wrote `NAMESPACE` and `man/structured_effects.Rd`.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(lazy = TRUE, preview = FALSE)` built
  `reference/structured_effects.html`, refreshed `reference/index.html`, and
  rebuilt `news/index.html`.
- The rendered scan found `structured_effects()` on the Reference index, the
  new reference page, and NEWS.
- `git diff --check` passed.

## Tests Of The Tests

- The empty-table test checks the boundary where a fit has no fitted structured
  marker but downstream tools still need stable columns.
- The marker test walks the parsed internal structures for every current fitted
  marker family and caught the first helper draft, which passed a formula object
  through `drm_formula()` in a way that broke its non-standard capture contract.

## Consistency Audit

Search:

```sh
rg -n "structured_effects|deparse\\(rhs\\)|formula-text grep|formula text|grepping formula|structured-effect metadata|matrix_attachment" README.md ROADMAP.md NEWS.md docs vignettes R tests man pkgdown-site/reference pkgdown-site/news
```

Result:

- The new references appear in `R/methods.R`, `man/structured_effects.Rd`,
  `NEWS.md`, `pkgdown-site/reference/index.html`,
  `pkgdown-site/reference/structured_effects.html`, and
  `pkgdown-site/news/index.html`.
- No stale user-facing instruction tells downstream packages to grep formula
  text for this metadata.

## GitHub Issue Maintenance

- Rechecked #335 and the open-issue search
  `structured_effects structured effect accessor metadata phylo animal symbolizer`.
- #335 is the only matching open issue. It remains open until the branch is
  pushed or merged, because this local worktree still contains other dirty
  main-lane and missing-data-lane changes.

## Known Limitations

- The accessor reports fitted structured-effect metadata already stored on the
  `drmTMB` object; it does not make planned markers fit.
- Current fitted objects store one structured-effect block in
  `model$structured$phylo_mu`; the implementation iterates the structured
  registry so later additional structured slots can return additional rows.

## Next Actions

- Include this slice in the next small issue-linked PR update, or split it onto
  a clean branch before closing #335 remotely.

## Member-Group Review

- Ada kept the slice issue-linked and package-capability focused before the
  planned large power simulations.
- Boole checked that the accessor reports parsed formula metadata rather than
  adding new syntax.
- Emmy kept the output a stable base data frame with explicit list columns
  rather than adding a new object class.
- Pat checked that the reference page names the fitted marker grammar directly.
- Rose kept fitted metadata separate from planned future structured markers and
  missing-data work.
- Grace required the package-skeleton, pkgdown, rendered Reference-index, and
  whitespace checks before treating the slice as complete.
