# After Task: Phase 10 Spatial Slope Reader Path

## Goal

Make the implemented coordinate-spatial one-slope path discoverable in the
reader-facing tutorial, model map, formula grammar, source map, README, and
historical Phase 6c handoff notes.

## Implemented

- Updated the structured-dependence article so the opening status, status
  table, and spatial section all name both
  `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`.
- Added an evaluated tutorial fit for one numeric coordinate-spatial `mu`
  slope and interpreted the two SDs as smooth site intercept variation and
  smooth site-to-site variation in the environmental slope.
- Updated the model map, formula grammar article, source map, and README so
  the first coordinate-spatial path is described as an intercept plus one
  numeric slope path, not intercept-only.
- Added supersession wording to the Phase 6c closure notes so they remain
  historically true while acknowledging the later Phase 10 coordinate-slope
  implementation.

## Mathematical Contract

The fitted claim is still narrow: univariate Gaussian `mu` can include a
coordinate-spatial random intercept and one numeric coordinate-spatial slope.
The two fields share the same fixed coordinate precision, have separate SDs,
and do not estimate an intercept-slope `corpair()` row. Mesh/SPDE spatial
fields, multiple spatial slopes, spatial slope correlations, spatial `sigma`,
bivariate spatial covariance, and spatial `corpair()` regressions remain
planned.

## Files Changed

- `README.md`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/after-phase/2026-05-15-phase-6c-core-random-effect-closure.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-10-spatial-slope-reader-path.md`

## Checks Run

- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH air format README.md vignettes/phylogenetic-spatial.Rmd vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd docs/design/16-phylo-spatial-common-math.md docs/design/33-phase-6c-core-random-effects.md docs/dev-log/after-phase/2026-05-15-phase-6c-core-random-effect-closure.md`
  passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/phylogenetic-spatial.Rmd", output_file = tempfile(fileext = ".html"), quiet = FALSE)'`
  passed and rendered the updated evaluated slope example.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'devtools::test(filter = "spatial-gaussian", reporter = "summary")'`
  passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::build_site()'`
  passed.
- `PATH=/opt/homebrew/bin:/usr/local/bin:$PATH /usr/local/bin/Rscript -e 'pkgdown::check_pkgdown()'`
  passed with no problems found.
- `git diff --check`
  passed.

## Tests Of The Tests

No new test files were added. The existing `spatial-gaussian` tests remain the
behavioural guard for the fitted one-slope path; the new evaluated vignette fit
adds a documentation-level smoke test that pkgdown rebuilds with the public
syntax.

## Consistency Audit

Search run:

```sh
rg -n 'spatial random intercepts|intercept-only structured random effect|The first coordinate-based spatial path|first fitted spatial instance|structured random slopes,|spatial\(1 \+ x \| site, coords = coords\).*Planned|spatial\(1 \+ x \| site, coords = coords\).*planned|only the intercept|spatial random fields|profile-likelihood confidence intervals\.' README.md ROADMAP.md NEWS.md docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/dev-log/**'
```

The remaining hits are valid: NEWS and README mention intercept-only
phylogenetic effects while also naming the implemented spatial slope, ROADMAP
records the completed coordinate path and planned mesh slopes, and design/docs
hits use "first fitted spatial instances" or "first coordinate-based spatial
paths" in the plural.

## What Did Not Go Smoothly

The first edit pass missed README and the historical Phase 6c after-phase note.
Mill and Maxwell both flagged those as reader-path gaps, and the second pass
closed them.

## Team Learning

- Ada: keep small follow-through slices concrete; this was a synchronization
  task, not another likelihood task.
- Pat and Darwin: evaluated examples are worth adding when they answer a real
  interpretation question, here whether an environmental slope changes across
  space.
- Gauss and Noether: wording must preserve the independent-field contract and
  avoid implying a spatial intercept-slope correlation.
- Grace: render the changed vignette before calling the docs path complete.
- Rose: historical closure notes need supersession wording instead of silent
  rewriting.

## Known Limitations

- The coordinate-spatial slope path remains univariate Gaussian `mu` only.
- Only one numeric spatial slope is fitted.
- No spatial intercept-slope `corpair()` row is fitted.
- Mesh/SPDE, multiple spatial slopes, spatial scale terms, bivariate spatial
  covariance, and spatial `corpair()` regressions remain planned.

## Next Actions

- Continue Phase 10+ with structured-slope follow-through only after keeping
  this reader path stable.
- For future tutorial work, keep biological interpretation, extractor names,
  and planned boundaries in the same section so users do not have to infer
  status from the roadmap.
