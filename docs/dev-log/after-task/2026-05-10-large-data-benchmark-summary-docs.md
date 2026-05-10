# After Task: Large-Data Benchmark Summary Docs

## Goal

Make the large-data article and durable benchmark table reflect the latest
current-schema benchmark evidence without turning local runs into public
performance promises.

## Implemented

- Updated `vignettes/large-data.Rmd` with a compact summary of current
  development benchmark evidence.
- Updated `docs/dev-log/benchmark-results.md` with the current-schema 100k
  storage comparison, 100k `sigma ~ x1`, 100k / 5k species-pressure, and
  500k / 1k row-pressure rows.

## Mathematical Contract

No model likelihood, parameterization, formula grammar, fitted-object API, or
benchmark generator changed. This was documentation and evidence synthesis
only.

## Files Changed

- `vignettes/large-data.Rmd`
- `docs/dev-log/benchmark-results.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md`

## Checks Run

- `air format vignettes/large-data.Rmd docs/dev-log/benchmark-results.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md`:
  passed.
- `rg -n "500k rows|500,000|10,000-species|factor-heavy|non-Gaussian|5\\.1 GB|memory-light" vignettes/large-data.Rmd docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md docs/dev-log/check-log.md`:
  passed and found the expected source text.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "What the current development benchmarks say|500k rows|5\\.1 GB|10,000-species|factor-heavy|non-Gaussian" vignettes/large-data.Rmd pkgdown-site/articles/large-data.html docs/dev-log/benchmark-results.md docs/dev-log/after-task/2026-05-10-large-data-benchmark-summary-docs.md --glob '!pkgdown-site/search.json'`:
  passed and confirmed the generated article includes the new section.
- `git diff --check`: passed.

## Result

The large-data article now tells users that local development rows have
converged for 100,000 rows / 1,000 species, 100,000 rows / 5,000 species, and
500,000 rows / 1,000 species, while also saying that factor-heavy fixed-effect
designs remain a scaling limitation.

## Tests Of The Tests

The new public prose is backed by existing after-task reports and benchmark
CSV summaries. The planned validation checks verify that the terms
`memory-light`, `500k`, `10,000-species`, `factor-heavy`, and
`non-Gaussian` appear in the expected files.

## Consistency Audit

The article keeps `drm_control()`, `sigma`, `phylo()`, and memory-light storage
language aligned with the current package interface. It does not claim
million-row, bivariate, non-Gaussian, or 10,000-species readiness.

## What Did Not Go Smoothly

Nothing failed during editing. The main risk was overclaiming from one local
500k run, so the article labels the evidence as development planning evidence.

## Team Learning

Pat should see one short table instead of hunting through after-task reports.
Rose should keep blocking broad readiness claims until repeated benchmark rows
exist.

## Known Limitations

The benchmark table still contains selected local rows only. It is not a
statistical performance study, and it does not include million-row,
10,000-species, bivariate, or non-Gaussian rows.

## Next Actions

- Add repeated-run benchmark summaries before making public performance claims.
- Add sparse fixed-effect support before encouraging factor-heavy large-data
  workflows.
