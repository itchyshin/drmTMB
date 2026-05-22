# After Task: gllvmTMB-Informed Figure Polish

## Goal

Continue the comprehensive figure audit by reading the local `gllvmTMB`
covariance/correlation plotting branch and applying only the transferable
visual lessons to the first high-risk `drmTMB` gallery panels.

## Implemented

The sister-package lesson is recorded in
`docs/dev-log/audits/2026-05-21-gllvmtmb-visual-lessons.md`. The useful pattern
was row-label-first plotting: labels carry layer identity, redundant legends
are hidden, missing-interval rows remain visible, and raindrops are described
as frequentist compatibility displays.

In `vignettes/figure-gallery.Rmd`, the coefficient and correlation raindrop
figures now hide redundant legends because the row labels already identify the
parameter class or layer. The modelled `sd(site)` surface now includes a
site-level reef-cover rug so readers can see where the predictor is supported.

## Mathematical And Visual Contract

No likelihood, extractor, or interval algorithm changed. The visual contract is
unchanged:

- coefficient and correlation raindrops are frequentist compatibility displays;
- direct correlation intervals use a guarded atanh-style link scale;
- the `sd(site)` surface is a modelled random-effect SD surface, not residual
  `sigma`;
- raw response observations are not plotted on the SD axis;
- the `sd(site)` surface still has no Wald ribbon or whisker because the
  prediction table reports unavailable surface intervals.

## Files Changed

- `vignettes/figure-gallery.Rmd`
- `docs/dev-log/audits/2026-05-21-gllvmtmb-visual-lessons.md`
- `docs/dev-log/figure-audits/2026-05-21-audit-kickoff/figure-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-gllvmtmb-informed-figure-polish.md`

## Checks Run

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
rg -n 'Parameter class|colour = "Layer"|Fisher-z scale|direct random-effect SD surface' vignettes/figure-gallery.Rmd pkgdown-site/articles/figure-gallery.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

## Tests Of The Tests

No new package tests were added because this slice changes article plotting
recipes and audit notes only. The meaningful evidence is rendered-page review:
the changed gallery figures were rendered and inspected as PNGs.

## Consistency Audit

The `gllvmTMB` source was used as design evidence, not as copied code. No
`inst/COPYRIGHTS` update is required for this slice. The stale-wording scan
checks that removed legend labels and old Fisher-z/direct-SD wording do not
remain in the current gallery source or rendered page.

## GitHub Issue Maintenance

No issue was updated in this local figure-polish slice. The broader audit is
still being tracked in the dev-log lane until the next PR summary decides
which figure items need separate GitHub issues.

## What Did Not Go Smoothly

The `gllvmTMB` branch inspected here is itself dirty, so it should be treated
as a sister-package working pattern rather than a stable API. That is still
useful: it showed a cleaner visual direction without requiring any code port.

## Known Limitations

The full figure-gallery audit is not complete. The coefficient, correlation,
and `sd(site)` panels are cleaner, but other gallery figures and the high-risk
articles still need one-by-one rendered review. The modelled `sd(group) ~ x`
surface still needs a future interval route before bands or whiskers can be
drawn.

## Next Actions

1. Continue the rendered audit through the remaining `figure-gallery` panels.
2. Rebuild the full pkgdown site before deploy or PR closeout.
3. Move from gallery figures to `model-workflow`, then `model-map`,
   `implementation-map`, `simulation-plot-grammar`, and
   `phylogenetic-spatial`.
