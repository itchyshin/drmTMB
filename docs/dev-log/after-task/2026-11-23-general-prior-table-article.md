# After Task: General prior table article

## Goal

Explain the drmTMB prior-table API with runnable examples for regression
coefficients, supported SD targets, and correlation targets.

## Implemented

The article now shows Normal and Student-t coefficient rows, Gamma rows for
residual and supported independent random-intercept SDs, an LKJ row for a
Gaussian random-slope correlation, and an LKJ `rho12` row for bivariate
Gaussian models. It states the natural-SD density convention and distinguishes
the data log-likelihood, log prior, and minimized negative penalized objective.
The pkgdown menu now names coefficient and covariance targets.

## Mathematical Contract

Gamma table parameters are `mean` and `shape`; the resulting density is
normalized on natural SD and has no log-SD Jacobian. The reported data
log-likelihood is unpenalized at the penalized estimate. The log prior is
stored separately, and the minimized objective is the negative of their sum.

## Files Changed

- `vignettes/articles/fixed-effect-priors.Rmd`
- `_pkgdown.yml`
- `docs/dev-log/check-log.d/2026-11-23-general-prior-table-article.md`

## Checks Run

The article rendered successfully and executed all examples, including the
bivariate residual-correlation fit. The rendered HTML SHA-256 is recorded in
the check-log shard. `pkgdown::check_pkgdown()` reported no problems.
`slop_check.py` reported zero findings for the article and report. `git diff
--check` passed.

## Tests Of The Tests

The executable article exposed unsupported prior/model combinations during
two initial renders. The examples were separated to match the native
selectors, and the final render passed. This was documentation validation;
no package tests were added in this task.

## Consistency Audit

A read-only review checked the examples against the table parser and prior
validator. The article now describes the current boundary: Gamma priors target
independent mean random-intercept SDs, while LKJ priors separately target a
supported random-slope correlation. The bivariate route permits one residual
`rho12` LKJ row and optional exact `mu1` or `mu2` Normal or Student-t rows.
AIC, BIC, and AICc are described as warning-labelled diagnostics, not ordinary
ML comparison criteria. Whole-project roadmap and NEWS edits remain with the
integrated feature closeout.

## GitHub Issue Maintenance

No issue was changed. The generalized prior feature remains in progress, so
issue maintenance belongs to its integration closeout.

## What Did Not Go Smoothly

The first draft combined Gamma random-intercept SD and LKJ random-slope rows in
one model, which the current resolver refuses. A second draft combined a
residual-SD Gamma row with a varying sigma formula, also refused. The render
then exposed a reused example variable and an incorrect description of the
objective sign. Each was corrected and the final article rerendered.

## Team Learning

Render examples that combine prior classes, not just one target at a time.
This catches model-family and selector restrictions as well as syntax errors.

## Known Limitations

The current implementation does not support Gamma priors on individual SDs in
correlated random-slope blocks. This is not an acceptance requirement in the
approved current plan and needs a separately scoped target and oracle if added.

## Next Actions

Continue exact-source full-suite and bridge validation across the four package
lanes. Keep all changes local; do not merge or release under the current plan.
