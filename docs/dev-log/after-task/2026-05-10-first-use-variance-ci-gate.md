# After Task: First-Use Variance Reporting And CI Gate

## Goal

Make the first user path teach `sigma` interpretation earlier, and make the
pkgdown deployment workflow wait for successful package checks on `main`.

## Implemented

- Updated the README smoke test so `sigma ~ x1` has a real scale signal rather
  than unrelated random noise.
- Added README code for residual SD ratios, residual variance ratios, and
  fitted residual variances.
- Added a "Fit your first model" section to the getting-started article before
  the feature catalogue.
- Added "Getting started" as the first Tutorials navbar item.
- Added marginal residual variances to bivariate coscale reporting tables.
- Expanded the meta-analysis article with extra heterogeneity variance, total
  observation variance, and bivariate residual covariance reporting.
- Changed `pkgdown` deployment to trigger from successful `R-CMD-check`
  workflow runs on `main` or `master`, with manual dispatch retained.
- Added `v*` release-tag triggers and workflow-level concurrency to
  `R-CMD-check`.

## Mathematical Contract

The public grammar remains `sigma`. Gaussian fitted `sigma` is residual SD;
residual variance is fitted `sigma^2`. A log-SD coefficient gives an SD ratio
of `exp(coef)` and a variance ratio of `exp(2 * coef)`. In meta-analysis,
`sigma^2` is extra heterogeneity variance after known sampling variance is
accounted for, and total observation variance is known sampling variance plus
extra heterogeneity variance. In bivariate Gaussian models, the diagonal
residual variances are `sigma1^2` and `sigma2^2`, and the off-diagonal
residual covariance is `rho12 * sigma1 * sigma2`.

## Files Changed

- `README.md`
- `_pkgdown.yml`
- `vignettes/drmTMB.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/meta-analysis.Rmd`
- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/pkgdown.yaml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-variance-facing-sigma-reporting.md`
- `docs/dev-log/after-task/2026-05-10-first-use-variance-ci-gate.md`

## Checks Run

- `air format README.md vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd`
- `Rscript -e "pkgdown::build_articles(c('drmTMB', 'bivariate-coscale', 'meta-analysis'))"` failed because the function expects a package path, not an article-name vector.
- `Rscript -e "pkgdown::build_article('drmTMB'); pkgdown::build_article('bivariate-coscale'); pkgdown::build_article('meta-analysis')"`
- `Rscript -e "pkgdown::build_home()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- README smoke-test command with the edited example. The first shell command
  failed because `$x1` expanded inside a double-quoted R expression; rerunning
  with a single-quoted R expression passed.
- `ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/R-CMD-check.yaml .github/workflows/pkgdown.yaml`
- `command -v actionlint || true`
- `rg -n "residual_sd_ratio|residual_variance_ratio|Fit your first model|Getting started|residual_variance_activity|fitted_extra_heterogeneity_variance|workflow_run|concurrency|tags" README.md _pkgdown.yml vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd vignettes/meta-analysis.Rmd .github/workflows docs/dev-log/after-task/2026-05-10-variance-facing-sigma-reporting.md pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/meta-analysis.html --glob '!pkgdown-site/search.json'`
- `gh run list --branch main --limit 2`
- `git diff --check`

## Tests Of The Tests

This task changed documentation and workflow YAML, not model code. The
executable changed articles were rendered, the home page was rebuilt, and
`pkgdown::check_pkgdown()` passed. Workflow files were parsed as YAML locally.
`actionlint` was not installed, so final workflow validation depends on
GitHub Actions after push.

## Consistency Audit

Pat's first-use concern is addressed by showing the sigma-to-variance
conversion in the README and before the getting-started article's feature
catalogue. Rose's stale-next-action finding is addressed by replacing the
completed bivariate covariance next action with a narrower uncertainty-guidance
next action. Grace's CI finding is addressed by preventing automatic pkgdown
deployment from push events that have not yet passed `R-CMD-check`.

## What Did Not Go Smoothly

The first article-render command used the wrong `pkgdown::build_articles()`
interface. The corrected command used three explicit `pkgdown::build_article()`
calls. The first README smoke-test command used double quotes around R code and
let the shell expand `$x1`; the corrected command used single quotes. Local
workflow linting was limited because `actionlint` is not installed in this
environment.

## Team Learning

Pat should see the first runnable model before the package catalogue. Rose
should compare after-task next actions against current source before the report
is closed. Ada should use single-quoted R expressions for shell smoke tests
when code contains `$`. Grace should treat green pkgdown and red R-CMD-check
as a workflow design bug, not just a one-off CI failure.

## Known Limitations

The workflow change has been checked against GitHub documentation and YAML
parsing, but it still needs a live GitHub Actions run to confirm that
`workflow_run` deploys pkgdown only after the `R-CMD-check` workflow succeeds.

## Next Actions

- Watch the next `R-CMD-check` and downstream `pkgdown` runs after push.
- Consider adding R-devel or oldrel CI lanes in a later release-hardening task.
