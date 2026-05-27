# After Task: Non-Gaussian Tutorial Gate Follow-Through

## Goal

Close Slices 1349-1358 by synchronizing the reader route after the fixed-effect
zero-one beta source and artifact lanes landed.

## Implemented

The getting-started article, model map, source map, worked-example inventory,
NEWS, and design gate now agree that the fitted bounded-response teaching route
contains `beta_binomial()` for successes out of known trials, `beta()` for
strict continuous proportions, and fixed-effect `zero_one_beta()` for
continuous proportions with structural exact 0 or 1 values.

## Mathematical Contract

No likelihood or formula grammar changed. The reader-facing contract remains:
`zero_one_beta()` uses interior `mu` and `sigma`, exact-boundary probability
`zoi`, conditional-one probability `coi`, and unconditional mean
`(1 - zoi) * mu + zoi * coi`.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/116-nongaussian-tutorial-gate-slices-1349-1358.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format NEWS.md README.md ROADMAP.md docs/design/37-worked-example-inventory.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/116-nongaussian-tutorial-gate-slices-1349-1358.md docs/dev-log/after-task/2026-05-26-nongaussian-tutorial-gate-slices-1349-1358.md vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd
Rscript --vanilla -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('drmTMB', new_process = FALSE, quiet = TRUE); pkgdown::build_article('model-map', new_process = FALSE, quiet = TRUE); pkgdown::build_article('source-map', new_process = FALSE, quiet = TRUE); pkgdown::build_article('proportion-beta-binomial', new_process = FALSE, quiet = TRUE)"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "devtools::test(filter = '^(zero-one-beta|family-link-contract)$', reporter = 'summary')"
rg -n 'beta and beta-binomial proportion examples|successes out of trials or continuous rates inside|strict continuous proportion or successes out|beta and beta-binomial `mu`, `sigma`|zero-one-inflated beta' README.md NEWS.md ROADMAP.md docs/design vignettes _pkgdown.yml pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-map.html pkgdown-site/articles/source-map.html pkgdown-site/articles/proportion-beta-binomial.html pkgdown-site/news/index.html -g '!*.json'
rg -n 'zero_one_beta\(\)|zero-one beta|bounded-response proportion examples|structural exact boundaries|model_type = 15|zoi|coi|beta-binomial.*random intercept|beta/beta-binomial.*random-intercept' README.md vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd docs/design/37-worked-example-inventory.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/116-nongaussian-tutorial-gate-slices-1349-1358.md ROADMAP.md NEWS.md pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-map.html pkgdown-site/articles/source-map.html pkgdown-site/articles/proportion-beta-binomial.html pkgdown-site/news/index.html -g '!*.json'
git diff --check
```

- The touched article build completed for getting-started, model-map,
  source-map, and the proportion tutorial.
- The full pkgdown site build completed and regenerated the ROADMAP,
  reference pages, touched articles, news, sitemap, and search index.
- `pkgdown::check_pkgdown()` reported no problems.
- Focused zero-one beta and family-link contract tests passed.
- The first stale scan returned no matches after the roadmap patch.
- The positive evidence scan found expected source and generated-site mentions
  of `zero_one_beta()`, `model_type = 15`, `zoi`, `coi`, structural exact
  boundaries, and the bounded-response proportion route.
- `git diff --check` was clean.

## Tests Of The Tests

This is a documentation and source-map synchronization slice. The check focus
is rendered article availability, pkgdown navigation, and stale-status scans
rather than new runtime tests.

## Consistency Audit

Rose found and fixed two real drift items. `ROADMAP.md` still described
zero-one beta as a future family in Phase 8/9 current-status text, and a few
README/roadmap/readiness summaries named beta `mu` random intercepts but
omitted the paired beta-binomial first slice. The current docs now say
fixed-effect `zero_one_beta()` is implemented and beta-binomial ordinary `mu`
random intercepts are source-tested, while ordered beta, zero-one beta random
effects, richer bounded-response covariance, and other neighbours remain
planned.

## GitHub Issue Maintenance

Issue #57 is the overlapping tutorial gate. It should close only after this PR
passes CI and merges.

## What Did Not Go Smoothly

The first source-only stale scan was too narrow. It checked the touched
vignettes and source-map route, but it did not include `ROADMAP.md`; adding the
roadmap to the scan exposed the drift before the PR.

## Team Learning

Added `docs/dev-log/team-improvements.md` entry "Tutorial-Gate Roadmap Scan" so
future tutorial gates include the roadmap and generated ROADMAP HTML in their
stale-wording pass.

## Known Limitations

Zero-one beta random effects, bounded-response random slopes, structured
bounded responses, known covariance, ordered beta, beta-binomial zero
inflation, denominator shorthand for zero-one beta, and bivariate or mixed
bounded-response models remain planned.

## Next Actions

Open the PR with `Closes #57`, monitor CI, and let the issue close only after
the PR passes and merges.
