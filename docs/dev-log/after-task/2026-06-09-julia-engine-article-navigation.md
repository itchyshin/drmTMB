# After Task: Julia Engine Article Navigation

## Goal

Make the live Julia-engine article discoverable from the normal user-facing
pkgdown navigation. The article was live, but the only top-level navbar route
was under Developer Notes, which made the R-user bridge story too easy to miss.

## Implemented

`_pkgdown.yml` now lists `articles/julia-engine.html` under Model Guides as
"Running models with the Julia engine". The article index also places
`julia-engine` in the Inference, Diagnostics, and Figures group beside the
large-data guide. The Developer Notes duplicate was removed so the article has
one clear navigation home.

## Files Changed

- `_pkgdown.yml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-09-julia-engine-article-navigation.md`

## Checks Run

```sh
Rscript -e 'pkgdown::build_site()'
Rscript -e 'pkgdown::check_pkgdown()'
rg -n "Model Guides|Running models with the Julia engine|Developer Notes|Working with the Julia engine" pkgdown-site/articles/drmTMB.html pkgdown-site/articles/index.html pkgdown-site/articles/julia-engine.html
git diff --check
```

`pkgdown::build_site()` completed and regenerated the local site. The build
printed the known local `glmmTMB`/`TMB` version-mismatch warning while rendering
`convergence.Rmd`, but finished successfully. `pkgdown::check_pkgdown()`
reported no problems and printed `pkgdown_check_ok`. The rendered HTML grep
found `Running models with the Julia engine` under `Model Guides` on the
getting-started page, article index, and Julia-engine article. `git diff
--check` reported no whitespace problems.

## Known Limitations

This is a navigation-only patch. It does not change article prose, benchmark
claims, bridge behavior, or the Julia profile/bootstrap implementation.
