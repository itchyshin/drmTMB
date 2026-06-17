# After Task: Julia Engine Article Title

## Goal

Align the visible Julia-engine article title with the user-facing navbar label.
The article was correctly discoverable under Model Guides, but the page title
and vignette index still said "Working with the Julia engine".

## Implemented

`vignettes/julia-engine.Rmd` now uses the title and vignette index entry
"Running models with the Julia engine".

## Files Changed

- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-09-julia-engine-article-title.md`

## Checks Run

Pending:

```sh
Rscript -e 'pkgdown::build_article("julia-engine")'
Rscript -e 'pkgdown::build_site()'
Rscript -e 'pkgdown::check_pkgdown()'
rg -n "Running models with the Julia engine|Working with the Julia engine" vignettes/julia-engine.Rmd pkgdown-site/articles/julia-engine.html pkgdown-site/articles/index.html
git diff --check
```

`pkgdown::build_article("julia-engine")` completed. A focused render updated
the article page title and heading, and the full `pkgdown::build_site()` was
then needed to regenerate `articles/index.html`. The full site build completed
with the known local `glmmTMB`/`TMB` version-mismatch warning while rendering
`convergence.Rmd`. `pkgdown::check_pkgdown()` reported no problems and printed
`pkgdown_check_ok`. Rendered scans found the new title in the vignette source,
article page, navbar entry, and article-index entry, with no rendered
`Working with the Julia engine` hit remaining in the checked article/index
files. `git diff --check` reported no whitespace problems.

## Known Limitations

This is a title-only patch. It does not change bridge behavior, benchmark
claims, or the article's technical content.
