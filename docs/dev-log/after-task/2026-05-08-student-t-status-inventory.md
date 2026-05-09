# After Task: Student-t Status Inventory Cleanup

## Goal

Bring the public status inventory into line with the implemented fixed-effect
univariate Student-t path and remove wording that could make planned mixed
families look runnable.

## Implemented

- Added the implemented Student-t path to README current status, ROADMAP,
  known limitations, formula status maps, and family-design prose.
- Clarified that `family = c(gaussian(), poisson())` is a planned mixed-response
  direction, not a supported fitting path.
- Replaced active Student-t "tail weight" wording with degrees-of-freedom or
  tail-shape language so larger `nu` is not misread as heavier tails.
- Added a status-inventory requirement to `docs/design/10-after-task-protocol.md`
  and `.agents/skills/after-task-audit/SKILL.md`.

## Mathematical Contract

For the implemented Student-t family:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
nu_i = 2 + exp(X_nu[i, ] beta_nu)
```

Here `nu_i` is the degrees-of-freedom or tail-shape parameter. Smaller values
near 2 mean heavier tails; larger values mean a more Gaussian-like likelihood.
This task changed prose only; it did not change the likelihood.

## Files Changed

- `.agents/skills/after-task-audit/SKILL.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/10-after-task-protocol.md`
- `docs/design/14-gamlss-parameter-names.md`
- `docs/design/19-phylogenetic-location-scale-shape.md`
- `docs/dev-log/after-task/2026-05-08-student-location-scale-shape.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-workflow.Rmd`
- `vignettes/robust-student.Rmd`

Generated and verified locally:

- `pkgdown-site/index.html`
- `pkgdown-site/ROADMAP.html`
- `pkgdown-site/articles/distribution-families.html`
- `pkgdown-site/articles/formula-grammar.html`
- `pkgdown-site/articles/model-workflow.html`
- `pkgdown-site/articles/robust-student.html`

## Checks Run

- `Rscript -e "devtools::load_all(quiet=TRUE); for (f in c('vignettes/distribution-families.Rmd','vignettes/formula-grammar.Rmd','vignettes/robust-student.Rmd','vignettes/model-workflow.Rmd')) rmarkdown::render(f, output_format = rmarkdown::html_vignette(), output_file = tempfile(fileext = '.html'), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Exact status-inventory scans:

- `rg -n "tail weight|tail-weight|heavy-tail parameter|all non-Gaussian families are planned|Add Student-t|fitted Gaussian likelihood path" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R man NEWS.md tests pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "family = c\\(gaussian\\(\\), poisson\\(\\)\\)" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests pkgdown-site --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

No new unit tests were added because this was a documentation consistency task.
Full package tests and R CMD check were run to ensure the changed vignettes and
examples still build, and the exact stale-wording scans were recorded so the
next audit can reproduce the inventory check.

## Consistency Audit

- README, ROADMAP, known limitations, formula grammar docs, and the formula
  grammar article now all list fixed-effect Student-t `mu`, `sigma`, and `nu`
  models as implemented.
- The distribution-family article now separates implemented
  `family = c(gaussian(), gaussian())` syntax from planned mixed-family syntax.
- Active Student-t prose now uses tail-shape or degrees-of-freedom language.
- The first stale-wording scan returned no active hits.
- The mixed-family scan returned planned/future-work text plus the deliberate
  unsupported-syntax test, not a runnable-looking implemented example.

## What Did Not Go Smoothly

The Student-t implementation had updated the direct family docs, tests, NEWS,
and tutorial, but status inventory files lagged behind. Pat found the
runnable-looking mixed-family example, and Rose found the stale known-limitations
and formula-status maps. This is a process issue, not a modelling issue.

## Team Learning

For every family or formula-grammar change, Ada should assign Rose's status
inventory scan before closing the task. The project-local after-task skill now
records that rule explicitly.

## Known Limitations

This task did not add Student-t random effects, Student-t known-covariance
models, Student-t phylogenetic models, bivariate Student-t models, or mixed
bivariate response families.

## Next Actions

- Use the updated after-task protocol for the next family or grammar change.
- Consider Jason's suggested next technical task: a small `metafor::rma.mv()`
  dense known-`V` comparator test.
