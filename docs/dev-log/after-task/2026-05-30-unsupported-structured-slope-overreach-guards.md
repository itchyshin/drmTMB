# After Task: Unsupported Structured-Slope Overreach Guards

## Goal

Keep the Phase 6c random-slope surface honest by rejecting formulae that look
like structured slope-correlation requests. The supported path is an unlabelled
one-slope `mu` term with independent structured intercept and slope fields, such
as `phylo(1 + x | species, tree = tree)`.

## Implemented

`parse_structured_bar_term()` now rejects structured covariance-block labels on
non-intercept terms. A labelled term such as
`phylo(1 + x | p | species, tree = tree)` stops with a message that labels are
currently intercept-only and points users to either labelled intercept blocks or
unlabelled independent one-slope paths.

The tests now cover the likely overreach routes: random effects in `rho12`,
bivariate residual-scale slope requests, labelled ordinary `sigma` slope blocks,
multiple structured slopes, and labelled `phylo()` and `spatial()` structured
slope blocks.

## Mathematical Contract

The fitted one-slope structured model estimates two independent latent fields:
one intercept field and one numeric-slope field. It does not estimate
intercept-slope covariance, slope-slope covariance, or predictor-dependent
structured slope correlations. Labelled structured blocks remain
intercept-only until the syntax, TMB mapping, extractor output, simulations, and
docs all agree.

## Files Changed

- `R/parse-formula.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-phylo-gaussian.R`
- `docs/design/01-formula-grammar.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

```sh
Rscript --vanilla -e "files <- c('R/parse-formula.R','tests/testthat/test-gaussian-random-intercepts.R','tests/testthat/test-phylo-gaussian.R','tests/testthat/test-spatial-gaussian.R'); invisible(lapply(files, parse)); cat('unsupported boundary parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^gaussian-random-intercepts$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phylo-gaussian$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^spatial-gaussian$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::build_article('formula-grammar', quiet = FALSE)"
Rscript --vanilla -e "pkgdown::build_reference_index()"
rg -n 'covariance-block labels currently require intercept-only structured terms|within-observation correlation|bivariate residual-scale random intercepts|Labelled structured slope blocks|structured covariance-block labels are intercept-only|phylo\(1 \+ x \| p \| species|spatial\(1 \+ x \| p \| site' R/parse-formula.R tests/testthat/test-gaussian-random-intercepts.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-spatial-gaussian.R docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
rg -n 'phylo\(1 \+ x \| p \| species.*Implemented|spatial\(1 \+ x \| p \| site.*Implemented|animal\(1 \+ x \| p \| id.*Implemented|relmat\(1 \+ x \| p \| id.*Implemented|labelled structured slope.*Implemented|slope correlations are implemented|rho12.*random effects.*Implemented' docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd README.md ROADMAP.md NEWS.md docs/design vignettes
git diff --check
```

## Tests Of The Tests

The new labelled `phylo()` slope test failed before the parser guard because
the formula was accepted and fitted independent fields. That failure exposed the
gap between the documented "planned" slope-correlation boundary and the parser's
previous behaviour.

## Consistency Audit

The formula grammar design note and tutorial now use the same contract:
unlabelled one-slope structured `mu` terms are fitted as independent fields,
while labelled structured slope blocks remain rejected. The stale-wording scan
looked for implemented-claim drift around labelled structured slopes, structured
slope correlations, and random effects in `rho12`.

## GitHub Issue Maintenance

This slice supports the Phase 6c random-slope boundary and structured
one-slope audit issues. No new issue was opened because the work tightens the
existing fitted-versus-planned contract rather than creating a separate feature
track.

## What Did Not Go Smoothly

`devtools::document()` produced local roxygen-version and Rd-link churn even
though no roxygen comments changed. Those generated files were excluded from the
slice before staging.

## Team Learning

When docs mark a natural-looking formula form as planned, add a negative test
for that exact form. Planned syntax should fail loudly instead of slipping into
a weaker fitted interpretation.

## Known Limitations

Structured slope correlations, multiple structured slopes, residual-scale
structured slopes, and labelled structured slope blocks remain unsupported.
Those capabilities still need design, simulations, extractor checks, docs, and
pkgdown evidence before promotion.

## Next Actions

- Keep the Phase 18 structured one-slope simulation tasks focused on recovery,
  accuracy, and coverage for the independent-field models.
- Open a separate design issue before introducing syntax for structured
  intercept-slope or slope-slope covariance.
