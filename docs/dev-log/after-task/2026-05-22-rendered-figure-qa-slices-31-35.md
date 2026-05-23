# After Task: Rendered Figure QA Slices 31-35

## Goal

Continue the rendered-figure QA sequence after PR #303 by improving the
referenced `model-workflow` and `bivariate-coscale` article figures without
changing their estimands or inventing uncertainty.

## Implemented

Merged PR #303, started `codex/rendered-figure-qa-31-35` from `main`, and made
two article-level figure improvements:

- Updated all five referenced `model-workflow` figures so visible plot text,
  captions, and alt text distinguish raw response values, fitted `mu`
  estimates, fitted `sigma` residual SDs, 95% Wald bands, and 90% Wald contrast
  intervals.
- Updated both referenced `bivariate-coscale` figures so the continuous
  residual `rho12` curve names its dotted zero line, while the row-wise
  residual-versus-individual correlation display retains Confidence Eye
  geometry and explicitly names the profile intervals and zero reference.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
rendered figures; Fisher checked uncertainty provenance and data grain; Pat and
Darwin checked reader decoding; Grace checked rendered article output and alt
text; Noether checked axes against estimands; Curie checked that prediction
tables and fitted surfaces were not conflated with raw observations; Rose
watched for one-rule-fits-all drift.

## Mathematical Contract

No likelihood, formula grammar, extractor, fitted model, or interval method
changed. The edits only affect article plotting recipes, captions, alt text,
and plot labels. Raw observations remain raw response evidence. Fitted `mu`,
`sigma`, and `rho12` surfaces remain fitted distributional-parameter summaries.
Confidence Eyes remain reserved for row-wise correlation intervals.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-31-35.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-31-35.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh pr merge 303 --squash --delete-branch --subject "Polish reference figure QA slices (#303)"
git checkout -b codex/rendered-figure-qa-31-35
air format vignettes/model-workflow.Rmd vignettes/bivariate-coscale.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE); pkgdown::build_article('bivariate-coscale', new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'plot-parameter-surface|plot-corpairs')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

The two articles rebuilt successfully. The changed rendered PNGs were opened
directly from `pkgdown-site`. The article-image alt-text check found 5
`model-workflow` images and 2 `bivariate-coscale` images, with 0 missing alt
text. Targeted plot-helper tests passed with 88 passing expectations and no
failures, warnings, or skips. `git diff --check` was clean.
`pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

This slice changes article plotting recipes and captions. The primary
validation is rendered-output inspection after rebuilding both articles. The
targeted helper tests cover the two plotting consumers used by the changed
figures: `plot_parameter_surface()` and `plot_corpairs()`.

## Consistency Audit

The case-by-case visual rule still holds:

- raw growth uses raw points and explicitly shows no model interval;
- fitted `mu` and `sigma` surfaces use Wald ribbons only because the prediction
  table supplies finite supported interval columns;
- the habitat contrast uses interval bars because its focal predictor is
  discrete and its table requests 90% Wald intervals;
- the continuous fitted `rho12` curve uses a line, ribbon, and dotted zero line
  rather than a Confidence Eye;
- the row-wise `corpairs()` comparison uses Confidence Eyes with profile
  intervals and a dotted zero line.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The ignored `pkgdown-site` directory still contains stale `unnamed-chunk-*`
PNGs from older `model-workflow` builds. The rendered HTML references only five
named images, so this slice records the boundary instead of deleting generated
site artifacts inside a source PR.

## Team Learning

Model-workflow figures need stronger in-image reader contracts than the gallery
because users may scan the images while learning the post-fit workflow. Pat
should keep asking what a new user can infer from the title and subtitle alone;
Fisher should keep checking whether the displayed interval has a named source;
Florence should keep rejecting helper-output panels when a small label edit
would make the estimand obvious.

## Known Limitations

This slice does not introduce new marginal-mean uncertainty methods, profile
routes, or plotting-helper APIs. It only makes existing rendered article figures
more interpretable and honest about their current interval source.

## Next Actions

1. Open a PR and update issue #58 with the slice summary.
2. Continue the rendered-figure sweep with another article group after this PR
   is green or deliberately queued.
