# After Task: Rendered Figure QA Slices 26-30

## Goal

Continue the rendered-figure QA sequence after PR #302 by polishing the next
gallery and generated-reference figures whose visible uncertainty contract was
still ambiguous or visually heavier than needed.

## Implemented

Merged PR #302, started `codex/rendered-figure-qa-26-30` from `main`, and made
five focused changes:

- Revised the categorical-by-categorical gallery caption, alt text, and
  subtitle so raw observations, fitted `mu` cell means, and 95% Wald intervals
  are named separately.
- Revised the empirical marginal gallery caption, alt text, subtitle, y-axis
  label, and source-map entry so plug-in means and averaged row-wise Wald
  limits are not presented as full marginal-mean uncertainty.
- Revised the continuous-by-continuous interaction subtitle so its ribbons are
  explicitly identified as 95% Wald bands at three moisture slices.
- Polished the `plot_corpairs()` roxygen example so the generated reference
  image uses readable multi-line labels, manual colours, no redundant legend,
  and the existing Confidence Eye geometry.
- Polished the `plot_parameter_surface()` roxygen example so the generated
  reference image shows fitted lines and Wald ribbons without grid-point
  clutter.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
rendered figures; Fisher checked uncertainty provenance; Pat and Darwin checked
reader decoding; Grace checked the pkgdown render path; Noether checked labels
against estimands; Curie checked data-grain distinctions; Rose watched for
one-rule-fits-all drift.

## Mathematical Contract

No likelihood, formula grammar, fitted model, extractor, or inferential target
changed. The edits affect rendered examples, captions, subtitles, alt text, and
the gallery source map. Confidence Eyes remain reserved for row-wise estimate
and uncertainty displays. Raw-data figures retain raw points when those points
are part of the reader evidence. Fitted surfaces use ribbons only when finite
interval columns are supplied.

## Files Changed

- `R/plot-corpairs.R`
- `R/plot-parameter-surface.R`
- `man/plot_corpairs.Rd`
- `man/plot_parameter_surface.Rd`
- `vignettes/figure-gallery.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-26-30.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-26-30.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh pr merge 302 --squash --delete-branch --subject "Polish gallery figure QA slices (#302)"
git checkout -b codex/rendered-figure-qa-26-30
air format R/plot-corpairs.R R/plot-parameter-surface.R vignettes/figure-gallery.Rmd
Rscript -e "devtools::document(); devtools::load_all(quiet = TRUE); pkgdown::build_reference(topics = c('plot_corpairs', 'plot_parameter_surface'), lazy = FALSE, preview = FALSE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'plot-parameter-surface|plot-corpairs')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

The `plot_corpairs()` and `plot_parameter_surface()` reference pages rebuilt,
the `figure-gallery` article rebuilt, and the reference alt-text post-processor
completed cleanly. Targeted plot-helper tests passed with 88 passing
expectations and no failures, warnings, or skips. `git diff --check` was clean.
`pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

This slice changes plotting examples and article figure wording. The primary
test is rendered-output inspection of the regenerated PNGs rather than source
inspection alone. The regenerated images were opened directly from
`pkgdown-site` after the build command completed.

## Consistency Audit

The case-by-case visual rule still holds:

- correlation rows with finite intervals use Confidence Eyes and a dotted zero
  reference line;
- fitted surfaces use lines and ribbons when the prediction table supplies
  finite interval columns;
- raw-data figures keep raw observations when those observations support the
  modeled comparison;
- plug-in summaries are labelled as plug-in summaries when their bars are only
  display approximations.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The empirical marginal summary remains a compromise display. Its bars are
averaged row-wise Wald limits, not a formal marginal-mean interval. The fix here
is not to overbuild a new estimator inside a visual QA slice; it is to label the
existing display honestly and leave a future statistical interval route for a
focused task.

## Team Learning

Some figures should show uncertainty with a Confidence Eye, some with Wald
ribbons or bars, and some should show raw data or fitted modes without
pretending an interval exists. Fisher should keep guarding the interval source;
Pat should keep reading subtitles as a new user would; Florence should keep
judging the rendered plot only after the estimand and data grain are named.

## Known Limitations

The generated reference examples are now cleaner, but they are still examples,
not a full design-system gallery. A future pass should continue through
model-workflow and bivariate-coscale figures where the plots are usable but
less polished than the main gallery.

## Next Actions

1. Run targeted tests, `pkgdown::check_pkgdown()`, and `git diff --check`.
2. Open a PR and update issue #58 with the slice summary.
3. Continue beyond slice 30 only after this PR is green or deliberately queued.
