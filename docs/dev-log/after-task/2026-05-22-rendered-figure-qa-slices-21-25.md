# After Task: Rendered Figure QA Slices 21-25

## Goal

Continue the rendered-figure QA sequence after PR #301 by improving the next
gallery figures whose uncertainty or estimate geometry needed clearer visual
contracts.

## Implemented

Merged PR #301, started `codex/rendered-figure-qa-21-25` from `main`, and made
three focused gallery changes:

- Revised the `parameter-surface` figure so it displays fitted lines and 95%
  Wald ribbons from `predict_parameters()` without dense grid-point overlays.
- Clarified that the random-slope trajectory figure shows conditional modes,
  not interval uncertainty.
- Clarified that the direct `sd(site)` surface is line-only because
  `conf.status = "wald_unavailable"` and profile or bootstrap intervals are the
  future uncertainty route.

The gallery source map now names the variance-component display as a Confidence
Eye, names random-slope rows as conditional modes, and records the interval
status of the fitted-surface and no-interval figures. No spawned subagents were
used. Ada coordinated the slice; Florence inspected rendered figures; Fisher
checked uncertainty provenance; Pat and Darwin checked reader decoding; Grace
checked rendered artifacts and stale-image boundaries; Noether checked labels
against estimands; Curie checked the data-grain distinction; Rose watched for
one-rule-fits-all drift.

## Mathematical Contract

No likelihood, formula grammar, fitted model, extractor, or inferential target
changed. The edits only change gallery captions, subtitles, source-map labels,
and one plot-helper call (`point = FALSE`) for a rendered example. Wald bands
remain tied to finite interval columns from `predict_parameters()`. Conditional
random-slope modes and direct random-effect SD surfaces remain point or line
summaries without fabricated uncertainty.

## Files Changed

- `vignettes/figure-gallery.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-21-25.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-21-25.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh pr merge 301 --squash --delete-branch --subject "Polish simulation figure QA slices (#301)"
git checkout -b codex/rendered-figure-qa-21-25
air format vignettes/figure-gallery.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'plot-parameter-surface|plot-corpairs')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

The `figure-gallery` article rebuilt successfully. The reference alt-text
post-processor completed cleanly on the current `pkgdown-site`. Targeted
plot-helper tests passed with 88 passing expectations and no failures, warnings,
or skips. `pkgdown::check_pkgdown()` reported no problems. `git diff --check`
was clean.

## Tests Of The Tests

This slice changes article plotting recipes and developer documentation. The
primary validation is rendered-output inspection after rebuilding the
`figure-gallery` article. The changed figures were opened directly rather than
judged from source code alone.

## Consistency Audit

The case-by-case visual rule still holds:

- fitted continuous surfaces use lines and ribbons only when prediction tables
  carry finite interval columns;
- conditional random-effect modes are useful fitted output but not interval
  displays;
- direct random-effect SD surfaces remain visibly interval-free until a
  profile or bootstrap route is validated;
- coefficient, variance-component, and correlation row summaries continue to
  use Confidence Eyes when finite interval provenance is available.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The first inventory included contact sheets from the ignored `pkgdown-site`
directory, but the model-workflow contact sheet mostly captured stale
`unnamed-chunk-*` PNGs that the rendered article no longer references. The
final audit records the referenced-image boundary instead of committing those
intermediate contact sheets.

## Team Learning

Line plots can and should carry uncertainty when the source table supplies a
real interval, but line plots can also be honest point or mode summaries. The
reader-facing difference must be visible in the caption, subtitle, and source
map. Fisher should keep checking provenance; Pat should keep asking what a new
reader would infer from a line or ribbon; Florence should judge the rendered
figure only after that contract is clear.

## Known Limitations

The direct `sd(site)` surface still has no uncertainty band. That is deliberate
for now because the current derived surface reports Wald intervals as
unavailable. A future slice should add profile or bootstrap uncertainty only
after the extractor and tests support that route.

## Next Actions

1. Open a PR and update issue #58 with the slice summary.
2. Continue with slices 26-30 by targeting reference pages or article pages
   where stale generated images, no-interval labels, or raw-data/data-grain
   mismatches still make rendered QA harder.
