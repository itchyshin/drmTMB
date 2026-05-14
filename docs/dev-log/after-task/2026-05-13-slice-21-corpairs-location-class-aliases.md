# After Task: Slice 21 Corpairs Location-Class Aliases

## Goal

Make `corpairs()` filtering compatible with the reserved `corpair()` class
vocabulary while keeping existing output classes stable.

## Implemented

- Added `location-location` as a filter alias for existing `mean-mean`
  `corpairs()` rows.
- Added `location-scale` as a filter alias for existing `mean-scale` rows.
- Added `location-slope` and `slope-location` aliases for existing
  `mean-slope` rows.
- Documented the alias bridge in `corpairs()` roxygen, formula grammar, and
  the coscale correlation-pairs design note.
- Added q4 regression checks showing that `corpairs(fit, class =
  "location-scale")` and `corpairs(fit, class = "location-location")` return
  the expected fitted rows.

## Mathematical Contract

No likelihood changed. This is an extractor compatibility layer:

```text
location-location -> mean-mean
location-scale    -> mean-scale
location-slope    -> mean-slope
slope-location    -> mean-slope
```

The fitted rows continue to report their existing `class` values. The aliases
only affect filtering.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `man/corpairs.Rd`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-biv-gaussian.R`
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::test(filter = "biv-gaussian|corpairs|package-skeleton", reporter = "summary")'`
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `git diff --check`

## Tests Of The Tests

The q4 test already fits a block with one location-location row and four
location-scale rows. The new expectations check that the alias filters return
exactly those counts.

## Consistency Audit

The reserved `corpair()` grammar uses `location-location` and
`location-scale`, while older fitted summaries use `mean-mean` and
`mean-scale`. The docs now state that this is an alias bridge, not a rename.

## What Did Not Go Smoothly

No implementation issue. I deliberately avoided a broad class-name migration
because it would touch many tests and user-facing tables.

## Team Learning

Boole caught a terminology mismatch between planned formula syntax and fitted
extractor filters. The small alias layer keeps the two surfaces usable without
destabilising existing output.

## Known Limitations

- `corpairs()` output still uses existing `mean-*` class names.
- A future output rename to `location-*` would need a broader deprecation or
  compatibility plan.

## Next Actions

Continue hardening q4 and phylogenetic surfaces, or design the broader class
name migration if the project wants `location-*` as the public output spelling.
