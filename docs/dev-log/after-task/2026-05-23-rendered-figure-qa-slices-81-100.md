# After Task: Rendered Figure QA Slices 81-100

## Goal

Finish the current rendered-figure sweep through slice 100 by adding
case-appropriate figures to the remaining family or model-family tutorials
that were still figure-free. The purpose was not to make every page look the
same. It was to give each page one useful visual check at the right data
grain.

## Implemented

Started `codex/rendered-figure-qa-81-100` from updated `origin/main`.

Four tutorial pages now have one rendered figure each:

- `robust-student`: `robust-student-tail-figure`
- `count-nbinom2`: `count-model-parts-figure`
- `proportion-beta-binomial`: `beta-binomial-tray-figure`
- `meta-analysis`: `meta-variance-components-figure`

The robust Student-t figure shows raw seedling-growth values and overlays
Gaussian versus Student-t fitted expected growth. This uses raw data because
the scientific question is whether heavy tails matter.

The zero-inflated NB2 figure shows fitted response-scale components:
conditional mean, unconditional mean, NB2 `sigma`, and structural-zero
probability. Facets use their own x scales so count means, scale, and
probabilities are not compared on one axis.

The beta-binomial figure shows raw tray proportions, fitted expected
germination probability, and plus or minus one fitted proportion-level
standard deviation. The caption explicitly says those bars are fitted scatter,
not confidence intervals.

The meta-analysis figure shows known sampling variance and fitted extra
heterogeneity variance as variance components, with a point marking mean total
observation variance. It is not an interval display.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
the rendered PNGs; Fisher checked uncertainty provenance and data grain; Pat
checked whether a reader can decode the figure where it appears; Darwin checked
that the biological question remains visible; Grace checked rendering and alt
text; Rose checked for one-rule-fits-all drift. These were role perspectives,
not running agents.

## Mathematical Contract

No likelihood, formula grammar, optimizer, extractor, interval method, or
exported plotting helper changed.

The figure grammar is:

- robust Student-t: raw response tails plus fitted expected-growth points;
- zero-inflated NB2: separate fitted components on response scales;
- beta-binomial: raw tray proportions plus fitted expected probability and
  fitted proportion-level scatter; and
- meta-analysis: known and fitted variance components, not confidence
  intervals.

## Files Changed

- `vignettes/robust-student.Rmd`
- `vignettes/count-nbinom2.Rmd`
- `vignettes/proportion-beta-binomial.Rmd`
- `vignettes/meta-analysis.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/audits/2026-05-22-rendered-article-checklist.md`
- `docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-81-100.md`
- `docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-81-100.md`
- `docs/dev-log/check-log.md`
- `.gitignore`
- `.Rbuildignore`

## Checks Run

```sh
git switch -c codex/rendered-figure-qa-81-100 origin/main
Rscript -e "devtools::load_all(quiet = TRUE); for (article in c('robust-student','count-nbinom2','proportion-beta-binomial','meta-analysis')) pkgdown::build_article(article, new_process = FALSE, quiet = TRUE)"
Rscript - <<'RS'
articles <- c('robust-student','count-nbinom2','proportion-beta-binomial','meta-analysis')
for (stem in articles) {
  html <- paste(readLines(sprintf('pkgdown-site/articles/%s.html', stem), warn = FALSE), collapse = '\n')
  pattern <- sprintf('<img[^>]+src=\"%s_files/figure-html/[^\"]+\"[^>]*>', stem)
  m <- gregexpr(pattern, html, perl = TRUE)
  imgs <- regmatches(html, m)[[1]]
  if (identical(imgs, character(0))) imgs <- character()
  missing <- imgs[!grepl('alt=\"[^\"]+', imgs)]
  cat(stem, ': ', length(imgs), ' images, ', length(missing), ' missing alt\n', sep = '')
}
RS
air format vignettes/robust-student.Rmd vignettes/count-nbinom2.Rmd vignettes/proportion-beta-binomial.Rmd vignettes/meta-analysis.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-81-100.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-81-100.md docs/dev-log/check-log.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::build_vignettes()"
```

Recovery closeout reran:

```sh
air format vignettes/robust-student.Rmd vignettes/count-nbinom2.Rmd vignettes/proportion-beta-binomial.Rmd vignettes/meta-analysis.Rmd docs/design/39-visualization-grammar.md docs/dev-log/audits/2026-05-22-rendered-article-checklist.md docs/dev-log/audits/2026-05-23-rendered-figure-qa-slices-81-100.md docs/dev-log/after-task/2026-05-23-rendered-figure-qa-slices-81-100.md docs/dev-log/check-log.md
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
rg -n "rendered figure|figure QA|robust-student|count-nbinom2|proportion-beta-binomial|meta-analysis|figure-free|family tutorial" README.md ROADMAP.md NEWS.md docs/design docs/dev-log vignettes _pkgdown.yml -g '!*.html'
```

The four edited articles rebuilt successfully. Each edited article has one
referenced image, 0 missing alt attributes, and one caption. The four new PNGs
were inspected directly. `git diff --check` was clean.
`pkgdown::check_pkgdown()` reported no problems. `devtools::build_vignettes()`
completed successfully.

## Tests Of The Tests

No package behaviour tests were added because this slice did not change package
code, likelihoods, extractors, interval methods, or exported plotting helpers.
The closest test of the figure work was the render-and-inspect loop: the four
edited articles rebuilt, the rendered HTML scan found one image with non-empty
alt text in each article, and the four referenced PNGs were inspected directly.

## Consistency Audit

The case-by-case figure rule still holds. These family tutorials do not use
Confidence Eyes because they are not row-wise interval summaries. Raw response
points appear only where the response distribution itself is the reader
evidence. Fitted scale, zero-inflation, and variance-component displays name
their data grain and avoid pretending to show confidence intervals.

Closeout also searched the project for rendered-figure, article-name, and
family-tutorial wording. The broad hits were existing roadmap, source-map,
after-task, and recovery-checkpoint records rather than stale claims that these
new figures provide formal intervals or new plotting APIs.

## GitHub Issue Maintenance

GitHub issue #58, "Phase 17: visualization layer for fitted models and
simulation outputs", is the overlapping open tracker. This slice contributes to
the tutorial-ready visualization surface, but it does not complete Phase 17
because broad helper contracts, simulation compatibility, and full issue
closure remain outside this local figure sweep. No issue was closed.

Issue searches used the open-issue queries "rendered figure QA tutorial figures
robust-student count-nbinom2 beta-binomial meta-analysis" and "figure QA OR
rendered figures OR visualization grammar OR family tutorials" against
`itchyshin/drmTMB`.

## What Did Not Go Smoothly

The thread crashed after validation but before final closure, so the recovery
state had to be reconstructed from `git status`, the check log, the audit
table, the after-task report, and rendered PNGs. `devtools::build_vignettes()`
also left local `doc/` and `Meta/` directories, so this slice adds them to
`.gitignore` and `.Rbuildignore` instead of letting generated build artifacts
keep reappearing as worktree noise.

## Team Learning

Ada should keep writing a recovery checkpoint before long visual sweeps cross
major transitions. Florence's gate worked best when it judged each rendered
image against the article's purpose rather than forcing one house style onto
family tutorials. Fisher and Pat should keep asking whether a bar, ribbon, or
point is evidence, fitted scatter, or a model component before the caption is
accepted.

## Known Limitations

The new figures are teaching fixtures tied to their articles. They are not
exported plotting helpers, and they do not add interval support to count,
proportion, robust Student-t, or meta-analysis examples.

## Next Actions

After slice 100, the rendered figure sweep has coverage across the main figure
gallery, workflow, structured-dependence guides, diagnostics, large-data,
simulation, and family tutorial pages. The next useful pass should be a status
and stale-claim audit rather than more visual expansion unless a rendered
figure looks wrong.
